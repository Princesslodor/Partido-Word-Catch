-- Partido Word Catch — security hardening
-- Run this ONCE in the Supabase SQL Editor, AFTER supabase_schema.sql has
-- already been run at least once. Safe to re-run (every statement below is
-- idempotent).
--
-- WHAT THIS FIXES
-- supabase_schema.sql created a policy - "anon full access", using (true) -
-- that lets ANYONE holding the project's anon/publishable key read or
-- write every row of `classes` and `students`, with no restriction to a
-- single class or student. That key is not a secret (it's meant to sit in
-- the client and is committed in this repo's SyncManager.gd), so in
-- practice this means the full students table - names, four-digit PINs,
-- progress - and the full classes table - teachers' names and emails - is
-- readable by anyone who finds the key, with no need to reverse-engineer
-- the APK.
--
-- THE FIX
-- 1. Drop the open policies. Row Level Security stays ON with NO policies,
--    which makes Postgres deny all direct table access to the `anon` role
--    by default.
-- 2. Add one Postgres function per operation the app actually needs
--    (join by class code, log in by name+PIN, sync progress, teacher
--    dashboard/leaderboard, ...), each SECURITY DEFINER so it can read/
--    write the tables internally despite the now-locked-down RLS, but each
--    one only exposes the exact narrow slice of data that operation needs
--    - never teacher_email, never student_pin - back to the caller.
-- 3. Grant EXECUTE on just those functions to `anon`, so the app calls
--    them via Supabase's normal /rest/v1/rpc/<function_name> endpoint
--    instead of querying the tables directly.
-- 4. Hash student_pin with bcrypt (via pgcrypto) instead of storing it as
--    plain text, both for new rows going forward and for the rows that
--    already exist. A pupil's PIN is still checked by the correct
--    function, it's just never stored or returned in plain text again.
--
-- Nothing about how the app behaves changes - same class codes, same
-- name+PIN login, same Teacher Dashboard and Leaderboard. Only
-- SyncManager.gd's internals change to call these functions instead of
-- querying the tables directly; every other script is untouched.

create extension if not exists pgcrypto;

-- 1) Lock the tables down: remove the open policies and add nothing back
-- in their place, so direct table access from the anon key is denied.
drop policy if exists "anon full access" on classes;
drop policy if exists "anon full access" on students;

-- 2) One function per operation, each returning only what its caller needs.

-- Teacher registers/edits their class. Mirrors the old
-- "POST /classes?on_conflict=class_code" upsert.
create or replace function public.upsert_class(
  p_class_code text,
  p_teacher_name text,
  p_teacher_email text,
  p_school_name text,
  p_grade_subject text,
  p_teacher_class_name text,
  p_avatar_id text default ''
) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if p_class_code is null or btrim(p_class_code) = '' then
    return;
  end if;
  insert into classes (class_code, teacher_name, teacher_email, school_name, grade_subject, teacher_class_name, avatar_id)
  values (btrim(p_class_code), p_teacher_name, p_teacher_email, p_school_name, p_grade_subject, p_teacher_class_name, p_avatar_id)
  on conflict (class_code) do update set
    teacher_name = excluded.teacher_name,
    teacher_email = excluded.teacher_email,
    school_name = excluded.school_name,
    grade_subject = excluded.grade_subject,
    teacher_class_name = excluded.teacher_class_name,
    avatar_id = excluded.avatar_id;
end;
$$;
grant execute on function public.upsert_class(text, text, text, text, text, text, text) to anon;

-- A pupil joining by class code, or the "Class Joined!" popup re-reading
-- the class's info. Deliberately excludes teacher_email - nothing in the
-- app ever needs to show it back.
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
security definer
set search_path = public, pg_temp
as $$
  select c.class_code, c.teacher_name, c.teacher_class_name, c.grade_subject, c.school_name, c.avatar_id
  from classes c
  where p_class_code is not null and btrim(p_class_code) <> '' and c.class_code = btrim(p_class_code)
  limit 1;
$$;
grant execute on function public.find_class_by_code(text) to anon;

-- Teacher Login screen, by the email the teacher typed. Same excluded
-- column, same reasoning - the teacher already knows their own email.
create or replace function public.find_class_by_email(p_teacher_email text)
returns table (
  class_code text,
  teacher_name text,
  teacher_class_name text,
  grade_subject text,
  school_name text,
  avatar_id text
)
language sql
security definer
set search_path = public, pg_temp
as $$
  select c.class_code, c.teacher_name, c.teacher_class_name, c.grade_subject, c.school_name, c.avatar_id
  from classes c
  where p_teacher_email is not null and btrim(p_teacher_email) <> '' and c.teacher_email = btrim(p_teacher_email)
  limit 1;
$$;
grant execute on function public.find_class_by_email(text) to anon;

