-- Project Afyon 0.41 — form-aware pricing
-- Separates result form from scoring tempo and makes both sport-specific.
-- Small samples are shrunk heavily toward the engine prior; 10-match samples
-- have a meaningful but still capped effect. expected_xg remains the single
-- source used by both market pricing and match simulation.

create or replace function private.result_form_before(
  p_club_id text,
  p_sport text,
  p_season integer,
  p_before timestamptz
)
returns numeric
language sql
stable
set search_path = 'public'
as $$
with recent as (
  select
    m.kickoff_at,
    case
      when m.home_club_id=p_club_id and m.home_goals>m.away_goals then 3
      when m.away_club_id=p_club_id and m.away_goals>m.home_goals then 3
      when m.home_goals=m.away_goals then 1
      else 0
    end as pts,
    case
      when m.home_club_id=p_club_id then m.home_goals-m.away_goals
      else m.away_goals-m.home_goals
    end as gd
  from public.matches m
  where m.season=p_season
    and m.sport=p_sport
    and m.status='finished'
    and m.kickoff_at<p_before
    and (m.home_club_id=p_club_id or m.away_club_id=p_club_id)
  order by m.kickoff_at desc
  limit 5
),
ordered as (
  select *,
    row_number() over(order by kickoff_at asc)-1 as idx
  from recent
),
weighted as (
  select
    coalesce(sum(pts*(1+idx*.15))/nullif(sum(1+idx*.15),0),1.35) as wp,
    coalesce(sum(gd*(1+idx*.15))/nullif(sum(1+idx*.15),0),0) as wgd,
    count(*) as cnt
  from ordered
)
select case
  when cnt=0 then 0
  else greatest(-6,least(6,(wp-1.35)*3.2+wgd*.7))
end
from weighted;
$$;

create or replace function private.recent_goal_profile(
  p_club_id text,
  p_sport text,
  p_season integer,
  p_before timestamptz
)
returns table(
  sample_count integer,
  avg_goals_for numeric,
  avg_goals_against numeric,
  avg_total_goals numeric,
  attack_factor numeric,
  concede_factor numeric,
  tempo_factor numeric
)
language sql
stable
set search_path = 'public'
as $$
with params as (
  select
    case when p_sport='efootball' then 1.98::numeric else 1.32::numeric end as prior_team_goals,
    case when p_sport='efootball' then 3.96::numeric else 2.64::numeric end as prior_total_goals
),
recent as (
  select
    case when m.home_club_id=p_club_id then m.home_goals else m.away_goals end::numeric as gf,
    case when m.home_club_id=p_club_id then m.away_goals else m.home_goals end::numeric as ga
  from public.matches m
  where m.season=p_season
    and m.sport=p_sport
    and m.status='finished'
    and m.kickoff_at<p_before
    and (m.home_club_id=p_club_id or m.away_club_id=p_club_id)
  order by m.kickoff_at desc
  limit 10
),
agg as (
  select
    count(*)::integer as n,
    avg(gf)::numeric as gf,
    avg(ga)::numeric as ga,
    avg(gf+ga)::numeric as total
  from recent
),
calc as (
  select
    a.n,
    a.gf,
    a.ga,
    a.total,
    p.prior_team_goals,
    p.prior_total_goals,
    case when a.n=0 then 0::numeric else a.n::numeric/(a.n+5)::numeric end as w
  from agg a cross join params p
)
select
  n,
  round(coalesce(gf,prior_team_goals),2),
  round(coalesce(ga,prior_team_goals),2),
  round(coalesce(total,prior_total_goals),2),
  case when n=0 then 1::numeric else
    greatest(.82,least(1.18,
      1 + ((gf/prior_team_goals)-1)*w*.30
    ))
  end,
  case when n=0 then 1::numeric else
    greatest(.86,least(1.14,
      1 + ((ga/prior_team_goals)-1)*w*.25
    ))
  end,
  case when n=0 then 1::numeric else
    greatest(.88,least(1.12,
      1 + ((total/prior_total_goals)-1)*w*.40
    ))
  end
from calc;
$$;

