import {
  cleanText,
  corsHeaders,
  createAdminClient,
  hmacSha256Hex,
  jsonResponse,
  PaymentConfigurationError,
  positiveSafeInteger,
  requiredEnv,
  sha256Hex,
  timingSafeHexEqual,
} from "../_shared/razorpay.ts";

type JsonObject = Record<string, unknown>;

function objectValue(value: unknown): JsonObject | null {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as JsonObject
    : null;
}

function entity(payload: JsonObject, name: string): JsonObject | null {
  const payloadObject = objectValue(payload.payload);
  const wrapper = objectValue(payloadObject?.[name]);
  return objectValue(wrapper?.entity);
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  let eventId = "";
  let admin: ReturnType<typeof createAdminClient> | null = null;

  try {
    admin = createAdminClient();
    const rawBody = await request.text();
    const receivedSignature = request.headers
      .get("x-razorpay-signature")
      ?.trim() ?? "";
    if (!rawBody || !receivedSignature) {
      return jsonResponse({ error: "signed_webhook_required" }, 400);
    }

    const expectedSignature = await hmacSha256Hex(
      rawBody,
      requiredEnv("RAZORPAY_WEBHOOK_SECRET"),
    );
    if (!timingSafeHexEqual(expectedSignature, receivedSignature)) {
      return jsonResponse({ error: "invalid_webhook_signature" }, 401);
    }

    const parsed = JSON.parse(rawBody) as unknown;
    const payload = objectValue(parsed);
    if (!payload) {
      return jsonResponse({ error: "invalid_webhook_payload" }, 400);
    }

    const eventType = cleanText(payload.event, 160);
    if (!eventType) {
      return jsonResponse({ error: "webhook_event_required" }, 400);
    }

    const payloadHash = await sha256Hex(rawBody);
    eventId = cleanText(
      request.headers.get("x-razorpay-event-id"),
      255,
    ) ?? `payload_${payloadHash}`;

    const { error: eventInsertError } = await admin
      .from("payment_webhook_events")
      .insert({
        event_id: eventId,
        event_type: eventType,
        payload_sha256: payloadHash,
        status: "processing",
      });

    if (eventInsertError?.code === "23505") {
      const { data: existing, error: existingError } = await admin
        .from("payment_webhook_events")
        .select("status,payload_sha256,updated_at")
        .eq("event_id", eventId)
        .single();
      if (existingError) throw existingError;
      if (existing.payload_sha256 !== payloadHash) {
        return jsonResponse({ error: "webhook_event_conflict" }, 409);
      }
      if (existing.status === "processed" || existing.status === "ignored") {
        return jsonResponse({ received: true, duplicate: true });
      }
      const processingStartedAt = Date.parse(existing.updated_at);
      if (
        existing.status === "processing" &&
        Number.isFinite(processingStartedAt) &&
        Date.now() - processingStartedAt < 5 * 60 * 1000
      ) {
        return jsonResponse({
          received: true,
          duplicate: true,
          processing: true,
        }, 202);
      }

      await admin.from("payment_webhook_events").update({
        status: "processing",
        last_error: null,
        updated_at: new Date().toISOString(),
      }).eq("event_id", eventId);
    } else if (eventInsertError) {
      throw eventInsertError;
    }

    let handled = false;

    if (eventType === "payment.authorized") {
      const payment = entity(payload, "payment");
      const providerOrderId = cleanText(payment?.order_id, 120);
      const providerPaymentId = cleanText(payment?.id, 120);
      if (providerOrderId && providerPaymentId) {
        const { error } = await admin
          .from("payment_attempts")
          .update({
            provider_payment_id: providerPaymentId,
            status: "authorized",
            verification_source: "webhook",
            updated_at: new Date().toISOString(),
          })
          .eq("provider_order_id", providerOrderId)
          .in("status", ["created", "authorized"]);
        if (error) throw error;
        handled = true;
      }
    } else if (eventType === "payment.captured") {
      const payment = entity(payload, "payment");
      const providerOrderId = cleanText(payment?.order_id, 120);
      const providerPaymentId = cleanText(payment?.id, 120);
      const amount = positiveSafeInteger(payment?.amount);
      const currency = cleanText(payment?.currency, 8);
      if (!providerOrderId || !providerPaymentId || !amount || !currency) {
        throw new Error("invalid_payment_captured_payload");
      }

      const { error } = await admin.rpc("finalize_razorpay_payment", {
        p_provider_order_id: providerOrderId,
        p_provider_payment_id: providerPaymentId,
        p_amount_paise: amount,
        p_currency: currency,
        p_verification_source: "webhook",
      });
      if (error) throw error;
      handled = true;
    } else if (eventType === "payment.failed") {
      const payment = entity(payload, "payment");
      const providerOrderId = cleanText(payment?.order_id, 120);
      if (providerOrderId) {
        const errorObject = objectValue(payment?.error);
        const { error } = await admin.rpc(
          "record_razorpay_payment_failure",
          {
            p_provider_order_id: providerOrderId,
            p_provider_payment_id: cleanText(payment?.id, 120),
            p_failure_code: cleanText(
              payment?.error_code ?? errorObject?.code,
              160,
            ),
            p_failure_description: cleanText(
              payment?.error_description ?? errorObject?.description,
              500,
            ),
          },
        );
        if (error) throw error;
        handled = true;
      }
    } else if (
      eventType === "refund.created" ||
      eventType === "refund.processed" ||
      eventType === "refund.failed"
    ) {
      const refund = entity(payload, "refund");
      const providerRefundId = cleanText(refund?.id, 120);
      const providerPaymentId = cleanText(refund?.payment_id, 120);
      const amount = positiveSafeInteger(refund?.amount);
      // Some Razorpay refund webhook examples contain an empty currency even
      // though the original payment is INR. The database re-validates this
      // against the stored payment attempt before accepting the event.
      const currency = cleanText(refund?.currency, 8) ?? "INR";
      const refundStatus = eventType === "refund.processed"
        ? "processed"
        : eventType === "refund.failed"
        ? "failed"
        : "pending";
      if (
        !providerRefundId ||
        !providerPaymentId ||
        !amount
      ) {
        throw new Error("invalid_refund_payload");
      }

      const { error } = await admin.rpc("record_razorpay_refund", {
        p_provider_refund_id: providerRefundId,
        p_provider_payment_id: providerPaymentId,
        p_amount_paise: amount,
        p_currency: currency,
        p_status: refundStatus,
      });
      if (error) throw error;
      handled = true;
    }

    await admin.from("payment_webhook_events").update({
      status: handled ? "processed" : "ignored",
      processed_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }).eq("event_id", eventId);

    return jsonResponse({ received: true, handled });
  } catch (error) {
    const code = error instanceof Error ? error.message : "webhook_failed";
    if (eventId && admin) {
      await admin.from("payment_webhook_events").update({
        status: "failed",
        last_error: code.slice(0, 500),
        updated_at: new Date().toISOString(),
      }).eq("event_id", eventId);
    }

    if (error instanceof PaymentConfigurationError) {
      console.error("razorpay-webhook is not configured", {
        code: error.message,
      });
      return jsonResponse({ error: "webhook_not_configured" }, 503);
    }
    console.error("razorpay-webhook failed", { code });
    return jsonResponse({ error: "webhook_processing_failed" }, 500);
  }
});
