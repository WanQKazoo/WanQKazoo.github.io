-- Project Afyon 052 — Retire Mühür Nerede?
-- The memory game is removed from the playable client. Historical chance_plays rows remain readable.
-- Reject any new stamp_memory settlement at the server boundary.

CREATE OR REPLACE FUNCTION public.settle_local_chance_game(p_client_id uuid, p_game_key text, p_stake bigint, p_choice text, p_result jsonb, p_multiplier numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_payout bigint;
  v_existing public.chance_plays%rowtype;
  v_allowed text[] := array[
    'marble_race','mines','rocket','high_card',
    'memur_box','coin_flip','penalty_series','zabita_raid',
    'inspector_escape'
  ];
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if p_client_id is null then raise exception 'Oyun kimliği eksik.'; end if;
  if p_game_key is null or not (p_game_key = any(v_allowed)) then
    raise exception 'Bilinmeyen şans oyunu.';
  end if;
  if p_stake is null or p_stake < 10 then raise exception 'Minimum oyun miktarı 10 ₳D.'; end if;
  if p_stake > 1000000 then raise exception 'Tek oyun için üst sınır 1.000.000 ₳D.'; end if;
  if p_multiplier is null or p_multiplier < 0 or p_multiplier > 20 then
    raise exception 'Geçersiz çarpan.';
  end if;

  select *
  into v_existing
  from public.chance_plays
  where session_id=p_client_id
    and user_id=v_user
  limit 1;

  if found then
    select balance into v_balance
    from public.wallets
    where user_id=v_user;

    return jsonb_build_object(
      'play_id',v_existing.id,
      'game_key',v_existing.game_key,
      'multiplier',v_existing.multiplier,
      'payout',v_existing.payout,
      'balance',v_balance,
      'already_settled',true
    );
  end if;

  select balance
  into v_balance
  from public.wallets
  where user_id=v_user
  for update;

  if not found then raise exception 'Cüzdan bulunamadı.'; end if;
  if v_balance < p_stake then raise exception 'Yetersiz ₳D.'; end if;

  v_payout:=round(p_stake*p_multiplier);

  update public.wallets
  set balance=balance-p_stake+v_payout,
      updated_at=now()
  where user_id=v_user
  returning balance into v_balance;

  insert into public.chance_plays(
    session_id,user_id,game_key,stake,choice,result,multiplier,payout
  )
  values(
    p_client_id,
    v_user,
    p_game_key,
    p_stake,
    nullif(upper(coalesce(p_choice,'')),''),
    coalesce(p_result,'{}'::jsonb),
    p_multiplier,
    v_payout
  )
  returning id into v_existing.id;

  return jsonb_build_object(
    'play_id',v_existing.id,
    'game_key',p_game_key,
    'multiplier',p_multiplier,
    'payout',v_payout,
    'balance',v_balance,
    'already_settled',false
  );
end;
$function$

