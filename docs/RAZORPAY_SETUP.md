# Razorpay payment setup

The app creates and verifies every Razorpay payment on Supabase Edge
Functions. The mobile app receives the public Razorpay key ID, provider order
ID, and booking amount only. The key secret and webhook secret must never be
included in the app, repository, or build configuration.

## What is included

- `create-razorpay-order` calculates the amount from the stored booking and
  creates an idempotent Razorpay Order.
- `verify-razorpay-payment` validates the checkout HMAC signature, fetches the
  payment from Razorpay, and confirms the booking only after capture.
- `razorpay-webhook` validates the raw request signature, deduplicates events,
  and recovers captured payments when the app callback is interrupted.
- The database stores payment attempts, refunds, webhook event IDs, and an
  atomic booking finalizer.
- The Flutter app opens Razorpay Checkout and allows a pending or failed
  payment to be retried from Order details.

## Configure Razorpay and Supabase

1. Start with Razorpay Test Mode. Copy the test key ID and key secret.
2. In Supabase Dashboard, open **Edge Functions → Secrets** and set:

   - `RAZORPAY_KEY_ID`
   - `RAZORPAY_KEY_SECRET`
   - `RAZORPAY_WEBHOOK_SECRET`

   The webhook secret is a separate random value chosen while creating the
   webhook. It is not the Razorpay API key secret.
3. In Razorpay Dashboard, enable automatic capture for successful payments.
4. Create a webhook with this URL:

   `https://jfimeyukzzorjzlhrtuf.supabase.co/functions/v1/razorpay-webhook`

5. Subscribe the webhook to:

   - `payment.authorized`
   - `payment.captured`
   - `payment.failed`
   - `refund.created`
   - `refund.processed`
   - `refund.failed`

6. Install the payment-capable app build on an internal test device.
7. Test on a staging Supabase project when possible. If this production project
   is the only environment, use a controlled test window after unsupported app
   traffic is paused: temporarily enable the rollout switch shown below, then
   disable it immediately after testing.
8. Complete a successful payment, a cancelled payment, and a failed payment in
   Test Mode. Confirm that duplicate webhook delivery does not create a second
   payment attempt or confirm a different booking.

Secrets can also be set with the CLI:

```bash
supabase secrets set \
  RAZORPAY_KEY_ID=rzp_test_replace_me \
  RAZORPAY_KEY_SECRET=replace_me \
  RAZORPAY_WEBHOOK_SECRET=replace_me
```

## Safe rollout

The database migration leaves payment enforcement disabled so older mobile
builds continue to book normally. Checkout is also intentionally bypassed while
this switch is disabled. Enable it only in staging, during a controlled Test
Mode window, or after the updated Android/iOS app is released:

```sql
update private.payment_gateway_settings
set enabled = true, updated_at = now()
where singleton = true;
```

To stop creating new payment-pending bookings without removing payment
history:

```sql
update private.payment_gateway_settings
set enabled = false, updated_at = now()
where singleton = true;
```

Use live keys only after Test Mode passes and the updated app is available to
users. Replace all three Supabase secrets together, create the production
webhook, then enable the rollout switch.

## Official references

- [Razorpay Flutter Standard Checkout](https://razorpay.com/docs/payments/payment-gateway/flutter-integration/standard/integration-steps/)
- [Razorpay Orders API](https://razorpay.com/docs/api/orders/create/)
- [Razorpay payment signature verification](https://razorpay.com/docs/payments/server-integration/nodejs/integration-steps/)
- [Razorpay webhook validation](https://razorpay.com/docs/webhooks/validate-test/)
- [Supabase Edge Function secrets](https://supabase.com/docs/guides/functions/secrets)
