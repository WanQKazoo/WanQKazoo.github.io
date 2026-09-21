-- Project Afyon 047 — Control Room Telemetry
-- Authenticated heartbeat + persistent activity days + owner-only analytics.
-- Online status is defined as a heartbeat within the last 2 minutes.

create table if not exists private.user_presence(
  user_id uuid primary key references public.profiles(id) on delete cascade,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  last_page text not null default 'unknown',
  session_count integer not null default 1 check(session_count>=1),
  last_session_at timestamptz not null default now()
);

create table if not exists private.user_activity_days(
  user_id uuid not null references public.profiles(id) on delete cascade,
  activity_date date not null,
  first_seen_at timestamptz not null,
  last_seen_at timestamptz not null,
  touches integer not null default 1 check(touches>=1),
  primary key(user_id,activity_date)
);

create table if not exists private.user_page_activity_days(
  user_id uuid not null references public.profiles(id) on delete cascade,
  activity_date date not null,
  page text not null,
  pings integer not null default 1 check(pings>=1),
  first_seen_at timestamptz not null,
  last_seen_at timestamptz not null,
  primary key(user_id,activity_date,page)
);

alter table private.user_presence enable row level security;
alter table private.user_activity_days enable row level security;
alter table private.user_page_activity_days enable row level security;

revoke all on private.user_presence,private.user_activity_days,private.user_page_activity_days from public,anon,authenticated;

create index if not exists user_presence_last_seen_idx on private.user_presence(last_seen_at desc);
create index if not exists user_activity_days_date_idx on private.user_activity_days(activity_date desc);
create index if not exists user_page_activity_days_date_page_idx on private.user_page_activity_days(activity_date desc,page);

with history as (
  select p.id as user_id,p.created_at as happened_at from public.profiles p
  union all
  select c.user_id,c.created_at from public.coupons c
  union all
  select cp.user_id,cp.created_at from public.chance_plays cp
  union all
  select pl.user_id,pl.purchased_at from public.profile_luxuries pl
  union all
  select pc.user_id,pc.purchased_at from public.profile_cosmetics pc
)
insert into private.user_presence as up(user_id,first_seen_at,last_seen_at,last_page,session_count,last_session_at)
select user_id,min(happened_at),max(happened_at),'history',1,max(happened_at)
from history
group by user_id
on conflict(user_id) do update set
  first_seen_at=least(up.first_seen_at,excluded.first_seen_at),
  last_seen_at=greatest(up.last_seen_at,excluded.last_seen_at),
  last_session_at=greatest(up.last_session_at,excluded.last_session_at);

with history as (
  select p.id as user_id,p.created_at as happened_at from public.profiles p
  union all
  select c.user_id,c.created_at from public.coupons c
  union all
  select cp.user_id,cp.created_at from public.chance_plays cp
  union all
  select pl.user_id,pl.purchased_at from public.profile_luxuries pl
  union all
  select pc.user_id,pc.purchased_at from public.profile_cosmetics pc
), grouped as (
  select
    user_id,
    timezone('Europe/Istanbul',happened_at)::date as activity_date,
    min(happened_at) as first_seen_at,
    max(happened_at) as last_seen_at,
    count(*)::integer as touches
  from history
  group by user_id,timezone('Europe/Istanbul',happened_at)::date
)
insert into private.user_activity_days as uad(user_id,activity_date,first_seen_at,last_seen_at,touches)
select user_id,activity_date,first_seen_at,last_seen_at,touches from grouped
on conflict(user_id,activity_date) do update set
  first_seen_at=least(uad.first_seen_at,excluded.first_seen_at),
  last_seen_at=greatest(uad.last_seen_at,excluded.last_seen_at),
  touches=greatest(uad.touches,excluded.touches);

create or replace function public.touch_activity(p_page text default null)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
  v_now timestamptz:=now();
  v_day date:=timezone('Europe/Istanbul',now())::date;
  v_page text:=lower(btrim(coalesce(p_page,'unknown')));
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists(select 1 from public.profiles p where p.id=v_user) then raise exception 'PROFILE_NOT_FOUND'; end if;

  if v_page not in ('bulletin','matches','coupons','leagues','news','boxing','games','profile','admin') then
    v_page:='other';
  end if;

  insert into private.user_presence as up(
    user_id,first_seen_at,last_seen_at,last_page,session_count,last_session_at
  )
  values(v_user,v_now,v_now,v_page,1,v_now)
  on conflict(user_id) do update set
    last_seen_at=v_now,
    last_page=v_page,
    session_count=up.session_count + case when up.last_seen_at < v_now-interval '30 minutes' then 1 else 0 end,
    last_session_at=case when up.last_seen_at < v_now-interval '30 minutes' then v_now else up.last_session_at end;

  insert into private.user_activity_days as uad(
    user_id,activity_date,first_seen_at,last_seen_at,touches
  )
  values(v_user,v_day,v_now,v_now,1)
  on conflict(user_id,activity_date) do update set
    last_seen_at=v_now,
    touches=uad.touches+1;

  insert into private.user_page_activity_days as upad(
    user_id,activity_date,page,pings,first_seen_at,last_seen_at
  )
  values(v_user,v_day,v_page,1,v_now,v_now)
  on conflict(user_id,activity_date,page) do update set
    pings=upad.pings+1,
    last_seen_at=v_now;

  return jsonb_build_object('ok',true,'page',v_page,'seen_at',v_now);
