-- Project Afyon 0.33.1 — allow new chance-game history keys

alter table public.chance_plays
  drop constraint if exists chance_plays_game_key_check;

alter table public.chance_plays
  add constraint chance_plays_game_key_check
  check (
    game_key in (
      'marble_race',
      'duck_derby',
      'snail_league',
      'afmb_wheel',
      'memur_box',
      'chicken_run',
      'coin_flip',
      'marble_royale',
      'mines',
      'rocket',
      'high_card',
      'bureaucracy_hurdles',
      'penalty_series',
      'zabita_raid'
    )
  );
