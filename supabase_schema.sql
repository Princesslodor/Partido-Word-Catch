-- Partido Word Catch — Supabase schema
-- Run this once in your Supabase project's SQL Editor (Project > SQL Editor > New query).

create table if not exists classes (
  class_code text primary key,
  teacher_name text,
  school_name text,
  grade_subject text,
  teacher_class_name text,
  created_at timestamptz default now()
);

create table if not exists students (
  student_id uuid primary key default gen_random_uuid(),
  class_code text references classes(class_code) on delete cascade,
  device_id text unique,
  player_name text not null default 'Student',
  avatar_id text,
  unlocked_level int default 1,
  player_coins int default 0,
  completed_levels jsonb default '{}'::jsonb,
  updated_at timestamptz default now()
);

-- No real accounts/login exist in the app yet (just class codes), so this
-- uses simple open policies scoped to the anon key rather than per-user auth.
-- Anyone with the anon key can read/write — acceptable for a classroom tool,
-- but note this if the app ever needs stronger data protection later.
alter table classes enable row level security;
alter table students enable row level security;

create policy "anon full access" on classes for all using (true) with check (true);
create policy "anon full access" on students for all using (true) with check (true);
