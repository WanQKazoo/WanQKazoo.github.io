-- Project Afyon 046 — Owner Admin Dashboard
-- Private allow-list + admin-only read dashboard RPC.
-- The first/only existing Project Afyon profile is seeded as project owner at migration time.

create table if not exists private.admin_users(
  user_id uuid primary key references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  note text
);

alter table private.admin_users enable row level security;
revoke all on private.admin_users from public,anon,authenticated;

insert into private.admin_users(user_id,note)
select p.id,'Project owner'
from public.profiles p
order by p.created_at asc
limit 1
on conflict(user_id) do nothing;

create or replace function public.get_my_profile()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
  v_result jsonb;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;

  perform private.sync_profile_badges(v_user);

  select jsonb_build_object(
    'profile',jsonb_build_object(
      'display_name',p.display_name,
      'created_at',p.created_at
    ),
    'is_admin',exists(select 1 from private.admin_users au where au.user_id=v_user),
    'balance',w.balance,
    'loadout',to_jsonb(l)-'user_id'-'updated_at',
    'stats',jsonb_build_object(
      'coupons',(select count(*) from public.coupons c where c.user_id=v_user),
      'won_coupons',(select count(*) from public.coupons c where c.user_id=v_user and c.status='won'),
      'chance_plays',(select count(*) from public.chance_plays cp where cp.user_id=v_user),
      'total_stake',
        coalesce((select sum(c.stake) from public.coupons c where c.user_id=v_user),0)
        +coalesce((select sum(cp.stake) from public.chance_plays cp where cp.user_id=v_user),0),
      'rescue_visits',ps.rescue_visits
    ),
    'owned_cosmetics',coalesce((
      select jsonb_agg(pc.cosmetic_key order by pc.purchased_at)
      from public.profile_cosmetics pc where pc.user_id=v_user
    ),'[]'::jsonb),
    'badges',coalesce((
      select jsonb_agg(jsonb_build_object(
        'key',b.badge_key,'icon',bc.icon,'name',bc.name,'description',bc.description,'earned_at',b.earned_at
      ) order by bc.sort_order)
      from public.profile_badges b
      join public.profile_badge_catalog bc on bc.badge_key=b.badge_key
      where b.user_id=v_user
    ),'[]'::jsonb),
    'badge_catalog',coalesce((
      select jsonb_agg(jsonb_build_object(
        'key',bc.badge_key,'icon',bc.icon,'name',bc.name,'description',bc.description
      ) order by bc.sort_order)
      from public.profile_badge_catalog bc
    ),'[]'::jsonb),
    'cosmetic_catalog',coalesce((
      select jsonb_agg(jsonb_build_object(
        'key',cc.cosmetic_key,'category',cc.category,'icon',cc.icon,'name',cc.name,
        'description',cc.description,'price',cc.price
      ) order by cc.sort_order)
      from public.profile_cosmetic_catalog cc
    ),'[]'::jsonb),
    'luxury_spent',coalesce((
      select sum(pl.price_paid) from public.profile_luxuries pl where pl.user_id=v_user
    ),0),
    'owned_luxuries',coalesce((
      select jsonb_agg(jsonb_build_object(
        'key',pl.item_key,'price_paid',pl.price_paid,'purchased_at',pl.purchased_at
      ) order by pl.purchased_at)
      from public.profile_luxuries pl where pl.user_id=v_user
    ),'[]'::jsonb),
    'dreams',coalesce((
      select jsonb_agg(jsonb_build_object('slot',pd.slot,'key',pd.item_key) order by pd.slot)
      from public.profile_dreams pd where pd.user_id=v_user
    ),'[]'::jsonb),
    'luxury_catalog',coalesce((
      select jsonb_agg(jsonb_build_object(
        'key',lc.item_key,'icon',lc.icon,'name',lc.name,'description',lc.description,'price',lc.price
      ) order by lc.sort_order)
      from public.profile_luxury_catalog lc
    ),'[]'::jsonb)
  )
  into v_result
  from public.profiles p
  join public.wallets w on w.user_id=p.id
  join public.profile_loadouts l on l.user_id=p.id
  join public.profile_stats ps on ps.user_id=p.id
  where p.id=v_user;

  if v_result is null then raise exception 'PROFILE_NOT_FOUND'; end if;
  return v_result;
