create table readiness_scores (
  id bigserial primary key,
  user_id uuid references users(id) on delete cascade,
  date date not null,

  readiness numeric,      -- 0–1 or 0–100
  recovery_level text,    -- "recovery", "moderate", "high"
  limiting_factor text,   -- "sleep", "HRV", "fatigue", "stress"
  notes text,

  unique(user_id, date)
);
