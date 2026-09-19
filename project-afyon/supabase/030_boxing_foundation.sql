-- Project Afyon 0.50 — Boxing foundation
-- Permanent boxing career table: no league season, no weekly points.
-- Rankings are persistent career rankings and records grow over time.

create table if not exists public.boxing_fighters (
  id text primary key,
  name text not null,
  country text not null,
  weight_class text not null check (weight_class in ('LIGHTWEIGHT','WELTERWEIGHT','MIDDLEWEIGHT','LIGHT_HEAVYWEIGHT','HEAVYWEIGHT')),
  style text not null,
  power smallint not null check (power between 20 and 99),
  speed smallint not null check (speed between 20 and 99),
  defense smallint not null check (defense between 20 and 99),
  chin smallint not null check (chin between 20 and 99),
  stamina smallint not null check (stamina between 20 and 99),
  rating numeric(5,2) not null check (rating between 20 and 99),
  wins integer not null default 0 check (wins >= 0),
  losses integer not null default 0 check (losses >= 0),
  draws integer not null default 0 check (draws >= 0),
  kos integer not null default 0 check (kos >= 0 and kos <= wins),
  streak_type text check (streak_type in ('W','L','D')),
  streak_count integer not null default 0 check (streak_count >= 0),
  is_active boolean not null default true,
  seed integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(weight_class,name)
);

create table if not exists public.boxing_bouts (
  id text primary key,
  event_name text not null,
  scheduled_at timestamptz not null,
  weight_class text not null check (weight_class in ('LIGHTWEIGHT','WELTERWEIGHT','MIDDLEWEIGHT','LIGHT_HEAVYWEIGHT','HEAVYWEIGHT')),
  red_fighter_id text not null references public.boxing_fighters(id),
  blue_fighter_id text not null references public.boxing_fighters(id),
  status text not null default 'scheduled' check (status in ('scheduled','live','finished','cancelled')),
  winner_id text references public.boxing_fighters(id),
  method text check (method in ('KO','TKO','UD','SD','MD','DRAW')),
  finish_round smallint check (finish_round between 1 and 12),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (red_fighter_id <> blue_fighter_id)
);

alter table public.boxing_fighters enable row level security;
alter table public.boxing_bouts enable row level security;

drop policy if exists boxing_fighters_public_read on public.boxing_fighters;
create policy boxing_fighters_public_read
on public.boxing_fighters
for select
to anon,authenticated
using (true);

drop policy if exists boxing_bouts_public_read on public.boxing_bouts;
create policy boxing_bouts_public_read
on public.boxing_bouts
for select
to anon,authenticated
using (true);

