-- Project Afyon 0.35 — strength-gap odds rebalance
-- Football xG now reacts more strongly to team-quality differences and uses a
-- slightly smaller home-field baseline. e-Football tuning is unchanged.
-- Reprice only scheduled football matches that already have published markets.

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
begin
  select * into m from public.matches where id=p_match_id;
  select * into h from public.clubs where id=m.home_club_id;
  select * into a from public.clubs where id=m.away_club_id;

  hf := private.form_modifier(h.id,m.season,m.week);
  af := private.form_modifier(a.id,m.season,m.week);

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
    -- Arcade profile unchanged.
    tempo := (((h.seed*7+a.seed*11+m.match_index)%7)-3)*.030;
    home_xg := greatest(.95,least(3.25,
      2.15 + ((h_atk-a_def)/10.0)*.15 + mid_edge*.04 + tempo
    ));
    away_xg := greatest(.85,least(3.00,
      1.85 + ((a_atk-h_def)/10.0)*.15 - mid_edge*.035 + tempo
    ));
  else
    -- Football v2:
    -- 1) slightly smaller home baseline,
    -- 2) stronger attack-v-defense impact,
    -- 3) explicit whole-team quality gap so a 10 OVR gap matters.
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

  return next;
end;
$$;

do $$
declare
  r record;
begin
  for r in
    select distinct m.id
    from public.matches m
    join public.match_markets mm on mm.match_id=m.id
    where m.status='scheduled'
      and m.sport='football'
  loop
    perform private.refresh_match_markets(r.id);
  end loop;
end;
$$;
