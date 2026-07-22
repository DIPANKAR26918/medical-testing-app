# Production location system setup

The app's saved-address, GPS, edit/delete/default, order snapshot, and manual
fallback paths work without a map credential. Google map and provider search are
intentionally build-gated so a missing or unrestricted key cannot ship a broken
screen.

## Architecture

1. The device requests Android/iOS location permission only when needed.
2. `google_maps_flutter` provides the visual pin picker. The pin is the precise
   collection point; the editable address is stored separately.
3. The authenticated Supabase Edge Function proxies Places Autocomplete, Place
   Details, and reverse geocoding. The server key never enters the app binary.
4. `collection_addresses` stores user-confirmed text, coordinates, provider
   place ID, pin source, accuracy/distance, validation state, and default state.
5. RLS limits every saved address to its owner. Deletes and fallback-default
   selection are atomic. Provider calls are limited to 120 requests/user/hour.
6. Bookings keep their existing immutable address/coordinate snapshot, so later
   edits do not change an already-created order.

## Google Cloud

Enable billing and only these APIs in a dedicated Google Cloud project:

- Maps SDK for Android
- Maps SDK for iOS
- Places API (New)
- Geocoding API

Create separate credentials:

- Android key: restrict by Android application and APIs. The current package is
  `com.example.medical_diagnostic_app`; replace this placeholder package before
  production and update Firebase at the same time. Add every release SHA-1/SHA-256.
- iOS key: restrict by the final iOS bundle ID and Maps SDK for iOS.
- Server key: restrict to Places API (New) and Geocoding API. Set quotas and a
  billing budget. Do not put this key in Flutter, GitHub, or `google-services.json`.

Google setup and security references:

- https://developers.google.com/maps/flutter-package/config
- https://developers.google.com/maps/api-security-best-practices
- https://developers.google.com/maps/documentation/places/web-service/place-autocomplete

## Local mobile keys

Android:

```text
cp android/local.properties.example android/local.properties
# Then set MAPS_API_KEY in android/local.properties.
```

iOS:

```text
cp ios/Flutter/Maps.example.xcconfig ios/Flutter/Maps.xcconfig
# Then set MAPS_API_KEY in Maps.xcconfig.
```

The real files are ignored by Git.

## Supabase server key

Set the Edge Function secret and deploy the authenticated function:

```text
supabase secrets set GOOGLE_MAPS_SERVER_API_KEY=YOUR_SERVER_RESTRICTED_KEY
supabase functions deploy location-intelligence --verify-jwt
```

Apply the migration in `supabase/migrations/20260723143000_location_intelligence.sql`
before enabling provider search.

## Enable the experience

For a configured development build:

```text
flutter run \
  --dart-define=GOOGLE_MAPS_ENABLED=true \
  --dart-define=GOOGLE_PLACES_ENABLED=true
```

Use the same two compile-time defines in the release build pipeline. Keep
`GOOGLE_PLACES_ENABLED=false` if the Edge Function secret has not been set; map
pin selection will still reverse-geocode through the device plugin and manual
address entry remains available.

## Release checks

- Test allow, deny, and permanently-deny permission states on a physical device.
- Confirm a deleted account cannot see any previous account's location.
- Verify map/search with release signing credentials, not only debug signing.
- Test a pin at the correct entrance, an away-from-device pin, weak GPS, no GPS,
  offline mode, edit/delete/default switching, and booking snapshot integrity.
- Review Google Maps attribution/storage policies before retaining any new
  provider response field. Provider place IDs may be stored; user-confirmed
  address text remains the canonical booking address.
