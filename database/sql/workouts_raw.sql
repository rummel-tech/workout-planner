create table workouts_raw (
  id bigserial primary key,
  user_id uuid references users(id) on delete cascade,
  created_at timestamptz default now(),

  source text, -- healthkit / watchkit / manual
  workout_type text,
  start_time timestamptz,
  end_time timestamptz,
  duration_seconds integer,
  calories numeric,
  distance_meters numeric,

  raw_json jsonb -- full unmodified data
);

create index on workouts_raw(user_id);
create index on workouts_raw(start_time);
