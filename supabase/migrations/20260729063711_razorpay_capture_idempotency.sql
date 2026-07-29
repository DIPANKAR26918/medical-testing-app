-- A captured payment remains terminal after partial or full refunds. Late
-- capture webhooks must return the current booking instead of attempting to
-- move the financial state back to `paid`.
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

  if paid_order.payment_status in (
       'paid',
       'partially_refunded',
       'refunded'
     )
     and payment_attempt.status in (
       'captured',
       'partially_refunded',
       'refunded'
     ) then
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

revoke all on function public.finalize_razorpay_payment(
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
