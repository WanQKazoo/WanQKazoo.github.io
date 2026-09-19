-- Project Afyon 0.51 — Boxing live engine + commentator
-- Boxing is deliberately slower than football:
--   regular bout: 10 rounds / 600 real seconds
--   main event:   12 rounds / 720 real seconds
-- Each round is 50 seconds of action + 10 seconds corner break.

alter table public.boxing_bouts
  add column if not exists rounds smallint not null default 10,
  add column if not exists duration_seconds integer not null default 600,
  add column if not exists started_at timestamptz,
  add column if not exists finished_at timestamptz,
  add column if not exists card_order smallint not null default 1,
  add column if not exists is_main_event boolean not null default false,
  add column if not exists venue text not null default 'AFMB Arena';

do $$
begin
  if not exists(
    select 1 from pg_constraint
    where conrelid='public.boxing_bouts'::regclass
      and conname='boxing_bouts_rounds_check'
  ) then
    alter table public.boxing_bouts
      add constraint boxing_bouts_rounds_check check (rounds between 4 and 12);
  end if;
  if not exists(
    select 1 from pg_constraint
    where conrelid='public.boxing_bouts'::regclass
      and conname='boxing_bouts_duration_check'
  ) then
    alter table public.boxing_bouts
      add constraint boxing_bouts_duration_check check (duration_seconds between 240 and 900);
  end if;
end;
$$;

