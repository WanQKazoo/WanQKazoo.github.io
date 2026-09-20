-- Project Afyon 0.53 — Boxing World v2
-- Fighter profiles, persistent belts, rematch metadata and a much richer AFMB ring commentator.

alter table public.boxing_bouts
  add column if not exists is_title_fight boolean not null default false,
  add column if not exists rematch_no smallint not null default 1;

do $$
begin
  if not exists(
    select 1 from pg_constraint
    where conrelid='public.boxing_bouts'::regclass
      and conname='boxing_bouts_rematch_no_check'
  ) then
    alter table public.boxing_bouts
      add constraint boxing_bouts_rematch_no_check check (rematch_no between 1 and 99);
  end if;
end;
$$;

create table if not exists public.boxing_titles (
  weight_class text primary key check (weight_class in ('LIGHTWEIGHT','WELTERWEIGHT','MIDDLEWEIGHT','LIGHT_HEAVYWEIGHT','HEAVYWEIGHT')),
  belt_name text not null,
  champion_id text references public.boxing_fighters(id),
  won_at timestamptz,
  defenses integer not null default 0 check (defenses >= 0),
  updated_at timestamptz not null default now()
);

alter table public.boxing_titles enable row level security;
drop policy if exists boxing_titles_public_read on public.boxing_titles;
create policy boxing_titles_public_read
on public.boxing_titles
for select
to anon,authenticated
using (true);
grant select on public.boxing_titles to anon,authenticated;

insert into public.boxing_titles(weight_class,belt_name,champion_id,won_at,defenses)
select x.weight_class,x.belt_name,f.id,now(),0
from (
  values
    ('LIGHTWEIGHT','AFMB Hafif Siklet Kemeri'),
    ('WELTERWEIGHT','AFMB Welter Siklet Kemeri'),
    ('MIDDLEWEIGHT','AFMB Orta Siklet Kemeri'),
    ('LIGHT_HEAVYWEIGHT','AFMB Yarı Ağır Siklet Kemeri'),
    ('HEAVYWEIGHT','AFMB Ağır Siklet Kemeri')
) x(weight_class,belt_name)
cross join lateral (
  select id
  from public.boxing_fighters
  where weight_class=x.weight_class and is_active
  order by rating desc,wins desc,seed
  limit 1
) f
on conflict(weight_class) do nothing;

-- Existing bouts learn whether they are a rematch from actual prior finished meetings.
update public.boxing_bouts b
set rematch_no=1+(
  select count(*)::integer
  from public.boxing_bouts old
  where old.status='finished'
    and old.scheduled_at<b.scheduled_at
    and (
      (old.red_fighter_id=b.red_fighter_id and old.blue_fighter_id=b.blue_fighter_id)
      or
      (old.red_fighter_id=b.blue_fighter_id and old.blue_fighter_id=b.red_fighter_id)
    )
);

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
  select
    b.id,
    b.event_name,
    b.scheduled_at,
    case when b.red_fighter_id=p_fighter_id then b.blue_fighter_id else b.red_fighter_id end,
    opp.name,
    opp.country,
    case
      when b.winner_id is null then 'D'
      when b.winner_id=p_fighter_id then 'W'
      else 'L'
    end,
    b.method,
    b.finish_round,
    b.is_title_fight,
    b.rematch_no
  from public.boxing_bouts b
  join public.boxing_fighters opp
    on opp.id=case when b.red_fighter_id=p_fighter_id then b.blue_fighter_id else b.red_fighter_id end
  where b.status='finished'
    and (b.red_fighter_id=p_fighter_id or b.blue_fighter_id=p_fighter_id)
  order by b.finished_at desc nulls last,b.scheduled_at desc
  limit greatest(1,least(coalesce(p_limit,8),20))
$$;
grant execute on function public.get_boxing_fighter_history(text,integer) to anon,authenticated;

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
declare
  v integer:=mod(abs(coalesce(p_variant,0)),12);
  r integer:=greatest(1,coalesce(p_round,1));
