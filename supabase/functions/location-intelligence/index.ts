import { createClient } from "npm:@supabase/supabase-js@2.95.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type JsonMap = Record<string, unknown>;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing ${name}`);
  return value;
}

function text(value: unknown): string | null {
  const normalized = value?.toString().replace(/\s+/g, " ").trim();
  return normalized ? normalized : null;
}

function number(value: unknown): number | null {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function validCoordinates(latitude: number | null, longitude: number | null) {
  return latitude !== null && longitude !== null && latitude >= -90 &&
    latitude <= 90 && longitude >= -180 && longitude <= 180;
}

const plusCodePattern =
  /\b[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3}\b/gi;

function stripCodes(value: unknown): string | null {
  const clean = text(value)?.replace(plusCodePattern, "").replace(/^\s*,|,\s*$/g, "")
    .replace(/\s+,/g, ",").trim();
  return clean || null;
}

function join(values: Array<string | null>): string | null {
  const result: string[] = [];
  const seen = new Set<string>();
  for (const raw of values) {
    const value = stripCodes(raw);
    if (!value) continue;
    const key = value.toLowerCase();
    if (!seen.has(key)) {
      seen.add(key);
      result.push(value);
    }
  }
  return result.length ? result.join(", ") : null;
}

async function googleJson(
  url: string,
  apiKey: string,
  init: RequestInit = {},
  fieldMask?: string,
): Promise<JsonMap> {
  const response = await fetch(url, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": apiKey,
      ...(fieldMask ? { "X-Goog-FieldMask": fieldMask } : {}),
      ...(init.headers ?? {}),
    },
  });
  const payload = (await response.json().catch(() => ({}))) as JsonMap;
  if (!response.ok) {
    const providerError = payload.error as JsonMap | undefined;
    throw new Error(
      `Google Maps provider error: ${text(providerError?.status) ?? response.status}`,
    );
  }
  return payload;
}

function addressPart(
  components: unknown,
  types: string[],
  short = false,
): string | null {
  if (!Array.isArray(components)) return null;
  for (const raw of components) {
    if (!raw || typeof raw !== "object") continue;
    const component = raw as JsonMap;
    const componentTypes = Array.isArray(component.types)
      ? component.types.map(String)
      : [];
    if (!types.some((type) => componentTypes.includes(type))) continue;
    return stripCodes(
      short
        ? (component.shortText ?? component.short_name)
        : (component.longText ?? component.long_name),
    );
  }
  return null;
}

function relationshipPhrase(value: unknown): string {
  switch (text(value)?.toUpperCase()) {
    case "WITHIN":
      return "Inside";
    case "BESIDE":
      return "Beside";
    case "ACROSS_THE_ROAD":
      return "Opposite";
    case "DOWN_THE_ROAD":
      return "Down the road from";
    case "AROUND_THE_CORNER":
      return "Around the corner from";
    case "BEHIND":
      return "Behind";
    default:
      return "Near";
  }
}

function descriptorCandidate(addressDescriptor: unknown): {
  phrase: string | null;
  name: string | null;
  area: string | null;
} {
  if (!addressDescriptor || typeof addressDescriptor !== "object") {
    return { phrase: null, name: null, area: null };
  }
  const descriptor = addressDescriptor as JsonMap;
  const landmarks = Array.isArray(descriptor.landmarks)
    ? descriptor.landmarks as JsonMap[]
    : [];
  const areas = Array.isArray(descriptor.areas)
    ? descriptor.areas as JsonMap[]
    : [];

  const ranked = landmarks
    .map((landmark) => {
      const name = stripCodes(landmark.display_name ?? landmark.displayName);
      const straight = number(
        landmark.straight_line_distance_meters ?? landmark.straightLineDistanceMeters,
      ) ?? 999999;
      const travel = number(
        landmark.travel_distance_meters ?? landmark.travelDistanceMeters,
      ) ?? straight;
      const spatial = text(landmark.spatial_relationship ?? landmark.spatialRelationship);
      const types = Array.isArray(landmark.types)
        ? landmark.types.map(String)
        : [];
      const usefulType = types.some((type) => [
        "school", "university", "hospital", "pharmacy", "bus_station",
        "train_station", "transit_station", "courthouse", "police",
        "post_office", "bank", "place_of_worship", "park", "shopping_mall",
        "supermarket", "restaurant", "local_government_office",
      ].includes(type));
      return { name, straight, travel, spatial, usefulType };
    })
    .filter((item) => item.name && item.straight <= 1500)
    .sort((a, b) => {
      if (a.usefulType !== b.usefulType) return a.usefulType ? -1 : 1;
      return (a.travel + a.straight) - (b.travel + b.straight);
    });

  const best = ranked[0];
  const area = areas
    .map((raw) => stripCodes(raw.display_name ?? raw.displayName))
    .find((value) => !!value) ?? null;
  return {
    phrase: best?.name ? relationshipPhrase(best.spatial) : null,
    name: best?.name ?? null,
    area,
  };
}

