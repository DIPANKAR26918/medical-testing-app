-- Enrich saved collection addresses with pin provenance and confidence data.
-- All fields are additive so older app releases continue to work unchanged.
alter table public.collection_addresses
  add column if not exists location_source text not null default 'manual',
  add column if not exists provider text,
  add column if not exists provider_place_id text,
  add column if not exists plus_code text,
  add column if not exists accuracy_meters double precision,
  add column if not exists distance_from_device_meters double precision,
  add column if not exists validation_status text not null default 'unverified',
  add column if not exists geocoded_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'collection_addresses_location_source_check'
      and conrelid = 'public.collection_addresses'::regclass
  ) then
    alter table public.collection_addresses
      add constraint collection_addresses_location_source_check
      check (location_source in ('gps', 'map_pin', 'search', 'manual', 'legacy'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'collection_addresses_provider_check'
      and conrelid = 'public.collection_addresses'::regclass
  ) then
    alter table public.collection_addresses
      add constraint collection_addresses_provider_check
      check (provider is null or provider in ('google', 'device', 'manual'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'collection_addresses_accuracy_check'
      and conrelid = 'public.collection_addresses'::regclass
  ) then
    alter table public.collection_addresses
      add constraint collection_addresses_accuracy_check
      check (accuracy_meters is null or accuracy_meters between 0 and 100000);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'collection_addresses_device_distance_check'
      and conrelid = 'public.collection_addresses'::regclass
  ) then
    alter table public.collection_addresses
      add constraint collection_addresses_device_distance_check
      check (
        distance_from_device_meters is null
        or distance_from_device_meters between 0 and 20000000
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'collection_addresses_validation_status_check'
      and conrelid = 'public.collection_addresses'::regclass
  ) then
    alter table public.collection_addresses
      add constraint collection_addresses_validation_status_check
      check (validation_status in ('unverified', 'geocoded', 'confirmed', 'invalid'));
  end if;
end
$$;

update public.collection_addresses
set location_source = case
  when location_type = 'manual' then 'manual'
  when latitude is not null and longitude is not null then 'legacy'
  else 'manual'
end
where location_source = 'manual';

create index if not exists collection_addresses_user_place_idx
  on public.collection_addresses (user_id, provider_place_id)
  where provider_place_id is not null;

-- Address deletion and fallback-default selection happen atomically. The
-- function runs as the caller, so the table's existing owner-only RLS remains
-- the authorization boundary.
create or replace function public.delete_collection_address(
  p_address_id uuid
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  acting_user_id uuid := (select auth.uid());
  deleted_default boolean;
  selected_address public.collection_addresses;
begin
  if acting_user_id is null then
    raise exception 'Sign in is required' using errcode = '42501';
  end if;

  delete from public.collection_addresses as address
  where address.id = p_address_id
    and address.user_id = acting_user_id
  returning address.is_default into deleted_default;

  if not found then
    raise exception 'Address was not found' using errcode = '42501';
  end if;

  select address.*
  into selected_address
  from public.collection_addresses as address
  where address.user_id = acting_user_id
    and address.is_default = true
  limit 1;

  if selected_address.id is null then
    select address.*
    into selected_address
    from public.collection_addresses as address
    where address.user_id = acting_user_id
    order by address.last_used_at desc, address.created_at desc
    limit 1
    for update;

    if selected_address.id is not null then
      update public.collection_addresses as address
      set
        is_default = true,
        last_used_at = now(),
        updated_at = now()
      where address.id = selected_address.id
        and address.user_id = acting_user_id
      returning address.* into selected_address;
    end if;
  end if;

  return jsonb_build_object(
    'deleted_id', p_address_id,
    'deleted_default', deleted_default,
    'selected_address', case
      when selected_address.id is null then null
      else to_jsonb(selected_address)
    end
  );
end;
$$;

revoke all on function public.delete_collection_address(uuid) from public;
grant execute on function public.delete_collection_address(uuid)
  to authenticated;

-- A small server-only quota protects the Places/Geocoding proxy from runaway
-- clients and keeps paid provider usage bounded per account.
create table if not exists public.location_intelligence_usage (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0,
  updated_at timestamptz not null default now(),
  check (request_count >= 0)
);

alter table public.location_intelligence_usage enable row level security;
revoke all on table public.location_intelligence_usage from anon, authenticated;

drop policy if exists "Clients cannot access location provider quota"
  on public.location_intelligence_usage;
create policy "Clients cannot access location provider quota"
  on public.location_intelligence_usage
  for all
  to authenticated
  using (false)
  with check (false);

create or replace function public.consume_location_intelligence_quota(
  p_user_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  allowed boolean;
begin
  if p_user_id is null then
    return false;
  end if;

  insert into public.location_intelligence_usage as usage (
    user_id,
    window_started_at,
    request_count,
    updated_at
  ) values (
    p_user_id,
    now(),
    1,
    now()
  )
  on conflict (user_id) do update
  set
    window_started_at = case
      when usage.window_started_at <= now() - interval '1 hour' then now()
      else usage.window_started_at
    end,
    request_count = case
      when usage.window_started_at <= now() - interval '1 hour' then 1
      else usage.request_count + 1
    end,
    updated_at = now()
  returning request_count <= 120 into allowed;

  return coalesce(allowed, false);
end;
$$;

revoke all on function public.consume_location_intelligence_quota(uuid)
  from public, anon, authenticated;
grant execute on function public.consume_location_intelligence_quota(uuid)
  to service_role;
