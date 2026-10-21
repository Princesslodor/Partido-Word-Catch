-- Partido Word Catch — Supabase schema
-- Run this once in your Supabase project's SQL Editor (Project > SQL Editor > New query).

create table if not exists classes (
  class_code text primary key,
  teacher_name text,
  teacher_email text,
  school_name text,
  grade_subject text,
  teacher_class_name text,
  avatar_id text,
  teacher_user_id uuid,
  created_at timestamptz default now()
);

-- Safe to re-run: adds the column if this table already existed without it.
alter table classes add column if not exists teacher_email text;

-- Safe to re-run: adds the column if this table already existed without it -
-- lets the "Class Joined!" popup show the teacher's own chosen avatar
-- instead of a hardcoded placeholder.
alter table classes add column if not exists avatar_id text;

-- Safe to re-run: the Supabase Auth user (Continue with Google) who owns
-- this class. Only that teacher can see the class's students.
alter table classes add column if not exists teacher_user_id uuid;
create unique index if not exists classes_teacher_user_id_key on classes (teacher_user_id);

-- Supabase's REST API (PostgREST) caches the table schema and doesn't
-- always notice a plain ALTER TABLE right away - this tells it to reload,
-- otherwise requests mentioning the new column can fail with a 400
-- "Could not find the 'teacher_email' column ... in the schema cache".
notify pgrst, 'reload schema';

create table if not exists students (
  student_id uuid primary key default gen_random_uuid(),
  class_code text references classes(class_code) on delete cascade,
  device_id text unique,
  player_name text not null default 'Student',
  student_pin text,
  avatar_id text,
  unlocked_level int default 1,
  player_coins int default 0,
  completed_levels jsonb default '{}'::jsonb,
  updated_at timestamptz default now()
);

-- Safe to re-run: adds the column if this table already existed without it -
-- needed so a student can log into their existing account on a different
-- device (class code + name + PIN), instead of the account being locked to
-- whichever device first registered it.
alter table students add column if not exists student_pin text;
notify pgrst, 'reload schema';

-- Row Level Security is ON with NO policies, so the anon/publishable key
-- (which ships inside the app) cannot read or write either table directly.
-- All access goes through the Postgres functions in supabase_hardening.sql -
-- run that file right after this one. Never add a "using (true)" policy
-- here: that would expose every pupil's name and progress and every
-- teacher's email to anyone holding the public key.
alter table classes enable row level security;
alter table students enable row level security;
drop policy if exists "anon full access" on classes;
drop policy if exists "anon full access" on students;
