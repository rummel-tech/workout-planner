create table users (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  name text,
  email text unique,
  apple_id text unique,
  timezone text default 'America/Chicago',
  birthdate date,
  sex text,
  height_cm numeric,
  weight_kg numeric,
  profile_image_url text
);
