-- Project Afyon 0.33 — Replace retired chance games
-- Adds AFMB Penalty Series (session game) and Zabita Raid (single game).
-- AFMB Wheel and Bureaucracy Hurdles remain only as historical records.

alter table private.chance_sessions
  drop constraint if exists chance_sessions_game_key_check;

alter table private.chance_sessions
  add constraint chance_sessions_game_key_check
  check (game_key in ('mines','rocket','high_card','penalty_series'));

create or replace function public.start_afmb_penalty(p_stake bigint)
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
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if p_stake is null or p_stake < 10 then raise exception 'Minimum oyun miktarı 10 ₳D.'; end if;
  if p_stake > 1000000 then raise exception 'Tek oyun için üst sınır 1.000.000 ₳D.'; end if;

  select balance into v_balance
  from public.wallets
  where user_id=v_user
  for update;

  if not found then raise exception 'Cüzdan bulunamadı.'; end if;
  if v_balance < p_stake then raise exception 'Yetersiz ₳D.'; end if;

  update public.wallets
  set balance=balance-p_stake,updated_at=now()
  where user_id=v_user
  returning balance into v_balance;

  v_state:=jsonb_build_object(
    'goals',0,
    'multiplier',0.92,
    'last_keeper',null,
    'last_shot',null
  );

  insert into private.chance_sessions(user_id,game_key,stake,state)
  values(v_user,'penalty_series',p_stake,v_state)
  returning id into v_id;

  return jsonb_build_object(
    'session_id',v_id,
    'game_key','penalty_series',
    'status','active',
    'stake',p_stake,
    'balance',v_balance,
    'goals',0,
    'multiplier',0.92
  );
end;
$$;

revoke all on function public.start_afmb_penalty(bigint) from public;
revoke all on function public.start_afmb_penalty(bigint) from anon;
grant execute on function public.start_afmb_penalty(bigint) to authenticated;

