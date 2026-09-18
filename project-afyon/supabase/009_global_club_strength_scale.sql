-- Project Afyon 0.23 — Global club strength scale
-- One rating scale for all 1,080 clubs.

alter table public.clubs drop constraint if exists clubs_attack_check;
alter table public.clubs drop constraint if exists clubs_midfield_check;
alter table public.clubs drop constraint if exists clubs_defense_check;

alter table public.clubs add constraint clubs_attack_check check (attack between 20 and 99);
alter table public.clubs add constraint clubs_midfield_check check (midfield between 20 and 99);
alter table public.clubs add constraint clubs_defense_check check (defense between 20 and 99);

with ranked as (
  select
    c.id,c.country,c.league_level,c.name,c.seed,c.style,
    row_number() over (
      partition by c.country,c.league_level
      order by c.base_strength desc,c.overall desc,c.name
    ) as rn,
    case c.country
      when 'İngiltere' then 82
      when 'İspanya' then 81
      when 'İtalya' then 80
      when 'Almanya' then 80
      when 'Fransa' then 78
      when 'Hollanda' then 76
      when 'Portekiz' then 76
      when 'Türkiye' then 74
      when 'Belçika' then 72
      when 'İskoçya' then 71
      when 'Yunanistan' then 69
      when 'Avusturya' then 69
      else 70
    end as country_base,
    case c.league_level
      when 1 then 0 when 2 then -13 when 3 then -24
      when 4 then -33 when 5 then -40 else 0
    end as league_delta
  from public.clubs c
),
targets as (
  select
    r.*,
    (
      country_base + league_delta +
      case league_level
        when 1 then case rn
          when 1 then 12 when 2 then 10 when 3 then 7 when 4 then 5
          when 5 then 3 when 6 then 2 when 7 then 1 when 8 then 0
          when 9 then 0 when 10 then -1 when 11 then -2 when 12 then -3
          when 13 then -4 when 14 then -5 when 15 then -6 when 16 then -7
          when 17 then -8 else -10 end
        when 2 then case rn
          when 1 then 8 when 2 then 7 when 3 then 6 when 4 then 5
          when 5 then 4 when 6 then 3 when 7 then 2 when 8 then 1
          when 9 then 0 when 10 then 0 when 11 then -1 when 12 then -2
          when 13 then -3 when 14 then -4 when 15 then -5 when 16 then -6
          when 17 then -7 else -8 end
        when 3 then case rn
          when 1 then 7 when 2 then 6 when 3 then 5 when 4 then 4
          when 5 then 3 when 6 then 2 when 7 then 1 when 8 then 1
          when 9 then 0 when 10 then 0 when 11 then -1 when 12 then -1
          when 13 then -2 when 14 then -3 when 15 then -4 when 16 then -5
          when 17 then -6 else -7 end
        when 4 then case rn
          when 1 then 6 when 2 then 5 when 3 then 4 when 4 then 3
          when 5 then 2 when 6 then 2 when 7 then 1 when 8 then 1
          when 9 then 0 when 10 then 0 when 11 then -1 when 12 then -1
          when 13 then -2 when 14 then -2 when 15 then -3 when 16 then -4
          when 17 then -5 else -6 end
        else case rn
          when 1 then 5 when 2 then 4 when 3 then 3 when 4 then 3
          when 5 then 2 when 6 then 2 when 7 then 1 when 8 then 1
          when 9 then 0 when 10 then 0 when 11 then -1 when 12 then -1
          when 13 then -2 when 14 then -2 when 15 then -3 when 16 then -3
          when 17 then -4 else -5 end
      end
    )::integer as target,
    ((seed % 3) - 1)::integer as jitter
  from ranked r
),
lines as (
  select
    t.*,
    case style
      when 'Hücumcu' then 4 when 'Savunmacı' then -4 when 'Kontrol' then -2
      when 'Kontra' then 3 when 'Kaotik' then 4 else 0 end as atk_delta,
    case style
      when 'Hücumcu' then 1 when 'Savunmacı' then 0 when 'Kontrol' then 4
      when 'Kontra' then -3 when 'Kaotik' then -1 else 0 end as mid_delta,
    case style
      when 'Hücumcu' then -5 when 'Savunmacı' then 4 when 'Kontrol' then -2
      when 'Kontra' then 0 when 'Kaotik' then -3 else 0 end as def_delta
  from targets t
)
update public.clubs c
set
  base_strength = l.target,
  attack = greatest(20,least(99,l.target+l.atk_delta+l.jitter)),
  midfield = greatest(20,least(99,l.target+l.mid_delta-l.jitter)),
  defense = greatest(20,least(99,l.target+l.def_delta)),
  tier = case when l.rn<=4 then 'favorite' when l.rn>=15 then 'relegation' else 'mid' end
from lines l
where c.id=l.id;

do $$
declare
  s integer;
  w integer;
  ph text;
begin
  select season,week,phase into s,w,ph from public.world_state where id=1;
  if ph='betting' then
    perform private.refresh_week_markets(s,w);
  end if;
end;
$$;
