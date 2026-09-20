-- Project Afyon 042 — Boxing scorecards justice
-- Decision outcomes are derived from round-by-round ring events instead of being preselected.
-- Also corrects the Théo Lambert vs Atlas Parsak archive bout and its one-leg coupon.

create or replace function private.rescore_boxing_decision(p_bout_id text)
returns void
language plpgsql
security definer
set search_path to 'public','private'
as $function$
declare
  b public.boxing_bouts%rowtype;
  p private.boxing_bout_plans%rowtype;
  r public.boxing_fighters%rowtype;
  bl public.boxing_fighters%rowtype;
  v_round integer;

  v_red_base numeric; v_blue_base numeric;
  v_red_tech numeric; v_blue_tech numeric;
  v_red_power numeric; v_blue_power numeric;
  v_red_kd integer; v_blue_kd integer;

  v_base_red integer; v_base_blue integer;
  v_j1_red_round integer; v_j1_blue_round integer;
  v_j2_red_round integer; v_j2_blue_round integer;
  v_j3_red_round integer; v_j3_blue_round integer;

  v_j1_red integer:=0; v_j1_blue integer:=0;
  v_j2_red integer:=0; v_j2_blue integer:=0;
  v_j3_red integer:=0; v_j3_blue integer:=0;

  v_base_leader text;
  v_j1_side text; v_j2_side text; v_j3_side text;
  v_red_cards integer:=0; v_blue_cards integer:=0; v_even_cards integer:=0;
  v_winner text; v_winner_side text; v_method text; v_actor text;
