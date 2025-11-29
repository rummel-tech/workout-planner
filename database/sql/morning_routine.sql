create table morning_routine (
  id bigserial primary key,
  user_id uuid references users(id),
  date date not null,

  meditation_minutes integer,
  movement_minutes integer,
  tracking_complete boolean,
  energy_level integer,
  focus_level integer,

  unique(user_id, date)
);
