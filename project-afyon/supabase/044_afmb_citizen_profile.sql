-- Project Afyon 044 — AFMB Citizen Profile
-- Earned badges + cosmetic profile upgrades paid with virtual ₳D.
-- Cosmetics are identity-only and never alter game odds, payouts or progression.

create table if not exists public.profile_cosmetic_catalog(
  cosmetic_key text primary key,
  category text not null check(category in ('avatar','title','frame','stamp')),
  icon text not null,
  name text not null,
  description text not null,
  price bigint not null check(price>=0),
  sort_order integer not null default 0
);

create table if not exists public.profile_badge_catalog(
  badge_key text primary key,
  icon text not null,
  name text not null,
  description text not null,
  sort_order integer not null default 0
);

create table if not exists public.profile_loadouts(
  user_id uuid primary key references public.profiles(id) on delete cascade,
  avatar_key text not null default 'COOL' references public.profile_cosmetic_catalog(cosmetic_key),
  title_key text not null default 'CITIZEN' references public.profile_cosmetic_catalog(cosmetic_key),
  frame_key text not null default 'STANDARD' references public.profile_cosmetic_catalog(cosmetic_key),
  stamp_key text not null default 'NONE' references public.profile_cosmetic_catalog(cosmetic_key),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_cosmetics(
  user_id uuid not null references public.profiles(id) on delete cascade,
  cosmetic_key text not null references public.profile_cosmetic_catalog(cosmetic_key),
  price_paid bigint not null default 0,
  purchased_at timestamptz not null default now(),
  primary key(user_id,cosmetic_key)
);

create table if not exists public.profile_badges(
  user_id uuid not null references public.profiles(id) on delete cascade,
  badge_key text not null references public.profile_badge_catalog(badge_key),
  earned_at timestamptz not null default now(),
  primary key(user_id,badge_key)
);

create table if not exists public.profile_stats(
  user_id uuid primary key references public.profiles(id) on delete cascade,
  rescue_visits integer not null default 0 check(rescue_visits>=0),
  updated_at timestamptz not null default now()
);

alter table public.profile_cosmetic_catalog enable row level security;
alter table public.profile_badge_catalog enable row level security;
alter table public.profile_loadouts enable row level security;
alter table public.profile_cosmetics enable row level security;
alter table public.profile_badges enable row level security;
alter table public.profile_stats enable row level security;

drop policy if exists profile_cosmetic_catalog_read on public.profile_cosmetic_catalog;
create policy profile_cosmetic_catalog_read on public.profile_cosmetic_catalog
for select to anon,authenticated using (true);

drop policy if exists profile_badge_catalog_read on public.profile_badge_catalog;
create policy profile_badge_catalog_read on public.profile_badge_catalog
for select to anon,authenticated using (true);

drop policy if exists profile_loadouts_select_own on public.profile_loadouts;
create policy profile_loadouts_select_own on public.profile_loadouts
for select to authenticated using ((select auth.uid())=user_id);

drop policy if exists profile_cosmetics_select_own on public.profile_cosmetics;
create policy profile_cosmetics_select_own on public.profile_cosmetics
for select to authenticated using ((select auth.uid())=user_id);

drop policy if exists profile_badges_select_own on public.profile_badges;
create policy profile_badges_select_own on public.profile_badges
for select to authenticated using ((select auth.uid())=user_id);

drop policy if exists profile_stats_select_own on public.profile_stats;
create policy profile_stats_select_own on public.profile_stats
for select to authenticated using ((select auth.uid())=user_id);

revoke all on public.profile_cosmetic_catalog,public.profile_badge_catalog,public.profile_loadouts,public.profile_cosmetics,public.profile_badges,public.profile_stats from anon,authenticated;
grant select on public.profile_cosmetic_catalog,public.profile_badge_catalog to anon,authenticated;
grant select on public.profile_loadouts,public.profile_cosmetics,public.profile_badges,public.profile_stats to authenticated;

insert into public.profile_cosmetic_catalog(cosmetic_key,category,icon,name,description,price,sort_order) values
  ('COOL','avatar','😎','Standart Vatandaş','AFMB dosyasında olağan şüpheli görünüm.',0,10),
  ('CLERK','avatar','🧑‍💼','Geçici Memur','Maaş bordrosu görmüş ama kadro görmemiş ifade.',700,20),
  ('MONEY_FACE','avatar','🤑','Likidite Yüzü','Bakiye artınca doğal olarak oluştuğu iddia edilen mimik.',2500,30),
  ('WHALE','avatar','🐋','Kamuoyunda Balina','AFMB bu sınıflandırmanın bilimsel olmadığını belirtir.',8000,40),
  ('STATUE','avatar','🗿','Likidite Anıtı','Kazanınca kıpırdamaz, kaybedince de kıpırdamaz.',12000,50),

  ('CITIZEN','title','📄','Sıradan Afyon Vatandaşı','Henüz hakkında ayrı klasör açılmamıştır.',0,110),
  ('SMALL_INVESTOR','title','🪙','Küçük Yatırımcı (Kendine Göre)','Portföy: iki kupon ve güçlü kanaatler.',500,120),
  ('COUPON_ENGINEER','title','🎟️','Kombine Mühendisi','Altı doğru seçimin yanına yedinciyi ekleme yetkinliği.',1500,130),
  ('AFMB_CONSULTANT','title','🏛️','AFMB Dışarıdan Danışmanı','Kurum kendisini danışman olarak görevlendirmemiştir.',3500,140),
  ('LIQUIDITY_PROVIDER','title','💸','Likidite Sağlayıcısı','Kasaya yaptığı katkılar kurumumuzca fark edilmiştir.',7500,150),
  ('PUBLIC_WHALE','title','🐋','Kamuoyunda Balina Olarak Bilinen','Resmî unvan değildir. Daha kötüsü: pahalıdır.',12000,160),

  ('STANDARD','frame','▫️','Standart Dosya Kenarı','Devlet dairesi uyumlu, heyecansız ve ücretsiz.',0,210),
  ('DOSSIER_BLUE','frame','🟦','Dosya Mavisi','Evrak kaybolduğunda ilk bakılan klasör rengi.',750,220),
  ('TENDER_GOLD','frame','🟨','İhale Altını','Neden altın olduğu sorulmamaktadır.',2500,230),
  ('DIRECTOR_PURPLE','frame','🟪','Müdür Moru','Koridorda yürürken doğal olarak yol açar.',4500,240),
  ('EMERGENCY_RED','frame','🟥','Acil Durum Kırmızısı','Bakiye ile psikoloji arasındaki bağı temsil eder.',6500,250),
  ('STATE_SERIOUS','frame','🏛️','Devlet Ciddiyeti','Çerçeveye bakınca istemsizce evrak imzalatır.',10000,260),

  ('NONE','stamp','—','Mühürsüz','Dosyan henüz resmî olarak gereksizleşmedi.',0,310),
  ('APPROVED','stamp','✅','ONAYLANDI','Ne için onaylandığı açıklanmamıştır.',1000,320),
  ('UNDER_REVIEW','stamp','🔎','İNCELEMEDE','AFMB seni izliyor olabilir. Ya da öğle arasındadır.',1500,330),
  ('CONSIDERED','stamp','📌','GEREĞİ DÜŞÜNÜLDÜ','Gereğinin ne olduğu ayrıca düşünülmemiştir.',3000,340),
  ('ASSETS_SUSPICIOUS','stamp','⚠️','MALVARLIĞI ŞÜPHELİ','Zengin olduğun anlamına gelmez. Tam tersine olabilir.',5000,350),
  ('WATCHED','stamp','👁️','AFMB TARAFINDAN İZLENİYOR','Kurum bunu tehdit değil hizmet olarak sınıflandırmıştır.',7500,360)
on conflict(cosmetic_key) do update set
  category=excluded.category,icon=excluded.icon,name=excluded.name,
  description=excluded.description,price=excluded.price,sort_order=excluded.sort_order;

insert into public.profile_badge_catalog(badge_key,icon,name,description,sort_order) values
  ('DOSYA_ACILDI','📁','Dosya Açıldı','AFMB seni artık ismen değil UUID ile tanıyor.',10),
  ('ILK_KUPON','🎟️','İlk Evrak','İlk kupon resmî kayda geçti. Geri dönüş yok.',20),
  ('KUPON_MEMURU','📚','Kupon Memuru','En az 10 kuponla kurum arşivine anlam kattın.',30),
  ('LUNAPARK_MUDAVIMI','🎰','Lunapark Müdavimi','En az 10 şans oyunu. AFMB sandalye ayırdı.',40),
  ('ROKET_MUHENDISI','🚀','Roket Mühendisi (Belgesiz)','Roketten en az ×2.50 ile inmeyi başardın.',50),
  ('KART_PROFESORU','🃏','Kart Profesörü','Yüksek-alçakta ×3.00 veya üstünü gördün. Diploma yok.',60),
  ('PENALTI_BAKANI','⚽','Penaltı Bakanı','5/5 seri ve ×7.00. Kaleciler sendikası rahatsız.',70),
  ('MUFETTISTEN_KACTI','🕵️','Müfettişten Kaçtı','Müfettişten tam seri kaçış. Adres bilgisi paylaşılmadı.',80),
  ('BOKS_LOBISI','🥊','Boks Lobisi','Kazanan bir boks kuponuyla ring masasına nüfuz ettin.',90),
  ('GECICI_PERSONEL','🧹','Geçici Personel','En az bir AFMB Acil İstihdam mesaisini tamamladın.',100),
  ('AFMB_DEMIRBASI','🏛️','AFMB Demirbaşı','Beş kez kurtarma mesaisi. Artık personel seni tanıyor.',110),
  ('MALI_FELAKET','🚨','Ayın Mali Felaketi','On kurtarma mesaisi. Kurum adına plaket düşündük, vazgeçtik.',120),
  ('KAMUOYUNDA_BALINA','🐋','Kamuoyunda Balina','Toplam oyun/kupon miktarın 25.000 ₳D sınırını geçti.',130)
on conflict(badge_key) do update set
  icon=excluded.icon,name=excluded.name,description=excluded.description,sort_order=excluded.sort_order;

insert into public.profile_loadouts(user_id)
select id from public.profiles
on conflict(user_id) do nothing;

insert into public.profile_stats(user_id)
select id from public.profiles
on conflict(user_id) do nothing;

create or replace function private.sync_profile_badges(p_user uuid)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_coupon_count integer:=0;
  v_chance_count integer:=0;
  v_rescue integer:=0;
  v_total_stake bigint:=0;
begin
  if p_user is null then return; end if;

  insert into public.profile_stats(user_id) values(p_user)
  on conflict(user_id) do nothing;

  insert into public.profile_loadouts(user_id) values(p_user)
  on conflict(user_id) do nothing;

  select count(*)::integer,coalesce(sum(stake),0)::bigint
  into v_coupon_count,v_total_stake
  from public.coupons where user_id=p_user;

  select count(*)::integer,v_total_stake+coalesce(sum(stake),0)::bigint
  into v_chance_count,v_total_stake
  from public.chance_plays where user_id=p_user;

  select rescue_visits into v_rescue
  from public.profile_stats where user_id=p_user;

  insert into public.profile_badges(user_id,badge_key) values(p_user,'DOSYA_ACILDI')
  on conflict do nothing;

  if v_coupon_count>=1 then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'ILK_KUPON') on conflict do nothing;
  end if;
  if v_coupon_count>=10 then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'KUPON_MEMURU') on conflict do nothing;
  end if;
  if v_chance_count>=10 then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'LUNAPARK_MUDAVIMI') on conflict do nothing;
  end if;
  if exists(select 1 from public.chance_plays where user_id=p_user and game_key='rocket' and multiplier>=2.50) then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'ROKET_MUHENDISI') on conflict do nothing;
  end if;
  if exists(select 1 from public.chance_plays where user_id=p_user and game_key='high_card' and multiplier>=3.00) then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'KART_PROFESORU') on conflict do nothing;
  end if;
  if exists(select 1 from public.chance_plays where user_id=p_user and game_key='penalty_series' and multiplier>=7.00) then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'PENALTI_BAKANI') on conflict do nothing;
  end if;
  if exists(select 1 from public.chance_plays where user_id=p_user and game_key='inspector_escape' and multiplier>=7.20) then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'MUFETTISTEN_KACTI') on conflict do nothing;
  end if;
  if exists(
    select 1
    from public.coupons c
    join public.coupon_selections cs on cs.coupon_id=c.id
    where c.user_id=p_user and c.status='won' and cs.bout_id is not null
  ) then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'BOKS_LOBISI') on conflict do nothing;
  end if;
  if v_rescue>=1 then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'GECICI_PERSONEL') on conflict do nothing;
  end if;
  if v_rescue>=5 then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'AFMB_DEMIRBASI') on conflict do nothing;
  end if;
  if v_rescue>=10 then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'MALI_FELAKET') on conflict do nothing;
  end if;
  if v_total_stake>=25000 then
    insert into public.profile_badges(user_id,badge_key) values(p_user,'KAMUOYUNDA_BALINA') on conflict do nothing;
  end if;
