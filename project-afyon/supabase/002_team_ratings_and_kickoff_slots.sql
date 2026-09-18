-- Project Afyon Online
-- 002_team_ratings_and_kickoff_slots.sql
-- Three-line club identity + shared evening matchday timetable.

alter table public.clubs
  add column if not exists attack smallint not null default 70 check (attack between 40 and 99),
  add column if not exists midfield smallint not null default 70 check (midfield between 40 and 99),
  add column if not exists defense smallint not null default 70 check (defense between 40 and 99),
  add column if not exists style text not null default 'Dengeli';

alter table public.clubs
  add column if not exists overall numeric(5,2)
  generated always as (round((attack + midfield + defense)::numeric / 3, 2)) stored;

alter table public.matches
  add column if not exists kickoff_at timestamptz;

create index if not exists matches_kickoff_at_idx
  on public.matches(kickoff_at);

create table if not exists public.kickoff_slots (
  country text not null,
  league_level smallint not null check (league_level between 1 and 5),
  local_time time not null,
  timezone text not null default 'Europe/Istanbul',
  primary key (country, league_level)
);

alter table public.kickoff_slots enable row level security;

drop policy if exists "kickoff_slots_public_read" on public.kickoff_slots;
create policy "kickoff_slots_public_read"
on public.kickoff_slots for select
to anon, authenticated
using (true);

-- 1 real day = 1 Project Afyon week.
-- League 5 starts one hour before that country's League 1;
-- the five tiers are staggered by 15 minutes.
insert into public.kickoff_slots (country, league_level, local_time, timezone) values
  ('Avusturya',5,'18:00','Europe/Istanbul'),
  ('Avusturya',4,'18:15','Europe/Istanbul'),
  ('Avusturya',3,'18:30','Europe/Istanbul'),
  ('Avusturya',2,'18:45','Europe/Istanbul'),
  ('Avusturya',1,'19:00','Europe/Istanbul'),

  ('İskoçya',5,'18:15','Europe/Istanbul'),
  ('İskoçya',4,'18:30','Europe/Istanbul'),
  ('İskoçya',3,'18:45','Europe/Istanbul'),
  ('İskoçya',2,'19:00','Europe/Istanbul'),
  ('İskoçya',1,'19:15','Europe/Istanbul'),

  ('Belçika',5,'18:30','Europe/Istanbul'),
  ('Belçika',4,'18:45','Europe/Istanbul'),
  ('Belçika',3,'19:00','Europe/Istanbul'),
  ('Belçika',2,'19:15','Europe/Istanbul'),
  ('Belçika',1,'19:30','Europe/Istanbul'),

  ('Hollanda',5,'18:45','Europe/Istanbul'),
  ('Hollanda',4,'19:00','Europe/Istanbul'),
  ('Hollanda',3,'19:15','Europe/Istanbul'),
  ('Hollanda',2,'19:30','Europe/Istanbul'),
  ('Hollanda',1,'19:45','Europe/Istanbul'),

  ('Türkiye',5,'19:00','Europe/Istanbul'),
  ('Türkiye',4,'19:15','Europe/Istanbul'),
  ('Türkiye',3,'19:30','Europe/Istanbul'),
  ('Türkiye',2,'19:45','Europe/Istanbul'),
  ('Türkiye',1,'20:00','Europe/Istanbul'),

  ('İngiltere',5,'19:15','Europe/Istanbul'),
  ('İngiltere',4,'19:30','Europe/Istanbul'),
  ('İngiltere',3,'19:45','Europe/Istanbul'),
  ('İngiltere',2,'20:00','Europe/Istanbul'),
  ('İngiltere',1,'20:15','Europe/Istanbul'),

  ('İspanya',5,'19:30','Europe/Istanbul'),
  ('İspanya',4,'19:45','Europe/Istanbul'),
  ('İspanya',3,'20:00','Europe/Istanbul'),
  ('İspanya',2,'20:15','Europe/Istanbul'),
  ('İspanya',1,'20:30','Europe/Istanbul'),

  ('Almanya',5,'19:45','Europe/Istanbul'),
  ('Almanya',4,'20:00','Europe/Istanbul'),
  ('Almanya',3,'20:15','Europe/Istanbul'),
  ('Almanya',2,'20:30','Europe/Istanbul'),
  ('Almanya',1,'20:45','Europe/Istanbul'),

  ('İtalya',5,'20:00','Europe/Istanbul'),
  ('İtalya',4,'20:15','Europe/Istanbul'),
  ('İtalya',3,'20:30','Europe/Istanbul'),
  ('İtalya',2,'20:45','Europe/Istanbul'),
  ('İtalya',1,'21:00','Europe/Istanbul'),

  ('Fransa',5,'20:15','Europe/Istanbul'),
  ('Fransa',4,'20:30','Europe/Istanbul'),
  ('Fransa',3,'20:45','Europe/Istanbul'),
  ('Fransa',2,'21:00','Europe/Istanbul'),
  ('Fransa',1,'21:15','Europe/Istanbul'),

  ('Portekiz',5,'20:30','Europe/Istanbul'),
  ('Portekiz',4,'20:45','Europe/Istanbul'),
  ('Portekiz',3,'21:00','Europe/Istanbul'),
  ('Portekiz',2,'21:15','Europe/Istanbul'),
  ('Portekiz',1,'21:30','Europe/Istanbul'),

  ('Yunanistan',5,'20:45','Europe/Istanbul'),
  ('Yunanistan',4,'21:00','Europe/Istanbul'),
  ('Yunanistan',3,'21:15','Europe/Istanbul'),
  ('Yunanistan',2,'21:30','Europe/Istanbul'),
  ('Yunanistan',1,'21:45','Europe/Istanbul')
on conflict (country, league_level)
do update set
  local_time = excluded.local_time,
  timezone = excluded.timezone;
