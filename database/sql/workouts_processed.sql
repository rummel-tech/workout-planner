create table workouts_processed (
  id bigserial primary key,
  raw_id bigint references workouts_raw(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  created_at timestamptz default now(),

  workout_category text, -- "swim_interval", "strength", "mobility", "run", "murph_partition"
  perceived_intensity integer,
  load_score numeric,
  training_zone text,  -- z1/z2/z3 etc
  key_metrics jsonb,   -- stroke rate / watts / rep velocity / etc

  ai_summary text,
  tags text[]
);

create index on workouts_processed(user_id);
create index on workouts_processed(raw_id);
