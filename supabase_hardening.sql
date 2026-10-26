-- Partido Word Catch — security hardening
-- Run this in the Supabase SQL Editor AFTER supabase_schema.sql. Safe to
-- re-run (every statement below is idempotent), and re-running it never
-- loosens anything.
--
-- THE MODEL
-- The app ships Supabase's anon/publishable key, which is public by
-- design. So:
-- 1. Row Level Security is ON for `classes` and `students` with NO
--    policies, which makes Postgres deny all direct table access.
-- 2. The app instead calls one Postgres function per operation
--    (/rest/v1/rpc/<name>). Each is SECURITY DEFINER so it can reach the
--    locked tables, and each returns only the slice of data its one job
--    needs - never teacher_email, never student_pin.
-- 3. TEACHERS sign in with Google (Supabase Auth). Every teacher function
--    reads the caller's identity from their signed-in session
--    (auth.uid()), never from a parameter, and is not callable with the
--    anon key at all. A class belongs to the teacher who created it
--    (classes.teacher_user_id): knowing a class code no longer lets anyone
--    see its roster, edit it, or delete its students.
-- 4. PUPILS keep the simple name + 4-digit PIN (no accounts for children).
--    PINs are stored as bcrypt hashes, every PIN check is rate-limited
--    (see login_attempts below), and taking over an account on a new
--    phone needs the PIN, not just an id.
--
-- SUPABASE DASHBOARD SETUP (once)
-- - Authentication > Providers > Google: enable it and paste the Client ID
--   and Client Secret of a Google Cloud "Web application" OAuth client
--   whose authorized redirect URI is
--   https://<your-project-ref>.supabase.co/auth/v1/callback
-- - Authentication > URL Configuration > Redirect URLs: add
--   http://127.0.0.1:43821/auth/callback (the app catches the sign-in
--   there - see SyncManager.gd's GOOGLE SIGN-IN section).
-- - Authentication > Providers > Email: turn it off. Only Google is used.

create extension if not exists pgcrypto;

-- 1) Lock the tables down.
alter table classes enable row level security;
alter table students enable row level security;
drop policy if exists "anon full access" on classes;
drop policy if exists "anon full access" on students;

alter table classes add column if not exists teacher_user_id uuid;
create unique index if not exists classes_teacher_user_id_key on classes (teacher_user_id);

-- 2) Remove the old functions that trusted the caller blindly. Each is
-- replaced by a safer one further down.
--    upsert_class         -> teacher_save_my_class (owner only)
--    find_class_by_email  -> teacher_get_my_class (Google sign-in)
--    claim_student_account(uuid, text) -> claim_student_account(uuid, text, text) (needs the PIN)
drop function if exists public.upsert_class(text, text, text, text, text, text, text);
drop function if exists public.find_class_by_email(text);
drop function if exists public.claim_student_account(uuid, text);

