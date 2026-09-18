-- Applied Supabase migration: turkiye_crown_2026_27_parody_rosters

-- Project Afyon 0.26 — Türkiye Crown 2026/27 parody rosters
-- Current 2026/27 Turkish top-flight squad identities are mirrored as fictional parody players.

create table if not exists private.player_source_map(
  player_id text primary key references public.players(id) on delete cascade,
  source_team text not null,
  source_player text not null,
  source_season text not null,
  created_at timestamptz not null default now()
);

delete from public.players p
using public.clubs c
where p.club_id=c.id and c.country='Türkiye' and c.league_level=1;


do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Galata Aslanları';
  if not found then raise exception 'Club not found: Galata Aslanları'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Uğurcan Çakıro','GK','Türkiye',26,87,88,
      71,69,94,0,3,264915,92190420,
      63,84,71,73,86,87,95,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Günay Güvenço','GK','Türkiye',33,87,87,
      66,80,98,0,4,264915,92190420,
      65,81,68,75,88,88,97,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Abdülkerim Bardakcıo','DEF','Türkiye',25,86,87,
      61,65,91,0,5,258860,89047840,
      77,87,82,95,85,89,53,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'El Chadaille Bitshiabuo','DEF','Türkiye',32,87,87,
      56,76,95,0,2,264915,92190420,
      80,90,80,93,88,91,56,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Eren Elmalıo','DEF','Türkiye',24,88,91,
      72,61,99,0,3,271040,95406080,
      78,88,83,96,91,93,54,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Wilfried Singov','DEF','Türkiye',31,84,84,
      67,72,92,0,4,246960,82978560,
      76,86,81,89,84,87,52,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Ismail Jakobso','DEF','Türkiye',23,85,88,
      62,83,96,0,5,252875,85977500,
      79,84,79,92,87,89,55,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Davinson Sanchezz','DEF','Türkiye',30,86,86,
      57,68,100,0,2,258860,89047840,
      77,87,82,95,85,91,53,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Roland Sallaio','DEF','Türkiye',22,87,90,
      73,79,93,0,3,264915,92190420,
      80,90,80,93,88,90,56,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'İlkay Gündoğam','MID','Türkiye',29,87,87,
      68,64,97,0,4,264915,92190420,
      86,92,91,89,89,87,53,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Renato Nhago','MID','Türkiye',21,87,92,
      63,75,90,0,5,264915,92190420,
      88,94,93,86,86,88,55,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Aleksey Batrakovo','MID','Türkiye',28,87,87,
      58,60,94,0,2,264915,92190420,
      90,91,90,88,88,86,57,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Mario Lemino','MID','Türkiye',20,87,92,
      74,71,98,0,3,264915,92190420,
      87,93,92,90,85,87,54,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Lesley Ugochukwuo','MID','Türkiye',27,87,88,
      69,82,91,0,4,264915,92190420,
      89,95,89,87,87,88,56,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Lucas Torreiro','MID','Türkiye',19,88,93,
      64,67,95,0,5,271040,95406080,
      87,93,92,90,90,87,54,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Gabriel Saro','MID','Türkiye',26,84,85,
      59,78,99,0,2,246960,82978560,
      85,91,90,83,83,84,52,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Deniz Gülo','FWD','Türkiye',33,88,88,
      75,63,92,0,3,271040,95406080,
      97,87,91,80,93,91,58,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Victy Osimha','FWD','Türkiye',25,88,89,
      70,74,96,0,4,271040,95406080,
      94,89,93,82,90,89,55,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Baris Alper Yelmazo','FWD','Türkiye',32,88,88,
      65,59,100,0,5,271040,95406080,
      96,91,90,79,92,90,57,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Rafa Leaoo','FWD','Türkiye',24,88,91,
      60,70,93,0,2,271040,95406080,
      93,88,92,81,94,91,54,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Yunus Akgüno','FWD','Türkiye',31,84,84,
      55,81,97,0,3,246960,82978560,
      91,86,90,74,87,85,52,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Ada Yüzgeço','FWD','Türkiye',23,85,88,
      71,66,90,0,4,252875,85977500,
      94,84,88,77,90,87,55,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Galatasaray','Uğurcan Çakır','2026-27'),
