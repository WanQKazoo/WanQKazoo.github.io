-- Project Afyon 0.51.1 — reconcile Fight Night engine
-- Production briefly received a duplicate experimental boxing scheduler.
-- Keep the established 10/12 minute commentator engine as the single source of truth.

-- Remove experimental bouts/cards only. Existing AFMB Fight Night history stays intact.
delete from public.boxing_bouts where id like 'BX|LAUNCH|%' or id like 'BX|CARD|%';

drop function if exists public.tick_boxing_world();
drop function if exists private.schedule_boxing_card(text,text,timestamptz,integer);
drop function if exists private.ensure_boxing_schedule();
drop function if exists private.start_boxing_bout(text);
drop function if exists private.finish_boxing_bout(text);
drop function if exists private.boxing_round_duration();
drop function if exists private.boxing_break_duration();

alter table public.boxing_bouts drop constraint if exists boxing_bouts_bout_type_check;
alter table public.boxing_bouts
  drop column if exists card_id,
  drop column if exists bout_order,
  drop column if exists bout_type,
  drop column if exists rounds_scheduled,
  drop column if exists scorecards;

drop table if exists public.boxing_cards;

-- Reassert the canonical Fight Night schedule and advance any due bouts.
select private.ensure_boxing_schedule((now() at time zone 'Europe/Istanbul')::date);
select private.ensure_boxing_schedule((now() at time zone 'Europe/Istanbul')::date+1);
select public.tick_world();