create table if not exists public.boxing_bout_events (
  id bigint generated always as identity primary key,
  bout_id text not null references public.boxing_bouts(id) on delete cascade,
  round smallint not null check (round between 1 and 12),
  second_in_round smallint not null check (second_in_round between 0 and 59),
  event_type text not null check (event_type in (
    'jab','power_shot','combo','body_shot','counter',
    'knockdown','cut','warning','round_end','fight_end'
  )),
  side text not null check (side in ('red','blue','neutral')),
  payload jsonb not null default '{}'::jsonb,
  commentary text not null,
  visible_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index if not exists boxing_bout_events_visible_idx
on public.boxing_bout_events(bout_id,visible_at,id);

alter table public.boxing_bout_events enable row level security;
drop policy if exists boxing_bout_events_public_read on public.boxing_bout_events;
create policy boxing_bout_events_public_read
on public.boxing_bout_events
for select
to anon,authenticated
using (visible_at<=now());

create table if not exists private.boxing_bout_plans (
  bout_id text primary key references public.boxing_bouts(id) on delete cascade,
  winner_id text references public.boxing_fighters(id),
  method text not null check (method in ('KO','TKO','UD','SD','MD','DRAW')),
  finish_round smallint not null check (finish_round between 1 and 12),
  finish_second smallint not null check (finish_second between 0 and 59),
  planned_end_seconds integer not null check (planned_end_seconds between 1 and 900),
  red_judge_score integer,
  blue_judge_score integer,
  created_at timestamptz not null default now()
);

create or replace function private.boxing_commentary(
  p_event text,
  p_actor text,
  p_other text,
  p_round integer,
  p_variant integer default 0
)
returns text
language plpgsql
immutable
set search_path=''
as $$
begin
  if p_event='jab' then
    return case mod(p_variant,4)
      when 0 then p_actor||' mesafeyi jab ile ölçüyor. Temiz bir dokunuş.'
      when 1 then p_actor||' öndeki eli çalıştırdı; '||p_other||' bir an ritmini kaybetti.'
      when 2 then 'Hızlı jab! '||p_actor||' puanı aldı ve yeniden açı değiştirdi.'
      else p_actor||' jabı araya soktu. Bu raundun temposunu kurmaya çalışıyor.'
    end;
  elsif p_event='power_shot' then
    return case mod(p_variant,4)
      when 0 then 'SERT VURUŞ! '||p_actor||' sağ eliyle '||p_other||'''ı geriye itti!'
      when 1 then p_actor||' bütün ağırlığını yumruğa koydu. '||p_other||' bunu kesinlikle hissetti.'
      when 2 then 'Salon ayağa kalktı! '||p_actor||' çok ağır bir isabet buldu.'
      else p_actor||' gardın arasından güçlü bir yumruk geçirdi. Tehlikeli anlar!'
    end;
  elsif p_event='combo' then
    return case mod(p_variant,4)
      when 0 then p_actor||' üçlü kombinasyonla içeri girdi; son yumruk net oturdu.'
      when 1 then 'Kombinasyon geliyor! '||p_actor||' baş-gövde-baş çalıştı.'
      when 2 then p_actor||' seri yumruklarla '||p_other||'''ı iplere doğru sürüklüyor.'
      else 'Çok güzel seri! '||p_actor||' iki eli de devrede.'
    end;
  elsif p_event='body_shot' then
    return case mod(p_variant,3)
      when 0 then p_actor||' gövdeye indi. Bu yumrukların etkisi ilerleyen raundlarda çıkar.'
      when 1 then 'Karaciğer bölgesine sert vuruş! '||p_other||' dirseğini hemen aşağı çekti.'
      else p_actor||' gövdeyi ihmal etmiyor; '||p_other||'''ın nefesini hedefliyor.'
    end;
  elsif p_event='counter' then
    return case mod(p_variant,3)
      when 0 then 'Mükemmel kontra! '||p_actor||' saldırıyı okudu ve tam zamanında cevap verdi.'
      when 1 then p_other||' açıldı, '||p_actor||' beklediği boşluğu buldu.'
      else p_actor||' geri adımda kontra yakaladı. Zamanlama çok temiz.'
    end;
  elsif p_event='knockdown' then
    return 'YERDE! '||p_other||' yere düştü! '||p_actor||' raund '||p_round||'''da büyük hasar verdi, hakem sayıyor!';
  elsif p_event='cut' then
    return p_other||'''ın yüzünde kesik var. Doktor yakından bakıyor; '||p_actor||' o bölgeyi hedefleyebilir.';
  elsif p_event='warning' then
    return 'Hakem araya girdi ve '||p_actor||'''ı uyardı. Dövüş yeniden başlıyor.';
  elsif p_event='round_end' then
    return 'GONG! Raund '||p_round||' sona erdi. Köşeler şimdi nefes ve taktik peşinde.';
  end if;
  return 'Ringde hareketlilik var.';
end;
$$;

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
begin
  if exists(
    select 1 from public.boxing_bouts
    where (scheduled_at at time zone 'Europe/Istanbul')::date=p_date
  ) then return; end if;

  for v_i in 1..5 loop
    v_weight:=v_weights[v_i];
    select array_agg(id order by seed,id) into v_ids
    from public.boxing_fighters
    where weight_class=v_weight and is_active;

    if coalesce(array_length(v_ids,1),0)<4 then continue; end if;

    v_shift:=mod(abs(v_day+v_i-1),array_length(v_ids,1));
    v_red:=v_ids[v_shift+1];
    v_blue:=v_ids[mod(v_shift+2,array_length(v_ids,1))+1];

    v_order:=case when v_i=v_main then 5 when v_i<v_main then v_i else v_i-1 end;
    v_start:=make_timestamptz(
      extract(year from p_date)::int,
      extract(month from p_date)::int,
      extract(day from p_date)::int,
      20,30,0,'Europe/Istanbul'
    ) + make_interval(mins=>(v_order-1)*12);

    insert into public.boxing_bouts(
      id,event_name,scheduled_at,weight_class,red_fighter_id,blue_fighter_id,
      status,rounds,duration_seconds,card_order,is_main_event,venue
    ) values(
      'BX|'||to_char(p_date,'YYYYMMDD')||'|'||v_weight,
      'AFMB Fight Night #'||v_event_no,
      v_start,v_weight,v_red,v_blue,'scheduled',
      case when v_i=v_main then 12 else 10 end,
      case when v_i=v_main then 720 else 600 end,
      v_order,v_i=v_main,'AFMB Arena'
    )
    on conflict(id) do nothing;
  end loop;
end;
$$;

create or replace function private.create_boxing_bout_plan(p_bout_id text)
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  b public.boxing_bouts%rowtype;
  r public.boxing_fighters%rowtype;
  bl public.boxing_fighters%rowtype;
  v_red_quality numeric;
  v_blue_quality numeric;
  v_red_prob numeric;
  v_roll numeric;
  v_winner text;
  v_loser text;
  v_winner_side text;
  v_loser_side text;
  v_winner_power integer;
  v_loser_chin integer;
  v_ko_prob numeric;
  v_method text;
  v_finish_round integer;
  v_finish_second integer;
  v_end_seconds integer;
  v_round integer;
  v_event integer;
  v_second integer;
  v_global integer;
  v_side text;
  v_actor text;
  v_other text;
  v_type text;
  v_variant integer;
  v_round_red numeric;
  v_round_blue numeric;
  v_round_leader text;
  v_red_judge integer:=0;
  v_blue_judge integer:=0;
  v_decision_margin integer;
begin
  select * into b from public.boxing_bouts where id=p_bout_id for update;
  if not found or b.status<>'scheduled' or b.scheduled_at>now() then return; end if;

  if exists(select 1 from private.boxing_bout_plans where bout_id=b.id) then
    update public.boxing_bouts
      set status='live',started_at=coalesce(started_at,b.scheduled_at),updated_at=now()
      where id=b.id;
    return;
  end if;

  select * into r from public.boxing_fighters where id=b.red_fighter_id;
  select * into bl from public.boxing_fighters where id=b.blue_fighter_id;

  v_red_quality:=r.rating*.35+r.power*.20+r.speed*.15+r.defense*.10+r.chin*.10+r.stamina*.10;
  v_blue_quality:=bl.rating*.35+bl.power*.20+bl.speed*.15+bl.defense*.10+bl.chin*.10+bl.stamina*.10;
  v_red_prob:=1/(1+exp(-(v_red_quality-v_blue_quality)/8.0));
  v_red_prob:=greatest(.18,least(.82,v_red_prob));

  v_roll:=random();
  if v_roll<.025 then
    v_winner:=null;
    v_loser:=null;
    v_winner_side:='neutral';
    v_loser_side:='neutral';
    v_method:='DRAW';
    v_finish_round:=b.rounds;
    v_finish_second:=50;
    v_end_seconds:=b.duration_seconds;
  else
    if random()<v_red_prob then
      v_winner:=r.id; v_loser:=bl.id; v_winner_side:='red'; v_loser_side:='blue';
      v_winner_power:=r.power; v_loser_chin:=bl.chin;
    else
      v_winner:=bl.id; v_loser:=r.id; v_winner_side:='blue'; v_loser_side:='red';
      v_winner_power:=bl.power; v_loser_chin:=r.chin;
    end if;

    v_ko_prob:=greatest(.12,least(.58,.24+(v_winner_power-v_loser_chin)*.012));
    if random()<v_ko_prob then
      v_method:=case when random()<.58 then 'TKO' else 'KO' end;
      v_finish_round:=greatest(2,least(b.rounds,ceil(b.rounds*(.22+random()*.68))::integer));
      v_finish_second:=18+floor(random()*29)::integer;
      v_end_seconds:=(v_finish_round-1)*60+v_finish_second;
    else
      v_method:=case
        when random()<.68 then 'UD'
        when random()<.82 then 'SD'
        else 'MD'
      end;
      v_finish_round:=b.rounds;
      v_finish_second:=50;
      v_end_seconds:=b.duration_seconds;
    end if;
  end if;

  delete from public.boxing_bout_events where bout_id=b.id;

  for v_round in 1..v_finish_round loop
    v_round_red:=0;
    v_round_blue:=0;

    for v_event in 1..5 loop
      v_second:=5+floor(random()*41)::integer;
      v_global:=(v_round-1)*60+v_second;
      if v_global>=v_end_seconds then continue; end if;

      -- Stamina gradually matters more in later rounds.
      v_red_prob:=1/(1+exp(-(
        (v_red_quality-v_blue_quality)
        + ((r.stamina-bl.stamina)*(v_round::numeric/b.rounds)*.18)
      )/8.0));
      v_red_prob:=greatest(.20,least(.80,v_red_prob));

      if random()<v_red_prob then
        v_side:='red'; v_actor:=r.name; v_other:=bl.name;
        v_round_red:=v_round_red+1;
      else
        v_side:='blue'; v_actor:=bl.name; v_other:=r.name;
        v_round_blue:=v_round_blue+1;
      end if;

      v_roll:=random();
      v_type:=case
        when v_roll<.28 then 'jab'
        when v_roll<.48 then 'body_shot'
        when v_roll<.67 then 'combo'
        when v_roll<.84 then 'counter'
        else 'power_shot'
      end;
      v_variant:=floor(random()*12)::integer;

      insert into public.boxing_bout_events(
        bout_id,round,second_in_round,event_type,side,payload,commentary,visible_at
      ) values(
        b.id,v_round,v_second,v_type,v_side,
        jsonb_build_object('impact',
          case v_type when 'power_shot' then 3 when 'combo' then 2 when 'counter' then 2 else 1 end
        ),
        private.boxing_commentary(v_type,v_actor,v_other,v_round,v_variant),
        b.scheduled_at+make_interval(secs=>v_global)
      );
    end loop;

    -- Occasional non-finishing drama before the planned finish.
    if v_round<v_finish_round and random()<.07 then
      v_side:=case when random()<v_red_prob then 'red' else 'blue' end;
      if v_side='red' then v_actor:=r.name;v_other:=bl.name;v_round_red:=v_round_red+3;
      else v_actor:=bl.name;v_other:=r.name;v_round_blue:=v_round_blue+3; end if;
      v_second:=34+floor(random()*12)::integer;
      v_global:=(v_round-1)*60+v_second;
      insert into public.boxing_bout_events(
        bout_id,round,second_in_round,event_type,side,payload,commentary,visible_at
      ) values(
        b.id,v_round,v_second,'knockdown',v_side,
        jsonb_build_object('standing_count',8,'finish',false),
        private.boxing_commentary('knockdown',v_actor,v_other,v_round,0),
        b.scheduled_at+make_interval(secs=>v_global)
      );
    end if;

    if v_round_red>v_round_blue then
      v_red_judge:=v_red_judge+10; v_blue_judge:=v_blue_judge+9; v_round_leader:='red';
    elsif v_round_blue>v_round_red then
      v_blue_judge:=v_blue_judge+10; v_red_judge:=v_red_judge+9; v_round_leader:='blue';
    else
      v_red_judge:=v_red_judge+10; v_blue_judge:=v_blue_judge+10; v_round_leader:='even';
    end if;

    if v_round<v_finish_round or v_method not in ('KO','TKO') then
      v_global:=(v_round-1)*60+50;
      if v_global<v_end_seconds then
        insert into public.boxing_bout_events(
          bout_id,round,second_in_round,event_type,side,payload,commentary,visible_at
        ) values(
          b.id,v_round,50,'round_end','neutral',
          jsonb_build_object('leader',v_round_leader),
          private.boxing_commentary('round_end','', '',v_round,0),
          b.scheduled_at+make_interval(secs=>v_global)
        );
      end if;
    end if;
  end loop;

  if v_method in ('KO','TKO') then
    if v_winner_side='red' then v_actor:=r.name;v_other:=bl.name;
    else v_actor:=bl.name;v_other:=r.name; end if;

    insert into public.boxing_bout_events(
      bout_id,round,second_in_round,event_type,side,payload,commentary,visible_at
    ) values(
      b.id,v_finish_round,greatest(1,v_finish_second-5),'knockdown',v_winner_side,
      jsonb_build_object('standing_count',10,'finish',true),
      private.boxing_commentary('knockdown',v_actor,v_other,v_finish_round,0),
      b.scheduled_at+make_interval(secs=>greatest(1,v_end_seconds-5))
    );

    insert into public.boxing_bout_events(
      bout_id,round,second_in_round,event_type,side,payload,commentary,visible_at
    ) values(
      b.id,v_finish_round,v_finish_second,'fight_end',v_winner_side,
      jsonb_build_object('method',v_method,'winner_id',v_winner),
      'BİTTİ! Hakem maçı durdurdu. '||v_actor||' raund '||v_finish_round||'''da '||v_method||' ile kazandı!',
      b.scheduled_at+make_interval(secs=>v_end_seconds)
    );
  else
    if v_method='DRAW' then
      v_red_judge:=round(b.rounds*9.5)::int;
      v_blue_judge:=v_red_judge;
      insert into public.boxing_bout_events(
        bout_id,round,second_in_round,event_type,side,payload,commentary,visible_at
      ) values(
        b.id,b.rounds,50,'fight_end','neutral',
        jsonb_build_object('method','DRAW'),
        'Son gong! Hakem kartları eşitliği gösteriyor. Mücadele beraberlikle sonuçlandı.',
        b.scheduled_at+make_interval(secs=>b.duration_seconds)
      );
    else
      -- Ensure the selected winner also wins the scorecards.
      v_decision_margin:=greatest(2,abs(v_red_judge-v_blue_judge)+2);
      if v_winner_side='red' and v_red_judge<=v_blue_judge then v_red_judge:=v_blue_judge+v_decision_margin; end if;
      if v_winner_side='blue' and v_blue_judge<=v_red_judge then v_blue_judge:=v_red_judge+v_decision_margin; end if;

      if v_winner_side='red' then v_actor:=r.name; else v_actor:=bl.name; end if;
      insert into public.boxing_bout_events(
        bout_id,round,second_in_round,event_type,side,payload,commentary,visible_at
      ) values(
        b.id,b.rounds,50,'fight_end',v_winner_side,
        jsonb_build_object('method',v_method,'winner_id',v_winner,'red_score',v_red_judge,'blue_score',v_blue_judge),
        'Son gong! Hakem kartları açıklandı: '||v_actor||' '||v_method||' ile kazanıyor.',
        b.scheduled_at+make_interval(secs=>b.duration_seconds)
      );
    end if;
  end if;

  insert into private.boxing_bout_plans(
    bout_id,winner_id,method,finish_round,finish_second,planned_end_seconds,red_judge_score,blue_judge_score
  ) values(
    b.id,v_winner,v_method,v_finish_round,v_finish_second,v_end_seconds,v_red_judge,v_blue_judge
  );

  update public.boxing_bouts
  set status='live',started_at=b.scheduled_at,updated_at=now()
  where id=b.id;
end;
$$;

create or replace function private.finalize_boxing_bout(p_bout_id text)
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  b public.boxing_bouts%rowtype;
  p private.boxing_bout_plans%rowtype;
  v_loser text;
  v_winner_rating numeric;
  v_loser_rating numeric;
  v_gain numeric;
begin
  select * into b from public.boxing_bouts where id=p_bout_id for update;
  if not found or b.status<>'live' then return; end if;
  select * into p from private.boxing_bout_plans where bout_id=b.id;
  if not found then return; end if;
  if b.started_at+make_interval(secs=>p.planned_end_seconds)>now() then return; end if;

  if p.method='DRAW' or p.winner_id is null then
    update public.boxing_fighters
    set draws=draws+1,
        streak_count=case when streak_type='D' then streak_count+1 else 1 end,
        streak_type='D',
        updated_at=now()
    where id in (b.red_fighter_id,b.blue_fighter_id);
  else
    v_loser:=case when p.winner_id=b.red_fighter_id then b.blue_fighter_id else b.red_fighter_id end;
    select rating into v_winner_rating from public.boxing_fighters where id=p.winner_id;
    select rating into v_loser_rating from public.boxing_fighters where id=v_loser;
    v_gain:=greatest(.25,least(1.20,.45+(v_loser_rating-v_winner_rating)*.035));

    update public.boxing_fighters
    set wins=wins+1,
        kos=kos+case when p.method in ('KO','TKO') then 1 else 0 end,
        rating=least(99,rating+v_gain),
        streak_count=case when streak_type='W' then streak_count+1 else 1 end,
        streak_type='W',
        updated_at=now()
    where id=p.winner_id;

    update public.boxing_fighters
    set losses=losses+1,
        rating=greatest(20,rating-greatest(.15,v_gain*.55)),
        streak_count=case when streak_type='L' then streak_count+1 else 1 end,
        streak_type='L',
        updated_at=now()
    where id=v_loser;
  end if;

  update public.boxing_bouts
  set status='finished',
      winner_id=p.winner_id,
      method=p.method,
      finish_round=p.finish_round,
      finished_at=b.started_at+make_interval(secs=>p.planned_end_seconds),
      updated_at=now()
  where id=b.id;
end;
$$;

create or replace function public.tick_world()
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  v_season integer; v_week integer; r record; p private.match_plans%rowtype;
  v_phase text; v_event_home integer; v_event_away integer;
  br record;
begin
  -- Keep a current + next-day Fight Night card available.
  perform private.ensure_boxing_schedule((now() at time zone 'Europe/Istanbul')::date);
  perform private.ensure_boxing_schedule((now() at time zone 'Europe/Istanbul')::date+1);

  for br in
    select id from public.boxing_bouts
    where status='scheduled' and scheduled_at<=now()
    order by scheduled_at
    for update skip locked
  loop
    perform private.create_boxing_bout_plan(br.id);
  end loop;

  for br in
    select b.id
    from public.boxing_bouts b
    join private.boxing_bout_plans bp on bp.bout_id=b.id
    where b.status='live'
      and b.started_at+make_interval(secs=>bp.planned_end_seconds)<=now()
    order by b.started_at
    for update of b skip locked
  loop
    perform private.finalize_boxing_bout(br.id);
  end loop;

  select season into v_season from public.world_state where id=1;
  if v_season is null then return; end if;
  select week into v_week from public.season_calendar
   where season=v_season and play_date=(now() at time zone 'Europe/Istanbul')::date;
  if v_week is not null then
    update public.world_state set week=v_week,updated_at=now() where id=1;
    if not exists(
      select 1 from public.match_markets mm join public.matches m on m.id=mm.match_id
      where m.season=v_season and m.week=v_week and m.sport='football'
    ) then perform private.refresh_week_markets(v_season,v_week); end if;
  else select week into v_week from public.world_state where id=1; end if;

  for r in
    select id from public.matches where season=v_season and status='scheduled' and kickoff_at<=now()
    order by kickoff_at for update skip locked
  loop perform private.create_match_plan(r.id); end loop;

  for r in
    select id,duration_seconds from public.matches
    where season=v_season and status='live'
      and started_at+make_interval(secs=>duration_seconds)<=now()
    order by started_at for update skip locked
  loop
    select count(*) filter(where event_type='goal' and side='home'),
           count(*) filter(where event_type='goal' and side='away')
      into v_event_home,v_event_away
      from public.match_events where match_id=r.id;
    select * into p from private.match_plans where match_id=r.id;
    if found and (p.final_home_goals<>v_event_home or p.final_away_goals<>v_event_away) then
      insert into private.match_integrity_audit(match_id,plan_home,plan_away,event_home,event_away,note)
      values(r.id,p.final_home_goals,p.final_away_goals,v_event_home,v_event_away,
             'Final score derived from visible live-event stream; plan differed.');
    end if;
    update public.matches set status='finished',home_goals=v_event_home,away_goals=v_event_away,
      finished_at=started_at+make_interval(secs=>r.duration_seconds) where id=r.id;
  end loop;

  perform private.settle_ready_coupons();

  if exists(select 1 from public.matches where season=v_season and week=v_week and sport='football' and status='live')
    then v_phase:='live';
  elsif exists(select 1 from public.matches where season=v_season and week=v_week and sport='football' and status='scheduled')
    then v_phase:='betting';
  else v_phase:='finished'; end if;
  update public.world_state set phase=v_phase,updated_at=now() where id=1;
end;
$$;

-- Seed today's and tomorrow's cards immediately; tick_world keeps this rolling.
select private.ensure_boxing_schedule((now() at time zone 'Europe/Istanbul')::date);
select private.ensure_boxing_schedule((now() at time zone 'Europe/Istanbul')::date+1);
