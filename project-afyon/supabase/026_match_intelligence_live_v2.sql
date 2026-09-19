-- Project Afyon 0.40 — Match Intelligence + Live Center v2
-- 1) Exposes real recent-form statistics computed from finished matches.
-- 2) Enriches future live matches with shared server-side shot/chance/card events.
-- Goals remain the only events that determine the final score.

create or replace function public.get_club_insights(
  p_sport text,
  p_recent integer default 10
)
returns table(
  club_id text,
  matches_played bigint,
  wins bigint,
  draws bigint,
  losses bigint,
  avg_goals_for numeric,
  avg_goals_against numeric,
  avg_total_goals numeric,
  scored_pct numeric,
  btts_pct numeric,
  over25_pct numeric,
  over35_pct numeric,
  over45_pct numeric,
  clean_sheet_pct numeric,
  form text
)
language sql
stable
set search_path = 'public'
as $$
  with current_world as (
    select season
    from public.world_state
    where id=1
  ),
  club_games as (
    select
      m.home_club_id as club_id,
      m.kickoff_at,
      m.home_goals::integer as gf,
      m.away_goals::integer as ga,
      case
        when m.home_goals>m.away_goals then 'W'
        when m.home_goals=m.away_goals then 'D'
        else 'L'
      end as outcome
    from public.matches m
    cross join current_world w
    where m.season=w.season
      and m.sport=p_sport
      and m.status='finished'
      and m.home_goals is not null
      and m.away_goals is not null

    union all

    select
      m.away_club_id as club_id,
      m.kickoff_at,
      m.away_goals::integer as gf,
      m.home_goals::integer as ga,
      case
        when m.away_goals>m.home_goals then 'W'
        when m.away_goals=m.home_goals then 'D'
        else 'L'
      end as outcome
    from public.matches m
    cross join current_world w
    where m.season=w.season
      and m.sport=p_sport
      and m.status='finished'
      and m.home_goals is not null
      and m.away_goals is not null
  ),
  ranked as (
    select
      cg.*,
      row_number() over(partition by cg.club_id order by cg.kickoff_at desc) as rn
    from club_games cg
  ),
  recent as (
    select *
    from ranked
    where rn<=greatest(1,least(coalesce(p_recent,10),30))
  )
  select
    r.club_id,
    count(*)::bigint as matches_played,
    count(*) filter(where r.outcome='W')::bigint as wins,
    count(*) filter(where r.outcome='D')::bigint as draws,
    count(*) filter(where r.outcome='L')::bigint as losses,
    round(avg(r.gf)::numeric,2) as avg_goals_for,
    round(avg(r.ga)::numeric,2) as avg_goals_against,
    round(avg(r.gf+r.ga)::numeric,2) as avg_total_goals,
    round(100*avg((r.gf>0)::integer)::numeric,0) as scored_pct,
    round(100*avg((r.gf>0 and r.ga>0)::integer)::numeric,0) as btts_pct,
    round(100*avg(((r.gf+r.ga)>2)::integer)::numeric,0) as over25_pct,
    round(100*avg(((r.gf+r.ga)>3)::integer)::numeric,0) as over35_pct,
    round(100*avg(((r.gf+r.ga)>4)::integer)::numeric,0) as over45_pct,
    round(100*avg((r.ga=0)::integer)::numeric,0) as clean_sheet_pct,
    string_agg(r.outcome,'' order by r.kickoff_at desc) as form
  from recent r
  group by r.club_id;
$$;

revoke all on function public.get_club_insights(text,integer) from public;
grant execute on function public.get_club_insights(text,integer) to anon, authenticated;

create or replace function private.create_match_plan(p_match_id text)
returns void
language plpgsql
security definer
set search_path = 'public', 'private'
as $$
declare
  m public.matches%rowtype;
  x record;
  tempo_shock numeric;
  home_shock numeric;
  away_shock numeric;
  hg integer;
  ag integer;
  i integer;
  minute integer;
  reveal_seconds integer;

  home_shots integer;
  away_shots integer;
  home_big integer;
  away_big integer;
  home_cards integer;
  away_cards integer;
  on_target boolean;
begin
  select * into m
  from public.matches
  where id=p_match_id
  for update;

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
  values(m.id,hg,ag)
  on conflict(match_id) do nothing;

  delete from public.match_events where match_id=m.id;

  -- Goals: these are authoritative for the final score.
  if hg>0 then
    for i in 1..hg loop
      minute:=3+floor(random()*86)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(
        m.id,minute,'goal','home',
        jsonb_build_object('importance','goal'),
        m.kickoff_at+make_interval(secs=>reveal_seconds)
      );
    end loop;
  end if;

  if ag>0 then
    for i in 1..ag loop
      minute:=3+floor(random()*86)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(
        m.id,minute,'goal','away',
        jsonb_build_object('importance','goal'),
        m.kickoff_at+make_interval(secs=>reveal_seconds)
      );
    end loop;
  end if;

  -- Shared live texture. These events never change the final score.
  home_shots:=greatest(hg+2,least(18,round(4+x.home_xg*3+random()*3)::integer));
  away_shots:=greatest(ag+2,least(18,round(4+x.away_xg*3+random()*3)::integer));

  for i in 1..home_shots loop
    minute:=2+floor(random()*87)::integer;
    on_target:=random()<greatest(.28,least(.58,.28+x.home_xg*.07));
    reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
    insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
    values(
      m.id,minute,'shot','home',
      jsonb_build_object('on_target',on_target),
      m.kickoff_at+make_interval(secs=>reveal_seconds)
    );
  end loop;

  for i in 1..away_shots loop
    minute:=2+floor(random()*87)::integer;
    on_target:=random()<greatest(.28,least(.58,.28+x.away_xg*.07));
    reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
    insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
    values(
      m.id,minute,'shot','away',
      jsonb_build_object('on_target',on_target),
      m.kickoff_at+make_interval(secs=>reveal_seconds)
    );
  end loop;

  home_big:=greatest(0,least(5,floor(x.home_xg*.85+random()*1.8)::integer));
  away_big:=greatest(0,least(5,floor(x.away_xg*.85+random()*1.8)::integer));

  if home_big>0 then
    for i in 1..home_big loop
      minute:=5+floor(random()*82)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'big_chance','home','{}'::jsonb,m.kickoff_at+make_interval(secs=>reveal_seconds));
    end loop;
  end if;

  if away_big>0 then
    for i in 1..away_big loop
      minute:=5+floor(random()*82)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'big_chance','away','{}'::jsonb,m.kickoff_at+make_interval(secs=>reveal_seconds));
    end loop;
  end if;

  home_cards:=case when m.sport='efootball' then floor(random()*2)::integer else floor(random()*3)::integer end;
  away_cards:=case when m.sport='efootball' then floor(random()*2)::integer else floor(random()*3)::integer end;

  if home_cards>0 then
    for i in 1..home_cards loop
      minute:=8+floor(random()*79)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'yellow_card','home','{}'::jsonb,m.kickoff_at+make_interval(secs=>reveal_seconds));
    end loop;
  end if;

  if away_cards>0 then
    for i in 1..away_cards loop
      minute:=8+floor(random()*79)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'yellow_card','away','{}'::jsonb,m.kickoff_at+make_interval(secs=>reveal_seconds));
    end loop;
  end if;

  update public.match_markets set locked=true where match_id=m.id;
  update public.matches set status='live',started_at=m.kickoff_at where id=m.id;
end;
$$;
