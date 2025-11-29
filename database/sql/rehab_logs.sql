create table rehab_logs (
  id bigserial primary key,
  user_id uuid references users(id),
  created_at timestamptz default now(),

  movement text,   -- external rotation, abduction, scapular control, etc
  reps integer,
  weight numeric,
  pain_score integer,  -- 0–10
  notes text
);

create index on rehab_logs(user_id);