begin
  if p_event='jab' then
    return case v
      when 0 then p_actor||' mesafeyi jab ile ölçüyor. Temiz bir dokunuş.'
      when 1 then p_actor||' öndeki eli çalıştırdı; '||p_other||' bir an ritmini kaybetti.'
      when 2 then 'Hızlı jab! '||p_actor||' puanı aldı ve yeniden açı değiştirdi.'
      when 3 then p_actor||' jabı araya soktu. Bu raundun temposunu kurmaya çalışıyor.'
      when 4 then p_actor||' çift jab ile öne çıktı; '||p_other||' gardı toparlamak zorunda.'
      when 5 then 'Öndeki el yine çalıştı. '||p_actor||' rakibine rahat nefes aldırmıyor.'
      when 6 then p_actor||' mesafeyi çok iyi tutuyor; jab tam yüzün önünde patladı.'
      when 7 then p_other||' içeri girmek istedi ama '||p_actor||' jabla kapıyı kapattı.'
      when 8 then 'Jab, adım, açı değişimi… '||p_actor||' şu an ders anlatır gibi boks yapıyor.'
      when 9 then p_actor||' bir jab daha yazdı. Küçük görünen ama puan toplayan işler.'
      when 10 then 'AFMB ölçüm birimi açıkladı: mesafe bir jab boyu. '||p_actor||' kontrolü bırakmıyor.'
      else p_actor||' öndeki eli fişek gibi gönderdi. '||p_other||' kafasını geriye çekti.'
    end;
  elsif p_event='power_shot' then
    return case v
      when 0 then 'SERT VURUŞ! '||p_actor||' sağ eliyle '||p_other||'''ı geriye itti!'
      when 1 then p_actor||' bütün ağırlığını yumruğa koydu. '||p_other||' bunu kesinlikle hissetti.'
      when 2 then 'Salon ayağa kalktı! '||p_actor||' çok ağır bir isabet buldu.'
      when 3 then p_actor||' gardın arasından güçlü bir yumruk geçirdi. Tehlikeli anlar!'
      when 4 then 'ÇOK SERT! '||p_other||' iki adım geriye gitti, '||p_actor||' üstüne yürüyor.'
      when 5 then p_actor||' sağ kroşeyi oturttu. Ringin sesi değişti resmen.'
      when 6 then 'Ağır bir isabet! '||p_other||' gardını kapattı ama yumruğun tamamını engelleyemedi.'
      when 7 then p_actor||' tam zamanında patlattı. '||p_other||' şimdi ayaklarını yeniden toplamaya çalışıyor.'
      when 8 then 'OVVV! Bunu ring dışında yapsan TCK devreye girer; bu nasıl darbe!'
      when 9 then 'Bir adet geçmiş olsun formu hazırlanıyor. '||p_actor||' çok sert vurdu!'
      when 10 then 'Bu yumruğa e-Devlet''ten itiraz ekranı açılır. '||p_other||' ciddi sarsıldı!'
      else 'Sanayiye götürsen “abi buna komple bakmak lazım” derler. '||p_actor||' bombayı bıraktı!'
    end;
  elsif p_event='combo' then
    return case v
      when 0 then p_actor||' üçlü kombinasyonla içeri girdi; son yumruk net oturdu.'
      when 1 then 'Kombinasyon geliyor! '||p_actor||' baş-gövde-baş çalıştı.'
      when 2 then p_actor||' seri yumruklarla '||p_other||'''ı iplere doğru sürüklüyor.'
      when 3 then 'Çok güzel seri! '||p_actor||' iki eli de devrede.'
      when 4 then p_actor||' iki yumrukla gardı açtı, üçüncüyü boşluğa yerleştirdi.'
      when 5 then 'Bir, iki, üç! '||p_actor||' ritmi buldu; '||p_other||' savunmada kaldı.'
      when 6 then p_actor||' kombinasyonu uzattı. '||p_other||' çıkış kapısını arıyor.'
      when 7 then 'Başladı seri! '||p_actor||' bir anda vitesi yükseltti.'
      when 8 then p_actor||' gövdeyi gösterip yukarı çıktı. Çok temiz kurgu.'
      when 9 then 'Gard çözüldü, seri geldi. '||p_actor||' bu sekansı cebine koydu.'
      when 10 then 'Bu komboya KDV eklesen yine ağır. '||p_actor||' peş peşe isabet buluyor!'
      else 'AFMB kayıtlarına göre bu kadar evrak peş peşe bile gelmiyor. '||p_actor||' yumruk yağdırdı!'
    end;
  elsif p_event='body_shot' then
    return case mod(v,10)
      when 0 then p_actor||' gövdeye indi. Bu yumrukların etkisi ilerleyen raundlarda çıkar.'
      when 1 then 'Karaciğer bölgesine sert vuruş! '||p_other||' dirseğini hemen aşağı çekti.'
      when 2 then p_actor||' gövdeyi ihmal etmiyor; '||p_other||'''ın nefesini hedefliyor.'
      when 3 then p_actor||' kaburgalara çalışıyor. Bu maç uzarsa hesabı ağır olabilir.'
      when 4 then 'Gövdeye temiz isabet. '||p_other||' bir an nefesini tuttu.'
      when 5 then p_actor||' alttan çalıştı; gard yukarıda ama gövde açık kaldı.'
      when 6 then 'Ciğerlere vergi geldi! '||p_actor||' gövdeye çok sert indi.'
      when 7 then p_other||' dirsekleri indirmek zorunda kaldı. '||p_actor||' şimdi üst tarafı açabilir.'
      when 8 then 'O yumruk mideye değil doğrudan moral departmanına gitti.'
      else p_actor||' gövdeyi dövüyor. Köşe bu gidişatı mutlaka konuşacak.'
    end;
  elsif p_event='counter' then
    return case mod(v,10)
      when 0 then 'Mükemmel kontra! '||p_actor||' saldırıyı okudu ve tam zamanında cevap verdi.'
      when 1 then p_other||' açıldı, '||p_actor||' beklediği boşluğu buldu.'
      when 2 then p_actor||' geri adımda kontra yakaladı. Zamanlama çok temiz.'
      when 3 then 'Tam gelirken yakalandı! '||p_actor||' rakibinin hamlesini cezalandırdı.'
      when 4 then p_actor||' önce savundu, sonra anında cevap verdi. Kitap gibi kontra.'
      when 5 then p_other||' fazla heveslendi; '||p_actor||' faturayı kesti.'
      when 6 then 'Bir adım geri, tek cevap. '||p_actor||' gereksiz hiçbir şey yapmadı.'
      when 7 then p_actor||' saldırıyı davet edip kontrayı bıraktı. Çok soğukkanlı.'
      when 8 then '“Gel” dedi, geldi, vurdu. '||p_actor||' bu işi fazla kolay gösterdi.'
      else 'AFMB hızlı işlem birimi bundan daha hızlı çalışmıyor. '||p_actor||' kontrayı yapıştırdı!'
    end;
  elsif p_event='knockdown' then
    return case mod(r+char_length(coalesce(p_actor,'')),8)
      when 0 then 'YERDE! '||p_other||' yere düştü! '||p_actor||' raund '||r||'''da büyük hasar verdi, hakem sayıyor!'
      when 1 then 'KNOCKDOWN! '||p_actor||' yakaladı ve '||p_other||' tuvale gitti! Salon ayakta!'
      when 2 then p_other||' YERDE! Hakem saymaya başladı; '||p_actor||' köşede bekliyor!'
      when 3 then 'İŞLER DEĞİŞTİ! '||p_actor||' tek isabetle '||p_other||'''ı yere gönderdi!'
      when 4 then 'Sekiz sayısı geliyor! '||p_other||' ayağa kalkmaya çalışıyor, '||p_actor||' gözünü ayırmıyor.'
      when 5 then 'Ovvv! Sandalye getirin demeye kalmadı, '||p_other||' zaten yerde! Büyük knockdown!'
      when 6 then 'AFMB Acil Durum Masası toplandı: '||p_other||' tuvalde, hakem sayıyor!'
      else 'Bu artık yumruk değil resmi tebligat! '||p_actor||' knockdown aldı!'
    end;
  elsif p_event='cut' then
    return case mod(v,6)
      when 0 then p_other||'''ın yüzünde kesik var. Doktor yakından bakıyor; '||p_actor||' o bölgeyi hedefleyebilir.'
      when 1 then 'Kanama başladı. '||p_other||'''ın köşesi raund arasında çok çalışacak.'
      when 2 then p_other||' kaş bölgesinden açıldı; doktor ring kenarında dikkatle izliyor.'
      when 3 then 'Kesik kötü yerde. '||p_actor||' artık o tarafı gördü, hedef büyüdü.'
      when 4 then 'Köşeye ekstra mesai çıktı. '||p_other||'''ın yüzünde ciddi bir kesik var.'
      else 'AFMB Sağlık Kurulu dosyayı açtı; '||p_other||' kanıyor ama mücadele sürüyor.'
    end;
  elsif p_event='warning' then
    return case mod(v,6)
      when 0 then 'Hakem araya girdi ve '||p_actor||'''ı uyardı. Dövüş yeniden başlıyor.'
      when 1 then p_actor||' için sözlü uyarı geldi. Hakem “temiz dövüş” diyor.'
      when 2 then 'Hakem net: '||p_actor||' bir kez daha yaparsa puan tehlikeye girebilir.'
      when 3 then 'Kısa bir devlet müdahalesi: hakem '||p_actor||'''a kuralları hatırlattı.'
      when 4 then p_actor||' uyarıyı aldı, başını salladı. Dosya şimdilik kapandı.'
      else 'Hakem toplantıyı kısa kesti. '||p_actor||' uyarıldı, boks devam ediyor.'
    end;
  elsif p_event='round_end' then
    return case mod(r,8)
      when 0 then 'GONG! Raund '||r||' sona erdi. Köşeler şimdi nefes ve taktik peşinde.'
      when 1 then 'Gong geldi! Raund '||r||' bitti; iki köşede de hararetli bir toplantı var.'
      when 2 then 'Raund '||r||' tamam. Su, nefes, vazelin ve bol miktarda nasihat zamanı.'
      when 3 then 'GONG! Ring bir dakika susuyor; köşeler birazdan yine birbirine girecek.'
      when 4 then 'Raund '||r||' kapandı. AFMB puan açıklamıyor, vatandaş kendi hesabını yapıyor.'
      when 5 then 'Gong kurtardı mı, böldü mü tartışılır. Raund '||r||' geride kaldı.'
      when 6 then 'Köşe molası. “Gardını kaldır” toplantısının yeni oturumu başladı.'
      else 'Raund '||r||' tamamlandı. Hakem kartları gizli; tansiyon halka açık.'
    end;
  end if;
  return 'Ringde hareketlilik var.';
