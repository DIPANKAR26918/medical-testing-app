import 'dart:async';

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

  static DateTime? _disabledUntil;
  static const _configurationCooldown = Duration(minutes: 10);

  final SupabaseClient _client;

  bool get isEnabled {
    if (!LocationFeatureConfig.googlePlacesEnabled) return false;
    final disabledUntil = _disabledUntil;
    if (disabledUntil == null) return true;
    if (DateTime.now().isAfter(disabledUntil)) {
      _disabledUntil = null;
      return true;
    }
    return false;
  }

  Future<List<LocationPlaceSuggestion>> autocomplete({
    required String input,
    required String sessionToken,
    double? originLatitude,
    double? originLongitude,
  }) async {
    if (!isEnabled || input.trim().length < 2) return const [];

    final data = await _invoke(
      {
        'action': 'autocomplete',
        'input': input.trim(),
        'session_token': sessionToken,
        'origin_latitude': ?originLatitude,
        'origin_longitude': ?originLongitude,
      },
      timeout: const Duration(milliseconds: 1800),
    );
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
    final data = await _invoke(
      {
        'action': 'place_details',
        'place_id': placeId,
        'session_token': sessionToken,
      },
      timeout: const Duration(milliseconds: 1900),
    );
    return _locationFromResponse(data, source: 'search');
  }

  Future<LocationData> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final data = await _invoke(
      {
        'action': 'reverse_geocode',
        'latitude': latitude,
        'longitude': longitude,
      },
      timeout: const Duration(milliseconds: 1400),
    );
    return _locationFromResponse(data, source: 'map_pin');
  }

  Future<Map<String, dynamic>> _invoke(
    Map<String, dynamic> body, {
    required Duration timeout,
  }) async {
    if (!isEnabled) {
      throw const LocationIntelligenceException(
        'Google location search is cooling down. Try again shortly.',
      );
    }

    try {
      final response = await _client.functions
          .invoke('location-intelligence', body: body)
          .timeout(timeout);
      final rawData = response.data;
      final data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};
      final providerError = data['error']?.toString().trim();

      if (response.status == 503) {
        _tripConfigurationCircuit();
        throw LocationIntelligenceException(
          providerError?.isNotEmpty == true
              ? providerError!
              : 'Google location search is not configured yet.',
        );
      }

      if (response.status < 200 || response.status >= 300) {
        throw LocationIntelligenceException(
          providerError?.isNotEmpty == true
              ? providerError!
              : 'Location search is temporarily unavailable.',
        );
      }

      if (rawData is! Map) {
        throw const LocationIntelligenceException(
          'Location search returned an unreadable response.',
        );
      }

      if (providerError != null && providerError.isNotEmpty) {
        throw LocationIntelligenceException(providerError);
      }
      return data;
    } on TimeoutException {
      throw const LocationIntelligenceException(
        'Location search took too long.',
      );
    } on LocationIntelligenceException {
      rethrow;
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('503') ||
          message.contains('not configured') ||
          message.contains('missing google_maps')) {
        _tripConfigurationCircuit();
      }
      throw const LocationIntelligenceException(
        'Location search is temporarily unavailable.',
      );
    }
  }

  static void _tripConfigurationCircuit() {
    _disabledUntil = DateTime.now().add(_configurationCooldown);
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
