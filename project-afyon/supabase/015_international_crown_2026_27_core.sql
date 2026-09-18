-- Applied Supabase migration: international_crown_2026_27_core


-- Project Afyon 0.26b — selected international Crown mirrors, 2026/27.
-- Current official-season analogues for Barcelona, Real Madrid and Manchester City counterparts.

delete from private.player_roster_templates
where season='2026-27' and club_name in ('Catalunya Blau','Madrid Crown','Manchester Sky');

insert into private.player_roster_templates(club_name,slot,source_player_name,parody_name,position,age,nationality)
values
('Catalunya Blau',1,'Joan García','Juan Garçiya','GK',25,'İspanya'),
('Catalunya Blau',2,'Wojciech Szczesny','Wojtek Şeçni','GK',36,'Polonya'),
('Catalunya Blau',3,'João Cancelo','Joao Kanselo','DEF',32,'Portekiz'),
('Catalunya Blau',4,'Alejandro Balde','Alejandro Baldo','DEF',22,'İspanya'),
('Catalunya Blau',5,'Pau Cubarsí','Pau Kubarsi','DEF',19,'İspanya'),
('Catalunya Blau',6,'Brian Fariñas','Brian Farinaso','DEF',20,'İspanya'),
('Catalunya Blau',7,'Andreas Christensen','Andreas Kristenso','DEF',30,'Danimarka'),
('Catalunya Blau',8,'Jules Koundé','Jules Koundeo','DEF',27,'Fransa'),
('Catalunya Blau',9,'Eric García','Erik Garçiya','DEF',25,'İspanya'),
('Catalunya Blau',10,'Gavi','Gavio Paez','MID',22,'İspanya'),
('Catalunya Blau',11,'Fermín López','Fermin Lopezo','MID',23,'İspanya'),
('Catalunya Blau',12,'Pedri','Pedri Gonzalo','MID',23,'İspanya'),
('Catalunya Blau',13,'Rodri','Rodri Hernan','MID',30,'İspanya'),
('Catalunya Blau',14,'Dani Olmo','Dani Olmio','MID',28,'İspanya'),
('Catalunya Blau',15,'Frenkie de Jong','Frenkie De Yongo','MID',29,'Hollanda'),
('Catalunya Blau',16,'Marc Bernal','Marc Bernalo','MID',19,'İspanya'),
('Catalunya Blau',17,'Gabriel Jesus','Gabriel Jesuz','FWD',29,'Brezilya'),
('Catalunya Blau',18,'Lamine Yamal','Lamal Yamine','FWD',19,'İspanya'),
('Catalunya Blau',19,'Raphinha','Raphin Diaso','FWD',29,'Brezilya'),
('Catalunya Blau',20,'Karim Adeyemi','Karim Adeyemio','FWD',24,'Almanya'),
('Catalunya Blau',21,'Anthony Gordon','Antony Gordono','FWD',25,'İngiltere'),
('Catalunya Blau',22,'Roony Bardghji','Runi Bardghio','FWD',20,'İsveç'),
('Madrid Crown',1,'Thibaut Courtois','Tibo Kurtois','GK',34,'Belçika'),
('Madrid Crown',2,'Andriy Lunin','Andri Lunino','GK',27,'Ukrayna'),
('Madrid Crown',3,'Dean Huijsen','Dean Huyseno','DEF',21,'İspanya'),
('Madrid Crown',4,'Trent Alexander-Arnold','Trent Alex-Arnoldo','DEF',27,'İngiltere'),
('Madrid Crown',5,'Ibrahima Konaté','Ibrahima Konato','DEF',27,'Fransa'),
('Madrid Crown',6,'Marc Cucurella','Marc Kukurella','DEF',28,'İspanya'),
('Madrid Crown',7,'Álvaro Carreras','Alvaro Karreras','DEF',23,'İspanya'),
('Madrid Crown',8,'Antonio Rüdiger','Anto Rudigerz','DEF',33,'Almanya'),
('Madrid Crown',9,'Denzel Dumfries','Denzel Dumfrieso','DEF',30,'Hollanda'),
('Madrid Crown',10,'Jude Bellingham','Jude Bellingram','MID',23,'İngiltere'),
('Madrid Crown',11,'Eduardo Camavinga','Edu Camavingo','MID',23,'Fransa'),
('Madrid Crown',12,'Federico Valverde','Fede Valvarde','MID',28,'Uruguay'),
('Madrid Crown',13,'Aurélien Tchouaméni','Aurel Çuameno','MID',26,'Fransa'),
('Madrid Crown',14,'Arda Güler','Arda Gülero','MID',21,'Türkiye'),
('Madrid Crown',15,'Bernardo Silva','Bernardo Silvo','MID',32,'Portekiz'),
('Madrid Crown',16,'Thiago Pitarch','Thiago Pitarko','MID',19,'İspanya'),
('Madrid Crown',17,'Vinícius Júnior','Vinny Juniar','FWD',26,'Brezilya'),
('Madrid Crown',18,'Endrick','Endriko','FWD',20,'Brezilya'),
('Madrid Crown',19,'Kylian Mbappé','Killian Mbappee','FWD',27,'Fransa'),
('Madrid Crown',20,'César Espi','Cesar Espino','FWD',21,'İspanya'),
('Madrid Crown',21,'Brahim Díaz','Brahim Diazo','FWD',27,'Fas'),
('Madrid Crown',22,'Yan Diomande','Yan Diomando','FWD',19,'Fildişi Sahili'),
('Manchester Sky',1,'Gianluigi Donnarumma','Gianlu Donnarumo','GK',27,'İtalya'),
('Manchester Sky',2,'Gerónimo Rulli','Geronimo Rullio','GK',34,'Arjantin'),
('Manchester Sky',3,'Rúben Dias','Ruben Diash','DEF',29,'Portekiz'),
('Manchester Sky',4,'Marc Guéhi','Marc Guehio','DEF',26,'İngiltere'),
('Manchester Sky',5,'Rayan Aït-Nouri','Rayan Ait-Nourio','DEF',25,'Cezayir'),
('Manchester Sky',6,'Joško Gvardiol','Josko Gvardiolo','DEF',24,'Hırvatistan'),
('Manchester Sky',7,'Abdukodir Khusanov','Abdu Khusanovo','DEF',22,'Özbekistan'),
('Manchester Sky',8,'Rico Lewis','Rico Lewiso','DEF',21,'İngiltere'),
('Manchester Sky',9,'Vitor Reis','Vitor Reiso','DEF',20,'Brezilya'),
('Manchester Sky',10,'Elliot Anderson','Elliot Anderso','MID',23,'İngiltere'),
('Manchester Sky',11,'Mateo Kovačić','Mateo Kovaciko','MID',32,'Hırvatistan'),
('Manchester Sky',12,'Rayan Cherki','Rayan Cherkio','MID',23,'Fransa'),
('Manchester Sky',13,'Enzo Fernández','Enzo Fernandesh','MID',25,'Arjantin'),
('Manchester Sky',14,'Matheus Nunes','Matheus Nunezo','MID',28,'Portekiz'),
('Manchester Sky',15,'Ayyoub Bouaddi','Ayyoub Bouaddio','MID',18,'Fransa'),
('Manchester Sky',16,'Nico O''Reilly','Nico O''Reillyo','MID',21,'İngiltere'),
('Manchester Sky',17,'Iliman Ndiaye','Iliman Ndiayen','FWD',26,'Senegal'),
('Manchester Sky',18,'Erling Haaland','Ervin Halland','FWD',26,'Norveç'),
('Manchester Sky',19,'Jérémy Doku','Jeremy Dokou','FWD',24,'Belçika'),
('Manchester Sky',20,'Allan Elias','Allan Eliasso','FWD',22,'Brezilya'),
('Manchester Sky',21,'Antoine Semenyo','Antoine Semenyo','FWD',26,'Gana'),
('Manchester Sky',22,'Phil Foden','Phil Fodenham','FWD',26,'İngiltere');

