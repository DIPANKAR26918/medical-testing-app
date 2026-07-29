-- The payment order Edge Function uses the service role to validate a booking
-- before creating a Razorpay order. Keep this grant read-only.
grant select on table public.orders to service_role;
