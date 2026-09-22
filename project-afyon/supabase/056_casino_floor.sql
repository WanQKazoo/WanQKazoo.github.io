-- Project Afyon 056 — AFMB Casino Katı
-- Adds server-authoritative European Roulette, Baccarat and Sic Bo.

alter table public.chance_plays drop constraint if exists chance_plays_game_key_check;
alter table public.chance_plays add constraint chance_plays_game_key_check check (
  game_key = any(array[
    'marble_race','duck_derby','snail_league','afmb_wheel','memur_box','chicken_run','coin_flip',
    'marble_royale','mines','rocket','high_card','bureaucracy_hurdles','penalty_series','zabita_raid',
    'inspector_escape','vault_crack','stamp_memory','ece_anne','blackjack','roulette','baccarat','sic_bo'
  ]::text[])
);

CREATE OR REPLACE FUNCTION private.baccarat_value(p_card integer)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select case
    when ((p_card % 13)+1)>=10 then 0
    else ((p_card % 13)+1)
  end;
$function$;
revoke all on function private.baccarat_value(integer) from public,anon,authenticated;

CREATE OR REPLACE FUNCTION public.play_casino_table(p_client_id uuid, p_game_key text, p_stake bigint, p_choice text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid:=auth.uid();
  v_game text:=lower(trim(coalesce(p_game_key,'')));
  v_choice text:=upper(trim(coalesce(p_choice,'')));
  v_balance bigint;
  v_payout bigint:=0;
  v_multiplier numeric:=0;
  v_result jsonb:='{}'::jsonb;
  v_existing public.chance_plays%rowtype;

  v_num integer;
  v_red integer[]:=array[1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
  v_win boolean:=false;

  v_d1 integer; v_d2 integer; v_d3 integer; v_sum integer; v_triple boolean;

  v_deck integer[];
  p1 integer; p2 integer; p3 integer;
  b1 integer; b2 integer; b3 integer;
  pt integer; bt integer;
  pv3 integer;
  v_baccarat_winner text;
  v_outcome text;
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if p_client_id is null then raise exception 'Oyun kimliği eksik.'; end if;
  if v_game not in ('roulette','baccarat','sic_bo') then raise exception 'Bilinmeyen casino oyunu.'; end if;
  if p_stake is null or p_stake<10 then raise exception 'Minimum oyun miktarı 10 ₳D.'; end if;
  if p_stake>1000000 then raise exception 'Tek oyun için üst sınır 1.000.000 ₳D.'; end if;

  select * into v_existing
  from public.chance_plays
  where session_id=p_client_id and user_id=v_user
  limit 1;

  if found then
    select balance into v_balance from public.wallets where user_id=v_user;
    return jsonb_build_object(
      'play_id',v_existing.id,'game_key',v_existing.game_key,'result',v_existing.result,
      'multiplier',v_existing.multiplier,'payout',v_existing.payout,'balance',v_balance,
      'already_settled',true
    );
  end if;

  if v_game='roulette' then
    if v_choice not in ('RED','BLACK','ODD','EVEN','LOW','HIGH','ZERO') then
      raise exception 'Geçersiz rulet seçimi.';
    end if;

    v_num:=floor(random()*37)::integer;

    if v_choice='RED' then v_win:=v_num=any(v_red);
    elsif v_choice='BLACK' then v_win:=v_num<>0 and not(v_num=any(v_red));
    elsif v_choice='ODD' then v_win:=v_num<>0 and (v_num%2)=1;
    elsif v_choice='EVEN' then v_win:=v_num<>0 and (v_num%2)=0;
    elsif v_choice='LOW' then v_win:=v_num between 1 and 18;
    elsif v_choice='HIGH' then v_win:=v_num between 19 and 36;
    else v_win:=v_num=0;
    end if;

    v_multiplier:=case when v_win and v_choice='ZERO' then 36.00 when v_win then 2.00 else 0 end;
    v_result:=jsonb_build_object(
      'number',v_num,
      'color',case when v_num=0 then 'GREEN' when v_num=any(v_red) then 'RED' else 'BLACK' end,
      'choice',v_choice,
      'won',v_win
    );

  elsif v_game='sic_bo' then
    if v_choice not in ('LOW','HIGH','ODD','EVEN','TRIPLE') then
      raise exception 'Geçersiz Sic Bo seçimi.';
    end if;

    v_d1:=1+floor(random()*6)::integer;
    v_d2:=1+floor(random()*6)::integer;
    v_d3:=1+floor(random()*6)::integer;
    v_sum:=v_d1+v_d2+v_d3;
    v_triple:=v_d1=v_d2 and v_d2=v_d3;

    if v_choice='LOW' then v_win:=not v_triple and v_sum between 4 and 10;
    elsif v_choice='HIGH' then v_win:=not v_triple and v_sum between 11 and 17;
    elsif v_choice='ODD' then v_win:=not v_triple and (v_sum%2)=1;
    elsif v_choice='EVEN' then v_win:=not v_triple and (v_sum%2)=0;
    else v_win:=v_triple;
    end if;

    v_multiplier:=case when v_win and v_choice='TRIPLE' then 31.00 when v_win then 2.00 else 0 end;
    v_result:=jsonb_build_object(
      'dice',jsonb_build_array(v_d1,v_d2,v_d3),
      'sum',v_sum,
      'triple',v_triple,
      'choice',v_choice,
      'won',v_win
    );

  else
    if v_choice not in ('PLAYER','BANKER','TIE') then
      raise exception 'Geçersiz Baccarat seçimi.';
    end if;

    select array_agg(i order by random()) into v_deck
    from generate_series(0,51) g(i);

    p1:=v_deck[1]; b1:=v_deck[2]; p2:=v_deck[3]; b2:=v_deck[4];
    p3:=null; b3:=null;

    pt:=(private.baccarat_value(p1)+private.baccarat_value(p2))%10;
    bt:=(private.baccarat_value(b1)+private.baccarat_value(b2))%10;

    if pt<8 and bt<8 then
      if pt<=5 then
        p3:=v_deck[5];
        pv3:=private.baccarat_value(p3);
        pt:=(pt+pv3)%10;

        if bt<=2
          or (bt=3 and pv3<>8)
          or (bt=4 and pv3 between 2 and 7)
          or (bt=5 and pv3 between 4 and 7)
          or (bt=6 and pv3 in (6,7))
        then
          b3:=v_deck[6];
          bt:=(bt+private.baccarat_value(b3))%10;
        end if;
      elsif bt<=5 then
        b3:=v_deck[5];
        bt:=(bt+private.baccarat_value(b3))%10;
      end if;
    end if;

    v_baccarat_winner:=case when pt>bt then 'PLAYER' when bt>pt then 'BANKER' else 'TIE' end;

    if v_baccarat_winner='TIE' and v_choice in ('PLAYER','BANKER') then
      v_multiplier:=1.00;
      v_outcome:='push';
    elsif v_choice=v_baccarat_winner then
      v_multiplier:=case v_choice when 'BANKER' then 1.95 when 'TIE' then 9.00 else 2.00 end;
      v_outcome:='win';
    else
      v_multiplier:=0;
      v_outcome:='loss';
    end if;

    v_result:=jsonb_build_object(
      'player_cards',jsonb_strip_nulls(jsonb_build_array(p1,p2,p3)),
      'banker_cards',jsonb_strip_nulls(jsonb_build_array(b1,b2,b3)),
      'player_score',pt,
      'banker_score',bt,
      'winner',v_baccarat_winner,
      'choice',v_choice,
      'outcome',v_outcome
    );
  end if;

  select balance into v_balance
  from public.wallets
  where user_id=v_user
  for update;

  if not found then raise exception 'Cüzdan bulunamadı.'; end if;
  if v_balance<p_stake then raise exception 'Yetersiz ₳D.'; end if;

  v_payout:=round(p_stake*v_multiplier);

  update public.wallets
  set balance=balance-p_stake+v_payout,updated_at=now()
  where user_id=v_user
  returning balance into v_balance;

  insert into public.chance_plays(
    session_id,user_id,game_key,stake,choice,result,multiplier,payout
  )
  values(
    p_client_id,v_user,v_game,p_stake,v_choice,v_result,v_multiplier,v_payout
  )
  returning id into v_existing.id;

  return jsonb_build_object(
    'play_id',v_existing.id,'game_key',v_game,'result',v_result,
    'multiplier',v_multiplier,'payout',v_payout,'balance',v_balance,'already_settled',false
  );
end;
$function$;
revoke all on function public.play_casino_table(uuid,text,bigint,text) from public,anon;
grant execute on function public.play_casino_table(uuid,text,bigint,text) to authenticated;
