import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.95.0";

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
  token_uri?: string;
};

type DeliveryClaim = {
  state: string;
  notification_id?: string;
  title?: string;
  body?: string;
  kind?: string;
  data?: Record<string, unknown>;
  devices?: Array<{ token?: string }>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type",
};

const allowedDestinations = new Set([
  "home",
  "bookings",
  "reports",
  "order_details",
  "prescription_review",
  "test_details",
]);

const allowedDataKeys = [
  "destination",
  "order_id",
  "medical_test_id",
  "status",
  "booking_source",
];

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

function base64Url(value: string | Uint8Array): string {
  const bytes = typeof value === "string"
    ? new TextEncoder().encode(value)
    : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function privateKeyBytes(pem: string): Uint8Array {
  const encoded = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, "");
  const decoded = atob(encoded);
  return Uint8Array.from(decoded, (character) => character.charCodeAt(0));
}

async function firebaseAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const tokenUri = account.token_uri ?? "https://oauth2.googleapis.com/token";
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64Url(JSON.stringify({
    iss: account.client_email,
    sub: account.client_email,
    aud: tokenUri,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claims}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    privateKeyBytes(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${base64Url(new Uint8Array(signature))}`;

  const response = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const responseBody = await response.json().catch(() => ({})) as Record<
    string,
    unknown
  >;
  if (!response.ok || typeof responseBody.access_token !== "string") {
    throw new Error("firebase_authorization_failed");
  }
  return responseBody.access_token;
}

function validServiceAccount(value: unknown): value is ServiceAccount {
  if (!value || typeof value !== "object" || Array.isArray(value)) return false;
  const account = value as Record<string, unknown>;
  return typeof account.client_email === "string" &&
    account.client_email.length > 0 &&
    typeof account.private_key === "string" &&
    account.private_key.length > 0 &&
    typeof account.project_id === "string" &&
    account.project_id.length > 0;
}

function cleanText(
  value: unknown,
  maximumLength: number,
  fallback: string,
): string {
  const text = typeof value === "string" ? value.trim() : "";
  return text.length > 0 && text.length <= maximumLength ? text : fallback;
}

function normalized(value: unknown): string {
  return value?.toString().trim().toLowerCase().replaceAll(/[-\s]+/g, "_") ??
    "";
}

function inferredDestination(data: Record<string, unknown>): string {
  const requested = normalized(data.destination);
  if (allowedDestinations.has(requested)) return requested;

  if (data.medical_test_id) return "test_details";

  const status = normalized(data.status);
  if (
    ["awaiting_user_approval", "test_list_prepared", "tests_prepared"].includes(
      status,
    )
  ) {
    return "prescription_review";
  }
  if (["completed", "report_ready", "reports_ready"].includes(status)) {
    return "reports";
  }
  if (data.order_id) return "order_details";
  return "home";
}

function pushData(
  claim: DeliveryClaim,
  notificationId: string,
): Record<string, string> {
  const source = claim.data && typeof claim.data === "object" ? claim.data : {};
  const data: Record<string, string> = {
    notification_id: notificationId,
    kind: normalized(claim.kind) || "general",
    destination: inferredDestination(source),
  };
  data.route = "/home";
  data.tab_index = data.destination === "reports" ? "2" : [
      "bookings",
      "order_details",
      "prescription_review",
    ].includes(data.destination)
    ? "1"
    : "0";

  for (const key of allowedDataKeys) {
    if (key === "destination") continue;
    const value = source[key];
    if (
      typeof value === "string" ||
      typeof value === "number" ||
      typeof value === "boolean"
    ) {
      const text = String(value).trim();
      if (text.length > 0 && text.length <= 256) data[key] = text;
    }
  }

  return data;
}

function isInvalidToken(responseBody: unknown): boolean {
  const text = JSON.stringify(responseBody).toUpperCase();
  return text.includes("UNREGISTERED") ||
    text.includes("REGISTRATION_TOKEN_NOT_REGISTERED");
}

async function completeDelivery(
  admin: SupabaseClient,
  notificationId: string,
  dispatchToken: string,
  status: "delivered" | "waiting_for_device" | "failed",
  errorCode?: string,
): Promise<void> {
  const { error } = await admin.rpc("complete_notification_delivery", {
    p_notification_id: notificationId,
    p_dispatch_token: dispatchToken,
    p_status: status,
    p_error: errorCode ?? null,
  });
  if (error) throw new Error("delivery_completion_failed");
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  let admin: SupabaseClient | null = null;
  let notificationId = "";
  let dispatchToken = "";

  try {
    const payload = await request.json().catch(() => null) as
      | Record<string, unknown>
      | null;
    notificationId = payload?.notification_id?.toString().trim() ?? "";
    dispatchToken = payload?.dispatch_token?.toString().trim() ?? "";

    const uuidPattern =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidPattern.test(notificationId) || !uuidPattern.test(dispatchToken)) {
      return json({ error: "invalid_dispatch_request" }, 400);
    }

    admin = createClient(
      requiredEnv("SUPABASE_URL"),
      requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    const { data, error } = await admin.rpc("claim_notification_delivery", {
      p_notification_id: notificationId,
      p_dispatch_token: dispatchToken,
    });
    if (error) throw new Error("delivery_claim_failed");

    const claim = data as DeliveryClaim | null;
    if (!claim || claim.state === "unauthorized") {
      return json({ error: "invalid_dispatch_token" }, 403);
    }
    if (claim.state === "already_delivered" || claim.state === "busy") {
      return json({ state: claim.state });
    }
    if (claim.state !== "ready") {
      return json({ error: "notification_not_available" }, 404);
    }

    const devices = (claim.devices ?? [])
      .map((device) => device.token?.trim() ?? "")
      .filter((token) => token.length >= 20);
    if (devices.length === 0) {
      await completeDelivery(
        admin,
        notificationId,
        dispatchToken,
        "waiting_for_device",
        "no_enabled_device",
      );
      return json({ state: "waiting_for_device", pushed: 0 }, 202);
    }

    const rawServiceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    if (!rawServiceAccount) {
      await completeDelivery(
        admin,
        notificationId,
        dispatchToken,
        "failed",
        "firebase_not_configured",
      );
      return json({ error: "firebase_not_configured" }, 503);
    }

    let parsedServiceAccount: unknown;
    try {
      parsedServiceAccount = JSON.parse(rawServiceAccount);
    } catch (_) {
      parsedServiceAccount = null;
    }
    if (!validServiceAccount(parsedServiceAccount)) {
      await completeDelivery(
        admin,
        notificationId,
        dispatchToken,
        "failed",
        "firebase_configuration_invalid",
      );
      return json({ error: "firebase_configuration_invalid" }, 503);
    }
    const serviceAccount = parsedServiceAccount;

    const title = cleanText(claim.title, 160, "Testified update");
    const body = cleanText(
      claim.body,
      1000,
      "Open Testified to view your latest update.",
    );
    const messageData = pushData(claim, notificationId);
    const accessToken = await firebaseAccessToken(serviceAccount);
    const notificationEventTime = new Date().toISOString();
    let pushed = 0;
    let failed = 0;
    let invalid = 0;

    await Promise.all(devices.map(async (token) => {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body },
              data: messageData,
              android: {
                priority: "high",
                notification: {
                  channel_id: "testified_medical_updates_v2",
                  sound: "default",
                  color: "#2563EB",
                  tag: `testified_${notificationId}`,
                  notification_priority: "PRIORITY_MAX",
                  default_vibrate_timings: true,
                  visibility: "PRIVATE",
                  event_time: notificationEventTime,
                },
              },
              apns: {
                headers: { "apns-priority": "10" },
                payload: {
                  aps: {
                    sound: "default",
                    badge: 1,
                    category: "TESTIFIED_UPDATE",
                  },
                },
              },
            },
          }),
        },
      );
      const responseBody = await response.json().catch(() => ({}));
      if (response.ok) {
        pushed += 1;
        return;
      }

      failed += 1;
      if (isInvalidToken(responseBody)) {
        invalid += 1;
        await admin!.from("push_devices")
          .update({ enabled: false, updated_at: new Date().toISOString() })
          .eq("token", token);
      }
    }));

    if (pushed > 0) {
      await completeDelivery(
        admin,
        notificationId,
        dispatchToken,
        "delivered",
      );
      return json({ state: "delivered", pushed, failed });
    }

    const waitingForDevice = invalid === devices.length;
    await completeDelivery(
      admin,
      notificationId,
      dispatchToken,
      waitingForDevice ? "waiting_for_device" : "failed",
      waitingForDevice ? "all_device_tokens_invalid" : "fcm_delivery_failed",
    );
    return json({
      state: waitingForDevice ? "waiting_for_device" : "failed",
      pushed,
      failed,
    }, 502);
  } catch (error) {
    const errorCode = error instanceof Error
      ? error.message
      : "delivery_failed";
    if (admin && notificationId && dispatchToken) {
      try {
        await completeDelivery(
          admin,
          notificationId,
          dispatchToken,
          "failed",
          errorCode,
        );
      } catch (_) {
        // A retry can reclaim this delivery after its short lock expires.
      }
    }
    console.error("deliver-notification failed", { code: errorCode });
    return json({ error: "notification_delivery_failed" }, 500);
  }
});