insert into public.boxing_fighters(
  id,name,country,weight_class,style,power,speed,defense,chin,stamina,rating,
  wins,losses,draws,kos,streak_type,streak_count,seed
) values
  ('BX|LW|T0','Luca Ferretti','İtalya','LIGHTWEIGHT','Teknik Boksör',76,88,86,74,85,85,9,1,0,5,'W',4,0),
  ('BX|LW|T1','Tiago Varela','Portekiz','LIGHTWEIGHT','Kontra Boksör',78,85,82,76,84,83,10,2,0,6,'W',2,1),
  ('BX|LW|T2','Callum Reed','İngiltere','LIGHTWEIGHT','Tempo Boksörü',74,87,78,75,88,80,8,2,0,4,'W',1,2),
  ('BX|LW|T3','Nikos Argyros','Yunanistan','LIGHTWEIGHT','Baskıcı',81,78,74,80,82,78,7,3,0,5,'L',1,3),
  ('BX|LW|T4','Bram Vos','Hollanda','LIGHTWEIGHT','Dengeli',72,82,81,77,80,77,6,2,1,2,'D',1,4),

  ('BX|WW|T0','Diego Serrano','İspanya','WELTERWEIGHT','Boxer-Puncher',84,86,83,81,87,88,10,1,0,5,'W',5,10),
  ('BX|WW|T1','Liam Kavanagh','İskoçya','WELTERWEIGHT','Baskıcı',86,80,78,84,86,84,9,2,0,4,'W',2,11),
  ('BX|WW|T2','Emre Emiroğlu','Türkiye','WELTERWEIGHT','Kontra Boksör',80,86,84,79,85,83,8,2,0,3,'W',3,12),
  ('BX|WW|T3','Jules Mercier','Fransa','WELTERWEIGHT','Teknik Boksör',76,85,85,75,82,80,7,2,1,2,'D',1,13),
  ('BX|WW|T4','Pieter De Smet','Belçika','WELTERWEIGHT','Dengeli',79,79,80,82,80,77,6,3,0,3,'L',1,14),

  ('BX|MW|T0','Atlas Parsak','Türkiye','MIDDLEWEIGHT','Boxer-Puncher',87,84,83,86,88,89,9,1,0,6,'W',5,20),
  ('BX|MW|T1','Jonas Falk','Almanya','MIDDLEWEIGHT','Teknik Boksör',82,83,87,84,86,87,10,2,0,5,'W',3,21),
  ('BX|MW|T2','Marco Bellini','İtalya','MIDDLEWEIGHT','Baskıcı',86,79,78,85,84,83,8,2,0,5,'W',2,22),
  ('BX|MW|T3','Théo Lambert','Fransa','MIDDLEWEIGHT','Kontra Boksör',78,85,84,80,83,81,7,1,1,2,'D',1,23),
  ('BX|MW|T4','Lukas Gruber','Avusturya','MIDDLEWEIGHT','Dengeli',80,78,80,82,79,77,6,3,0,3,'L',2,24),

  ('BX|LHW|T0','Viktor Adler','Avusturya','LIGHT_HEAVYWEIGHT','Baskıcı',89,77,81,87,85,88,11,2,0,7,'W',4,30),
  ('BX|LHW|T1','Daan Vermeer','Hollanda','LIGHT_HEAVYWEIGHT','Teknik Boksör',82,82,86,84,83,85,9,2,0,4,'W',2,31),
  ('BX|LHW|T2','Sergio Costa','Portekiz','LIGHT_HEAVYWEIGHT','Boxer-Puncher',87,78,79,84,81,82,8,3,0,6,'W',1,32),
  ('BX|LHW|T3','Aleksander Voss','Almanya','LIGHT_HEAVYWEIGHT','Kontra Boksör',81,81,84,82,80,80,7,2,1,3,'D',1,33),
  ('BX|LHW|T4','Mateo Ruiz','İspanya','LIGHT_HEAVYWEIGHT','Dengeli',83,77,78,80,82,77,6,3,0,4,'L',1,34),

  ('BX|HW|T0','Malcolm Fraser','İskoçya','HEAVYWEIGHT','Güç Boksörü',94,70,78,92,82,89,10,2,0,8,'W',3,40),
  ('BX|HW|T1','Berat Baybars Tümer','Türkiye','HEAVYWEIGHT','Boxer-Puncher',91,76,82,89,84,87,7,1,0,5,'W',4,41),
  ('BX|HW|T2','Arthur King','İngiltere','HEAVYWEIGHT','Teknik Ağır Siklet',87,78,86,88,83,86,9,1,0,6,'W',2,42),
  ('BX|HW|T3','Enzo Romano','İtalya','HEAVYWEIGHT','Baskıcı',93,69,75,87,80,82,8,3,0,7,'L',1,43),
  ('BX|HW|T4','Leon Papadakis','Yunanistan','HEAVYWEIGHT','Kontra Boksör',88,73,81,90,79,80,7,2,0,5,'W',1,44)
on conflict(id) do update set
  name=excluded.name,
  country=excluded.country,
  weight_class=excluded.weight_class,
  style=excluded.style,
  power=excluded.power,
  speed=excluded.speed,
  defense=excluded.defense,
  chin=excluded.chin,
  stamina=excluded.stamina,
  rating=excluded.rating,
  wins=excluded.wins,
  losses=excluded.losses,
  draws=excluded.draws,
  kos=excluded.kos,
  streak_type=excluded.streak_type,
  streak_count=excluded.streak_count,
  seed=excluded.seed,
  updated_at=now();

create index if not exists boxing_fighters_weight_rating_idx
on public.boxing_fighters(weight_class,rating desc);

create index if not exists boxing_bouts_schedule_idx
on public.boxing_bouts(status,scheduled_at);
