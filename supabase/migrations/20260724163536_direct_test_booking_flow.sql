alter table public.orders
  add column if not exists booking_source text not null default 'prescription';

alter table public.orders
  drop constraint if exists orders_booking_source_check;

alter table public.orders
  add constraint orders_booking_source_check
  check (booking_source in ('prescription', 'direct_test'));

alter table public.order_tests
  alter column suggested_by_agent_id drop not null;

alter table public.order_tests
  add column if not exists selection_source text not null default 'agent';

alter table public.order_tests
  drop constraint if exists order_tests_selection_source_check;

alter table public.order_tests
  add constraint order_tests_selection_source_check
  check (selection_source in ('agent', 'user'));

create schema if not exists private;
grant usage on schema private to authenticated, service_role;

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
    coalesce(sum(mt.mrp), 0)::numeric(10, 2),
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
      raise exception 'Choose a collection address.';
    end if;

    select ca.*
    into v_address
    from public.collection_addresses ca
    where ca.id = p_collection_address_id
      and ca.user_id = v_user_id;

    if not found then
      raise exception 'The selected collection address is unavailable.';
    end if;

    if v_address.serviceability_status = 'unavailable' then
      raise exception 'Home collection is unavailable at this address.';
    end if;
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
    coalesce(v_patient.full_name, v_patient.display_name),
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

revoke all on function private.create_direct_test_booking(uuid[], uuid) from public;
revoke all on function private.create_direct_test_booking(uuid[], uuid) from anon;
grant execute on function private.create_direct_test_booking(uuid[], uuid)
  to authenticated, service_role;

create or replace function public.create_direct_test_booking(
  p_test_ids uuid[],
  p_collection_address_id uuid default null
)
returns public.orders
language sql
security invoker
set search_path = ''
as $$
  select private.create_direct_test_booking(
    p_test_ids,
    p_collection_address_id
  );
$$;

revoke all on function public.create_direct_test_booking(uuid[], uuid) from public;
revoke all on function public.create_direct_test_booking(uuid[], uuid) from anon;
grant execute on function public.create_direct_test_booking(uuid[], uuid)
  to authenticated, service_role;
