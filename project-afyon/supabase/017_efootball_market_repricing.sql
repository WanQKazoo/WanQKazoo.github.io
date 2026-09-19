-- Project Afyon 0.28 — e-Football market repricing
-- e-Football averages roughly four total goals, so its goal-market odds
-- must not reuse the long-form football floors.

create or replace function private.refresh_match_markets(p_match_id text)
returns void
language plpgsql
security definer
set search_path = 'public','private'
as $$
declare
  m public.matches%rowtype;
  x record;
  h integer;
  a integer;
  p numeric;
  total_mass numeric:=0;
  p1 numeric:=0;
  px numeric:=0;
  p2 numeric:=0;
  btts numeric:=0;
  u15 numeric:=0;
  u25 numeric:=0;
  u35 numeric:=0;
begin
  select * into m from public.matches where id=p_match_id;
  if not found or m.status<>'scheduled' then return; end if;

  select * into x from private.expected_xg(m.id);

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

  p1:=p1/total_mass;
  px:=px/total_mass;
  p2:=p2/total_mass;
  btts:=btts/total_mass;
  u15:=u15/total_mass;
  u25:=u25/total_mass;
  u35:=u35/total_mass;

  delete from public.match_markets where match_id=m.id;

  if m.sport='efootball' then
    insert into public.match_markets(match_id,market_key,selection_key,odd,locked) values
      (m.id,'1X2','1',private.fair_odd(p1,1.06,1.20,7.20),false),
      (m.id,'1X2','X',private.fair_odd(px,1.06,3.00,5.80),false),
      (m.id,'1X2','2',private.fair_odd(p2,1.06,1.20,7.20),false),
      (m.id,'OU15','UNDER',private.fair_odd(u15,1.05,4.50,8.50),false),
      (m.id,'OU15','OVER', private.fair_odd(1-u15,1.05,1.05,1.18),false),
      (m.id,'OU25','UNDER',private.fair_odd(u25,1.05,2.60,5.20),false),
      (m.id,'OU25','OVER', private.fair_odd(1-u25,1.05,1.12,1.45),false),
      (m.id,'OU35','UNDER',private.fair_odd(u35,1.05,1.75,2.85),false),
      (m.id,'OU35','OVER', private.fair_odd(1-u35,1.05,1.45,2.15),false),
      (m.id,'BTTS','YES',private.fair_odd(btts,1.05,1.18,1.55),false),
      (m.id,'BTTS','NO', private.fair_odd(1-btts,1.05,2.40,4.50),false),
      (m.id,'DC','1X',private.fair_odd(p1+px,1.035,1.06,2.45),false),
      (m.id,'DC','12',private.fair_odd(p1+p2,1.035,1.06,2.45),false),
      (m.id,'DC','X2',private.fair_odd(px+p2,1.035,1.06,2.45),false);
  else
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
  end if;
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
