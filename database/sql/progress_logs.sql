create table progress_logs (
  id bigserial primary key,
  user_id uuid references users(id),
  created_at timestamptz default now(),
  
  period text,       -- daily, weekly, monthly
  summary text,
  insights jsonb,    -- trends in HRV, pace, strength
  recommendations jsonb
);
