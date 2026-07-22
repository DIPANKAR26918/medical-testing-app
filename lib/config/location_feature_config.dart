/// Build-time switches for provider-backed location features.
///
/// Maps and Places stay off unless their restricted credentials are configured.
/// This keeps development, CI, and an accidentally misconfigured release from
/// opening a broken map or sending requests with an unprotected key.
class LocationFeatureConfig {
  const LocationFeatureConfig._();

  static const bool googleMapsEnabled = bool.fromEnvironment(
    'GOOGLE_MAPS_ENABLED',
  );

  static const bool googlePlacesEnabled = bool.fromEnvironment(
    'GOOGLE_PLACES_ENABLED',
  );
}
