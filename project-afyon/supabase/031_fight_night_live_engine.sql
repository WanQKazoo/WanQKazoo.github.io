-- Project Afyon 0.51 — Fight Night live engine
-- Long-form boxing: 45s rounds + 12s corners, server-authored events,
-- hidden judge scorecards, KO/TKO stoppages and persistent career updates.

create table if not exists public.boxing_cards (
  id text primary key,
  name text not null,
  starts_at timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled','live','finished')),
  created_at timestamptz not null default now()
);

alter table public.boxing_cards enable row level security;
drop policy if exists boxing_cards_public_read on public.boxing_cards;
create policy boxing_cards_public_read on public.boxing_cards
for select to anon,authenticated using (true);

alter table public.boxing_bouts
  add column if not exists card_id text references public.boxing_cards(id),
  add column if not exists bout_order smallint,
  add column if not exists bout_type text,
  add column if not exists rounds_scheduled smallint not null default 6,
  add column if not exists duration_seconds integer not null default 330,
  add column if not exists started_at timestamptz,
  add column if not exists finished_at timestamptz,
  add column if not exists scorecards jsonb;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid='public.boxing_bouts'::regclass
      and conname='boxing_bouts_bout_type_check'
  ) then
    alter table public.boxing_bouts
      add constraint boxing_bouts_bout_type_check
      check (bout_type is null or bout_type in ('UNDERCARD','CO_MAIN','MAIN'));
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid='public.boxing_bouts'::regclass
      and conname='boxing_bouts_rounds_check'
  ) then
    alter table public.boxing_bouts
      add constraint boxing_bouts_rounds_check
      check (rounds_scheduled between 4 and 12);
  end if;
end $$;

