-- Appointment slots and end-to-end agent fulfilment for direct and
-- prescription-assisted bookings.

alter table public.orders
  add column if not exists fulfillment_mode text not null default 'home_collection',
  add column if not exists collection_slot_start_at timestamp with time zone,
  add column if not exists collection_slot_end_at timestamp with time zone,
  add column if not exists collection_slot_timezone text not null default 'Asia/Kolkata',
  add column if not exists collection_slot_booked_at timestamp with time zone;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_fulfillment_mode_check'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_fulfillment_mode_check
      check (fulfillment_mode in ('home_collection', 'lab_visit'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_collection_slot_pair_check'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_collection_slot_pair_check
      check (
        (
          collection_slot_start_at is null
          and collection_slot_end_at is null
        )
        or (
          collection_slot_start_at is not null
          and collection_slot_end_at is not null
          and collection_slot_end_at > collection_slot_start_at
          and collection_slot_end_at - collection_slot_start_at = interval '2 hours'
        )
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_collection_slot_timezone_check'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_collection_slot_timezone_check
      check (collection_slot_timezone = 'Asia/Kolkata');
  end if;
end;
$$;

update public.orders as customer_order
set fulfillment_mode = case
  when exists (
    select 1
    from public.order_tests as selected_test
    join public.medical_tests as medical_test
      on medical_test.id = selected_test.medical_test_id
    where selected_test.order_id = customer_order.id
      and selected_test.selected_by_user = true
      and medical_test.lab_visit_required = true
  ) then 'lab_visit'
  else 'home_collection'
end
where customer_order.fulfillment_mode = 'home_collection';

create index if not exists orders_unassigned_agent_work_idx
on public.orders (
  collection_slot_start_at,
  created_at
)
where agent_id is null
  and (
    (
      booking_source = 'prescription'
      and status = 'uploaded'
    )
    or (
      status = 'confirmed'
      and collection_slot_start_at is not null
    )
  );

create index if not exists orders_agent_collection_schedule_idx
on public.orders (
  agent_id,
  collection_slot_start_at,
  collection_slot_end_at
)
where agent_id is not null
  and collection_slot_start_at is not null
  and status not in ('cancelled', 'canceled', 'report_delivered', 'completed');

create or replace function private.validate_collection_slot(
  p_slot_start_at timestamp with time zone,
  p_slot_end_at timestamp with time zone
)
returns void
language plpgsql
stable
set search_path = ''
as $$
declare
  slot_start_ist timestamp without time zone;
  slot_end_ist timestamp without time zone;
begin
  if p_slot_start_at is null or p_slot_end_at is null then
    raise exception 'Choose a collection slot before booking.'
      using errcode = '22023';
  end if;

  if p_slot_end_at - p_slot_start_at <> interval '2 hours' then
    raise exception 'Choose a valid two-hour collection slot.'
      using errcode = '22023';
  end if;

  if p_slot_start_at < now() + interval '30 minutes' then
    raise exception 'Choose a future collection slot.'
      using errcode = '22023';
  end if;

  if p_slot_start_at > now() + interval '30 days' then
    raise exception 'Collection slots can be booked up to 30 days ahead.'
      using errcode = '22023';
  end if;

  slot_start_ist := p_slot_start_at at time zone 'Asia/Kolkata';
  slot_end_ist := p_slot_end_at at time zone 'Asia/Kolkata';

  if slot_start_ist::date <> slot_end_ist::date
     or extract(minute from slot_start_ist) <> 0
     or extract(second from slot_start_ist) <> 0
     or extract(hour from slot_start_ist) not in (7, 9, 11, 15, 17) then
    raise exception 'Choose one of the available collection windows.'
      using errcode = '22023';
  end if;
end;
$$;

revoke all on function private.validate_collection_slot(
  timestamp with time zone,
  timestamp with time zone
) from public, anon, authenticated;

create or replace function private.create_direct_test_booking(
  p_test_ids uuid[],
  p_collection_address_id uuid,
  p_slot_start_at timestamp with time zone,
  p_slot_end_at timestamp with time zone
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_order public.orders;
  v_test_names text[];
  v_total numeric(10, 2);
  v_selected_count integer;
  v_unique_count integer;
  v_missing_price_count integer;
  v_unbookable_count integer;
  v_has_lab_visit boolean;
  v_has_home_collection boolean;
  v_fulfillment_mode text;
  v_address public.collection_addresses;
  v_patient public.users;
begin
  if v_user_id is null then
    raise exception 'Sign in to book tests.' using errcode = '42501';
  end if;

  perform private.validate_collection_slot(
    p_slot_start_at,
    p_slot_end_at
  );

  v_unique_count := coalesce(
    cardinality(array(select distinct unnest(p_test_ids))),
    0
  );

  if v_unique_count = 0 then
    raise exception 'Select at least one medical test.'
      using errcode = '22023';
  end if;

  if v_unique_count > 30 then
    raise exception 'A booking can contain at most 30 tests.'
      using errcode = '22023';
  end if;

  select
    count(*)::integer,
    count(*) filter (where medical_test.mrp is null)::integer,
    count(*) filter (
      where medical_test.lab_visit_required = false
        and medical_test.home_collection_available = false
    )::integer,
    coalesce(
      array_agg(
        coalesce(
          nullif(trim(medical_test.common_name), ''),
          medical_test.name_sheet
        )
        order by coalesce(
          nullif(trim(medical_test.common_name), ''),
          medical_test.name_sheet
        )
      ),
      '{}'::text[]
    ),
    coalesce(
      sum(private.medical_test_selling_price(medical_test.mrp)),
      0
    )::numeric(10, 2),
    coalesce(bool_or(medical_test.lab_visit_required), false),
    coalesce(bool_or(not medical_test.lab_visit_required), false)
  into
    v_selected_count,
    v_missing_price_count,
    v_unbookable_count,
    v_test_names,
    v_total,
    v_has_lab_visit,
    v_has_home_collection
  from public.medical_tests as medical_test
  where medical_test.id = any(p_test_ids)
    and medical_test.is_active = true;

  if v_selected_count <> v_unique_count then
    raise exception 'One or more selected tests are unavailable.'
      using errcode = '22023';
  end if;

  if v_missing_price_count > 0 then
    raise exception 'One or more selected tests require price confirmation.'
      using errcode = '22023';
  end if;

  if v_unbookable_count > 0 then
    raise exception 'One or more selected tests cannot be booked directly.'
      using errcode = '22023';
  end if;

  if v_has_lab_visit and v_has_home_collection then
    raise exception 'Lab-visit and home-collection tests must be booked separately.'
      using errcode = '22023';
  end if;

  v_fulfillment_mode := case
    when v_has_lab_visit then 'lab_visit'
    else 'home_collection'
  end;

  if v_fulfillment_mode = 'home_collection' then
    if p_collection_address_id is null then
      select collection_address.*
      into v_address
      from public.collection_addresses as collection_address
      where collection_address.user_id = v_user_id
      order by
        collection_address.is_default desc,
        case collection_address.serviceability_status
          when 'serviceable' then 0
          when 'limited' then 1
          when 'unverified' then 2
          else 3
        end,
        collection_address.last_used_at desc
      limit 1;
    else
      select collection_address.*
      into v_address
      from public.collection_addresses as collection_address
      where collection_address.id = p_collection_address_id
        and collection_address.user_id = v_user_id;
    end if;

    if not found then
      raise exception 'Choose a collection address.'
        using errcode = '22023';
    end if;

    if v_address.serviceability_status = 'unavailable' then
      raise exception 'Home collection is unavailable at this address.'
        using errcode = '22023';
    end if;

    update public.collection_addresses
    set
      last_used_at = now(),
      updated_at = now()
    where id = v_address.id
      and user_id = v_user_id;
  end if;

  select patient.*
  into v_patient
  from public.users as patient
  where patient.id = v_user_id;

  insert into public.orders (
    user_id,
    prescription_image_url,
    status,
    test_list,
    price,
    booking_source,
    fulfillment_mode,
    patient_name,
    patient_phone_number,
    patient_age,
    patient_gender,
    collection_address_id,
    patient_location_address,
    patient_latitude,
    patient_longitude,
    patient_location_type,
    collection_slot_start_at,
    collection_slot_end_at,
    collection_slot_timezone,
    collection_slot_booked_at,
    user_confirmed_at,
    timeline
  )
  values (
    v_user_id,
    null,
    'confirmed',
    v_test_names,
    v_total,
    'direct_test',
    v_fulfillment_mode,
    v_patient.full_name,
    v_patient.phone_number,
    v_patient.age,
    v_patient.gender,
    v_address.id,
    v_address.display_address,
    v_address.latitude,
    v_address.longitude,
    case
      when v_address.location_type in ('approximate', 'precise')
        then v_address.location_type
      when v_address.id is not null then 'precise'
      else null
    end,
    p_slot_start_at,
    p_slot_end_at,
    'Asia/Kolkata',
    now(),
    now(),
    array[
      jsonb_build_object(
        'status', 'confirmed',
        'message', case
          when v_fulfillment_mode = 'lab_visit'
            then 'Your lab appointment slot is confirmed.'
          else 'Your home collection slot is confirmed.'
        end,
        'timestamp', now(),
        'source', 'direct_test',
        'slot_start_at', p_slot_start_at,
        'slot_end_at', p_slot_end_at
      )
    ]::jsonb[]
  )
  returning * into v_order;

  insert into public.order_tests (
    order_id,
    medical_test_id,
    suggested_by_agent_id,
    selected_by_user,
    user_selected_at,
    selection_source
  )
  select
    v_order.id,
    medical_test.id,
    null,
    true,
    now(),
    'user'
  from public.medical_tests as medical_test
  where medical_test.id = any(p_test_ids)
    and medical_test.is_active = true;

  return v_order;
end;
$$;

create or replace function public.create_direct_test_booking(
  p_test_ids uuid[],
  p_collection_address_id uuid,
  p_slot_start_at timestamp with time zone,
  p_slot_end_at timestamp with time zone
)
returns public.orders
language sql
set search_path = ''
as $$
  select private.create_direct_test_booking(
    p_test_ids,
    p_collection_address_id,
    p_slot_start_at,
    p_slot_end_at
  );
$$;

create or replace function private.create_direct_test_booking(
  p_test_ids uuid[],
  p_collection_address_id uuid default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception 'Choose a collection slot before booking.'
    using errcode = '22023';
end;
$$;

create or replace function public.schedule_direct_test_booking(
  p_order_id bigint,
  p_slot_start_at timestamp with time zone,
  p_slot_end_at timestamp with time zone
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  acting_user_id uuid := auth.uid();
  scheduled_order public.orders;
  has_lab_visit boolean;
  has_home_collection boolean;
  resolved_mode text;
begin
  if acting_user_id is null then
    raise exception 'Sign in to schedule this booking.'
      using errcode = '42501';
  end if;

  perform private.validate_collection_slot(
    p_slot_start_at,
    p_slot_end_at
  );

  select customer_order.*
  into scheduled_order
  from public.orders as customer_order
  where customer_order.id = p_order_id
  for update;

  if scheduled_order.id is null
     or scheduled_order.user_id is distinct from acting_user_id
     or scheduled_order.booking_source <> 'direct_test' then
    raise exception 'This direct booking does not belong to you.'
      using errcode = '42501';
  end if;

  if scheduled_order.agent_id is not null
     or scheduled_order.status not in ('booking_requested', 'confirmed') then
    raise exception 'This booking can no longer be rescheduled here.'
      using errcode = 'P0001';
  end if;

  select
    coalesce(bool_or(medical_test.lab_visit_required), false),
    coalesce(bool_or(not medical_test.lab_visit_required), false)
  into has_lab_visit, has_home_collection
  from public.order_tests as selected_test
  join public.medical_tests as medical_test
    on medical_test.id = selected_test.medical_test_id
  where selected_test.order_id = p_order_id
    and selected_test.selected_by_user = true;

  if has_lab_visit and has_home_collection then
    raise exception 'Lab-visit and home-collection tests must be booked separately.'
      using errcode = '22023';
  end if;

  resolved_mode := case
    when has_lab_visit then 'lab_visit'
    else 'home_collection'
  end;

  if resolved_mode = 'home_collection'
     and (
       scheduled_order.collection_address_id is null
       or nullif(trim(scheduled_order.patient_location_address), '') is null
     ) then
    raise exception 'Choose a collection address before selecting a slot.'
      using errcode = '22023';
  end if;

  update public.orders as customer_order
  set
    status = 'confirmed',
    fulfillment_mode = resolved_mode,
    collection_slot_start_at = p_slot_start_at,
    collection_slot_end_at = p_slot_end_at,
    collection_slot_timezone = 'Asia/Kolkata',
    collection_slot_booked_at = now(),
    user_confirmed_at = coalesce(customer_order.user_confirmed_at, now()),
    updated_at = now(),
    timeline = array_append(
      coalesce(customer_order.timeline, '{}'::jsonb[]),
      jsonb_build_object(
        'status', 'confirmed',
        'message', case
          when resolved_mode = 'lab_visit'
            then 'Your lab appointment slot is confirmed.'
          else 'Your home collection slot is confirmed.'
        end,
        'timestamp', now(),
        'slot_start_at', p_slot_start_at,
        'slot_end_at', p_slot_end_at
      )
    )
  where customer_order.id = p_order_id
  returning customer_order.* into scheduled_order;

  return scheduled_order;
end;
$$;

create or replace function public.confirm_prescription_booking(
  p_order_id bigint,
  p_selected_test_ids uuid[],
  p_slot_start_at timestamp with time zone,
  p_slot_end_at timestamp with time zone
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  confirmed_order public.orders;
  acting_user_id uuid := auth.uid();
  requested_count integer;
  suggested_count integer;
  selected_names text[];
  selected_price numeric;
  has_lab_visit boolean;
  has_home_collection boolean;
  resolved_mode text;
begin
  if acting_user_id is null then
    raise exception 'Sign in is required' using errcode = '42501';
  end if;

  perform private.validate_collection_slot(
    p_slot_start_at,
    p_slot_end_at
  );

  select customer_order.*
  into confirmed_order
  from public.orders as customer_order
  where customer_order.id = p_order_id
  for update;

  if confirmed_order.id is null
     or confirmed_order.user_id is distinct from acting_user_id then
    raise exception 'This booking does not belong to you'
      using errcode = '42501';
  end if;

  if confirmed_order.status <> 'awaiting_user_approval' then
    raise exception 'This test list is not awaiting confirmation'
      using errcode = 'P0001';
  end if;

  if coalesce(array_length(p_selected_test_ids, 1), 0) = 0 then
    raise exception 'Select at least one medical test'
      using errcode = '22023';
  end if;

  select count(distinct requested_test_id)
  into requested_count
  from unnest(p_selected_test_ids) as requested_test_id;

  select count(*)
  into suggested_count
  from public.order_tests as recommendation
  where recommendation.order_id = p_order_id
    and recommendation.medical_test_id = any(p_selected_test_ids);

  if suggested_count <> requested_count then
    raise exception 'Only tests from the prepared list can be booked'
      using errcode = '22023';
  end if;

  update public.order_tests as recommendation
  set
    selected_by_user = recommendation.medical_test_id = any(p_selected_test_ids),
    user_selected_at = case
      when recommendation.medical_test_id = any(p_selected_test_ids) then now()
      else null
    end
  where recommendation.order_id = p_order_id;

  select
    array_agg(
      coalesce(
        nullif(trim(medical_test.common_name), ''),
        medical_test.name_sheet
      )
      order by medical_test.display_order, medical_test.name_sheet
    ),
    coalesce(
      sum(private.medical_test_selling_price(medical_test.mrp)),
      0
    ),
    coalesce(bool_or(medical_test.lab_visit_required), false),
    coalesce(bool_or(not medical_test.lab_visit_required), false)
  into
    selected_names,
    selected_price,
    has_lab_visit,
    has_home_collection
  from public.order_tests as recommendation
  join public.medical_tests as medical_test
    on medical_test.id = recommendation.medical_test_id
  where recommendation.order_id = p_order_id
    and recommendation.selected_by_user = true;

  if has_lab_visit and has_home_collection then
    raise exception 'Lab-visit and home-collection tests must be booked separately.'
      using errcode = '22023';
  end if;

  resolved_mode := case
    when has_lab_visit then 'lab_visit'
    else 'home_collection'
  end;

  if resolved_mode = 'home_collection'
     and (
       confirmed_order.collection_address_id is null
       or nullif(trim(confirmed_order.patient_location_address), '') is null
     ) then
    raise exception 'Choose a collection address before confirming.'
      using errcode = '22023';
  end if;

  update public.orders as customer_order
  set
    status = 'confirmed',
    agent_id = null,
    test_list = coalesce(selected_names, '{}'::text[]),
    price = coalesce(selected_price, 0),
    fulfillment_mode = resolved_mode,
    collection_slot_start_at = p_slot_start_at,
    collection_slot_end_at = p_slot_end_at,
    collection_slot_timezone = 'Asia/Kolkata',
    collection_slot_booked_at = now(),
    user_confirmed_at = now(),
    updated_at = now(),
    timeline = array_append(
      coalesce(customer_order.timeline, '{}'::jsonb[]),
      jsonb_build_object(
        'status', 'confirmed',
        'message', case
          when resolved_mode = 'lab_visit'
            then 'The patient confirmed the tests and lab appointment slot.'
          else 'The patient confirmed the tests and home collection slot.'
        end,
        'timestamp', now(),
        'reviewed_by_agent_id', customer_order.agent_id,
        'slot_start_at', p_slot_start_at,
        'slot_end_at', p_slot_end_at
      )
    )
  where customer_order.id = p_order_id
  returning customer_order.* into confirmed_order;

  return confirmed_order;
end;
$$;

create or replace function public.confirm_prescription_booking(
  p_order_id bigint,
  p_selected_test_ids uuid[]
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception 'Choose a collection slot before confirming.'
    using errcode = '22023';
end;
$$;

create or replace function public.list_agent_work_queue()
returns table (
  order_id bigint,
  work_type text,
  booking_source text,
  patient_name text,
  patient_phone_number text,
  patient_age integer,
  patient_gender text,
  patient_location_address text,
  fulfillment_mode text,
  collection_slot_start_at timestamp with time zone,
  collection_slot_end_at timestamp with time zone,
  test_list text[],
  created_at timestamp with time zone,
  status text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (select private.is_verified_agent()) then
    raise exception 'Agent access is not approved' using errcode = '42501';
  end if;

  return query
  select
    customer_order.id,
    case
      when customer_order.status = 'uploaded'
        then 'prescription_review'
      else 'scheduled_fulfillment'
    end,
    customer_order.booking_source,
    coalesce(nullif(trim(customer_order.patient_name), ''), 'Patient'),
    customer_order.patient_phone_number,
    customer_order.patient_age,
    customer_order.patient_gender,
    customer_order.patient_location_address,
    customer_order.fulfillment_mode,
    customer_order.collection_slot_start_at,
    customer_order.collection_slot_end_at,
    coalesce(customer_order.test_list, '{}'::text[]),
    customer_order.created_at,
    customer_order.status
  from public.orders as customer_order
  where customer_order.agent_id is null
    and (
      (
        customer_order.booking_source = 'prescription'
        and customer_order.status = 'uploaded'
        and nullif(trim(customer_order.prescription_image_url), '') is not null
      )
      or (
        customer_order.status = 'confirmed'
        and customer_order.collection_slot_start_at is not null
        and customer_order.collection_slot_end_at is not null
        and coalesce(array_length(customer_order.test_list, 1), 0) > 0
      )
    )
  order by
    case
      when customer_order.status = 'confirmed' then 0
      else 1
    end,
    customer_order.collection_slot_start_at asc nulls last,
    customer_order.created_at asc
  limit 200;
end;
$$;

create or replace function public.claim_scheduled_order(
  p_order_id bigint
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  acting_agent_id uuid := auth.uid();
  claimed_order public.orders;
begin
  if acting_agent_id is null or not (select private.is_verified_agent()) then
    raise exception 'Agent access is not approved' using errcode = '42501';
  end if;

  select customer_order.*
  into claimed_order
  from public.orders as customer_order
  where customer_order.id = p_order_id
  for update;

  if claimed_order.id is null
     or claimed_order.status <> 'confirmed'
     or claimed_order.collection_slot_start_at is null
     or claimed_order.collection_slot_end_at is null
     or coalesce(array_length(claimed_order.test_list, 1), 0) = 0 then
    raise exception 'This collection request is no longer available.'
      using errcode = 'P0001';
  end if;

  if claimed_order.agent_id is not null then
    if claimed_order.agent_id = acting_agent_id then
      return claimed_order;
    end if;

    raise exception 'Another agent already accepted this collection.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from public.orders as existing_case
    where existing_case.agent_id = acting_agent_id
      and existing_case.id <> claimed_order.id
      and existing_case.collection_slot_start_at is not null
      and existing_case.collection_slot_end_at is not null
      and existing_case.status not in (
        'cancelled',
        'canceled',
        'report_delivered',
        'completed'
      )
      and tstzrange(
        existing_case.collection_slot_start_at,
        existing_case.collection_slot_end_at,
        '[)'
      ) && tstzrange(
        claimed_order.collection_slot_start_at,
        claimed_order.collection_slot_end_at,
        '[)'
      )
  ) then
    raise exception 'You already have another case in this time slot.'
      using errcode = 'P0001';
  end if;

  update public.orders as customer_order
  set
    agent_id = acting_agent_id,
    status = 'assigned',
    updated_at = now(),
    timeline = array_append(
      coalesce(customer_order.timeline, '{}'::jsonb[]),
      jsonb_build_object(
        'status', 'assigned',
        'message', case
          when customer_order.fulfillment_mode = 'lab_visit'
            then 'A verified agent accepted this lab appointment.'
          else 'A verified collection agent accepted this booking.'
        end,
        'timestamp', now()
      )
    )
  where customer_order.id = p_order_id
    and customer_order.agent_id is null
  returning customer_order.* into claimed_order;

  if claimed_order.id is null then
    raise exception 'Another agent already accepted this collection.'
      using errcode = 'P0001';
  end if;

  return claimed_order;
end;
$$;

create or replace function public.claim_direct_test_order(
  p_order_id bigint
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_order public.orders;
begin
  select customer_order.*
  into target_order
  from public.orders as customer_order
  where customer_order.id = p_order_id;

  if target_order.id is null
     or target_order.booking_source <> 'direct_test' then
    raise exception 'This direct collection request is no longer available.'
      using errcode = 'P0001';
  end if;

  return public.claim_scheduled_order(p_order_id);
end;
$$;

create or replace function public.update_order_fulfillment_status(
  p_order_id bigint,
  p_status text
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  acting_agent_id uuid := auth.uid();
  active_order public.orders;
  target_status text := lower(trim(coalesce(p_status, '')));
  transition_allowed boolean := false;
  status_message text;
begin
  if acting_agent_id is null or not (select private.is_verified_agent()) then
    raise exception 'Agent access is not approved' using errcode = '42501';
  end if;

  select customer_order.*
  into active_order
  from public.orders as customer_order
  where customer_order.id = p_order_id
  for update;

  if active_order.id is null
     or active_order.agent_id is distinct from acting_agent_id then
    raise exception 'This case is not assigned to you.'
      using errcode = '42501';
  end if;

  if active_order.collection_slot_start_at is null
     or active_order.collection_slot_end_at is null then
    raise exception 'A booked appointment slot is required before fulfilment.'
      using errcode = 'P0001';
  end if;

  if active_order.fulfillment_mode = 'home_collection' then
    transition_allowed := (
      active_order.status in ('confirmed', 'assigned')
      and target_status = 'agent_out_for_collection'
    ) or (
      active_order.status = 'agent_out_for_collection'
      and target_status = 'sample_collected'
    ) or (
      active_order.status = 'sample_collected'
      and target_status = 'sample_received_at_lab'
    );
  else
    transition_allowed := (
      active_order.status in ('confirmed', 'assigned')
      and target_status = 'sample_received_at_lab'
    );
  end if;

  transition_allowed := transition_allowed or (
    active_order.status = 'sample_received_at_lab'
    and target_status = 'sample_processing'
  ) or (
    active_order.status = 'sample_processing'
    and target_status = 'report_ready'
  ) or (
    active_order.status = 'report_ready'
    and target_status = 'report_out_for_delivery'
  ) or (
    active_order.status = 'report_out_for_delivery'
    and target_status = 'report_delivered'
  );

  if not transition_allowed then
    raise exception 'This status update is out of sequence.'
      using errcode = 'P0001';
  end if;

  status_message := case target_status
    when 'agent_out_for_collection'
      then 'Your collection agent has left for your selected location.'
    when 'sample_collected'
      then 'Your sample has been collected successfully.'
    when 'sample_received_at_lab'
      then 'Your sample has reached the diagnostic lab.'
    when 'sample_processing'
      then 'The lab is processing your sample.'
    when 'report_ready'
      then 'Your diagnostic report is ready.'
    when 'report_out_for_delivery'
      then 'Your agent is travelling to deliver the report.'
    when 'report_delivered'
      then 'Your diagnostic report has been delivered.'
    else 'Your booking status was updated.'
  end;

  update public.orders as customer_order
  set
    status = target_status,
    updated_at = now(),
    timeline = array_append(
      coalesce(customer_order.timeline, '{}'::jsonb[]),
      jsonb_build_object(
        'status', target_status,
        'message', status_message,
        'timestamp', now(),
        'agent_id', acting_agent_id
      )
    )
  where customer_order.id = p_order_id
  returning customer_order.* into active_order;

  return active_order;
end;
$$;

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
      'Your prescription review is complete. Tap to review the prepared tests and choose a collection slot.';
    kind := 'prescription_tests_ready';
    destination := 'prescription_review';
  elsif normalized_status = 'booking_requested'
      and normalized_source = 'direct_test' then
    title := 'Choose a collection slot';
    body :=
      'Your selected tests are saved. Choose a collection slot to finish booking.';
    kind := 'direct_booking_slot_required';
    destination := 'order_details';
  elsif normalized_status = 'booking_requested' then
    title := 'Booking request received';
    body :=
      'We are confirming your selected tests and collection details. Tap to follow the booking.';
    kind := 'booking_received';
    destination := 'order_details';
  elsif normalized_status in ('confirmed', 'booking_confirmed') then
    title := 'Booking and slot confirmed';
    body :=
      'Your selected tests and appointment slot are confirmed. Tap to view the details.';
    kind := 'booking_confirmed';
    destination := 'order_details';
  elsif normalized_status in (
    'assigned',
    'agent_assigned',
    'assigned_agent',
    'collection_agent_assigned'
  ) then
    title := 'Agent assigned';
    body :=
      'A verified agent has accepted your booking. Tap to view the latest status.';
    kind := 'collection_assigned';
    destination := 'order_details';
  elsif normalized_status in (
    'agent_out_for_collection',
    'out_for_collection',
    'executive_on_the_way'
  ) then
    title := 'Collection agent is on the way';
    body :=
      'Your collection agent is travelling to your selected location. Tap to track the update.';
    kind := 'collection_on_the_way';
    destination := 'order_details';
  elsif normalized_status in ('collected', 'sample_collected') then
    title := 'Sample collected';
    body :=
      'Your sample was collected successfully. Tap to follow its lab progress.';
    kind := 'sample_collected';
    destination := 'order_details';
  elsif normalized_status in (
    'sample_out_for_testing',
    'sample_in_transit'
  ) then
    title := 'Sample is going to the lab';
    body :=
      'Your collected sample is being transported to the diagnostic lab.';
    kind := 'sample_in_transit';
    destination := 'order_details';
  elsif normalized_status = 'sample_received_at_lab' then
    title := 'Sample reached the lab';
    body :=
      'Your sample has reached the diagnostic lab and will be processed next.';
    kind := 'sample_received_at_lab';
    destination := 'order_details';
  elsif normalized_status in (
    'testing',
    'lab_testing',
    'sample_processing',
    'sample_testing'
  ) then
    title := 'Sample processing started';
    body :=
      'The lab is processing your sample now. Tap to see the latest status.';
    kind := 'testing_in_progress';
    destination := 'order_details';
  elsif normalized_status in ('report_ready', 'reports_ready') then
    title := 'Your report is ready';
    body :=
      'Your diagnostic report is ready. Tap to view the booking update.';
    kind := 'report_ready';
    destination := 'order_details';
  elsif normalized_status = 'report_out_for_delivery' then
    title := 'Report is on the way';
    body :=
      'Your agent is travelling to your location with the report.';
    kind := 'report_out_for_delivery';
    destination := 'order_details';
  elsif normalized_status in ('report_delivered', 'completed') then
    title := 'Report delivered';
    body :=
      'Your diagnostic report has been delivered successfully.';
    kind := 'report_delivered';
    destination := 'order_details';
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

revoke all on function public.create_direct_test_booking(
  uuid[],
  uuid,
  timestamp with time zone,
  timestamp with time zone
) from public;
revoke all on function public.schedule_direct_test_booking(
  bigint,
  timestamp with time zone,
  timestamp with time zone
) from public;
revoke all on function public.confirm_prescription_booking(
  bigint,
  uuid[],
  timestamp with time zone,
  timestamp with time zone
) from public;
revoke all on function public.list_agent_work_queue() from public;
revoke all on function public.claim_scheduled_order(bigint) from public;
revoke all on function public.claim_direct_test_order(bigint) from public;
revoke all on function public.update_order_fulfillment_status(
  bigint,
  text
) from public;

grant execute on function public.create_direct_test_booking(
  uuid[],
  uuid,
  timestamp with time zone,
  timestamp with time zone
) to authenticated;
grant execute on function public.schedule_direct_test_booking(
  bigint,
  timestamp with time zone,
  timestamp with time zone
) to authenticated;
grant execute on function public.confirm_prescription_booking(
  bigint,
  uuid[],
  timestamp with time zone,
  timestamp with time zone
) to authenticated;
grant execute on function public.list_agent_work_queue() to authenticated;
grant execute on function public.claim_scheduled_order(bigint)
to authenticated;
grant execute on function public.claim_direct_test_order(bigint)
to authenticated;
grant execute on function public.update_order_fulfillment_status(
  bigint,
  text
) to authenticated;

comment on function public.list_agent_work_queue() is
  'Returns limited unassigned prescription reviews and patient-confirmed scheduled bookings to verified agents.';
comment on function public.claim_scheduled_order(bigint) is
  'Atomically assigns one patient-confirmed scheduled booking to a verified agent.';
comment on function public.claim_direct_test_order(bigint) is
  'Backward-compatible direct-booking wrapper around claim_scheduled_order.';
comment on function public.update_order_fulfillment_status(bigint, text) is
  'Advances an assigned order through the server-validated fulfilment state machine.';
