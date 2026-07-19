import { createClient } from "npm:@supabase/supabase-js@2.95.0";

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
  token_uri?: string;
};

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
  if (!value) throw new Error(`Missing ${name}`);
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
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64Url(JSON.stringify({
    iss: account.client_email,
    sub: account.client_email,
    aud: account.token_uri ?? "https://oauth2.googleapis.com/token",
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

  const response = await fetch(
    account.token_uri ?? "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    },
  );
  const body = await response.json();
  if (!response.ok || typeof body.access_token !== "string") {
    throw new Error("Could not authorize Firebase Cloud Messaging");
  }
  return body.access_token;
}

function fcmData(value: unknown): Record<string, string> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return Object.fromEntries(
    Object.entries(value as Record<string, unknown>)
      .slice(0, 40)
      .map(([key, item]) => [
        key,
        typeof item === "string" ? item : JSON.stringify(item) ?? String(item),
      ]),
  );
}

function isInvalidToken(responseBody: unknown): boolean {
  const text = JSON.stringify(responseBody).toUpperCase();
  return text.includes("UNREGISTERED") ||
    text.includes("REGISTRATION_TOKEN_NOT_REGISTERED");
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) {
      return json({ error: "Authentication required" }, 401);
    }

    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const anonKey = requiredEnv("SUPABASE_ANON_KEY");
    const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const userClient = createClient(supabaseUrl, anonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: authorization } },
    });
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return json({ error: "Invalid session" }, 401);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: actor, error: actorError } = await admin
      .from("users")
      .select("role")
      .eq("id", user.id)
      .single();

    if (actorError || !actor || !["agent", "admin"].includes(actor.role)) {
      return json({ error: "Staff access required" }, 403);
    }

    const payload = await request.json().catch(() => null) as
      | Record<string, unknown>
      | null;
    const userId = payload?.user_id?.toString().trim() ?? "";
    const title = payload?.title?.toString().trim() ?? "";
    const body = payload?.body?.toString().trim() ?? "";
    const kind = payload?.kind?.toString().trim().toLowerCase() || "general";
    const orderId = Number(payload?.order_id);
    const data = fcmData(payload?.data);

    if (!userId || title.length < 1 || title.length > 160) {
      return json({ error: "A valid user and title are required" }, 400);
    }
    if (body.length < 1 || body.length > 1000) {
      return json({ error: "Notification body is invalid" }, 400);
    }
    if (!/^[a-z0-9_-]{1,50}$/.test(kind)) {
      return json({ error: "Notification kind is invalid" }, 400);
    }

    if (actor.role === "agent") {
      if (!Number.isSafeInteger(orderId) || orderId < 1) {
        return json({ error: "Agents must provide an assigned order" }, 403);
      }
      const { data: assignedOrder } = await admin
        .from("orders")
        .select("id")
        .eq("id", orderId)
        .eq("user_id", userId)
        .eq("agent_id", user.id)
        .maybeSingle();
      if (!assignedOrder) {
        return json({ error: "This order is not assigned to you" }, 403);
      }
    }

    const { data: notification, error: notificationError } = await admin
      .from("notifications")
      .insert({ user_id: userId, title, body, kind, data })
      .select("id")
      .single();
    if (notificationError) throw notificationError;

    const { data: devices, error: deviceError } = await admin
      .from("push_devices")
      .select("token")
      .eq("user_id", userId)
      .eq("enabled", true);
    if (deviceError) throw deviceError;

    const rawServiceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    if (!rawServiceAccount) {
      return json({
        notification_id: notification.id,
        saved: true,
        pushed: 0,
        reason: "firebase_not_configured",
      }, 202);
    }

    const serviceAccount = JSON.parse(rawServiceAccount) as ServiceAccount;
    if (
      !serviceAccount.client_email ||
      !serviceAccount.private_key ||
      !serviceAccount.project_id
    ) {
      throw new Error("Invalid Firebase service account secret");
    }

    if (!devices?.length) {
      return json({ notification_id: notification.id, saved: true, pushed: 0 });
    }

    const accessToken = await firebaseAccessToken(serviceAccount);
    // FCM is only a wake-up signal. Medical/order details remain inside the
    // authenticated Supabase inbox and never appear in third-party push
    // transport payloads or on a locked device.
    const messageData = {
      notification_id: notification.id,
      route: "/notifications",
    };
    let pushed = 0;
    let failed = 0;

    await Promise.all(devices.map(async ({ token }) => {
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
              notification: {
                title: "Testified",
                body: "A new secure update is ready in your inbox.",
              },
              data: messageData,
              android: {
                priority: "high",
                notification: {
                  channel_id: "testified_updates",
                  sound: "default",
                  color: "#2563EB",
                },
              },
              apns: {
                headers: { "apns-priority": "10" },
                payload: { aps: { sound: "default", badge: 1 } },
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
        await admin
          .from("push_devices")
          .update({ enabled: false, updated_at: new Date().toISOString() })
          .eq("token", token);
      }
    }));

    return json({
      notification_id: notification.id,
      saved: true,
      pushed,
      failed,
    });
  } catch (error) {
    console.error("send-push failed", error);
    return json({ error: "Could not send notification" }, 500);
  }
});