function normalizeAddress({
  formattedAddress,
  components,
  latitude,
  longitude,
  placeId,
  plusCode,
  addressDescriptor,
}: {
  formattedAddress: unknown;
  components: unknown;
  latitude: number;
  longitude: number;
  placeId: unknown;
  plusCode: unknown;
  addressDescriptor?: unknown;
}): JsonMap {
  const premise = addressPart(components, ["premise", "subpremise"]);
  const streetNumber = addressPart(components, ["street_number"]);
  const route = addressPart(components, ["route"]);
  const baseLocality = addressPart(components, [
    "sublocality_level_1", "sublocality", "neighborhood",
  ]);
  const city = addressPart(components, [
    "locality", "postal_town", "administrative_area_level_2",
  ]);
  const state = addressPart(components, ["administrative_area_level_1"]);
  const postalCode = addressPart(components, ["postal_code"]);
  const countryCode = addressPart(components, ["country"], true) ?? "IN";
  const descriptor = descriptorCandidate(addressDescriptor);
  const locality = baseLocality ?? descriptor.area;
  const addressLine1 = join([premise, join([streetNumber, route])]);
  const hasFormalAddress = !!addressLine1;
  const landmark = descriptor.name && descriptor.phrase
    ? `${descriptor.phrase} ${descriptor.name}`
    : descriptor.name;
  const readableFormatted = stripCodes(formattedAddress);
  const displayAddress = hasFormalAddress
    ? join([addressLine1, locality, city, state, postalCode]) ?? readableFormatted
    : join([landmark, locality, city, state, postalCode]) ?? readableFormatted ??
      join([locality, city, state, postalCode]) ?? "Pinned collection point";

  return {
    location_type: "precise",
    display_address: displayAddress,
    address_line1: addressLine1,
    landmark,
    locality,
    city,
    state,
    postal_code: postalCode,
    country_code: countryCode.toUpperCase(),
    latitude,
    longitude,
    provider_place_id: text(placeId),
    plus_code: text(plusCode),
    validation_status: "geocoded",
    serviceability_status: "unverified",
  };
}

async function authenticate(authorization: string) {
  const supabaseUrl = requiredEnv("SUPABASE_URL");
  const anonKey = requiredEnv("SUPABASE_ANON_KEY");
  const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { headers: { Authorization: authorization } },
  });
  const { data: { user }, error } = await userClient.auth.getUser();
  if (error || !user) return null;
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: allowed, error: quotaError } = await admin.rpc(
    "consume_location_intelligence_quota",
    { p_user_id: user.id },
  );
  if (quotaError) throw new Error("Location quota check failed");
  return { user, allowed: allowed === true };
}

async function autocomplete(payload: JsonMap, apiKey: string) {
  const input = text(payload.input);
  const sessionToken = text(payload.session_token);
  if (!input || input.length < 2 || input.length > 180 || !sessionToken) {
    return json({ error: "Enter a more specific place or address." }, 400);
  }
  const latitude = number(payload.origin_latitude);
  const longitude = number(payload.origin_longitude);
  const hasOrigin = validCoordinates(latitude, longitude);
  const requestBody: JsonMap = {
    input,
    sessionToken,
    includedRegionCodes: ["in"],
    languageCode: "en",
    regionCode: "IN",
  };
  if (hasOrigin) {
    const origin = { latitude, longitude };
    requestBody.origin = origin;
    requestBody.locationBias = { circle: { center: origin, radius: 50000 } };
  }
  const result = await googleJson(
    "https://places.googleapis.com/v1/places:autocomplete",
    apiKey,
    { method: "POST", body: JSON.stringify(requestBody) },
    [
      "suggestions.placePrediction.placeId",
      "suggestions.placePrediction.text.text",
      "suggestions.placePrediction.structuredFormat.mainText.text",
      "suggestions.placePrediction.structuredFormat.secondaryText.text",
      "suggestions.placePrediction.distanceMeters",
    ].join(","),
  );
  const suggestions = Array.isArray(result.suggestions)
    ? result.suggestions.flatMap((raw) => {
      const prediction = (raw as JsonMap)?.placePrediction as JsonMap | undefined;
      const placeId = text(prediction?.placeId);
      if (!placeId) return [];
      const structured = prediction?.structuredFormat as JsonMap | undefined;
      const main = structured?.mainText as JsonMap | undefined;
      const secondary = structured?.secondaryText as JsonMap | undefined;
      const fullText = prediction?.text as JsonMap | undefined;
      return [{
        place_id: placeId,
        primary_text: text(main?.text) ?? text(fullText?.text) ?? "Location",
        secondary_text: stripCodes(secondary?.text) ?? "",
        distance_meters: number(prediction?.distanceMeters),
      }];
    })
    : [];
  return json({ suggestions });
}

