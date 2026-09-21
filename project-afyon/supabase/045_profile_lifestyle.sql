-- Project Afyon 045 — Good Life / Lifestyle Progression
-- Luxury collection + 3 dream targets + server-authoritative virtual ₳D spending.
-- All purchases are cosmetic/meta only: no odds, payout or game advantage changes.

create table if not exists public.profile_luxury_catalog(
  item_key text primary key,
  icon text not null,
  name text not null,
  description text not null,
  price bigint not null check(price>0),
  sort_order integer not null default 0
);

create table if not exists public.profile_luxuries(
  user_id uuid not null references public.profiles(id) on delete cascade,
  item_key text not null references public.profile_luxury_catalog(item_key),
  price_paid bigint not null check(price_paid>0),
  purchased_at timestamptz not null default now(),
  primary key(user_id,item_key)
);

create table if not exists public.profile_dreams(
  user_id uuid not null references public.profiles(id) on delete cascade,
  slot smallint not null check(slot between 1 and 3),
  item_key text not null references public.profile_luxury_catalog(item_key),
  updated_at timestamptz not null default now(),
  primary key(user_id,slot),
  unique(user_id,item_key)
);

alter table public.profile_luxury_catalog enable row level security;
alter table public.profile_luxuries enable row level security;
alter table public.profile_dreams enable row level security;

drop policy if exists profile_luxury_catalog_read on public.profile_luxury_catalog;
create policy profile_luxury_catalog_read on public.profile_luxury_catalog
for select to anon,authenticated using (true);

drop policy if exists profile_luxuries_select_own on public.profile_luxuries;
create policy profile_luxuries_select_own on public.profile_luxuries
for select to authenticated using ((select auth.uid())=user_id);

drop policy if exists profile_dreams_select_own on public.profile_dreams;
create policy profile_dreams_select_own on public.profile_dreams
for select to authenticated using ((select auth.uid())=user_id);

revoke all on public.profile_luxury_catalog,public.profile_luxuries,public.profile_dreams from anon,authenticated;
grant select on public.profile_luxury_catalog to anon,authenticated;
grant select on public.profile_luxuries,public.profile_dreams to authenticated;

insert into public.profile_luxury_catalog(item_key,icon,name,description,price,sort_order) values
('MARKA_GOZLUK','🕶️','Marka Güneş Gözlüğü','Hava kapalı olabilir. Statü meteoroloji dinlemez.',2500,10),
('ITALYAN_AYAKKABI','👞','İtalyan Ayakkabı','Daha hızlı yürütmez. Koridorda sesi daha pahalı çıkar.',4000,20),
('LUKS_SAAT','⌚','Lüks Saat','Saati telefon da gösteriyordu ama konu o değil.',7500,30),
('VIP_MASA','🍾','VIP Masa','Masa aynı masa. Hesap kesinlikle aynı hesap değil.',10000,40),
('ALTIN_TELEFON','📱','Altın Kaplama Telefon','Çekim gücü değişmedi. Özgüven değişmiş olabilir.',15000,50),
('PATRON_KOLTUGU','🪑','Deri Patron Koltuğu','Otururken bütçe toplantısı yapma isteği uyandırır.',22500,60),
('MODERN_SANAT','🖼️','Anlamsız Modern Sanat','Ne olduğu bilinmiyor. Pahalı olduğu kesin.',30000,70),
('OZEL_PLAKALI_SCOOTER','🛵','Özel Plakalı Scooter','Gereksiz derecede kişisel bir ulaşım çözümü.',40000,80),
('ELMAS_KASIK','🥄','Elmas Çay Kaşığı','Çay hâlâ aynı çay. Kaşığın haberi yok.',55000,90),
('DEV_AKVARYUM','🐠','Dev Akvaryum','Balıkların senden daha düzenli bir portföyü var.',75000,100),
('SPOR_ARABA','🏎️','Spor Araba','Mantıklı kararlar döneminin resmen kapandığı araç.',100000,110),
('MANZARALI_DAIRE','🏠','Manzaralı Daire','Kupon buradan da kaybedilebiliyor ama manzara iyi.',135000,120),
('IKINCI_SPOR_ARABA','🚗','İkinci Spor Araba','Birincisinin çözmediği hangi sorunu çözdüğü belirsiz.',175000,130),
('YARIS_ATI','🐎','Yarış Atı','Adını sen koyarsın. Finans danışmanı karışmaz.',225000,140),
('HELIKOPTER_HISSESI','🚁','Helikopter Hissesi','Helikopterin tamamı bile değil. Bu bilgi fiyatı düşürmedi.',300000,150),
('KUCUK_YAT','⛵','Küçük Yat','Küçük kelimesi yalnızca büyük yat satabilmek için kullanılır.',400000,160),
('BUYUK_ELMAS','💎','Gereksiz Büyük Elmas','Finans danışmanın çevrimdışı görünmeye başladı.',525000,170),
('ADA_HISSESI','🏝️','Ada Hissesi','Adanın yaklaşık üç ağacı ve bir kayanın yarısı senin.',675000,180),
('BUYUK_YAT','🛥️','Büyük Yat','Küçük yat artık senden gözlerini kaçırıyor.',850000,190),
('OZEL_JET','✈️','Özel Jet','Ekonomi sınıfını hatırlamamak için alınan pahalı hafıza silici.',1100000,200),
('VIP_LOCA','🏟️','VIP Loca','Maç aynı maç. Sandalye çok daha ciddi.',1400000,210),
('KENDINE_HEYKEL','🗿','Kendine Heykel','Mütevazılık yönetmelikten çıkarıldı.',1800000,220),
('STADYUM_ISIM_HAKKI','📣','Stadyum İsim Hakkı','Tabelada adın yazıyor. Skora etkisi hâlâ sıfır.',2300000,230),
('OZEL_ADA','🌴','Özel Ada','Ada hissesindeki diğer ağaçlar da sonunda teslim edildi.',3000000,240),
('KENDINI_KRAL_ILAN_ET','👑','Kendini Kral İlan Et','Hiçbir yetki vermez. Buna rağmen tören masrafı yüksektir.',4000000,250)
on conflict(item_key) do update set
  icon=excluded.icon,name=excluded.name,description=excluded.description,
  price=excluded.price,sort_order=excluded.sort_order;

