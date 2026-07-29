-- Secure Razorpay payment lifecycle for Testified bookings.
--
-- Rollout is intentionally disabled by default. This lets the schema and Edge
-- Functions ship before older mobile builds are prevented from creating
-- bookings without Checkout. Enable only after the payment-capable app build is
-- in use and the Razorpay secrets/webhook have been configured.

create schema if not exists private;

create table if not exists private.payment_gateway_settings (
  singleton boolean primary key default true check (singleton),
  enabled boolean not null default false,
  updated_at timestamp with time zone not null default now()
);

insert into private.payment_gateway_settings (singleton, enabled)
values (true, false)
on conflict (singleton) do nothing;

revoke all on table private.payment_gateway_settings
  from public, anon, authenticated;

alter table public.orders
  add column if not exists payment_status text not null default 'not_started',
  add column if not exists payment_provider text,
  add column if not exists paid_at timestamp with time zone;

update public.orders
set payment_status = case
  when status in (
    'confirmed',
    'booking_confirmed',
    'assigned',
    'assigned_agent',
    'agent_assigned',
    'collection_agent_assigned',
    'agent_out_for_collection',
    'out_for_collection',
    'executive_on_the_way',
    'sample_collected',
    'collected',
    'sample_out_for_testing',
    'sample_in_transit',
    'sample_received_at_lab',
    'sample_processing',
    'sample_testing',
    'testing',
    'sample_processed',
    'report_preparing',
    'report_in_making',
    'report_ready',
    'report_out_for_delivery',
    'report_delivered',
    'completed',
    'cancelled',
    'canceled'
  ) then 'not_required'
  else 'not_started'
