-- Project Afyon 0.52 — Boxing Sportsbook
-- Connects AFMB Fight Night to the shared coupon/wallet system.
-- Football, eFootball and boxing selections can coexist in one coupon.

create table if not exists public.boxing_markets (
  bout_id text not null references public.boxing_bouts(id) on delete cascade,
  market_key text not null check (market_key in ('BOX_WIN','BOX_METHOD','BOX_DISTANCE')),
  selection_key text not null,
  odd numeric(8,2) not null check (odd >= 1.01),
  locked boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (bout_id,market_key,selection_key)
);

alter table public.boxing_markets enable row level security;
drop policy if exists boxing_markets_public_read on public.boxing_markets;
create policy boxing_markets_public_read
on public.boxing_markets
for select
to anon,authenticated
using (true);
grant select on public.boxing_markets to anon,authenticated;

alter table public.coupon_selections
  alter column match_id drop not null;

alter table public.coupon_selections
  add column if not exists bout_id text references public.boxing_bouts(id);

create index if not exists coupon_selections_bout_id_idx
on public.coupon_selections(bout_id);

do $$
begin
  if not exists(
    select 1 from pg_constraint
    where conrelid='public.coupon_selections'::regclass
      and conname='coupon_selections_exactly_one_event_check'
  ) then
    alter table public.coupon_selections
      add constraint coupon_selections_exactly_one_event_check
      check (
        (match_id is not null and bout_id is null)
        or
        (match_id is null and bout_id is not null)
      );
  end if;
end;
$$;

create or replace function private.boxing_market_odd(
  p_probability numeric,
  p_max numeric default 25
)
returns numeric
language sql
immutable
set search_path=''
as $$
  select round(
    greatest(
      1.05::numeric,
      least(
        p_max,
        1 / (greatest(.005::numeric,least(.995::numeric,p_probability)) * 1.06::numeric)
      )
    ),
    2
  )
$$;

create or replace function private.refresh_boxing_markets(p_bout_id text)
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  b public.boxing_bouts%rowtype;
  r public.boxing_fighters%rowtype;
  bl public.boxing_fighters%rowtype;
  red_quality numeric;
  blue_quality numeric;
  red_raw numeric;
  p_draw numeric:=.025;
  p_red numeric;
  p_blue numeric;
  ko_red numeric;
  ko_blue numeric;
  p_red_ko numeric;
  p_blue_ko numeric;
  p_red_dec numeric;
  p_blue_dec numeric;
  p_goes numeric;
  p_not_goes numeric;
begin
  select * into b from public.boxing_bouts where id=p_bout_id;
  if not found then return; end if;

  if b.status<>'scheduled' or b.scheduled_at<=now() then
    update public.boxing_markets
    set locked=true,updated_at=now()
    where bout_id=b.id;
    return;
  end if;

  select * into r from public.boxing_fighters where id=b.red_fighter_id;
  select * into bl from public.boxing_fighters where id=b.blue_fighter_id;
  if r.id is null or bl.id is null then return; end if;

  -- Mirrors the core Fight Night quality model so the line knows the same
  -- information as the simulation, without knowing the future random plan.
  red_quality:=r.rating*.35+r.power*.20+r.speed*.15+r.defense*.10+r.chin*.10+r.stamina*.10;
  blue_quality:=bl.rating*.35+bl.power*.20+bl.speed*.15+bl.defense*.10+bl.chin*.10+bl.stamina*.10;
  red_raw:=1/(1+exp(-(red_quality-blue_quality)/8.0));
  red_raw:=greatest(.18,least(.82,red_raw));

  p_red:=(1-p_draw)*red_raw;
  p_blue:=(1-p_draw)*(1-red_raw);

  ko_red:=greatest(.12,least(.58,.24+(r.power-bl.chin)*.012));
  ko_blue:=greatest(.12,least(.58,.24+(bl.power-r.chin)*.012));

  p_red_ko:=p_red*ko_red;
  p_blue_ko:=p_blue*ko_blue;
  p_red_dec:=p_red*(1-ko_red);
  p_blue_dec:=p_blue*(1-ko_blue);
  p_not_goes:=p_red_ko+p_blue_ko;
  p_goes:=1-p_not_goes;

  insert into public.boxing_markets(bout_id,market_key,selection_key,odd,locked,updated_at)
  values
    (b.id,'BOX_WIN','RED', private.boxing_market_odd(p_red,8),false,now()),
    (b.id,'BOX_WIN','DRAW',private.boxing_market_odd(p_draw,25),false,now()),
    (b.id,'BOX_WIN','BLUE',private.boxing_market_odd(p_blue,8),false,now()),

    (b.id,'BOX_METHOD','RED_KO', private.boxing_market_odd(p_red_ko,15),false,now()),
    (b.id,'BOX_METHOD','RED_DEC',private.boxing_market_odd(p_red_dec,15),false,now()),
    (b.id,'BOX_METHOD','BLUE_KO',private.boxing_market_odd(p_blue_ko,15),false,now()),
    (b.id,'BOX_METHOD','BLUE_DEC',private.boxing_market_odd(p_blue_dec,15),false,now()),

    (b.id,'BOX_DISTANCE','GOES',    private.boxing_market_odd(p_goes,6),false,now()),
    (b.id,'BOX_DISTANCE','NOT_GOES',private.boxing_market_odd(p_not_goes,6),false,now())
  on conflict(bout_id,market_key,selection_key)
  do update set
    odd=excluded.odd,
    locked=false,
    updated_at=excluded.updated_at;
