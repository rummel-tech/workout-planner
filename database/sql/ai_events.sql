create table ai_events (
  id bigserial primary key,
  user_id uuid references users(id),
  created_at timestamptz default now(),

  event_type text, -- daily_plan, weekly_plan, feedback, sync
  input jsonb,
  output jsonb,
  cost numeric      -- token cost
);