create index if not exists profile_luxuries_item_key_idx on public.profile_luxuries(item_key);
create index if not exists profile_dreams_item_key_idx on public.profile_dreams(item_key);

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
    'profile',jsonb_build_object('display_name',p.display_name,'created_at',p.created_at),
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

create or replace function public.profile_buy_luxury(p_key text)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
  v_key text:=upper(coalesce(p_key,''));
  v_price bigint;
  v_balance bigint;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;

  select price into v_price
  from public.profile_luxury_catalog
  where item_key=v_key;
  if not found then raise exception 'UNKNOWN_LUXURY'; end if;

  select balance into v_balance
  from public.wallets
  where user_id=v_user
  for update;
  if not found then raise exception 'WALLET_NOT_FOUND'; end if;

  if exists(select 1 from public.profile_luxuries where user_id=v_user and item_key=v_key) then
    return public.get_my_profile();
  end if;

  if v_balance<v_price then raise exception 'YETERSIZ_AD'; end if;

  update public.wallets
  set balance=balance-v_price,updated_at=now()
  where user_id=v_user;

  insert into public.profile_luxuries(user_id,item_key,price_paid)
  values(v_user,v_key,v_price);

  delete from public.profile_dreams
  where user_id=v_user and item_key=v_key;

  return public.get_my_profile();
end;
$function$;

create or replace function public.profile_set_dream(p_slot smallint,p_key text default null)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
  v_key text:=case when p_key is null then null else upper(p_key) end;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_slot is null or p_slot<1 or p_slot>3 then raise exception 'INVALID_DREAM_SLOT'; end if;

  if v_key is null or btrim(v_key)='' then
    delete from public.profile_dreams where user_id=v_user and slot=p_slot;
    return public.get_my_profile();
  end if;

  if not exists(select 1 from public.profile_luxury_catalog where item_key=v_key) then
    raise exception 'UNKNOWN_LUXURY';
  end if;

  if exists(select 1 from public.profile_luxuries where user_id=v_user and item_key=v_key) then
    delete from public.profile_dreams where user_id=v_user and item_key=v_key;
    return public.get_my_profile();
  end if;

  delete from public.profile_dreams
  where user_id=v_user and item_key=v_key and slot<>p_slot;

  insert into public.profile_dreams(user_id,slot,item_key,updated_at)
  values(v_user,p_slot,v_key,now())
  on conflict(user_id,slot) do update
  set item_key=excluded.item_key,updated_at=now();

  return public.get_my_profile();
end;
$function$;

revoke all on function public.profile_buy_luxury(text) from public;
revoke all on function public.profile_buy_luxury(text) from anon;
revoke all on function public.profile_set_dream(smallint,text) from public;
revoke all on function public.profile_set_dream(smallint,text) from anon;
grant execute on function public.profile_buy_luxury(text) to authenticated;
grant execute on function public.profile_set_dream(smallint,text) to authenticated;
