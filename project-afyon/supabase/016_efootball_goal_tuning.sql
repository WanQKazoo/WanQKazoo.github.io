-- Project Afyon 0.28 — e-Football goal tuning
-- Makes the fast mode visibly more arcade/high-scoring while preserving football tuning.

create or replace function private.expected_xg(p_match_id text)
returns table(home_xg numeric, away_xg numeric)
language plpgsql
stable
set search_path = 'public','private'
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
    home_xg := greatest(.58,least(2.45,
      1.38+((h_atk-a_def)/10.0)*.18+mid_edge*.05+tempo
    ));
    away_xg := greatest(.48,least(2.25,
      1.08+((a_atk-h_def)/10.0)*.18-mid_edge*.045+tempo
    ));
  end if;

  return next;
end;
$$;

do $$
declare r record;
begin
  for r in
    select m.id
    from public.matches m
    where m.sport='efootball'
      and m.status='scheduled'
      and m.kickoff_at>now()
  loop
    perform private.refresh_match_markets(r.id);
  end loop;
end;
$$;