end;
$$;

create or replace function private.boxing_market_sync_trigger()
returns trigger
language plpgsql
security definer
set search_path='public','private'
as $$
begin
  if new.status='scheduled' and new.scheduled_at>now() then
    perform private.refresh_boxing_markets(new.id);
  elsif new.status<>'scheduled' then
    update public.boxing_markets
    set locked=true,updated_at=now()
    where bout_id=new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists boxing_market_sync on public.boxing_bouts;
create trigger boxing_market_sync
after insert or update of status,scheduled_at,red_fighter_id,blue_fighter_id
on public.boxing_bouts
for each row
execute function private.boxing_market_sync_trigger();

create or replace function private.boxing_fighter_market_sync_trigger()
returns trigger
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  b record;
begin
  if new.rating is distinct from old.rating
     or new.power is distinct from old.power
     or new.speed is distinct from old.speed
     or new.defense is distinct from old.defense
     or new.chin is distinct from old.chin
     or new.stamina is distinct from old.stamina then
    for b in
      select id
      from public.boxing_bouts
      where status='scheduled'
        and scheduled_at>now()
        and (red_fighter_id=new.id or blue_fighter_id=new.id)
    loop
      perform private.refresh_boxing_markets(b.id);
    end loop;
  end if;
  return new;
end;
$$;

drop trigger if exists boxing_fighter_market_sync on public.boxing_fighters;
create trigger boxing_fighter_market_sync
after update of rating,power,speed,defense,chin,stamina
on public.boxing_fighters
for each row
execute function private.boxing_fighter_market_sync_trigger();

create or replace function private.boxing_selection_wins(
  p_market text,
  p_selection text,
  p_winner_id text,
  p_red_id text,
  p_blue_id text,
  p_method text
)
returns boolean
language plpgsql
immutable
set search_path=''
as $$
begin
  if p_market='BOX_WIN' then
    return (p_selection='RED' and p_winner_id=p_red_id)
      or (p_selection='BLUE' and p_winner_id=p_blue_id)
      or (p_selection='DRAW' and p_winner_id is null);
  elsif p_market='BOX_METHOD' then
    return (p_selection='RED_KO' and p_winner_id=p_red_id and p_method in ('KO','TKO'))
      or (p_selection='RED_DEC' and p_winner_id=p_red_id and p_method in ('UD','SD','MD'))
      or (p_selection='BLUE_KO' and p_winner_id=p_blue_id and p_method in ('KO','TKO'))
      or (p_selection='BLUE_DEC' and p_winner_id=p_blue_id and p_method in ('UD','SD','MD'));
  elsif p_market='BOX_DISTANCE' then
    return (p_selection='NOT_GOES' and p_method in ('KO','TKO'))
      or (p_selection='GOES' and p_method in ('UD','SD','MD','DRAW'));
  end if;
  return false;
end;
$$;