with t as (
 select r.*,c.id club_id,c.overall club_overall
 from private.player_roster_templates r
 join public.clubs c on c.name=r.club_name
 where r.season='2026-27' and r.club_name in ('Catalunya Blau','Madrid Crown','Manchester Sky')
),
rated as (
 select t.*,
 case position
  when 'GK' then case slot when 1 then 1 else -3 end
  when 'DEF' then (array[3,2,1,0,-1,-2,-3])[slot-2]
  when 'MID' then (array[4,3,2,1,0,-2,-3])[slot-9]
  when 'FWD' then (array[5,3,2,0,-2,-3])[slot-16]
 end delta
 from t
)
update public.players p
set display_name=r.parody_name,
 source_player_name=r.source_player_name,
 position=r.position,nationality=r.nationality,age=r.age,
 overall=greatest(20,least(97,round(r.club_overall)::int+r.delta)),
 potential=greatest(greatest(20,least(97,round(r.club_overall)::int+r.delta)),
   least(99,greatest(20,least(97,round(r.club_overall)::int+r.delta))+
    case when r.age<=21 then 6 when r.age<=24 then 4 when r.age<=27 then 2 else 0 end)),
 roster_season='2026-27',is_parody=true,is_star_parody=true,is_roster_mirror=true
from rated r
where p.club_id=r.club_id and regexp_replace(p.id,'^.*\|','')::int=r.slot;

-- Prevent duplicate generated names inside the same non-mirrored club.
with d as (
 select id,display_name,club_id,
   row_number() over(partition by club_id,display_name order by id) rn,
   chr(65+((hashtextextended(id,73)&9223372036854775807)%26)::int) initial
 from public.players
 where is_roster_mirror=false
),
fix as (
 select id,
   split_part(display_name,' ',1)||' '||initial||'. '||
   substring(display_name from position(' ' in display_name)+1) new_name
 from d where rn>1
)
update public.players p set display_name=f.new_name
from fix f where p.id=f.id;

update public.players p
set
 finishing=greatest(20,least(99,p.overall+case p.position when 'FWD' then 7 when 'MID' then 1 when 'DEF' then -9 else -25 end)),
 passing=greatest(20,least(99,p.overall+case p.position when 'MID' then 6 when 'FWD' then 1 when 'DEF' then 1 else -4 end)),
 dribbling=greatest(20,least(99,p.overall+case p.position when 'FWD' then 4 when 'MID' then 4 when 'DEF' then -5 else -20 end)),
 tackling=greatest(20,least(99,p.overall+case p.position when 'DEF' then 7 when 'MID' then 1 when 'FWD' then -8 else -12 end)),
 pace=greatest(20,least(99,p.overall+case p.position when 'FWD' then 4 when 'DEF' then 1 when 'MID' then 0 else -8 end)),
 strength=greatest(20,least(99,p.overall+case p.position when 'DEF' then 4 when 'FWD' then 2 when 'GK' then 1 else 0 end)),
 goalkeeping=greatest(20,least(99,p.overall+case p.position when 'GK' then 8 else -32 end))
where p.club_id in (
 select id from public.clubs where name in ('Catalunya Blau','Madrid Crown','Manchester Sky')
);

