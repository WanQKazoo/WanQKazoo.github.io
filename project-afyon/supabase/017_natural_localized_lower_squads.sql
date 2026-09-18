-- Applied Supabase migration: natural_localized_lower_squads


-- Project Afyon 0.26c — natural localized lower-division squads.
-- Levels 2-5: 20 local players + 2 foreign players per 22-man squad.
-- Avoid duplicate/initial-patched names inside a club.

with base as (
  select
    p.id,p.club_id,c.country,c.league_level,
    regexp_replace(p.id,'^.*\|','')::int as slot,
    (hashtextextended(p.club_id,101) & 9223372036854775807) as ch,
    (regexp_replace(p.id,'^.*\|','')::int in (8,18)) as foreign_slot
  from public.players p
  join public.clubs c on c.id=p.club_id
  where c.league_level between 2 and 5
),
ranked as (
  select b.*,
    case when not foreign_slot then
      row_number() over(partition by club_id,foreign_slot order by slot)-1
    else
      row_number() over(partition by club_id,foreign_slot order by slot)-1
    end as local_idx
  from base b
),
pools as (
  select r.*,
    case country
      when 'Türkiye' then array['Aras','Ali','Poyraz','Mert','Emir','Kerem','Eren','Bora','Doruk','Can','Yiğit','Oğuz','Kaan','Umut','Baran','Berke','Deniz','Tuna','Efe','Alp','Cem','Onur','Ulaş','Berk']
      when 'İngiltere' then array['Jack','Harry','Oliver','George','Alfie','Charlie','Liam','Mason','Ethan','Callum','Jamie','Lewis','Archie','Finley','Theo','Max','Ben','Sam','Reece','Owen','Harvey','Luke','Joe','Ryan']
      when 'İspanya' then array['Mateo','Hugo','Pablo','Diego','Sergio','Iker','Adrian','Alejandro','Nico','Ivan','Raul','Javi','Marco','Dani','Alex','Mario','Unai','Leo','Alvaro','Marcos','Jorge','Jaime','Ruben','Carlos']
      when 'Almanya' then array['Lukas','Jonas','Felix','Maximilian','Leon','Niklas','Florian','Julian','Timo','Moritz','Finn','Paul','Anton','David','Noah','Emil','Mats','Kai','Simon','Fabian','Tim','Jan','Nico','Sebastian']
      when 'İtalya' then array['Luca','Marco','Matteo','Andrea','Federico','Nicolo','Alessio','Davide','Simone','Tommaso','Riccardo','Gabriele','Pietro','Lorenzo','Filippo','Edoardo','Samuele','Elia','Giulio','Daniele','Mattia','Fabio','Stefano','Giacomo']
      when 'Fransa' then array['Theo','Hugo','Lucas','Jules','Louis','Adrien','Mathis','Enzo','Maxime','Antoine','Noe','Rayan','Yanis','Kylian','Bastien','Remy','Axel','Loic','Nolan','Eliott','Clement','Valentin','Quentin','Gael']
      when 'Hollanda' then array['Daan','Jesse','Lars','Mats','Sem','Thijs','Luuk','Bram','Mees','Jelle','Sven','Niels','Teun','Wout','Koen','Joep','Finn','Timo','Stijn','Joris','Ruben','Sander','Jens','Pepijn']
      when 'Portekiz' then array['Tiago','Rui','Joao','Diogo','Goncalo','Andre','Miguel','Pedro','Tomas','Nuno','Afonso','Ricardo','Bruno','Fabio','Duarte','Vasco','Henrique','Luis','Gustavo','Martim','Rodrigo','Francisco','Leandro','Rafael']
      when 'Belçika' then array['Arthur','Louis','Jules','Mathis','Noah','Victor','Milan','Seppe','Lars','Wout','Robbe','Jarne','Tibo','Maxime','Niels','Bram','Lucas','Emile','Mathieu','Jelle','Senne','Ruben','Nathan','Thomas']
      when 'İskoçya' then array['Callum','Lewis','Ryan','Scott','Jamie','Ross','Ewan','Finlay','Connor','Liam','Craig','Fraser','Dylan','Jack','Cameron','Kieran','Aidan','Rory','Calum','Blair','Logan','Kyle','Sean','Andrew']
      when 'Yunanistan' then array['Nikos','Giorgos','Dimitris','Kostas','Manolis','Petros','Vasilis','Alexis','Stavros','Yannis','Thanos','Michalis','Andreas','Sotiris','Christos','Panos','Spiros','Leonidas','Antonis','Giorgos','Lefteris','Kostas','Marios','Fotis']
      when 'Avusturya' then array['Lukas','Florian','Dominik','Matthias','Sebastian','Felix','Jakob','David','Simon','Tobias','Moritz','Paul','Maximilian','Niklas','Fabian','Leon','Alexander','Julian','Stefan','Michael','Daniel','Thomas','Martin','Christoph']
      else array['Alex','Leo','Max','Nico','Sam','Tom','Dan','Ben','Kai','Ian','Noah','Liam','Theo','Milo','Eli','Oli','Jan','Luca','Ryan','Marco','David','Paul','Eric','Joel']
    end as firsts,
    case country
      when 'Türkiye' then array['Demir','Kaya','Aydın','Yıldız','Arslan','Çetin','Koç','Şahin','Aksoy','Kurt','Öztürk','Karaca','Güneş','Duman','Erdem','Bulut','Tekin','Keskin','Polat','Avcı','Ekinci','Taş','Yalçın','Güler']
      when 'İngiltere' then array['Baker','Turner','Cooper','Walker','Parker','Foster','Carter','Miller','Wilson','Taylor','Collins','Morgan','Hughes','Bennett','Ward','Reed','Hall','Brooks','Shaw','Bailey','Wood','Gray','Young','King']
      when 'İspanya' then array['Ruiz','Navarro','Santos','Molina','Vega','Ramos','Ortega','Castro','Iglesias','Moreno','Soler','Cano','Rojas','Vidal','Mendez','Prieto','Lozano','Cruz','Serrano','Reyes','Moya','Cortes','Pascual','Calvo']
      when 'Almanya' then array['Weber','Klein','Fischer','Wagner','Krause','Becker','Schulz','Wolf','Hartmann','Vogel','Keller','Bauer','Neumann','Brandt','Kuhn','Jager','Maier','Stein','Hoffmann','Schmidt','Kruger','Lorenz','Kaiser','Busch']
      when 'İtalya' then array['Romano','Bianchi','Conti','Rossi','Ferrari','Gallo','Costa','Moretti','Lombardi','Greco','Marino','Rinaldi','Caruso','Vitale','De Luca','Serra','Fontana','Leone','Martini','Ricci','Villa','Ferri','Grassi','Fiore']
      when 'Fransa' then array['Bernard','Moreau','Petit','Dubois','Leroy','Roux','Fontaine','Mercier','Garnier','Chevalier','Blanc','Robin','Perrot','Masson','Colin','Renard','Barbier','Marchand','Giraud','Perrin','Benoit','Caron','Meyer','Henry']
      when 'Hollanda' then array['de Vries','Bakker','Jansen','Smit','Visser','de Boer','Mulder','Meijer','Bos','Vos','Dekker','Dijkstra','Kuiper','de Jong','Vermeer','Koster','van Dijk','Hoek','Prins','Scholten','Kok','Mol','Post','Vink']
      when 'Portekiz' then array['Silva','Costa','Pereira','Santos','Ferreira','Rodrigues','Oliveira','Sousa','Martins','Almeida','Correia','Teixeira','Rocha','Neves','Coelho','Mendes','Pinto','Ribeiro','Carvalho','Nunes','Lopes','Gomes','Monteiro','Barbosa']
      when 'Belçika' then array['Peeters','Maes','Jacobs','Willems','Mertens','Claes','Goossens','Wouters','Vermeulen','Aerts','De Smet','Vandamme','Vercauteren','Lemmens','Devos','Dierckx','Baert','Verhoeven','De Vos','Vermeire','Geerts','Martens','De Clercq','Vercammen']
      when 'İskoçya' then array['MacLeod','Campbell','Stewart','Murray','Fraser','McKay','Hamilton','Robertson','Douglas','Graham','Ferguson','Kerr','Morrison','Cameron','Johnston','Sinclair','Munro','Boyd','McLean','Scott','Anderson','Grant','Ross','Paterson']
      when 'Yunanistan' then array['Papadopoulos','Nikolaou','Georgiou','Vlachos','Pappas','Kostas','Manolas','Raptis','Karalis','Zafeiris','Kouris','Theodorou','Markou','Sarris','Loukas','Tzimas','Vrettos','Dimas','Karras','Lazarou','Stavrou','Kotsis','Vasilou','Mavros']
      when 'Avusturya' then array['Gruber','Huber','Bauer','Wagner','Moser','Steiner','Hofer','Berger','Fuchs','Leitner','Eder','Schmid','Mayr','Pichler','Koller','Auer','Winter','Hauser','Egger','Binder','Lang','Reiter','Winkler','Kern']
      else array['Smith','Silva','Costa','Martin','Rossi','Weber','Santos','Brown','Taylor','Lopez','Muller','Garcia','Wilson','Pereira','Jones','Mendes','Klein','Moreau','Walker','King','Young','Hill','Green','Wood']
    end as lasts
  from ranked r
),
built as (
  select p.*,
    case
      when foreign_slot then
        (array['Lucas Pereira','Mamadou Diallo','Luka Petrovic','Youssef Benali','Ibrahim Traore','Nico Jovic','Samuel Mensah','Rayan Kone','Dario Rossi','Mateo Costa','Noah Ndiaye','Leo Mendes'])[1+((ch + local_idx*5)%12)::int]
      else
        firsts[1+((ch + local_idx)::bigint % array_length(firsts,1))::int]
        || ' ' ||
        lasts[1+(((ch/29) + local_idx*7)::bigint % array_length(lasts,1))::int]
    end as new_name,
    case
      when not foreign_slot then country
      else
        (array['Brezilya','Senegal','Sırbistan','Fas','Fildişi Sahili','Hırvatistan','Gana','Nijerya','İtalya','Portekiz','Fransa','İspanya'])[1+((ch + local_idx*5)%12)::int]
    end as new_nat
  from pools p
)
update public.players p
set display_name=b.new_name,
    nationality=b.new_nat,
    is_parody=true,
    is_star_parody=false,
    is_roster_mirror=false,
    roster_season='2026-27'
from built b
where p.id=b.id;

