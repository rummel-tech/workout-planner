create table swim_metrics (
  id bigserial primary key,
  user_id uuid references users(id),
  workout_id bigint references workouts_processed(id),

  distance_meters numeric,
  avg_pace_seconds numeric,
  pace_curve jsonb,
  stroke_rate numeric,
  heart_rate_curve jsonb,
  water_type text, -- pool or open_water

  created_at timestamptz default now()
);
