-- Project Afyon 0.43 — Türkiye club suffix polish
-- Adds natural football-club suffixes to Türkiye L2-L5 names.
-- Stable IDs preserve fixtures, ratings, results and historical statistics.

with names(id,new_name) as (
  values
    ('C|Türkiye|L2|T0','Çukurova Akın SK'),
    ('C|Türkiye|L2|T1','Başkent Demirspor'),
    ('C|Türkiye|L2|T2','İzmir Kordon FK'),
    ('C|Türkiye|L2|T3','Bursa Uludağspor'),
    ('C|Türkiye|L2|T4','Konya Selçuklu FK'),
    ('C|Türkiye|L2|T5','Mersin Akdenizspor'),
    ('C|Türkiye|L2|T6','Trabzon Zigana SK'),
    ('C|Türkiye|L2|T7','Eskişehir Porsukspor'),
    ('C|Türkiye|L2|T8','Antalya Kaleiçi FK'),
    ('C|Türkiye|L2|T9','Samsun Atakum FK'),
    ('C|Türkiye|L2|T10','Kayseri Erciyes FK'),
    ('C|Türkiye|L2|T11','Gaziantep Zeugma SK'),
    ('C|Türkiye|L2|T12','Sakarya Nehirspor'),
    ('C|Türkiye|L2|T13','Kocaeli Sanayi FK'),
    ('C|Türkiye|L2|T14','Manisa Spilspor'),
    ('C|Türkiye|L2|T15','Denizli Horozları SK'),
    ('C|Türkiye|L2|T16','Balıkesir Kuvayi FK'),
    ('C|Türkiye|L2|T17','Malatya Battalgazi SK'),

    ('C|Türkiye|L3|T0','Van Gölüspor'),
    ('C|Türkiye|L3|T1','Iğdır Aras FK'),
    ('C|Türkiye|L3|T2','Mardin Mezopotamya SK'),
    ('C|Türkiye|L3|T3','Batman Petrolkent FK'),
    ('C|Türkiye|L3|T4','Bandırma Limanspor'),
    ('C|Türkiye|L3|T5','Bolu Köroğlu SK'),
    ('C|Türkiye|L3|T6','Sivas Kangal Gücü'),
    ('C|Türkiye|L3|T7','Pendik Sahil FK'),
    ('C|Türkiye|L3|T8','Sarıyer Boğazspor'),
    ('C|Türkiye|L3|T9','Muğla Zeybek SK'),
    ('C|Türkiye|L3|T10','Çorum Hitit FK'),
    ('C|Türkiye|L3|T11','Düzce Melen SK'),
    ('C|Türkiye|L3|T12','Kırklareli Trakya FK'),
    ('C|Türkiye|L3|T13','Kastamonu Ilgazspor'),
    ('C|Türkiye|L3|T14','Aksaray Hasan Dağı SK'),
    ('C|Türkiye|L3|T15','Karaman Karamanoğlu FK'),
    ('C|Türkiye|L3|T16','Afyon Kocatepe SK'),
    ('C|Türkiye|L3|T17','Şanlıurfa Harran FK'),

    ('C|Türkiye|L4|T0','Kozan Anavarza SK'),
    ('C|Türkiye|L4|T1','Keçiören Başkent FK'),
    ('C|Türkiye|L4|T2','Bornova Çınarspor'),
    ('C|Türkiye|L4|T3','İnegöl Mobilyacılar SK'),
    ('C|Türkiye|L4|T4','Akşehir Nasreddin FK'),
    ('C|Türkiye|L4|T5','Tarsus Berdan SK'),
    ('C|Türkiye|L4|T6','Akçaabat Yelken FK'),
    ('C|Türkiye|L4|T7','Sivrihisar Bozkırspor'),
    ('C|Türkiye|L4|T8','Kumluca Narenciye SK'),
    ('C|Türkiye|L4|T9','Bafra Kızılırmak FK'),
    ('C|Türkiye|L4|T10','Develi Erciyes SK'),
    ('C|Türkiye|L4|T11','Nizip Zeytinspor'),
    ('C|Türkiye|L4|T12','Hendek Gücü'),
    ('C|Türkiye|L4|T13','Gebze Fabrika FK'),
    ('C|Türkiye|L4|T14','Akhisar Zeytin SK'),
    ('C|Türkiye|L4|T15','Acıpayam Ovalılar FK'),
    ('C|Türkiye|L4|T16','Edremit Körfezspor'),
    ('C|Türkiye|L4|T17','Darende Somuncu SK'),

    ('C|Türkiye|L5|T0','Atlasspor'),
    ('C|Türkiye|L5|T1','Ecekuş SK'),
    ('C|Türkiye|L5|T2','Can Akademi FK'),
    ('C|Türkiye|L5|T3','Dayılar Köyspor'),
    ('C|Türkiye|L5|T4','Mirzaçelebi Gücü'),
    ('C|Türkiye|L5|T5','Fevzipaşaspor'),
    ('C|Türkiye|L5|T6','Gökçeada Rüzgâr SK'),
    ('C|Türkiye|L5|T7','Taşköprü Sarımsakspor'),
    ('C|Türkiye|L5|T8','Finike Portakalspor'),
    ('C|Türkiye|L5|T9','Şarköy Bağcılar FK'),
    ('C|Türkiye|L5|T10','Divriği Demirspor'),
    ('C|Türkiye|L5|T11','Akçakoca Dalgaspor'),
    ('C|Türkiye|L5|T12','Eğirdir Gölspor'),
    ('C|Türkiye|L5|T13','Halfeti Fırat FK'),
    ('C|Türkiye|L5|T14','Tire Ovaspor'),
    ('C|Türkiye|L5|T15','Bor Madenciler SK'),
    ('C|Türkiye|L5|T16','Göynük Safranspor'),
    ('C|Türkiye|L5|T17','Vize Ormanspor')
)
update public.clubs c
set name=n.new_name
from names n
where c.id=n.id
  and c.country='Türkiye'
  and c.league_level between 2 and 5;