-- Pushes a Student's local progress up for the Teacher Dashboard/
-- Leaderboard to see. The PIN is hashed here, on write, with bcrypt - it
-- is never stored or read back as plain text again. If a sync happens to
-- carry an empty PIN, the existing hash is left alone rather than wiped.
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
begin
  if p_device_id is null or btrim(p_device_id) = '' then
    return;
  end if;
  insert into students (device_id, class_code, player_name, student_pin, avatar_id, unlocked_level, player_coins, completed_levels, updated_at)
  values (
    btrim(p_device_id), p_class_code,
    coalesce(nullif(p_player_name, ''), 'Student'),
    case when p_pin is null or btrim(p_pin) = '' then null else crypt(btrim(p_pin), gen_salt('bf')) end,
    p_avatar_id, p_unlocked_level, p_player_coins, p_completed_levels, now()
  )
  on conflict (device_id) do update set
    class_code = excluded.class_code,
    player_name = excluded.player_name,
    student_pin = coalesce(excluded.student_pin, students.student_pin),
    avatar_id = excluded.avatar_id,
    unlocked_level = excluded.unlocked_level,
    player_coins = excluded.player_coins,
    completed_levels = excluded.completed_levels,
    updated_at = now();
end;
$$;
grant execute on function public.sync_student_progress(text, text, text, text, text, int, int, jsonb) to anon;

-- Standalone "Log In" screen: look up an existing account by name+PIN
-- across ALL classes (a pupil belongs to exactly one class, so this alone
-- is enough to find it). Can match more than one row if the same name+PIN
-- happens to exist in two different classes - the caller (SyncManager.gd)
-- already handles that "ambiguous" case exactly as before.
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
language sql
security definer
set search_path = public, pg_temp
as $$
  select s.student_id, s.device_id, s.class_code, s.player_name, s.avatar_id, s.unlocked_level, s.player_coins, s.completed_levels
  from students s
  where p_player_name is not null and btrim(p_player_name) <> ''
    and p_pin is not null and btrim(p_pin) <> ''
    and s.player_name = btrim(p_player_name)
    and s.student_pin is not null
    and s.student_pin = crypt(btrim(p_pin), s.student_pin)
  limit 5;
$$;
grant execute on function public.find_student_account(text, text) to anon;

-- Right after a pupil types a class code: is this name+PIN already a
-- student of THIS class (restore them) or brand new (register them)?
-- Scoped to one class, so no ambiguity handling is needed here.
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
language sql
security definer
set search_path = public, pg_temp
as $$
  select s.student_id, s.device_id, s.class_code, s.player_name, s.avatar_id, s.unlocked_level, s.player_coins, s.completed_levels
  from students s
  where p_class_code is not null and btrim(p_class_code) <> ''
    and p_player_name is not null and btrim(p_player_name) <> ''
    and p_pin is not null and btrim(p_pin) <> ''
    and s.class_code = btrim(p_class_code)
    and s.player_name = btrim(p_player_name)
    and s.student_pin is not null
    and s.student_pin = crypt(btrim(p_pin), s.student_pin)
  limit 1;
$$;
grant execute on function public.find_student_in_class(text, text, text) to anon;

-- Re-points an existing student row at a new device_id after a name+PIN
-- match already succeeded (find_student_account / find_student_in_class),
-- so logging into an account on a different phone doesn't create a
-- duplicate row. No PIN re-check here, same as the original REST version -
-- the caller only reaches this after a successful lookup already verified it.
create or replace function public.claim_student_account(p_student_id uuid, p_new_device_id text)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  affected int;
begin
  if p_student_id is null or p_new_device_id is null or btrim(p_new_device_id) = '' then
    return false;
  end if;
  update students
  set device_id = btrim(p_new_device_id)
  where student_id = p_student_id;
  get diagnostics affected = row_count;
  return affected > 0;
end;
$$;
grant execute on function public.claim_student_account(uuid, text) to anon;

-- Teacher Dashboard / Leaderboard / Students list for one class. Excludes
-- device_id and student_pin - the dashboard never needs either.
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
security definer
set search_path = public, pg_temp
as $$
  select s.student_id, s.player_name, s.avatar_id, s.unlocked_level, s.player_coins, s.completed_levels, s.updated_at
  from students s
  where p_class_code is not null and btrim(p_class_code) <> '' and s.class_code = btrim(p_class_code)
  order by s.unlocked_level desc, s.player_coins desc;
$$;
grant execute on function public.fetch_leaderboard(text) to anon;

-- 4) One-time migration: hash any PIN that's still plain text (bcrypt
-- hashes always start with $2a$/$2b$/$2y$, so this only touches rows that
-- genuinely still have a raw 4-digit PIN - safe to re-run).
update students
set student_pin = crypt(student_pin, gen_salt('bf'))
where student_pin is not null
  and student_pin <> ''
  and student_pin !~ '^\$2[aby]\$';
