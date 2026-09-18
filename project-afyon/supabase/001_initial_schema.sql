-- Project Afyon Online
-- 001_initial_schema.sql
-- Shared-world backend foundation for Supabase/Postgres.

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- USERS
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance bigint not null default 10000 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;

  insert into public.wallets (user_id, balance)
  values (new.id, 10000)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- SHARED WORLD
-- Exactly one active Project Afyon universe.
-- ------------------------------------------------------------
create table if not exists public.world_state (
  id smallint primary key default 1 check (id = 1),
  season integer not null default 1 check (season >= 1),
  week integer not null default 1 check (week between 1 and 34),
  phase text not null default 'betting'
    check (phase in ('betting','live','finished')),
  live_started_at timestamptz,
  live_duration_ms integer not null default 180000 check (live_duration_ms > 0),
  updated_at timestamptz not null default now()
);

insert into public.world_state (id)
values (1)
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- CLUBS
-- Authoritative club strength lives on the server.
-- ------------------------------------------------------------
create table if not exists public.clubs (
  id text primary key,
  country text not null,
  league_level smallint not null check (league_level between 1 and 5),
  name text not null,
  base_strength numeric(5,2) not null,
  seed integer not null default 0,
  created_at timestamptz not null default now(),
  unique(country, league_level, name)
);

create index if not exists clubs_country_league_idx
  on public.clubs(country, league_level);

-- ------------------------------------------------------------
-- MATCHES + LIVE EVENTS
-- One result for everybody.
-- ------------------------------------------------------------
create table if not exists public.matches (
  id text primary key,
  season integer not null,
  week integer not null check (week between 1 and 34),
  country text not null,
  league_level smallint not null check (league_level between 1 and 5),
  match_index smallint not null,
  home_club_id text not null references public.clubs(id),
  away_club_id text not null references public.clubs(id),
  status text not null default 'scheduled'
    check (status in ('scheduled','live','finished')),
  home_goals smallint,
  away_goals smallint,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  unique(season, week, country, league_level, match_index)
);

create index if not exists matches_week_idx
  on public.matches(season, week, country, league_level);

create table if not exists public.match_events (
  id bigint generated always as identity primary key,
  match_id text not null references public.matches(id) on delete cascade,
  minute smallint not null check (minute between 0 and 120),
  event_type text not null,
  side text check (side in ('home','away')),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists match_events_match_minute_idx
  on public.match_events(match_id, minute, id);

-- ------------------------------------------------------------
-- MARKETS
-- Client never supplies authoritative odds.
-- ------------------------------------------------------------
create table if not exists public.match_markets (
  match_id text not null references public.matches(id) on delete cascade,
  market_key text not null,
  selection_key text not null,
  odd numeric(8,2) not null check (odd >= 1.01),
  locked boolean not null default false,
  primary key (match_id, market_key, selection_key)
);

-- ------------------------------------------------------------
-- COUPONS
-- Wallet movement and coupon creation happen server-side.
-- ------------------------------------------------------------
create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  season integer not null,
  week integer not null,
  stake bigint not null check (stake >= 10),
  total_odds numeric(12,2) not null,
  possible_return bigint not null,
  status text not null default 'pending'
    check (status in ('pending','won','lost','void')),
  payout bigint not null default 0,
  created_at timestamptz not null default now(),
  settled_at timestamptz
);

create index if not exists coupons_user_created_idx
  on public.coupons(user_id, created_at desc);

create table if not exists public.coupon_selections (
  id bigint generated always as identity primary key,
  coupon_id uuid not null references public.coupons(id) on delete cascade,
  match_id text not null references public.matches(id),
  market_key text not null,
  selection_key text not null,
  odd numeric(8,2) not null
);

create index if not exists coupon_selections_coupon_idx
  on public.coupon_selections(coupon_id);

