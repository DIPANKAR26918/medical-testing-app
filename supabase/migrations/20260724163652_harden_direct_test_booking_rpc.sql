-- The privileged implementation lives in the non-exposed private schema.
-- Keep the public Data API entry point as a SECURITY INVOKER wrapper.
alter function public.create_direct_test_booking(uuid[], uuid)
  security invoker;

revoke all on function public.create_direct_test_booking(uuid[], uuid) from public;
revoke all on function public.create_direct_test_booking(uuid[], uuid) from anon;
grant execute on function public.create_direct_test_booking(uuid[], uuid)
  to authenticated, service_role;
