-- Project Afyon 0.41 — stronger recent-goal trend pricing
-- Recent scoring/conceding/tempo profiles now influence xG more meaningfully,
-- while still shrinking small samples toward sport priors.

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
    case when a.n=0 then 0::numeric else a.n::numeric/(a.n+3)::numeric end as w
  from agg a
  cross join params p
)
select
  n,
  round(coalesce(gf,prior_team_goals),2),
  round(coalesce(ga,prior_team_goals),2),
  round(coalesce(total,prior_total_goals),2),
  case when n=0 then 1::numeric else
    greatest(.78,least(1.22,
      1 + ((gf/prior_team_goals)-1)*w*.40
    ))
  end,
  case when n=0 then 1::numeric else
    greatest(.84,least(1.16,
      1 + ((ga/prior_team_goals)-1)*w*.25
    ))
  end,
  case when n=0 then 1::numeric else
    greatest(.86,least(1.14,
      1 + ((total/prior_total_goals)-1)*w*.50
    ))
  end
from calc;
$$;

-- Reprice only currently published scheduled markets.
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
