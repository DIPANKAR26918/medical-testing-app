-- The default-address switch only touches rows already permitted by the
-- owner's RLS policies, so it does not need elevated table-owner privileges.
alter function public.set_default_collection_address(uuid) security invoker;
