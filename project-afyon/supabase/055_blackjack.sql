-- Project Afyon 055 — AFMB Blackjack / 21
-- Server-authoritative deck and dealer flow. HIT / STAND only.
-- Natural Blackjack pays 3:2 profit (2.50x total return), normal win 2.00x, push returns stake.

alter table private.chance_sessions drop constraint if exists chance_sessions_game_key_check;
alter table private.chance_sessions add constraint chance_sessions_game_key_check check (
  game_key = any(array['mines','rocket','high_card','penalty_series','blackjack']::text[])
);

alter table private.chance_sessions drop constraint if exists chance_sessions_status_check;
alter table private.chance_sessions add constraint chance_sessions_status_check check (
  status = any(array['active','won','lost','cashed','push']::text[])
);

alter table public.chance_plays drop constraint if exists chance_plays_game_key_check;
alter table public.chance_plays add constraint chance_plays_game_key_check check (
  game_key = any(array[
    'marble_race','duck_derby','snail_league','afmb_wheel','memur_box','chicken_run','coin_flip',
    'marble_royale','mines','rocket','high_card','bureaucracy_hurdles','penalty_series','zabita_raid',
    'inspector_escape','vault_crack','stamp_memory','ece_anne','blackjack'
  ]::text[])
);

CREATE OR REPLACE FUNCTION private.blackjack_score(p_cards integer[])
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare
  v_card integer;
  v_rank integer;
  v_total integer:=0;
  v_aces integer:=0;
begin
  if p_cards is null then return 0; end if;
  foreach v_card in array p_cards loop
    v_rank:=(v_card % 13)+1;
    if v_rank=1 then
      v_total:=v_total+11;
      v_aces:=v_aces+1;
    elsif v_rank>=10 then
      v_total:=v_total+10;
    else
      v_total:=v_total+v_rank;
    end if;
  end loop;

  while v_total>21 and v_aces>0 loop
    v_total:=v_total-10;
    v_aces:=v_aces-1;
  end loop;
  return v_total;
end;
$function$;
revoke all on function private.blackjack_score(integer[]) from public,anon,authenticated;

