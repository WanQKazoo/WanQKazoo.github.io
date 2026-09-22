-- Project Afyon 053 — Sergio Costa -> Mert Berk Parsak
-- Preserve fighter id, record, ranking, bouts and all historical references.

update public.boxing_fighters
set
  name='Mert Berk Parsak',
  country='Türkiye',
  updated_at=now()
where id='BX|LHW|T2';
