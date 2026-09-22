-- Project Afyon 051 — AFMB Gece Masası
-- Daily live-ish studio briefing from real player/world data + one vote per user/day.

create table if not exists private.afmb_night_votes(
  vote_day date not null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  choice text not null check(choice in ('MERT','HAKEM','KINALI','SISTEM')),
  created_at timestamptz not null default now(),
  primary key(vote_day,user_id)
);

alter table private.afmb_night_votes enable row level security;
create index if not exists afmb_night_votes_user_id_idx on private.afmb_night_votes(user_id);
revoke all on table private.afmb_night_votes from public,anon,authenticated;

create or replace function public.get_afmb_night_desk()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
  v_day date:=(now() at time zone 'Europe/Istanbul')::date;
  v_start timestamptz;
  v_end timestamptz;
  v_name text;
  v_balance bigint:=0;
  v_coupon jsonb:='{}'::jsonb;
  v_chance jsonb:='{}'::jsonb;
  v_special jsonb:='{}'::jsonb;
  v_boxing jsonb:='{}'::jsonb;
  v_luxury jsonb:='{}'::jsonb;
  v_poll jsonb:='{}'::jsonb;
  v_my_vote text;
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if not exists(select 1 from public.profiles where id=v_user) then raise exception 'Profil bulunamadı.'; end if;

  v_start:=(v_day::timestamp at time zone 'Europe/Istanbul');
  v_end:=((v_day+1)::timestamp at time zone 'Europe/Istanbul');

  select p.display_name,coalesce(w.balance,0)
  into v_name,v_balance
  from public.profiles p
  left join public.wallets w on w.user_id=p.id
  where p.id=v_user;

  select coalesce(jsonb_build_object(
    'id',c.id,'stake',c.stake,'odds',c.total_odds,'status',c.status,
    'possible_return',c.possible_return,'payout',c.payout,'created_at',c.created_at
  ),'{}'::jsonb)
  into v_coupon
  from public.coupons c
  where c.user_id=v_user and c.created_at>=v_start and c.created_at<v_end
  order by c.stake desc,c.created_at desc
  limit 1;

  select jsonb_build_object(
    'plays',count(*),
    'stake',coalesce(sum(cp.stake),0),
    'payout',coalesce(sum(cp.payout),0),
    'net',coalesce(sum(cp.payout-cp.stake),0),
    'favorite_game',coalesce((
      select cp2.game_key
      from public.chance_plays cp2
      where cp2.user_id=v_user and cp2.created_at>=v_start and cp2.created_at<v_end
      group by cp2.game_key
      order by count(*) desc,sum(cp2.stake) desc,cp2.game_key
      limit 1
    ),'')
  )
  into v_chance
  from public.chance_plays cp
  where cp.user_id=v_user and cp.created_at>=v_start and cp.created_at<v_end;

  select coalesce(jsonb_build_object(
    'id',m.id,'title',m.special_title,'key',m.special_key,'icon',m.special_icon,
    'status',m.status,'outcomes',m.special_outcomes,'kickoff_at',m.kickoff_at
  ),'{}'::jsonb)
  into v_special
  from public.matches m
  where m.sport='special' and m.kickoff_at<v_end
  order by case when m.kickoff_at>=v_start then 0 else 1 end,m.kickoff_at desc
  limit 1;

  select coalesce(jsonb_build_object(
    'id',b.id,'event_name',b.event_name,'status',b.status,'method',b.method,
    'scheduled_at',b.scheduled_at,'red',rf.name,'blue',bf.name,
    'winner',wf.name,'finish_round',b.finish_round
  ),'{}'::jsonb)
  into v_boxing
  from public.boxing_bouts b
  join public.boxing_fighters rf on rf.id=b.red_fighter_id
  join public.boxing_fighters bf on bf.id=b.blue_fighter_id
  left join public.boxing_fighters wf on wf.id=b.winner_id
  where b.scheduled_at<v_end
  order by case when b.scheduled_at>=v_start then 0 else 1 end,b.scheduled_at desc
  limit 1;

  select coalesce(jsonb_build_object(
    'item_key',pl.item_key,'name',lc.name,'icon',lc.icon,'price',pl.price_paid,'purchased_at',pl.purchased_at
  ),'{}'::jsonb)
  into v_luxury
  from public.profile_luxuries pl
  join public.profile_luxury_catalog lc on lc.item_key=pl.item_key
  where pl.user_id=v_user
  order by pl.purchased_at desc
  limit 1;

  select jsonb_build_object(
    'MERT',count(*) filter(where choice='MERT'),
    'HAKEM',count(*) filter(where choice='HAKEM'),
    'KINALI',count(*) filter(where choice='KINALI'),
    'SISTEM',count(*) filter(where choice='SISTEM'),
    'total',count(*)
  )
  into v_poll
  from private.afmb_night_votes
  where vote_day=v_day;

  select choice into v_my_vote
  from private.afmb_night_votes
  where vote_day=v_day and user_id=v_user;

  return jsonb_build_object(
    'day',v_day,
    'display_name',coalesce(v_name,'Vatandaş'),
    'balance',v_balance,
    'coupon',coalesce(v_coupon,'{}'::jsonb),
    'chance',coalesce(v_chance,'{}'::jsonb),
    'special',coalesce(v_special,'{}'::jsonb),
    'boxing',coalesce(v_boxing,'{}'::jsonb),
    'luxury',coalesce(v_luxury,'{}'::jsonb),
    'poll',coalesce(v_poll,'{}'::jsonb),
    'my_vote',v_my_vote,
    'special_case',jsonb_build_object(
      'code','BABA-01',
      'title','Atlas’ın boks maçına baba müdahalesi',
      'subject','Mert Berk Parsak',
      'code_access',true
    )
  );
end;
$function$;

revoke all on function public.get_afmb_night_desk() from public;
revoke all on function public.get_afmb_night_desk() from anon;
grant execute on function public.get_afmb_night_desk() to authenticated;

create or replace function public.cast_afmb_night_vote(p_choice text)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid:=auth.uid();
  v_day date:=(now() at time zone 'Europe/Istanbul')::date;
  v_choice text:=upper(trim(coalesce(p_choice,'')));
begin
  if v_user is null then raise exception 'Giriş yapman gerekiyor.'; end if;
  if not exists(select 1 from public.profiles where id=v_user) then raise exception 'Profil bulunamadı.'; end if;
  if v_choice not in ('MERT','HAKEM','KINALI','SISTEM') then raise exception 'Geçersiz oy.'; end if;
  if exists(select 1 from private.afmb_night_votes where vote_day=v_day and user_id=v_user) then
    raise exception 'Bugünkü oyunu zaten kullandın.';
  end if;

  insert into private.afmb_night_votes(vote_day,user_id,choice)
  values(v_day,v_user,v_choice);

  return public.get_afmb_night_desk();
end;
$function$;

revoke all on function public.cast_afmb_night_vote(text) from public;
revoke all on function public.cast_afmb_night_vote(text) from anon;
grant execute on function public.cast_afmb_night_vote(text) to authenticated;
