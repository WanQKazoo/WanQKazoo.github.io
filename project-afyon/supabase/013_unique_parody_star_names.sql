-- Applied Supabase migration: unique_parody_star_names


alter table public.players
  add column if not exists is_star_parody boolean not null default false;

with stars(club_name,display_name) as (
  values
    ('Manchester Sky','Nedersın'),('Manchester Sky','Ruben Diash'),('Manchester Sky','Rodry Hernan'),('Manchester Sky','Kevin De Bruynel'),('Manchester Sky','Ervin Halland'),('Manchester Sky','Phil Fodenham'),
    ('Mersey Reds','Alison Bekk'),('Mersey Reds','Virgil Van Dijko'),('Mersey Reds','Trent Alex-Arnoldo'),('Mersey Reds','Alexis Mac Allisto'),('Mersey Reds','Mo Salahh'),('Mersey Reds','Darwin Nunezzo'),
    ('North London Cannons','Martin Odegardo'),('North London Cannons','Declan Rize'),('North London Cannons','Bukay Sakaro'),('North London Cannons','Kai Havertzo'),
    ('Madrid Crown','Anto Rudigerz'),('Madrid Crown','Jude Bellingram'),('Madrid Crown','Fede Valvarde'),('Madrid Crown','Killian Mbappee'),('Madrid Crown','Vinny Juniar'),('Madrid Crown','Rodry Goeson'),
    ('Catalunya Blau','Pedri Gonzalo'),('Catalunya Blau','Gavi Paezzo'),('Catalunya Blau','Frenkie De Yongo'),('Catalunya Blau','Lamal Yamine'),('Catalunya Blau','Raphin Diaso'),('Catalunya Blau','Robert Levandorski'),
    ('Madrid Red Stripe','Jose Gimenezzo'),('Madrid Red Stripe','Koke Resurro'),('Madrid Red Stripe','Julian Alvarezo'),
    ('Munich Redworks','Manu Neuerer'),('Munich Redworks','Joshua Kimmixo'),('Munich Redworks','Jamal Musialo'),('Munich Redworks','Harry Kaner'),
    ('Dortmund Yellow Wall','Serhu Guirassy'),('Dortmund Yellow Wall','Karim Adeyemio'),
    ('Milano Serpents','Aless Bastonio'),('Milano Serpents','Nicolo Barello'),('Milano Serpents','Hakan Calhanolu'),('Milano Serpents','Lauta Martino'),('Milano Serpents','Marcus Thuramo'),
    ('Napoli Vespa','Scot McTomino'),('Napoli Vespa','Romelu Lukako'),('Milano Rosso','Tijjan Reijndro'),('Milano Rosso','Rafael Leaon'),('Torino Zebras','Dusan Vlahovik'),
    ('Paris Étoile','Marquin Hos'),('Paris Étoile','Achraf Hakimio'),('Paris Étoile','Vitinya Silvao'),('Paris Étoile','Ous Dembeleux'),('Paris Étoile','Khvicha Kvaratskhelo'),
    ('Eindhoven Lamps','Luke De Yung'),('Amsterdam Masters','Kenneth Tayloro'),
    ('Lisboa Eagles','Kokcu Orkuno'),('Lisboa Eagles','Vangel Pavlidiso'),('Porto Azure','Pepe Cardoso'),('Porto Azure','Samu Omorodino'),
    ('Galata Aslanları','Davinson Sanchezz'),('Galata Aslanları','Lucas Torrero'),('Galata Aslanları','Gabriel Sarao'),('Galata Aslanları','Victy Osimha'),('Galata Aslanları','Maura Icardo'),('Galata Aslanları','Baris Alper Yelmazo'),
    ('Kadıköy Feneri','Fred Rodrigueso'),('Kadıköy Feneri','Talis Kanno'),('Kadıköy Feneri','Youssef En Nesyro'),('Kadıköy Feneri','Dusan Tadiko'),
    ('Boğaziçi Kartalları','Gedson Fernandesh'),('Boğaziçi Kartalları','Rafa Silvino'),('Boğaziçi Kartalları','Ciro Immobilo'),
    ('Karadeniz Fırtınası','Edin Viskao'),('Karadeniz Fırtınası','Simon Banzaa'),
    ('Bruges Blackblue','Ferran Jutglao'),('Glasgow Hoops','Daizen Meda'),('Salzburg Energy','Karim Konato'),('Piraeus Red','Ayoub El Kaabio')
)
update public.players p
set is_star_parody=true
from public.clubs c
join stars s on s.club_name=c.name
where p.club_id=c.id and p.display_name=s.display_name;

update public.players p
set display_name =
  split_part(p.display_name,' ',1)
  || ' ' ||
  chr(65 + ((hashtextextended(p.club_id||'|'||p.id,7) & 9223372036854775807) % 26)::int)
  || '. ' ||
  substring(p.display_name from position(' ' in p.display_name)+1)
where p.is_parody=true and p.is_star_parody=false;

