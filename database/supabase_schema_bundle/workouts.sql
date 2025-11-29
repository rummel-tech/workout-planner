-- Workouts Table
create table if not exists workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  source text not null, -- healthkit, manual, workoutkit
  type text,
  start_time timestamptz,
  end_time timestamptz,
  calories numeric,
  distance_m numeric,
  raw jsonb,
  created_at timestamptz default now()
);
