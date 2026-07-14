create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  phone_number text,
  display_name text,
  full_name text,
  age integer,
  gender text,
  role text not null default 'patient',
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.users
add column if not exists email text;

alter table public.users
add column if not exists phone_number text;

alter table public.users
add column if not exists display_name text;

alter table public.users
add column if not exists full_name text;

alter table public.users
add column if not exists age integer;

alter table public.users
add column if not exists gender text;

alter table public.users
add column if not exists role text not null default 'patient';

alter table public.users
add column if not exists updated_at timestamp with time zone not null default now();

alter table public.users
drop constraint if exists users_role_check;

alter table public.users
add constraint users_role_check
check (role in ('patient', 'agent', 'admin'));

create table if not exists public.orders (
  id bigserial primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  prescription_image_url text not null,
  status text not null default 'uploaded',
  test_list text[] not null default '{}',
  price numeric(10, 2) not null default 0,
  agent_id uuid references public.users(id) on delete set null,
  patient_name text,
  patient_phone_number text,
  patient_age integer,
  patient_gender text,
  timeline jsonb not null default '[]'::jsonb,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.orders
add column if not exists patient_name text;

alter table public.orders
add column if not exists patient_phone_number text;

alter table public.orders
add column if not exists patient_age integer;

alter table public.orders
add column if not exists patient_gender text;

alter table public.orders
add column if not exists updated_at timestamp with time zone not null default now();

alter table public.orders
drop constraint if exists orders_status_check;

alter table public.orders
add constraint orders_status_check
check (
  status in (
    'uploaded',
    'processing',
    'confirmed',
    'booking_requested',
    'booking_confirmed',
    'assigned',
    'collected',
    'testing',
    'completed',
    'cancelled'
  )
);

create index if not exists idx_users_email
on public.users (email);

create index if not exists idx_users_role
on public.users (role);

create index if not exists idx_orders_user_id
on public.orders (user_id);

create index if not exists idx_orders_agent_id
on public.orders (agent_id);

create index if not exists idx_orders_status
on public.orders (status);

create index if not exists idx_orders_created_at
on public.orders (created_at desc);

alter table public.users enable row level security;
alter table public.orders enable row level security;

drop policy if exists "Users can read own profile" on public.users;
drop policy if exists "Users can insert their own profile" on public.users;
drop policy if exists "Users can update own profile" on public.users;
drop policy if exists "Assigned agents can read patient profiles" on public.users;

create policy "Users can read own profile"
on public.users
for select
to authenticated
using (auth.uid() = id);

create policy "Users can insert their own profile"
on public.users
for insert
to authenticated
with check (auth.uid() = id);

create policy "Users can update own profile"
on public.users
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can read own orders" on public.orders;
drop policy if exists "Agents can read assigned orders" on public.orders;
drop policy if exists "Staff can read review queue" on public.orders;
drop policy if exists "Users can create orders" on public.orders;
drop policy if exists "Users can update own orders" on public.orders;
drop policy if exists "Staff can update orders" on public.orders;

create policy "Users can read own orders"
on public.orders
for select
to authenticated
using (auth.uid() = user_id);

create policy "Agents can read assigned orders"
on public.orders
for select
to authenticated
using (auth.uid() = agent_id);

create policy "Staff can read review queue"
on public.orders
for select
to authenticated
using (
  status in ('uploaded', 'processing', 'confirmed', 'booking_requested')
  and exists (
    select 1
    from public.users actor
    where actor.id = auth.uid()
      and actor.role in ('agent', 'admin')
  )
);

create policy "Users can create orders"
on public.orders
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can update own orders"
on public.orders
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Staff can update orders"
on public.orders
for update
to authenticated
using (
  auth.uid() = agent_id
  or exists (
    select 1
    from public.users actor
    where actor.id = auth.uid()
      and actor.role in ('agent', 'admin')
  )
)
with check (
  auth.uid() = agent_id
  or exists (
    select 1
    from public.users actor
    where actor.id = auth.uid()
      and actor.role in ('agent', 'admin')
  )
);

insert into storage.buckets (id, name, public)
values ('prescriptions', 'prescriptions', false)
on conflict (id) do update set public = false;

drop policy if exists "Users can upload prescriptions" on storage.objects;
drop policy if exists "Strict access for User and Assigned Agent" on storage.objects;
drop policy if exists "Users can delete own prescriptions" on storage.objects;

create policy "Users can upload prescriptions"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'prescriptions'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Strict access for User and Assigned Agent"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'prescriptions'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (
      select 1
      from public.orders
      where orders.prescription_image_url = storage.objects.name
        and (
          orders.agent_id = auth.uid()
          or exists (
            select 1
            from public.users actor
            where actor.id = auth.uid()
              and actor.role in ('agent', 'admin')
              and orders.status in (
                'uploaded',
                'processing',
                'confirmed',
                'booking_requested'
              )
          )
        )
    )
  )
);

create policy "Users can delete own prescriptions"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'prescriptions'
  and (storage.foldername(name))[1] = auth.uid()::text
);
