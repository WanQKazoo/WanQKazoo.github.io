-- Applied Supabase migration: player_universe


-- Project Afyon 0.25 — Player Universe
-- 23,760 persistent fictional players: 22 per club.
-- Crown League squads use parody-style names; lower divisions use fictional names.

create table if not exists public.players (
  id text primary key,
  club_id text not null references public.clubs(id) on delete cascade,
  shirt_number smallint not null check (shirt_number between 1 and 99),
  display_name text not null,
  position text not null check (position in ('GK','DEF','MID','FWD')),
  nationality text not null,
  age smallint not null check (age between 16 and 45),
  overall smallint not null check (overall between 20 and 99),
  potential smallint not null check (potential between 20 and 99),
  form smallint not null default 60 check (form between 0 and 100),
  morale smallint not null default 65 check (morale between 0 and 100),
  fitness smallint not null default 100 check (fitness between 0 and 100),
  injury_weeks smallint not null default 0 check (injury_weeks between 0 and 52),
  contract_until_season smallint not null,
  wage bigint not null default 0 check (wage >= 0),
  market_value bigint not null default 0 check (market_value >= 0),
  finishing smallint not null check (finishing between 20 and 99),
  passing smallint not null check (passing between 20 and 99),
  dribbling smallint not null check (dribbling between 20 and 99),
  tackling smallint not null check (tackling between 20 and 99),
  pace smallint not null check (pace between 20 and 99),
  strength smallint not null check (strength between 20 and 99),
  goalkeeping smallint not null check (goalkeeping between 20 and 99),
  is_parody boolean not null default false,
  created_at timestamptz not null default now(),
  unique(club_id,shirt_number)
);

alter table public.players enable row level security;

drop policy if exists "players_read_all" on public.players;
create policy "players_read_all"
on public.players for select
to anon,authenticated
using (true);

revoke all on public.players from anon,authenticated;
grant select on public.players to anon,authenticated;

create index if not exists players_club_idx on public.players(club_id);
create index if not exists players_overall_idx on public.players(overall desc);
create index if not exists players_position_idx on public.players(position);

