create extension if not exists pgcrypto;

create table if not exists public.medical_tests (
  id uuid primary key default gen_random_uuid(),
  test_code text,
  name_sheet text not null,
  common_name text,
  mrp numeric(10, 2),
  reporting_time text,
  sample_type_volume text,
  category text,
  body_system text,
  test_type text not null default 'individual' check (test_type in ('individual', 'panel', 'procedure')),
  purpose text,
  preparation text,
  age_recommendation text,
  home_collection_available boolean not null default true,
  lab_visit_required boolean not null default false,
  special_handling_required boolean not null default false,
  search_keywords text[] not null default '{}',
  is_active boolean not null default true,
  is_popular boolean not null default false,
  is_preventive boolean not null default false,
  min_age integer,
  max_age integer,
  gender text not null default 'any' check (gender in ('any', 'male', 'female')),
  display_order integer not null default 999,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.medical_tests enable row level security;

revoke all on table public.medical_tests from anon, authenticated;
grant select on table public.medical_tests to anon, authenticated;

create policy "Public can read active medical tests"
on public.medical_tests
for select
to public
using (is_active = true);

create index medical_tests_test_code_idx
on public.medical_tests (test_code);

create index medical_tests_category_idx
on public.medical_tests (category);

create index medical_tests_is_active_idx
on public.medical_tests (is_active);

create index medical_tests_is_popular_idx
on public.medical_tests (is_popular);

create index medical_tests_is_preventive_idx
on public.medical_tests (is_preventive);
