-- Razorpay warns that webhooks can arrive out of order. Keep each refund's
-- financial state monotonic so a late `refund.created` or `refund.failed`
-- event cannot overwrite an already processed refund.
create or replace function private.enforce_razorpay_refund_status_monotonic()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.status = 'processed'
     and new.status in ('pending', 'failed') then
    new.status := old.status;
    new.processed_at := old.processed_at;
  elsif old.status = 'failed'
        and new.status = 'pending' then
    new.status := old.status;
  end if;

  return new;
end;
$$;

revoke all on function
  private.enforce_razorpay_refund_status_monotonic()
from public, anon, authenticated, service_role;

drop trigger if exists payment_refunds_keep_terminal_status
  on public.payment_refunds;
create trigger payment_refunds_keep_terminal_status
before update of status
on public.payment_refunds
for each row
execute function private.enforce_razorpay_refund_status_monotonic();
