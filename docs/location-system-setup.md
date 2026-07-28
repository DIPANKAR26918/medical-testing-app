# Map-free collection address setup

Testified has two address-entry paths:

1. **Use current location** requests foreground permission after the user taps
   the action, reads one device position, and converts it into a readable area.
2. **Enter address manually** opens the same address form without requesting
   device location.

Both paths finish in the address form so the user can confirm the house,
landmark, PIN, and collection contact before anything is saved. There is no map,
pin picker, place search, Google Maps SDK, or Google Places request in the
client.

## Data flow

1. The app first loads the signed-in user's saved addresses.
2. A current-location request uses `geolocator` only after an explicit tap.
3. `geocoding` converts the device coordinates into editable address fields.
4. The user confirms the address and contact details.
5. `LocationService` saves the address under the current Supabase user ID and
   makes the selected address the default.
6. Bookings retain their existing immutable address and coordinate snapshot, so
   later address edits do not change an existing order.

If GPS or reverse geocoding is unavailable, the user remains in the same flow
and can complete the address manually. Raw coordinates and plus codes are never
used as the visible address.

## Platform permissions

Android keeps foreground-only coarse and fine location permissions in
`android/app/src/main/AndroidManifest.xml`.

iOS keeps `NSLocationWhenInUseUsageDescription` in
`ios/Runner/Info.plist`.

The app does not request background location. No Google Maps API key or
map-specific build configuration is required.

## Supabase contract

- `collection_addresses` remains the source of truth for signed-in users.
- Existing row-level security continues to restrict every address to its owner.
- Default-address selection and deletion continue through the existing RPCs.
- Guest fallback storage and signed-in caches remain account-scoped.
- No database migration is required for the map-free UI.

The historical location migration remains unchanged because existing rows may
still contain old provider metadata. New addresses use `gps` or `manual` as the
location source.

## Release checks

- Verify current-location allow, deny, and permanently-deny states.
- Confirm permission is requested only after tapping **Use current location**.
- Verify manual entry never requests location permission.
- Test GPS timeout and reverse-geocoding failure fallbacks.
- Confirm raw coordinates and plus codes never appear in the UI.
- Confirm saved addresses are scoped to the signed-in account.
- Verify active/default switching and booking address snapshots still work.
- Confirm Android and iOS builds contain no Google Maps SDK or API-key setup.
