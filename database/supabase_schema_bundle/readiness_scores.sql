-- Readiness Scores Table
create table if not exists readiness_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  readiness numeric,
  details jsonb,
  created_at timestamptz default now()
);
