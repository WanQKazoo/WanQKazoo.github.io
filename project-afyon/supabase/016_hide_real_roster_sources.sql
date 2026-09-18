-- Applied Supabase migration: hide_real_roster_sources


alter table public.players drop column if exists source_player_name;

