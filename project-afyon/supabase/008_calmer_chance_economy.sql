-- Project Afyon 0.22 — calmer chance-game economy.
-- Replaces payout curves only; no real-money functionality exists.

create or replace function private.afyon_mines_multiplier(p_safe_count integer)
returns numeric
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_safe_count <= 0 then return 0.85; end if;
  return round(0.85 * power(1.09::numeric,p_safe_count),2);
end;
$$;

create or replace function private.record_chance_session(
  p_session_id uuid,p_user_id uuid,p_game_key text,p_stake bigint,
  p_result jsonb,p_multiplier numeric,p_payout bigint
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.chance_plays(session_id,user_id,game_key,stake,choice,result,multiplier,payout)
  values(p_session_id,p_user_id,p_game_key,p_stake,null,coalesce(p_result,'{}'::jsonb),p_multiplier,p_payout)
  on conflict (session_id) where session_id is not null do nothing;
$$;

revoke all on function private.record_chance_session(uuid,uuid,text,bigint,jsonb,numeric,bigint) from public, anon, authenticated;

create or replace function public.start_chance_session(p_game_key text,p_stake bigint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_id uuid;
  v_state jsonb;
  v_bombs integer[] := '{}';
  v_pos integer;
  v_card integer;
  v_crash numeric;
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if p_game_key not in ('mines','rocket','high_card') then raise exception 'Bu oyun oturum tipi desteklenmiyor.'; end if;
  if p_stake is null or p_stake < 10 then raise exception 'Minimum oyun miktarı 10 ₳D.'; end if;
  if p_stake > 1000000 then raise exception 'Tek oyun için üst sınır 1.000.000 ₳D.'; end if;

  select balance into v_balance from public.wallets where user_id=v_user for update;
  if not found then raise exception 'Cüzdan bulunamadı.'; end if;
  if v_balance < p_stake then raise exception 'Yetersiz ₳D.'; end if;

  update public.wallets set balance=balance-p_stake,updated_at=now()
  where user_id=v_user returning balance into v_balance;

  if p_game_key='mines' then
    while coalesce(array_length(v_bombs,1),0) < 5 loop
      v_pos := floor(random()*25)::int;
      if not (v_pos = any(v_bombs)) then v_bombs := array_append(v_bombs,v_pos); end if;
    end loop;
    v_state := jsonb_build_object('bombs',to_jsonb(v_bombs),'opened','[]'::jsonb,'safe_count',0,'multiplier',0.85);
  elsif p_game_key='rocket' then
    v_crash := round((1.05 + power(random(),2.4)*2.95)::numeric,2);
    v_state := jsonb_build_object('crash_multiplier',v_crash);
  else
    v_card := 2 + floor(random()*13)::int;
    v_state := jsonb_build_object('current_card',v_card,'streak',0,'multiplier',0.90);
  end if;

  insert into private.chance_sessions(user_id,game_key,stake,state)
  values(v_user,p_game_key,p_stake,v_state) returning id into v_id;

  if p_game_key='mines' then
    return jsonb_build_object('session_id',v_id,'game_key',p_game_key,'status','active','stake',p_stake,'balance',v_balance,'opened','[]'::jsonb,'safe_count',0,'multiplier',0.85);
  elsif p_game_key='rocket' then
    return jsonb_build_object('session_id',v_id,'game_key',p_game_key,'status','active','stake',p_stake,'balance',v_balance,'multiplier',0.90,'started_at',now());
  else
    return jsonb_build_object('session_id',v_id,'game_key',p_game_key,'status','active','stake',p_stake,'balance',v_balance,'current_card',v_card,'streak',0,'multiplier',0.90);
  end if;
end;
$$;

revoke all on function public.start_chance_session(text,bigint) from public, anon;
grant execute on function public.start_chance_session(text,bigint) to authenticated;

create or replace function public.chance_session_action(p_session_id uuid,p_action text,p_choice text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  s private.chance_sessions%rowtype;
  v_pick integer; v_is_bomb boolean; v_safe_count integer; v_multiplier numeric;
  v_payout bigint; v_balance bigint; v_opened jsonb; v_current integer; v_next integer;
  v_streak integer; v_correct boolean; v_elapsed numeric; v_crash numeric;
  v_action text := upper(coalesce(p_action,'')); v_choice text := upper(coalesce(p_choice,''));
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  select * into s from private.chance_sessions where id=p_session_id and user_id=v_user for update;
  if not found then raise exception 'Oyun oturumu bulunamadı.'; end if;
  if s.status<>'active' then return jsonb_build_object('session_id',s.id,'game_key',s.game_key,'status',s.status,'payout',s.payout); end if;

  if s.game_key='mines' then
    if v_action='PICK' then
      begin v_pick := p_choice::integer; exception when others then raise exception 'Geçersiz kutu.'; end;
      if v_pick<0 or v_pick>24 then raise exception 'Geçersiz kutu.'; end if;
      if exists(select 1 from jsonb_array_elements_text(s.state->'opened') x where x::integer=v_pick) then raise exception 'Bu kutu zaten açıldı.'; end if;
      v_is_bomb := exists(select 1 from jsonb_array_elements_text(s.state->'bombs') x where x::integer=v_pick);
      v_opened := (s.state->'opened') || to_jsonb(v_pick);
      if v_is_bomb then
        update private.chance_sessions set status='lost',state=jsonb_set(jsonb_set(state,'{opened}',v_opened),'{hit}',to_jsonb(v_pick)),updated_at=now() where id=s.id;
        perform private.record_chance_session(s.id,v_user,'mines',s.stake,jsonb_build_object('safe_count',(s.state->>'safe_count')::int,'hit',v_pick),0,0);
        return jsonb_build_object('session_id',s.id,'game_key','mines','status','lost','hit',v_pick,'opened',v_opened,'payout',0);
      end if;
      v_safe_count := (s.state->>'safe_count')::int + 1;
      v_multiplier := private.afyon_mines_multiplier(v_safe_count);
      update private.chance_sessions
      set state=jsonb_set(jsonb_set(jsonb_set(state,'{opened}',v_opened),'{safe_count}',to_jsonb(v_safe_count)),'{multiplier}',to_jsonb(v_multiplier)),updated_at=now()
      where id=s.id;
      return jsonb_build_object('session_id',s.id,'game_key','mines','status','active','opened',v_opened,'safe_count',v_safe_count,'multiplier',v_multiplier);
    elsif v_action='CASHOUT' then
      v_safe_count := (s.state->>'safe_count')::int;
      if v_safe_count<1 then raise exception 'Önce en az bir güvenli kutu aç.'; end if;
      v_multiplier := (s.state->>'multiplier')::numeric;
      v_payout := round(s.stake*v_multiplier);
      update public.wallets set balance=balance+v_payout,updated_at=now() where user_id=v_user returning balance into v_balance;
      update private.chance_sessions set status='cashed',payout=v_payout,updated_at=now() where id=s.id;
      perform private.record_chance_session(s.id,v_user,'mines',s.stake,jsonb_build_object('safe_count',v_safe_count),v_multiplier,v_payout);
      return jsonb_build_object('session_id',s.id,'game_key','mines','status','cashed','safe_count',v_safe_count,'multiplier',v_multiplier,'payout',v_payout,'balance',v_balance);
    else
      raise exception 'Mayın oyununda PICK veya CASHOUT kullan.';
    end if;
  elsif s.game_key='high_card' then
    if v_action='CASHOUT' then
      v_streak := (s.state->>'streak')::int;
      if v_streak<1 then raise exception 'Önce en az bir doğru tahmin yap.'; end if;
      v_multiplier := (s.state->>'multiplier')::numeric;
      v_payout := round(s.stake*v_multiplier);
      update public.wallets set balance=balance+v_payout,updated_at=now() where user_id=v_user returning balance into v_balance;
      update private.chance_sessions set status='cashed',payout=v_payout,updated_at=now() where id=s.id;
      perform private.record_chance_session(s.id,v_user,'high_card',s.stake,jsonb_build_object('streak',v_streak,'last_card',(s.state->>'current_card')::int),v_multiplier,v_payout);
      return jsonb_build_object('session_id',s.id,'game_key','high_card','status','cashed','streak',v_streak,'multiplier',v_multiplier,'payout',v_payout,'balance',v_balance);
    end if;
    if v_action<>'GUESS' or v_choice not in ('HIGHER','LOWER') then raise exception 'Yüksek veya düşük seç.'; end if;
    v_current := (s.state->>'current_card')::int; v_next := 2 + floor(random()*13)::int;
    v_streak := (s.state->>'streak')::int; v_multiplier := (s.state->>'multiplier')::numeric;
    if v_next=v_current then
      update private.chance_sessions set state=jsonb_set(state,'{current_card}',to_jsonb(v_next)),updated_at=now() where id=s.id;
      return jsonb_build_object('session_id',s.id,'game_key','high_card','status','active','push',true,'current_card',v_next,'streak',v_streak,'multiplier',v_multiplier);
    end if;
    v_correct := (v_choice='HIGHER' and v_next>v_current) or (v_choice='LOWER' and v_next<v_current);
    if not v_correct then
      update private.chance_sessions set status='lost',state=jsonb_set(state,'{current_card}',to_jsonb(v_next)),updated_at=now() where id=s.id;
      perform private.record_chance_session(s.id,v_user,'high_card',s.stake,jsonb_build_object('streak',v_streak,'last_card',v_next,'guess',v_choice),0,0);
      return jsonb_build_object('session_id',s.id,'game_key','high_card','status','lost','current_card',v_next,'streak',v_streak,'payout',0);
    end if;
    v_streak := v_streak+1; v_multiplier := round(0.90 * power(1.28::numeric,v_streak),2);
    if v_streak>=6 then
      v_payout := round(s.stake*v_multiplier);
      update public.wallets set balance=balance+v_payout,updated_at=now() where user_id=v_user returning balance into v_balance;
      update private.chance_sessions set status='won',payout=v_payout,state=jsonb_set(jsonb_set(jsonb_set(state,'{current_card}',to_jsonb(v_next)),'{streak}',to_jsonb(v_streak)),'{multiplier}',to_jsonb(v_multiplier)),updated_at=now() where id=s.id;
      perform private.record_chance_session(s.id,v_user,'high_card',s.stake,jsonb_build_object('streak',v_streak,'last_card',v_next),v_multiplier,v_payout);
      return jsonb_build_object('session_id',s.id,'game_key','high_card','status','won','current_card',v_next,'streak',v_streak,'multiplier',v_multiplier,'payout',v_payout,'balance',v_balance);
    end if;
    update private.chance_sessions
    set state=jsonb_set(jsonb_set(jsonb_set(state,'{current_card}',to_jsonb(v_next)),'{streak}',to_jsonb(v_streak)),'{multiplier}',to_jsonb(v_multiplier)),updated_at=now()
    where id=s.id;
    return jsonb_build_object('session_id',s.id,'game_key','high_card','status','active','current_card',v_next,'streak',v_streak,'multiplier',v_multiplier);
  elsif s.game_key='rocket' then
    if v_action<>'CASHOUT' then raise exception 'Rokette CASHOUT kullan.'; end if;
    v_elapsed := extract(epoch from (now()-s.started_at)); v_crash := (s.state->>'crash_multiplier')::numeric;
    v_multiplier := least(4.00::numeric,round((0.90 + 0.08*v_elapsed)::numeric,2));
    if v_multiplier>=v_crash then
      update private.chance_sessions set status='lost',updated_at=now() where id=s.id;
      perform private.record_chance_session(s.id,v_user,'rocket',s.stake,jsonb_build_object('crash_multiplier',v_crash),0,0);
      return jsonb_build_object('session_id',s.id,'game_key','rocket','status','lost','crash_multiplier',v_crash,'payout',0);
    end if;
    v_payout := round(s.stake*v_multiplier);
    update public.wallets set balance=balance+v_payout,updated_at=now() where user_id=v_user returning balance into v_balance;
    update private.chance_sessions set status='cashed',payout=v_payout,updated_at=now() where id=s.id;
    perform private.record_chance_session(s.id,v_user,'rocket',s.stake,jsonb_build_object('cashout_multiplier',v_multiplier,'crash_multiplier',v_crash),v_multiplier,v_payout);
    return jsonb_build_object('session_id',s.id,'game_key','rocket','status','cashed','multiplier',v_multiplier,'payout',v_payout,'balance',v_balance);
  end if;
  raise exception 'Bilinmeyen oyun oturumu.';
end;
$$;

revoke all on function public.chance_session_action(uuid,text,text) from public, anon;
grant execute on function public.chance_session_action(uuid,text,text) to authenticated;

create or replace function public.chance_session_status(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid(); s private.chance_sessions%rowtype;
  v_elapsed numeric; v_crash numeric; v_multiplier numeric;
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  select * into s from private.chance_sessions where id=p_session_id and user_id=v_user for update;
  if not found then raise exception 'Oyun oturumu bulunamadı.'; end if;
  if s.game_key='rocket' and s.status='active' then
    v_elapsed := extract(epoch from (now()-s.started_at)); v_crash := (s.state->>'crash_multiplier')::numeric;
    v_multiplier := least(4.00::numeric,round((0.90 + 0.08*v_elapsed)::numeric,2));
    if v_multiplier>=v_crash then
      update private.chance_sessions set status='lost',updated_at=now() where id=s.id;
      perform private.record_chance_session(s.id,v_user,'rocket',s.stake,jsonb_build_object('crash_multiplier',v_crash),0,0);
      return jsonb_build_object('session_id',s.id,'game_key','rocket','status','lost','crash_multiplier',v_crash,'payout',0);
    end if;
    return jsonb_build_object('session_id',s.id,'game_key','rocket','status','active','multiplier',v_multiplier);
  end if;
  return jsonb_build_object('session_id',s.id,'game_key',s.game_key,'status',s.status,'payout',s.payout);
end;
$$;

revoke all on function public.chance_session_status(uuid) from public, anon;
grant execute on function public.chance_session_status(uuid) to authenticated;

create or replace function public.play_chance_game(p_game_key text,p_stake bigint,p_choice text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid(); v_balance bigint; v_winner text; v_multiplier numeric(8,2):=0;
  v_payout bigint:=0; v_result jsonb:='{}'::jsonb; v_play_id bigint; v_roll integer;
  v_valid_choices text[]; v_hurdles integer;
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if p_stake is null or p_stake<10 then raise exception 'Minimum oyun miktarı 10 ₳D.'; end if;
  if p_stake>1000000 then raise exception 'Tek oyun için üst sınır 1.000.000 ₳D.'; end if;
  select balance into v_balance from public.wallets where user_id=v_user for update;
  if not found then raise exception 'Cüzdan bulunamadı.'; end if;
  if v_balance<p_stake then raise exception 'Yetersiz ₳D.'; end if;

  case p_game_key
    when 'coin_flip' then
      v_valid_choices:=array['HEADS','TAILS']; if p_choice is null or not (upper(p_choice)=any(v_valid_choices)) then raise exception 'Yazı veya tura seç.'; end if;
      v_winner:=v_valid_choices[1+floor(random()*2)::int]; if upper(p_choice)=v_winner then v_multiplier:=1.85; end if; v_result:=jsonb_build_object('winner',v_winner);
    when 'marble_race' then
      v_valid_choices:=array['BLUE','RED','YELLOW','GREEN','PURPLE','ORANGE','WHITE','BLACK']; if p_choice is null or not (upper(p_choice)=any(v_valid_choices)) then raise exception 'Bir bilye seç.'; end if;
      v_winner:=v_valid_choices[1+floor(random()*8)::int]; if upper(p_choice)=v_winner then v_multiplier:=6.00; end if; v_result:=jsonb_build_object('winner',v_winner);
    when 'memur_box' then
      v_valid_choices:=array['BOX1','BOX2','BOX3']; if p_choice is null or not (upper(p_choice)=any(v_valid_choices)) then raise exception 'Bir kutu seç.'; end if;
      v_winner:=v_valid_choices[1+floor(random()*3)::int]; if upper(p_choice)=v_winner then v_multiplier:=2.40; end if; v_result:=jsonb_build_object('winner',v_winner);
    when 'afmb_wheel' then
      v_roll:=1+floor(random()*8)::int;
      case v_roll
        when 1 then v_multiplier:=0;v_winner:='EVRAK_KAYIP'; when 2 then v_multiplier:=0;v_winner:='OGLEDEN_SONRA_GEL';
        when 3 then v_multiplier:=0.40;v_winner:='YARIM_MAAS'; when 4 then v_multiplier:=0.70;v_winner:='KESINTI';
        when 5 then v_multiplier:=0.90;v_winner:='AYNEN_IADE'; when 6 then v_multiplier:=1.05;v_winner:='MESAİ';
        when 7 then v_multiplier:=1.25;v_winner:='IKRAMIYE'; when 8 then v_multiplier:=1.60;v_winner:='MUHASEBE_HATASI';
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
    else raise exception 'Bilinmeyen şans oyunu.';
  end case;

  v_payout:=round(p_stake*v_multiplier);
  update public.wallets set balance=balance-p_stake+v_payout,updated_at=now() where user_id=v_user returning balance into v_balance;
  insert into public.chance_plays(user_id,game_key,stake,choice,result,multiplier,payout)
  values(v_user,p_game_key,p_stake,upper(p_choice),v_result,v_multiplier,v_payout) returning id into v_play_id;

  return jsonb_build_object('play_id',v_play_id,'game_key',p_game_key,'choice',upper(p_choice),'result',v_result,'multiplier',v_multiplier,'payout',v_payout,'balance',v_balance);
end;
$$;

revoke all on function public.play_chance_game(text,bigint,text) from public, anon;
grant execute on function public.play_chance_game(text,bigint,text) to authenticated;
