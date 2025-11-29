create table strength_metrics (
  id bigserial primary key,
  user_id uuid references users(id),
  date date,
  
  lift text,        -- squat
  weight numeric,
  reps integer,
  set_number integer,
  estimated_1rm numeric,
  velocity_m_per_s numeric,

  unique(user_id, date, lift, set_number)
);
