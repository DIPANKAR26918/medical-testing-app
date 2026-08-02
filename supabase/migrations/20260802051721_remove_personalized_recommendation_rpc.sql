-- The home recommendation engine has been retired. Its ranking RPC was
-- stateless, so removing it does not delete user, booking, or catalogue data.
drop function if exists public.get_personalized_medical_test_candidates(
  jsonb,
  integer,
  text,
  integer
);
