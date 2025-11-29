-- Weekly Plans Table
create table if not exists weekly_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  plan jsonb,
  created_at timestamptz default now()
);
