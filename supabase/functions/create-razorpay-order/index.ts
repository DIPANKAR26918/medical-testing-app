import {
  authenticateUser,
  cleanText,
  corsHeaders,
  createAdminClient,
  jsonResponse,
  normalizeIndianContact,
  PaymentConfigurationError,
  positiveSafeInteger,
  RazorpayApiError,
  razorpayCredentials,
  razorpayRequest,
  readJsonObject,
  rupeesToPaise,
} from "../_shared/razorpay.ts";

type BookingRow = {
  id: number;
  user_id: string;
  status: string;
  price: number | string;
  payment_status: string;
  patient_name?: string | null;
  patient_phone_number?: string | null;
  test_list?: string[] | null;
};

type PaymentAttemptRow = {
  id: string;
  provider_order_id: string | null;
  amount_paise: number;
  currency: string;
  status: string;
  receipt: string;
  updated_at: string;
};

type RazorpayOrder = {
  id: string;
  amount: number;
  currency: string;
  receipt: string;
  status: string;
};

function checkoutPayload(
  order: BookingRow,
  attempt: PaymentAttemptRow,
  keyId: string,
  userEmail: string | null,
) {
  const firstTest = order.test_list?.find((name) => name.trim().length > 0);
  return {
    booking_order_id: order.id,
    razorpay_order_id: attempt.provider_order_id,
    key_id: keyId,
    amount: attempt.amount_paise,
    currency: attempt.currency,
    description: cleanText(firstTest, 180) ?? "Diagnostic test booking",
    prefill: {
      name: cleanText(order.patient_name, 120),
      contact: normalizeIndianContact(order.patient_phone_number),
      email: cleanText(userEmail, 254),
    },
  };
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  let attemptId = "";
  let admin: ReturnType<typeof createAdminClient> | null = null;

  try {
    admin = createAdminClient();
    const user = await authenticateUser(request, admin);
    if (!user) return jsonResponse({ error: "authentication_required" }, 401);

    const payload = await readJsonObject(request);
    const bookingOrderId = positiveSafeInteger(payload?.order_id);
    if (!bookingOrderId) {
      return jsonResponse({ error: "valid_booking_order_required" }, 400);
    }

    const { data, error } = await admin
      .from("orders")
      .select("*")
      .eq("id", bookingOrderId)
      .eq("user_id", user.id)
      .maybeSingle();
    if (error) throw new Error(`booking_lookup_failed:${error.code}`);
    const order = data as BookingRow | null;
    if (!order) return jsonResponse({ error: "booking_not_found" }, 404);

    if (
      ["paid", "partially_refunded", "refunded"].includes(
        order.payment_status,
      ) &&
      order.status === "confirmed"
    ) {
      return jsonResponse({
        already_paid: true,
        booking_order_id: order.id,
        order,
      });
    }
    if (
      order.status !== "payment_pending" ||
      !["pending", "failed"].includes(order.payment_status)
    ) {
      return jsonResponse({ error: "booking_not_awaiting_payment" }, 409);
    }

    const amountPaise = rupeesToPaise(order.price);
    if (!amountPaise) {
      return jsonResponse({ error: "invalid_booking_total" }, 422);
    }

    const { data: existingData, error: existingError } = await admin
      .from("payment_attempts")
      .select(
        "id,provider_order_id,amount_paise,currency,status,receipt,updated_at",
      )
      .eq("order_id", order.id)
      .in("status", ["creating", "created", "authorized", "captured"])
      .maybeSingle();
    if (existingError) {
      throw new Error(`payment_attempt_lookup_failed:${existingError.code}`);
    }
    const existing = existingData as PaymentAttemptRow | null;
    if (existing?.provider_order_id) {
      if (
        existing.amount_paise !== amountPaise || existing.currency !== "INR"
      ) {
        return jsonResponse({ error: "booking_total_changed" }, 409);
      }
      if (existing.status === "authorized" || existing.status === "captured") {
        return jsonResponse({
          payment_status: "processing",
          booking_order_id: order.id,
        }, 202);
      }
      return jsonResponse(
        checkoutPayload(
          order,
          existing,
          razorpayCredentials().keyId,
          user.email ?? null,
        ),
      );
    }
    if (existing) {
      const updatedAt = Date.parse(existing.updated_at);
      const initializationIsStale = Number.isFinite(updatedAt) &&
        Date.now() - updatedAt >= 2 * 60 * 1000;
      if (!initializationIsStale) {
        return jsonResponse(
          { error: "payment_initialization_in_progress" },
          409,
        );
      }

      const { error: staleError } = await admin
        .from("payment_attempts")
        .update({
          status: "failed",
          failure_code: "stale_initialization",
          updated_at: new Date().toISOString(),
        })
        .eq("id", existing.id)
        .eq("status", "creating");
      if (staleError) {
        throw new Error(
          `stale_payment_attempt_cleanup_failed:${staleError.code}`,
        );
      }
    }

    attemptId = crypto.randomUUID();
    const compactAttemptId = attemptId.replaceAll("-", "").slice(0, 16);
    const receipt = `tf_${order.id}_${compactAttemptId}`.slice(0, 40);
    const { data: reservedData, error: reserveError } = await admin
      .from("payment_attempts")
      .insert({
        id: attemptId,
        order_id: order.id,
        user_id: user.id,
        receipt,
        amount_paise: amountPaise,
        currency: "INR",
        status: "creating",
      })
      .select(
        "id,provider_order_id,amount_paise,currency,status,receipt,updated_at",
      )
      .single();

    if (reserveError) {
      if (reserveError.code === "23505") {
        return jsonResponse(
          { error: "payment_initialization_in_progress" },
          409,
        );
      }
      throw new Error(
        `payment_attempt_reservation_failed:${reserveError.code}`,
      );
    }

    const providerOrder = await razorpayRequest<RazorpayOrder>("/orders", {
      method: "POST",
      body: {
        amount: amountPaise,
        currency: "INR",
        receipt,
        partial_payment: false,
        notes: {
          testified_order_id: order.id.toString(),
          source: "testified_app",
        },
      },
    });

    if (
      !providerOrder.id ||
      providerOrder.amount !== amountPaise ||
      providerOrder.currency !== "INR" ||
      providerOrder.receipt !== receipt ||
      providerOrder.status !== "created"
    ) {
      throw new Error("invalid_razorpay_order_response");
    }

    const { data: completedData, error: completeError } = await admin
      .from("payment_attempts")
      .update({
        provider_order_id: providerOrder.id,
        status: "created",
        updated_at: new Date().toISOString(),
      })
      .eq("id", attemptId)
      .eq("status", "creating")
      .select(
        "id,provider_order_id,amount_paise,currency,status,receipt,updated_at",
      )
      .single();
    if (completeError) {
      throw new Error(`payment_attempt_update_failed:${completeError.code}`);
    }

    return jsonResponse(
      checkoutPayload(
        order,
        completedData as PaymentAttemptRow,
        razorpayCredentials().keyId,
        user.email ?? null,
      ),
      201,
    );
  } catch (error) {
    if (attemptId && admin) {
      await admin.from("payment_attempts").update({
        status: "failed",
        failure_code: error instanceof RazorpayApiError
          ? error.providerCode
          : "payment_initialization_failed",
        updated_at: new Date().toISOString(),
      }).eq("id", attemptId).eq("status", "creating");
    }

    if (error instanceof PaymentConfigurationError) {
      console.error("create-razorpay-order is not configured", {
        code: error.message,
      });
      return jsonResponse({ error: "payments_not_configured" }, 503);
    }
    if (error instanceof RazorpayApiError) {
      console.error("Razorpay order creation failed", {
        status: error.status,
        code: error.providerCode,
      });
      return jsonResponse({ error: "payment_provider_unavailable" }, 502);
    }

    const code = error instanceof Error ? error.message : "unknown_error";
    console.error("create-razorpay-order failed", { code });
    return jsonResponse({ error: "payment_initialization_failed" }, 500);
  }
});