end
where payment_status = 'not_started';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_payment_status_check'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_payment_status_check
      check (
        payment_status in (
          'not_started',
          'not_required',
          'pending',
          'paid',
          'failed',
          'partially_refunded',
          'refunded'
        )
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_payment_provider_check'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_payment_provider_check
      check (payment_provider is null or payment_provider = 'razorpay');
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_paid_at_check'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_paid_at_check
      check (payment_status <> 'paid' or paid_at is not null);
  end if;
end;
$$;

create table if not exists public.payment_attempts (
  id uuid primary key default gen_random_uuid(),
  order_id bigint not null references public.orders(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null default 'razorpay'
    check (provider = 'razorpay'),
  provider_order_id text unique,
  provider_payment_id text unique,
  receipt text not null unique
    check (char_length(receipt) between 1 and 40),
  amount_paise bigint not null check (amount_paise > 0),
  currency text not null default 'INR'
    check (currency = 'INR'),
  status text not null default 'creating'
    check (
      status in (
        'creating',
        'created',
        'authorized',
        'captured',
        'failed',
        'partially_refunded',
        'refunded'
      )
    ),
  verification_source text
    check (
      verification_source is null
      or verification_source in ('checkout_signature', 'webhook')
    ),
  signature_verified_at timestamp with time zone,
  failure_code text,
  failure_description text,
  captured_at timestamp with time zone,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create unique index if not exists payment_attempts_one_active_per_order_idx
on public.payment_attempts (order_id)
where status in ('creating', 'created', 'authorized', 'captured');

create index if not exists payment_attempts_user_created_idx
on public.payment_attempts (user_id, created_at desc);

create index if not exists payment_attempts_order_created_idx
on public.payment_attempts (order_id, created_at desc);

create table if not exists public.payment_refunds (
  id uuid primary key default gen_random_uuid(),
  payment_attempt_id uuid not null
    references public.payment_attempts(id) on delete cascade,
  order_id bigint not null references public.orders(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider_refund_id text not null unique,
  provider_payment_id text not null,
  amount_paise bigint not null check (amount_paise > 0),
  currency text not null default 'INR' check (currency = 'INR'),
  status text not null default 'processed'
    check (status in ('pending', 'processed', 'failed')),
  created_at timestamp with time zone not null default now(),
  processed_at timestamp with time zone,
  updated_at timestamp with time zone not null default now()
);

create index if not exists payment_refunds_attempt_created_idx
on public.payment_refunds (payment_attempt_id, created_at desc);

create table if not exists public.payment_webhook_events (
  event_id text primary key,
  event_type text not null,
  payload_sha256 text not null,
  status text not null default 'processing'
    check (status in ('processing', 'processed', 'failed', 'ignored')),
  last_error text,
  received_at timestamp with time zone not null default now(),
  processed_at timestamp with time zone,
  updated_at timestamp with time zone not null default now()
);

alter table public.payment_attempts enable row level security;
alter table public.payment_refunds enable row level security;
alter table public.payment_webhook_events enable row level security;

drop policy if exists "Customers can view own payment attempts"
  on public.payment_attempts;
create policy "Customers can view own payment attempts"
on public.payment_attempts
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Customers can view own payment refunds"
  on public.payment_refunds;
create policy "Customers can view own payment refunds"
on public.payment_refunds
for select
to authenticated
using ((select auth.uid()) = user_id);

-- New public tables are not guaranteed to be exposed to the Data API. Grant
-- only the read access the mobile client actually needs; all mutations remain
-- server-only.
grant select on table public.payment_attempts, public.payment_refunds
  to authenticated;
revoke insert, update, delete, truncate, references, trigger
  on table public.payment_attempts, public.payment_refunds
  from anon, authenticated;
revoke all on table public.payment_webhook_events
  from public, anon, authenticated;

grant all on table
  public.payment_attempts,
  public.payment_refunds,
  public.payment_webhook_events
to service_role;

-- Keep direct client inserts limited to the initial prescription-upload row.
-- In particular, a client cannot insert payment_status = 'paid'.
drop policy if exists "Users can insert their own orders" on public.orders;
create policy "Users can insert their own orders"
on public.orders
for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and agent_id is null
  and booking_source = 'prescription'
  and status = 'uploaded'
  and coalesce(array_length(test_list, 1), 0) = 0
  and coalesce(price, 0) = 0
  and payment_status = 'not_started'
  and payment_provider is null
  and paid_at is null
);

revoke update, delete on table public.orders from anon, authenticated;
grant select, insert on table public.orders to authenticated;

create or replace function private.enforce_payment_before_confirmation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  gateway_enabled boolean := false;
  last_timeline_index integer;
  last_timeline_status text;
begin
  if new.status not in ('confirmed', 'booking_confirmed') then
    return new;
  end if;

  select settings.enabled
  into gateway_enabled
  from private.payment_gateway_settings as settings
  where settings.singleton = true;

  if coalesce(new.price, 0) <= 0
     or not coalesce(gateway_enabled, false) then
    if new.payment_status not in (
      'paid',
      'partially_refunded',
      'refunded'
    ) then
      new.payment_status := 'not_required';
      new.payment_provider := null;
    end if;
    return new;
  end if;

  if new.payment_status in ('paid', 'not_required') then
    return new;
  end if;

  new.status := 'payment_pending';
  new.payment_status := 'pending';
  new.payment_provider := 'razorpay';
  new.paid_at := null;

  last_timeline_index := array_upper(new.timeline, 1);
  if last_timeline_index is not null then
    last_timeline_status := lower(
      replace(
        replace(
          coalesce(new.timeline[last_timeline_index] ->> 'status', ''),
          '-',
          '_'
        ),
        ' ',
        '_'
      )
    );
  end if;

  if last_timeline_status in ('confirmed', 'booking_confirmed') then
    new.timeline[last_timeline_index] :=
      (new.timeline[last_timeline_index] - 'status' - 'message')
      || jsonb_build_object(
        'status', 'payment_pending',
        'message', 'Complete payment to confirm this booking.'
      );
  else
    new.timeline := array_append(
      coalesce(new.timeline, '{}'::jsonb[]),
      jsonb_build_object(
        'status', 'payment_pending',
        'message', 'Complete payment to confirm this booking.',
        'timestamp', now(),
        'source', 'razorpay'
      )
    );
  end if;

  return new;
end;
$$;

revoke all on function private.enforce_payment_before_confirmation()
  from public, anon, authenticated, service_role;

drop trigger if exists orders_require_payment_before_confirmation
  on public.orders;
create trigger orders_require_payment_before_confirmation
before insert or update of status, price, payment_status
on public.orders
for each row
execute function private.enforce_payment_before_confirmation();

create or replace function public.finalize_razorpay_payment(
  p_provider_order_id text,
  p_provider_payment_id text,
  p_amount_paise bigint,
  p_currency text,
  p_verification_source text
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  payment_attempt public.payment_attempts;
  paid_order public.orders;
  confirmation_message text;
begin
  if nullif(trim(p_provider_order_id), '') is null
     or nullif(trim(p_provider_payment_id), '') is null then
    raise exception 'A valid Razorpay order and payment are required.'
      using errcode = '22023';
  end if;

  if p_amount_paise <= 0 or upper(trim(p_currency)) <> 'INR' then
    raise exception 'The payment amount or currency is invalid.'
      using errcode = '22023';
  end if;

  if p_verification_source not in ('checkout_signature', 'webhook') then
    raise exception 'The payment verification source is invalid.'
      using errcode = '22023';
  end if;

  select attempt.*
  into payment_attempt
  from public.payment_attempts as attempt
  where attempt.provider_order_id = trim(p_provider_order_id)
  for update;

  if payment_attempt.id is null then
    raise exception 'The Razorpay order is not registered.'
      using errcode = 'P0002';
  end if;

  if payment_attempt.amount_paise <> p_amount_paise
     or payment_attempt.currency <> upper(trim(p_currency)) then
    raise exception 'The captured payment does not match the booking total.'
      using errcode = '22023';
  end if;

  if payment_attempt.provider_payment_id is not null
     and payment_attempt.provider_payment_id <> trim(p_provider_payment_id) then
    raise exception 'This Razorpay order is linked to another payment.'
      using errcode = '23505';
  end if;

  select customer_order.*
  into paid_order
  from public.orders as customer_order
  where customer_order.id = payment_attempt.order_id
    and customer_order.user_id = payment_attempt.user_id
  for update;

  if paid_order.id is null then
    raise exception 'The booking for this payment is unavailable.'
      using errcode = 'P0002';
  end if;

  if paid_order.payment_status = 'paid'
     and payment_attempt.status = 'captured' then
    return paid_order;
  end if;

  if paid_order.status <> 'payment_pending'
     or paid_order.payment_status not in ('pending', 'failed') then
    raise exception 'This booking is not awaiting payment.'
      using errcode = 'P0001';
  end if;

  update public.payment_attempts
  set
    provider_payment_id = trim(p_provider_payment_id),
    status = 'captured',
    verification_source = p_verification_source,
    signature_verified_at = case
      when p_verification_source = 'checkout_signature' then now()
      else signature_verified_at
    end,
    failure_code = null,
    failure_description = null,
    captured_at = coalesce(captured_at, now()),
    updated_at = now()
  where id = payment_attempt.id;

  confirmation_message := case
    when paid_order.fulfillment_mode = 'lab_visit'
      then 'Payment received. Your lab appointment is confirmed.'
    else 'Payment received. Your home collection booking is confirmed.'
  end;

  update public.orders as customer_order
  set
    status = 'confirmed',
    payment_status = 'paid',
    payment_provider = 'razorpay',
    paid_at = coalesce(customer_order.paid_at, now()),
    updated_at = now(),
    timeline = array_append(
      coalesce(customer_order.timeline, '{}'::jsonb[]),
      jsonb_build_object(
        'status', 'confirmed',
        'message', confirmation_message,
        'timestamp', now(),
        'source', 'razorpay',
        'payment_id', trim(p_provider_payment_id)
      )
    )
  where customer_order.id = paid_order.id
  returning customer_order.* into paid_order;

  return paid_order;
end;
$$;

create or replace function public.record_razorpay_payment_failure(
  p_provider_order_id text,
  p_provider_payment_id text,
  p_failure_code text,
  p_failure_description text
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  payment_attempt public.payment_attempts;
  failed_order public.orders;
begin
  select attempt.*
  into payment_attempt
  from public.payment_attempts as attempt
  where attempt.provider_order_id = trim(p_provider_order_id)
  for update;

  if payment_attempt.id is null then
    raise exception 'The Razorpay order is not registered.'
      using errcode = 'P0002';
  end if;

  select customer_order.*
  into failed_order
  from public.orders as customer_order
  where customer_order.id = payment_attempt.order_id
  for update;

  if payment_attempt.status in (
    'captured',
    'partially_refunded',
    'refunded'
  ) or failed_order.payment_status in (
    'paid',
    'partially_refunded',
    'refunded'
  ) then
    return failed_order;
  end if;

  update public.payment_attempts
  set
    provider_payment_id = coalesce(
      nullif(trim(p_provider_payment_id), ''),
      provider_payment_id
    ),
    status = 'failed',
    failure_code = left(nullif(trim(p_failure_code), ''), 160),
    failure_description = left(
      nullif(trim(p_failure_description), ''),
      500
    ),
    updated_at = now()
  where id = payment_attempt.id;

  update public.orders as customer_order
  set
    payment_status = 'failed',
    updated_at = now(),
    timeline = array_append(
      coalesce(customer_order.timeline, '{}'::jsonb[]),
      jsonb_build_object(
        'status', 'payment_failed',
        'message', 'The payment was not completed. You can try again.',
        'timestamp', now(),
        'source', 'razorpay'
      )
    )
  where customer_order.id = failed_order.id
    and customer_order.status = 'payment_pending'
    and customer_order.payment_status in ('not_started', 'pending', 'failed')
  returning customer_order.* into failed_order;

  return failed_order;
end;
$$;

create or replace function public.record_razorpay_refund(
  p_provider_refund_id text,
  p_provider_payment_id text,
  p_amount_paise bigint,
  p_currency text,
  p_status text
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  payment_attempt public.payment_attempts;
  refunded_order public.orders;
  refunded_total bigint;
  resulting_payment_status text;
begin
  if nullif(trim(p_provider_refund_id), '') is null
     or nullif(trim(p_provider_payment_id), '') is null
     or p_amount_paise <= 0
     or upper(trim(p_currency)) <> 'INR'
     or p_status not in ('pending', 'processed', 'failed') then
    raise exception 'The refund payload is invalid.'
      using errcode = '22023';
  end if;

  select attempt.*
  into payment_attempt
  from public.payment_attempts as attempt
  where attempt.provider_payment_id = trim(p_provider_payment_id)
  for update;

  if payment_attempt.id is null then
    raise exception 'The payment for this refund is unavailable.'
      using errcode = 'P0002';
  end if;

  insert into public.payment_refunds (
    payment_attempt_id,
    order_id,
    user_id,
    provider_refund_id,
    provider_payment_id,
    amount_paise,
    currency,
    status,
    processed_at,
    updated_at
  )
  values (
    payment_attempt.id,
    payment_attempt.order_id,
    payment_attempt.user_id,
    trim(p_provider_refund_id),
    trim(p_provider_payment_id),
    p_amount_paise,
    'INR',
    p_status,
    case when p_status = 'processed' then now() else null end,
    now()
  )
  on conflict (provider_refund_id) do update
  set
    status = excluded.status,
    processed_at = case
      when excluded.status = 'processed'
        then coalesce(public.payment_refunds.processed_at, now())
      else public.payment_refunds.processed_at
    end,
    updated_at = now();

  select coalesce(sum(refund.amount_paise), 0)
  into refunded_total
  from public.payment_refunds as refund
  where refund.payment_attempt_id = payment_attempt.id
    and refund.status = 'processed';

  resulting_payment_status := case
    when refunded_total >= payment_attempt.amount_paise then 'refunded'
    when refunded_total > 0 then 'partially_refunded'
    else 'paid'
  end;

  update public.payment_attempts
  set
    status = case
      when resulting_payment_status = 'refunded' then 'refunded'
      when resulting_payment_status = 'partially_refunded'
        then 'partially_refunded'
      else status
    end,
    updated_at = now()
  where id = payment_attempt.id;

  update public.orders as customer_order
  set
    payment_status = resulting_payment_status,
    updated_at = now(),
    timeline = array_append(
      coalesce(customer_order.timeline, '{}'::jsonb[]),
      jsonb_build_object(
        'status', resulting_payment_status,
        'message', case
          when resulting_payment_status = 'refunded'
            then 'Your payment has been refunded.'
          else 'A partial refund has been processed.'
        end,
        'timestamp', now(),
        'source', 'razorpay',
        'refund_id', trim(p_provider_refund_id)
      )
    )
  where customer_order.id = payment_attempt.order_id
    and customer_order.payment_status is distinct from resulting_payment_status
  returning customer_order.* into refunded_order;

  if refunded_order.id is null then
    select customer_order.*
    into refunded_order
    from public.orders as customer_order
    where customer_order.id = payment_attempt.order_id;
  end if;

  return refunded_order;
end;
$$;

revoke all on function public.finalize_razorpay_payment(
  text,
  text,
  bigint,
  text,
  text
) from public, anon, authenticated;
revoke all on function public.record_razorpay_payment_failure(
  text,
  text,
  text,
  text
) from public, anon, authenticated;
revoke all on function public.record_razorpay_refund(
  text,
  text,
  bigint,
  text,
  text
) from public, anon, authenticated;

grant execute on function public.finalize_razorpay_payment(
  text,
  text,
  bigint,
  text,
  text
) to service_role;
grant execute on function public.record_razorpay_payment_failure(
  text,
  text,
  text,
  text
) to service_role;
grant execute on function public.record_razorpay_refund(
  text,
  text,
  bigint,
  text,
  text
) to service_role;

comment on table public.payment_attempts is
  'Server-owned Razorpay order and payment lifecycle for Testified bookings.';
comment on table public.payment_webhook_events is
  'Idempotency ledger for signature-verified Razorpay webhooks.';
comment on column public.orders.payment_status is
  'Financial state kept separate from the medical fulfilment status.';
