-- Project Afyon 0.42 — Türkiye lower-league naming refresh
-- Keep Türkiye L1 untouched. Rename only L2-L5 using stable club IDs so
-- fixtures, historical results, stats and ratings remain attached to clubs.

with names(id,new_name) as (
  values
    ('C|Türkiye|L2|T0','Çukurova Akın'),
    ('C|Türkiye|L2|T1','Başkent Demirspor'),
    ('C|Türkiye|L2|T2','İzmir Kordon'),
    ('C|Türkiye|L2|T3','Bursa Uludağ'),
    ('C|Türkiye|L2|T4','Konya Selçuklu'),
    ('C|Türkiye|L2|T5','Mersin Akdeniz'),
    ('C|Türkiye|L2|T6','Trabzon Zigana'),
    ('C|Türkiye|L2|T7','Eskişehir Porsuk'),
    ('C|Türkiye|L2|T8','Antalya Kaleiçi'),
    ('C|Türkiye|L2|T9','Samsun Atakum'),
    ('C|Türkiye|L2|T10','Kayseri Erciyes'),
    ('C|Türkiye|L2|T11','Gaziantep Zeugma'),
    ('C|Türkiye|L2|T12','Sakarya Nehirspor'),
    ('C|Türkiye|L2|T13','Kocaeli Sanayi'),
    ('C|Türkiye|L2|T14','Manisa Spil'),
    ('C|Türkiye|L2|T15','Denizli Horozları'),
    ('C|Türkiye|L2|T16','Balıkesir Kuvayi'),
    ('C|Türkiye|L2|T17','Malatya Battalgazi'),

    ('C|Türkiye|L3|T0','Van Gölüspor'),
    ('C|Türkiye|L3|T1','Iğdır Aras'),
    ('C|Türkiye|L3|T2','Mardin Mezopotamya'),
    ('C|Türkiye|L3|T3','Batman Petrolkent'),
    ('C|Türkiye|L3|T4','Bandırma Liman'),
    ('C|Türkiye|L3|T5','Bolu Köroğlu'),
    ('C|Türkiye|L3|T6','Sivas Kangal Gücü'),
    ('C|Türkiye|L3|T7','Pendik Sahil'),
    ('C|Türkiye|L3|T8','Sarıyer Boğazspor'),
    ('C|Türkiye|L3|T9','Muğla Zeybek'),
    ('C|Türkiye|L3|T10','Çorum Hitit'),
    ('C|Türkiye|L3|T11','Düzce Melen'),
    ('C|Türkiye|L3|T12','Kırklareli Trakya'),
    ('C|Türkiye|L3|T13','Kastamonu Ilgaz'),
    ('C|Türkiye|L3|T14','Aksaray Hasan Dağı'),
    ('C|Türkiye|L3|T15','Karaman Karamanoğlu'),
    ('C|Türkiye|L3|T16','Afyon Kocatepe'),
    ('C|Türkiye|L3|T17','Şanlıurfa Harran'),

    ('C|Türkiye|L4|T0','Kozan Anavarza'),
    ('C|Türkiye|L4|T1','Keçiören Başkent'),
    ('C|Türkiye|L4|T2','Bornova Çınar'),
    ('C|Türkiye|L4|T3','İnegöl Mobilyacılar'),
    ('C|Türkiye|L4|T4','Akşehir Nasreddin'),
    ('C|Türkiye|L4|T5','Tarsus Berdan'),
    ('C|Türkiye|L4|T6','Akçaabat Yelken'),
    ('C|Türkiye|L4|T7','Sivrihisar Bozkır'),
    ('C|Türkiye|L4|T8','Kumluca Narenciye'),
    ('C|Türkiye|L4|T9','Bafra Kızılırmak'),
    ('C|Türkiye|L4|T10','Develi Erciyes'),
    ('C|Türkiye|L4|T11','Nizip Zeytinspor'),
    ('C|Türkiye|L4|T12','Hendek Gücü'),
    ('C|Türkiye|L4|T13','Gebze Fabrika'),
    ('C|Türkiye|L4|T14','Akhisar Zeytin'),
    ('C|Türkiye|L4|T15','Acıpayam Ovalılar'),
    ('C|Türkiye|L4|T16','Edremit Körfez'),
    ('C|Türkiye|L4|T17','Darende Somuncu'),

    ('C|Türkiye|L5|T0','Atlasspor'),
    ('C|Türkiye|L5|T1','Ecekuş SK'),
    ('C|Türkiye|L5|T2','Can Akademi FK'),
    ('C|Türkiye|L5|T3','Dayılar Köyspor'),
    ('C|Türkiye|L5|T4','Mirzaçelebi Gücü'),
    ('C|Türkiye|L5|T5','Fevzipaşaspor'),
    ('C|Türkiye|L5|T6','Gökçeada Rüzgâr'),
    ('C|Türkiye|L5|T7','Taşköprü Sarımsakspor'),
    ('C|Türkiye|L5|T8','Finike Portakal'),
    ('C|Türkiye|L5|T9','Şarköy Bağcılar'),
    ('C|Türkiye|L5|T10','Divriği Demir'),
    ('C|Türkiye|L5|T11','Akçakoca Dalgaspor'),
    ('C|Türkiye|L5|T12','Eğirdir Gölspor'),
    ('C|Türkiye|L5|T13','Halfeti Fırat'),
    ('C|Türkiye|L5|T14','Tire Ovaspor'),
    ('C|Türkiye|L5|T15','Bor Madenciler'),
    ('C|Türkiye|L5|T16','Göynük Safran'),
    ('C|Türkiye|L5|T17','Vize Ormanspor')
)
update public.clubs c
set name=n.new_name
from names n
where c.id=n.id
  and c.country='Türkiye'
  and c.league_level between 2 and 5;

do $$
declare
  v_count integer;
begin
  select count(*) into v_count
  from public.clubs
  where country='Türkiye' and league_level between 2 and 5;

  if v_count<>72 then
    raise exception 'Türkiye lower-league club count mismatch: %',v_count;
  end if;

  if exists(
    select 1
    from public.clubs
    where country='Türkiye' and league_level=1
      and name not in (
        'Galata Aslanları','Kadıköy Feneri','Boğaziçi Kartalları','Karadeniz Fırtınası',
        'Başakşehir Birlik','İzmir Körfez','Samsun Kızıl Liman','Rize Çay Birliği',
        'Konya Bozkır','Kocaeli Körfez','Alanya Sahil','Gaziantep Fıstıkspor',
        'Ankara Gençlik','Kasımpaşa Tersane','Eyüp Haliç','Diyarbakır Surlar',
        'Erzurum Ayaz','Çorum Leblebi'
      )
  ) then
    raise exception 'Türkiye L1 unexpectedly changed';
  end if;
end;
$$;
