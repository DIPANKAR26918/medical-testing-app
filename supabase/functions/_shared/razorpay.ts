import {
  createClient,
  type SupabaseClient,
  type User,
} from "npm:@supabase/supabase-js@2.95.0";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-razorpay-signature, x-razorpay-event-id",
};

export type RazorpayCredentials = {
  keyId: string;
  keySecret: string;
};

export class PaymentConfigurationError extends Error {
  constructor(code: string) {
    super(code);
    this.name = "PaymentConfigurationError";
  }
}

export class RazorpayApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly providerCode: string,
  ) {
    super("razorpay_api_error");
    this.name = "RazorpayApiError";
  }
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new PaymentConfigurationError(`missing_${name.toLowerCase()}`);
  }
  return value;
}

function namedSecretKey(name = "default"): string | null {
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (!raw) return null;

  try {
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    const value = parsed[name];
    return typeof value === "string" && value.trim().length > 0
      ? value.trim()
      : null;
  } catch (_) {
    return null;
  }
}

export function createAdminClient(): SupabaseClient {
  const serviceKey = namedSecretKey() ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!serviceKey) {
    throw new PaymentConfigurationError("missing_supabase_secret_key");
  }

  return createClient(requiredEnv("SUPABASE_URL"), serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

export async function authenticateUser(
  request: Request,
  admin: SupabaseClient,
): Promise<User | null> {
  const authorization = request.headers.get("Authorization");
  const token = authorization?.startsWith("Bearer ")
    ? authorization.slice("Bearer ".length).trim()
    : "";
  if (!token) return null;

  const {
    data: { user },
    error,
  } = await admin.auth.getUser(token);
  return error ? null : user;
}

export function razorpayCredentials(): RazorpayCredentials {
  return {
    keyId: requiredEnv("RAZORPAY_KEY_ID"),
    keySecret: requiredEnv("RAZORPAY_KEY_SECRET"),
  };
}

export async function razorpayRequest<T>(
  path: string,
  init: { method?: "GET" | "POST"; body?: Record<string, unknown> } = {},
): Promise<T> {
  const credentials = razorpayCredentials();
  const response = await fetch(`https://api.razorpay.com/v1${path}`, {
    method: init.method ?? "GET",
    headers: {
      Authorization: `Basic ${
        btoa(
          `${credentials.keyId}:${credentials.keySecret}`,
        )
      }`,
      "Content-Type": "application/json",
    },
    body: init.body == null ? undefined : JSON.stringify(init.body),
  });

  const responseBody = await response.json().catch(() => ({})) as Record<
    string,
    unknown
  >;
  if (!response.ok) {
    const providerError = responseBody.error;
    const code = providerError && typeof providerError === "object"
      ? (providerError as Record<string, unknown>).code?.toString()
      : null;
    throw new RazorpayApiError(
      response.status,
      cleanText(code, 120) ?? "unknown_provider_error",
    );
  }

  return responseBody as T;
}

export async function hmacSha256Hex(
  message: string,
  secret: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(message),
  );
  return bytesToHex(new Uint8Array(signature));
}

export async function sha256Hex(message: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(message),
  );
  return bytesToHex(new Uint8Array(digest));
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export function timingSafeHexEqual(left: string, right: string): boolean {
  const normalizedLeft = left.trim().toLowerCase();
  const normalizedRight = right.trim().toLowerCase();
  const maximumLength = Math.max(
    normalizedLeft.length,
    normalizedRight.length,
  );
  let difference = normalizedLeft.length ^ normalizedRight.length;

  for (let index = 0; index < maximumLength; index += 1) {
    difference |= (normalizedLeft.charCodeAt(index) || 0) ^
      (normalizedRight.charCodeAt(index) || 0);
  }
  return difference === 0;
}

export function cleanText(
  value: unknown,
  maximumLength: number,
): string | null {
  const text = typeof value === "string" ? value.trim() : "";
  if (!text) return null;
  return text.slice(0, maximumLength);
}

export function positiveSafeInteger(value: unknown): number | null {
  const parsed = typeof value === "number"
    ? value
    : Number(value?.toString() ?? "");
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : null;
}

export function rupeesToPaise(value: unknown): number | null {
  const raw = value?.toString().trim() ?? "";
  const match = /^(\d+)(?:\.(\d{1,2}))?$/.exec(raw);
  if (!match) return null;

  const rupees = Number(match[1]);
  const paise = Number((match[2] ?? "").padEnd(2, "0"));
  const total = (rupees * 100) + paise;
  return Number.isSafeInteger(total) && total > 0 ? total : null;
}

export function normalizeIndianContact(value: unknown): string | null {
  const digits = value?.toString().replaceAll(/\D/g, "") ?? "";
  if (digits.length === 10) return `+91${digits}`;
  if (digits.length === 12 && digits.startsWith("91")) return `+${digits}`;
  if (digits.length >= 8 && digits.length <= 15) return `+${digits}`;
  return null;
}

export async function readJsonObject(
  request: Request,
): Promise<Record<string, unknown> | null> {
  const value = await request.json().catch(() => null);
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}
