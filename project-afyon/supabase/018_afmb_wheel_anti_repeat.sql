-- Project Afyon 0.28.2 — AFMB Wheel anti-repeat
-- The same wheel segment cannot land twice in a row for the same user.
-- Selection remains uniform among the other seven segments.

create or replace function public.play_chance_game(
  p_game_key text,
  p_stake bigint,
  p_choice text default null::text
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_winner text;
  v_multiplier numeric(8,2):=0;
  v_payout bigint:=0;
  v_result jsonb:='{}'::jsonb;
  v_play_id bigint;
  v_roll integer;
  v_valid_choices text[];
  v_hurdles integer;
  v_last_segment integer;
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

  case p_game_key
    when 'coin_flip' then
      v_valid_choices:=array['HEADS','TAILS'];
      if p_choice is null or not (upper(p_choice)=any(v_valid_choices)) then raise exception 'Yazı veya tura seç.'; end if;
      v_winner:=v_valid_choices[1+floor(random()*2)::int];
      if upper(p_choice)=v_winner then v_multiplier:=1.85; end if;
      v_result:=jsonb_build_object('winner',v_winner);

    when 'marble_race' then
      v_valid_choices:=array['BLUE','RED','YELLOW','GREEN','PURPLE','ORANGE','WHITE','BLACK'];
      if p_choice is null or not (upper(p_choice)=any(v_valid_choices)) then raise exception 'Bir bilye seç.'; end if;
      v_winner:=v_valid_choices[1+floor(random()*8)::int];
      if upper(p_choice)=v_winner then v_multiplier:=6.00; end if;
      v_result:=jsonb_build_object('winner',v_winner);

    when 'memur_box' then
      v_valid_choices:=array['BOX1','BOX2','BOX3'];
      if p_choice is null or not (upper(p_choice)=any(v_valid_choices)) then raise exception 'Bir kutu seç.'; end if;
      v_winner:=v_valid_choices[1+floor(random()*3)::int];
      if upper(p_choice)=v_winner then v_multiplier:=2.40; end if;
      v_result:=jsonb_build_object('winner',v_winner);

    when 'afmb_wheel' then
      select (cp.result->>'segment')::integer
      into v_last_segment
      from public.chance_plays cp
      where cp.user_id=v_user
        and cp.game_key='afmb_wheel'
      order by cp.created_at desc,cp.id desc
      limit 1;

      if v_last_segment between 1 and 8 then
        v_roll:=1+floor(random()*7)::int;
        if v_roll>=v_last_segment then
          v_roll:=v_roll+1;
        end if;
      else
        v_roll:=1+floor(random()*8)::int;
      end if;

      case v_roll
        when 1 then v_multiplier:=0;v_winner:='EVRAK_KAYIP';
        when 2 then v_multiplier:=0;v_winner:='OGLEDEN_SONRA_GEL';
        when 3 then v_multiplier:=0.40;v_winner:='YARIM_MAAS';
        when 4 then v_multiplier:=0.70;v_winner:='KESINTI';
        when 5 then v_multiplier:=0.90;v_winner:='AYNEN_IADE';
        when 6 then v_multiplier:=1.05;v_winner:='MESAİ';
        when 7 then v_multiplier:=1.25;v_winner:='IKRAMIYE';
        when 8 then v_multiplier:=1.60;v_winner:='MUHASEBE_HATASI';
      end case;
      v_result:=jsonb_build_object('winner',v_winner,'segment',v_roll);

    when 'bureaucracy_hurdles' then
      if upper(coalesce(p_choice,'')) not in ('LOW','MID','ALL') then raise exception '0-1, 2-3 veya 4 engel seç.'; end if;
      v_hurdles:=floor(random()*5)::int;
      if upper(p_choice)='LOW' and v_hurdles<=1 then v_multiplier:=2.00; end if;
      if upper(p_choice)='MID' and v_hurdles between 2 and 3 then v_multiplier:=2.00; end if;
      if upper(p_choice)='ALL' and v_hurdles=4 then v_multiplier:=3.50; end if;
      v_winner:=case when v_hurdles<=1 then 'LOW' when v_hurdles<=3 then 'MID' else 'ALL' end;
      v_result:=jsonb_build_object('winner',v_winner,'hurdles',v_hurdles);

    else
      raise exception 'Bilinmeyen şans oyunu.';
  end case;

  v_payout:=round(p_stake*v_multiplier);

  update public.wallets
  set balance=balance-p_stake+v_payout,updated_at=now()
  where user_id=v_user
  returning balance into v_balance;

  insert into public.chance_plays(user_id,game_key,stake,choice,result,multiplier,payout)
  values(v_user,p_game_key,p_stake,upper(p_choice),v_result,v_multiplier,v_payout)
  returning id into v_play_id;

  return jsonb_build_object(
    'play_id',v_play_id,
    'game_key',p_game_key,
    'choice',upper(p_choice),
    'result',v_result,
    'multiplier',v_multiplier,
    'payout',v_payout,
    'balance',v_balance
  );
end;
$function$;