-- ------------------------------------------------------------
-- SERVER-SIDE COUPON PLACEMENT
-- p_selections example:
-- [
--   {"match_id":"...","market_key":"1X2","selection_key":"1"},
--   {"match_id":"...","market_key":"OU25","selection_key":"OVER"}
-- ]
-- ------------------------------------------------------------
create or replace function public.place_coupon(
  p_stake bigint,
  p_selections jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_world public.world_state%rowtype;
  v_coupon_id uuid;
  v_total_odds numeric := 1;
  v_count integer := 0;
  v_item jsonb;
  v_odd numeric(8,2);
  v_match public.matches%rowtype;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if p_stake < 10 then
    raise exception 'MIN_STAKE_10';
  end if;

  if jsonb_typeof(p_selections) <> 'array'
     or jsonb_array_length(p_selections) < 1 then
    raise exception 'NO_SELECTIONS';
  end if;

  select * into v_world
  from public.world_state
  where id = 1
  for share;

  if v_world.phase <> 'betting' then
    raise exception 'BETTING_CLOSED';
  end if;

  -- Validate each selection against current authoritative server odds.
  for v_item in select * from jsonb_array_elements(p_selections)
  loop
    v_count := v_count + 1;

    select *
    into v_match
    from public.matches
    where id = v_item ->> 'match_id';

    if not found
       or v_match.season <> v_world.season
       or v_match.week <> v_world.week
       or v_match.status <> 'scheduled' then
      raise exception 'INVALID_MATCH';
    end if;

    select odd
    into v_odd
    from public.match_markets
    where match_id = v_match.id
      and market_key = v_item ->> 'market_key'
      and selection_key = v_item ->> 'selection_key'
      and locked = false;

    if not found then
      raise exception 'INVALID_OR_LOCKED_SELECTION';
    end if;

    v_total_odds := v_total_odds * v_odd;
  end loop;

  if v_count > 30 then
    raise exception 'TOO_MANY_SELECTIONS';
  end if;

  select balance
  into v_balance
  from public.wallets
  where user_id = v_user
  for update;

  if not found then
    raise exception 'WALLET_NOT_FOUND';
  end if;

  if v_balance < p_stake then
    raise exception 'INSUFFICIENT_BALANCE';
  end if;

  update public.wallets
  set balance = balance - p_stake,
      updated_at = now()
  where user_id = v_user;

  insert into public.coupons (
    user_id, season, week, stake, total_odds, possible_return
  )
  values (
    v_user,
    v_world.season,
    v_world.week,
    p_stake,
    round(v_total_odds, 2),
    round(p_stake * v_total_odds)
  )
  returning id into v_coupon_id;

  for v_item in select * from jsonb_array_elements(p_selections)
  loop
    select odd
    into v_odd
    from public.match_markets
    where match_id = v_item ->> 'match_id'
      and market_key = v_item ->> 'market_key'
      and selection_key = v_item ->> 'selection_key';

    insert into public.coupon_selections (
      coupon_id, match_id, market_key, selection_key, odd
    )
    values (
      v_coupon_id,
      v_item ->> 'match_id',
      v_item ->> 'market_key',
      v_item ->> 'selection_key',
      v_odd
    );
  end loop;

  return v_coupon_id;
end;
$$;

revoke all on function public.place_coupon(bigint, jsonb) from public;
grant execute on function public.place_coupon(bigint, jsonb) to authenticated;

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.world_state enable row level security;
alter table public.clubs enable row level security;
alter table public.matches enable row level security;
alter table public.match_events enable row level security;
alter table public.match_markets enable row level security;
alter table public.coupons enable row level security;
alter table public.coupon_selections enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "wallet_select_own" on public.wallets;
create policy "wallet_select_own"
on public.wallets for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "world_public_read" on public.world_state;
create policy "world_public_read"
on public.world_state for select
to anon, authenticated
using (true);

drop policy if exists "clubs_public_read" on public.clubs;
create policy "clubs_public_read"
on public.clubs for select
to anon, authenticated
using (true);

drop policy if exists "matches_public_read" on public.matches;
create policy "matches_public_read"
on public.matches for select
to anon, authenticated
using (true);

drop policy if exists "events_public_read" on public.match_events;
create policy "events_public_read"
on public.match_events for select
to anon, authenticated
using (true);

drop policy if exists "markets_public_read" on public.match_markets;
create policy "markets_public_read"
on public.match_markets for select
to anon, authenticated
using (true);

drop policy if exists "coupons_select_own" on public.coupons;
create policy "coupons_select_own"
on public.coupons for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "coupon_selections_select_own" on public.coupon_selections;
create policy "coupon_selections_select_own"
on public.coupon_selections for select
to authenticated
using (
  exists (
    select 1
    from public.coupons c
    where c.id = coupon_id
      and c.user_id = auth.uid()
  )
);

-- Direct client writes to wallets, world, matches, events and markets
-- intentionally have NO policies. They are server-authoritative.
