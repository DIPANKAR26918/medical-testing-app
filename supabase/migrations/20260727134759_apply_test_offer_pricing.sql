create or replace function private.medical_test_selling_price(p_mrp numeric)
returns numeric(10, 2)
language sql
immutable
strict
parallel safe
security invoker
set search_path = ''
as $$
  with discounted as (
    select greatest(round(p_mrp * 0.80), 0) as amount
  )
  select (
    case
      when amount > 0 and mod(amount, 5) = 0 then amount - 1
      else amount
    end
  )::numeric(10, 2)
  from discounted;
$$;

comment on function private.medical_test_selling_price(numeric) is
  'Returns the per-test payable price: 20% off MRP, rounded to a whole rupee, then minus one when the result is a multiple of five.';

revoke all on function private.medical_test_selling_price(numeric)
  from public, anon, authenticated, service_role;

create or replace function private.create_direct_test_booking(
  p_test_ids uuid[],
  p_collection_address_id uuid default null
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
  v_address public.collection_addresses;
  v_patient public.users;
begin
  if v_user_id is null then
    raise exception 'Sign in to book tests.';
  end if;

  v_unique_count := coalesce(
    cardinality(array(select distinct unnest(p_test_ids))),
    0
  );

  if v_unique_count = 0 then
    raise exception 'Select at least one medical test.';
  end if;

  if v_unique_count > 30 then
    raise exception 'A booking can contain at most 30 tests.';
  end if;

  select
    count(*)::integer,
    count(*) filter (where mt.mrp is null)::integer,
    count(*) filter (
      where mt.lab_visit_required = false
        and mt.home_collection_available = false
    )::integer,
    coalesce(
      array_agg(
        coalesce(nullif(trim(mt.common_name), ''), mt.name_sheet)
        order by coalesce(nullif(trim(mt.common_name), ''), mt.name_sheet)
      ),
      '{}'::text[]
    ),
    coalesce(sum(private.medical_test_selling_price(mt.mrp)), 0)::numeric(10, 2),
    coalesce(bool_or(mt.lab_visit_required), false),
    coalesce(bool_or(not mt.lab_visit_required), false)
  into
    v_selected_count,
    v_missing_price_count,
    v_unbookable_count,
    v_test_names,
    v_total,
    v_has_lab_visit,
    v_has_home_collection
  from public.medical_tests mt
  where mt.id = any(p_test_ids)
    and mt.is_active = true;

  if v_selected_count <> v_unique_count then
    raise exception 'One or more selected tests are unavailable.';
  end if;

  if v_missing_price_count > 0 then
    raise exception 'One or more selected tests require price confirmation.';
  end if;

  if v_unbookable_count > 0 then
    raise exception 'One or more selected tests cannot be booked directly.';
  end if;

  if v_has_lab_visit and v_has_home_collection then
    raise exception 'Lab-visit and home-collection tests must be booked separately.';
  end if;

  if not v_has_lab_visit then
    if p_collection_address_id is null then
      select ca.*
      into v_address
      from public.collection_addresses ca
      where ca.user_id = v_user_id
      order by
        ca.is_default desc,
        case ca.serviceability_status
          when 'serviceable' then 0
          when 'limited' then 1
          when 'unverified' then 2
          else 3
        end,
        ca.last_used_at desc
      limit 1;
    else
      select ca.*
      into v_address
      from public.collection_addresses ca
      where ca.id = p_collection_address_id
        and ca.user_id = v_user_id;
    end if;

    if not found then
      raise exception 'Choose a collection address.';
    end if;

    if v_address.serviceability_status = 'unavailable' then
      raise exception 'Home collection is unavailable at this address.';
    end if;

    update public.collection_addresses
    set last_used_at = now(), updated_at = now()
    where id = v_address.id
      and user_id = v_user_id;
  end if;

  select u.*
  into v_patient
  from public.users u
  where u.id = v_user_id;

  insert into public.orders (
    user_id,
    prescription_image_url,
    status,
    test_list,
    price,
    booking_source,
    patient_name,
    patient_phone_number,
    patient_age,
    patient_gender,
    collection_address_id,
    patient_location_address,
    patient_latitude,
    patient_longitude,
    patient_location_type,
    timeline
  )
  values (
    v_user_id,
    null,
    'booking_requested',
    v_test_names,
    v_total,
    'direct_test',
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
    array[
      jsonb_build_object(
        'status', 'booking_requested',
        'timestamp', timezone('utc', now()),
        'source', 'direct_test'
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
    mt.id,
    null,
    true,
    timezone('utc', now()),
    'user'
  from public.medical_tests mt
  where mt.id = any(p_test_ids)
    and mt.is_active = true;

  return v_order;
end;
$$;

create or replace function public.submit_prescription_tests(
  p_order_id bigint,
  p_test_ids uuid[]
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  reviewed_order public.orders;
  acting_agent_id uuid := (select auth.uid());
  requested_count integer;
  valid_count integer;
  selected_names text[];
  selected_price numeric;
begin
  if acting_agent_id is null or not (select private.is_verified_agent()) then
    raise exception 'Agent access is not approved' using errcode = '42501';
  end if;

  select customer_order.*
  into reviewed_order
  from public.orders as customer_order
  where customer_order.id = p_order_id
  for update;

  if reviewed_order.id is null
     or reviewed_order.agent_id is distinct from acting_agent_id then
    raise exception 'This prescription is not assigned to you'
      using errcode = '42501';
  end if;

  if reviewed_order.status not in ('under_review', 'awaiting_user_approval') then
    raise exception 'Tests cannot be changed at this stage'
      using errcode = 'P0001';
  end if;

  if coalesce(array_length(p_test_ids, 1), 0) = 0 then
    raise exception 'Select at least one medical test'
      using errcode = '22023';
  end if;

  select count(distinct requested_test_id)
  into requested_count
  from unnest(p_test_ids) as requested_test_id;

  select count(*)
  into valid_count
  from public.medical_tests as medical_test
  where medical_test.id = any(p_test_ids)
    and medical_test.is_active = true;

  if valid_count <> requested_count then
    raise exception 'One or more selected tests are unavailable'
      using errcode = '22023';
  end if;

  delete from public.order_tests
  where order_id = p_order_id;

  insert into public.order_tests (
    order_id,
    medical_test_id,
    suggested_by_agent_id,
    selected_by_user
  )
  select
    p_order_id,
    medical_test.id,
    acting_agent_id,
    true
  from public.medical_tests as medical_test
  where medical_test.id = any(p_test_ids)
    and medical_test.is_active = true;

  select
    array_agg(
      coalesce(nullif(trim(medical_test.common_name), ''), medical_test.name_sheet)
      order by medical_test.display_order, medical_test.name_sheet
    ),
    coalesce(
      sum(private.medical_test_selling_price(medical_test.mrp)),
      0
    )
  into selected_names, selected_price
  from public.order_tests as recommendation
  join public.medical_tests as medical_test
    on medical_test.id = recommendation.medical_test_id
  where recommendation.order_id = p_order_id;

  update public.orders as customer_order
  set
    status = 'awaiting_user_approval',
    test_list = coalesce(selected_names, '{}'::text[]),
    price = coalesce(selected_price, 0),
    tests_prepared_at = now(),
    updated_at = now(),
    timeline = array_append(
      coalesce(customer_order.timeline, '{}'::jsonb[]),
      jsonb_build_object(
        'status', 'awaiting_user_approval',
        'message', 'Your prescribed test list is ready to review.',
        'timestamp', now()
      )
    )
  where customer_order.id = p_order_id
  returning customer_order.* into reviewed_order;

  return reviewed_order;
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
declare
  confirmed_order public.orders;
  acting_user_id uuid := (select auth.uid());
  requested_count integer;
  suggested_count integer;
  selected_names text[];
  selected_price numeric;
begin
  if acting_user_id is null then
    raise exception 'Sign in is required' using errcode = '42501';
  end if;

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
      coalesce(nullif(trim(medical_test.common_name), ''), medical_test.name_sheet)
      order by medical_test.display_order, medical_test.name_sheet
    ),
    coalesce(
      sum(private.medical_test_selling_price(medical_test.mrp)),
      0
    )
  into selected_names, selected_price
  from public.order_tests as recommendation
  join public.medical_tests as medical_test
    on medical_test.id = recommendation.medical_test_id
  where recommendation.order_id = p_order_id
    and recommendation.selected_by_user = true;

  update public.orders as customer_order
  set
    status = 'confirmed',
    test_list = coalesce(selected_names, '{}'::text[]),
    price = coalesce(selected_price, 0),
    user_confirmed_at = now(),
    updated_at = now(),
    timeline = array_append(
      coalesce(customer_order.timeline, '{}'::jsonb[]),
      jsonb_build_object(
        'status', 'confirmed',
        'message', 'The patient confirmed the selected tests.',
        'timestamp', now()
      )
    )
  where customer_order.id = p_order_id
  returning customer_order.* into confirmed_order;

  return confirmed_order;
end;
$$;
