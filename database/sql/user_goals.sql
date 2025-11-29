create table user_goals (
  id bigserial primary key,
  user_id uuid references users(id) on delete cascade,
  created_at timestamptz default now(),

  goal_type text check (goal_type in (
    'squat_350',
    'murph',
    'alcatraz_swim',
    '40_min_mile_swim',
    'shoulder_rehab',
    'weight_loss',
    'weight_gain',
    'general_fitness',
    'custom'
  )),

  target_value numeric,
  target_date date,
  notes text,
  is_active boolean default true
);

create index on user_goals(user_id);