create or replace function public.afmb_penalty_action(
  p_session_id uuid,
  p_action text,
  p_choice text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  s private.chance_sessions%rowtype;
  v_action text := upper(coalesce(p_action,''));
  v_choice text := upper(coalesce(p_choice,''));
  v_keeper text;
  v_dirs text[] := array['LEFT','CENTER','RIGHT'];
  v_goals integer;
  v_multiplier numeric(8,2);
  v_payout bigint;
  v_balance bigint;
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;

  select * into s
  from private.chance_sessions
  where id=p_session_id
    and user_id=v_user
    and game_key='penalty_series'
  for update;

  if not found then raise exception 'Penaltı oturumu bulunamadı.'; end if;

  if s.status<>'active' then
    return jsonb_build_object(
      'session_id',s.id,
      'game_key',s.game_key,
      'status',s.status,
      'payout',s.payout
    );
  end if;

  v_goals:=coalesce((s.state->>'goals')::integer,0);
  v_multiplier:=coalesce((s.state->>'multiplier')::numeric,0.92);

  if v_action='CASHOUT' then
    if v_goals<1 then raise exception 'Önce en az bir gol at.'; end if;

    v_payout:=round(s.stake*v_multiplier);

    update public.wallets
    set balance=balance+v_payout,updated_at=now()
    where user_id=v_user
    returning balance into v_balance;

    update private.chance_sessions
    set status='cashed',payout=v_payout,updated_at=now()
    where id=s.id;

    perform private.record_chance_session(
      s.id,v_user,'penalty_series',s.stake,
      jsonb_build_object('goals',v_goals),
      v_multiplier,v_payout
    );

    return jsonb_build_object(
      'session_id',s.id,
      'game_key','penalty_series',
      'status','cashed',
      'goals',v_goals,
      'multiplier',v_multiplier,
      'payout',v_payout,
      'balance',v_balance
    );
  end if;

  if v_action<>'KICK' or v_choice not in ('LEFT','CENTER','RIGHT') then
    raise exception 'Sol, orta veya sağ seç.';
  end if;

  v_keeper:=v_dirs[1+floor(random()*3)::integer];

  if v_keeper=v_choice then
    update private.chance_sessions
    set status='lost',
        state=jsonb_set(
          jsonb_set(state,'{last_keeper}',to_jsonb(v_keeper)),
          '{last_shot}',to_jsonb(v_choice)
        ),
        updated_at=now()
    where id=s.id;

    perform private.record_chance_session(
      s.id,v_user,'penalty_series',s.stake,
      jsonb_build_object(
        'goals',v_goals,
        'last_keeper',v_keeper,
        'last_shot',v_choice,
        'saved',true
      ),
      0,0
    );

    return jsonb_build_object(
      'session_id',s.id,
      'game_key','penalty_series',
      'status','lost',
      'goals',v_goals,
      'keeper',v_keeper,
      'shot',v_choice,
      'saved',true,
      'payout',0
    );
  end if;

  v_goals:=v_goals+1;
  v_multiplier:=round(0.92 * power(1.50::numeric,v_goals),2);

  if v_goals>=5 then
    v_payout:=round(s.stake*v_multiplier);

    update public.wallets
    set balance=balance+v_payout,updated_at=now()
    where user_id=v_user
    returning balance into v_balance;

    update private.chance_sessions
    set status='won',
        payout=v_payout,
        state=jsonb_set(
          jsonb_set(
            jsonb_set(
              jsonb_set(state,'{goals}',to_jsonb(v_goals)),
              '{multiplier}',to_jsonb(v_multiplier)
            ),
            '{last_keeper}',to_jsonb(v_keeper)
          ),
          '{last_shot}',to_jsonb(v_choice)
        ),
        updated_at=now()
    where id=s.id;

    perform private.record_chance_session(
      s.id,v_user,'penalty_series',s.stake,
      jsonb_build_object(
        'goals',v_goals,
        'last_keeper',v_keeper,
        'last_shot',v_choice,
        'saved',false
      ),
      v_multiplier,v_payout
    );

    return jsonb_build_object(
      'session_id',s.id,
      'game_key','penalty_series',
      'status','won',
      'goals',v_goals,
      'keeper',v_keeper,
      'shot',v_choice,
      'saved',false,
      'multiplier',v_multiplier,
      'payout',v_payout,
      'balance',v_balance
    );
  end if;

  update private.chance_sessions
  set state=jsonb_set(
        jsonb_set(
          jsonb_set(
            jsonb_set(state,'{goals}',to_jsonb(v_goals)),
            '{multiplier}',to_jsonb(v_multiplier)
          ),
          '{last_keeper}',to_jsonb(v_keeper)
        ),
        '{last_shot}',to_jsonb(v_choice)
      ),
      updated_at=now()
  where id=s.id;

  return jsonb_build_object(
    'session_id',s.id,
    'game_key','penalty_series',
    'status','active',
    'goals',v_goals,
    'keeper',v_keeper,
    'shot',v_choice,
    'saved',false,
    'multiplier',v_multiplier
  );
end;
$$;

revoke all on function public.afmb_penalty_action(uuid,text,text) from public;
revoke all on function public.afmb_penalty_action(uuid,text,text) from anon;
grant execute on function public.afmb_penalty_action(uuid,text,text) to authenticated;

create or replace function public.play_zabita_raid(
  p_stake bigint,
  p_choice text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_choice text := upper(coalesce(p_choice,''));
  v_stalls text[] := array['SIMIT','MISIR','KESTANE'];
  v_raided text;
  v_safe boolean;
  v_multiplier numeric(8,2):=0;
  v_payout bigint:=0;
  v_play_id bigint;
  v_result jsonb;
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if p_stake is null or p_stake<10 then raise exception 'Minimum oyun miktarı 10 ₳D.'; end if;
  if p_stake>1000000 then raise exception 'Tek oyun için üst sınır 1.000.000 ₳D.'; end if;
  if v_choice not in ('SIMIT','MISIR','KESTANE') then raise exception 'Bir tezgâh seç.'; end if;

  select balance into v_balance
  from public.wallets
  where user_id=v_user
  for update;

  if not found then raise exception 'Cüzdan bulunamadı.'; end if;
  if v_balance<p_stake then raise exception 'Yetersiz ₳D.'; end if;

  v_raided:=v_stalls[1+floor(random()*3)::integer];
  v_safe:=v_choice<>v_raided;
  if v_safe then v_multiplier:=1.40; end if;
  v_payout:=round(p_stake*v_multiplier);

  update public.wallets
  set balance=balance-p_stake+v_payout,updated_at=now()
  where user_id=v_user
  returning balance into v_balance;

  v_result:=jsonb_build_object(
    'winner',case when v_safe then 'SAFE' else 'CAUGHT' end,
    'chosen',v_choice,
    'raided',v_raided
  );

  insert into public.chance_plays(user_id,game_key,stake,choice,result,multiplier,payout)
  values(v_user,'zabita_raid',p_stake,v_choice,v_result,v_multiplier,v_payout)
  returning id into v_play_id;

  return jsonb_build_object(
    'play_id',v_play_id,
    'game_key','zabita_raid',
    'choice',v_choice,
    'result',v_result,
    'multiplier',v_multiplier,
    'payout',v_payout,
    'balance',v_balance
  );
end;
$$;

revoke all on function public.play_zabita_raid(bigint,text) from public;
revoke all on function public.play_zabita_raid(bigint,text) from anon;
grant execute on function public.play_zabita_raid(bigint,text) to authenticated;
