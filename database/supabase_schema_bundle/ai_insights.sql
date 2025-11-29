-- AI Insights Table
create table if not exists ai_insights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  summary text,
  recommendations jsonb,
  created_at timestamptz default now()
);