end;
$$;

-- Occasional extra ring drama. Roughly 4% of ordinary landed events become
-- a cut or referee warning, keeping them noticeable without becoming noise.
create or replace function private.boxing_flavor_event_trigger()
returns trigger
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  b public.boxing_bouts%rowtype;
  actor_name text;
  other_name text;
  extra_type text;
  roll numeric;
  v integer;
begin
  if new.event_type not in ('jab','power_shot','combo','body_shot','counter') then
    return new;
  end if;

  roll:=random();
  if roll>=.04 then return new; end if;
  extra_type:=case when roll<.022 then 'cut' else 'warning' end;

  select * into b from public.boxing_bouts where id=new.bout_id;
  if new.side='red' then
    select name into actor_name from public.boxing_fighters where id=b.red_fighter_id;
    select name into other_name from public.boxing_fighters where id=b.blue_fighter_id;
  else
    select name into actor_name from public.boxing_fighters where id=b.blue_fighter_id;
    select name into other_name from public.boxing_fighters where id=b.red_fighter_id;
  end if;
  v:=floor(random()*12)::integer;

  insert into public.boxing_bout_events(
    bout_id,round,second_in_round,event_type,side,payload,commentary,visible_at
  ) values(
    new.bout_id,new.round,least(49,new.second_in_round+1),extra_type,new.side,
    jsonb_build_object('flavor',true),
    private.boxing_commentary(extra_type,actor_name,other_name,new.round,v),
    new.visible_at+interval '0.7 seconds'
  );
  return new;
