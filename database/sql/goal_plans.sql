create table goal_plans (
  id bigserial primary key,
  goal_id bigint references user_goals(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  name text not null,
  description text,
  status text default 'active' check (status in ('active', 'completed', 'archived'))
);

create index on goal_plans(goal_id);
create index on goal_plans(user_id);

-- Trigger to auto-update updated_at
create or replace function update_goal_plans_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger goal_plans_updated_at_trigger
  before update on goal_plans
  for each row
  execute function update_goal_plans_updated_at();
