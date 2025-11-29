create table weekly_plans (
  id bigserial primary key,
  user_id uuid references users(id) on delete cascade,
  week_start date not null,

  focus text,      -- strength, swim, murph, rehab, deload
  goals jsonb,     -- squat target, swim intervals, etc
  plan_json jsonb, -- daily breakdown

  unique(user_id, week_start)
);
