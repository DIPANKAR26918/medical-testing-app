create extension if not exists pg_net with schema extensions;

alter table public.notifications
  add column if not exists event_key text;

create unique index if not exists notifications_event_key_unique
on public.notifications (event_key)
where event_key is not null;

comment on table public.notifications is
  'Trusted notification event log and durable push-delivery source.';

-- The new mobile client does not subscribe to this table through Realtime.
-- Existing owner-only RLS policies remain during rollout so an older installed
-- build does not fail before the user updates the app.

create schema if not exists private;

create table if not exists private.notification_outbox (
  notification_id uuid primary key
    references public.notifications(id) on delete cascade,
  dispatch_token uuid not null default gen_random_uuid() unique,
  status text not null default 'pending',
  attempts integer not null default 0,
  next_attempt_at timestamptz,
  locked_at timestamptz,
  delivered_at timestamptz,
  last_error text,
  last_request_id bigint,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notification_outbox_status_check
    check (
      status in (
        'pending',
        'delivering',
        'waiting_for_device',
        'failed',
        'delivered'
      )
    ),
  constraint notification_outbox_attempts_check
    check (attempts >= 0)
);

create index if not exists notification_outbox_due_idx
on private.notification_outbox (next_attempt_at, created_at)
where status <> 'delivered';

revoke all on table private.notification_outbox
from public, anon, authenticated;

create or replace function private.order_notification_payload(
  p_status text,
  p_booking_source text
)
returns table (
  title text,
  body text,
  kind text,
  destination text
)
language plpgsql
immutable
set search_path = ''
as $$
declare
  normalized_status text := lower(trim(coalesce(p_status, '')));
  normalized_source text := lower(
    trim(coalesce(p_booking_source, 'prescription'))
  );
begin
  if normalized_status = 'uploaded' then
    title := 'Prescription received';
    body :=
      'We received your prescription and will prepare a test list for your review. Tap to track it.';
    kind := 'prescription_received';
    destination := 'order_details';
  elsif normalized_status in (
    'under_review',
    'processing',
    'prescription_reviewing',
    'review_started'
  ) then
    title := 'Prescription review started';
    body :=
      'A verified team member is reviewing your prescription. Tap to see the latest status.';
    kind := 'prescription_review_started';
    destination := 'order_details';
  elsif normalized_status in (
    'awaiting_user_approval',
    'test_list_prepared',
    'tests_prepared'
  ) then
    title := 'Your test list is ready';
    body :=
      'Your prescription review is complete. Tap to review the prepared tests and choose what to book.';
    kind := 'prescription_tests_ready';
    destination := 'prescription_review';
  elsif normalized_status = 'booking_requested'
      and normalized_source = 'direct_test' then
    title := 'Test booking received';
    body :=
      'Thanks for choosing Testified. Tap to view your selected tests and collection details.';
    kind := 'direct_booking_received';
    destination := 'order_details';
  elsif normalized_status = 'booking_requested' then
    title := 'Booking request received';
    body :=
      'We are confirming your selected tests and collection details. Tap to follow the booking.';
    kind := 'booking_received';
    destination := 'order_details';
  elsif normalized_status in ('confirmed', 'booking_confirmed') then
    title := 'Booking confirmed';
    body :=
      'Thanks for choosing Testified. Tap to view your booked tests and collection details.';
    kind := 'booking_confirmed';
    destination := 'order_details';
  elsif normalized_status in (
    'assigned',
    'agent_assigned',
    'assigned_agent',
    'collection_agent_assigned'
  ) then
    title := 'Collection executive assigned';
    body :=
      'A verified collection executive has been assigned. Tap to view your booking.';
    kind := 'collection_assigned';
    destination := 'order_details';
  elsif normalized_status in (
    'agent_out_for_collection',
    'out_for_collection',
    'executive_on_the_way'
  ) then
    title := 'Collection executive is on the way';
    body :=
      'Your collection executive is travelling to your location. Tap to track the update.';
    kind := 'collection_on_the_way';
    destination := 'order_details';
  elsif normalized_status in ('collected', 'sample_collected') then
    title := 'Sample collected';
    body :=
      'Your sample is on its way to the lab. Tap to follow the testing progress.';
    kind := 'sample_collected';
    destination := 'order_details';
  elsif normalized_status in (
    'testing',
    'lab_testing',
    'sample_out_for_testing',
    'sample_processing'
  ) then
    title := 'Testing in progress';
    body :=
      'The lab is processing your sample now. Tap to see the latest status.';
    kind := 'testing_in_progress';
    destination := 'order_details';
  elsif normalized_status in ('completed', 'report_ready', 'reports_ready') then
    title := 'Your reports are ready';
    body := 'Your reports are ready to view securely in Testified.';
    kind := 'report_ready';
    destination := 'reports';
  elsif normalized_status in ('cancelled', 'canceled') then
    title := 'Booking cancelled';
    body := 'Your booking was cancelled. Tap to view the booking details.';
    kind := 'booking_cancelled';
    destination := 'order_details';
  else
    return;
  end if;

  return next;