CREATE OR REPLACE FUNCTION public.start_blackjack(p_stake bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid:=auth.uid();
  v_balance bigint;
  v_deck integer[];
  v_player integer[];
  v_dealer integer[];
  v_player_score integer;
  v_dealer_score integer;
  v_id uuid;
  v_state jsonb;
  v_status text:='active';
  v_payout bigint:=0;
  v_multiplier numeric:=0;
  v_outcome text;
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if p_stake is null or p_stake<10 then raise exception 'Minimum oyun miktarı 10 ₳D.'; end if;
  if p_stake>1000000 then raise exception 'Tek oyun için üst sınır 1.000.000 ₳D.'; end if;

  select balance into v_balance
  from public.wallets
  where user_id=v_user
  for update;

  if not found then raise exception 'Cüzdan bulunamadı.'; end if;
  if v_balance<p_stake then raise exception 'Yetersiz ₳D.'; end if;

  update public.wallets
  set balance=balance-p_stake,updated_at=now()
  where user_id=v_user
  returning balance into v_balance;

  select array_agg(i order by random()) into v_deck
  from generate_series(0,51) g(i);

  v_player:=array[v_deck[1],v_deck[3]];
  v_dealer:=array[v_deck[2],v_deck[4]];
  v_player_score:=private.blackjack_score(v_player);
  v_dealer_score:=private.blackjack_score(v_dealer);

  v_state:=jsonb_build_object(
    'deck',to_jsonb(v_deck),
    'next_pos',5,
    'player_cards',to_jsonb(v_player),
    'dealer_cards',to_jsonb(v_dealer)
  );

  insert into private.chance_sessions(user_id,game_key,stake,state)
  values(v_user,'blackjack',p_stake,v_state)
  returning id into v_id;

  if v_player_score=21 or v_dealer_score=21 then
    if v_player_score=21 and v_dealer_score=21 then
      v_status:='push'; v_payout:=p_stake; v_multiplier:=1.00; v_outcome:='push';
    elsif v_player_score=21 then
      v_status:='won'; v_payout:=round(p_stake*2.50); v_multiplier:=2.50; v_outcome:='blackjack';
    else
      v_status:='lost'; v_payout:=0; v_multiplier:=0; v_outcome:='dealer_blackjack';
    end if;

    if v_payout>0 then
      update public.wallets
      set balance=balance+v_payout,updated_at=now()
      where user_id=v_user
      returning balance into v_balance;
    end if;

    update private.chance_sessions
    set status=v_status,payout=v_payout,updated_at=now()
    where id=v_id;

    perform private.record_chance_session(
      v_id,v_user,'blackjack',p_stake,
      jsonb_build_object(
        'outcome',v_outcome,
        'player_cards',to_jsonb(v_player),
        'dealer_cards',to_jsonb(v_dealer),
        'player_score',v_player_score,
        'dealer_score',v_dealer_score,
        'natural',true
      ),
      v_multiplier,v_payout
    );

    return jsonb_build_object(
      'session_id',v_id,'game_key','blackjack','status',v_status,'stake',p_stake,
      'player_cards',to_jsonb(v_player),'dealer_cards',to_jsonb(v_dealer),
      'player_score',v_player_score,'dealer_score',v_dealer_score,
      'payout',v_payout,'multiplier',v_multiplier,'balance',v_balance,'outcome',v_outcome
    );
  end if;

  return jsonb_build_object(
    'session_id',v_id,'game_key','blackjack','status','active','stake',p_stake,
    'player_cards',to_jsonb(v_player),'dealer_cards',jsonb_build_array(v_dealer[1],null),
    'player_score',v_player_score,'dealer_score',private.blackjack_score(array[v_dealer[1]]),
    'payout',0,'multiplier',0,'balance',v_balance
  );
end;
$function$;
revoke all on function public.start_blackjack(bigint) from public,anon;
grant execute on function public.start_blackjack(bigint) to authenticated;

CREATE OR REPLACE FUNCTION public.blackjack_action(p_session_id uuid, p_action text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid:=auth.uid();
  s private.chance_sessions%rowtype;
  v_action text:=upper(trim(coalesce(p_action,'')));
  v_deck integer[];
  v_player integer[];
  v_dealer integer[];
  v_next integer;
  v_player_score integer;
  v_dealer_score integer;
  v_status text;
  v_outcome text;
  v_payout bigint:=0;
  v_multiplier numeric:=0;
  v_balance bigint;
  v_state jsonb;
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if p_session_id is null then raise exception 'Oyun kimliği eksik.'; end if;
  if v_action not in ('HIT','STAND') then raise exception 'Geçersiz Blackjack hamlesi.'; end if;

  select * into s
  from private.chance_sessions
  where id=p_session_id and user_id=v_user
  for update;

  if not found then raise exception 'Blackjack oturumu bulunamadı.'; end if;
  if s.game_key<>'blackjack' then raise exception 'Bu oturum Blackjack değil.'; end if;
  if s.status<>'active' then
    raise exception 'Bu Blackjack eli tamamlandı.';
  end if;

  v_deck:=array(
    select value::integer
    from jsonb_array_elements_text(s.state->'deck') with ordinality t(value,ord)
    order by ord
  );
  v_player:=array(
    select value::integer
    from jsonb_array_elements_text(s.state->'player_cards') with ordinality t(value,ord)
    order by ord
  );
  v_dealer:=array(
    select value::integer
    from jsonb_array_elements_text(s.state->'dealer_cards') with ordinality t(value,ord)
    order by ord
  );
  v_next:=(s.state->>'next_pos')::integer;

  if v_action='HIT' then
    if v_next>52 then raise exception 'Deste tükendi.'; end if;
    v_player:=array_append(v_player,v_deck[v_next]);
    v_next:=v_next+1;
    v_player_score:=private.blackjack_score(v_player);

    v_state:=jsonb_set(
      jsonb_set(s.state,'{player_cards}',to_jsonb(v_player)),
      '{next_pos}',to_jsonb(v_next)
    );

    if v_player_score>21 then
      v_status:='lost'; v_outcome:='bust'; v_payout:=0; v_multiplier:=0;
      update private.chance_sessions
      set state=v_state,status=v_status,payout=0,updated_at=now()
      where id=s.id;

      perform private.record_chance_session(
        s.id,v_user,'blackjack',s.stake,
        jsonb_build_object(
          'outcome',v_outcome,
          'player_cards',to_jsonb(v_player),
          'dealer_cards',to_jsonb(v_dealer),
          'player_score',v_player_score,
          'dealer_score',private.blackjack_score(v_dealer),
          'natural',false
        ),
        0,0
      );

      select balance into v_balance from public.wallets where user_id=v_user;
      return jsonb_build_object(
        'session_id',s.id,'game_key','blackjack','status',v_status,'stake',s.stake,
        'player_cards',to_jsonb(v_player),'dealer_cards',to_jsonb(v_dealer),
        'player_score',v_player_score,'dealer_score',private.blackjack_score(v_dealer),
        'payout',0,'multiplier',0,'balance',v_balance,'outcome',v_outcome
      );
    end if;

    update private.chance_sessions set state=v_state,updated_at=now() where id=s.id;
    return jsonb_build_object(
      'session_id',s.id,'game_key','blackjack','status','active','stake',s.stake,
      'player_cards',to_jsonb(v_player),'dealer_cards',jsonb_build_array(v_dealer[1],null),
      'player_score',v_player_score,'dealer_score',private.blackjack_score(array[v_dealer[1]]),
      'payout',0,'multiplier',0
    );
  end if;

  v_player_score:=private.blackjack_score(v_player);
  while private.blackjack_score(v_dealer)<17 loop
    if v_next>52 then exit; end if;
    v_dealer:=array_append(v_dealer,v_deck[v_next]);
    v_next:=v_next+1;
  end loop;
  v_dealer_score:=private.blackjack_score(v_dealer);

  if v_dealer_score>21 or v_player_score>v_dealer_score then
    v_status:='won'; v_outcome:='win'; v_payout:=s.stake*2; v_multiplier:=2.00;
  elsif v_player_score=v_dealer_score then
    v_status:='push'; v_outcome:='push'; v_payout:=s.stake; v_multiplier:=1.00;
  else
    v_status:='lost'; v_outcome:='loss'; v_payout:=0; v_multiplier:=0;
  end if;

  if v_payout>0 then
    update public.wallets
    set balance=balance+v_payout,updated_at=now()
    where user_id=v_user
    returning balance into v_balance;
  else
    select balance into v_balance from public.wallets where user_id=v_user;
  end if;

  v_state:=jsonb_set(
    jsonb_set(
      jsonb_set(s.state,'{player_cards}',to_jsonb(v_player)),
      '{dealer_cards}',to_jsonb(v_dealer)
    ),
    '{next_pos}',to_jsonb(v_next)
  );

  update private.chance_sessions
  set state=v_state,status=v_status,payout=v_payout,updated_at=now()
  where id=s.id;

  perform private.record_chance_session(
    s.id,v_user,'blackjack',s.stake,
    jsonb_build_object(
      'outcome',v_outcome,
      'player_cards',to_jsonb(v_player),
      'dealer_cards',to_jsonb(v_dealer),
      'player_score',v_player_score,
      'dealer_score',v_dealer_score,
      'natural',false
    ),
    v_multiplier,v_payout
  );

  return jsonb_build_object(
    'session_id',s.id,'game_key','blackjack','status',v_status,'stake',s.stake,
    'player_cards',to_jsonb(v_player),'dealer_cards',to_jsonb(v_dealer),
    'player_score',v_player_score,'dealer_score',v_dealer_score,
    'payout',v_payout,'multiplier',v_multiplier,'balance',v_balance,'outcome',v_outcome
  );
end;
$function$;
revoke all on function public.blackjack_action(uuid,text) from public,anon;
grant execute on function public.blackjack_action(uuid,text) to authenticated;