create or replace function private.expected_xg(p_match_id text)
returns table(home_xg numeric, away_xg numeric)
language plpgsql
stable
set search_path = 'public', 'private'
as $$
declare
  m public.matches%rowtype;
  h public.clubs%rowtype;
  a public.clubs%rowtype;
  hf numeric;
  af numeric;
  h_atk numeric;
  h_mid numeric;
  h_def numeric;
  a_atk numeric;
  a_mid numeric;
  a_def numeric;
  mid_edge numeric;
  quality_edge numeric;
  tempo numeric;
  hgp record;
  agp record;
  profile_tempo numeric:=1;
begin
  select * into m from public.matches where id=p_match_id;
  if not found then return; end if;

  select * into h from public.clubs where id=m.home_club_id;
  select * into a from public.clubs where id=m.away_club_id;

  -- Result form is sport-specific and strictly pre-match.
  hf := private.result_form_before(h.id,m.sport,m.season,m.kickoff_at);
  af := private.result_form_before(a.id,m.sport,m.season,m.kickoff_at);

  h_atk := h.attack + hf*.70;
  h_mid := h.midfield + hf*.50;
  h_def := h.defense + hf*.45;
  a_atk := a.attack + af*.70;
  a_mid := a.midfield + af*.50;
  a_def := a.defense + af*.45;

  mid_edge := (h_mid-a_mid)/10.0;
  quality_edge := (
    ((h_atk+h_mid+h_def)/3.0) - ((a_atk+a_mid+a_def)/3.0)
  )/10.0;

  if m.sport='efootball' then
    tempo := (((h.seed*7+a.seed*11+m.match_index)%7)-3)*.030;
    home_xg := greatest(.95,least(3.25,
      2.15 + ((h_atk-a_def)/10.0)*.15 + mid_edge*.04 + tempo
    ));
    away_xg := greatest(.85,least(3.00,
      1.85 + ((a_atk-h_def)/10.0)*.15 - mid_edge*.035 + tempo
    ));
  else
    tempo := (((h.seed*3+a.seed*5)%5)-2)*.015;
    home_xg := greatest(.52,least(2.65,
      1.32
      + ((h_atk-a_def)/10.0)*.23
      + mid_edge*.06
      + quality_edge*.18
      + tempo
    ));
    away_xg := greatest(.45,least(2.55,
      1.12
      + ((a_atk-h_def)/10.0)*.23
      - mid_edge*.055
      - quality_edge*.18
      + tempo
    ));
  end if;

  -- Scoring identity: last 10 same-sport matches, with strong small-sample
  -- shrinkage. Attack, defensive vulnerability and game tempo are separate.
  select * into hgp
  from private.recent_goal_profile(h.id,m.sport,m.season,m.kickoff_at);

  select * into agp
  from private.recent_goal_profile(a.id,m.sport,m.season,m.kickoff_at);

  profile_tempo := (coalesce(hgp.tempo_factor,1)+coalesce(agp.tempo_factor,1))/2;

  if m.sport='efootball' then
    home_xg := greatest(.95,least(3.25,
      home_xg
      * coalesce(hgp.attack_factor,1)
      * coalesce(agp.concede_factor,1)
      * profile_tempo
    ));
    away_xg := greatest(.85,least(3.00,
      away_xg
      * coalesce(agp.attack_factor,1)
      * coalesce(hgp.concede_factor,1)
      * profile_tempo
    ));
  else
    home_xg := greatest(.52,least(2.65,
      home_xg
      * coalesce(hgp.attack_factor,1)
      * coalesce(agp.concede_factor,1)
      * profile_tempo
    ));
    away_xg := greatest(.45,least(2.55,
      away_xg
      * coalesce(agp.attack_factor,1)
      * coalesce(hgp.concede_factor,1)
      * profile_tempo
    ));
  end if;

  return next;
end;
$$;

-- Reprice only markets that are currently published and have not started.
do $$
declare
  r record;
begin
  for r in
    select distinct m.id
    from public.matches m
    join public.match_markets mm on mm.match_id=m.id
    where m.status='scheduled'
  loop
    perform private.refresh_match_markets(r.id);
  end loop;
end;
$$;