-- ============================================
-- RATE LIMITING
-- ============================================
-- One row per FAILED PIN check. A pupil's name gets 5 wrong PINs per 15
-- minutes (counted together across every login screen, so switching
-- screens doesn't buy more guesses), and one network address gets 50.
-- 50 is generous on purpose: a whole class often shares one school Wi-Fi
-- address, and a few pupils mistyping shouldn't lock out everyone else.
-- A successful login clears that name's failures.
create table if not exists login_attempts (
  id bigserial primary key,
  bucket text not null,
  attempted_at timestamptz not null default now()
);
create index if not exists login_attempts_bucket_time on login_attempts (bucket, attempted_at);
alter table login_attempts enable row level security;

-- The caller's address as Supabase's API gateway reports it, or '' when
-- it isn't available (e.g. running these functions by hand in the editor).
create or replace function public._caller_ip()
returns text
language plpgsql
stable
set search_path = public, pg_temp
as $$
declare
  headers json;
begin
  begin
    headers := nullif(current_setting('request.headers', true), '')::json;
  exception when others then
    return '';
  end;
  return coalesce(
    nullif(btrim(split_part(headers->>'x-forwarded-for', ',', 1)), ''),
    headers->>'cf-connecting-ip',
    ''
  );
end;
$$;

-- Raises 'too_many_attempts' if either bucket is over its limit. The app
-- shows "too many wrong tries" when it sees that message.
create or replace function public._check_login_limit(p_name_bucket text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  ip text := public._caller_ip();
begin
  if (select count(*) from login_attempts
      where bucket = p_name_bucket and attempted_at > now() - interval '15 minutes') >= 5 then
    raise exception 'too_many_attempts' using errcode = 'P0001';
  end if;
  if ip <> '' and (select count(*) from login_attempts
      where bucket = 'ip:' || ip and attempted_at > now() - interval '15 minutes') >= 50 then
    raise exception 'too_many_attempts' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public._record_login_failure(p_name_bucket text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  ip text := public._caller_ip();
begin
  insert into login_attempts (bucket) values (p_name_bucket);
  if ip <> '' then
    insert into login_attempts (bucket) values ('ip:' || ip);
  end if;
  -- Keep the table small.
  delete from login_attempts where attempted_at < now() - interval '1 day';
end;
$$;

create or replace function public._clear_login_failures(p_name_bucket text)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  delete from login_attempts where bucket = p_name_bucket;
$$;

create or replace function public._name_bucket(p_player_name text)
returns text
language sql
immutable
as $$
  select 'name:' || lower(btrim(coalesce(p_player_name, '')));
$$;

-- Helpers are internal only - never callable through the API.
revoke execute on function public._caller_ip() from public, anon, authenticated;
revoke execute on function public._check_login_limit(text) from public, anon, authenticated;
revoke execute on function public._record_login_failure(text) from public, anon, authenticated;
revoke execute on function public._clear_login_failures(text) from public, anon, authenticated;
revoke execute on function public._name_bucket(text) from public, anon, authenticated;

-- ============================================
-- TEACHER FUNCTIONS (signed in with Google only)
-- ============================================

-- The signed-in teacher's own verified email, or null. Read from
-- auth.users rather than from the token so it's always the address
-- Google actually confirmed.
create or replace function public._my_verified_email()
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select u.email from auth.users u
  where u.id = auth.uid() and u.email_confirmed_at is not null and u.email is not null;
$$;
revoke execute on function public._my_verified_email() from public, anon, authenticated;

-- Classes created before Google sign-in existed have no owner yet. The
-- first time their teacher signs in with the same (Google-verified) email
-- they registered with, the class becomes theirs.
create or replace function public._claim_legacy_class()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  my_email text := public._my_verified_email();
begin
  if auth.uid() is null or my_email is null then
    return;
  end if;
  if exists (select 1 from classes where teacher_user_id = auth.uid()) then
    return;
  end if;
  update classes
  set teacher_user_id = auth.uid()
  where class_code = (
    select c.class_code from classes c
    where c.teacher_user_id is null and lower(btrim(c.teacher_email)) = lower(my_email)
    order by c.created_at
    limit 1
  );
end;
$$;
revoke execute on function public._claim_legacy_class() from public, anon, authenticated;

-- Teacher Login: returns the signed-in teacher's class, or no rows if
-- they haven't created one yet (the app then shows Create Account).
create or replace function public.teacher_get_my_class()
returns table (
  class_code text,
  teacher_name text,
  teacher_email text,
  school_name text,
  grade_subject text,
  teacher_class_name text,
  avatar_id text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'not_signed_in' using errcode = 'P0001';
  end if;
  perform public._claim_legacy_class();
  return query
    select c.class_code, c.teacher_name, c.teacher_email, c.school_name, c.grade_subject, c.teacher_class_name, c.avatar_id
    from classes c
    where c.teacher_user_id = auth.uid()
    limit 1;
end;
$$;

-- Teacher Create Account / any later edit of the class details. Creates
-- the teacher's class (with a server-generated random code) the first
-- time, updates it after that, and returns its class code either way.
-- The email always comes from the Google sign-in, never from the app.
create or replace function public.teacher_save_my_class(
  p_teacher_name text,
  p_school_name text,
  p_grade_subject text,
  p_teacher_class_name text,
  p_avatar_id text default null
) returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  my_email text := public._my_verified_email();
  code_chars constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  new_code text;
  existing_code text;
  rand bytea;
  i int;
begin
  if auth.uid() is null or my_email is null then
    raise exception 'not_signed_in' using errcode = 'P0001';
  end if;
  perform public._claim_legacy_class();

  select c.class_code into existing_code from classes c where c.teacher_user_id = auth.uid();
  if existing_code is not null then
    update classes set
      teacher_name = coalesce(nullif(btrim(p_teacher_name), ''), teacher_name),
      teacher_email = my_email,
      school_name = coalesce(nullif(btrim(p_school_name), ''), school_name),
      grade_subject = coalesce(nullif(btrim(p_grade_subject), ''), grade_subject),
      teacher_class_name = coalesce(nullif(btrim(p_teacher_class_name), ''), teacher_class_name),
      avatar_id = coalesce(nullif(btrim(p_avatar_id), ''), avatar_id)
    where class_code = existing_code;
    return existing_code;
  end if;

  loop
    rand := extensions.gen_random_bytes(6);
    new_code := '';
    for i in 0..5 loop
      new_code := new_code || substr(code_chars, (get_byte(rand, i) % 32) + 1, 1);
    end loop;
    exit when not exists (select 1 from classes where class_code = new_code);
  end loop;

  insert into classes (class_code, teacher_name, teacher_email, school_name, grade_subject, teacher_class_name, avatar_id, teacher_user_id)
  values (new_code, btrim(p_teacher_name), my_email, btrim(p_school_name), btrim(p_grade_subject), btrim(p_teacher_class_name), nullif(btrim(p_avatar_id), ''), auth.uid());
  return new_code;
end;
$$;

-- Teacher Dashboard / Leaderboard / Students list. Only the class's own
-- teacher gets rows back. Excludes device_id and student_pin.
create or replace function public.fetch_leaderboard(p_class_code text)
returns table (
  student_id uuid,
  player_name text,
  avatar_id text,
  unlocked_level int,
  player_coins int,
  completed_levels jsonb,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select s.student_id, s.player_name, s.avatar_id, s.unlocked_level, s.player_coins, s.completed_levels, s.updated_at
  from students s
  join classes c on c.class_code = s.class_code
  where auth.uid() is not null
    and c.teacher_user_id = auth.uid()
    and s.class_code = btrim(p_class_code)
  order by s.unlocked_level desc, s.player_coins desc;
$$;

-- delete_student_account was removed: no app screen used it.
drop function if exists public.delete_student_account(uuid, text);

-- Teacher functions: signed-in users only, never the anon key.
revoke execute on function public.teacher_get_my_class() from public, anon;
revoke execute on function public.teacher_save_my_class(text, text, text, text, text) from public, anon;
revoke execute on function public.fetch_leaderboard(text) from public, anon;
grant execute on function public.teacher_get_my_class() to authenticated;
grant execute on function public.teacher_save_my_class(text, text, text, text, text) to authenticated;
grant execute on function public.fetch_leaderboard(text) to authenticated;

-- ============================================
-- PUPIL FUNCTIONS (anon key)
-- ============================================

-- A pupil joining by class code, or the "Class Joined!" popup. Returns
-- only what the popup shows.
create or replace function public.find_class_by_code(p_class_code text)
returns table (
  class_code text,
  teacher_name text,
  teacher_class_name text,
  grade_subject text,
  school_name text,
  avatar_id text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select c.class_code, c.teacher_name, c.teacher_class_name, c.grade_subject, c.school_name, c.avatar_id
  from classes c
  where p_class_code is not null and btrim(p_class_code) <> '' and c.class_code = btrim(p_class_code)
  limit 1;
$$;

-- Pushes a pupil's local progress up for their teacher. device_id is the
-- random per-install id only that pupil's phone (and anyone who already
-- passed the PIN check) knows. If the row already has a PIN, the sync
-- must carry the same PIN, so knowing a device_id alone can't change a
-- pupil's PIN or move them to another class. Numbers are kept in range.
create or replace function public.sync_student_progress(
  p_device_id text,
  p_class_code text,
  p_player_name text,
  p_pin text,
  p_avatar_id text,
  p_unlocked_level int,
  p_player_coins int,
  p_completed_levels jsonb
) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  existing_pin text;
  row_exists boolean;
  pin_ok boolean;
  clean_level int := least(greatest(coalesce(p_unlocked_level, 1), 1), 31);
  clean_coins int := least(greatest(coalesce(p_player_coins, 0), 0), 1000000);
  clean_pin text := nullif(btrim(coalesce(p_pin, '')), '');
begin
  if p_device_id is null or btrim(p_device_id) = '' then
    return;
  end if;
  if p_class_code is null or not exists (select 1 from classes where class_code = btrim(p_class_code)) then
    return;
  end if;

  select true, s.student_pin into row_exists, existing_pin
  from students s where s.device_id = btrim(p_device_id);

  if row_exists then
    pin_ok := existing_pin is null
      or (clean_pin is not null and existing_pin = extensions.crypt(clean_pin, existing_pin));
    if not pin_ok then
      raise exception 'pin_mismatch' using errcode = 'P0001';
    end if;
    update students set
      class_code = btrim(p_class_code),
      player_name = coalesce(nullif(btrim(p_player_name), ''), 'Student'),
      student_pin = case when existing_pin is null and clean_pin is not null
                         then extensions.crypt(clean_pin, extensions.gen_salt('bf'))
                         else existing_pin end,
      avatar_id = p_avatar_id,
      unlocked_level = clean_level,
      player_coins = clean_coins,
      completed_levels = coalesce(p_completed_levels, '{}'::jsonb),
      updated_at = now()
    where device_id = btrim(p_device_id);
  else
    insert into students (device_id, class_code, player_name, student_pin, avatar_id, unlocked_level, player_coins, completed_levels, updated_at)
    values (
      btrim(p_device_id), btrim(p_class_code),
      coalesce(nullif(btrim(p_player_name), ''), 'Student'),
      case when clean_pin is null then null else extensions.crypt(clean_pin, extensions.gen_salt('bf')) end,
      p_avatar_id, clean_level, clean_coins, coalesce(p_completed_levels, '{}'::jsonb), now()
    );
  end if;
end;
$$;

-- Standalone "Log In" screen: look up an account by name + PIN across all
-- classes. Rate-limited. Can match more than one row if the same name+PIN
-- exists in two classes - the app handles that "ambiguous" case.
create or replace function public.find_student_account(p_player_name text, p_pin text)
returns table (
  student_id uuid,
  device_id text,
  class_code text,
  player_name text,
  avatar_id text,
  unlocked_level int,
  player_coins int,
  completed_levels jsonb
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  bucket text := public._name_bucket(p_player_name);
  found_any boolean := false;
begin
  if p_player_name is null or btrim(p_player_name) = '' or p_pin is null or btrim(p_pin) = '' then
    return;
  end if;
  perform public._check_login_limit(bucket);
  for student_id, device_id, class_code, player_name, avatar_id, unlocked_level, player_coins, completed_levels in
    select s.student_id, s.device_id, s.class_code, s.player_name, s.avatar_id, s.unlocked_level, s.player_coins, s.completed_levels
    from students s
    where s.player_name = btrim(p_player_name)
      and s.student_pin is not null
      and s.student_pin = extensions.crypt(btrim(p_pin), s.student_pin)
    limit 5
  loop
    found_any := true;
    return next;
  end loop;
  if found_any then
    perform public._clear_login_failures(bucket);
  else
    perform public._record_login_failure(bucket);
  end if;
end;
$$;

-- Right after a pupil types a class code: is this name+PIN already a
-- student of THIS class (restore them) or new (register them)? Shares the
-- same per-name limit as find_student_account. A miss here is usually a
-- brand-new pupil, but it still counts, because to an attacker it is just
-- another PIN guess.
create or replace function public.find_student_in_class(p_class_code text, p_player_name text, p_pin text)
returns table (
  student_id uuid,
  device_id text,
  class_code text,
  player_name text,
  avatar_id text,
  unlocked_level int,
  player_coins int,
  completed_levels jsonb
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  bucket text := public._name_bucket(p_player_name);
  name_taken boolean;
begin
  if p_class_code is null or btrim(p_class_code) = '' or p_player_name is null or btrim(p_player_name) = ''
     or p_pin is null or btrim(p_pin) = '' then
    return;
  end if;
  perform public._check_login_limit(bucket);
  return query
    select s.student_id, s.device_id, s.class_code, s.player_name, s.avatar_id, s.unlocked_level, s.player_coins, s.completed_levels
    from students s
    where s.class_code = btrim(p_class_code)
      and s.player_name = btrim(p_player_name)
      and s.student_pin is not null
      and s.student_pin = extensions.crypt(btrim(p_pin), s.student_pin)
    limit 1;
  if found then
    perform public._clear_login_failures(bucket);
    return;
  end if;
  -- Only a wrong PIN for a name that already exists in this class is a
  -- failed guess. A new pupil registering a new name isn't.
  select exists (
    select 1 from students s
    where s.class_code = btrim(p_class_code) and s.player_name = btrim(p_player_name)
  ) into name_taken;
  if name_taken then
    perform public._record_login_failure(bucket);
  end if;
end;
$$;

-- Re-points an existing pupil row at a new phone's device_id. Needs the
-- pupil's PIN (and is rate-limited like every other PIN check), so a
-- student_id alone is no longer enough to take over an account.
create or replace function public.claim_student_account(p_student_id uuid, p_pin text, p_new_device_id text)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  stored_pin text;
  stored_name text;
  bucket text;
  affected int;
begin
  if p_student_id is null or p_new_device_id is null or btrim(p_new_device_id) = ''
     or p_pin is null or btrim(p_pin) = '' then
    return false;
  end if;
  select s.student_pin, s.player_name into stored_pin, stored_name from students s where s.student_id = p_student_id;
  if stored_name is null then
    return false;
  end if;
  bucket := public._name_bucket(stored_name);
  perform public._check_login_limit(bucket);
  if stored_pin is null or stored_pin <> extensions.crypt(btrim(p_pin), stored_pin) then
    perform public._record_login_failure(bucket);
    return false;
  end if;
  update students set device_id = btrim(p_new_device_id) where student_id = p_student_id;
  get diagnostics affected = row_count;
  return affected > 0;
end;
$$;

revoke execute on function public.find_class_by_code(text) from public;
revoke execute on function public.sync_student_progress(text, text, text, text, text, int, int, jsonb) from public;
revoke execute on function public.find_student_account(text, text) from public;
revoke execute on function public.find_student_in_class(text, text, text) from public;
revoke execute on function public.claim_student_account(uuid, text, text) from public;
grant execute on function public.find_class_by_code(text) to anon, authenticated;
grant execute on function public.sync_student_progress(text, text, text, text, text, int, int, jsonb) to anon, authenticated;
grant execute on function public.find_student_account(text, text) to anon, authenticated;
grant execute on function public.find_student_in_class(text, text, text) to anon, authenticated;
grant execute on function public.claim_student_account(uuid, text, text) to anon, authenticated;

-- ============================================
-- ONE-TIME MIGRATION
-- ============================================
-- Hash any PIN that's still plain text (bcrypt hashes start with
-- $2a$/$2b$/$2y$, so this only touches raw PINs - safe to re-run).
update students
set student_pin = extensions.crypt(student_pin, extensions.gen_salt('bf'))
where student_pin is not null
  and student_pin <> ''
  and student_pin !~ '^\$2[aby]\$';

notify pgrst, 'reload schema';