begin
  select * into b from public.boxing_bouts where id=p_bout_id;
  if not found then return; end if;

  select * into p from private.boxing_bout_plans where bout_id=b.id;
  if not found or p.method in ('KO','TKO') then return; end if;

  select * into r from public.boxing_fighters where id=b.red_fighter_id;
  select * into bl from public.boxing_fighters where id=b.blue_fighter_id;

  for v_round in 1..b.rounds loop
    select
      coalesce(sum(case when e.side='red' then
        case e.event_type
          when 'jab' then 1.00 when 'body_shot' then 1.25 when 'combo' then 2.10
          when 'counter' then 2.25 when 'power_shot' then 3.20 when 'knockdown' then 7.00 else 0 end
      else 0 end),0),
      coalesce(sum(case when e.side='blue' then
        case e.event_type
          when 'jab' then 1.00 when 'body_shot' then 1.25 when 'combo' then 2.10
          when 'counter' then 2.25 when 'power_shot' then 3.20 when 'knockdown' then 7.00 else 0 end
      else 0 end),0),

      coalesce(sum(case when e.side='red' then
        case e.event_type
          when 'jab' then 1.20 when 'body_shot' then 1.20 when 'combo' then 2.00
          when 'counter' then 2.50 when 'power_shot' then 2.80 when 'knockdown' then 7.00 else 0 end
      else 0 end),0),
      coalesce(sum(case when e.side='blue' then
        case e.event_type
          when 'jab' then 1.20 when 'body_shot' then 1.20 when 'combo' then 2.00
          when 'counter' then 2.50 when 'power_shot' then 2.80 when 'knockdown' then 7.00 else 0 end
      else 0 end),0),

      coalesce(sum(case when e.side='red' then
        case e.event_type
          when 'jab' then .80 when 'body_shot' then 1.35 when 'combo' then 2.30
          when 'counter' then 2.00 when 'power_shot' then 3.60 when 'knockdown' then 7.50 else 0 end
      else 0 end),0),
      coalesce(sum(case when e.side='blue' then
        case e.event_type
          when 'jab' then .80 when 'body_shot' then 1.35 when 'combo' then 2.30
          when 'counter' then 2.00 when 'power_shot' then 3.60 when 'knockdown' then 7.50 else 0 end
      else 0 end),0),

      count(*) filter(where e.event_type='knockdown' and e.side='red' and not coalesce((e.payload->>'finish')::boolean,false)),
      count(*) filter(where e.event_type='knockdown' and e.side='blue' and not coalesce((e.payload->>'finish')::boolean,false))
    into
      v_red_base,v_blue_base,
      v_red_tech,v_blue_tech,
      v_red_power,v_blue_power,
      v_red_kd,v_blue_kd
    from public.boxing_bout_events e
    where e.bout_id=b.id and e.round=v_round;

    -- Balanced official round card shown in the UI.
    if v_red_base>v_blue_base then
      v_base_red:=greatest(7,10-v_blue_kd);
      v_base_blue:=greatest(7,9-v_red_kd);
      v_base_leader:='red';
    elsif v_blue_base>v_red_base then
      v_base_red:=greatest(7,9-v_blue_kd);
      v_base_blue:=greatest(7,10-v_red_kd);
      v_base_leader:='blue';
    else
      v_base_red:=greatest(7,10-v_blue_kd);
      v_base_blue:=greatest(7,10-v_red_kd);
      v_base_leader:='even';
    end if;

    -- Judge 1: technical boxing / counters.
    if v_red_tech>v_blue_tech then
      v_j1_red_round:=greatest(7,10-v_blue_kd); v_j1_blue_round:=greatest(7,9-v_red_kd);
    elsif v_blue_tech>v_red_tech then
      v_j1_red_round:=greatest(7,9-v_blue_kd); v_j1_blue_round:=greatest(7,10-v_red_kd);
    else
      v_j1_red_round:=greatest(7,10-v_blue_kd); v_j1_blue_round:=greatest(7,10-v_red_kd);
    end if;

    -- Judge 2: power / combinations.
    if v_red_power>v_blue_power then
      v_j2_red_round:=greatest(7,10-v_blue_kd); v_j2_blue_round:=greatest(7,9-v_red_kd);
    elsif v_blue_power>v_red_power then
      v_j2_red_round:=greatest(7,9-v_blue_kd); v_j2_blue_round:=greatest(7,10-v_red_kd);
    else
      v_j2_red_round:=greatest(7,10-v_blue_kd); v_j2_blue_round:=greatest(7,10-v_red_kd);
    end if;

    -- Judge 3: balanced card.
    v_j3_red_round:=v_base_red;
    v_j3_blue_round:=v_base_blue;

    v_j1_red:=v_j1_red+v_j1_red_round; v_j1_blue:=v_j1_blue+v_j1_blue_round;
    v_j2_red:=v_j2_red+v_j2_red_round; v_j2_blue:=v_j2_blue+v_j2_blue_round;
    v_j3_red:=v_j3_red+v_j3_red_round; v_j3_blue:=v_j3_blue+v_j3_blue_round;

    update public.boxing_bout_events
    set payload=payload||jsonb_build_object(
      'leader',v_base_leader,
      'red_score',v_base_red,
      'blue_score',v_base_blue,
      'red_metric',round(v_red_base,2),
      'blue_metric',round(v_blue_base,2),
      'red_kd',v_red_kd,
      'blue_kd',v_blue_kd
    )
    where bout_id=b.id and round=v_round and event_type='round_end';
  end loop;

  v_j1_side:=case when v_j1_red>v_j1_blue then 'red' when v_j1_blue>v_j1_red then 'blue' else 'even' end;
  v_j2_side:=case when v_j2_red>v_j2_blue then 'red' when v_j2_blue>v_j2_red then 'blue' else 'even' end;
  v_j3_side:=case when v_j3_red>v_j3_blue then 'red' when v_j3_blue>v_j3_red then 'blue' else 'even' end;

  v_red_cards:=(case when v_j1_side='red' then 1 else 0 end)+(case when v_j2_side='red' then 1 else 0 end)+(case when v_j3_side='red' then 1 else 0 end);
  v_blue_cards:=(case when v_j1_side='blue' then 1 else 0 end)+(case when v_j2_side='blue' then 1 else 0 end)+(case when v_j3_side='blue' then 1 else 0 end);
  v_even_cards:=3-v_red_cards-v_blue_cards;

  if v_red_cards>=2 then
    v_winner:=b.red_fighter_id; v_winner_side:='red'; v_actor:=r.name;
    v_method:=case when v_red_cards=3 then 'UD' when v_blue_cards=1 then 'SD' else 'MD' end;
  elsif v_blue_cards>=2 then
    v_winner:=b.blue_fighter_id; v_winner_side:='blue'; v_actor:=bl.name;
    v_method:=case when v_blue_cards=3 then 'UD' when v_red_cards=1 then 'SD' else 'MD' end;
  else
    v_winner:=null; v_winner_side:='neutral'; v_actor:=''; v_method:='DRAW';
  end if;

  update private.boxing_bout_plans
  set winner_id=v_winner,
      method=v_method,
      red_judge_score=round((v_j1_red+v_j2_red+v_j3_red)/3.0)::integer,
      blue_judge_score=round((v_j1_blue+v_j2_blue+v_j3_blue)/3.0)::integer
  where bout_id=b.id;

  update public.boxing_bout_events
  set side=v_winner_side,
      payload=jsonb_build_object(
        'method',v_method,
        'winner_id',v_winner,
        'judges',jsonb_build_array(
          jsonb_build_object('name','AFMB-1','red',v_j1_red,'blue',v_j1_blue,'winner',v_j1_side),
          jsonb_build_object('name','AFMB-2','red',v_j2_red,'blue',v_j2_blue,'winner',v_j2_side),
          jsonb_build_object('name','AFMB-3','red',v_j3_red,'blue',v_j3_blue,'winner',v_j3_side)
        )
      ),
      commentary=case when v_method='DRAW'
        then 'Son gong! Üç hakem kartı sonucu eşitlik çıktı.'
        else 'Hakem kartları açıklandı: '||v_actor||' '||v_method||' ile kazanıyor! '
          ||v_j1_red||'-'||v_j1_blue||' / '
          ||v_j2_red||'-'||v_j2_blue||' / '
          ||v_j3_red||'-'||v_j3_blue
      end
  where bout_id=b.id and event_type='fight_end';