end;
$$;

drop trigger if exists boxing_flavor_event on public.boxing_bout_events;
create trigger boxing_flavor_event
after insert on public.boxing_bout_events
for each row
execute function private.boxing_flavor_event_trigger();

create or replace function private.boxing_finish_commentary_trigger()
returns trigger
language plpgsql
security definer
set search_path='public','private'
as $$
declare
  b public.boxing_bouts%rowtype;
  actor_name text;
  method_name text:=coalesce(new.payload->>'method','');
  v integer:=floor(random()*8)::integer;
begin
  if new.event_type<>'fight_end' then return new; end if;
  select * into b from public.boxing_bouts where id=new.bout_id;

  if new.side='red' then
    select name into actor_name from public.boxing_fighters where id=b.red_fighter_id;
  elsif new.side='blue' then
    select name into actor_name from public.boxing_fighters where id=b.blue_fighter_id;
  else
    actor_name:='Kimse';
  end if;

  if method_name='DRAW' or new.side='neutral' then
    new.commentary:=case v
      when 0 then 'Son gong! Hakemler eşitlik dedi. İki köşe de tam memnun değil; boks geleneği yerine geldi.'
      when 1 then 'BERABERE! Hakem kartları taraf seçmedi. Rövanş isteyenlerin sesi şimdiden geliyor.'
      else 'Karar açıklandı: beraberlik. AFMB, tartışmaların sabaha kadar sürmesini bekliyor.'
    end;
  elsif method_name in ('KO','TKO') then
    new.commentary:=case v
      when 0 then 'BİTTİ! '||actor_name||' maçı '||method_name||' ile kapattı. Hakem daha fazlasına izin vermedi!'
      when 1 then 'MAÇ BİTTİ! '||actor_name||' için '||method_name||' zaferi. Ringde son sözü yumruk söyledi!'
      when 2 then 'Hakem araya girdi! '||actor_name||' işi '||method_name||' ile bitirdi!'
      when 3 then 'Gecenin dosyası kapandı: '||actor_name||' '||method_name||' ile kazandı!'
      when 4 then 'Bu kadar. Hakem “yeter” dedi. '||actor_name||' '||method_name||' galibiyetini aldı!'
      when 5 then 'AFMB sonuç tutanağına tek kelime yazdı: '||method_name||'. Kazanan '||actor_name||'!'
      when 6 then 'Salon ayakta! '||actor_name||' maçı erken bitirdi. Bu gece tekrarını çok izleriz.'
      else 'BİTTİ! '||actor_name||' noktayı koydu. Rakip köşe için uzun bir sabah olacak.'
    end;
  else
    new.commentary:=case v
      when 0 then 'Hakem kartları geldi! '||actor_name||' '||method_name||' ile kazanıyor.'
      when 1 then 'SONUÇ AÇIKLANDI: '||actor_name||' kararla kazandı. Şimdi itirazlar sosyal medyada başlayabilir.'
      when 2 then 'Kartlar okundu. '||actor_name||' gecenin kazananı; yöntem '||method_name||'.'
      when 3 then 'AFMB mühür bastı: '||actor_name||' kararla galip!'
      when 4 then 'Hakemler tercihini yaptı. '||actor_name||' elini kaldırıyor!'
      when 5 then 'Son gongdan sonra bekleyiş bitti: '||actor_name||' kazanıyor.'
      when 6 then 'Karar geldi. '||actor_name||' için zafer; diğer köşede hesap makinesi açıldı.'
      else actor_name||' kazandı! Kartlar açıklandı, ringde dosya kapandı.'
    end;
  end if;
  return new;
