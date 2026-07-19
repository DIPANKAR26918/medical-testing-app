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
  if (!value) throw new Error(`Missing ${name}`);
  return value;
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

    const payload = await request.json().catch(() => null) as
      | Record<string, unknown>
      | null;
    const token = payload?.token?.toString().trim() ?? "";
    const platform = payload?.platform?.toString().trim().toLowerCase() ?? "";
    const appVersion = payload?.app_version?.toString().trim() || null;
    const enabled = typeof payload?.enabled === "boolean"
      ? payload.enabled
      : true;

    if (token.length < 20 || token.length > 4096) {
      return json({ error: "Invalid FCM token" }, 400);
    }

    if (platform !== "android" && platform !== "ios") {
      return json({ error: "Unsupported platform" }, 400);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    if (!enabled) {
      const { error } = await admin
        .from("push_devices")
        .update({ enabled: false, updated_at: new Date().toISOString() })
        .eq("token", token)
        .eq("user_id", user.id);

      if (error) throw error;
      return json({ registered: false });
    }

    const now = new Date().toISOString();
    const { error } = await admin.from("push_devices").upsert(
      {
        user_id: user.id,
        token,
        platform,
        app_version: appVersion,
        enabled: true,
        last_seen_at: now,
        updated_at: now,
      },
      { onConflict: "token" },
    );

    if (error) throw error;
    return json({ registered: true });
  } catch (error) {
    console.error("register-push-device failed", error);
    return json({ error: "Could not register this device" }, 500);
  }
});
