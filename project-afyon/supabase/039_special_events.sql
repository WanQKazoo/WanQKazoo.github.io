-- Project Afyon 039 — AFMB Özel Etkinlikler
-- A.R.O.G. vs AROGAN + Sudan Koyun Atlatma
-- Shared matches/coupon/match-center pipeline with special event outcomes.

alter table public.matches
  add column if not exists special_key text,
  add column if not exists special_title text,
  add column if not exists special_home_label text,
  add column if not exists special_away_label text,
  add column if not exists special_subtitle text,
  add column if not exists special_icon text,
  add column if not exists special_outcomes jsonb;

alter table public.matches drop constraint if exists matches_sport_check;
alter table public.matches
  add constraint matches_sport_check
  check (sport = any (array['football'::text,'efootball'::text,'special'::text]));

alter table public.match_events drop constraint if exists match_events_side_check;
alter table public.match_events
  add constraint match_events_side_check
  check (side = any (array['home'::text,'away'::text,'neutral'::text]));

insert into public.clubs(id,country,league_level,name,base_strength,seed,attack,midfield,defense,style,overall,tier)
values
  ('SPC-HOME','AFMB',1,'Özel Etkinlik A',70,9901,70,70,70,'Özel Etkinlik',70,'mid'),
  ('SPC-AWAY','AFMB',1,'Özel Etkinlik B',70,9902,70,70,70,'Özel Etkinlik',70,'mid')
on conflict (id) do nothing;

create or replace function private.special_selection_wins(
  p_match_id text,
  p_market text,
  p_selection text
)
returns boolean
language plpgsql
stable
set search_path to 'public','private'
as $$
declare
  m public.matches%rowtype;
  v_bool boolean;
begin
  select * into m from public.matches where id=p_match_id;
  if not found or m.status<>'finished' or m.sport<>'special' then return false; end if;

  if p_market='1X2' then
    return private.selection_wins(p_market,p_selection,m.home_goals,m.away_goals);
  end if;

  if p_market='SP_SHEEP_WINNER' then
    return coalesce(m.special_outcomes->>'SP_SHEEP_WINNER','')=p_selection;
  end if;

  begin
    v_bool:=coalesce((m.special_outcomes->>p_market)::boolean,false);
  exception when others then
    v_bool:=false;
  end;

  return (p_selection='YES' and v_bool) or (p_selection='NO' and not v_bool);
end;
$$;

create or replace function private.create_special_match_plan(p_match_id text)
returns void
language plpgsql
security definer
set search_path to 'public','private'
as $$
declare
  m public.matches%rowtype;
  i integer;
  minute integer;
  reveal_seconds integer;
  v_side text;
  v_total_goals integer;
  v_home integer:=0;
  v_away integer:=0;
  v_ridvan boolean:=false;
  v_ptero boolean:=false;
  v_backward boolean:=false;
  v_rule boolean:=false;
  v_object boolean:=false;
  v_hesitation boolean:=false;
  v_return boolean:=false;
  v_shepherd_first boolean:=false;
  v_chain boolean:=false;
  v_opposite boolean:=false;
  v_jump boolean:=false;
  v_jury boolean:=false;
  v_graze boolean:=false;
  v_arch boolean:=false;
  v_winner text;
  v_goal record;
