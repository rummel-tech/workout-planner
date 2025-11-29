-- Morning Routine Table
create table if not exists morning_routine (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  weight_lbs numeric,
  meditation_min numeric,
  movement text,
  notes text,
  hrv numeric,
  resting_hr numeric,
  sleep_hours numeric,
  created_at timestamptz default now()
);
