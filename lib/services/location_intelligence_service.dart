import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/location_feature_config.dart';
import '../models/location_data.dart';
import '../models/location_place_suggestion.dart';

class LocationIntelligenceException implements Exception {
  const LocationIntelligenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationIntelligenceService {
  LocationIntelligenceService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  bool get isEnabled => LocationFeatureConfig.googlePlacesEnabled;

  Future<List<LocationPlaceSuggestion>> autocomplete({
    required String input,
    required String sessionToken,
    double? originLatitude,
    double? originLongitude,
  }) async {
    if (!isEnabled || input.trim().length < 2) return const [];

    final data = await _invoke({
      'action': 'autocomplete',
      'input': input.trim(),
      'session_token': sessionToken,
      'origin_latitude': ?originLatitude,
      'origin_longitude': ?originLongitude,
    });
    final rawSuggestions = data['suggestions'];
    if (rawSuggestions is! List) return const [];

    return rawSuggestions
        .whereType<Map>()
        .map(
          (item) =>
              LocationPlaceSuggestion.fromMap(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.placeId.isNotEmpty && item.primaryText.isNotEmpty)
        .toList(growable: false);
  }

  Future<LocationData> placeDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    final data = await _invoke({
      'action': 'place_details',
      'place_id': placeId,
      'session_token': sessionToken,
    });
    return _locationFromResponse(data, source: 'search');
  }

  Future<LocationData> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final data = await _invoke({
      'action': 'reverse_geocode',
      'latitude': latitude,
      'longitude': longitude,
    });
    return _locationFromResponse(data, source: 'map_pin');
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    if (!isEnabled) {
      throw const LocationIntelligenceException(
        'Location search is not configured for this build.',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'location-intelligence',
        body: body,
      );
      final data = response.data;
      if (response.status < 200 || response.status >= 300 || data is! Map) {
        throw const LocationIntelligenceException(
          'Location search is temporarily unavailable.',
        );
      }
      final result = Map<String, dynamic>.from(data);
      final error = result['error']?.toString().trim();
      if (error != null && error.isNotEmpty) {
        throw LocationIntelligenceException(error);
      }
      return result;
    } on LocationIntelligenceException {
      rethrow;
    } catch (_) {
      throw const LocationIntelligenceException(
        'Location search is temporarily unavailable.',
      );
    }
  }

  LocationData _locationFromResponse(
    Map<String, dynamic> data, {
    required String source,
  }) {
    final rawLocation = data['location'];
    if (rawLocation is! Map) {
      throw const LocationIntelligenceException(
        'We could not read that location. Try moving the pin.',
      );
    }
    return LocationData.fromMap({
      ...Map<String, dynamic>.from(rawLocation),
      'type': 'precise',
      'location_source': source,
      'provider': 'google',
      'geocoded_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