create or replace function public.place_coupon(p_stake bigint, p_selections jsonb)
returns uuid
language plpgsql
security definer
set search_path='public'
as $$
declare
  v_user uuid:=auth.uid();
  v_balance bigint;
  v_coupon_id uuid;
  v_total_odds numeric:=1;
  v_count integer:=0;
  v_item jsonb;
  v_odd numeric(8,2);
  v_match public.matches%rowtype;
  v_bout public.boxing_bouts%rowtype;
  v_match_id text;
  v_bout_id text;
  v_first_match_season integer;
  v_first_match_week integer;
  v_coupon_season integer;
  v_coupon_week integer;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_stake<10 then raise exception 'MIN_STAKE_10'; end if;
  if jsonb_typeof(p_selections)<>'array' or jsonb_array_length(p_selections)<1 then
    raise exception 'NO_SELECTIONS';
  end if;

  select season,week into v_coupon_season,v_coupon_week
  from public.world_state
  where id=1;

  for v_item in select * from jsonb_array_elements(p_selections)
  loop
    v_count:=v_count+1;
    if v_count>30 then raise exception 'TOO_MANY_SELECTIONS'; end if;

    v_match_id:=nullif(v_item->>'match_id','');
    v_bout_id:=nullif(v_item->>'bout_id','');

    if (v_match_id is null and v_bout_id is null)
       or (v_match_id is not null and v_bout_id is not null) then
      raise exception 'INVALID_EVENT_REFERENCE';
    end if;

    if v_match_id is not null then
      select * into v_match from public.matches where id=v_match_id;
      if not found or v_match.status<>'scheduled' or v_match.kickoff_at<=now() then
        raise exception 'INVALID_OR_STARTED_MATCH';
      end if;

      if v_first_match_season is null then
        v_first_match_season:=v_match.season;
        v_first_match_week:=v_match.week;
        v_coupon_season:=v_match.season;
        v_coupon_week:=v_match.week;
      elsif v_match.season<>v_first_match_season or v_match.week<>v_first_match_week then
        raise exception 'MIXED_WEEK_COUPON';
      end if;

      select odd into v_odd
      from public.match_markets
      where match_id=v_match.id
        and market_key=v_item->>'market_key'
        and selection_key=v_item->>'selection_key'
        and locked=false;

      if not found then raise exception 'INVALID_OR_LOCKED_SELECTION'; end if;
    else
      select * into v_bout from public.boxing_bouts where id=v_bout_id;
      if not found or v_bout.status<>'scheduled' or v_bout.scheduled_at<=now() then
        raise exception 'INVALID_OR_STARTED_BOUT';
      end if;

      select odd into v_odd
      from public.boxing_markets
      where bout_id=v_bout.id
        and market_key=v_item->>'market_key'
        and selection_key=v_item->>'selection_key'
        and locked=false;

      if not found then raise exception 'INVALID_OR_LOCKED_SELECTION'; end if;
    end if;

    v_total_odds:=v_total_odds*v_odd;
  end loop;

  select balance into v_balance
  from public.wallets
  where user_id=v_user
  for update;

  if not found then raise exception 'WALLET_NOT_FOUND'; end if;
  if v_balance<p_stake then raise exception 'INSUFFICIENT_BALANCE'; end if;

  update public.wallets
  set balance=balance-p_stake,updated_at=now()
  where user_id=v_user;

  insert into public.coupons(user_id,season,week,stake,total_odds,possible_return)
  values(v_user,v_coupon_season,v_coupon_week,p_stake,round(v_total_odds,2),round(p_stake*v_total_odds))
  returning id into v_coupon_id;

  for v_item in select * from jsonb_array_elements(p_selections)
  loop
    v_match_id:=nullif(v_item->>'match_id','');
    v_bout_id:=nullif(v_item->>'bout_id','');

    if v_match_id is not null then
      select odd into v_odd
      from public.match_markets
      where match_id=v_match_id
        and market_key=v_item->>'market_key'
        and selection_key=v_item->>'selection_key';

      insert into public.coupon_selections(coupon_id,match_id,bout_id,market_key,selection_key,odd)
      values(v_coupon_id,v_match_id,null,v_item->>'market_key',v_item->>'selection_key',v_odd);
    else
      select odd into v_odd
      from public.boxing_markets
      where bout_id=v_bout_id
        and market_key=v_item->>'market_key'
        and selection_key=v_item->>'selection_key';

      insert into public.coupon_selections(coupon_id,match_id,bout_id,market_key,selection_key,odd)
      values(v_coupon_id,null,v_bout_id,v_item->>'market_key',v_item->>'selection_key',v_odd);
    end if;
  end loop;

  return v_coupon_id;
end;
$$;

create or replace function private.settle_ready_coupons()
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  c record;
  leg_count integer;
  done_count integer;
  loss_count integer;
begin
  for c in
    select * from public.coupons where status='pending' order by created_at
    for update
  loop
    select
      count(*),
      count(*) filter(where x.done),
      count(*) filter(where x.done and not x.won)
    into leg_count,done_count,loss_count
    from (
      select
        case
          when cs.match_id is not null then coalesce(m.status='finished',false)
          when cs.bout_id is not null then coalesce(b.status='finished',false)
          else false
        end as done,
        case
          when cs.match_id is not null and m.status='finished' then
            private.selection_wins(cs.market_key,cs.selection_key,m.home_goals,m.away_goals)
          when cs.bout_id is not null and b.status='finished' then
            private.boxing_selection_wins(
              cs.market_key,cs.selection_key,b.winner_id,b.red_fighter_id,b.blue_fighter_id,b.method
            )
          else false
        end as won
      from public.coupon_selections cs
      left join public.matches m on m.id=cs.match_id
      left join public.boxing_bouts b on b.id=cs.bout_id
      where cs.coupon_id=c.id
    ) x;

    if leg_count=0 then
      continue;
    elsif loss_count>0 then
      update public.coupons
      set status='lost',settled_at=now()
      where id=c.id;
    elsif done_count=leg_count then
      update public.coupons
      set status='won',payout=possible_return,settled_at=now()
      where id=c.id;

      update public.wallets
      set balance=balance+c.possible_return,updated_at=now()
      where user_id=c.user_id;
    end if;
  end loop;
end;
$$;

-- Generate prices for currently scheduled Fight Night bouts.
do $$
declare
  b record;
begin
  for b in
    select id
    from public.boxing_bouts
    where status='scheduled' and scheduled_at>now()
  loop
    perform private.refresh_boxing_markets(b.id);
  end loop;
end;
$$;
