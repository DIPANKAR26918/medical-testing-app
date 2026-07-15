-- Ranked medical-test search and account-synced collection addresses.
--
-- Search combines exact/prefix matching, PostgreSQL full-text ranking,
-- keyword intent, and trigram typo tolerance. Address rows are private to
-- their owner and the default-address switch is atomic.

create extension if not exists pg_trgm with schema extensions;

alter table public.medical_tests
  add column if not exists search_document tsvector
  generated always as (
    setweight(
      to_tsvector(
        'simple'::regconfig,
        coalesce(common_name, '') || ' ' ||
        coalesce(name_sheet, '') || ' ' ||
        coalesce(test_code, '')
      ),
      'A'
    ) ||
    setweight(
      to_tsvector(
        'simple'::regconfig,
        coalesce(category, '') || ' ' || coalesce(body_system, '')
      ),
      'B'
    ) ||
    setweight(
      to_tsvector(
        'simple'::regconfig,
        coalesce(purpose, '') || ' ' || coalesce(preparation, '')
      ),
      'C'
    )
  ) stored;

create index if not exists medical_tests_active_search_document_idx
  on public.medical_tests using gin (search_document)
  where is_active = true;

create index if not exists medical_tests_active_search_trgm_idx
  on public.medical_tests using gin (
    (
      lower(
        coalesce(common_name, '') || ' ' ||
        coalesce(name_sheet, '') || ' ' ||
        coalesce(test_code, '')
      )
    ) extensions.gin_trgm_ops
  )
  where is_active = true;

drop function if exists public.search_medical_tests(text, integer, text);

create function public.search_medical_tests(
  p_query text default '',
  p_limit integer default 30,
  p_category text default null
)
returns table (
  id uuid,
  test_code text,
  name_sheet text,
  common_name text,
  mrp numeric,
  reporting_time text,
  sample_type_volume text,
  category text,
  body_system text,
  test_type text,
  purpose text,
  preparation text,
  age_recommendation text,
  home_collection_available boolean,
  lab_visit_required boolean,
  special_handling_required boolean,
  is_popular boolean,
  min_age integer,
  max_age integer,
  gender text,
  parameter_count integer,
  included_parameters text[],
  sample_source text,
  sample_source_label text,
  sample_collection_note text,
  relevance double precision,
  match_reason text
)
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  normalized_query text := lower(
    trim(
      regexp_replace(coalesce(p_query, ''), '[[:space:]]+', ' ', 'g')
    )
  );
  safe_limit integer := greatest(1, least(coalesce(p_limit, 30), 60));
  search_query tsquery;
