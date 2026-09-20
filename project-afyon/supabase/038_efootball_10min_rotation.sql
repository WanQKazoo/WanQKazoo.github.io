-- Project Afyon 0.54 — eFootball Turbo Rotation
-- Keep the established 30-minute anchor matches, but fill the +10 and +20
-- minute gaps with additional eFootball Arena matches. Result: a kickoff group
-- every 10 minutes, without moving or invalidating existing matches/coupons.

create or replace function private.ensure_efootball_turbo_schedule(
  p_horizon_hours integer default 48
)
returns integer
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  r record;
  k integer;
  v_target timestamptz;
  v_home_seed integer;
  v_away_seed integer;
  v_home_id text;
  v_away_id text;
  v_match_index integer;
  v_id text;
  v_inserted integer;
  v_total integer:=0;
begin
  p_horizon_hours:=greatest(1,least(coalesce(p_horizon_hours,48),168));

  -- Original eFootball rows are the anchors (EF|...). Turbo rows use EFT|.
  -- Look slightly behind "now" so a recently played anchor can still supply
  -- the +10/+20 match that has not kicked off yet.
  for r in
    select
      m.id,m.season,m.week,m.country,m.league_level,m.match_index,m.kickoff_at,
      hc.seed::integer as home_seed,
      ac.seed::integer as away_seed
    from public.matches m
    join public.clubs hc on hc.id=m.home_club_id
    join public.clubs ac on ac.id=m.away_club_id
    where m.sport='efootball'
      and m.id like 'EF|%'
      and m.kickoff_at>=now()-interval '25 minutes'
      and m.kickoff_at<now()+make_interval(hours=>p_horizon_hours)
    order by m.kickoff_at,m.id
  loop
    for k in 1..2 loop
      v_target:=r.kickoff_at+make_interval(mins=>k*10);
      if v_target<=now() then
        continue;
      end if;

      -- Deterministic but different eFC pairing for each inserted slot.
      v_home_seed:=mod(abs(r.home_seed + r.week*3 + r.match_index + k*4),18);
      v_away_seed:=mod(abs(r.away_seed + r.week*5 + r.match_index + k*7 + 3),18);
      if v_away_seed=v_home_seed then
        v_away_seed:=mod(v_away_seed+1,18);
      end if;

      select id into v_home_id
      from public.clubs
      where country=r.country
        and league_level=1
        and seed=v_home_seed
      order by id
      limit 1;

      select id into v_away_id
      from public.clubs
      where country=r.country
        and league_level=1
        and seed=v_away_seed
      order by id
      limit 1;

      if v_home_id is null or v_away_id is null or v_home_id=v_away_id then
        continue;
      end if;

      v_match_index:=10000 + r.match_index*10 + k;
      v_id:='EFT|'||r.season||'|'||r.week||'|'||replace(r.country,'|','')||'|'||r.match_index||'|'||k;

      insert into public.matches(
        id,season,week,country,league_level,match_index,
        home_club_id,away_club_id,status,kickoff_at,sport,duration_seconds
      ) values(
        v_id,r.season,r.week,r.country,1,v_match_index,
        v_home_id,v_away_id,'scheduled',v_target,'efootball',75
      )
      on conflict do nothing;

      get diagnostics v_inserted=row_count;
      if v_inserted=1 then
        perform private.refresh_match_markets(v_id);
        v_total:=v_total+1;
      end if;
    end loop;
  end loop;

  return v_total;
end;
$$;

create or replace function private.efootball_turbo_world_state_trigger()
returns trigger
language plpgsql
security definer
set search_path='public','private'
as $$
begin
  perform private.ensure_efootball_turbo_schedule(48);
  return new;
end;
$$;

drop trigger if exists efootball_turbo_world_state on public.world_state;
create trigger efootball_turbo_world_state
after update of updated_at on public.world_state
for each row
when (new.id=1)
execute function private.efootball_turbo_world_state_trigger();

-- Prime the next two days immediately.
select private.ensure_efootball_turbo_schedule(48);