begin
  select * into m
  from public.matches
  where id=p_match_id
  for update;

  if not found or m.sport<>'special' or m.status<>'scheduled' or m.kickoff_at>now() then return; end if;

  delete from public.match_events where match_id=m.id;

  if m.special_key='AROG_FINAL' then
    v_total_goals:=4+floor(random()*5)::integer;

    for i in 1..v_total_goals loop
      minute:=4+floor(random()*84)::integer;
      v_side:=case when random()<0.5 then 'home' else 'away' end;
      if v_side='home' then v_home:=v_home+1; else v_away:=v_away+1; end if;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'goal',v_side,jsonb_build_object('importance','goal'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end loop;

    v_ridvan:=random()<0.5;
    v_ptero:=random()<0.5;
    v_backward:=random()<0.5;
    v_rule:=random()<0.5;
    v_object:=random()<0.5;

    if v_ridvan then
      minute:=24+floor(random()*50)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'special_ridvan','neutral',jsonb_build_object('text','Rıdvan Dilmen teknik alana doğru ilerliyor. AFMB hangi sıfatla geldiğini tespit edemedi.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_ptero then
      minute:=18+floor(random()*62)::integer;
      v_side:=case when random()<0.5 then 'home' else 'away' end;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'special_pteranodon',v_side,jsonb_build_object('text','Bir oyuncu Pteranodon tarafından müsabaka alanından geçici olarak uzaklaştırıldı.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_backward then
      select minute,side into v_goal
      from public.match_events
      where match_id=m.id and event_type='goal'
      order by random()
      limit 1;
      if found then
        reveal_seconds:=greatest(1,round((v_goal.minute::numeric/90.0)*m.duration_seconds)::integer);
        insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
        values(m.id,v_goal.minute,'special_backward_goal',v_goal.side,jsonb_build_object('text','GERİ KALMIŞ MEDENİYETLER ADINA!'),m.kickoff_at+make_interval(secs=>reveal_seconds));
      end if;
    end if;

    if v_rule then
      minute:=12+floor(random()*65)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'special_new_rule','neutral',jsonb_build_object('text','Arif yeni bir futbol kuralı açıkladı. Yazılı metne ulaşılamadı.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_object then
      minute:=9+floor(random()*72)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'special_foreign_object','neutral',jsonb_build_object('text','Futbol topu dışında bir cisim oyuna dahil oldu. Hakem devam kararı verdi.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    update public.matches
    set special_outcomes=jsonb_build_object(
      'SP_RIDVAN',v_ridvan,
      'SP_PTERANODON',v_ptero,
      'SP_BACKWARD_GOAL',v_backward,
      'SP_NEW_RULE',v_rule,
      'SP_FOREIGN_OBJECT',v_object
    )
    where id=m.id;

  elsif m.special_key='SHEEP_JUMP' then
    v_winner:=(array['KINALI','KARABAS','PAMUK','REIS','FISTIK','MOR'])[1+floor(random()*6)::integer];
    v_hesitation:=random()<0.5;
    v_return:=random()<0.5;
    v_shepherd_first:=random()<0.5;
    v_chain:=random()<0.5;
    v_opposite:=random()<0.5;
    v_jump:=random()<0.5;
    v_jury:=random()<0.5;
    v_graze:=random()<0.5;
    v_arch:=random()<0.5;

    if v_hesitation then
      minute:=10+floor(random()*55)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_hesitation','neutral',jsonb_build_object('text','Bir koyun kıyıda en az 5 saniye bekleyerek hayat tercihlerini değerlendirdi.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_return then
      minute:=20+floor(random()*50)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_water_return','neutral',jsonb_build_object('text','Bir koyun suya girdikten sonra fikrini değiştirip kıyıya geri döndü.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_shepherd_first then
      minute:=8+floor(random()*45)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_shepherd_first','neutral',jsonb_build_object('text','Çoban karşı kıyıya ulaştı. Koyun hâlâ prosedürü inceliyor.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_chain then
      minute:=18+floor(random()*48)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_chain_jump','neutral',jsonb_build_object('text','Bir koyunun ardından en az üç koyun peş peşe suya atladı.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_opposite then
      minute:=15+floor(random()*52)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_opposite_way','neutral',jsonb_build_object('text','Bir koyun sürünün ters yönüne gidiyor. AFMB bunun taktik olup olmadığını araştırıyor.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_jump then
      minute:=12+floor(random()*58)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_dramatic_jump','neutral',jsonb_build_object('text','Belirgin derecede gösterişli bir sıçrayış kayıtlara geçti.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_jury then
      minute:=58+floor(random()*22)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_jury_split','neutral',jsonb_build_object('text','Hakem heyeti puanlama konusunda anlaşamadı. Tutanak iki nüsha düzenlendi.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_graze then
      minute:=7+floor(random()*57)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_grazing','neutral',jsonb_build_object('text','Bir koyun yarışmayı bırakıp otlamaya yöneldi.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_arch then
      minute:=25+floor(random()*43)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_archaeology','neutral',jsonb_build_object('text','Denizli arkeoloji heyeti olaya gereğinden fazla ilgi gösteriyor.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    minute:=84;
    reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
    insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
    values(m.id,minute,'sheep_winner','neutral',jsonb_build_object('winner',v_winner,'text','Sudan Koyun Atlatma sonucu kesinleşti.'),m.kickoff_at+make_interval(secs=>reveal_seconds));

    update public.matches
    set special_outcomes=jsonb_build_object(
      'SP_SHEEP_WINNER',v_winner,
      'SP_SHEEP_HESITATION',v_hesitation,
      'SP_SHEEP_RETURN',v_return,
      'SP_SHEPHERD_FIRST',v_shepherd_first,
      'SP_SHEEP_CHAIN',v_chain,
      'SP_SHEEP_OPPOSITE',v_opposite,
      'SP_SHEEP_DRAMATIC',v_jump,
      'SP_SHEEP_JURY',v_jury,
      'SP_SHEEP_GRAZE',v_graze,
      'SP_SHEEP_ARCH',v_arch
    )
    where id=m.id;
  else
    return;
  end if;

  insert into private.match_plans(match_id,final_home_goals,final_away_goals)
  values(m.id,v_home,v_away)
  on conflict(match_id) do update
  set final_home_goals=excluded.final_home_goals,
      final_away_goals=excluded.final_away_goals;

  update public.match_markets set locked=true where match_id=m.id;
  update public.matches set status='live',started_at=m.kickoff_at where id=m.id;
end;
$$;

create or replace function private.ensure_special_schedule(p_date date)
returns void
language plpgsql
security definer
set search_path to 'public','private'
as $$
declare
  v_season integer;
  v_week integer;
  v_key text;
  v_id text;
  v_seq integer;
  v_candidate timestamptz;
  v_time time;
  v_found boolean;
  v_index integer;
begin
  select sc.season,sc.week into v_season,v_week
  from public.season_calendar sc
  where sc.play_date=p_date
  order by sc.season desc
  limit 1;

  if v_season is null then
    select season,week into v_season,v_week from public.world_state where id=1;
  end if;

  if v_season is null or v_week is null then return; end if;

  for v_seq in 1..2 loop
    v_key:=case when v_seq=1 then 'AROG_FINAL' else 'SHEEP_JUMP' end;
    v_id:='special-'||to_char(p_date,'YYYYMMDD')||'-'||case when v_seq=1 then 'arog' else 'sheep' end;

    if exists(select 1 from public.matches where id=v_id) then
      continue;
    end if;

    v_found:=false;
    foreach v_time in array array['22:15'::time,'22:45'::time,'23:15'::time,'23:45'::time]
    loop
      v_candidate:=(p_date+v_time) at time zone 'Europe/Istanbul';

      if not exists(
        select 1 from public.matches x
        where x.season=v_season
          and x.week=v_week
          and x.sport in ('football','efootball')
          and x.league_level=1
          and x.kickoff_at is not null
          and abs(extract(epoch from (x.kickoff_at-v_candidate)))<20*60
      )
      and not exists(
        select 1 from public.boxing_bouts b
        where (b.is_main_event or b.is_title_fight)
          and abs(extract(epoch from (b.scheduled_at-v_candidate)))<40*60
      )
      and not exists(
        select 1 from public.matches sx
        where sx.sport='special'
          and sx.kickoff_at is not null
          and abs(extract(epoch from (sx.kickoff_at-v_candidate)))<20*60
      ) then
        v_found:=true;
        exit;
      end if;
    end loop;

    if not v_found then
      v_candidate:=(p_date+(case when v_seq=1 then '23:30'::time else '23:55'::time end)) at time zone 'Europe/Istanbul';
    end if;

    v_index:=extract(doy from p_date)::integer*10+v_seq;

    insert into public.matches(
      id,season,week,country,league_level,match_index,home_club_id,away_club_id,status,
      kickoff_at,sport,duration_seconds,special_key,special_title,special_home_label,
      special_away_label,special_subtitle,special_icon
    )
    values(
      v_id,v_season,v_week,'AFMB Özel',1,v_index,'SPC-HOME','SPC-AWAY','scheduled',
      v_candidate,'special',case when v_key='AROG_FINAL' then 180 else 120 end,v_key,
      case when v_key='AROG_FINAL' then 'A.R.O.G. vs AROGAN' else 'Sudan Koyun Atlatma • Çal Özel' end,
      case when v_key='AROG_FINAL' then 'A.R.O.G.' else 'Çal Çobanları' end,
      case when v_key='AROG_FINAL' then 'AROGAN' else 'Büyük Menderes' end,
      case when v_key='AROG_FINAL'
        then 'Tarih Öncesi Arena • FIFA henüz kurulmamıştır.'
        else 'Büyük Menderes • Geleneksel Çoban Bayramı'
      end,
      case when v_key='AROG_FINAL' then '🏺' else '🐑' end
    );

    if v_key='AROG_FINAL' then
      insert into public.match_markets(match_id,market_key,selection_key,odd,locked) values
        (v_id,'1X2','1',2.35,false),
        (v_id,'1X2','X',4.10,false),
        (v_id,'1X2','2',2.35,false),
        (v_id,'SP_RIDVAN','YES',1.80,false),(v_id,'SP_RIDVAN','NO',1.80,false),
        (v_id,'SP_PTERANODON','YES',1.80,false),(v_id,'SP_PTERANODON','NO',1.80,false),
        (v_id,'SP_BACKWARD_GOAL','YES',1.80,false),(v_id,'SP_BACKWARD_GOAL','NO',1.80,false),
        (v_id,'SP_NEW_RULE','YES',1.80,false),(v_id,'SP_NEW_RULE','NO',1.80,false),
        (v_id,'SP_FOREIGN_OBJECT','YES',1.80,false),(v_id,'SP_FOREIGN_OBJECT','NO',1.80,false);
    else
      insert into public.match_markets(match_id,market_key,selection_key,odd,locked) values
        (v_id,'SP_SHEEP_WINNER','KINALI',5.20,false),
        (v_id,'SP_SHEEP_WINNER','KARABAS',5.20,false),
        (v_id,'SP_SHEEP_WINNER','PAMUK',5.20,false),
        (v_id,'SP_SHEEP_WINNER','REIS',5.20,false),
        (v_id,'SP_SHEEP_WINNER','FISTIK',5.20,false),
        (v_id,'SP_SHEEP_WINNER','MOR',5.20,false),
        (v_id,'SP_SHEEP_HESITATION','YES',1.80,false),(v_id,'SP_SHEEP_HESITATION','NO',1.80,false),
        (v_id,'SP_SHEEP_RETURN','YES',1.80,false),(v_id,'SP_SHEEP_RETURN','NO',1.80,false),
        (v_id,'SP_SHEPHERD_FIRST','YES',1.80,false),(v_id,'SP_SHEPHERD_FIRST','NO',1.80,false),
        (v_id,'SP_SHEEP_CHAIN','YES',1.80,false),(v_id,'SP_SHEEP_CHAIN','NO',1.80,false),
        (v_id,'SP_SHEEP_OPPOSITE','YES',1.80,false),(v_id,'SP_SHEEP_OPPOSITE','NO',1.80,false),
        (v_id,'SP_SHEEP_DRAMATIC','YES',1.80,false),(v_id,'SP_SHEEP_DRAMATIC','NO',1.80,false),
        (v_id,'SP_SHEEP_JURY','YES',1.80,false),(v_id,'SP_SHEEP_JURY','NO',1.80,false),
        (v_id,'SP_SHEEP_GRAZE','YES',1.80,false),(v_id,'SP_SHEEP_GRAZE','NO',1.80,false),
        (v_id,'SP_SHEEP_ARCH','YES',1.80,false),(v_id,'SP_SHEEP_ARCH','NO',1.80,false);
    end if;
  end loop;
end;
$$;

create or replace function private.refresh_week_markets(p_season integer, p_week integer)
returns void
language plpgsql
security definer
set search_path to 'public','private'
as $$
declare r record;
begin
  for r in
    select id from public.matches
    where season=p_season and week=p_week and status='scheduled' and sport in ('football','efootball')
  loop
    perform private.refresh_match_markets(r.id);
  end loop;
end;
$$;

create or replace function private.settle_ready_coupons()
returns void
language plpgsql
security definer
set search_path to 'public','private'
as $$
declare
  c record;
  leg_count integer;
  done_count integer;
  loss_count integer;
begin
  for c in
    select * from public.coupons where status='pending' order by created_at
    for update
  loop
    select
      count(*),
      count(*) filter(where x.done),
      count(*) filter(where x.done and not x.won)
    into leg_count,done_count,loss_count
    from (
      select
        case
          when cs.match_id is not null then coalesce(m.status='finished',false)
          when cs.bout_id is not null then coalesce(b.status='finished',false)
          else false
        end as done,
        case
          when cs.match_id is not null and m.status='finished' and m.sport='special' then
            private.special_selection_wins(cs.match_id,cs.market_key,cs.selection_key)
          when cs.match_id is not null and m.status='finished' then
            private.selection_wins(cs.market_key,cs.selection_key,m.home_goals,m.away_goals)
          when cs.bout_id is not null and b.status='finished' then
            private.boxing_selection_wins(
              cs.market_key,cs.selection_key,b.winner_id,b.red_fighter_id,b.blue_fighter_id,b.method
            )
          else false
        end as won
      from public.coupon_selections cs
      left join public.matches m on m.id=cs.match_id
      left join public.boxing_bouts b on b.id=cs.bout_id
      where cs.coupon_id=c.id
    ) x;

    if leg_count=0 then
      continue;
    elsif loss_count>0 then
      update public.coupons
      set status='lost',settled_at=now()
      where id=c.id;
    elsif done_count=leg_count then
      update public.coupons
      set status='won',payout=possible_return,settled_at=now()
      where id=c.id;

      update public.wallets
      set balance=balance+c.possible_return,updated_at=now()
      where user_id=c.user_id;
    end if;
  end loop;
end;
$$;

create or replace function public.tick_world()
returns void
language plpgsql
security definer
set search_path to 'public','private'
as $$
declare
  v_season integer; v_week integer; r record; p private.match_plans%rowtype;
  v_phase text; v_event_home integer; v_event_away integer;
  br record;
begin
  perform private.ensure_boxing_schedule((now() at time zone 'Europe/Istanbul')::date);
  perform private.ensure_boxing_schedule((now() at time zone 'Europe/Istanbul')::date+1);
  perform private.ensure_special_schedule((now() at time zone 'Europe/Istanbul')::date);
  perform private.ensure_special_schedule((now() at time zone 'Europe/Istanbul')::date+1);

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
    select id,sport from public.matches
    where season=v_season and status='scheduled' and kickoff_at<=now()
    order by kickoff_at for update skip locked
  loop
    if r.sport='special' then
      perform private.create_special_match_plan(r.id);
    else
      perform private.create_match_plan(r.id);
    end if;
  end loop;

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

select private.ensure_special_schedule((now() at time zone 'Europe/Istanbul')::date);
select private.ensure_special_schedule((now() at time zone 'Europe/Istanbul')::date+1);
