-- Applied Supabase migration: player_presentation_polish


-- Project Afyon 0.25b — player presentation polish.
-- Normalize shirt numbers and give the hand-authored parody stars plausible fictional ages.

with shirt_map(slot,shirt) as (
  values
    (1,1),(2,12),(3,2),(4,3),(5,4),(6,5),(7,6),(8,13),(9,14),
    (10,8),(11,10),(12,15),(13,16),(14,20),(15,21),(16,22),
    (17,7),(18,9),(19,11),(20,17),(21,18),(22,19)
)
update public.players p
set shirt_number=m.shirt
from shirt_map m
where p.id like '%|'||lpad(m.slot::text,2,'0');

with stars(display_name,age) as (
  values
    ('Nedersın',33),('Ruben Diash',29),('Rodry Hernan',30),('Kevin De Bruynel',35),('Ervin Halland',26),('Phil Fodenham',26),
    ('Alison Bekk',34),('Virgil Van Dijko',35),('Trent Alex-Arnoldo',28),('Alexis Mac Allisto',27),('Mo Salahh',34),('Darwin Nunezzo',27),
    ('Martin Odegardo',27),('Declan Rize',27),('Bukay Sakaro',25),('Kai Havertzo',27),
    ('Anto Rudigerz',33),('Jude Bellingram',23),('Fede Valvarde',28),('Killian Mbappee',27),('Vinny Juniar',26),('Rodry Goeson',25),
    ('Pedri Gonzalo',23),('Gavi Paezzo',22),('Frenkie De Yongo',29),('Lamal Yamine',19),('Raphin Diaso',29),('Robert Levandorski',38),
    ('Jose Gimenezzo',31),('Koke Resurro',34),('Julian Alvarezo',26),
    ('Manu Neuerer',40),('Joshua Kimmixo',31),('Jamal Musialo',23),('Harry Kaner',33),
    ('Serhu Guirassy',30),('Karim Adeyemio',24),
    ('Aless Bastonio',27),('Nicolo Barello',29),('Hakan Calhanolu',32),('Lauta Martino',29),('Marcus Thuramo',29),
    ('Scot McTomino',29),('Romelu Lukako',33),('Tijjan Reijndro',28),('Rafael Leaon',27),('Dusan Vlahovik',26),
    ('Marquin Hos',32),('Achraf Hakimio',28),('Vitinya Silvao',26),('Ous Dembeleux',29),('Khvicha Kvaratskhelo',25),
    ('Luke De Yung',35),('Kenneth Tayloro',24),('Kokcu Orkuno',25),('Vangel Pavlidiso',28),('Pepe Cardoso',29),('Samu Omorodino',22),
    ('Davinson Sanchezz',30),('Lucas Torrero',30),('Gabriel Sarao',27),('Victy Osimha',27),('Maura Icardo',33),('Baris Alper Yelmazo',26),
    ('Fred Rodrigueso',33),('Talis Kanno',32),('Youssef En Nesyro',29),('Dusan Tadiko',37),
    ('Gedson Fernandesh',27),('Rafa Silvino',33),('Ciro Immobilo',36),('Edin Viskao',36),('Simon Banzaa',30),
    ('Ferran Jutglao',27),('Daizen Meda',29),('Karim Konato',22),('Ayoub El Kaabio',33)
)
update public.players p
set age=s.age,
    potential=greatest(p.overall,
      least(99,p.overall + case when s.age<=21 then 6 when s.age<=24 then 4 when s.age<=27 then 2 else 0 end)
    )
from stars s
where p.display_name=s.display_name;

