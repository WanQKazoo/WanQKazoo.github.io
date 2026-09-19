-- Project Afyon 0.32 — e-Football daily rotation fix
-- The original seed formula repeated the same home club whenever a country
-- reappeared six slots later. Rebalance every still-scheduled e-Football match
-- so daily appearances rotate through different clubs, then rebuild markets.
-- Live/finished history is intentionally preserved.

create or replace function private.rebalance_efootball_schedule()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_updated integer := 0;
  r record;
begin
  with club_rank as (
    select
      c.id,
      c.country,
      row_number() over (
        partition by c.country
        order by c.seed, c.name
      )::integer as rn
    from public.clubs c
    where c.league_level = 1
  ),
  ordered as (
    select
      m.id,
      m.season,
      m.week,
      m.country,
      (
        row_number() over (
          partition by
            m.season,
            m.week,
            m.country,
            (m.kickoff_at at time zone 'Europe/Istanbul')::date
          order by m.kickoff_at, m.id
        ) - 1
      )::integer as appearance_no,
      coalesce(
        array_position(
          array[
            'İngiltere','Türkiye','İspanya','Almanya','İtalya','Fransa',
            'Hollanda','Portekiz','Belçika','İskoçya','Yunanistan','Avusturya'
          ]::text[],
          m.country
        ),
        1
      )::integer as country_no
    from public.matches m
    where m.sport = 'efootball'
  ),
  target_rank as (
    select
      o.*,
      1 + mod(o.week * 7 + o.country_no * 3 + o.appearance_no * 5, 18) as home_rn
    from ordered o
  ),
  target as (
    select
      t.id,
      h.id as home_club_id,
      a.id as away_club_id
    from target_rank t
    join club_rank h
      on h.country = t.country
     and h.rn = t.home_rn
    join club_rank a
      on a.country = t.country
     and a.rn = (
       1 + mod(
         (t.home_rn - 1)
         + (1 + mod(t.appearance_no * 2 + 6, 17)),
         18
       )
     )
  )
  update public.matches m
  set home_club_id = t.home_club_id,
      away_club_id = t.away_club_id
  from target t
  where m.id = t.id
    and m.status = 'scheduled'
    and m.sport = 'efootball'
    and (
      m.home_club_id is distinct from t.home_club_id
      or m.away_club_id is distinct from t.away_club_id
    );

  get diagnostics v_updated = row_count;

  for r in
    select m.id
    from public.matches m
    where m.sport = 'efootball'
      and m.status = 'scheduled'
  loop
    perform private.refresh_match_markets(r.id);
  end loop;

  return v_updated;
end;
$$;

select private.rebalance_efootball_schedule();