('P|'||c.id||'|02','Galatasaray','Günay Güvenç','2026-27'),
('P|'||c.id||'|03','Galatasaray','Abdülkerim Bardakcı','2026-27'),
('P|'||c.id||'|04','Galatasaray','El Chadaille Bitshiabu','2026-27'),
('P|'||c.id||'|05','Galatasaray','Eren Elmalı','2026-27'),
('P|'||c.id||'|06','Galatasaray','Wilfried Singo','2026-27'),
('P|'||c.id||'|07','Galatasaray','Ismail Jakobs','2026-27'),
('P|'||c.id||'|08','Galatasaray','Davinson Sanchez','2026-27'),
('P|'||c.id||'|09','Galatasaray','Roland Sallai','2026-27'),
('P|'||c.id||'|10','Galatasaray','İlkay Gündoğan','2026-27'),
('P|'||c.id||'|11','Galatasaray','Renato Nhaga','2026-27'),
('P|'||c.id||'|12','Galatasaray','Aleksey Batrakov','2026-27'),
('P|'||c.id||'|13','Galatasaray','Mario Lemina','2026-27'),
('P|'||c.id||'|14','Galatasaray','Lesley Ugochukwu','2026-27'),
('P|'||c.id||'|15','Galatasaray','Lucas Torreira','2026-27'),
('P|'||c.id||'|16','Galatasaray','Gabriel Sara','2026-27'),
('P|'||c.id||'|17','Galatasaray','Deniz Gül','2026-27'),
('P|'||c.id||'|18','Galatasaray','Victor Osimhen','2026-27'),
('P|'||c.id||'|19','Galatasaray','Barış Alper Yılmaz','2026-27'),
('P|'||c.id||'|20','Galatasaray','Rafael Leao','2026-27'),
('P|'||c.id||'|21','Galatasaray','Yunus Akgün','2026-27'),
('P|'||c.id||'|22','Galatasaray','Ada Yüzgeç','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Kadıköy Feneri';
  if not found then raise exception 'Club not found: Kadıköy Feneri'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Nedersın','GK','Türkiye',29,85,85,
      61,70,92,0,4,252875,85977500,
      59,80,67,74,87,84,91,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Mert Günoko','GK','Türkiye',21,85,90,
      56,81,96,0,5,252875,85977500,
      61,82,69,71,84,85,93,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Yiğit Efe Demiro','DEF','Türkiye',28,85,85,
      72,66,100,0,2,252875,85977500,
      79,84,79,92,87,90,55,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Jayden Oosterwoldo','DEF','Türkiye',20,86,91,
      67,77,93,0,3,258860,89047840,
      77,87,82,95,85,89,53,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Kojo Oppongo','DEF','Türkiye',27,82,83,
      62,62,97,0,4,235340,77191520,
      75,85,75,88,83,86,51,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Archie Browno','DEF','Türkiye',19,83,88,
      57,73,90,0,5,241115,80050180,
      73,83,78,91,86,88,49,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Mert Müldüro','DEF','Türkiye',26,84,85,
      73,58,94,0,2,246960,82978560,
      76,86,81,89,84,87,52,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Nélson Semedov','DEF','Türkiye',33,85,85,
      68,69,98,0,3,252875,85977500,
      79,84,79,92,87,89,55,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Milan Skrinyar','DEF','Türkiye',25,86,87,
      63,80,91,0,4,258860,89047840,
      77,87,82,95,85,91,53,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Matteo Guendouzio','MID','Türkiye',32,85,85,
      58,65,95,0,5,252875,85977500,
      87,93,87,85,85,84,54,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'N''Golo Kanto','MID','Türkiye',24,85,88,
      74,76,99,0,2,252875,85977500,
      84,90,89,87,87,85,51,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'İrfan Can Kahvecio','MID','Türkiye',31,85,85,
      69,61,92,0,3,252875,85977500,
      86,92,91,84,84,86,53,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'İsmail Yükseko','MID','Türkiye',23,85,88,
      64,72,96,0,4,252875,85977500,
      88,89,88,86,86,84,55,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Mert Hakan Yandaşo','MID','Türkiye',30,86,86,
      59,83,100,0,5,258860,89047840,
      86,92,91,89,84,86,53,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Bartug Elmazo','MID','Türkiye',22,82,85,
      75,68,93,0,2,235340,77191520,
      84,90,84,82,82,83,51,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Mason Greenwud','FWD','Türkiye',29,86,86,
      70,79,97,0,3,258860,89047840,
      91,86,90,79,92,87,52,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Dorgeles Neno','FWD','Türkiye',21,86,91,
      65,64,90,0,4,258860,89047840,
      93,88,92,76,89,88,54,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Kerem Aktürkoğlo','FWD','Türkiye',28,86,86,
      60,75,94,0,5,258860,89047840,
      95,85,89,78,91,89,56,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Oğuz Aydıno','FWD','Türkiye',20,86,91,
      55,60,98,0,2,258860,89047840,
      92,87,91,80,88,87,53,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Vedat Muriqio','FWD','Türkiye',27,82,83,
      71,71,91,0,3,235340,77191520,
      90,85,84,73,86,84,51,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Marco Asensyo','FWD','Türkiye',19,83,88,
      66,82,95,0,4,241115,80050180,
      88,83,87,76,89,86,49,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Romelu Lukako','FWD','Türkiye',26,84,85,
      61,67,99,0,5,246960,82978560,
      91,86,90,74,87,85,52,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Fenerbahçe','Ederson','2026-27'),
('P|'||c.id||'|02','Fenerbahçe','Mert Günok','2026-27'),
('P|'||c.id||'|03','Fenerbahçe','Yiğit Efe Demir','2026-27'),
('P|'||c.id||'|04','Fenerbahçe','Jayden Oosterwolde','2026-27'),
('P|'||c.id||'|05','Fenerbahçe','Kojo Oppong','2026-27'),
('P|'||c.id||'|06','Fenerbahçe','Archie Brown','2026-27'),
('P|'||c.id||'|07','Fenerbahçe','Mert Müldür','2026-27'),
('P|'||c.id||'|08','Fenerbahçe','Nélson Semedo','2026-27'),
('P|'||c.id||'|09','Fenerbahçe','Milan Skriniar','2026-27'),
('P|'||c.id||'|10','Fenerbahçe','Matteo Guendouzi','2026-27'),
('P|'||c.id||'|11','Fenerbahçe','N''Golo Kante','2026-27'),
('P|'||c.id||'|12','Fenerbahçe','İrfan Can Kahveci','2026-27'),
('P|'||c.id||'|13','Fenerbahçe','İsmail Yüksek','2026-27'),
('P|'||c.id||'|14','Fenerbahçe','Mert Hakan Yandaş','2026-27'),
('P|'||c.id||'|15','Fenerbahçe','Bartug Elmaz','2026-27'),
('P|'||c.id||'|16','Fenerbahçe','Mason Greenwood','2026-27'),
('P|'||c.id||'|17','Fenerbahçe','Dorgeles Nene','2026-27'),
('P|'||c.id||'|18','Fenerbahçe','Kerem Aktürkoğlu','2026-27'),
('P|'||c.id||'|19','Fenerbahçe','Oğuz Aydın','2026-27'),
('P|'||c.id||'|20','Fenerbahçe','Vedat Muriqi','2026-27'),
('P|'||c.id||'|21','Fenerbahçe','Marco Asensio','2026-27'),
('P|'||c.id||'|22','Fenerbahçe','Romelu Lukaku','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Boğaziçi Kartalları';
  if not found then raise exception 'Club not found: Boğaziçi Kartalları'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Alex Nübelo','GK','Türkiye',32,82,82,
      72,71,90,0,5,235340,77191520,
      59,80,62,69,82,83,91,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Doğan Alemdaro','GK','Türkiye',24,82,85,
      67,82,94,0,2,235340,77191520,
      56,77,64,71,84,81,88,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Amir Murillov','DEF','Türkiye',31,83,83,
      62,67,98,0,3,241115,80050180,
      75,85,80,88,83,87,51,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Taylan Buluto','DEF','Türkiye',23,79,82,
      57,78,91,0,4,218435,69025460,
      73,78,73,86,81,84,49,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Yasin Özcano','DEF','Türkiye',30,80,80,
      73,63,95,0,5,224000,71680000,
      71,81,76,89,79,83,47,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Tiago Djalov','DEF','Türkiye',22,81,84,
      68,74,99,0,2,229635,74401740,
      74,84,74,87,82,85,50,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Emirhan Topçuo','DEF','Türkiye',29,82,82,
      63,59,92,0,3,235340,77191520,
      72,82,77,90,85,87,48,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Rıdvan Yılmazo','DEF','Türkiye',21,83,88,
      58,70,96,0,4,241115,80050180,
      75,85,80,88,83,86,51,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Emmanuel Agbadouo','DEF','Türkiye',28,79,79,
      74,81,100,0,5,218435,69025460,
      73,78,73,86,81,83,49,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Wilfred Ndidio','MID','Türkiye',20,82,87,
      69,66,93,0,2,235340,77191520,
      82,88,87,85,80,83,49,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Fabio Mirettio','MID','Türkiye',27,82,83,
      64,77,97,0,3,235340,77191520,
      84,90,84,82,82,81,51,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Kartal Kayra Yılmazo','MID','Türkiye',19,82,87,
      59,62,90,0,4,235340,77191520,
      81,87,86,84,84,82,48,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Orkun Kökçu','MID','Türkiye',26,82,83,
      75,73,94,0,5,235340,77191520,
      83,89,88,81,81,83,50,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Salih Özcano','MID','Türkiye',33,79,79,
      70,58,98,0,2,218435,69025460,
      82,83,82,80,80,78,49,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Milot Rashico','MID','Türkiye',25,80,81,
      65,69,91,0,3,224000,71680000,
      80,86,85,83,78,80,47,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Hyeon-Gyu Oho','FWD','Türkiye',32,83,83,
      60,80,95,0,4,241115,80050180,
      91,86,85,74,87,86,52,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Ernest Pokuo','FWD','Türkiye',24,83,86,
      55,65,99,0,5,241115,80050180,
      88,83,87,76,89,84,49,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Junior Olaitano','FWD','Türkiye',31,83,83,
      71,76,92,0,2,241115,80050180,
      90,85,89,73,86,85,51,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Dusan Vlahovik','FWD','Türkiye',23,83,86,
      66,61,96,0,3,241115,80050180,
      92,82,86,75,88,86,53,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Semih Kılıçsoyo','FWD','Türkiye',30,80,80,
      61,72,100,0,4,224000,71680000,
      86,81,85,74,82,81,47,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Vaclav Cernyo','FWD','Türkiye',22,81,84,
      56,83,93,0,5,229635,74401740,
      89,84,83,72,85,83,50,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Leandro Trossardo','FWD','Türkiye',29,82,82,
      72,68,97,0,2,235340,77191520,
      87,82,86,75,88,85,48,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Beşiktaş','Alexander Nübel','2026-27'),
('P|'||c.id||'|02','Beşiktaş','Doğan Alemdar','2026-27'),
('P|'||c.id||'|03','Beşiktaş','Amir Murillo','2026-27'),
('P|'||c.id||'|04','Beşiktaş','Taylan Bulut','2026-27'),
('P|'||c.id||'|05','Beşiktaş','Yasin Özcan','2026-27'),
('P|'||c.id||'|06','Beşiktaş','Tiago Djalo','2026-27'),
('P|'||c.id||'|07','Beşiktaş','Emirhan Topçu','2026-27'),
('P|'||c.id||'|08','Beşiktaş','Rıdvan Yılmaz','2026-27'),
('P|'||c.id||'|09','Beşiktaş','Emmanuel Agbadou','2026-27'),
('P|'||c.id||'|10','Beşiktaş','Wilfred Ndidi','2026-27'),
('P|'||c.id||'|11','Beşiktaş','Fabio Miretti','2026-27'),
('P|'||c.id||'|12','Beşiktaş','Kartal Kayra Yılmaz','2026-27'),
('P|'||c.id||'|13','Beşiktaş','Orkun Kökçü','2026-27'),
('P|'||c.id||'|14','Beşiktaş','Salih Özcan','2026-27'),
('P|'||c.id||'|15','Beşiktaş','Milot Rashica','2026-27'),
('P|'||c.id||'|16','Beşiktaş','Hyeon-Gyu Oh','2026-27'),
('P|'||c.id||'|17','Beşiktaş','Ernest Poku','2026-27'),
('P|'||c.id||'|18','Beşiktaş','Junior Olaitan','2026-27'),
('P|'||c.id||'|19','Beşiktaş','Dusan Vlahovic','2026-27'),
('P|'||c.id||'|20','Beşiktaş','Semih Kılıçsoy','2026-27'),
('P|'||c.id||'|21','Beşiktaş','Vaclav Cerny','2026-27'),
('P|'||c.id||'|22','Beşiktaş','Leandro Trossard','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Karadeniz Fırtınası';
  if not found then raise exception 'Club not found: Karadeniz Fırtınası'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Andre Onano','GK','Türkiye',20,80,85,
      62,72,99,0,2,224000,71680000,
      55,76,63,70,78,80,87,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Ahmet Doğan Yıldırımo','GK','Türkiye',27,80,81,
      57,83,92,0,3,224000,71680000,
      57,78,60,67,80,81,89,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Wagner Pino','DEF','Türkiye',19,77,82,
      73,68,96,0,4,207515,63914620,
      67,77,72,85,80,80,43,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Stefan Savico','DEF','Türkiye',26,78,79,
      68,79,100,0,5,212940,66437280,
      70,80,75,83,78,82,46,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Sidny Lopes Cabralo','DEF','Türkiye',33,79,79,
      63,64,93,0,2,218435,69025460,
      73,78,73,86,81,84,49,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Samet Akaydino','DEF','Türkiye',25,80,81,
      58,75,97,0,3,224000,71680000,
      71,81,76,89,79,83,47,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Arseniy Batagovo','DEF','Türkiye',32,81,81,
      74,60,90,0,4,229635,74401740,
      74,84,74,87,82,85,50,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Cenk Özkacaro','DEF','Türkiye',24,77,80,
      69,71,94,0,5,207515,63914620,
      67,77,72,85,80,82,43,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Mustafa Eskihellaco','MID','Türkiye',31,80,80,
      64,82,98,0,2,224000,71680000,
      81,87,86,79,79,79,48,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Chibuike Nwaiwuo','MID','Türkiye',23,80,83,
      59,67,91,0,3,224000,71680000,
      83,84,83,81,81,80,50,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Tim Jabol-Folcarellio','MID','Türkiye',30,80,80,
      75,78,95,0,4,224000,71680000,
      80,86,85,83,78,81,47,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Benjamin Bouchouario','MID','Türkiye',22,80,83,
      70,63,99,0,5,224000,71680000,
      82,88,82,80,80,79,49,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Batista Mendyo','MID','Türkiye',29,80,80,
      65,74,92,0,2,224000,71680000,
      79,85,84,82,82,80,46,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Ruslan Malinovskyo','MID','Türkiye',21,78,83,
      60,59,96,0,3,212940,66437280,
      79,85,84,77,77,79,46,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Fabinyo','MID','Türkiye',28,79,79,
      55,70,100,0,4,218435,69025460,
      82,83,82,80,80,78,49,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Franculinov','FWD','Türkiye',20,81,86,
      71,81,93,0,5,229635,74401740,
      87,82,86,75,83,83,48,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Cihan Çanako','FWD','Türkiye',27,81,82,
      66,66,97,0,2,229635,74401740,
      89,84,83,72,85,84,50,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Aral Şimşiro','FWD','Türkiye',19,81,86,
      61,77,90,0,3,229635,74401740,
      86,81,85,74,87,82,47,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Umut Nayiro','FWD','Türkiye',26,81,82,
      56,62,94,0,4,229635,74401740,
      88,83,87,71,84,83,49,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Metehan Mimaroğluo','FWD','Türkiye',33,79,79,
      72,73,98,0,5,218435,69025460,
      88,78,82,71,84,82,49,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Mohamet Salahh','FWD','Türkiye',25,80,81,
      67,58,91,0,2,224000,71680000,
      86,81,85,74,82,81,47,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Poyraz Efe Yıldırımo','FWD','Türkiye',32,81,81,
      62,69,95,0,3,229635,74401740,
      89,84,83,72,85,83,50,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Trabzonspor','Andre Onana','2026-27'),
('P|'||c.id||'|02','Trabzonspor','Ahmet Doğan Yıldırım','2026-27'),
('P|'||c.id||'|03','Trabzonspor','Wagner Pina','2026-27'),
('P|'||c.id||'|04','Trabzonspor','Stefan Savic','2026-27'),
('P|'||c.id||'|05','Trabzonspor','Sidny Lopes Cabral','2026-27'),
('P|'||c.id||'|06','Trabzonspor','Samet Akaydin','2026-27'),
('P|'||c.id||'|07','Trabzonspor','Arseniy Batagov','2026-27'),
('P|'||c.id||'|08','Trabzonspor','Cenk Özkacar','2026-27'),
('P|'||c.id||'|09','Trabzonspor','Mustafa Eskihellac','2026-27'),
('P|'||c.id||'|10','Trabzonspor','Chibuike Nwaiwu','2026-27'),
('P|'||c.id||'|11','Trabzonspor','Tim Jabol-Folcarelli','2026-27'),
('P|'||c.id||'|12','Trabzonspor','Benjamin Bouchouari','2026-27'),
('P|'||c.id||'|13','Trabzonspor','Batista Mendy','2026-27'),
('P|'||c.id||'|14','Trabzonspor','Ruslan Malinovsky','2026-27'),
('P|'||c.id||'|15','Trabzonspor','Fabinho','2026-27'),
('P|'||c.id||'|16','Trabzonspor','Franculino','2026-27'),
('P|'||c.id||'|17','Trabzonspor','Cihan Çanak','2026-27'),
('P|'||c.id||'|18','Trabzonspor','Aral Şimşir','2026-27'),
('P|'||c.id||'|19','Trabzonspor','Umut Nayir','2026-27'),
('P|'||c.id||'|20','Trabzonspor','Metehan Mimaroğlu','2026-27'),
('P|'||c.id||'|21','Trabzonspor','Mohamed Salah','2026-27'),
('P|'||c.id||'|22','Trabzonspor','Poyraz Efe Yıldırım','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Başakşehir Birlik';
  if not found then raise exception 'Club not found: Başakşehir Birlik'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Volkan Babacano','GK','Türkiye',23,78,81,
      73,73,97,0,3,212940,66437280,
      56,72,59,66,79,77,88,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Deniz Dilmeno','GK','Türkiye',30,78,78,
      68,58,90,0,4,212940,66437280,
      53,74,61,68,76,78,85,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Emin Bayramo','DEF','Türkiye',22,76,79,
      63,69,94,0,5,202160,61456640,
      69,79,69,82,77,81,45,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Ousseynou Bao','DEF','Türkiye',29,77,77,
      58,80,98,0,2,207515,63914620,
      67,77,72,85,80,80,43,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Christopher Operio','DEF','Türkiye',21,78,83,
      74,65,91,0,3,212940,66437280,
      70,80,75,83,78,82,46,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Francis Nzabo','DEF','Türkiye',28,79,79,
      69,76,95,0,4,218435,69025460,
      73,78,73,86,81,84,49,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Saba Kharebashvilio','DEF','Türkiye',20,75,80,
      64,61,99,0,5,196875,59062500,
      66,76,71,84,74,78,42,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Onur Buluto','DEF','Türkiye',27,76,77,
      59,72,92,0,2,202160,61456640,
      69,79,69,82,77,80,45,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Ömer Ali Şahinero','DEF','Türkiye',19,77,82,
      75,83,96,0,3,207515,63914620,
      67,77,72,85,80,82,43,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Abdoulaye Yorov','MID','Türkiye',26,78,79,
      70,68,100,0,4,212940,66437280,
      79,85,84,77,77,77,46,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Abbosbek Fayzullayevo','MID','Türkiye',33,78,78,
      65,79,93,0,5,212940,66437280,
      81,82,81,79,79,78,48,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Ivan Brnico','MID','Türkiye',25,78,79,
      60,64,97,0,2,212940,66437280,
      78,84,83,81,76,79,45,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Jakub Kaluzinskio','MID','Türkiye',32,78,78,
      55,75,90,0,3,212940,66437280,
      80,86,80,78,78,77,47,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Michal Karbowniko','MID','Türkiye',24,77,80,
      71,60,94,0,4,207515,63914620,
      76,82,81,79,79,77,43,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Umut Güneşo','MID','Türkiye',31,78,78,
      66,71,98,0,5,212940,66437280,
      79,85,84,77,77,79,46,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Berkay Özcano','MID','Türkiye',23,79,82,
      61,82,91,0,2,218435,69025460,
      82,83,82,80,80,78,49,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Yusuf Sarıo','FWD','Türkiye',30,79,79,
      56,67,95,0,3,218435,69025460,
      85,80,84,73,81,81,46,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Andreas Skov Olseno','FWD','Türkiye',22,79,82,
      72,78,99,0,4,218435,69025460,
      87,82,81,70,83,82,48,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Bertuğ Yıldırımo','FWD','Türkiye',29,79,79,
      67,63,92,0,5,218435,69025460,
      84,79,83,72,85,80,45,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Umut Bozoko','FWD','Türkiye',21,78,83,
      62,74,96,0,2,212940,66437280,
      85,80,84,68,81,80,46,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Eldor Shomurodo','FWD','Türkiye',28,79,79,
      57,59,100,0,3,218435,69025460,
      88,78,82,71,84,82,49,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Davie Selko','FWD','Türkiye',20,75,80,
      73,70,93,0,4,196875,59062500,
      81,76,80,69,77,76,42,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','İstanbul Başakşehir','Volkan Babacan','2026-27'),
('P|'||c.id||'|02','İstanbul Başakşehir','Deniz Dilmen','2026-27'),
('P|'||c.id||'|03','İstanbul Başakşehir','Emin Bayram','2026-27'),
('P|'||c.id||'|04','İstanbul Başakşehir','Ousseynou Ba','2026-27'),
('P|'||c.id||'|05','İstanbul Başakşehir','Christopher Operi','2026-27'),
('P|'||c.id||'|06','İstanbul Başakşehir','Francis Nzaba','2026-27'),
('P|'||c.id||'|07','İstanbul Başakşehir','Saba Kharebashvili','2026-27'),
('P|'||c.id||'|08','İstanbul Başakşehir','Onur Bulut','2026-27'),
('P|'||c.id||'|09','İstanbul Başakşehir','Ömer Ali Şahiner','2026-27'),
('P|'||c.id||'|10','İstanbul Başakşehir','Abdoulaye Yoro','2026-27'),
('P|'||c.id||'|11','İstanbul Başakşehir','Abbosbek Fayzullayev','2026-27'),
('P|'||c.id||'|12','İstanbul Başakşehir','Ivan Brnic','2026-27'),
('P|'||c.id||'|13','İstanbul Başakşehir','Jakub Kaluzinski','2026-27'),
('P|'||c.id||'|14','İstanbul Başakşehir','Michal Karbownik','2026-27'),
('P|'||c.id||'|15','İstanbul Başakşehir','Umut Güneş','2026-27'),
('P|'||c.id||'|16','İstanbul Başakşehir','Berkay Özcan','2026-27'),
('P|'||c.id||'|17','İstanbul Başakşehir','Yusuf Sarı','2026-27'),
('P|'||c.id||'|18','İstanbul Başakşehir','Andreas Skov Olsen','2026-27'),
('P|'||c.id||'|19','İstanbul Başakşehir','Bertuğ Yıldırım','2026-27'),
('P|'||c.id||'|20','İstanbul Başakşehir','Umut Bozok','2026-27'),
('P|'||c.id||'|21','İstanbul Başakşehir','Eldor Shomurodov','2026-27'),
('P|'||c.id||'|22','İstanbul Başakşehir','Davie Selke','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='İzmir Körfez';
  if not found then raise exception 'Club not found: İzmir Körfez'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Luka Gugeshashvilio','GK','Türkiye',26,77,78,
      63,74,95,0,4,207515,63914620,
      53,74,61,63,76,78,85,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Arda Özçimeno','GK','Türkiye',33,77,77,
      58,59,99,0,5,207515,63914620,
      55,71,58,65,78,76,87,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Ege Yıldırımo','DEF','Türkiye',25,76,77,
      74,70,92,0,2,202160,61456640,
      67,77,72,85,75,80,43,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Ogün Bayrako','DEF','Türkiye',32,77,77,
      69,81,96,0,3,207515,63914620,
      70,80,70,83,78,82,46,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Furkan Bayıro','DEF','Türkiye',24,78,81,
      64,66,100,0,4,212940,66437280,
      68,78,73,86,81,81,44,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Taha Altıkardeşo','DEF','Türkiye',31,74,74,
      59,77,93,0,5,191660,56731360,
      66,76,71,79,74,78,42,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Allan Godoio','DEF','Türkiye',23,75,78,
      75,62,97,0,2,196875,59062500,
      69,74,69,82,77,80,45,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Noah Sonko Sundbergo','DEF','Türkiye',30,76,76,
      70,73,90,0,3,202160,61456640,
      67,77,72,85,75,79,43,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Malcom Bokelo','DEF','Türkiye',22,77,80,
      65,58,94,0,4,207515,63914620,
      70,80,70,83,78,81,46,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Novatus Miroshio','MID','Türkiye',29,77,77,
      60,69,98,0,5,207515,63914620,
      76,82,81,79,79,78,43,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'İzzet Furkan Malako','MID','Türkiye',21,77,82,
      55,80,91,0,2,207515,63914620,
      78,84,83,76,76,76,45,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Alex Matoso','MID','Türkiye',28,77,77,
      71,65,95,0,3,207515,63914620,
      80,81,80,78,78,77,47,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Tino Anjorino','MID','Türkiye',20,77,82,
      66,76,99,0,4,207515,63914620,
      77,83,82,80,75,78,44,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Alexis Antuneso','MID','Türkiye',27,77,78,
      61,61,92,0,5,207515,63914620,
      79,85,79,77,77,76,46,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Arda Kurtulano','FWD','Türkiye',19,78,83,
      56,72,96,0,2,212940,66437280,
      83,78,82,71,84,80,44,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Juano','FWD','Türkiye',26,78,79,
      72,83,100,0,3,212940,66437280,
      85,80,84,68,81,81,46,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Sinclair Armstrongo','FWD','Türkiye',33,78,78,
      67,68,93,0,4,212940,66437280,
      87,77,81,70,83,79,48,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Gökdeniz Bayrakdaro','FWD','Türkiye',25,78,79,
      62,79,97,0,5,212940,66437280,
      84,79,83,72,80,80,45,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Richard Akonnoro','FWD','Türkiye',32,78,78,
      57,64,90,0,2,212940,66437280,
      86,81,80,69,82,81,47,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Jandersono','FWD','Türkiye',24,78,81,
      73,75,94,0,3,212940,66437280,
      83,78,82,71,84,79,44,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Ibrahim Sabro','FWD','Türkiye',31,74,74,
      68,60,98,0,4,191660,56731360,
      81,76,80,64,77,76,42,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Efkan Bekiroğluo','FWD','Türkiye',23,75,78,
      63,71,91,0,5,196875,59062500,
      84,74,78,67,80,78,45,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Göztepe','Luka Gugeshashvili','2026-27'),
('P|'||c.id||'|02','Göztepe','Arda Özçimen','2026-27'),
('P|'||c.id||'|03','Göztepe','Ege Yıldırım','2026-27'),
('P|'||c.id||'|04','Göztepe','Ogün Bayrak','2026-27'),
('P|'||c.id||'|05','Göztepe','Furkan Bayır','2026-27'),
('P|'||c.id||'|06','Göztepe','Taha Altıkardeş','2026-27'),
('P|'||c.id||'|07','Göztepe','Allan Godoi','2026-27'),
('P|'||c.id||'|08','Göztepe','Noah Sonko Sundberg','2026-27'),
('P|'||c.id||'|09','Göztepe','Malcom Bokele','2026-27'),
('P|'||c.id||'|10','Göztepe','Novatus Miroshi','2026-27'),
('P|'||c.id||'|11','Göztepe','İzzet Furkan Malak','2026-27'),
('P|'||c.id||'|12','Göztepe','Alex Matos','2026-27'),
('P|'||c.id||'|13','Göztepe','Tino Anjorin','2026-27'),
('P|'||c.id||'|14','Göztepe','Alexis Antunes','2026-27'),
('P|'||c.id||'|15','Göztepe','Arda Kurtulan','2026-27'),
('P|'||c.id||'|16','Göztepe','Juan','2026-27'),
('P|'||c.id||'|17','Göztepe','Sinclair Armstrong','2026-27'),
('P|'||c.id||'|18','Göztepe','Gökdeniz Bayrakdar','2026-27'),
('P|'||c.id||'|19','Göztepe','Richard Akonnor','2026-27'),
('P|'||c.id||'|20','Göztepe','Janderson','2026-27'),
('P|'||c.id||'|21','Göztepe','Ibrahim Sabra','2026-27'),
('P|'||c.id||'|22','Göztepe','Efkan Bekiroğlu','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Samsun Kızıl Liman';
  if not found then raise exception 'Club not found: Samsun Kızıl Liman'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Okan Kocuko','GK','Türkiye',29,76,76,
      74,75,93,0,5,202160,61456640,
      50,71,58,65,78,76,82,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Bilal Bayazito','GK','Türkiye',21,76,81,
      69,60,97,0,2,202160,61456640,
      52,73,60,62,75,77,84,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Strahinja Erakovico','DEF','Türkiye',28,76,76,
      64,71,90,0,3,202160,61456640,
      70,75,70,83,78,79,46,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Bedirhan Çetino','DEF','Türkiye',20,77,82,
      59,82,94,0,4,207515,63914620,
      68,78,73,86,76,81,44,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Gabriele Guarinov','DEF','Türkiye',27,73,74,
      75,67,98,0,5,186515,54462380,
      66,76,66,79,74,78,42,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Josafat Mendeso','DEF','Türkiye',19,74,79,
      70,78,91,0,2,191660,56731360,
      64,74,69,82,77,77,40,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Igor Drapinskio','DEF','Türkiye',26,75,76,
      65,63,95,0,3,196875,59062500,
      67,77,72,80,75,79,43,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Toni Borevkovico','DEF','Türkiye',33,76,76,
      60,74,99,0,4,202160,61456640,
      70,75,70,83,78,81,46,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Logi Tomassono','DEF','Türkiye',25,77,78,
      55,59,92,0,5,207515,63914620,
      68,78,73,86,76,80,44,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Samed Onuro','MID','Türkiye',32,76,76,
      71,70,96,0,2,202160,61456640,
      78,84,78,76,76,76,45,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Afonso Souso','MID','Türkiye',24,76,79,
      66,81,100,0,3,202160,61456640,
      75,81,80,78,78,77,42,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Yunus Emre Çifto','MID','Türkiye',31,76,76,
      61,66,93,0,4,202160,61456640,
      77,83,82,75,75,75,44,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Elliot Watto','MID','Türkiye',23,76,79,
      56,77,97,0,5,202160,61456640,
      79,80,79,77,77,76,46,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Oskar Oehlenschlaegero','MID','Türkiye',30,77,77,
      72,62,90,0,2,207515,63914620,
      77,83,82,80,75,78,44,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Yalçın Kayano','MID','Türkiye',22,73,76,
      67,73,94,0,3,186515,54462380,
      75,81,75,73,73,72,42,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Celil Yükselo','MID','Türkiye',29,74,74,
      62,58,98,0,4,191660,56731360,
      73,79,78,76,76,74,40,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Tanguy Coulibalyo','FWD','Türkiye',21,77,82,
      57,69,91,0,5,207515,63914620,
      84,79,83,67,80,80,45,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Elayis Tavsano','FWD','Türkiye',28,77,77,
      73,80,95,0,2,207515,63914620,
      86,76,80,69,82,78,47,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Fatih Kayo','FWD','Türkiye',20,77,82,
      68,65,99,0,3,207515,63914620,
      83,78,82,71,79,79,44,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Mohamed Bayov','FWD','Türkiye',27,73,74,
      63,76,92,0,4,186515,54462380,
      81,76,75,64,77,76,42,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Emre Kılınço','FWD','Türkiye',19,74,79,
      58,61,96,0,5,191660,56731360,
      79,74,78,67,80,75,40,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Jaures Assoumouo','FWD','Türkiye',26,75,76,
      74,72,100,0,2,196875,59062500,
      82,77,81,65,78,77,43,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Samsunspor','Okan Kocuk','2026-27'),
('P|'||c.id||'|02','Samsunspor','Bilal Bayazit','2026-27'),
('P|'||c.id||'|03','Samsunspor','Strahinja Erakovic','2026-27'),
('P|'||c.id||'|04','Samsunspor','Bedirhan Çetin','2026-27'),
('P|'||c.id||'|05','Samsunspor','Gabriele Guarino','2026-27'),
('P|'||c.id||'|06','Samsunspor','Josafat Mendes','2026-27'),
('P|'||c.id||'|07','Samsunspor','Igor Drapinski','2026-27'),
('P|'||c.id||'|08','Samsunspor','Toni Borevkovic','2026-27'),
('P|'||c.id||'|09','Samsunspor','Logi Tomasson','2026-27'),
('P|'||c.id||'|10','Samsunspor','Samed Onur','2026-27'),
('P|'||c.id||'|11','Samsunspor','Afonso Sousa','2026-27'),
('P|'||c.id||'|12','Samsunspor','Yunus Emre Çift','2026-27'),
('P|'||c.id||'|13','Samsunspor','Elliot Watt','2026-27'),
('P|'||c.id||'|14','Samsunspor','Oskar Oehlenschlaeger','2026-27'),
('P|'||c.id||'|15','Samsunspor','Yalçın Kayan','2026-27'),
('P|'||c.id||'|16','Samsunspor','Celil Yüksel','2026-27'),
('P|'||c.id||'|17','Samsunspor','Tanguy Coulibaly','2026-27'),
('P|'||c.id||'|18','Samsunspor','Elayis Tavsan','2026-27'),
('P|'||c.id||'|19','Samsunspor','Fatih Kaya','2026-27'),
('P|'||c.id||'|20','Samsunspor','Mohamed Bayo','2026-27'),
('P|'||c.id||'|21','Samsunspor','Emre Kılınç','2026-27'),
('P|'||c.id||'|22','Samsunspor','Jaures Assoumou','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Rize Çay Birliği';
  if not found then raise exception 'Club not found: Rize Çay Birliği'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Yahia Fofano','GK','Türkiye',32,72,72,
      64,76,91,0,2,181440,52254720,
      49,70,52,59,72,71,81,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Erdem Canpolato','GK','Türkiye',24,72,75,
      59,61,95,0,3,181440,52254720,
      46,67,54,61,74,72,78,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Anıl Yaşaro','DEF','Türkiye',31,73,73,
      75,72,99,0,4,186515,54462380,
      65,75,70,78,73,78,41,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Khusniddin Alikulovo','DEF','Türkiye',23,69,72,
      70,83,92,0,5,166635,45991260,
      63,68,63,76,71,72,39,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Taha Şahino','DEF','Türkiye',30,70,70,
      65,68,96,0,2,171500,48020000,
      61,71,66,79,69,74,37,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Moussa Diakito','DEF','Türkiye',22,71,74,
      60,79,100,0,3,176435,50107540,
      64,74,64,77,72,76,40,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Umut Erdemo','DEF','Türkiye',29,72,72,
      55,64,93,0,4,181440,52254720,
      62,72,67,80,75,75,38,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Modibo Sagnano','DEF','Türkiye',21,73,78,
      71,75,97,0,5,186515,54462380,
      65,75,70,78,73,77,41,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Attila Mocsio','DEF','Türkiye',28,69,69,
      66,60,90,0,2,166635,45991260,
      63,68,63,76,71,74,39,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Siaka Bakayokov','DEF','Türkiye',20,70,75,
      61,71,94,0,3,171500,48020000,
      61,71,66,79,69,73,37,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Tayyip Talha Sanuço','DEF','Türkiye',27,71,72,
      56,82,98,0,4,176435,50107540,
      64,74,64,77,72,75,40,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Zakaria Arisso','DEF','Türkiye',19,72,77,
      72,67,91,0,5,181440,52254720,
      62,72,67,80,75,77,38,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Emirhan Yılmazo','MID','Türkiye',26,72,73,
      67,78,95,0,2,181440,52254720,
      73,79,78,71,71,71,40,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Taylan Antalyalıo','MID','Türkiye',33,69,69,
      62,63,99,0,3,166635,45991260,
      72,73,72,70,70,69,39,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Dal Varesanovico','MID','Türkiye',25,70,71,
      57,74,92,0,4,171500,48020000,
      70,76,75,73,68,71,37,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Ibrahim Olawoyino','MID','Türkiye',32,71,71,
      73,59,96,0,5,176435,50107540,
      73,79,73,71,71,70,40,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Can Bozdoğano','MID','Türkiye',24,72,75,
      68,70,100,0,2,181440,52254720,
      71,77,76,74,74,72,38,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Qazim Lacio','MID','Türkiye',31,73,73,
      63,81,93,0,3,186515,54462380,
      74,80,79,72,72,74,41,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Adedire Mebudo','FWD','Türkiye',23,73,76,
      58,66,97,0,4,186515,54462380,
      82,72,76,65,78,74,43,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Emrecan Buluto','FWD','Türkiye',30,70,70,
      74,77,90,0,5,171500,48020000,
      76,71,75,64,72,72,37,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Gennaro Borrellio','FWD','Türkiye',22,71,74,
      69,62,94,0,2,176435,50107540,
      79,74,73,62,75,74,40,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Iustin Doicaruo','FWD','Türkiye',29,72,72,
      64,73,98,0,3,181440,52254720,
      77,72,76,65,78,73,38,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Çaykur Rizespor','Yahia Fofana','2026-27'),
('P|'||c.id||'|02','Çaykur Rizespor','Erdem Canpolat','2026-27'),
('P|'||c.id||'|03','Çaykur Rizespor','Anıl Yaşar','2026-27'),
('P|'||c.id||'|04','Çaykur Rizespor','Khusniddin Alikulov','2026-27'),
('P|'||c.id||'|05','Çaykur Rizespor','Taha Şahin','2026-27'),
('P|'||c.id||'|06','Çaykur Rizespor','Moussa Diakite','2026-27'),
('P|'||c.id||'|07','Çaykur Rizespor','Umut Erdem','2026-27'),
('P|'||c.id||'|08','Çaykur Rizespor','Modibo Sagnan','2026-27'),
('P|'||c.id||'|09','Çaykur Rizespor','Attila Mocsi','2026-27'),
('P|'||c.id||'|10','Çaykur Rizespor','Siaka Bakayoko','2026-27'),
('P|'||c.id||'|11','Çaykur Rizespor','Tayyip Talha Sanuç','2026-27'),
('P|'||c.id||'|12','Çaykur Rizespor','Zakaria Ariss','2026-27'),
('P|'||c.id||'|13','Çaykur Rizespor','Emirhan Yılmaz','2026-27'),
('P|'||c.id||'|14','Çaykur Rizespor','Taylan Antalyalı','2026-27'),
('P|'||c.id||'|15','Çaykur Rizespor','Dal Varesanovic','2026-27'),
('P|'||c.id||'|16','Çaykur Rizespor','Ibrahim Olawoyin','2026-27'),
('P|'||c.id||'|17','Çaykur Rizespor','Can Bozdoğan','2026-27'),
('P|'||c.id||'|18','Çaykur Rizespor','Qazim Laci','2026-27'),
('P|'||c.id||'|19','Çaykur Rizespor','Adedire Mebude','2026-27'),
('P|'||c.id||'|20','Çaykur Rizespor','Emrecan Bulut','2026-27'),
('P|'||c.id||'|21','Çaykur Rizespor','Gennaro Borrelli','2026-27'),
('P|'||c.id||'|22','Çaykur Rizespor','Iustin Doicaru','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Konya Bozkır';
  if not found then raise exception 'Club not found: Konya Bozkır'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Egemen Aydıno','GK','Türkiye',20,73,78,
      75,77,100,0,3,186515,54462380,
      48,69,56,63,71,74,80,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Deniz Ertaşo','GK','Türkiye',27,73,74,
      70,62,93,0,4,186515,54462380,
      50,71,53,60,73,72,82,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Arthur Masuakuo','DEF','Türkiye',19,70,75,
      65,73,97,0,5,171500,48020000,
      60,70,65,78,73,74,36,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Joao Pedro da Mato','DEF','Türkiye',26,71,72,
      60,58,90,0,2,176435,50107540,
      63,73,68,76,71,76,39,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Arif Boşluko','DEF','Türkiye',33,72,72,
      55,69,94,0,3,181440,52254720,
      66,71,66,79,74,75,42,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Rayyan Baniyo','DEF','Türkiye',25,73,74,
      71,80,98,0,4,186515,54462380,
      64,74,69,82,72,77,40,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Adil Demirbağo','DEF','Türkiye',32,74,74,
      66,65,91,0,5,191660,56731360,
      67,77,67,80,75,79,43,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Chidozie Awaziemo','DEF','Türkiye',24,70,73,
      61,76,95,0,2,171500,48020000,
      60,70,65,78,73,73,36,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Yhoan Andzouano','DEF','Türkiye',31,71,71,
      56,61,99,0,3,176435,50107540,
      63,73,68,76,71,75,39,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Deniz Türüço','MID','Türkiye',23,73,76,
      72,72,92,0,4,186515,54462380,
      76,77,76,74,74,74,43,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Uğurcan Yazğılıo','MID','Türkiye',30,73,73,
      67,83,96,0,5,186515,54462380,
      73,79,78,76,71,72,40,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Marko Jevtovico','MID','Türkiye',22,73,76,
      62,68,100,0,2,186515,54462380,
      75,81,75,73,73,73,42,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Ebrima Colleyo','MID','Türkiye',29,73,73,
      57,79,93,0,3,186515,54462380,
      72,78,77,75,75,74,39,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Melih İbrahimoğluo','MID','Türkiye',21,71,76,
      73,64,97,0,4,176435,50107540,
      72,78,77,70,70,70,39,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Enis Bardhio','MID','Türkiye',28,72,72,
      68,75,90,0,5,181440,52254720,
      75,76,75,73,73,72,42,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Jin-Ho Joo','MID','Türkiye',20,73,78,
      63,60,94,0,2,186515,54462380,
      73,79,78,76,71,74,40,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Jean-Luc Dompo','FWD','Türkiye',27,74,75,
      58,71,98,0,3,191660,56731360,
      82,77,76,65,78,75,43,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Diogo Goncalveso','FWD','Türkiye',19,74,79,
      74,82,91,0,4,191660,56731360,
      79,74,78,67,80,76,40,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Enis Destano','FWD','Türkiye',26,74,75,
      69,67,95,0,5,191660,56731360,
      81,76,80,64,77,77,42,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Kazeem Olaigbo','FWD','Türkiye',33,72,72,
      64,78,99,0,2,181440,52254720,
      81,71,75,64,77,73,42,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Jackson Muleko','FWD','Türkiye',25,73,74,
      59,63,92,0,3,186515,54462380,
      79,74,78,67,75,75,40,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Mustafa Muhammedo','FWD','Türkiye',32,74,74,
      75,74,96,0,4,191660,56731360,
      82,77,76,65,78,77,43,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Konyaspor','Egemen Aydın','2026-27'),
('P|'||c.id||'|02','Konyaspor','Deniz Ertaş','2026-27'),
('P|'||c.id||'|03','Konyaspor','Arthur Masuaku','2026-27'),
('P|'||c.id||'|04','Konyaspor','Joao Pedro da Mata','2026-27'),
('P|'||c.id||'|05','Konyaspor','Arif Boşluk','2026-27'),
('P|'||c.id||'|06','Konyaspor','Rayyan Baniya','2026-27'),
('P|'||c.id||'|07','Konyaspor','Adil Demirbağ','2026-27'),
('P|'||c.id||'|08','Konyaspor','Chidozie Awaziem','2026-27'),
('P|'||c.id||'|09','Konyaspor','Yhoan Andzouana','2026-27'),
('P|'||c.id||'|10','Konyaspor','Deniz Türüç','2026-27'),
('P|'||c.id||'|11','Konyaspor','Uğurcan Yazğılı','2026-27'),
('P|'||c.id||'|12','Konyaspor','Marko Jevtovic','2026-27'),
('P|'||c.id||'|13','Konyaspor','Ebrima Colley','2026-27'),
('P|'||c.id||'|14','Konyaspor','Melih İbrahimoğlu','2026-27'),
('P|'||c.id||'|15','Konyaspor','Enis Bardhi','2026-27'),
('P|'||c.id||'|16','Konyaspor','Jin-Ho Jo','2026-27'),
('P|'||c.id||'|17','Konyaspor','Jean-Luc Dompe','2026-27'),
('P|'||c.id||'|18','Konyaspor','Diogo Goncalves','2026-27'),
('P|'||c.id||'|19','Konyaspor','Enis Destan','2026-27'),
('P|'||c.id||'|20','Konyaspor','Kazeem Olaigbe','2026-27'),
('P|'||c.id||'|21','Konyaspor','Jackson Muleka','2026-27'),
('P|'||c.id||'|22','Konyaspor','Mustafa Muhammed','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Kocaeli Körfez';
  if not found then raise exception 'Club not found: Kocaeli Körfez'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Onurcan Pirio','GK','Türkiye',23,75,78,
      65,78,98,0,4,196875,59062500,
      53,69,56,63,76,75,85,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Aleksandar Jovanovico','GK','Türkiye',30,75,75,
      60,63,91,0,5,196875,59062500,
      50,71,58,65,73,76,82,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Emir Ortakayo','DEF','Türkiye',22,73,76,
      55,74,95,0,2,186515,54462380,
      66,76,66,79,74,76,42,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Tanguy Zoukrouo','DEF','Türkiye',29,74,74,
      71,59,99,0,3,191660,56731360,
      64,74,69,82,77,78,40,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Matej Maglico','DEF','Türkiye',21,75,80,
      66,70,92,0,4,196875,59062500,
      67,77,72,80,75,80,43,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Massadio Haidaro','DEF','Türkiye',28,76,76,
      61,81,96,0,5,202160,61456640,
      70,75,70,83,78,79,46,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Muharrem Cinano','DEF','Türkiye',20,72,77,
      56,66,100,0,2,181440,52254720,
      63,73,68,81,71,76,39,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Anfernee Dijksteelo','DEF','Türkiye',27,73,74,
      72,77,93,0,3,186515,54462380,
      66,76,66,79,74,78,42,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Onur Öztongo','DEF','Türkiye',19,74,79,
      67,62,97,0,4,191660,56731360,
      64,74,69,82,77,77,40,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Tobias Gullikseno','MID','Türkiye',26,75,76,
      62,73,90,0,5,196875,59062500,
      76,82,81,74,74,75,43,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Showo','MID','Türkiye',33,75,75,
      57,58,94,0,2,196875,59062500,
      78,79,78,76,76,76,45,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Berkan Kutluo','MID','Türkiye',25,75,76,
      73,69,98,0,3,196875,59062500,
      75,81,80,78,73,74,42,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Rigoberto Rivaso','MID','Türkiye',32,75,75,
      68,80,91,0,4,196875,59062500,
      77,83,77,75,75,75,44,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Uğur Yıldızo','MID','Türkiye',24,74,77,
      63,65,95,0,5,191660,56731360,
      73,79,78,76,76,75,40,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Habib Keito','MID','Türkiye',31,75,75,
      58,76,99,0,2,196875,59062500,
      76,82,81,74,74,74,43,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Mahamadou Susohov','MID','Türkiye',23,76,79,
      74,61,92,0,3,202160,61456640,
      79,80,79,77,77,76,46,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Daniel Agyeio','FWD','Türkiye',30,76,76,
      69,72,96,0,4,202160,61456640,
      82,77,81,70,78,79,43,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Bruno Petkoviko','FWD','Türkiye',22,76,79,
      64,83,100,0,5,202160,61456640,
      84,79,78,67,80,77,45,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Goncalo Souso','FWD','Türkiye',29,76,76,
      59,68,93,0,2,202160,61456640,
      81,76,80,69,82,78,42,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Makana Bakuo','FWD','Türkiye',21,75,80,
      75,79,97,0,3,196875,59062500,
      82,77,81,65,78,78,43,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Florian Ayeo','FWD','Türkiye',28,76,76,
      70,64,90,0,4,202160,61456640,
      85,75,79,68,81,77,46,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Metehan Altunbaşo','FWD','Türkiye',20,72,77,
      65,75,94,0,5,181440,52254720,
      78,73,77,66,74,74,39,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Kocaelispor','Onurcan Piri','2026-27'),
('P|'||c.id||'|02','Kocaelispor','Aleksandar Jovanovic','2026-27'),
('P|'||c.id||'|03','Kocaelispor','Emir Ortakaya','2026-27'),
('P|'||c.id||'|04','Kocaelispor','Tanguy Zoukrou','2026-27'),
('P|'||c.id||'|05','Kocaelispor','Matej Maglica','2026-27'),
('P|'||c.id||'|06','Kocaelispor','Massadio Haidara','2026-27'),
('P|'||c.id||'|07','Kocaelispor','Muharrem Cinan','2026-27'),
('P|'||c.id||'|08','Kocaelispor','Anfernee Dijksteel','2026-27'),
('P|'||c.id||'|09','Kocaelispor','Onur Öztonga','2026-27'),
('P|'||c.id||'|10','Kocaelispor','Tobias Gulliksen','2026-27'),
('P|'||c.id||'|11','Kocaelispor','Show','2026-27'),
('P|'||c.id||'|12','Kocaelispor','Berkan Kutlu','2026-27'),
('P|'||c.id||'|13','Kocaelispor','Rigoberto Rivas','2026-27'),
('P|'||c.id||'|14','Kocaelispor','Uğur Yıldız','2026-27'),
('P|'||c.id||'|15','Kocaelispor','Habib Keita','2026-27'),
('P|'||c.id||'|16','Kocaelispor','Mahamadou Susoho','2026-27'),
('P|'||c.id||'|17','Kocaelispor','Daniel Agyei','2026-27'),
('P|'||c.id||'|18','Kocaelispor','Bruno Petkovic','2026-27'),
('P|'||c.id||'|19','Kocaelispor','Goncalo Sousa','2026-27'),
('P|'||c.id||'|20','Kocaelispor','Makana Baku','2026-27'),
('P|'||c.id||'|21','Kocaelispor','Florian Aye','2026-27'),
('P|'||c.id||'|22','Kocaelispor','Metehan Altunbaş','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Alanya Sahil';
  if not found then raise exception 'Club not found: Alanya Sahil'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Paulo Victoro','GK','Türkiye',26,71,72,
      55,79,96,0,5,176435,50107540,
      47,68,55,57,70,70,79,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Mert Bayramo','GK','Türkiye',33,71,71,
      71,64,100,0,2,176435,50107540,
      49,65,52,59,72,71,81,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Nuno Limo','DEF','Türkiye',25,70,71,
      66,75,93,0,3,171500,48020000,
      61,71,66,79,69,75,37,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Şahin Diko','DEF','Türkiye',32,71,71,
      61,60,97,0,4,176435,50107540,
      64,74,64,77,72,74,40,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Bedirhan Özyurto','DEF','Türkiye',24,72,75,
      56,71,90,0,5,181440,52254720,
      62,72,67,80,75,76,38,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Enes Keskino','DEF','Türkiye',31,68,68,
      72,82,94,0,2,161840,44020480,
      60,70,65,73,68,73,36,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Fatih Aksoyo','DEF','Türkiye',23,69,72,
      67,67,98,0,3,166635,45991260,
      63,68,63,76,71,72,39,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Bruno Viano','DEF','Türkiye',30,70,70,
      62,78,91,0,4,171500,48020000,
      61,71,66,79,69,74,37,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Fidan Alitio','DEF','Türkiye',22,71,74,
      57,63,95,0,5,176435,50107540,
      64,74,64,77,72,76,40,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Yusuf Can Karademiro','MID','Türkiye',29,71,71,
      73,74,99,0,2,176435,50107540,
      70,76,75,73,73,70,37,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Gaius Makouto','MID','Türkiye',21,71,76,
      68,59,92,0,3,176435,50107540,
      72,78,77,70,70,71,39,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'İbrahim Kayo','MID','Türkiye',28,71,71,
      63,70,96,0,4,176435,50107540,
      74,75,74,72,72,72,41,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Arouna Sorov','MID','Türkiye',20,71,76,
      58,81,100,0,5,176435,50107540,
      71,77,76,74,69,70,38,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'İzzet Çeliko','MID','Türkiye',27,71,72,
      74,66,93,0,2,176435,50107540,
      73,79,73,71,71,71,40,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Maestrov','MID','Türkiye',19,72,77,
      69,77,97,0,3,181440,52254720,
      71,77,76,74,74,73,38,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Arda Usluoğluo','FWD','Türkiye',26,72,73,
      64,62,90,0,4,181440,52254720,
      79,74,78,62,75,73,40,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Ivan Cedrico','FWD','Türkiye',33,72,72,
      59,73,94,0,5,181440,52254720,
      81,71,75,64,77,74,42,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Omar Ben Alio','FWD','Türkiye',25,72,73,
      75,58,98,0,2,181440,52254720,
      78,73,77,66,74,75,39,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Ruano','FWD','Türkiye',32,72,72,
      70,69,91,0,3,181440,52254720,
      80,75,74,63,76,73,41,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Emre Demiro','FWD','Türkiye',24,72,75,
      65,80,95,0,4,181440,52254720,
      77,72,76,65,78,74,38,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Ianis Hagio','FWD','Türkiye',31,68,68,
      60,65,99,0,5,161840,44020480,
      75,70,74,58,71,71,36,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Ui-Jo Hwango','FWD','Türkiye',23,69,72,
      55,76,92,0,2,166635,45991260,
      78,68,72,61,74,70,39,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Alanyaspor','Paulo Victor','2026-27'),
('P|'||c.id||'|02','Alanyaspor','Mert Bayram','2026-27'),
('P|'||c.id||'|03','Alanyaspor','Nuno Lima','2026-27'),
('P|'||c.id||'|04','Alanyaspor','Şahin Dik','2026-27'),
('P|'||c.id||'|05','Alanyaspor','Bedirhan Özyurt','2026-27'),
('P|'||c.id||'|06','Alanyaspor','Enes Keskin','2026-27'),
('P|'||c.id||'|07','Alanyaspor','Fatih Aksoy','2026-27'),
('P|'||c.id||'|08','Alanyaspor','Bruno Viana','2026-27'),
('P|'||c.id||'|09','Alanyaspor','Fidan Aliti','2026-27'),
('P|'||c.id||'|10','Alanyaspor','Yusuf Can Karademir','2026-27'),
('P|'||c.id||'|11','Alanyaspor','Gaius Makouta','2026-27'),
('P|'||c.id||'|12','Alanyaspor','İbrahim Kaya','2026-27'),
('P|'||c.id||'|13','Alanyaspor','Arouna Soro','2026-27'),
('P|'||c.id||'|14','Alanyaspor','İzzet Çelik','2026-27'),
('P|'||c.id||'|15','Alanyaspor','Maestro','2026-27'),
('P|'||c.id||'|16','Alanyaspor','Arda Usluoğlu','2026-27'),
('P|'||c.id||'|17','Alanyaspor','Ivan Cedric','2026-27'),
('P|'||c.id||'|18','Alanyaspor','Omar Ben Ali','2026-27'),
('P|'||c.id||'|19','Alanyaspor','Ruan','2026-27'),
('P|'||c.id||'|20','Alanyaspor','Emre Demir','2026-27'),
('P|'||c.id||'|21','Alanyaspor','Ianis Hagi','2026-27'),
('P|'||c.id||'|22','Alanyaspor','Ui-Jo Hwang','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Gaziantep Fıstıkspor';
  if not found then raise exception 'Club not found: Gaziantep Fıstıkspor'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Kacper Tobiaszo','GK','Türkiye',29,74,74,
      66,80,94,0,2,191660,56731360,
      48,69,56,63,76,75,80,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Cemilhan Aslano','GK','Türkiye',21,74,79,
      61,65,98,0,3,191660,56731360,
      50,71,58,60,73,73,82,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Myenty Abeno','DEF','Türkiye',28,74,74,
      56,76,91,0,4,191660,56731360,
      68,73,68,81,76,78,44,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Mervan Müjdecio','DEF','Türkiye',20,75,80,
      72,61,95,0,5,196875,59062500,
      66,76,71,84,74,80,42,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Kerim Çalhanoğluo','DEF','Türkiye',27,71,72,
      67,72,99,0,2,176435,50107540,
      64,74,64,77,72,74,40,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Salem M''Bakato','DEF','Türkiye',19,72,77,
      62,83,92,0,3,181440,52254720,
      62,72,67,80,75,76,38,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Luis Perezo','DEF','Türkiye',26,73,74,
      57,68,96,0,4,186515,54462380,
      65,75,70,78,73,78,41,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Ulrich Meleko','DEF','Türkiye',33,74,74,
      73,79,100,0,5,191660,56731360,
      68,73,68,81,76,77,44,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Fuat Bavuko','DEF','Türkiye',25,75,76,
      68,64,93,0,2,196875,59062500,
      66,76,71,84,74,79,42,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Juninho Bacuno','MID','Türkiye',32,74,74,
      63,75,97,0,3,191660,56731360,
      76,82,76,74,74,75,43,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Nazım Sangaro','MID','Türkiye',24,74,77,
      58,60,90,0,4,191660,56731360,
      73,79,78,76,76,73,40,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Karamba Gassamo','MID','Türkiye',31,74,74,
      74,71,94,0,5,191660,56731360,
      75,81,80,73,73,74,42,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Victor Gidadov','MID','Türkiye',23,74,77,
      69,82,98,0,2,191660,56731360,
      77,78,77,75,75,75,44,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Deian Sorescuo','MID','Türkiye',30,75,75,
      64,67,91,0,3,196875,59062500,
      75,81,80,78,73,74,42,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Oğün Özçiçeko','MID','Türkiye',22,71,74,
      59,78,95,0,4,176435,50107540,
      73,79,73,71,71,71,40,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Kacper Kozlowskio','MID','Türkiye',29,72,72,
      75,63,99,0,5,181440,52254720,
      71,77,76,74,74,73,38,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Drissa Camaro','MID','Türkiye',21,73,78,
      70,74,92,0,2,186515,54462380,
      74,80,79,72,72,72,41,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Trivante Stewarto','FWD','Türkiye',28,75,75,
      65,59,96,0,3,196875,59062500,
      84,74,78,67,80,77,45,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Ali Osman Kalıno','FWD','Türkiye',20,75,80,
      60,70,100,0,4,196875,59062500,
      81,76,80,69,77,78,42,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Kuzey Bulguluo','FWD','Türkiye',27,71,72,
      55,81,93,0,5,176435,50107540,
      79,74,73,62,75,72,40,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Muhammed Akmeleko','FWD','Türkiye',19,72,77,
      71,66,97,0,2,181440,52254720,
      77,72,76,65,78,74,38,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Serdar Dursuno','FWD','Türkiye',26,73,74,
      66,77,90,0,3,186515,54462380,
      80,75,79,63,76,76,41,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Gaziantep FK','Kacper Tobiasz','2026-27'),
('P|'||c.id||'|02','Gaziantep FK','Cemilhan Aslan','2026-27'),
('P|'||c.id||'|03','Gaziantep FK','Myenty Abena','2026-27'),
('P|'||c.id||'|04','Gaziantep FK','Mervan Müjdeci','2026-27'),
('P|'||c.id||'|05','Gaziantep FK','Kerim Çalhanoğlu','2026-27'),
('P|'||c.id||'|06','Gaziantep FK','Salem M''Bakata','2026-27'),
('P|'||c.id||'|07','Gaziantep FK','Luis Perez','2026-27'),
('P|'||c.id||'|08','Gaziantep FK','Ulrich Meleke','2026-27'),
('P|'||c.id||'|09','Gaziantep FK','Fuat Bavuk','2026-27'),
('P|'||c.id||'|10','Gaziantep FK','Juninho Bacuna','2026-27'),
('P|'||c.id||'|11','Gaziantep FK','Nazım Sangare','2026-27'),
('P|'||c.id||'|12','Gaziantep FK','Karamba Gassama','2026-27'),
('P|'||c.id||'|13','Gaziantep FK','Victor Gidado','2026-27'),
('P|'||c.id||'|14','Gaziantep FK','Deian Sorescu','2026-27'),
('P|'||c.id||'|15','Gaziantep FK','Oğün Özçiçek','2026-27'),
('P|'||c.id||'|16','Gaziantep FK','Kacper Kozlowski','2026-27'),
('P|'||c.id||'|17','Gaziantep FK','Drissa Camara','2026-27'),
('P|'||c.id||'|18','Gaziantep FK','Trivante Stewart','2026-27'),
('P|'||c.id||'|19','Gaziantep FK','Ali Osman Kalın','2026-27'),
('P|'||c.id||'|20','Gaziantep FK','Kuzey Bulgulu','2026-27'),
('P|'||c.id||'|21','Gaziantep FK','Muhammed Akmelek','2026-27'),
('P|'||c.id||'|22','Gaziantep FK','Serdar Dursun','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Ankara Gençlik';
  if not found then raise exception 'Club not found: Ankara Gençlik'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Gökhan Akkano','GK','Türkiye',32,70,70,
      56,81,92,0,3,171500,48020000,
      47,68,50,57,70,70,79,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'İrfan Eğribayato','GK','Türkiye',24,70,73,
      72,66,96,0,4,171500,48020000,
      44,65,52,59,72,71,76,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Dimitrios Goutaso','DEF','Türkiye',31,71,71,
      67,77,100,0,5,176435,50107540,
      63,73,68,76,71,74,39,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Ensar Çavuşoğluo','DEF','Türkiye',23,67,70,
      62,62,93,0,2,157115,42106820,
      61,66,61,74,69,71,37,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Yiğit Hamza Aydaro','DEF','Türkiye',30,68,68,
      57,73,97,0,3,161840,44020480,
      59,69,64,77,67,73,35,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Metehan Baltacıo','DEF','Türkiye',22,69,72,
      73,58,90,0,4,166635,45991260,
      62,72,62,75,70,72,38,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Abdurrahim Dursuno','DEF','Türkiye',29,70,70,
      68,69,94,0,5,171500,48020000,
      60,70,65,78,73,74,36,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Thalissono','DEF','Türkiye',21,71,76,
      63,80,98,0,2,176435,50107540,
      63,73,68,76,71,76,39,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Kevin Rodrigueso','DEF','Türkiye',28,67,67,
      58,65,91,0,3,157115,42106820,
      61,66,61,74,69,70,37,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Oğulcan Ülgüno','MID','Türkiye',20,70,75,
      74,76,95,0,4,171500,48020000,
      70,76,75,73,68,70,37,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Salih Uçano','MID','Türkiye',27,70,71,
      69,61,99,0,5,171500,48020000,
      72,78,72,70,70,71,39,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Ousmane Diabato','MID','Türkiye',19,70,75,
      64,72,92,0,2,171500,48020000,
      69,75,74,72,72,69,36,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Michal Nalepo','MID','Türkiye',26,70,71,
      59,83,96,0,3,171500,48020000,
      71,77,76,69,69,70,38,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Rafael Luiso','MID','Türkiye',33,67,67,
      75,68,100,0,4,157115,42106820,
      70,71,70,68,68,68,37,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Cheikh Niasso','MID','Türkiye',25,68,69,
      70,79,93,0,5,161840,44020480,
      68,74,73,71,66,67,35,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Sekou Koito','FWD','Türkiye',32,71,71,
      65,64,97,0,2,176435,50107540,
      79,74,73,62,75,73,40,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Victor Orakpov','FWD','Türkiye',24,71,74,
      60,75,90,0,3,176435,50107540,
      76,71,75,64,77,74,37,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Tiago Gouveio','FWD','Türkiye',31,71,71,
      55,60,94,0,4,176435,50107540,
      78,73,77,61,74,72,39,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Furkan Özcano','FWD','Türkiye',23,71,74,
      71,71,98,0,5,176435,50107540,
      80,70,74,63,76,73,41,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Adama Traoro','FWD','Türkiye',30,68,68,
      66,82,91,0,2,161840,44020480,
      74,69,73,62,70,71,35,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Prince Martor Jr.o','FWD','Türkiye',22,69,72,
      61,67,95,0,3,166635,45991260,
      77,72,71,60,73,70,38,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Pedro Mendeso','FWD','Türkiye',29,70,70,
      56,78,99,0,4,171500,48020000,
      75,70,74,63,76,72,36,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Gençlerbirliği','Gökhan Akkan','2026-27'),
('P|'||c.id||'|02','Gençlerbirliği','İrfan Eğribayat','2026-27'),
('P|'||c.id||'|03','Gençlerbirliği','Dimitrios Goutas','2026-27'),
('P|'||c.id||'|04','Gençlerbirliği','Ensar Çavuşoğlu','2026-27'),
('P|'||c.id||'|05','Gençlerbirliği','Yiğit Hamza Aydar','2026-27'),
('P|'||c.id||'|06','Gençlerbirliği','Metehan Baltacı','2026-27'),
('P|'||c.id||'|07','Gençlerbirliği','Abdurrahim Dursun','2026-27'),
('P|'||c.id||'|08','Gençlerbirliği','Thalisson','2026-27'),
('P|'||c.id||'|09','Gençlerbirliği','Kevin Rodrigues','2026-27'),
('P|'||c.id||'|10','Gençlerbirliği','Oğulcan Ülgün','2026-27'),
('P|'||c.id||'|11','Gençlerbirliği','Salih Uçan','2026-27'),
('P|'||c.id||'|12','Gençlerbirliği','Ousmane Diabate','2026-27'),
('P|'||c.id||'|13','Gençlerbirliği','Michal Nalepa','2026-27'),
('P|'||c.id||'|14','Gençlerbirliği','Rafael Luis','2026-27'),
('P|'||c.id||'|15','Gençlerbirliği','Cheikh Niasse','2026-27'),
('P|'||c.id||'|16','Gençlerbirliği','Sekou Koita','2026-27'),
('P|'||c.id||'|17','Gençlerbirliği','Victor Orakpo','2026-27'),
('P|'||c.id||'|18','Gençlerbirliği','Tiago Gouveia','2026-27'),
('P|'||c.id||'|19','Gençlerbirliği','Furkan Özcan','2026-27'),
('P|'||c.id||'|20','Gençlerbirliği','Adama Traore','2026-27'),
('P|'||c.id||'|21','Gençlerbirliği','Prince Martor Jr.','2026-27'),
('P|'||c.id||'|22','Gençlerbirliği','Pedro Mendes','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Kasımpaşa Tersane';
  if not found then raise exception 'Club not found: Kasımpaşa Tersane'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Andreas Gianniotiso','GK','Türkiye',20,69,74,
      67,82,90,0,4,166635,45991260,
      44,65,52,59,67,68,76,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Ali Yanaro','GK','Türkiye',27,69,70,
      62,67,94,0,5,166635,45991260,
      46,67,49,56,69,69,78,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Kamil Ahmet Çörekçio','DEF','Türkiye',19,66,71,
      57,78,98,0,2,152460,40249440,
      56,66,61,74,69,71,32,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Ahmet Saliho','DEF','Türkiye',26,67,68,
      73,63,91,0,3,157115,42106820,
      59,69,64,72,67,70,35,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Adem Arouso','DEF','Türkiye',33,68,68,
      68,74,95,0,4,161840,44020480,
      62,67,62,75,70,72,38,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Matei Cristian Ilio','DEF','Türkiye',25,69,70,
      63,59,99,0,5,166635,45991260,
      60,70,65,78,68,74,36,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Ömer Bayramo','DEF','Türkiye',32,70,70,
      58,70,92,0,2,171500,48020000,
      63,73,63,76,71,73,39,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Claudio Wincko','DEF','Türkiye',24,66,69,
      74,81,96,0,3,152460,40249440,
      56,66,61,74,69,70,32,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Godfried Frimpongo','DEF','Türkiye',31,67,67,
      69,66,100,0,4,157115,42106820,
      59,69,64,72,67,72,35,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Kerem Demirbayo','MID','Türkiye',23,69,72,
      64,77,93,0,5,166635,45991260,
      72,73,72,70,70,68,39,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Haris Hajradinovico','MID','Türkiye',30,69,69,
      59,62,97,0,2,166635,45991260,
      69,75,74,72,67,69,36,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Fousseni Diabato','MID','Türkiye',22,69,72,
      75,73,90,0,3,166635,45991260,
      71,77,71,69,69,70,38,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Mortadha Ben Ouaneso','MID','Türkiye',29,69,69,
      70,58,94,0,4,166635,45991260,
      68,74,73,71,71,68,35,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Jakob Vestergaard Jesseno','MID','Türkiye',21,67,72,
      65,69,98,0,5,157115,42106820,
      68,74,73,66,66,67,35,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Jesurun Rak-Sakyio','MID','Türkiye',28,68,68,
      60,80,91,0,2,161840,44020480,
      71,72,71,69,69,69,38,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Andri Fannar Baldurssono','MID','Türkiye',20,69,74,
      55,65,95,0,3,166635,45991260,
      69,75,74,72,67,68,36,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Adrian Benedyczako','FWD','Türkiye',27,70,71,
      71,76,99,0,4,171500,48020000,
      78,73,72,61,74,72,39,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Güven Yalçıno','FWD','Türkiye',19,70,75,
      66,61,92,0,5,171500,48020000,
      75,70,74,63,76,73,36,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Thiemoko Diarro','FWD','Türkiye',26,70,71,
      61,72,96,0,2,171500,48020000,
      77,72,76,60,73,71,38,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Erdem Çetinkayo','FWD','Türkiye',33,68,68,
      56,83,100,0,3,161840,44020480,
      77,67,71,60,73,70,38,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Ali Kolo','FWD','Türkiye',25,69,70,
      72,68,93,0,4,166635,45991260,
      75,70,74,63,71,72,36,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Sercan Denizo','FWD','Türkiye',32,70,70,
      67,79,97,0,5,171500,48020000,
      78,73,72,61,74,71,39,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Kasımpaşa','Andreas Gianniotis','2026-27'),
('P|'||c.id||'|02','Kasımpaşa','Ali Yanar','2026-27'),
('P|'||c.id||'|03','Kasımpaşa','Kamil Ahmet Çörekçi','2026-27'),
('P|'||c.id||'|04','Kasımpaşa','Ahmet Salih','2026-27'),
('P|'||c.id||'|05','Kasımpaşa','Adem Arous','2026-27'),
('P|'||c.id||'|06','Kasımpaşa','Matei Cristian Ilie','2026-27'),
('P|'||c.id||'|07','Kasımpaşa','Ömer Bayram','2026-27'),
('P|'||c.id||'|08','Kasımpaşa','Claudio Winck','2026-27'),
('P|'||c.id||'|09','Kasımpaşa','Godfried Frimpong','2026-27'),
('P|'||c.id||'|10','Kasımpaşa','Kerem Demirbay','2026-27'),
('P|'||c.id||'|11','Kasımpaşa','Haris Hajradinovic','2026-27'),
('P|'||c.id||'|12','Kasımpaşa','Fousseni Diabate','2026-27'),
('P|'||c.id||'|13','Kasımpaşa','Mortadha Ben Ouanes','2026-27'),
('P|'||c.id||'|14','Kasımpaşa','Jakob Vestergaard Jessen','2026-27'),
('P|'||c.id||'|15','Kasımpaşa','Jesurun Rak-Sakyi','2026-27'),
('P|'||c.id||'|16','Kasımpaşa','Andri Fannar Baldursson','2026-27'),
('P|'||c.id||'|17','Kasımpaşa','Adrian Benedyczak','2026-27'),
('P|'||c.id||'|18','Kasımpaşa','Güven Yalçın','2026-27'),
('P|'||c.id||'|19','Kasımpaşa','Thiemoko Diarra','2026-27'),
('P|'||c.id||'|20','Kasımpaşa','Erdem Çetinkaya','2026-27'),
('P|'||c.id||'|21','Kasımpaşa','Ali Kol','2026-27'),
('P|'||c.id||'|22','Kasımpaşa','Sercan Deniz','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Eyüp Haliç';
  if not found then raise exception 'Club not found: Eyüp Haliç'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Emre Bilgino','GK','Türkiye',23,75,78,
      57,83,99,0,5,196875,59062500,
      53,69,56,63,76,76,85,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Horatiu Moldovano','GK','Türkiye',30,75,75,
      73,68,92,0,2,196875,59062500,
      50,71,58,65,73,74,82,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Talha Ulvano','DEF','Türkiye',22,73,76,
      68,79,96,0,3,186515,54462380,
      66,76,66,79,74,77,42,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Simone Giordanov','DEF','Türkiye',29,74,74,
      63,64,100,0,4,191660,56731360,
      64,74,69,82,77,79,40,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Anıl Yaşaro','DEF','Türkiye',21,75,80,
      58,75,93,0,5,196875,59062500,
      67,77,72,80,75,78,43,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Arda Yavuzo','DEF','Türkiye',28,76,76,
      74,60,97,0,2,202160,61456640,
      70,75,70,83,78,80,46,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Gilbert Mendyo','DEF','Türkiye',20,72,77,
      69,71,90,0,3,181440,52254720,
      63,73,68,81,71,77,39,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Jawad El Yamiqo','DEF','Türkiye',27,73,74,
      64,82,94,0,4,186515,54462380,
      66,76,66,79,74,76,42,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Zak Juleso','DEF','Türkiye',19,74,79,
      59,67,98,0,5,191660,56731360,
      64,74,69,82,77,78,40,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Christ Sadio','MID','Türkiye',26,75,76,
      75,78,91,0,2,196875,59062500,
      76,82,81,74,74,76,43,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Charles-Andre Raux-Yaov','MID','Türkiye',33,75,75,
      70,63,95,0,3,196875,59062500,
      78,79,78,76,76,74,45,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Hamza Akmano','MID','Türkiye',25,75,76,
      65,74,99,0,4,196875,59062500,
      75,81,80,78,73,75,42,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Erdem Çalıko','MID','Türkiye',32,75,75,
      60,59,92,0,5,196875,59062500,
      77,83,77,75,75,76,44,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'David Costo','MID','Türkiye',24,74,77,
      55,70,96,0,2,191660,56731360,
      73,79,78,76,76,73,40,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Chandrel Massango','MID','Türkiye',31,75,75,
      71,81,100,0,3,196875,59062500,
      76,82,81,74,74,75,43,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Abdelhamid Sabirio','MID','Türkiye',23,76,79,
      66,66,93,0,4,202160,61456640,
      79,80,79,77,77,77,46,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Ahmed Abdullahio','FWD','Türkiye',30,76,76,
      61,77,97,0,5,202160,61456640,
      82,77,81,70,78,77,43,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Yusuf Barasio','FWD','Türkiye',22,76,79,
      56,62,90,0,2,202160,61456640,
      84,79,78,67,80,78,45,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Lenny Pintoro','FWD','Türkiye',29,76,76,
      72,73,94,0,3,202160,61456640,
      81,76,80,69,82,79,42,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Mete Kaan Demiro','FWD','Türkiye',21,75,80,
      67,58,98,0,4,196875,59062500,
      82,77,81,65,78,76,43,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Abdou Syo','FWD','Türkiye',28,76,76,
      62,69,91,0,5,202160,61456640,
      85,75,79,68,81,78,46,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Bilal Boutobbo','FWD','Türkiye',20,72,77,
      57,80,95,0,2,181440,52254720,
      78,73,77,66,74,75,39,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Eyüpspor','Emre Bilgin','2026-27'),
('P|'||c.id||'|02','Eyüpspor','Horatiu Moldovan','2026-27'),
('P|'||c.id||'|03','Eyüpspor','Talha Ulvan','2026-27'),
('P|'||c.id||'|04','Eyüpspor','Simone Giordano','2026-27'),
('P|'||c.id||'|05','Eyüpspor','Anıl Yaşar','2026-27'),
('P|'||c.id||'|06','Eyüpspor','Arda Yavuz','2026-27'),
('P|'||c.id||'|07','Eyüpspor','Gilbert Mendy','2026-27'),
('P|'||c.id||'|08','Eyüpspor','Jawad El Yamiq','2026-27'),
('P|'||c.id||'|09','Eyüpspor','Zak Jules','2026-27'),
('P|'||c.id||'|10','Eyüpspor','Christ Sadia','2026-27'),
('P|'||c.id||'|11','Eyüpspor','Charles-Andre Raux-Yao','2026-27'),
('P|'||c.id||'|12','Eyüpspor','Hamza Akman','2026-27'),
('P|'||c.id||'|13','Eyüpspor','Erdem Çalık','2026-27'),
('P|'||c.id||'|14','Eyüpspor','David Costa','2026-27'),
('P|'||c.id||'|15','Eyüpspor','Chandrel Massanga','2026-27'),
('P|'||c.id||'|16','Eyüpspor','Abdelhamid Sabiri','2026-27'),
('P|'||c.id||'|17','Eyüpspor','Ahmed Abdullahi','2026-27'),
('P|'||c.id||'|18','Eyüpspor','Yusuf Barasi','2026-27'),
('P|'||c.id||'|19','Eyüpspor','Lenny Pintor','2026-27'),
('P|'||c.id||'|20','Eyüpspor','Mete Kaan Demir','2026-27'),
('P|'||c.id||'|21','Eyüpspor','Abdou Sy','2026-27'),
('P|'||c.id||'|22','Eyüpspor','Bilal Boutobba','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Diyarbakır Surlar';
  if not found then raise exception 'Club not found: Diyarbakır Surlar'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Alban Lafonte','GK','Türkiye',26,68,69,
      68,58,97,0,2,161840,44020480,
      44,65,52,54,67,68,76,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Mustafa Burak Bozano','GK','Türkiye',33,68,68,
      63,69,90,0,3,161840,44020480,
      46,62,49,56,69,69,78,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Gökhan Gülo','DEF','Türkiye',25,67,68,
      58,80,94,0,4,157115,42106820,
      58,68,63,76,66,70,34,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Miraç Acero','DEF','Türkiye',32,68,68,
      74,65,98,0,5,161840,44020480,
      61,71,61,74,69,72,37,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Ali Turap Bülbülo','DEF','Türkiye',24,69,72,
      69,76,91,0,2,166635,45991260,
      59,69,64,77,72,74,35,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Lumbardh Dellovo','DEF','Türkiye',31,65,65,
      64,61,95,0,3,147875,38447500,
      57,67,62,70,65,68,33,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Mehmet Yeşilo','DEF','Türkiye',23,66,69,
      59,72,99,0,4,152460,40249440,
      60,65,60,73,68,70,36,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Umut Meraşo','DEF','Türkiye',30,67,67,
      75,83,92,0,5,157115,42106820,
      58,68,63,76,66,72,34,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'David Bateso','DEF','Türkiye',22,68,71,
      70,68,96,0,2,161840,44020480,
      61,71,61,74,69,71,37,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Rayan Lutino','MID','Türkiye',29,68,68,
      65,79,100,0,3,161840,44020480,
      67,73,72,70,70,68,34,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Samuel Balleto','MID','Türkiye',21,68,73,
      60,64,93,0,4,161840,44020480,
      69,75,74,67,67,69,36,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Cem Üstündağo','MID','Türkiye',28,68,68,
      55,75,97,0,5,161840,44020480,
      71,72,71,69,69,67,38,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Dia Sabo','MID','Türkiye',20,68,73,
      71,60,90,0,2,161840,44020480,
      68,74,73,71,66,68,35,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Rayan Ravelosono','MID','Türkiye',27,68,69,
      66,71,94,0,3,161840,44020480,
      70,76,70,68,68,69,37,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Furkan Soyalpo','MID','Türkiye',19,69,74,
      61,82,98,0,4,166635,45991260,
      68,74,73,71,71,68,35,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Berk Kızıldemiro','MID','Türkiye',26,65,66,
      56,67,91,0,5,147875,38447500,
      66,72,71,64,64,65,33,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Gifty Orban','FWD','Türkiye',33,69,69,
      72,78,95,0,2,166635,45991260,
      78,68,72,61,74,72,39,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Ermal Krasniqio','FWD','Türkiye',25,69,70,
      67,63,99,0,3,166635,45991260,
      75,70,74,63,71,70,36,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Collins Soro','FWD','Türkiye',32,69,69,
      62,74,92,0,4,166635,45991260,
      77,72,71,60,73,71,38,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Mohamed Khalilo','FWD','Türkiye',24,69,72,
      57,59,96,0,5,166635,45991260,
      74,69,73,62,75,72,35,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Mbaye Diagno','FWD','Türkiye',31,65,65,
      73,70,100,0,2,147875,38447500,
      72,67,71,55,68,66,33,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Dilhan Demiro','FWD','Türkiye',23,66,69,
      68,81,93,0,3,152460,40249440,
      75,65,69,58,71,68,36,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Amed Sportif','Alban Lafont','2026-27'),
('P|'||c.id||'|02','Amed Sportif','Mustafa Burak Bozan','2026-27'),
('P|'||c.id||'|03','Amed Sportif','Gökhan Gül','2026-27'),
('P|'||c.id||'|04','Amed Sportif','Miraç Acer','2026-27'),
('P|'||c.id||'|05','Amed Sportif','Ali Turap Bülbül','2026-27'),
('P|'||c.id||'|06','Amed Sportif','Lumbardh Dellova','2026-27'),
('P|'||c.id||'|07','Amed Sportif','Mehmet Yeşil','2026-27'),
('P|'||c.id||'|08','Amed Sportif','Umut Meraş','2026-27'),
('P|'||c.id||'|09','Amed Sportif','David Bates','2026-27'),
('P|'||c.id||'|10','Amed Sportif','Rayan Lutin','2026-27'),
('P|'||c.id||'|11','Amed Sportif','Samuel Ballet','2026-27'),
('P|'||c.id||'|12','Amed Sportif','Cem Üstündağ','2026-27'),
('P|'||c.id||'|13','Amed Sportif','Dia Saba','2026-27'),
('P|'||c.id||'|14','Amed Sportif','Rayan Raveloson','2026-27'),
('P|'||c.id||'|15','Amed Sportif','Furkan Soyalp','2026-27'),
('P|'||c.id||'|16','Amed Sportif','Berk Kızıldemir','2026-27'),
('P|'||c.id||'|17','Amed Sportif','Gift Orban','2026-27'),
('P|'||c.id||'|18','Amed Sportif','Ermal Krasniqi','2026-27'),
('P|'||c.id||'|19','Amed Sportif','Collins Sor','2026-27'),
('P|'||c.id||'|20','Amed Sportif','Mohamed Khalil','2026-27'),
('P|'||c.id||'|21','Amed Sportif','Mbaye Diagne','2026-27'),
('P|'||c.id||'|22','Amed Sportif','Dilhan Demir','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Erzurum Ayaz';
  if not found then raise exception 'Club not found: Erzurum Ayaz'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Ertuğrul Taşkırano','GK','Türkiye',29,67,67,
      58,59,95,0,3,157115,42106820,
      41,62,49,56,69,66,73,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Matija Orbanico','GK','Türkiye',21,67,72,
      74,70,99,0,4,157115,42106820,
      43,64,51,53,66,67,75,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Cengizhan Bayrako','DEF','Türkiye',28,67,67,
      69,81,92,0,5,157115,42106820,
      61,66,61,74,69,72,37,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Mustafa Yumluo','DEF','Türkiye',20,68,73,
      64,66,96,0,2,161840,44020480,
      59,69,64,77,67,71,35,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Yakup Kırtayo','DEF','Türkiye',27,64,65,
      59,77,100,0,3,143360,36700160,
      57,67,57,70,65,68,33,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Amar Gerxhaliuo','DEF','Türkiye',19,65,70,
      75,62,93,0,4,147875,38447500,
      55,65,60,73,68,70,31,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Orhan Ovacıklıo','DEF','Türkiye',26,66,67,
      70,73,97,0,5,152460,40249440,
      58,68,63,71,66,69,34,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Guram Giorbelidzo','DEF','Türkiye',33,67,67,
      65,58,90,0,2,157115,42106820,
      61,66,61,74,69,71,37,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Nihad Mujakico','DEF','Türkiye',25,68,69,
      60,69,94,0,3,161840,44020480,
      59,69,64,77,67,73,35,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Sefa Akgüno','MID','Türkiye',32,67,67,
      55,80,98,0,4,157115,42106820,
      69,75,69,67,67,66,36,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Miguel Cardosov','MID','Türkiye',24,67,70,
      71,65,91,0,5,157115,42106820,
      66,72,71,69,69,67,33,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Mert Önalo','MID','Türkiye',31,67,67,
      66,76,95,0,2,157115,42106820,
      68,74,73,66,66,68,35,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Elisha Owusuo','MID','Türkiye',23,67,70,
      61,61,99,0,3,157115,42106820,
      70,71,70,68,68,66,37,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Nariman Akhundzado','MID','Türkiye',30,68,68,
      56,72,92,0,4,161840,44020480,
      68,74,73,71,66,68,35,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Lawrence Agyekumo','MID','Türkiye',22,64,67,
      72,83,96,0,5,143360,36700160,
      66,72,66,64,64,65,33,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Brandon Baiyo','MID','Türkiye',29,65,65,
      67,68,100,0,2,147875,38447500,
      64,70,69,67,67,64,31,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Eren Tozluo','FWD','Türkiye',21,68,73,
      62,79,93,0,3,161840,44020480,
      75,70,74,58,71,70,36,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Martin Rodriguezo','FWD','Türkiye',28,68,68,
      57,64,97,0,4,161840,44020480,
      77,67,71,60,73,71,38,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Ibrahim Diabato','FWD','Türkiye',20,68,73,
      73,75,90,0,5,161840,44020480,
      74,69,73,62,70,69,35,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Festy Eboselo','FWD','Türkiye',27,64,65,
      68,60,94,0,2,143360,36700160,
      72,67,66,55,68,66,33,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Gyrano Kerko','FWD','Türkiye',19,65,70,
      63,71,98,0,3,147875,38447500,
      70,65,69,58,71,68,31,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Mustafa Fettahoğluo','FWD','Türkiye',26,66,67,
      58,82,91,0,4,152460,40249440,
      73,68,72,56,69,67,34,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Erzurumspor','Ertuğrul Taşkıran','2026-27'),
('P|'||c.id||'|02','Erzurumspor','Matija Orbanic','2026-27'),
('P|'||c.id||'|03','Erzurumspor','Cengizhan Bayrak','2026-27'),
('P|'||c.id||'|04','Erzurumspor','Mustafa Yumlu','2026-27'),
('P|'||c.id||'|05','Erzurumspor','Yakup Kırtay','2026-27'),
('P|'||c.id||'|06','Erzurumspor','Amar Gerxhaliu','2026-27'),
('P|'||c.id||'|07','Erzurumspor','Orhan Ovacıklı','2026-27'),
('P|'||c.id||'|08','Erzurumspor','Guram Giorbelidze','2026-27'),
('P|'||c.id||'|09','Erzurumspor','Nihad Mujakic','2026-27'),
('P|'||c.id||'|10','Erzurumspor','Sefa Akgün','2026-27'),
('P|'||c.id||'|11','Erzurumspor','Miguel Cardoso','2026-27'),
('P|'||c.id||'|12','Erzurumspor','Mert Önal','2026-27'),
('P|'||c.id||'|13','Erzurumspor','Elisha Owusu','2026-27'),
('P|'||c.id||'|14','Erzurumspor','Nariman Akhundzade','2026-27'),
('P|'||c.id||'|15','Erzurumspor','Lawrence Agyekum','2026-27'),
('P|'||c.id||'|16','Erzurumspor','Brandon Baiye','2026-27'),
('P|'||c.id||'|17','Erzurumspor','Eren Tozlu','2026-27'),
('P|'||c.id||'|18','Erzurumspor','Martin Rodriguez','2026-27'),
('P|'||c.id||'|19','Erzurumspor','Ibrahim Diabate','2026-27'),
('P|'||c.id||'|20','Erzurumspor','Festy Ebosele','2026-27'),
('P|'||c.id||'|21','Erzurumspor','Gyrano Kerk','2026-27'),
('P|'||c.id||'|22','Erzurumspor','Mustafa Fettahoğlu','2026-27')
  ;
end $$;

do $$
declare c public.clubs%rowtype;
begin
  select * into c from public.clubs where country='Türkiye' and league_level=1 and name='Çorum Leblebi';
  if not found then raise exception 'Club not found: Çorum Leblebi'; end if;

  insert into public.players(
    id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
    form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
    finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody,is_star_parody
  ) values
  (
      'P|'||c.id||'|01',c.id,1,'Marcos Felipo','GK','Türkiye',32,65,65,
      69,60,93,0,4,147875,38447500,
      42,63,45,52,65,66,74,true,true
    ),
(
      'P|'||c.id||'|02',c.id,12,'Erhan Erentürko','GK','Türkiye',24,65,68,
      64,71,97,0,5,147875,38447500,
      39,60,47,54,67,64,71,true,true
    ),
(
      'P|'||c.id||'|03',c.id,2,'Gökhan Sazdağıo','DEF','Türkiye',31,66,66,
      59,82,90,0,2,152460,40249440,
      58,68,63,71,66,70,34,true,true
    ),
(
      'P|'||c.id||'|04',c.id,3,'Çağlar Söyünço','DEF','Türkiye',23,62,65,
      75,67,94,0,3,134540,33365920,
      56,61,56,69,64,67,32,true,true
    ),
(
      'P|'||c.id||'|05',c.id,4,'Andrei Borzo','DEF','Türkiye',30,63,63,
      70,78,98,0,4,138915,35006580,
      54,64,59,72,62,66,30,true,true
    ),
(
      'P|'||c.id||'|06',c.id,5,'Arda Şengülo','DEF','Türkiye',22,64,67,
      65,63,91,0,5,143360,36700160,
      57,67,57,70,65,68,33,true,true
    ),
(
      'P|'||c.id||'|07',c.id,6,'Cemali Sertelo','DEF','Türkiye',29,65,65,
      60,74,95,0,2,147875,38447500,
      55,65,60,73,68,70,31,true,true
    ),
(
      'P|'||c.id||'|08',c.id,13,'Serdar Saatçıo','DEF','Türkiye',21,66,71,
      55,59,99,0,3,152460,40249440,
      58,68,63,71,66,69,34,true,true
    ),
(
      'P|'||c.id||'|09',c.id,14,'Alexandre Penetro','DEF','Türkiye',28,62,62,
      71,70,92,0,4,134540,33365920,
      56,61,56,69,64,66,32,true,true
    ),
(
      'P|'||c.id||'|10',c.id,8,'Mohamed Diomando','MID','Türkiye',20,65,70,
      66,81,96,0,5,147875,38447500,
      65,71,70,68,63,66,32,true,true
    ),
(
      'P|'||c.id||'|11',c.id,10,'Göktan Gürpüzo','MID','Türkiye',27,65,66,
      61,66,100,0,2,147875,38447500,
      67,73,67,65,65,64,34,true,true
    ),
(
      'P|'||c.id||'|12',c.id,15,'Cengiz Ündero','MID','Türkiye',19,65,70,
      56,77,93,0,3,147875,38447500,
      64,70,69,67,67,65,31,true,true
    ),
(
      'P|'||c.id||'|13',c.id,16,'Berat Özdemiro','MID','Türkiye',26,65,66,
      72,62,97,0,4,147875,38447500,
      66,72,71,64,64,66,33,true,true
    ),
(
      'P|'||c.id||'|14',c.id,20,'Markus Karlsbakko','MID','Türkiye',33,62,62,
      67,73,90,0,5,134540,33365920,
      65,66,65,63,63,61,32,true,true
    ),
(
      'P|'||c.id||'|15',c.id,21,'Ahmed Ildizo','MID','Türkiye',25,63,64,
      62,58,94,0,2,138915,35006580,
      63,69,68,66,61,63,30,true,true
    ),
(
      'P|'||c.id||'|16',c.id,22,'Ylber Ramadanio','MID','Türkiye',32,64,64,
      57,69,98,0,3,143360,36700160,
      66,72,66,64,64,65,33,true,true
    ),
(
      'P|'||c.id||'|17',c.id,7,'Mame Baba Thiamm','FWD','Türkiye',24,66,69,
      73,80,91,0,4,152460,40249440,
      71,66,70,59,72,67,32,true,true
    ),
(
      'P|'||c.id||'|18',c.id,9,'Emircan Gürlüko','FWD','Türkiye',31,66,66,
      68,65,95,0,5,152460,40249440,
      73,68,72,56,69,68,34,true,true
    ),
(
      'P|'||c.id||'|19',c.id,11,'Youssoufa Moukokov','FWD','Türkiye',23,66,69,
      63,76,99,0,2,152460,40249440,
      75,65,69,58,71,69,36,true,true
    ),
(
      'P|'||c.id||'|20',c.id,17,'Alexandros Kyziridiso','FWD','Türkiye',30,63,63,
      58,61,92,0,3,138915,35006580,
      69,64,68,57,65,64,30,true,true
    ),
(
      'P|'||c.id||'|21',c.id,18,'Jesus Ramirezo','FWD','Türkiye',22,64,67,
      74,72,96,0,4,143360,36700160,
      72,67,66,55,68,66,33,true,true
    ),
(
      'P|'||c.id||'|22',c.id,19,'Hasan Abdulkareemo','FWD','Türkiye',29,65,65,
      69,83,100,0,5,147875,38447500,
      70,65,69,58,71,68,31,true,true
    )
  ;

  insert into private.player_source_map(player_id,source_team,source_player,source_season) values
  ('P|'||c.id||'|01','Arca Çorum FK','Marcos Felipe','2026-27'),
('P|'||c.id||'|02','Arca Çorum FK','Erhan Erentürk','2026-27'),
('P|'||c.id||'|03','Arca Çorum FK','Gökhan Sazdağı','2026-27'),
('P|'||c.id||'|04','Arca Çorum FK','Çağlar Söyüncü','2026-27'),
('P|'||c.id||'|05','Arca Çorum FK','Andrei Borza','2026-27'),
('P|'||c.id||'|06','Arca Çorum FK','Arda Şengül','2026-27'),
('P|'||c.id||'|07','Arca Çorum FK','Cemali Sertel','2026-27'),
('P|'||c.id||'|08','Arca Çorum FK','Serdar Saatçı','2026-27'),
('P|'||c.id||'|09','Arca Çorum FK','Alexandre Penetra','2026-27'),
('P|'||c.id||'|10','Arca Çorum FK','Mohamed Diomande','2026-27'),
('P|'||c.id||'|11','Arca Çorum FK','Göktan Gürpüz','2026-27'),
('P|'||c.id||'|12','Arca Çorum FK','Cengiz Ünder','2026-27'),
('P|'||c.id||'|13','Arca Çorum FK','Berat Özdemir','2026-27'),
('P|'||c.id||'|14','Arca Çorum FK','Markus Karlsbakk','2026-27'),
('P|'||c.id||'|15','Arca Çorum FK','Ahmed Ildiz','2026-27'),
('P|'||c.id||'|16','Arca Çorum FK','Ylber Ramadani','2026-27'),
('P|'||c.id||'|17','Arca Çorum FK','Mame Baba Thiam','2026-27'),
('P|'||c.id||'|18','Arca Çorum FK','Emircan Gürlük','2026-27'),
('P|'||c.id||'|19','Arca Çorum FK','Youssoufa Moukoko','2026-27'),
('P|'||c.id||'|20','Arca Çorum FK','Alexandros Kyziridis','2026-27'),
('P|'||c.id||'|21','Arca Çorum FK','Jesus Ramirez','2026-27'),
('P|'||c.id||'|22','Arca Çorum FK','Hasan Abdulkareem','2026-27')
  ;
end $$;

