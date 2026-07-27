import { createClient } from "npm:@supabase/supabase-js@2.95.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`missing_${name.toLowerCase()}`);
  return value;
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const authorization = request.headers.get("Authorization");
    const accessToken = authorization?.startsWith("Bearer ")
      ? authorization.slice("Bearer ".length).trim()
      : "";
    if (!accessToken) {
      return json({ error: "authentication_required" }, 401);
    }

    const admin = createClient(
      requiredEnv("SUPABASE_URL"),
      requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { autoRefreshToken: false, persistSession: false } },
    );
    const {
      data: { user },
      error: userError,
    } = await admin.auth.getUser(accessToken);
    if (userError || !user) {
      return json({ error: "invalid_session" }, 401);
    }

    const payload = await request.json().catch(() => null) as
      | Record<string, unknown>
      | null;
    const orderId = Number(payload?.order_id);
    const requestedUserId = payload?.user_id?.toString().trim() ?? "";
    if (!Number.isSafeInteger(orderId) || orderId < 1 || !requestedUserId) {
      return json({ error: "valid_order_required" }, 400);
    }

    const { data: order, error: orderError } = await admin
      .from("orders")
      .select("id,user_id,agent_id,status")
      .eq("id", orderId)
      .eq("user_id", requestedUserId)
      .maybeSingle();
    if (orderError) throw new Error(`order_lookup_failed:${orderError.code}`);
    if (!order) return json({ error: "order_not_found" }, 404);

    let authorized = order.user_id === user.id;
    if (!authorized && order.agent_id === user.id) {
      const { data: agent, error: agentError } = await admin
        .from("agent_profiles")
        .select("id")
        .eq("id", user.id)
        .eq("verification_status", "approved")
        .eq("is_active", true)
        .maybeSingle();
      if (agentError) {
        throw new Error(`agent_lookup_failed:${agentError.code}`);
      }
      authorized = agent != null;
    }
    if (!authorized) {
      return json({ error: "order_access_required" }, 403);
    }

    // The database trigger owns message copy and deep-link data. This
    // compatibility endpoint cannot accept caller-supplied notification text.
    const status = order.status?.toString().trim().toLowerCase() ?? "";
    const eventKey = `order:${order.id}:status:${status}`;
    const { data: notification, error: notificationError } = await admin
      .from("notifications")
      .select("id")
      .eq("event_key", eventKey)
      .maybeSingle();
    if (notificationError) {
      throw new Error(
        `notification_lookup_failed:${notificationError.code}`,
      );
    }

    return json({
      saved: notification != null,
      notification_id: notification?.id ?? null,
      delivery: "database_managed",
    }, notification == null ? 202 : 200);
  } catch (error) {
    const code = error instanceof Error ? error.message : "send_push_failed";
    console.error("send-push failed", { code });
    return json({ error: "notification_request_failed" }, 500);
  }
});