create table if not exists public.boxing_bout_events (
  id bigint generated always as identity primary key,
  bout_id text not null references public.boxing_bouts(id) on delete cascade,
  round_number smallint not null,
  second_in_round smallint not null,
  event_type text not null check (event_type in (
    'jab','power_shot','combo','body_shot','counter','clinch',
    'knockdown','cut','round_end','stoppage'
  )),
  side text check (side in ('red','blue')),
  payload jsonb not null default '{}'::jsonb,
  visible_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index if not exists boxing_bout_events_visible_idx
on public.boxing_bout_events(bout_id,visible_at);

alter table public.boxing_bout_events enable row level security;
drop policy if exists boxing_bout_events_public_read on public.boxing_bout_events;
create policy boxing_bout_events_public_read on public.boxing_bout_events
for select to anon,authenticated
using (visible_at<=now());

create table if not exists private.boxing_bout_plans (
  bout_id text primary key references public.boxing_bouts(id) on delete cascade,
  winner_id text,
  method text not null,
  finish_round smallint not null,
  finish_offset_seconds integer not null,
  scorecards jsonb,
  settled boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function private.boxing_round_duration()
returns integer
language sql
immutable
set search_path=''
as $$ select 45 $$;

create or replace function private.boxing_break_duration()
returns integer
language sql
immutable
set search_path=''
as $$ select 12 $$;

create or replace function private.schedule_boxing_card(
  p_card_id text,
  p_name text,
  p_start timestamptz,
  p_seed integer
)
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  weights text[]:=array['LIGHTWEIGHT','WELTERWEIGHT','MIDDLEWEIGHT','LIGHT_HEAVYWEIGHT','HEAVYWEIGHT'];
  ord integer;
  wi integer;
  w text;
  red_pos integer;
  blue_pos integer;
  red_id text;
  blue_id text;
  bout_start timestamptz;
  rounds integer;
  kind text;
begin
  insert into public.boxing_cards(id,name,starts_at,status)
  values(p_card_id,p_name,p_start,'scheduled')
  on conflict(id) do nothing;

  for ord in 1..3 loop
    wi:=1+mod(abs(p_seed)+ord*2,5);
    w:=weights[wi];
    red_pos:=mod(abs(p_seed)+ord,5);
    blue_pos:=mod(red_pos+1+ord,5);

    select id into red_id
    from public.boxing_fighters
    where weight_class=w and is_active
    order by seed,id
    offset red_pos limit 1;

    select id into blue_id
    from public.boxing_fighters
    where weight_class=w and is_active
    order by seed,id
    offset blue_pos limit 1;

    if red_id=blue_id then
      select id into blue_id
      from public.boxing_fighters
      where weight_class=w and is_active and id<>red_id
      order by seed,id limit 1;
    end if;

    if ord=1 then
      bout_start:=p_start;
      rounds:=6;
      kind:='UNDERCARD';
    elsif ord=2 then
      bout_start:=p_start+interval '7 minutes';
      rounds:=8;
      kind:='CO_MAIN';
    else
      bout_start:=p_start+interval '16 minutes';
      rounds:=10;
      kind:='MAIN';
    end if;

    insert into public.boxing_bouts(
      id,event_name,scheduled_at,weight_class,red_fighter_id,blue_fighter_id,status,
      card_id,bout_order,bout_type,rounds_scheduled,duration_seconds
    ) values(
      p_card_id||'|B'||ord,p_name,bout_start,w,red_id,blue_id,'scheduled',
      p_card_id,ord,kind,rounds,
      rounds*private.boxing_round_duration()+(rounds-1)*private.boxing_break_duration()
    )
    on conflict(id) do nothing;
  end loop;
end;
$$;

create or replace function private.ensure_boxing_schedule()
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  local_day date;
  day_offset integer;
  hh integer;
  card_start timestamptz;
  card_id text;
  seed_value integer;
begin
  -- Normal rhythm: three Fight Nights per day in Türkiye time.
  for day_offset in 0..2 loop
    local_day:=(now() at time zone 'Europe/Istanbul')::date+day_offset;
    foreach hh in array array[14,19,23] loop
      card_start:=(local_day::timestamp+make_interval(hours=>hh)) at time zone 'Europe/Istanbul';
      if card_start<now()-interval '30 minutes' then
        continue;
      end if;
      card_id:='BX|CARD|'||to_char(local_day,'YYYYMMDD')||'|'||lpad(hh::text,2,'0');
      seed_value:=extract(doy from local_day)::integer*10+hh;
      perform private.schedule_boxing_card(
        card_id,
        'AFMB Fight Night • '||to_char(local_day,'DD.MM')||' • '||lpad(hh::text,2,'0')||':00',
        card_start,
        seed_value
      );
    end loop;
  end loop;
end;
$$;

create or replace function private.start_boxing_bout(p_bout_id text)
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  b public.boxing_bouts%rowtype;
  red public.boxing_fighters%rowtype;
  blue public.boxing_fighters%rowtype;
  r integer;
  i integer;
  actions integer;
  sec integer;
  round_offset integer;
  red_metric numeric;
  blue_metric numeric;
  red_damage numeric:=0;
  blue_damage numeric:=0;
  red_kd integer;
  blue_kd integer;
  attacker_side text;
  event_kind text;
  impact numeric;
  choice numeric;
  red_prob numeric;
  kd_chance numeric;
  stop_chance numeric;
  stopped boolean:=false;
  v_winner text:=null;
  v_method text:='DRAW';
  v_finish_round integer:=1;
  v_finish_offset integer:=0;
  leader text;
  close_round boolean;
  j1r integer:=0;j1b integer:=0;
  j2r integer:=0;j2b integer:=0;
  j3r integer:=0;j3b integer:=0;
  red_votes integer;
  blue_votes integer;
  flip boolean;
  red_power numeric; red_speed numeric; red_def numeric; red_chin numeric; red_sta numeric;
  blue_power numeric; blue_speed numeric; blue_def numeric; blue_chin numeric; blue_sta numeric;
begin
  select * into b from public.boxing_bouts where id=p_bout_id for update;
  if not found or b.status<>'scheduled' or b.scheduled_at>now() then return; end if;

  if exists(select 1 from private.boxing_bout_plans where bout_id=b.id) then
    update public.boxing_bouts set status='live',started_at=scheduled_at where id=b.id;
    return;
  end if;

  select * into red from public.boxing_fighters where id=b.red_fighter_id;
  select * into blue from public.boxing_fighters where id=b.blue_fighter_id;

  red_power:=red.power;red_speed:=red.speed;red_def:=red.defense;red_chin:=red.chin;red_sta:=red.stamina;
  blue_power:=blue.power;blue_speed:=blue.speed;blue_def:=blue.defense;blue_chin:=blue.chin;blue_sta:=blue.stamina;

  delete from public.boxing_bout_events where bout_id=b.id;

  for r in 1..b.rounds_scheduled loop
    exit when stopped;
    red_metric:=0;blue_metric:=0;red_kd:=0;blue_kd:=0;
    actions:=5+floor(random()*4)::integer;
    round_offset:=(r-1)*(private.boxing_round_duration()+private.boxing_break_duration());

    for i in 1..actions loop
      exit when stopped;
      sec:=4+floor(random()*36)::integer;
      red_prob:=greatest(.34,least(.66,
        .50
        +((red.rating-blue.rating)/100.0)
        +((red_speed-blue_speed)/240.0)
        -((r-1)*greatest(0,blue_sta-red_sta)/5000.0)
      ));

      if random()<red_prob then attacker_side:='red'; else attacker_side:='blue'; end if;
      choice:=random();
      if choice<.28 then event_kind:='jab';
      elsif choice<.48 then event_kind:='power_shot';
      elsif choice<.66 then event_kind:='combo';
      elsif choice<.80 then event_kind:='body_shot';
      elsif choice<.94 then event_kind:='counter';
      else event_kind:='clinch';
      end if;

      if attacker_side='red' then
        impact:=case event_kind
          when 'jab' then .75
          when 'power_shot' then 1.55
          when 'combo' then 1.35
          when 'body_shot' then 1.05
          when 'counter' then 1.45
          else .20 end;
        impact:=greatest(.15,impact+(red_power-blue_def)*.018+(red_speed-blue_speed)*.008+(random()-.5)*.70);
        red_metric:=red_metric+impact;
        blue_damage:=blue_damage+greatest(0,impact-.35)*.78;
      else
        impact:=case event_kind
          when 'jab' then .75
          when 'power_shot' then 1.55
          when 'combo' then 1.35
          when 'body_shot' then 1.05
          when 'counter' then 1.45
          else .20 end;
        impact:=greatest(.15,impact+(blue_power-red_def)*.018+(blue_speed-red_speed)*.008+(random()-.5)*.70);
        blue_metric:=blue_metric+impact;
        red_damage:=red_damage+greatest(0,impact-.35)*.78;
      end if;

      insert into public.boxing_bout_events(
        bout_id,round_number,second_in_round,event_type,side,payload,visible_at
      ) values(
        b.id,r,sec,event_kind,attacker_side,
        jsonb_build_object(
          'impact',round(impact,2),
          'commentary_key',case event_kind
            when 'jab' then 'JAB'
            when 'power_shot' then 'POWER'
            when 'combo' then 'COMBO'
            when 'body_shot' then 'BODY'
            when 'counter' then 'COUNTER'
            else 'CLINCH' end
        ),
        b.scheduled_at+make_interval(secs=>round_offset+sec)
      );

      if event_kind<>'clinch' and impact>1.20 and random()<.035 then
        insert into public.boxing_bout_events(
          bout_id,round_number,second_in_round,event_type,side,payload,visible_at
        ) values(
          b.id,r,least(44,sec+1),'cut',attacker_side,
          jsonb_build_object('commentary_key','CUT'),
          b.scheduled_at+make_interval(secs=>round_offset+least(44,sec+1))
        );
        if attacker_side='red' then blue_damage:=blue_damage+2.2; else red_damage:=red_damage+2.2; end if;
      end if;

      if event_kind in ('power_shot','combo','counter') and impact>1.45 then
        if attacker_side='red' then
          kd_chance:=greatest(.015,least(.22,.025+(red_power-blue_chin)*.0045+blue_damage*.004));
        else
          kd_chance:=greatest(.015,least(.22,.025+(blue_power-red_chin)*.0045+red_damage*.004));
        end if;

        if random()<kd_chance then
          if attacker_side='red' then
            red_kd:=red_kd+1;red_metric:=red_metric+2.4;blue_damage:=blue_damage+6;
          else
            blue_kd:=blue_kd+1;blue_metric:=blue_metric+2.4;red_damage:=red_damage+6;
          end if;

          insert into public.boxing_bout_events(
            bout_id,round_number,second_in_round,event_type,side,payload,visible_at
          ) values(
            b.id,r,least(44,sec+2),'knockdown',attacker_side,
            jsonb_build_object('commentary_key','KNOCKDOWN'),
            b.scheduled_at+make_interval(secs=>round_offset+least(44,sec+2))
          );

          if attacker_side='red' then
            stop_chance:=greatest(.08,least(.62,.10+(red_power-blue_chin)*.012+blue_damage*.012));
          else
            stop_chance:=greatest(.08,least(.62,.10+(blue_power-red_chin)*.012+red_damage*.012));
          end if;

          if random()<stop_chance then
            stopped:=true;
            v_winner:=case when attacker_side='red' then red.id else blue.id end;
            v_method:=case when random()<.55 then 'KO' else 'TKO' end;
            v_finish_round:=r;
            v_finish_offset:=round_offset+least(45,sec+6);
            insert into public.boxing_bout_events(
              bout_id,round_number,second_in_round,event_type,side,payload,visible_at
            ) values(
              b.id,r,least(45,sec+6),'stoppage',attacker_side,
              jsonb_build_object('commentary_key','STOPPAGE','method',v_method),
              b.scheduled_at+make_interval(secs=>v_finish_offset)
            );
          end if;
        end if;
      end if;
    end loop;

    if not stopped then
      close_round:=abs(red_metric-blue_metric)<.85;
      leader:=case when red_metric>blue_metric then 'red'
                   when blue_metric>red_metric then 'blue'
                   else 'even' end;

      insert into public.boxing_bout_events(
        bout_id,round_number,second_in_round,event_type,side,payload,visible_at
      ) values(
        b.id,r,45,'round_end',null,
        jsonb_build_object('commentary_key','ROUND_END','leader',leader,'close',close_round),
        b.scheduled_at+make_interval(secs=>round_offset+45)
      );

      -- Three hidden judges. Close rounds can split.
      flip:=close_round and random()<.28;
      if (red_metric>=blue_metric and not flip) or (blue_metric>red_metric and flip) then
        j1r:=j1r+10;j1b:=j1b+greatest(7,9-red_kd);
      else
        j1b:=j1b+10;j1r:=j1r+greatest(7,9-blue_kd);
      end if;

      flip:=close_round and random()<.28;
      if (red_metric>=blue_metric and not flip) or (blue_metric>red_metric and flip) then
        j2r:=j2r+10;j2b:=j2b+greatest(7,9-red_kd);
      else
        j2b:=j2b+10;j2r:=j2r+greatest(7,9-blue_kd);
      end if;

      flip:=close_round and random()<.28;
      if (red_metric>=blue_metric and not flip) or (blue_metric>red_metric and flip) then
        j3r:=j3r+10;j3b:=j3b+greatest(7,9-red_kd);
      else
        j3b:=j3b+10;j3r:=j3r+greatest(7,9-blue_kd);
      end if;
    end if;
  end loop;

  if not stopped then
    red_votes:=(case when j1r>j1b then 1 else 0 end)+(case when j2r>j2b then 1 else 0 end)+(case when j3r>j3b then 1 else 0 end);
    blue_votes:=(case when j1b>j1r then 1 else 0 end)+(case when j2b>j2r then 1 else 0 end)+(case when j3b>j3r then 1 else 0 end);

    if red_votes>=2 then
      v_winner:=red.id;
      v_method:=case when red_votes=3 then 'UD' else 'SD' end;
    elsif blue_votes>=2 then
      v_winner:=blue.id;
      v_method:=case when blue_votes=3 then 'UD' else 'SD' end;
    else
      v_winner:=null;
      v_method:='DRAW';
    end if;
    v_finish_round:=b.rounds_scheduled;
    v_finish_offset:=b.rounds_scheduled*private.boxing_round_duration()+(b.rounds_scheduled-1)*private.boxing_break_duration();
  end if;

  insert into private.boxing_bout_plans(
    bout_id,winner_id,method,finish_round,finish_offset_seconds,scorecards
  ) values(
    b.id,v_winner,v_method,v_finish_round,v_finish_offset,
    case when v_method in ('KO','TKO') then null else jsonb_build_array(
      jsonb_build_object('red',j1r,'blue',j1b),
      jsonb_build_object('red',j2r,'blue',j2b),
      jsonb_build_object('red',j3r,'blue',j3b)
    ) end
  );

  update public.boxing_bouts
  set status='live',started_at=scheduled_at
  where id=b.id;
end;
$$;

create or replace function private.finish_boxing_bout(p_bout_id text)
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  b public.boxing_bouts%rowtype;
  p private.boxing_bout_plans%rowtype;
  loser_id text;
  rating_gain numeric;
begin
  select * into b from public.boxing_bouts where id=p_bout_id for update;
  if not found or b.status<>'live' then return; end if;

  select * into p from private.boxing_bout_plans where bout_id=b.id for update;
  if not found or p.settled then return; end if;
  if now()<b.started_at+make_interval(secs=>p.finish_offset_seconds) then return; end if;

  update public.boxing_bouts
  set status='finished',
      winner_id=p.winner_id,
      method=p.method,
      finish_round=p.finish_round,
      scorecards=p.scorecards,
      finished_at=b.started_at+make_interval(secs=>p.finish_offset_seconds)
  where id=b.id;

  if p.winner_id is null then
    update public.boxing_fighters
    set draws=draws+1,streak_type='D',streak_count=1,updated_at=now()
    where id in (b.red_fighter_id,b.blue_fighter_id);
  else
    loser_id:=case when p.winner_id=b.red_fighter_id then b.blue_fighter_id else b.red_fighter_id end;
    rating_gain:=case when p.method in ('KO','TKO') then 1.6 else 1.2 end;

    update public.boxing_fighters
    set wins=wins+1,
        kos=kos+case when p.method in ('KO','TKO') then 1 else 0 end,
        streak_count=case when streak_type='W' then streak_count+1 else 1 end,
        streak_type='W',
        rating=least(99,rating+rating_gain),
        updated_at=now()
    where id=p.winner_id;

    update public.boxing_fighters
    set losses=losses+1,
        streak_count=case when streak_type='L' then streak_count+1 else 1 end,
        streak_type='L',
        rating=greatest(20,rating-rating_gain*.75),
        updated_at=now()
    where id=loser_id;
  end if;

  update private.boxing_bout_plans set settled=true where bout_id=b.id;
end;
$$;

create or replace function public.tick_boxing_world()
returns void
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  r record;
begin
  perform private.ensure_boxing_schedule();

  for r in
    select id from public.boxing_bouts
    where status='scheduled' and scheduled_at<=now()
    order by scheduled_at
    limit 12
  loop
    perform private.start_boxing_bout(r.id);
  end loop;

  for r in
    select id from public.boxing_bouts
    where status='live'
    order by started_at
    limit 12
  loop
    perform private.finish_boxing_bout(r.id);
  end loop;

  update public.boxing_cards c
  set status=case
    when exists(select 1 from public.boxing_bouts b where b.card_id=c.id and b.status='live') then 'live'
    when not exists(select 1 from public.boxing_bouts b where b.card_id=c.id and b.status<>'finished') then 'finished'
    else 'scheduled'
  end
  where c.starts_at>=now()-interval '1 day';
end;
$$;

revoke all on function public.tick_boxing_world() from public;
grant execute on function public.tick_boxing_world() to anon,authenticated;

-- One immediate showcase so the live system can be experienced without waiting
-- for the normal 14:00 / 19:00 / 23:00 Türkiye-time rhythm.
do $$
declare
  cid text;
  cstart timestamptz;
begin
  if not exists(select 1 from public.boxing_cards) then
    cstart:=now()+interval '2 minutes';
    cid:='BX|LAUNCH|'||floor(extract(epoch from now()))::bigint::text;
    insert into public.boxing_cards(id,name,starts_at,status)
    values(cid,'AFMB Fight Night 001 • Türkiye Gecesi',cstart,'scheduled');

    insert into public.boxing_bouts(
      id,event_name,scheduled_at,weight_class,red_fighter_id,blue_fighter_id,status,
      card_id,bout_order,bout_type,rounds_scheduled,duration_seconds
    ) values
      (cid||'|B1','AFMB Fight Night 001 • Türkiye Gecesi',cstart,
       'WELTERWEIGHT','BX|WW|T2','BX|WW|T1','scheduled',cid,1,'UNDERCARD',6,6*45+5*12),
      (cid||'|B2','AFMB Fight Night 001 • Türkiye Gecesi',cstart+interval '7 minutes',
       'HEAVYWEIGHT','BX|HW|T1','BX|HW|T2','scheduled',cid,2,'CO_MAIN',8,8*45+7*12),
      (cid||'|B3','AFMB Fight Night 001 • Türkiye Gecesi',cstart+interval '16 minutes',
       'MIDDLEWEIGHT','BX|MW|T0','BX|MW|T1','scheduled',cid,3,'MAIN',10,10*45+9*12);
  end if;

  perform private.ensure_boxing_schedule();
end;
$$;
