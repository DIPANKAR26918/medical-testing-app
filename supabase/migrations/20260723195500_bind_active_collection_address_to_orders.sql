-- Snapshot the user's active collection address onto each new order.
--
-- `collection_address_id` keeps the relationship to the saved address while the
-- patient_* columns preserve the exact address used when the booking was made.
-- Changing the active saved address later therefore does not silently reroute an
-- existing collection or report delivery.

create or replace function private.bind_order_collection_address()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_address public.collection_addresses;
begin
  if new.user_id is null then
    return new;
  end if;

  if new.collection_address_id is not null then
    select address.*
    into selected_address
    from public.collection_addresses as address
    where address.id = new.collection_address_id
      and address.user_id = new.user_id
    limit 1;

    if selected_address.id is null then
      raise exception 'Collection address does not belong to this user'
        using errcode = '42501';
    end if;
  else
    select address.*
    into selected_address
    from public.collection_addresses as address
    where address.user_id = new.user_id
      and address.is_default = true
    order by address.last_used_at desc
    limit 1;
  end if;

  if selected_address.id is null then
    return new;
  end if;

  new.collection_address_id := selected_address.id;
  new.patient_location_address := selected_address.display_address;
  new.patient_latitude := selected_address.latitude;
  new.patient_longitude := selected_address.longitude;
  new.patient_location_type := selected_address.location_type;

  if coalesce(btrim(new.patient_name), '') = '' then
    new.patient_name := selected_address.recipient_name;
  end if;
  if coalesce(btrim(new.patient_phone_number), '') = '' then
    new.patient_phone_number := selected_address.phone_number;
  end if;

  return new;
end;
$$;

drop trigger if exists orders_bind_active_collection_address
on public.orders;

create trigger orders_bind_active_collection_address
before insert or update of collection_address_id, user_id
on public.orders
for each row
execute function private.bind_order_collection_address();

comment on function private.bind_order_collection_address() is
  'Validates or resolves the active collection address and snapshots it onto an order.';