end;
$$;

create or replace function private.create_order_status_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_status text := lower(trim(coalesce(new.status, '')));
  notification_title text;
  notification_body text;
  notification_kind text;
  notification_destination text;
begin
  if tg_op = 'UPDATE' and new.status is not distinct from old.status then
    return new;
  end if;

  select
    payload.title,
    payload.body,
    payload.kind,
    payload.destination
  into
    notification_title,
    notification_body,
    notification_kind,
    notification_destination
  from private.order_notification_payload(
    normalized_status,
    new.booking_source
  ) as payload;

  if notification_title is null
     or notification_body is null
     or notification_destination is null then
    return new;
  end if;

  insert into public.notifications (
    user_id,
    title,
    body,
    kind,
    event_key,
    data
  )
  values (
    new.user_id,
    notification_title,
    notification_body,
    notification_kind,
    format('order:%s:status:%s', new.id, normalized_status),
    jsonb_build_object(
      'destination', notification_destination,
      'order_id', new.id::text,
      'status', normalized_status,
      'booking_source', new.booking_source
    )
  )
  on conflict (event_key) where event_key is not null do nothing;

  return new;
end;
$$;

create or replace function private.request_notification_delivery(
  p_notification_id uuid,
  p_dispatch_token uuid
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  dispatch_url text;
  request_id bigint;
begin
  select secret.decrypted_secret
  into dispatch_url
  from vault.decrypted_secrets as secret
  where secret.name = 'testified_notification_dispatch_url'
  limit 1;

  if dispatch_url is null or trim(dispatch_url) = '' then
    update private.notification_outbox
    set
      status = 'failed',
      last_error = 'dispatch_url_not_configured',
      next_attempt_at = now() + interval '15 minutes',
      updated_at = now()
    where notification_id = p_notification_id;
    return null;
  end if;

  select net.http_post(
    url := dispatch_url,
    body := jsonb_build_object(
      'notification_id', p_notification_id,
      'dispatch_token', p_dispatch_token
    ),
    headers := jsonb_build_object('Content-Type', 'application/json'),
    timeout_milliseconds := 5000
  )
  into request_id;

  update private.notification_outbox
  set
    last_request_id = request_id,
    next_attempt_at = now() + interval '2 minutes',
    updated_at = now()
  where notification_id = p_notification_id;

  return request_id;
end;
$$;

create or replace function private.queue_notification_delivery()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  token uuid;
begin
  insert into private.notification_outbox (
    notification_id,
    next_attempt_at
  )
  values (new.id, now())
  on conflict (notification_id) do update
  set updated_at = now()
  returning dispatch_token into token;

  perform private.request_notification_delivery(new.id, token);
  return new;
end;
$$;

create or replace function public.claim_notification_delivery(
  p_notification_id uuid,
  p_dispatch_token uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  queued private.notification_outbox%rowtype;
  payload jsonb;
begin
  select outbox.*
  into queued
  from private.notification_outbox as outbox
  where outbox.notification_id = p_notification_id
    and outbox.dispatch_token = p_dispatch_token
  for update;

  if not found then
    return jsonb_build_object('state', 'unauthorized');
  end if;

  if queued.status = 'delivered' then
    return jsonb_build_object('state', 'already_delivered');
  end if;

  if queued.status = 'delivering'
     and queued.locked_at > now() - interval '90 seconds' then
    return jsonb_build_object('state', 'busy');
  end if;

  update private.notification_outbox
  set
    status = 'delivering',
    attempts = attempts + 1,
    locked_at = now(),
    updated_at = now()
  where notification_id = p_notification_id;

  select jsonb_build_object(
    'state', 'ready',
    'notification_id', notification.id,
    'title', notification.title,
    'body', notification.body,
    'kind', notification.kind,
    'data', notification.data,
    'devices', coalesce((
      select jsonb_agg(jsonb_build_object('token', device.token))
      from public.push_devices as device
      where device.user_id = notification.user_id
        and device.enabled = true
    ), '[]'::jsonb)
  )
  into payload
  from public.notifications as notification
  where notification.id = p_notification_id;

  return coalesce(payload, jsonb_build_object('state', 'missing'));
end;
$$;

create or replace function public.complete_notification_delivery(
  p_notification_id uuid,
  p_dispatch_token uuid,
  p_status text,
  p_error text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_status text := lower(trim(coalesce(p_status, '')));
begin
  if normalized_status not in (
    'delivered',
    'waiting_for_device',
    'failed'
  ) then
    raise exception 'Invalid delivery status' using errcode = '22023';
  end if;

  update private.notification_outbox
  set
    status = normalized_status,
    delivered_at = case
      when normalized_status = 'delivered' then now()
      else delivered_at
    end,
    locked_at = null,
    next_attempt_at = case
      when normalized_status = 'delivered' then null
      when normalized_status = 'waiting_for_device'
        then now() + interval '15 minutes'
      else now() + interval '5 minutes'
    end,
    last_error = case
      when normalized_status = 'delivered' then null
      else left(nullif(trim(coalesce(p_error, '')), ''), 200)
    end,
    updated_at = now()
  where notification_id = p_notification_id
    and dispatch_token = p_dispatch_token;

  return found;
end;
$$;

create or replace function private.dispatch_user_pending_notifications()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  queued record;
begin
  if new.enabled is not true then
    return new;
  end if;

  for queued in
    select outbox.notification_id, outbox.dispatch_token
    from private.notification_outbox as outbox
    join public.notifications as notification
      on notification.id = outbox.notification_id
    where notification.user_id = new.user_id
      and outbox.status <> 'delivered'
      and (
        outbox.status <> 'delivering'
        or outbox.locked_at is null
        or outbox.locked_at <= now() - interval '90 seconds'
      )
    order by outbox.created_at
    for update of outbox skip locked
    limit 20
  loop
    perform private.request_notification_delivery(
      queued.notification_id,
      queued.dispatch_token
    );
  end loop;

  return new;
end;
$$;

create or replace function private.dispatch_due_notifications(
  p_limit integer default 50
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  queued record;
  dispatched integer := 0;
begin
  for queued in
    select outbox.notification_id, outbox.dispatch_token
    from private.notification_outbox as outbox
    join public.notifications as notification
      on notification.id = outbox.notification_id
    where outbox.status <> 'delivered'
      and coalesce(outbox.next_attempt_at, now()) <= now()
      and (
        outbox.status <> 'delivering'
        or outbox.locked_at is null
        or outbox.locked_at <= now() - interval '90 seconds'
      )
      and exists (
        select 1
        from public.push_devices as device
        where device.user_id = notification.user_id
          and device.enabled = true
      )
    order by outbox.created_at
    for update of outbox skip locked
    limit greatest(1, least(coalesce(p_limit, 50), 200))
  loop
    perform private.request_notification_delivery(
      queued.notification_id,
      queued.dispatch_token
    );
    dispatched := dispatched + 1;
  end loop;

  return dispatched;
end;
$$;

drop trigger if exists notifications_queue_push_delivery
on public.notifications;
create trigger notifications_queue_push_delivery
after insert on public.notifications
for each row execute function private.queue_notification_delivery();

drop trigger if exists orders_create_status_notification
on public.orders;
create trigger orders_create_status_notification
after insert or update of status on public.orders
for each row execute function private.create_order_status_notification();

drop trigger if exists push_devices_dispatch_pending_notifications
on public.push_devices;
create trigger push_devices_dispatch_pending_notifications
after insert or update of enabled on public.push_devices
for each row execute function private.dispatch_user_pending_notifications();

-- Keep any not-yet-delivered events compatible after the inbox route is
-- removed. Already delivered rows are harmless to backfill as well.
update public.notifications
set data = (
  coalesce(data, '{}'::jsonb) - 'route' - 'tab_index' - 'tabIndex'
) || jsonb_build_object(
  'destination',
  case
    when coalesce(data ->> 'medical_test_id', '') <> ''
      then 'test_details'
    when lower(coalesce(data ->> 'status', '')) in (
      'awaiting_user_approval',
      'test_list_prepared',
      'tests_prepared'
    ) then 'prescription_review'
    when lower(coalesce(data ->> 'status', '')) in (
      'completed',
      'report_ready',
      'reports_ready'
    ) then 'reports'
    when coalesce(data ->> 'order_id', '') <> ''
      then 'order_details'
    else 'home'
  end
)
where not (coalesce(data, '{}'::jsonb) ? 'destination');

revoke all on function private.order_notification_payload(text, text)
from public, anon, authenticated;
revoke all on function private.create_order_status_notification()
from public, anon, authenticated;
revoke all on function private.request_notification_delivery(uuid, uuid)
from public, anon, authenticated;
revoke all on function private.queue_notification_delivery()
from public, anon, authenticated;
revoke all on function private.dispatch_user_pending_notifications()
from public, anon, authenticated;
revoke all on function private.dispatch_due_notifications(integer)
from public, anon, authenticated;

revoke all on function public.claim_notification_delivery(uuid, uuid)
from public, anon, authenticated;
revoke all on function public.complete_notification_delivery(
  uuid,
  uuid,
  text,
  text
) from public, anon, authenticated;

grant execute on function public.claim_notification_delivery(uuid, uuid)
to service_role;
grant execute on function public.complete_notification_delivery(
  uuid,
  uuid,
  text,
  text
) to service_role;

drop function if exists private.order_notification_copy(text);
