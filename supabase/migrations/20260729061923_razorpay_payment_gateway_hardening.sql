-- Explicitly document that webhook payload metadata is server-only. Table
-- privileges are already revoked; the deny policy keeps that intent visible to
-- RLS tooling as well.
drop policy if exists "Clients cannot access payment webhook events"
  on public.payment_webhook_events;
create policy "Clients cannot access payment webhook events"
on public.payment_webhook_events
for all
to anon, authenticated
using (false)
with check (false);

create index if not exists payment_refunds_order_created_idx
on public.payment_refunds (order_id, created_at desc);

create index if not exists payment_refunds_user_created_idx
on public.payment_refunds (user_id, created_at desc);