end;
$$;

drop trigger if exists boxing_finish_commentary on public.boxing_bout_events;
create trigger boxing_finish_commentary
before insert on public.boxing_bout_events
for each row
execute function private.boxing_finish_commentary_trigger();

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
  v_title_fight boolean;
  v_champion text;
  v_prev_meetings integer;
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
      'AFMB Fight Night #'||v_event_no,
      v_start,v_weight,v_red,v_blue,'scheduled',
      case when v_i=v_main then 12 else 10 end,
      case when v_i=v_main then 720 else 600 end,
      v_order,v_i=v_main,'AFMB Arena',v_title_fight,greatest(1,v_prev_meetings+1)
    )
    on conflict(id) do nothing;
  end loop;
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
  v_current_champion text;
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

  if b.is_title_fight then
    select champion_id into v_current_champion
    from public.boxing_titles
    where weight_class=b.weight_class
    for update;

    if p.winner_id is null then
      update public.boxing_titles
      set defenses=defenses+1,updated_at=now()
      where weight_class=b.weight_class;
    elsif p.winner_id=v_current_champion then
      update public.boxing_titles
      set defenses=defenses+1,updated_at=now()
      where weight_class=b.weight_class;
    else
      update public.boxing_titles
      set champion_id=p.winner_id,won_at=now(),defenses=0,updated_at=now()
      where weight_class=b.weight_class;
    end if;
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

-- Make sure the next title-bearing card can be generated when its date enters the window.
select private.ensure_boxing_schedule((now() at time zone 'Europe/Istanbul')::date+2);
