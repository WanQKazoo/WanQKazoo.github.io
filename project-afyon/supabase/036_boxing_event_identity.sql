-- Project Afyon 0.53.2 — Kemer Gecesi identity + legacy archive variety

with ranked as (
  select
    h.id,
    f.seed,
    row_number() over(partition by h.fighter_id order by h.fought_at desc,h.id) as rn
  from public.boxing_legacy_history h
  join public.boxing_fighters f on f.id=h.fighter_id
),
mapped as (
  select
    id,
    (array[
      'Milan Kovač','Rafael Duarte','Noah Berg','Yusuf Karim','Matteo Ricci',
      'Ivan Petrov','Sami Haddad','Hugo Martins','Daniel Okoro','Leo Novak',
      'André Silva','Marek Zielinski','Nico Alvarez','Omar Benali','Felix Werner'
    ])[1+mod(abs(seed*7+rn::integer*4),15)] as opponent_name,
    (array[
      'Hırvatistan','İspanya','İsveç','Fas','İtalya',
      'Sırbistan','Tunus','Portekiz','Nijerya','Çekya',
      'Fransa','Polonya','Arjantin','Cezayir','Almanya'
    ])[1+mod(abs(seed*7+rn::integer*4),15)] as opponent_country
  from ranked
)
update public.boxing_legacy_history h
set opponent_name=m.opponent_name,
    opponent_country=m.opponent_country
from mapped m
where m.id=h.id;

update public.boxing_bouts b
set event_name=split_part(b.event_name,' • ',1)||' • Kemer Gecesi'
where exists(
  select 1
  from public.boxing_bouts x
  where (x.scheduled_at at time zone 'Europe/Istanbul')::date
        =(b.scheduled_at at time zone 'Europe/Istanbul')::date
    and x.is_title_fight
)
and b.event_name not like '%Kemer Gecesi%';

create or replace function private.ensure_boxing_schedule(p_date date)
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  v_weights text[]:=array['LIGHTWEIGHT','WELTERWEIGHT','MIDDLEWEIGHT','LIGHT_HEAVYWEIGHT','HEAVYWEIGHT'];
  v_weight text;
  v_ids text[];
  v_i integer;
  v_day integer:=p_date-date '2026-09-20';
  v_shift integer;
  v_red text;
  v_blue text;
  v_main integer:=mod(abs(p_date-date '2026-09-20'),5)+1;
  v_order integer;
  v_start timestamptz;
  v_event_no integer:=greatest(1,(p_date-date '2026-09-20')+1);
  v_event_name text;
  v_title_fight boolean;
  v_champion text;
  v_prev_meetings integer;
begin
  if exists(
    select 1 from public.boxing_bouts
    where (scheduled_at at time zone 'Europe/Istanbul')::date=p_date
  ) then return; end if;

  v_event_name:='AFMB Fight Night #'||v_event_no||
    case when mod(v_event_no,3)=0 then ' • Kemer Gecesi' else '' end;

  for v_i in 1..5 loop
    v_weight:=v_weights[v_i];
    select array_agg(id order by seed,id) into v_ids
    from public.boxing_fighters
    where weight_class=v_weight and is_active;

    if coalesce(array_length(v_ids,1),0)<4 then continue; end if;

    v_title_fight:=v_i=v_main and mod(v_event_no,3)=0;
    v_champion:=null;

    if v_title_fight then
      select champion_id into v_champion
      from public.boxing_titles
      where weight_class=v_weight;

      if v_champion is not null then
        v_red:=v_champion;
        select id into v_blue
        from public.boxing_fighters
        where weight_class=v_weight
          and is_active
          and id<>v_champion
        order by rating desc,wins desc,seed
        limit 1;
      else
        v_title_fight:=false;
      end if;
    end if;

    if not v_title_fight then
      v_shift:=mod(abs(v_day+v_i-1),array_length(v_ids,1));
      v_red:=v_ids[v_shift+1];
      v_blue:=v_ids[mod(v_shift+2,array_length(v_ids,1))+1];
    end if;

    v_order:=case when v_i=v_main then 5 when v_i<v_main then v_i else v_i-1 end;
    v_start:=make_timestamptz(
      extract(year from p_date)::int,
      extract(month from p_date)::int,
      extract(day from p_date)::int,
      20,30,0,'Europe/Istanbul'
    ) + make_interval(mins=>(v_order-1)*12);

    select count(*)::integer into v_prev_meetings
    from public.boxing_bouts old
    where old.status='finished'
      and (
        (old.red_fighter_id=v_red and old.blue_fighter_id=v_blue)
        or
        (old.red_fighter_id=v_blue and old.blue_fighter_id=v_red)
      );

    insert into public.boxing_bouts(
      id,event_name,scheduled_at,weight_class,red_fighter_id,blue_fighter_id,
      status,rounds,duration_seconds,card_order,is_main_event,venue,is_title_fight,rematch_no
    ) values(
      'BX|'||to_char(p_date,'YYYYMMDD')||'|'||v_weight,
      v_event_name,
      v_start,v_weight,v_red,v_blue,'scheduled',
      case when v_i=v_main then 12 else 10 end,
      case when v_i=v_main then 720 else 600 end,
      v_order,v_i=v_main,'AFMB Arena',v_title_fight,greatest(1,v_prev_meetings+1)
    )
    on conflict(id) do nothing;
  end loop;
end;
$$;