end;
$function$;

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

create or replace function public.profile_cosmetic_action(p_action text,p_key text)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
  v_action text:=upper(coalesce(p_action,''));
  v_key text:=upper(coalesce(p_key,''));
  v_category text;
  v_price bigint;
  v_balance bigint;
  v_owned boolean;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;

  select category,price into v_category,v_price
  from public.profile_cosmetic_catalog
  where cosmetic_key=v_key;

  if not found then raise exception 'UNKNOWN_COSMETIC'; end if;
  if v_action not in ('BUY','EQUIP') then raise exception 'UNKNOWN_ACTION'; end if;

  insert into public.profile_loadouts(user_id) values(v_user)
  on conflict(user_id) do nothing;

  select exists(
    select 1 from public.profile_cosmetics
    where user_id=v_user and cosmetic_key=v_key
  ) into v_owned;

  if v_action='BUY' and not v_owned and v_price>0 then
    select balance into v_balance
    from public.wallets
    where user_id=v_user
    for update;

    if not found then raise exception 'WALLET_NOT_FOUND'; end if;
    if v_balance<v_price then raise exception 'YETERSIZ_AD'; end if;

    update public.wallets
    set balance=balance-v_price,updated_at=now()
    where user_id=v_user;

    insert into public.profile_cosmetics(user_id,cosmetic_key,price_paid)
    values(v_user,v_key,v_price)
    on conflict do nothing;

    v_owned:=true;
  elsif v_price=0 then
    v_owned:=true;
  end if;

  if not v_owned then raise exception 'COSMETIC_NOT_OWNED'; end if;

  if v_category='avatar' then
    update public.profile_loadouts set avatar_key=v_key,updated_at=now() where user_id=v_user;
  elsif v_category='title' then
    update public.profile_loadouts set title_key=v_key,updated_at=now() where user_id=v_user;
  elsif v_category='frame' then
    update public.profile_loadouts set frame_key=v_key,updated_at=now() where user_id=v_user;
  elsif v_category='stamp' then
    update public.profile_loadouts set stamp_key=v_key,updated_at=now() where user_id=v_user;
  end if;

  return public.get_my_profile();