with star_parodies(club_name,slot,parody_name) as (
  values
    ('Manchester Sky',1,'Nedersın'),
    ('Manchester Sky',4,'Ruben Diash'),
    ('Manchester Sky',11,'Rodry Hernan'),
    ('Manchester Sky',12,'Kevin De Bruynel'),
    ('Manchester Sky',17,'Ervin Halland'),
    ('Manchester Sky',18,'Phil Fodenham'),

    ('Mersey Reds',1,'Alison Bekk'),
    ('Mersey Reds',4,'Virgil Van Dijko'),
    ('Mersey Reds',7,'Trent Alex-Arnoldo'),
    ('Mersey Reds',12,'Alexis Mac Allisto'),
    ('Mersey Reds',17,'Mo Salahh'),
    ('Mersey Reds',18,'Darwin Nunezzo'),

    ('North London Cannons',10,'Martin Odegardo'),
    ('North London Cannons',11,'Declan Rize'),
    ('North London Cannons',17,'Bukay Sakaro'),
    ('North London Cannons',18,'Kai Havertzo'),

    ('Madrid Crown',4,'Anto Rudigerz'),
    ('Madrid Crown',10,'Jude Bellingram'),
    ('Madrid Crown',11,'Fede Valvarde'),
    ('Madrid Crown',17,'Killian Mbappee'),
    ('Madrid Crown',18,'Vinny Juniar'),
    ('Madrid Crown',19,'Rodry Goeson'),

    ('Catalunya Blau',10,'Pedri Gonzalo'),
    ('Catalunya Blau',11,'Gavi Paezzo'),
    ('Catalunya Blau',12,'Frenkie De Yongo'),
    ('Catalunya Blau',17,'Lamal Yamine'),
    ('Catalunya Blau',18,'Raphin Diaso'),
    ('Catalunya Blau',19,'Robert Levandorski'),

    ('Madrid Red Stripe',4,'Jose Gimenezzo'),
    ('Madrid Red Stripe',10,'Koke Resurro'),
    ('Madrid Red Stripe',17,'Julian Alvarezo'),

    ('Munich Redworks',1,'Manu Neuerer'),
    ('Munich Redworks',6,'Joshua Kimmixo'),
    ('Munich Redworks',11,'Jamal Musialo'),
    ('Munich Redworks',17,'Harry Kaner'),

    ('Dortmund Yellow Wall',17,'Serhu Guirassy'),
    ('Dortmund Yellow Wall',18,'Karim Adeyemio'),

    ('Milano Serpents',5,'Aless Bastonio'),
    ('Milano Serpents',11,'Nicolo Barello'),
    ('Milano Serpents',12,'Hakan Calhanolu'),
    ('Milano Serpents',17,'Lauta Martino'),
    ('Milano Serpents',18,'Marcus Thuramo'),

    ('Napoli Vespa',11,'Scot McTomino'),
    ('Napoli Vespa',17,'Romelu Lukako'),

    ('Milano Rosso',10,'Tijjan Reijndro'),
    ('Milano Rosso',17,'Rafael Leaon'),

    ('Torino Zebras',17,'Dusan Vlahovik'),

    ('Paris Étoile',4,'Marquin Hos'),
    ('Paris Étoile',7,'Achraf Hakimio'),
    ('Paris Étoile',11,'Vitinya Silvao'),
    ('Paris Étoile',17,'Ous Dembeleux'),
    ('Paris Étoile',18,'Khvicha Kvaratskhelo'),

    ('Eindhoven Lamps',17,'Luke De Yung'),
    ('Amsterdam Masters',10,'Kenneth Tayloro'),

    ('Lisboa Eagles',10,'Kokcu Orkuno'),
    ('Lisboa Eagles',17,'Vangel Pavlidiso'),
    ('Porto Azure',4,'Pepe Cardoso'),
    ('Porto Azure',17,'Samu Omorodino'),

    ('Galata Aslanları',4,'Davinson Sanchezz'),
    ('Galata Aslanları',10,'Lucas Torrero'),
    ('Galata Aslanları',11,'Gabriel Sarao'),
    ('Galata Aslanları',17,'Victy Osimha'),
    ('Galata Aslanları',18,'Maura Icardo'),
    ('Galata Aslanları',19,'Baris Alper Yelmazo'),

    ('Kadıköy Feneri',10,'Fred Rodrigueso'),
    ('Kadıköy Feneri',11,'Talis Kanno'),
    ('Kadıköy Feneri',17,'Youssef En Nesyro'),
    ('Kadıköy Feneri',18,'Dusan Tadiko'),

    ('Boğaziçi Kartalları',10,'Gedson Fernandesh'),
    ('Boğaziçi Kartalları',11,'Rafa Silvino'),
    ('Boğaziçi Kartalları',17,'Ciro Immobilo'),

    ('Karadeniz Fırtınası',10,'Edin Viskao'),
    ('Karadeniz Fırtınası',17,'Simon Banzaa'),

    ('Bruges Blackblue',17,'Ferran Jutglao'),
    ('Glasgow Hoops',17,'Daizen Meda'),
    ('Salzburg Energy',17,'Karim Konato'),
    ('Piraeus Red',17,'Ayoub El Kaabio')
),
slots as (
  select c.*, gs as slot,
    case
      when gs<=2 then 'GK'
      when gs<=9 then 'DEF'
      when gs<=16 then 'MID'
      else 'FWD'
    end as position,
    (hashtextextended(c.id||'|'||gs::text,0) & 9223372036854775807) as h
  from public.clubs c
  cross join generate_series(1,22) gs
),
named as (
  select
    s.*,
    sp.parody_name,
    case when s.league_level=1 then true else false end as is_parody,
    case
      when s.league_level=1 then
        (
          array[
            'Lional','Cristo','Killian','Ervin','Jude','Vinny','Lamal','Victy','Maura','Moha',
            'Kevin','Bruno','Marcus','Virgil','Trent','Phil','Cole','Bukay','Rodry','Pedri',
            'Gavi','Raphin','Robert','Lauta','Khvicha','Ous','Achraf','Jamal','Harry','Joshua',
            'Manu','Nicolo','Hakan','Dusan','Romelu','Scot','Frenkie','Ruben','Anto','Fede',
            'Theo','Rafael','Bernar','Joao','Victor','Martin','Declan','Kai','Alexis','Julian'
          ]
        )[1 + ((s.h + s.slot*7) % 50)::int]
        || ' ' ||
        (
          array[
            'Messio','Ronaldy','Mbappee','Halland','Bellingram','Juniar','Yamine','Osimha','Icardo','Salahh',
            'De Bruynel','Fernandesh','Rashfordo','Van Dijko','Arnoldo','Fodenham','Palmero','Sakaro','Goeson','Gonzalo',
            'Paezzo','Diaso','Levandorski','Martino','Kvaratskhelo','Dembeleux','Hakimio','Musialo','Kaner','Kimmixo',
            'Neuerer','Barello','Calhanolu','Vlahovik','Lukako','McTomino','De Yongo','Di Mario','Guirassy','Valvarde',
            'Rodrigoz','Rudigerz','Leaon','Alvarezo','Odegardo','Havertzo','Nunezzo','Bekk','Thuramo','Silvao'
          ]
        )[1 + ((s.h/53 + s.slot*11) % 50)::int]
      else
        (
          array[
            'Arda','Mert','Emir','Kerem','Eren','Deniz','Can','Bora','Luca','Marco',
            'Leo','Nico','Tomas','Milan','Jonas','Felix','Noah','Oscar','Hugo','Rui',
            'Tiago','Bruno','Yannis','Kostas','Liam','Jamie','Callum','Finn','Louis','Adrien',
            'Daan','Jelle','Mats','Lars','Pablo','Diego','Sergio','Ivan','Mateo','Andre'
          ]
        )[1 + ((s.h + s.slot*3) % 40)::int]
        || ' ' ||
        (
          array[
            'Aydin','Kaya','Demir','Yildiz','Arslan','Cetin','Koc','Acar','Silva','Costa',
            'Pereira','Santos','Martin','Lopez','Ramos','Garcia','Weber','Klein','Fischer','Wagner',
            'Rossi','Bianchi','Romano','Conti','Dubois','Bernard','Moreau','Petit','De Vries','Bakker',
            'Jansen','Smit','Brown','Wilson','Taylor','Campbell','Papadakis','Nikolaou','Maes','Peeters'
          ]
        )[1 + ((s.h/41 + s.slot*5) % 40)::int]
    end as generated_name
  from slots s
  left join star_parodies sp on sp.club_name=s.name and sp.slot=s.slot
),
ratings as (
  select
    n.*,
    greatest(20,least(97,
      round(n.overall)::int +
      case
        when n.parody_name is not null then
          case n.position when 'FWD' then 4 when 'MID' then 3 when 'DEF' then 2 else 2 end
        else ((n.h/101)%11)::int-5
      end
    )) as player_overall,
    (18 + ((n.h/1009)%17)::int) as player_age
  from named n
)
insert into public.players(
  id,club_id,shirt_number,display_name,position,nationality,age,overall,potential,
  form,morale,fitness,injury_weeks,contract_until_season,wage,market_value,
  finishing,passing,dribbling,tackling,pace,strength,goalkeeping,is_parody
)
select
  'P|'||r.id||'|'||lpad(r.slot::text,2,'0'),
  r.id,
  case
    when r.slot=1 then 1 when r.slot=2 then 12
    when r.slot<=9 then r.slot+1
    when r.slot<=16 then r.slot+10
    else r.slot+20
  end,
  coalesce(r.parody_name,r.generated_name),
  r.position,
  r.country,
  r.player_age,
  r.player_overall,
  greatest(r.player_overall,least(99,
    r.player_overall +
    case
      when r.player_age<=21 then 5+((r.h/701)%5)::int
      when r.player_age<=24 then 2+((r.h/701)%4)::int
      when r.player_age<=28 then ((r.h/701)%3)::int
      else 0
    end
  )),
  50+((r.h/307)%26)::int,
  55+((r.h/401)%31)::int,
  88+((r.h/503)%13)::int,
  0,
  1+1+((r.h/607)%4)::int,
  greatest(250,
    round(
      r.player_overall*r.player_overall *
      case r.league_level when 1 then 35 when 2 then 15 when 3 then 7 when 4 then 3 else 1 end
    )::bigint
  ),
  greatest(1000,
    round(
      power(r.player_overall::numeric,3) *
      case r.league_level when 1 then 140 when 2 then 55 when 3 then 22 when 4 then 8 else 3 end
    )::bigint
  ),
  greatest(20,least(99,r.player_overall + case r.position when 'FWD' then 7 when 'MID' then 1 when 'DEF' then -9 else -25 end + (((r.h/809)%5)::int-2))),
  greatest(20,least(99,r.player_overall + case r.position when 'MID' then 6 when 'FWD' then 1 when 'DEF' then 1 else -4 end + (((r.h/811)%5)::int-2))),
  greatest(20,least(99,r.player_overall + case r.position when 'FWD' then 4 when 'MID' then 4 when 'DEF' then -5 else -20 end + (((r.h/821)%5)::int-2))),
  greatest(20,least(99,r.player_overall + case r.position when 'DEF' then 7 when 'MID' then 1 when 'FWD' then -8 else -12 end + (((r.h/823)%5)::int-2))),
  greatest(20,least(99,r.player_overall + case r.position when 'FWD' then 4 when 'DEF' then 1 when 'MID' then 0 else -8 end + (((r.h/827)%5)::int-2))),
  greatest(20,least(99,r.player_overall + case r.position when 'DEF' then 4 when 'FWD' then 2 when 'GK' then 1 else 0 end + (((r.h/829)%5)::int-2))),
  greatest(20,least(99,r.player_overall + case r.position when 'GK' then 8 else -32 end + (((r.h/839)%5)::int-2))),
  r.is_parody
from ratings r
on conflict(id) do update set
  club_id=excluded.club_id,
  shirt_number=excluded.shirt_number,
  display_name=excluded.display_name,
  position=excluded.position,
  nationality=excluded.nationality,
  age=excluded.age,
  overall=excluded.overall,
  potential=excluded.potential,
  form=excluded.form,
  morale=excluded.morale,
  fitness=excluded.fitness,
  injury_weeks=excluded.injury_weeks,
  contract_until_season=excluded.contract_until_season,
  wage=excluded.wage,
  market_value=excluded.market_value,
  finishing=excluded.finishing,
  passing=excluded.passing,
  dribbling=excluded.dribbling,
  tackling=excluded.tackling,
  pace=excluded.pace,
  strength=excluded.strength,
  goalkeeping=excluded.goalkeeping,
  is_parody=excluded.is_parody;