end;
$function$;

create or replace function public.get_admin_dashboard()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists(select 1 from private.admin_users au where au.user_id=v_user) then
    raise exception 'ADMIN_REQUIRED';
  end if;

  return jsonb_build_object(
    'generated_at',now(),
    'summary',jsonb_build_object(
      'members',(select count(*) from public.profiles),
      'new_today',(select count(*) from public.profiles p where timezone('Europe/Istanbul',p.created_at)::date=timezone('Europe/Istanbul',now())::date),
      'new_7d',(select count(*) from public.profiles p where p.created_at>=now()-interval '7 days'),
      'active_24h',(select count(distinct x.user_id) from (
        select c.user_id from public.coupons c where c.created_at>=now()-interval '24 hours'
        union all
        select cp.user_id from public.chance_plays cp where cp.created_at>=now()-interval '24 hours'
        union all
        select pl.user_id from public.profile_luxuries pl where pl.purchased_at>=now()-interval '24 hours'
      ) x),
      'active_7d',(select count(distinct x.user_id) from (
        select c.user_id from public.coupons c where c.created_at>=now()-interval '7 days'
        union all
        select cp.user_id from public.chance_plays cp where cp.created_at>=now()-interval '7 days'
        union all
        select pl.user_id from public.profile_luxuries pl where pl.purchased_at>=now()-interval '7 days'
      ) x),
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
      'wallet_balance',(select coalesce(sum(balance),0) from public.wallets)
    ),
    'daily',coalesce((
      select jsonb_agg(jsonb_build_object(
        'date',d.day,
        'members',(select count(*) from public.profiles p where timezone('Europe/Istanbul',p.created_at)::date=d.day),
        'coupons',(select count(*) from public.coupons c where timezone('Europe/Istanbul',c.created_at)::date=d.day),
        'coupon_stake',(select coalesce(sum(c.stake),0) from public.coupons c where timezone('Europe/Istanbul',c.created_at)::date=d.day),
        'chance_plays',(select count(*) from public.chance_plays cp where timezone('Europe/Istanbul',cp.created_at)::date=d.day),
        'chance_stake',(select coalesce(sum(cp.stake),0) from public.chance_plays cp where timezone('Europe/Istanbul',cp.created_at)::date=d.day)
      ) order by d.day)
      from (
        select generate_series(
          timezone('Europe/Istanbul',now())::date-6,
          timezone('Europe/Istanbul',now())::date,
          interval '1 day'
        )::date as day
      ) d
    ),'[]'::jsonb),
    'recent_users',coalesce((
      select jsonb_agg(to_jsonb(u) order by u.created_at desc)
      from (
        select
          p.id::text as id,
          p.display_name,
          p.created_at,
          coalesce(w.balance,0) as balance,
          (select count(*) from public.coupons c where c.user_id=p.id) as coupons,
          (select count(*) from public.chance_plays cp where cp.user_id=p.id) as chance_plays,
          (select coalesce(sum(pl.price_paid),0) from public.profile_luxuries pl where pl.user_id=p.id) as luxury_spent
        from public.profiles p
        left join public.wallets w on w.user_id=p.id
        order by p.created_at desc
        limit 20
      ) u
    ),'[]'::jsonb),
    'recent_coupons',coalesce((
      select jsonb_agg(to_jsonb(cq) order by cq.created_at desc)
      from (
        select
          c.id::text as id,
          coalesce(p.display_name,'Vatandaş') as display_name,
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
        select
          cp.id,
          coalesce(p.display_name,'Vatandaş') as display_name,
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

revoke all on function public.get_admin_dashboard() from public;
revoke all on function public.get_admin_dashboard() from anon;
grant execute on function public.get_admin_dashboard() to authenticated;
