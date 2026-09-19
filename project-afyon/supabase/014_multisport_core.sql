-- Applied Supabase migration: multisport_core


alter table public.matches
  add column if not exists sport text not null default 'football',
  add column if not exists duration_seconds smallint not null default 180;

alter table public.matches drop constraint if exists matches_sport_check;
alter table public.matches add constraint matches_sport_check check (sport in ('football','efootball'));
alter table public.matches drop constraint if exists matches_duration_seconds_check;
alter table public.matches add constraint matches_duration_seconds_check check (duration_seconds between 30 and 600);
alter table public.matches drop constraint if exists matches_season_week_country_league_level_match_index_key;
alter table public.matches
  add constraint matches_sport_season_week_country_league_level_match_index_key
  unique (sport,season,week,country,league_level,match_index);
create index if not exists matches_sport_kickoff_idx on public.matches(sport,status,kickoff_at);

create or replace function private.expected_xg(p_match_id text)
returns table(home_xg numeric, away_xg numeric)
language plpgsql
stable
set search_path = 'public','private'
as $$
declare
  m public.matches%rowtype; h public.clubs%rowtype; a public.clubs%rowtype;
  hf numeric; af numeric; h_atk numeric; h_mid numeric; h_def numeric;
  a_atk numeric; a_mid numeric; a_def numeric; mid_edge numeric; tempo numeric;
begin
  select * into m from public.matches where id=p_match_id;
  select * into h from public.clubs where id=m.home_club_id;
  select * into a from public.clubs where id=m.away_club_id;
  hf:=private.form_modifier(h.id,m.season,m.week); af:=private.form_modifier(a.id,m.season,m.week);
  h_atk:=h.attack+hf*.70; h_mid:=h.midfield+hf*.50; h_def:=h.defense+hf*.45;
  a_atk:=a.attack+af*.70; a_mid:=a.midfield+af*.50; a_def:=a.defense+af*.45;
  mid_edge:=(h_mid-a_mid)/10.0;
  if m.sport='efootball' then
    tempo:=(((h.seed*7+a.seed*11+m.match_index)%7)-3)*.025;
    home_xg:=greatest(.72,least(2.85,1.68+((h_atk-a_def)/10.0)*.14+mid_edge*.035+tempo));
    away_xg:=greatest(.65,least(2.65,1.43+((a_atk-h_def)/10.0)*.14-mid_edge*.030+tempo));
  else
    tempo:=(((h.seed*3+a.seed*5)%5)-2)*.015;
    home_xg:=greatest(.58,least(2.45,1.38+((h_atk-a_def)/10.0)*.18+mid_edge*.05+tempo));
    away_xg:=greatest(.48,least(2.25,1.08+((a_atk-h_def)/10.0)*.18-mid_edge*.045+tempo));
  end if;
  return next;
end;
$$;

create or replace function private.refresh_match_markets(p_match_id text)
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  m public.matches%rowtype; x record; h integer; a integer; p numeric;
  total_mass numeric:=0; p1 numeric:=0; px numeric:=0; p2 numeric:=0;
  btts numeric:=0; u15 numeric:=0; u25 numeric:=0; u35 numeric:=0;
begin
  select * into m from public.matches where id=p_match_id;
  if not found or m.status<>'scheduled' then return; end if;
  select * into x from private.expected_xg(m.id);
  for h in 0..8 loop
    for a in 0..8 loop
      p:=private.poisson_probability(x.home_xg,h)*private.poisson_probability(x.away_xg,a);
      total_mass:=total_mass+p;
      if h>a then p1:=p1+p; elsif h=a then px:=px+p; else p2:=p2+p; end if;
      if h>0 and a>0 then btts:=btts+p; end if;
      if h+a<1.5 then u15:=u15+p; end if;
      if h+a<2.5 then u25:=u25+p; end if;
      if h+a<3.5 then u35:=u35+p; end if;
    end loop;
  end loop;
  p1:=p1/total_mass; px:=px/total_mass; p2:=p2/total_mass;
  btts:=btts/total_mass; u15:=u15/total_mass; u25:=u25/total_mass; u35:=u35/total_mass;
  delete from public.match_markets where match_id=m.id;
  insert into public.match_markets(match_id,market_key,selection_key,odd,locked) values
    (m.id,'1X2','1',private.fair_odd(p1,1.06,1.25,6.80),false),
    (m.id,'1X2','X',private.fair_odd(px,1.06,2.65,4.80),false),
    (m.id,'1X2','2',private.fair_odd(p2,1.06,1.25,6.80),false),
    (m.id,'OU15','UNDER',private.fair_odd(u15,1.06,2.15,3.30),false),
    (m.id,'OU15','OVER',private.fair_odd(1-u15,1.06,1.30,1.70),false),
    (m.id,'OU25','UNDER',private.fair_odd(u25,1.055,1.55,2.35),false),
    (m.id,'OU25','OVER',private.fair_odd(1-u25,1.055,1.55,2.35),false),
    (m.id,'OU35','UNDER',private.fair_odd(u35,1.06,1.30,1.75),false),
    (m.id,'OU35','OVER',private.fair_odd(1-u35,1.06,2.15,3.30),false),
    (m.id,'BTTS','YES',private.fair_odd(btts,1.055,1.55,2.35),false),
    (m.id,'BTTS','NO',private.fair_odd(1-btts,1.055,1.55,2.35),false),
    (m.id,'DC','1X',private.fair_odd(p1+px,1.035,1.08,2.35),false),
    (m.id,'DC','12',private.fair_odd(p1+p2,1.035,1.08,2.35),false),
    (m.id,'DC','X2',private.fair_odd(px+p2,1.035,1.08,2.35),false);
