-- Project Afyon 0.53.1 — Pre-AFMB career archive
-- Gives seeded career records readable recent history without affecting live AFMB rematches,
-- titles, ratings, scheduling or settlement.

create table if not exists public.boxing_legacy_history (
  id bigint generated always as identity primary key,
  fighter_id text not null references public.boxing_fighters(id) on delete cascade,
  fought_at timestamptz not null,
  opponent_name text not null,
  opponent_country text not null,
  result text not null check (result in ('W','L','D')),
  method text not null check (method in ('KO','TKO','UD','SD','MD','DRAW')),
  finish_round smallint check (finish_round between 1 and 12),
  created_at timestamptz not null default now()
);

create index if not exists boxing_legacy_history_fighter_date_idx
on public.boxing_legacy_history(fighter_id,fought_at desc);

alter table public.boxing_legacy_history enable row level security;
drop policy if exists boxing_legacy_history_public_read on public.boxing_legacy_history;
create policy boxing_legacy_history_public_read
on public.boxing_legacy_history
for select
to anon,authenticated
using (true);
grant select on public.boxing_legacy_history to anon,authenticated;

do $$
declare
  f public.boxing_fighters%rowtype;
  n integer;
  v_result text;
  v_method text;
  v_round integer;
  v_names text[]:=array[
    'Milan Kovač','Rafael Duarte','Noah Berg','Yusuf Karim','Matteo Ricci',
    'Ivan Petrov','Sami Haddad','Hugo Martins','Daniel Okoro','Leo Novak',
    'André Silva','Marek Zielinski','Nico Alvarez','Omar Benali','Felix Werner'
  ];
  v_countries text[]:=array[
    'Hırvatistan','İspanya','İsveç','Fas','İtalya',
    'Sırbistan','Tunus','Portekiz','Nijerya','Çekya',
    'Fransa','Polonya','Arjantin','Cezayir','Almanya'
  ];
  idx integer;
  ko_recent integer;
begin
  for f in
    select * from public.boxing_fighters
    where is_active
    order by seed,id
  loop
    if exists(select 1 from public.boxing_legacy_history where fighter_id=f.id) then
      continue;
    end if;

    ko_recent:=least(4,greatest(0,round((f.kos::numeric/greatest(1,f.wins))*5)::integer));

    for n in 1..5 loop
      if n<=least(f.streak_count,5) then
        v_result:=coalesce(f.streak_type,'W');
      elsif f.draws>0 and mod(f.seed+n,5)=0 then
        v_result:='D';
      elsif f.losses>0 and mod(f.seed+n,3)=0 then
        v_result:='L';
      else
        v_result:='W';
      end if;

      if v_result='D' then
        v_method:='DRAW';
        v_round:=10;
      elsif v_result='W' then
        if n<=ko_recent then
          v_method:=case when mod(f.seed+n,2)=0 then 'KO' else 'TKO' end;
          v_round:=2+mod(f.seed+n*3,7);
        else
          v_method:=case when mod(f.seed+n,4)=0 then 'SD' else 'UD' end;
          v_round:=10;
        end if;
      else
        if mod(f.seed+n,4)=0 then
          v_method:='TKO';
          v_round:=4+mod(f.seed+n,5);
        else
          v_method:=case when mod(f.seed+n,3)=0 then 'SD' else 'UD' end;
          v_round:=10;
        end if;
      end if;

      idx:=1+mod(abs(f.seed*3+n*5),array_length(v_names,1));

      insert into public.boxing_legacy_history(
        fighter_id,fought_at,opponent_name,opponent_country,result,method,finish_round
      ) values(
        f.id,
        (timestamp with time zone '2026-09-10 20:00:00+03')
          - make_interval(days=>(n*13+mod(abs(f.seed),7))),
        v_names[idx],
        v_countries[idx],
        v_result,
        v_method,
        v_round
      );
    end loop;
  end loop;
end;
$$;

create or replace function public.get_boxing_fighter_history(
  p_fighter_id text,
  p_limit integer default 8
)
returns table(
  bout_id text,
  event_name text,
  scheduled_at timestamptz,
  opponent_id text,
  opponent_name text,
  opponent_country text,
  result text,
  method text,
  finish_round smallint,
  is_title_fight boolean,
  rematch_no smallint
)
language sql
stable
security invoker
set search_path='public'
as $$
  select *
  from (
    select
      b.id as bout_id,
      b.event_name,
      b.scheduled_at,
      case when b.red_fighter_id=p_fighter_id then b.blue_fighter_id else b.red_fighter_id end as opponent_id,
      opp.name as opponent_name,
      opp.country as opponent_country,
      case
        when b.winner_id is null then 'D'
        when b.winner_id=p_fighter_id then 'W'
        else 'L'
      end as result,
      b.method,
      b.finish_round,
      b.is_title_fight,
      b.rematch_no
    from public.boxing_bouts b
    join public.boxing_fighters opp
      on opp.id=case when b.red_fighter_id=p_fighter_id then b.blue_fighter_id else b.red_fighter_id end
    where b.status='finished'
      and (b.red_fighter_id=p_fighter_id or b.blue_fighter_id=p_fighter_id)

    union all

    select
      'LEGACY|'||h.id::text,
      'AFMB Öncesi Kariyer',
      h.fought_at,
      null::text,
      h.opponent_name,
      h.opponent_country,
      h.result,
      h.method,
      h.finish_round,
      false,
      1::smallint
    from public.boxing_legacy_history h
    where h.fighter_id=p_fighter_id
  ) x
  order by scheduled_at desc
  limit greatest(1,least(coalesce(p_limit,8),20))
$$;

grant execute on function public.get_boxing_fighter_history(text,integer) to anon,authenticated;
