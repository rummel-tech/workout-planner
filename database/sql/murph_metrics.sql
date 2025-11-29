create table murph_metrics (
  id bigserial primary key,
  user_id uuid references users(id),
  workout_id bigint references workouts_processed(id),

  run_1_time_seconds integer,
  run_2_time_seconds integer,
  partition text,
  total_time_seconds integer,
  vest_weight numeric,
  notes text,

  created_at timestamptz default now()
);