end;
$function$;

revoke all on function public.touch_activity(text) from public;
revoke all on function public.touch_activity(text) from anon;
grant execute on function public.touch_activity(text) to authenticated;

create or replace function public.get_admin_dashboard()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
  v_today date:=timezone('Europe/Istanbul',now())::date;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists(select 1 from private.admin_users au where au.user_id=v_user) then
    raise exception 'ADMIN_REQUIRED';
  end if;

  return jsonb_build_object(
    'generated_at',now(),
    'summary',jsonb_build_object(
      'members',(select count(*) from public.profiles),
      'new_today',(select count(*) from public.profiles p where timezone('Europe/Istanbul',p.created_at)::date=v_today),
      'new_7d',(select count(*) from public.profiles p where p.created_at>=now()-interval '7 days'),
      'online_now',(select count(*) from private.user_presence up where up.last_seen_at>=now()-interval '2 minutes'),
      'online_15m',(select count(*) from private.user_presence up where up.last_seen_at>=now()-interval '15 minutes'),
      'dau',(select count(*) from private.user_activity_days d where d.activity_date=v_today),
      'wau',(select count(distinct d.user_id) from private.user_activity_days d where d.activity_date between v_today-6 and v_today),
      'mau',(select count(distinct d.user_id) from private.user_activity_days d where d.activity_date between v_today-29 and v_today),
      'd1_eligible',(select count(*) from public.profiles p where timezone('Europe/Istanbul',p.created_at)::date<=v_today-1),
      'd1_returned',(select count(*) from public.profiles p
        where timezone('Europe/Istanbul',p.created_at)::date<=v_today-1
          and exists(
            select 1 from private.user_activity_days d
            where d.user_id=p.id
              and d.activity_date=timezone('Europe/Istanbul',p.created_at)::date+1
          )),
      'd1_retention',(select case when count(*)=0 then null else round(
          100.0*count(*) filter(where exists(
            select 1 from private.user_activity_days d
            where d.user_id=p.id
              and d.activity_date=timezone('Europe/Istanbul',p.created_at)::date+1
          ))/count(*),1) end
        from public.profiles p
        where timezone('Europe/Istanbul',p.created_at)::date<=v_today-1),
      'd7_eligible',(select count(*) from public.profiles p where timezone('Europe/Istanbul',p.created_at)::date<=v_today-7),
      'd7_returned',(select count(*) from public.profiles p
        where timezone('Europe/Istanbul',p.created_at)::date<=v_today-7
          and exists(
            select 1 from private.user_activity_days d
            where d.user_id=p.id
              and d.activity_date=timezone('Europe/Istanbul',p.created_at)::date+7
          )),
      'd7_retention',(select case when count(*)=0 then null else round(
          100.0*count(*) filter(where exists(
            select 1 from private.user_activity_days d
            where d.user_id=p.id
              and d.activity_date=timezone('Europe/Istanbul',p.created_at)::date+7
          ))/count(*),1) end
        from public.profiles p
        where timezone('Europe/Istanbul',p.created_at)::date<=v_today-7),
      'active_24h',(select count(distinct d.user_id) from private.user_activity_days d where d.last_seen_at>=now()-interval '24 hours'),
      'active_7d',(select count(distinct d.user_id) from private.user_activity_days d where d.activity_date between v_today-6 and v_today),
      'coupons',(select count(*) from public.coupons),
      'pending_coupons',(select count(*) from public.coupons where status='pending'),
      'won_coupons',(select count(*) from public.coupons where status='won'),
      'lost_coupons',(select count(*) from public.coupons where status='lost'),
      'coupon_stake',(select coalesce(sum(stake),0) from public.coupons),
      'coupon_payout',(select coalesce(sum(payout),0) from public.coupons),
      'chance_plays',(select count(*) from public.chance_plays),
      'chance_stake',(select coalesce(sum(stake),0) from public.chance_plays),
      'chance_payout',(select coalesce(sum(payout),0) from public.chance_plays),
      'luxury_spent',(select coalesce(sum(price_paid),0) from public.profile_luxuries),
      'cosmetic_spent',(select coalesce(sum(price_paid),0) from public.profile_cosmetics),
      'rescue_granted',(select coalesce(sum(rescue_visits),0)*1000 from public.profile_stats),
      'wallet_balance',(select coalesce(sum(balance),0) from public.wallets)
    ),
    'daily',coalesce((
      select jsonb_agg(jsonb_build_object(
        'date',d.day,
        'members',(select count(*) from public.profiles p where timezone('Europe/Istanbul',p.created_at)::date=d.day),
        'dau',(select count(*) from private.user_activity_days ad where ad.activity_date=d.day),
        'coupons',(select count(*) from public.coupons c where timezone('Europe/Istanbul',c.created_at)::date=d.day),
        'coupon_stake',(select coalesce(sum(c.stake),0) from public.coupons c where timezone('Europe/Istanbul',c.created_at)::date=d.day),
        'chance_plays',(select count(*) from public.chance_plays cp where timezone('Europe/Istanbul',cp.created_at)::date=d.day),
        'chance_stake',(select coalesce(sum(cp.stake),0) from public.chance_plays cp where timezone('Europe/Istanbul',cp.created_at)::date=d.day)
      ) order by d.day)
      from (
        select generate_series(v_today-6,v_today,interval '1 day')::date as day
      ) d
    ),'[]'::jsonb),
    'online_users',coalesce((
      select jsonb_agg(to_jsonb(ou) order by ou.last_seen_at desc)
      from (
        select p.display_name,up.last_page,up.last_seen_at,up.session_count
        from private.user_presence up
        join public.profiles p on p.id=up.user_id
        where up.last_seen_at>=now()-interval '15 minutes'
        order by up.last_seen_at desc
        limit 20
      ) ou
    ),'[]'::jsonb),
    'page_usage',coalesce((
      select jsonb_agg(to_jsonb(pg) order by pg.pings desc,pg.users desc)
      from (
        select page,sum(pings)::bigint as pings,count(distinct user_id) as users
        from private.user_page_activity_days
        where activity_date between v_today-6 and v_today
        group by page
        order by sum(pings) desc,count(distinct user_id) desc
      ) pg
    ),'[]'::jsonb),
    'economy_systems',coalesce((
      select jsonb_agg(to_jsonb(e) order by abs(e.net) desc,e.volume desc)
      from (
        select 'coupons'::text as key,'Kuponlar'::text as name,count(*)::bigint as plays,
          coalesce(sum(stake),0)::bigint as volume,coalesce(sum(payout),0)::bigint as payout,
          (coalesce(sum(stake),0)-coalesce(sum(payout),0))::bigint as net
        from public.coupons
        union all
        select 'chance:'||game_key,game_key,count(*)::bigint,coalesce(sum(stake),0)::bigint,
          coalesce(sum(payout),0)::bigint,(coalesce(sum(stake),0)-coalesce(sum(payout),0))::bigint
        from public.chance_plays group by game_key
        union all
        select 'luxury','Good Life Lüks',count(*)::bigint,coalesce(sum(price_paid),0)::bigint,0::bigint,
          coalesce(sum(price_paid),0)::bigint from public.profile_luxuries
        union all
        select 'cosmetics','Profil Kozmetik',count(*)::bigint,coalesce(sum(price_paid),0)::bigint,0::bigint,
          coalesce(sum(price_paid),0)::bigint from public.profile_cosmetics
        union all
        select 'rescue','AFMB Mesai',coalesce(sum(rescue_visits),0)::bigint,0::bigint,
          (coalesce(sum(rescue_visits),0)*1000)::bigint,-(coalesce(sum(rescue_visits),0)*1000)::bigint
        from public.profile_stats
      ) e
    ),'[]'::jsonb),
    'recent_users',coalesce((
      select jsonb_agg(to_jsonb(u) order by u.created_at desc)
      from (
        select p.id::text as id,p.display_name,p.created_at,coalesce(w.balance,0) as balance,
          (select count(*) from public.coupons c where c.user_id=p.id) as coupons,
          (select count(*) from public.chance_plays cp where cp.user_id=p.id) as chance_plays,
          (select coalesce(sum(pl.price_paid),0) from public.profile_luxuries pl where pl.user_id=p.id) as luxury_spent,
          up.last_seen_at,up.last_page,coalesce(up.session_count,0) as sessions
        from public.profiles p
        left join public.wallets w on w.user_id=p.id
        left join private.user_presence up on up.user_id=p.id
        order by p.created_at desc
        limit 20
      ) u
    ),'[]'::jsonb),
    'recent_coupons',coalesce((
      select jsonb_agg(to_jsonb(cq) order by cq.created_at desc)
      from (
        select c.id::text as id,coalesce(p.display_name,'Vatandaş') as display_name,
          c.created_at,c.stake,c.total_odds,c.possible_return,c.status,c.payout
        from public.coupons c
        left join public.profiles p on p.id=c.user_id
        order by c.created_at desc
        limit 20
      ) cq
    ),'[]'::jsonb),
    'recent_chance',coalesce((
      select jsonb_agg(to_jsonb(ch) order by ch.created_at desc)
      from (
        select cp.id,coalesce(p.display_name,'Vatandaş') as display_name,
          cp.created_at,cp.game_key,cp.stake,cp.multiplier,cp.payout
        from public.chance_plays cp
        left join public.profiles p on p.id=cp.user_id
        order by cp.created_at desc
        limit 20
      ) ch
    ),'[]'::jsonb),
    'popular_games',coalesce((
      select jsonb_agg(to_jsonb(g) order by g.plays desc,g.stake desc)
      from (
        select game_key,count(*) as plays,coalesce(sum(stake),0) as stake,coalesce(sum(payout),0) as payout
        from public.chance_plays
        group by game_key
        order by count(*) desc,coalesce(sum(stake),0) desc
        limit 8
      ) g
    ),'[]'::jsonb)
  );
end;
$function$;