end;
$function$;

create or replace function private.boxing_bout_plan_rescore_trigger()
returns trigger
language plpgsql
security definer
set search_path to 'public','private'
as $function$
begin
  perform private.rescore_boxing_decision(new.bout_id);
  return new;
end;
$function$;

drop trigger if exists boxing_bout_plan_rescore_after_insert on private.boxing_bout_plans;
create trigger boxing_bout_plan_rescore_after_insert
after insert on private.boxing_bout_plans
for each row execute function private.boxing_bout_plan_rescore_trigger();

-- Re-score the archived Théo Lambert vs Atlas Parsak bout.
select private.rescore_boxing_decision(
  (
    select b.id
    from public.boxing_bouts b
    join public.boxing_fighters r on r.id=b.red_fighter_id
    join public.boxing_fighters bl on bl.id=b.blue_fighter_id
    where r.name='Théo Lambert' and bl.name='Atlas Parsak'
    order by b.scheduled_at desc
    limit 1
  )
);

do $correction$
declare
  v_bout public.boxing_bouts%rowtype;
  v_plan private.boxing_bout_plans%rowtype;
  v_old_winner_rating numeric;
  v_old_loser_rating numeric;
  v_old_gain numeric;
  v_old_loss numeric;
  v_pre_old_winner numeric;
  v_pre_old_loser numeric;
  v_new_gain numeric;
  v_new_loss numeric;
  c public.coupons%rowtype;
begin
  select b.* into v_bout
  from public.boxing_bouts b
  join public.boxing_fighters r on r.id=b.red_fighter_id
  join public.boxing_fighters bl on bl.id=b.blue_fighter_id
  where r.name='Théo Lambert' and bl.name='Atlas Parsak'
  order by b.scheduled_at desc
  limit 1;

  if not found then return; end if;

  select * into v_plan from private.boxing_bout_plans where bout_id=v_bout.id;
  if not found then return; end if;

  if v_bout.status='finished'
     and v_bout.winner_id=v_bout.red_fighter_id
     and v_plan.winner_id=v_bout.blue_fighter_id
     and not exists(
       select 1 from public.boxing_bouts later
       where later.status='finished'
         and later.scheduled_at>v_bout.scheduled_at
         and (
           later.red_fighter_id in (v_bout.red_fighter_id,v_bout.blue_fighter_id)
           or later.blue_fighter_id in (v_bout.red_fighter_id,v_bout.blue_fighter_id)
         )
     )
  then
    select rating into v_old_winner_rating from public.boxing_fighters where id=v_bout.red_fighter_id;
    select rating into v_old_loser_rating from public.boxing_fighters where id=v_bout.blue_fighter_id;

    v_old_gain:=greatest(.25,least(1.20,(.45+.035*(v_old_loser_rating-v_old_winner_rating))/.94575));
    v_old_loss:=greatest(.15,v_old_gain*.55);
    v_pre_old_winner:=v_old_winner_rating-v_old_gain;
    v_pre_old_loser:=v_old_loser_rating+v_old_loss;

    v_new_gain:=greatest(.25,least(1.20,.45+(v_pre_old_winner-v_pre_old_loser)*.035));
    v_new_loss:=greatest(.15,v_new_gain*.55);

    update public.boxing_fighters
    set wins=greatest(0,wins-1),
        losses=losses+1,
        rating=greatest(20,v_pre_old_winner-v_new_loss),
        streak_type='L',streak_count=1,updated_at=now()
    where id=v_bout.red_fighter_id;

    update public.boxing_fighters
    set losses=greatest(0,losses-1),
        wins=wins+1,
        rating=least(99,v_pre_old_loser+v_new_gain),
        streak_type='W',streak_count=1,updated_at=now()
    where id=v_bout.blue_fighter_id;

    update public.boxing_bouts
    set winner_id=v_plan.winner_id,
        method=v_plan.method,
        updated_at=now()
    where id=v_bout.id;

    for c in
      select c.*
      from public.coupons c
      join public.coupon_selections cs on cs.coupon_id=c.id
      where cs.bout_id=v_bout.id
        and cs.market_key='BOX_WIN'
        and cs.selection_key='BLUE'
        and c.status='lost'
        and c.payout=0
        and (select count(*) from public.coupon_selections x where x.coupon_id=c.id)=1
      for update
    loop
      update public.coupons
      set status='won',payout=possible_return,settled_at=now()
      where id=c.id;

      update public.wallets
      set balance=balance+c.possible_return,updated_at=now()
      where user_id=c.user_id;
    end loop;
  end if;
end;
$correction$;
