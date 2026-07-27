-- `reliable_push_notification_delivery` used the `_idx` name while the
-- contextual notification migration uses the canonical index name below.
-- Both enforce the same partial uniqueness, so retain only one.
drop index if exists public.notifications_event_key_unique_idx;