async function placeDetails(payload: JsonMap, apiKey: string) {
  const placeId = text(payload.place_id);
  const sessionToken = text(payload.session_token);
  if (!placeId || placeId.length > 300 || !sessionToken) {
    return json({ error: "That location could not be opened." }, 400);
  }
  const url = new URL(
    `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}`,
  );
  url.searchParams.set("languageCode", "en");
  url.searchParams.set("regionCode", "IN");
  url.searchParams.set("sessionToken", sessionToken);
  const result = await googleJson(url.toString(), apiKey, {}, [
    "id", "formattedAddress", "shortFormattedAddress", "addressComponents",
    "location", "plusCode",
  ].join(","));
  const location = result.location as JsonMap | undefined;
  const latitude = number(location?.latitude);
  const longitude = number(location?.longitude);
  if (!validCoordinates(latitude, longitude)) {
    return json({ error: "That result has no usable map location." }, 422);
  }
  const plusCode = result.plusCode as JsonMap | undefined;
  return json({
    location: normalizeAddress({
      formattedAddress: result.formattedAddress ?? result.shortFormattedAddress,
      components: result.addressComponents,
      latitude: latitude!,
      longitude: longitude!,
      placeId: result.id ?? placeId,
      plusCode: plusCode?.globalCode ?? plusCode?.compoundCode,
    }),
  });
}

async function reverseGeocode(payload: JsonMap, apiKey: string) {
  const latitude = number(payload.latitude);
  const longitude = number(payload.longitude);
  if (!validCoordinates(latitude, longitude)) {
    return json({ error: "Move the pin to a valid location." }, 400);
  }
  const url = new URL("https://maps.googleapis.com/maps/api/geocode/json");
  url.searchParams.set("latlng", `${latitude},${longitude}`);
  url.searchParams.set("language", "en");
  url.searchParams.set("region", "in");
  url.searchParams.append("extra_computations", "ADDRESS_DESCRIPTORS");
  url.searchParams.set("key", apiKey);
  const response = await fetch(url);
  const result = (await response.json().catch(() => ({}))) as JsonMap;
  if (!response.ok || (result.status !== "OK" && result.status !== "ZERO_RESULTS")) {
    throw new Error(`Google geocoding error: ${text(result.status) ?? "UNKNOWN"}`);
  }
  const first = Array.isArray(result.results)
    ? result.results[0] as JsonMap | undefined
    : undefined;
  if (!first) return json({ error: "No address was found at this pin." }, 422);
  const plusCode = result.plus_code as JsonMap | undefined;
  return json({
    location: normalizeAddress({
      formattedAddress: first.formatted_address,
      components: first.address_components,
      latitude: latitude!,
      longitude: longitude!,
      placeId: first.place_id,
      plusCode: plusCode?.global_code ?? plusCode?.compound_code,
      addressDescriptor: result.address_descriptor,
    }),
  });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) {
      return json({ error: "Authentication required" }, 401);
    }
    const session = await authenticate(authorization);
    if (!session) return json({ error: "Invalid session" }, 401);
    if (!session.allowed) {
      return json({ error: "Too many location searches. Please try again later." }, 429);
    }
    const apiKey = requiredEnv("GOOGLE_MAPS_SERVER_API_KEY");
    const payload = await request.json().catch(() => null) as JsonMap | null;
    const action = text(payload?.action);
    if (!payload || !action) return json({ error: "Invalid request" }, 400);
    if (action === "autocomplete") return await autocomplete(payload, apiKey);
    if (action === "place_details") return await placeDetails(payload, apiKey);
    if (action === "reverse_geocode") return await reverseGeocode(payload, apiKey);
    return json({ error: "Unsupported location action" }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    console.error("location-intelligence failed", message);
    if (message.startsWith("Missing GOOGLE_MAPS_SERVER_API_KEY")) {
      return json({ error: "Location search is not configured yet." }, 503);
    }
    return json({ error: "Location lookup failed. Please try again." }, 502);
  }
});