end;
$$;

create or replace function private.refresh_week_markets(p_season integer,p_week integer)
returns void
language plpgsql security definer set search_path='public','private'
as $$
declare r record;
begin
  for r in select id from public.matches where season=p_season and week=p_week and status='scheduled'
  loop perform private.refresh_match_markets(r.id); end loop;
end;
$$;

create or replace function private.create_match_plan(p_match_id text)
returns void
language plpgsql security definer set search_path='public','private'
as $$
declare
  m public.matches%rowtype; x record; tempo_shock numeric; home_shock numeric; away_shock numeric;
  hg integer; ag integer; i integer; minute integer; reveal_seconds integer;
begin
  select * into m from public.matches where id=p_match_id for update;
  if m.status<>'scheduled' or m.kickoff_at>now() then return; end if;
  select * into x from private.expected_xg(m.id);
  if m.sport='efootball' then
    tempo_shock:=.90+random()*.22;
    home_shock:=greatest(.74,least(1.30,1+((random()+random()+random()-1.5)/1.5)*.24));
    away_shock:=greatest(.74,least(1.30,1+((random()+random()+random()-1.5)/1.5)*.24));
  else
    tempo_shock:=.93+random()*.14;
    home_shock:=greatest(.78,least(1.24,1+((random()+random()+random()+random()-2)/2)*.20));
    away_shock:=greatest(.78,least(1.24,1+((random()+random()+random()+random()-2)/2)*.20));
  end if;
  hg:=private.poisson_sample(x.home_xg*tempo_shock*home_shock);
  ag:=private.poisson_sample(x.away_xg*tempo_shock*away_shock);
  insert into private.match_plans(match_id,final_home_goals,final_away_goals)
  values(m.id,hg,ag) on conflict(match_id) do nothing;
  delete from public.match_events where match_id=m.id;
  if hg>0 then for i in 1..hg loop
    minute:=3+floor(random()*86)::integer;
    reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
    insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
    values(m.id,minute,'goal','home','{}'::jsonb,m.kickoff_at+make_interval(secs=>reveal_seconds));
  end loop; end if;
  if ag>0 then for i in 1..ag loop
    minute:=3+floor(random()*86)::integer;
    reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
    insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
    values(m.id,minute,'goal','away','{}'::jsonb,m.kickoff_at+make_interval(secs=>reveal_seconds));
  end loop; end if;
  update public.match_markets set locked=true where match_id=m.id;
  update public.matches set status='live',started_at=m.kickoff_at where id=m.id;
end;
$$;

create or replace function public.tick_world()
returns void
language plpgsql security definer set search_path='public','private'
as $$
declare
  v_season integer; v_week integer; r record; p private.match_plans%rowtype;
  v_phase text; v_event_home integer; v_event_away integer;
begin
  select season into v_season from public.world_state where id=1;
  if v_season is null then return; end if;
  select week into v_week from public.season_calendar
   where season=v_season and play_date=(now() at time zone 'Europe/Istanbul')::date;
  if v_week is not null then
    update public.world_state set week=v_week,updated_at=now() where id=1;
    if not exists(
      select 1 from public.match_markets mm join public.matches m on m.id=mm.match_id
      where m.season=v_season and m.week=v_week and m.sport='football'
    ) then perform private.refresh_week_markets(v_season,v_week); end if;
  else select week into v_week from public.world_state where id=1; end if;
  for r in
    select id from public.matches where season=v_season and status='scheduled' and kickoff_at<=now()
    order by kickoff_at for update skip locked
  loop perform private.create_match_plan(r.id); end loop;
  for r in
    select id,duration_seconds from public.matches
    where season=v_season and status='live'
      and started_at+make_interval(secs=>duration_seconds)<=now()
    order by started_at for update skip locked
  loop
    select count(*) filter(where event_type='goal' and side='home'),
           count(*) filter(where event_type='goal' and side='away')
      into v_event_home,v_event_away
      from public.match_events where match_id=r.id;
    select * into p from private.match_plans where match_id=r.id;
    if found and (p.final_home_goals<>v_event_home or p.final_away_goals<>v_event_away) then
      insert into private.match_integrity_audit(match_id,plan_home,plan_away,event_home,event_away,note)
      values(r.id,p.final_home_goals,p.final_away_goals,v_event_home,v_event_away,
             'Final score derived from visible live-event stream; plan differed.');
    end if;
    update public.matches set status='finished',home_goals=v_event_home,away_goals=v_event_away,
      finished_at=started_at+make_interval(secs=>r.duration_seconds) where id=r.id;
  end loop;
  perform private.settle_ready_coupons();
  if exists(select 1 from public.matches where season=v_season and week=v_week and sport='football' and status='live')
    then v_phase:='live';
  elsif exists(select 1 from public.matches where season=v_season and week=v_week and sport='football' and status='scheduled')
    then v_phase:='betting';
  else v_phase:='finished'; end if;
  update public.world_state set phase=v_phase,updated_at=now() where id=1;
end;
$$;

