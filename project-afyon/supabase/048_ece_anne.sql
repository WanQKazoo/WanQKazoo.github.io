-- Project Afyon 048 — Ece Anne Der Mi?
-- Server-authoritative single-round special chance game.
-- Win chance: 25%. Win multiplier: x3.60 (90% theoretical RTP).

create or replace function public.play_ece_anne(p_client_id uuid,p_stake bigint)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
  v_balance bigint;
  v_existing public.chance_plays%rowtype;
  v_win boolean;
  v_multiplier numeric:=3.60;
  v_payout bigint;
  v_count integer;
  v_anne_pos integer;
  v_i integer;
  v_r numeric;
  v_token text;
  v_sequence jsonb:='[]'::jsonb;
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if p_client_id is null then raise exception 'Oyun kimliği eksik.'; end if;
  if p_stake is null or p_stake<10 then raise exception 'Minimum oyun miktarı 10 ₳D.'; end if;
  if p_stake>1000000 then raise exception 'Tek oyun için üst sınır 1.000.000 ₳D.'; end if;

  select * into v_existing
  from public.chance_plays
  where session_id=p_client_id and user_id=v_user
  limit 1;

  if found then
    select balance into v_balance from public.wallets where user_id=v_user;
    return jsonb_build_object(
      'play_id',v_existing.id,
      'game_key',v_existing.game_key,
      'result',v_existing.result,
      'multiplier',v_existing.multiplier,
      'payout',v_existing.payout,
      'balance',v_balance,
      'already_settled',true
    );
  end if;

  select balance into v_balance
  from public.wallets
  where user_id=v_user
  for update;

  if not found then raise exception 'Cüzdan bulunamadı.'; end if;
  if v_balance<p_stake then raise exception 'Yetersiz ₳D.'; end if;

  v_win:=random()<0.25;
  v_count:=5+floor(random()*5)::integer;
  v_anne_pos:=case when v_win then 2+floor(random()*greatest(1,v_count-1))::integer else null end;

  for v_i in 1..v_count loop
    if v_win and v_i=v_anne_pos then
      v_token:='ANNE';
      v_sequence:=v_sequence||jsonb_build_array(v_token);
      exit;
    end if;

    if v_i=1 then
      v_token:='BABA';
    else
      v_r:=random();
      if v_r<0.64 then
        v_token:='BABA';
      elsif v_r<0.76 then
        v_token:='BABA BABA';
      elsif v_r<0.85 then
        v_token:='HAVVA';
      elsif v_r<0.94 then
        v_token:='NEM NEM';
      else
        v_token:='AAAANNN... AN AN AN 🚗';
      end if;
    end if;
    v_sequence:=v_sequence||jsonb_build_array(v_token);
  end loop;

  v_payout:=case when v_win then round(p_stake*v_multiplier) else 0 end;

  update public.wallets
  set balance=balance-p_stake+v_payout,updated_at=now()
  where user_id=v_user
  returning balance into v_balance;

  insert into public.chance_plays(
    session_id,user_id,game_key,stake,choice,result,multiplier,payout
  )
  values(
    p_client_id,v_user,'ece_anne',p_stake,null,
    jsonb_build_object(
      'winner',case when v_win then 'ANNE' else 'NO_ANNE' end,
      'said_anne',v_win,
      'sequence',v_sequence,
      'chance',0.25
    ),
    case when v_win then v_multiplier else 0 end,
    v_payout
  )
  returning id into v_existing.id;

  return jsonb_build_object(
    'play_id',v_existing.id,
    'game_key','ece_anne',
    'result',jsonb_build_object(
      'winner',case when v_win then 'ANNE' else 'NO_ANNE' end,
      'said_anne',v_win,
      'sequence',v_sequence,
      'chance',0.25
    ),
    'multiplier',case when v_win then v_multiplier else 0 end,
    'payout',v_payout,
    'balance',v_balance,
    'already_settled',false
  );
end;
$function$;

revoke all on function public.play_ece_anne(uuid,bigint) from public;
revoke all on function public.play_ece_anne(uuid,bigint) from anon;
grant execute on function public.play_ece_anne(uuid,bigint) to authenticated;
