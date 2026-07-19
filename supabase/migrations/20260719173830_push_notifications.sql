create extension if not exists pgcrypto;

create table if not exists public.push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  token text not null unique,
  platform text not null,
  app_version text,
  enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint push_devices_platform_check
    check (platform in ('android', 'ios')),
  constraint push_devices_token_length_check
    check (char_length(token) between 20 and 4096)
);

comment on table public.push_devices is
  'FCM registration tokens claimed by authenticated Testified users.';

create index if not exists idx_push_devices_user_enabled
on public.push_devices (user_id, enabled)
where enabled;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  body text not null,
  kind text not null default 'general',
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  constraint notifications_title_length_check
    check (char_length(title) between 1 and 160),
  constraint notifications_body_length_check
    check (char_length(body) between 1 and 1000),
  constraint notifications_data_object_check
    check (jsonb_typeof(data) = 'object')
);

comment on table public.notifications is
  'Durable in-app notification history written only by trusted backends.';

create index if not exists idx_notifications_user_created
on public.notifications (user_id, created_at desc);

create index if not exists idx_notifications_user_unread
on public.notifications (user_id, created_at desc)
where read_at is null;

alter table public.push_devices enable row level security;
alter table public.notifications enable row level security;

revoke all on table public.push_devices from anon, authenticated;
revoke all on table public.notifications from anon, authenticated;

grant select, delete on table public.push_devices to authenticated;
grant select on table public.notifications to authenticated;
grant update (read_at) on table public.notifications to authenticated;

drop policy if exists "Users can view own push devices"
on public.push_devices;
drop policy if exists "Users can delete own push devices"
on public.push_devices;

create policy "Users can view own push devices"
on public.push_devices
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can delete own push devices"
on public.push_devices
for delete
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can view own notifications"
on public.notifications;
drop policy if exists "Users can mark own notifications read"
on public.notifications;

create policy "Users can view own notifications"
on public.notifications
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can mark own notifications read"
on public.notifications
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end
$$;
