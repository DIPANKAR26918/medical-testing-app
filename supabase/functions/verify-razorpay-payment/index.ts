import {
  authenticateUser,
  cleanText,
  corsHeaders,
  createAdminClient,
  hmacSha256Hex,
  jsonResponse,
  PaymentConfigurationError,
  positiveSafeInteger,
  RazorpayApiError,
  razorpayCredentials,
  razorpayRequest,
  readJsonObject,
  timingSafeHexEqual,
} from "../_shared/razorpay.ts";

type PaymentAttemptRow = {
  id: string;
  order_id: number;
  user_id: string;
  provider_order_id: string;
  amount_paise: number;
  currency: string;
  status: string;
};

type RazorpayPayment = {
  id: string;
  order_id: string;
  amount: number;
  currency: string;
  status: string;
  captured: boolean;
};

async function fetchSettledPayment(
  paymentId: string,
): Promise<RazorpayPayment> {
  let payment = await razorpayRequest<RazorpayPayment>(
    `/payments/${encodeURIComponent(paymentId)}`,
  );

  // Default auto-capture is normally immediate, but a short bounded poll avoids
  // showing a false failure when Checkout wins a small race with capture.
  for (
    let attempt = 0;
    attempt < 3 && payment.status === "authorized";
    attempt += 1
  ) {
    await new Promise((resolve) => setTimeout(resolve, 500));
    payment = await razorpayRequest<RazorpayPayment>(
      `/payments/${encodeURIComponent(paymentId)}`,
    );
  }
  return payment;
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  try {
    const admin = createAdminClient();
    const user = await authenticateUser(request, admin);
    if (!user) return jsonResponse({ error: "authentication_required" }, 401);

    const payload = await readJsonObject(request);
    const bookingOrderId = positiveSafeInteger(payload?.booking_order_id);
    const providerOrderId = cleanText(payload?.razorpay_order_id, 120);
    const providerPaymentId = cleanText(payload?.razorpay_payment_id, 120);
    const receivedSignature = cleanText(payload?.razorpay_signature, 256);
    if (
      !bookingOrderId ||
      !providerOrderId ||
      !providerPaymentId ||
      !receivedSignature
    ) {
      return jsonResponse({ error: "complete_payment_response_required" }, 400);
    }

    const { data, error } = await admin
      .from("payment_attempts")
      .select(
        "id,order_id,user_id,provider_order_id,amount_paise,currency,status",
      )
      .eq("provider_order_id", providerOrderId)
      .eq("order_id", bookingOrderId)
      .eq("user_id", user.id)
      .maybeSingle();
    if (error) throw new Error(`payment_attempt_lookup_failed:${error.code}`);
    const attempt = data as PaymentAttemptRow | null;
    if (!attempt) {
      return jsonResponse({ error: "payment_attempt_not_found" }, 404);
    }

    const expectedSignature = await hmacSha256Hex(
      `${attempt.provider_order_id}|${providerPaymentId}`,
      razorpayCredentials().keySecret,
    );
    if (!timingSafeHexEqual(expectedSignature, receivedSignature)) {
      console.warn("Razorpay checkout signature rejected", {
        bookingOrderId,
        providerOrderId,
      });
      return jsonResponse({ error: "invalid_payment_signature" }, 400);
    }

    const payment = await fetchSettledPayment(providerPaymentId);
    if (
      payment.id !== providerPaymentId ||
      payment.order_id !== attempt.provider_order_id ||
      payment.amount !== attempt.amount_paise ||
      payment.currency !== attempt.currency
    ) {
      return jsonResponse({ error: "payment_details_do_not_match" }, 409);
    }

    if (payment.status === "authorized" && !payment.captured) {
      await admin
        .from("payment_attempts")
        .update({
          provider_payment_id: payment.id,
          status: "authorized",
          verification_source: "checkout_signature",
          signature_verified_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq("id", attempt.id)
        .in("status", ["created", "authorized"]);

      return jsonResponse({
        payment_status: "processing",
        booking_order_id: bookingOrderId,
      }, 202);
    }

    if (payment.status !== "captured" || payment.captured !== true) {
      return jsonResponse({ error: "payment_not_captured" }, 409);
    }

    const { data: finalized, error: finalizeError } = await admin.rpc(
      "finalize_razorpay_payment",
      {
        p_provider_order_id: attempt.provider_order_id,
        p_provider_payment_id: payment.id,
        p_amount_paise: payment.amount,
        p_currency: payment.currency,
        p_verification_source: "checkout_signature",
      },
    );
    if (finalizeError) {
      throw new Error(`payment_finalization_failed:${finalizeError.code}`);
    }

    return jsonResponse({
      payment_status: "paid",
      booking_order_id: bookingOrderId,
      order: finalized,
    });
  } catch (error) {
    if (error instanceof PaymentConfigurationError) {
      console.error("verify-razorpay-payment is not configured", {
        code: error.message,
      });
      return jsonResponse({ error: "payments_not_configured" }, 503);
    }
    if (error instanceof RazorpayApiError) {
      console.error("Razorpay payment lookup failed", {
        status: error.status,
        code: error.providerCode,
      });
      return jsonResponse({ error: "payment_verification_unavailable" }, 502);
    }

    const code = error instanceof Error ? error.message : "unknown_error";
    console.error("verify-razorpay-payment failed", { code });
    return jsonResponse({ error: "payment_verification_failed" }, 500);
  }
});
