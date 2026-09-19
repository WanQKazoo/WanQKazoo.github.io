-- Applied Supabase migration: seed_efootball_fast_league


with current_world as (
  select season,week from public.world_state where id=1
),
club_rank as (
  select c.*,
         row_number() over(partition by c.country order by c.seed,c.name) as rn
  from public.clubs c
  where c.league_level=1
),
slots as (
  select sc.season,sc.week,sc.play_date,cw.week as current_week,
         s.slot,l.lane,
         ((s.slot*2+l.lane+sc.week-1)%12)+1 as country_no
  from public.season_calendar sc
  join current_world cw on cw.season=sc.season and sc.week>=cw.week
  cross join generate_series(0,47) as s(slot)
  cross join generate_series(0,1) as l(lane)
),
picked as (
  select *,
    (array['İngiltere','Türkiye','İspanya','Almanya','İtalya','Fransa','Hollanda','Portekiz','Belçika','İskoçya','Yunanistan','Avusturya'])[country_no] as country,
    ((week + slot*3 + lane*5) % 18)+1 as home_rn,
    ((play_date::timestamp + time '00:10' + slot*interval '30 minutes') at time zone 'Europe/Istanbul') as kickoff
  from slots
),
paired as (
  select *,
    ((home_rn + 5 + (slot%7) - 1) % 18)+1 as away_rn
  from picked
)
insert into public.matches(
  id,season,week,country,league_level,match_index,
  home_club_id,away_club_id,status,kickoff_at,sport,duration_seconds
)
select
  'EF|S'||p.season||'|W'||p.week||'|S'||p.slot||'|L'||p.lane,
  p.season,p.week,p.country,1,(p.slot*2+p.lane)::smallint,
  h.id,a.id,'scheduled',p.kickoff,'efootball',75
from paired p
join club_rank h on h.country=p.country and h.rn=p.home_rn
join club_rank a on a.country=p.country and a.rn=p.away_rn
where p.week>p.current_week or p.kickoff>now()+interval '90 seconds'
on conflict(id) do nothing;

do $$
declare r record; v_season integer; v_week integer;
begin
  select season,week into v_season,v_week from public.world_state where id=1;
  for r in
    select m.id from public.matches m
    where m.sport='efootball' and m.season=v_season and m.week=v_week
      and m.status='scheduled'
      and not exists(select 1 from public.match_markets mm where mm.match_id=m.id)
  loop
    perform private.refresh_match_markets(r.id);
  end loop;
end;
$$;

