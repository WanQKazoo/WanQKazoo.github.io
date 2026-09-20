-- Project Afyon 040 — AFMB rescue eligibility hotfix
-- Pending coupons are not liquid balance. Rescue is allowed whenever the authenticated wallet is below 10 ₳D.

create or replace function public.claim_afmb_rescue()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select w.balance
  into v_balance
  from public.wallets w
  where w.user_id = v_user
  for update;

  if not found then
    raise exception 'WALLET_NOT_FOUND';
  end if;

  if v_balance >= 10 then
    raise exception 'AFMB_NOT_ELIGIBLE';
  end if;

  update public.wallets
  set balance = balance + 1000,
      updated_at = now()
  where user_id = v_user
  returning balance into v_balance;

  return jsonb_build_object('granted',1000,'balance',v_balance);
end;
$function$;
