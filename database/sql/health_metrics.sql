create table health_metrics (
  id bigserial primary key,
  user_id uuid references users(id) on delete cascade,
  date date not null,

  hrv_ms numeric,
  resting_hr integer,
  vo2max numeric,
  sleep_hours numeric,
  weight_kg numeric,
  rpe integer,
  soreness integer,
  mood integer, 

  unique(user_id, date)
);

create index on health_metrics(user_id);
create index on health_metrics(date);
