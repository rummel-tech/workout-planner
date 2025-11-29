create table daily_plans (
  id bigserial primary key,
  user_id uuid references users(id) on delete cascade,
  date date not null,

  plan_json jsonb, -- warmup, main set, cooldown, notes
  ai_notes text,
  status text default 'pending', -- pending, complete, skipped

  unique(user_id, date)
);

create index on daily_plans(user_id);

