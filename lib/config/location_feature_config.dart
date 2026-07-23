/// Build-time switches for provider-backed location features.
///
/// Testified's Android build already reads the restricted Maps SDK key from
/// `local.properties`, while Places requests go through the authenticated
/// Supabase Edge Function. The features therefore default to on for normal app
/// runs. CI or a deliberately map-free build can still disable either feature
/// with `--dart-define=GOOGLE_MAPS_ENABLED=false` or
/// `--dart-define=GOOGLE_PLACES_ENABLED=false`.
class LocationFeatureConfig {
  const LocationFeatureConfig._();

  static const bool googleMapsEnabled = bool.fromEnvironment(
    'GOOGLE_MAPS_ENABLED',
    defaultValue: true,
  );

  static const bool googlePlacesEnabled = bool.fromEnvironment(
    'GOOGLE_PLACES_ENABLED',
    defaultValue: true,
  );
}
