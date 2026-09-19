-- Project Afyon 0.32 — AFMB rescue + leaner starting wallet
-- New accounts start with 5,000 AD. Existing balances are untouched.
-- Authenticated players below 10 AD with no pending coupon can claim
-- the existing 1,000 AD AFMB emergency-work reward after the client challenge.

alter table public.wallets
  alter column balance set default 5000;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;

  insert into public.wallets (user_id, balance)
  values (new.id, 5000)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create or replace function public.claim_afmb_rescue()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
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

  if exists (
    select 1
    from public.coupons c
    where c.user_id = v_user
      and c.status = 'pending'
  ) then
    raise exception 'AFMB_PENDING_COUPON';
  end if;

  update public.wallets
  set balance = balance + 1000,
      updated_at = now()
  where user_id = v_user
  returning balance into v_balance;

  return jsonb_build_object(
    'granted', 1000,
    'balance', v_balance
  );
end;
$$;

revoke all on function public.claim_afmb_rescue() from public;
revoke all on function public.claim_afmb_rescue() from anon;
grant execute on function public.claim_afmb_rescue() to authenticated;