begin
  if normalized_query = '' then
    return query
    select
      medical_test.id,
      medical_test.test_code,
      medical_test.name_sheet,
      medical_test.common_name,
      medical_test.mrp,
      medical_test.reporting_time,
      medical_test.sample_type_volume,
      medical_test.category,
      medical_test.body_system,
      medical_test.test_type,
      medical_test.purpose,
      medical_test.preparation,
      medical_test.age_recommendation,
      medical_test.home_collection_available,
      medical_test.lab_visit_required,
      medical_test.special_handling_required,
      medical_test.is_popular,
      medical_test.min_age,
      medical_test.max_age,
      medical_test.gender,
      medical_test.parameter_count,
      medical_test.included_parameters,
      medical_test.sample_source,
      medical_test.sample_source_label,
      medical_test.sample_collection_note,
      case when medical_test.is_popular then 10.0 else 1.0 end,
      case when medical_test.is_popular then 'Popular near you' else 'Explore test' end
    from public.medical_tests as medical_test
    where medical_test.is_active = true
      and (
        p_category is null
        or trim(p_category) = ''
        or medical_test.category = p_category
      )
    order by
      medical_test.is_popular desc,
      medical_test.is_preventive desc,
      medical_test.display_order,
      medical_test.name_sheet
    limit safe_limit;

    return;
  end if;

  search_query := pg_catalog.websearch_to_tsquery(
    'simple'::regconfig,
    normalized_query
  );

  return query
  with candidates as (
    select
      medical_test.*,
      lower(coalesce(medical_test.common_name, '')) as common_name_lower,
      lower(medical_test.name_sheet) as name_lower,
      lower(coalesce(medical_test.test_code, '')) as code_lower,
      lower(coalesce(medical_test.category, '')) as category_lower,
      lower(coalesce(medical_test.body_system, '')) as body_system_lower,
      lower(
        coalesce(medical_test.common_name, '') || ' ' ||
        medical_test.name_sheet || ' ' ||
        coalesce(medical_test.test_code, '')
      ) as compact_search_text,
      pg_catalog.ts_rank_cd(medical_test.search_document, search_query) as text_rank,
      greatest(
        extensions.similarity(lower(coalesce(medical_test.common_name, '')), normalized_query),
        extensions.similarity(lower(medical_test.name_sheet), normalized_query),
        extensions.similarity(
          lower(
            coalesce(medical_test.common_name, '') || ' ' ||
            medical_test.name_sheet
          ),
          normalized_query
        )
      ) as typo_rank,
      exists (
        select 1
        from unnest(medical_test.search_keywords) as keyword
        where lower(keyword) = normalized_query
           or lower(keyword) like normalized_query || '%'
           or normalized_query like lower(keyword) || '%'
      ) as keyword_match
    from public.medical_tests as medical_test
    where medical_test.is_active = true
      and (
        p_category is null
        or trim(p_category) = ''
        or medical_test.category = p_category
      )
      and (
        medical_test.search_document @@ search_query
        or lower(
          coalesce(medical_test.common_name, '') || ' ' ||
          medical_test.name_sheet || ' ' ||
          coalesce(medical_test.test_code, '')
        ) like '%' || normalized_query || '%'
        or extensions.similarity(
          lower(
            coalesce(medical_test.common_name, '') || ' ' ||
            medical_test.name_sheet
          ),
          normalized_query
        ) >= 0.18
        or exists (
          select 1
          from unnest(medical_test.search_keywords) as keyword
          where lower(keyword) = normalized_query
             or lower(keyword) like normalized_query || '%'
             or normalized_query like lower(keyword) || '%'
        )
      )
  ), ranked as (
    select
      candidate.*,
      (
        case
          when candidate.common_name_lower = normalized_query then 150
          when candidate.name_lower = normalized_query then 145
          when candidate.code_lower = normalized_query then 140
          when candidate.common_name_lower like normalized_query || '%' then 112
          when candidate.name_lower like normalized_query || '%' then 108
          when candidate.code_lower like normalized_query || '%' then 104
          when candidate.compact_search_text like '%' || normalized_query || '%' then 75
          else 0
        end
        + candidate.text_rank * 80
        + candidate.typo_rank * 46
        + case when candidate.keyword_match then 34 else 0 end
        + case when candidate.category_lower = normalized_query then 26 else 0 end
        + case when candidate.body_system_lower = normalized_query then 22 else 0 end
        + case when candidate.is_popular then 5 else 0 end
      )::double precision as score
    from candidates as candidate
  )
  select
    ranked_test.id,
    ranked_test.test_code,
    ranked_test.name_sheet,
    ranked_test.common_name,
    ranked_test.mrp,
    ranked_test.reporting_time,
    ranked_test.sample_type_volume,
    ranked_test.category,
    ranked_test.body_system,
    ranked_test.test_type,
    ranked_test.purpose,
    ranked_test.preparation,
    ranked_test.age_recommendation,
    ranked_test.home_collection_available,
    ranked_test.lab_visit_required,
    ranked_test.special_handling_required,
    ranked_test.is_popular,
    ranked_test.min_age,
    ranked_test.max_age,
    ranked_test.gender,
    ranked_test.parameter_count,
    ranked_test.included_parameters,
    ranked_test.sample_source,
    ranked_test.sample_source_label,
    ranked_test.sample_collection_note,
    ranked_test.score,
    case
      when ranked_test.common_name_lower = normalized_query
        or ranked_test.name_lower = normalized_query
        or ranked_test.code_lower = normalized_query
        then 'Exact match'
      when ranked_test.common_name_lower like normalized_query || '%'
        or ranked_test.name_lower like normalized_query || '%'
        or ranked_test.code_lower like normalized_query || '%'
        then 'Name match'
      when ranked_test.keyword_match then 'Matches your health need'
      when ranked_test.text_rank > 0 then 'Relevant test'
      else 'Closest match'
    end
  from ranked as ranked_test
  order by
    ranked_test.score desc,
    ranked_test.is_popular desc,
    ranked_test.display_order,
    ranked_test.name_sheet
  limit safe_limit;