end;
$function$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.profiles(id,display_name)
  values(new.id,coalesce(new.raw_user_meta_data->>'display_name',split_part(new.email,'@',1)))
  on conflict(id) do nothing;

  insert into public.wallets(user_id,balance)
  values(new.id,5000)
  on conflict(user_id) do nothing;

  insert into public.profile_loadouts(user_id) values(new.id)
  on conflict(user_id) do nothing;

  insert into public.profile_stats(user_id) values(new.id)
  on conflict(user_id) do nothing;

  return new;
end;
$function$;

-- Keep AFMB rescue seniority authoritative on the server for profile badges.
create or replace function public.claim_afmb_rescue()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
  v_balance bigint;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;

  select w.balance into v_balance
  from public.wallets w
  where w.user_id=v_user
  for update;

  if not found then raise exception 'WALLET_NOT_FOUND'; end if;
  if v_balance>=10 then raise exception 'AFMB_NOT_ELIGIBLE'; end if;

  if exists(
    select 1 from public.coupons c
    where c.user_id=v_user and c.status='pending'
  ) then
    raise exception 'AFMB_PENDING_COUPON';
  end if;

  update public.wallets
  set balance=balance+1000,updated_at=now()
  where user_id=v_user
  returning balance into v_balance;

  insert into public.profile_stats(user_id,rescue_visits,updated_at)
  values(v_user,1,now())
  on conflict(user_id) do update
    set rescue_visits=public.profile_stats.rescue_visits+1,updated_at=now();

  return jsonb_build_object('granted',1000,'balance',v_balance);
end;
$function$;

create index if not exists profile_badges_badge_key_idx on public.profile_badges(badge_key);
create index if not exists profile_cosmetics_cosmetic_key_idx on public.profile_cosmetics(cosmetic_key);
create index if not exists profile_loadouts_avatar_key_idx on public.profile_loadouts(avatar_key);
create index if not exists profile_loadouts_title_key_idx on public.profile_loadouts(title_key);
create index if not exists profile_loadouts_frame_key_idx on public.profile_loadouts(frame_key);
create index if not exists profile_loadouts_stamp_key_idx on public.profile_loadouts(stamp_key);

revoke all on function public.get_my_profile() from public;
revoke all on function public.get_my_profile() from anon;
revoke all on function public.profile_cosmetic_action(text,text) from public;
revoke all on function public.profile_cosmetic_action(text,text) from anon;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.profile_cosmetic_action(text,text) to authenticated;
