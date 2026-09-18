-- Project Afyon 0.24 — Goal market balance
-- Keeps xG in a tighter range and caps Alt/Üst + KG odds to playable bands.

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
  tempo := (((h.seed*3+a.seed*5)%5)-2)*.015;

  home_xg := greatest(.58,least(2.45,1.38+((h_atk-a_def)/10.0)*.18+mid_edge*.05+tempo));
  away_xg := greatest(.48,least(2.25,1.08+((a_atk-h_def)/10.0)*.18-mid_edge*.045+tempo));
  return next;
end;
$$;

create or replace function private.refresh_week_markets(p_season integer,p_week integer)
returns void
language plpgsql
security definer
set search_path = 'public','private'
as $$
declare
  m record;
  x record;
  h integer;
  a integer;
  p numeric;
  total_mass numeric;
  p1 numeric;
  px numeric;
  p2 numeric;
  btts numeric;
  u15 numeric;
  u25 numeric;
  u35 numeric;
begin
  delete from public.match_markets mm
  using public.matches mt
  where mm.match_id=mt.id
    and mt.season=p_season
    and mt.week=p_week
    and mt.status='scheduled';

  for m in
    select id from public.matches
    where season=p_season and week=p_week and status='scheduled'
  loop
    select * into x from private.expected_xg(m.id);

    total_mass:=0;p1:=0;px:=0;p2:=0;btts:=0;u15:=0;u25:=0;u35:=0;
    for h in 0..8 loop
      for a in 0..8 loop
        p := private.poisson_probability(x.home_xg,h) * private.poisson_probability(x.away_xg,a);
        total_mass:=total_mass+p;
        if h>a then p1:=p1+p;
        elsif h=a then px:=px+p;
        else p2:=p2+p;
        end if;
        if h>0 and a>0 then btts:=btts+p; end if;
        if h+a<1.5 then u15:=u15+p; end if;
        if h+a<2.5 then u25:=u25+p; end if;
        if h+a<3.5 then u35:=u35+p; end if;
      end loop;
    end loop;

    p1:=p1/total_mass;px:=px/total_mass;p2:=p2/total_mass;
    btts:=btts/total_mass;u15:=u15/total_mass;u25:=u25/total_mass;u35:=u35/total_mass;

    insert into public.match_markets(match_id,market_key,selection_key,odd,locked) values
      (m.id,'1X2','1',private.fair_odd(p1,1.06,1.25,6.80),false),
      (m.id,'1X2','X',private.fair_odd(px,1.06,2.65,4.80),false),
      (m.id,'1X2','2',private.fair_odd(p2,1.06,1.25,6.80),false),
      (m.id,'OU15','UNDER',private.fair_odd(u15,1.06,2.15,3.30),false),
      (m.id,'OU15','OVER', private.fair_odd(1-u15,1.06,1.30,1.70),false),
      (m.id,'OU25','UNDER',private.fair_odd(u25,1.055,1.55,2.35),false),
      (m.id,'OU25','OVER', private.fair_odd(1-u25,1.055,1.55,2.35),false),
      (m.id,'OU35','UNDER',private.fair_odd(u35,1.06,1.30,1.75),false),
      (m.id,'OU35','OVER', private.fair_odd(1-u35,1.06,2.15,3.30),false),
      (m.id,'BTTS','YES',private.fair_odd(btts,1.055,1.55,2.35),false),
      (m.id,'BTTS','NO', private.fair_odd(1-btts,1.055,1.55,2.35),false),
      (m.id,'DC','1X',private.fair_odd(p1+px,1.035,1.08,2.35),false),
      (m.id,'DC','12',private.fair_odd(p1+p2,1.035,1.08,2.35),false),
      (m.id,'DC','X2',private.fair_odd(px+p2,1.035,1.08,2.35),false);
  end loop;
end;
$$;

do $$
declare s integer; w integer; ph text;
begin
  select season,week,phase into s,w,ph from public.world_state where id=1;
  if ph='betting' then perform private.refresh_week_markets(s,w); end if;
end;
$$;