end;
$$;

revoke all on function public.search_medical_tests(text, integer, text) from public;
grant execute on function public.search_medical_tests(text, integer, text)
  to anon, authenticated;

create table if not exists public.collection_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null default 'Home',
  location_type text not null default 'precise'
    check (location_type in ('precise', 'approximate', 'manual')),
  display_address text not null,
  address_line1 text,
  address_line2 text,
  landmark text,
  locality text,
  city text,
  state text,
  postal_code text,
  country_code text not null default 'IN',
  recipient_name text,
  phone_number text,
  latitude double precision,
  longitude double precision,
  serviceability_status text not null default 'unverified'
    check (serviceability_status in ('unverified', 'serviceable', 'limited', 'unavailable')),
  is_default boolean not null default false,
  last_used_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(trim(display_address)) between 3 and 500),
  check (latitude is null or latitude between -90 and 90),
  check (longitude is null or longitude between -180 and 180)
);

alter table public.collection_addresses enable row level security;

create unique index if not exists collection_addresses_one_default_per_user_idx
  on public.collection_addresses (user_id)
  where is_default = true;

create index if not exists collection_addresses_user_recent_idx
  on public.collection_addresses (user_id, last_used_at desc);

drop policy if exists "Users can read their collection addresses"
  on public.collection_addresses;
create policy "Users can read their collection addresses"
  on public.collection_addresses
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their collection addresses"
  on public.collection_addresses;
create policy "Users can create their collection addresses"
  on public.collection_addresses
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their collection addresses"
  on public.collection_addresses;
create policy "Users can update their collection addresses"
  on public.collection_addresses
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their collection addresses"
  on public.collection_addresses;
create policy "Users can delete their collection addresses"
  on public.collection_addresses
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on table public.collection_addresses from anon;
grant select, insert, update, delete on table public.collection_addresses
  to authenticated;

create or replace function public.set_default_collection_address(
  p_address_id uuid
)
returns public.collection_addresses
language plpgsql
security definer
set search_path = ''
as $$
declare
  acting_user_id uuid := (select auth.uid());
  selected_address public.collection_addresses;
begin
  if acting_user_id is null then
    raise exception 'Sign in is required' using errcode = '42501';
  end if;

  select address.*
  into selected_address
  from public.collection_addresses as address
  where address.id = p_address_id
    and address.user_id = acting_user_id
  for update;

  if selected_address.id is null then
    raise exception 'Address was not found' using errcode = '42501';
  end if;

  update public.collection_addresses as address
  set
    is_default = false,
    updated_at = now()
  where address.user_id = acting_user_id
    and address.is_default = true
    and address.id <> p_address_id;

  update public.collection_addresses as address
  set
    is_default = true,
    last_used_at = now(),
    updated_at = now()
  where address.id = p_address_id
    and address.user_id = acting_user_id
  returning address.* into selected_address;

  return selected_address;
end;
$$;

revoke all on function public.set_default_collection_address(uuid) from public;
grant execute on function public.set_default_collection_address(uuid)
  to authenticated;

alter table public.orders
  add column if not exists collection_address_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_collection_address_id_fkey'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_collection_address_id_fkey
      foreign key (collection_address_id)
      references public.collection_addresses(id)
      on delete set null;
  end if;
end
$$;

create index if not exists orders_collection_address_id_idx
  on public.orders (collection_address_id)
  where collection_address_id is not null;
