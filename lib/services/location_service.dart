import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_data.dart';

class LocationService {
  LocationService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const String _storageKeyPrefix = 'saved_location_data_v3';
  static const String _initialBootstrapKeyPrefix =
      'initial_location_bootstrap_v1';
  static const List<String> _legacyUnscopedStorageKeys = [
    'saved_location_data_v2',
    'saved_location_data',
  ];

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  @visibleForTesting
  static String cacheStorageKeyForUser(String userId) {
    return _scopedKey(_storageKeyPrefix, userId);
  }

  @visibleForTesting
  static String initialBootstrapStorageKeyForUser(String userId) {
    return _scopedKey(_initialBootstrapKeyPrefix, userId);
  }

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<void> clearSavedLocation({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final accountId = userId ?? currentUserId;
    final keys = <String>{
      ..._legacyUnscopedStorageKeys,
      _locationStorageKey(accountId),
      if (accountId != null) _initialBootstrapStorageKey(accountId),
    };

    await Future.wait(keys.map(prefs.remove));
  }

  /// Claims the automatic first-location attempt for the signed-in account.
  ///
  /// The marker is scoped to the Supabase user id, so a newly created account
  /// gets its own permission/location flow without repeatedly prompting an
  /// account that already declined it.
  Future<bool> beginInitialLocationBootstrap() async {
    final userId = currentUserId;
    if (userId == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final key = _initialBootstrapStorageKey(userId);
    if (prefs.getBool(key) ?? false) return false;

    await prefs.setBool(key, true);
    return true;
  }

  Future<LocationData?> loadSavedLocation({bool syncAccount = true}) async {
    final user = _client.auth.currentUser;
    final userId = user?.id;
    final cached = await _loadCachedLocation(userId);

    if (!syncAccount || user == null) return cached;

    try {
      final addresses = await _loadSavedLocationsForUser(userId!);
      if (currentUserId != userId) return null;

      if (addresses.isEmpty) {
        // A successful empty response is authoritative. Never fall back to a
        // location cached by an earlier account on the same device.
        await _removeCachedLocation(userId);
        return null;
      }

      final selected = addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () => addresses.first,
      );
      await _cacheLocation(selected, userId: userId);
      return selected;
    } catch (_) {
      // Offline fallback is safe because the cache itself is user-scoped.
      return currentUserId == userId ? cached : null;
    }
  }

  Future<List<LocationData>> loadSavedLocations() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final cached = await _loadCachedLocation(null);
      return cached == null ? const [] : [cached];
    }

    return _loadSavedLocationsForUser(user.id);
  }

  Future<List<LocationData>> _loadSavedLocationsForUser(String userId) async {
    final response = await _client
        .from('collection_addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('last_used_at', ascending: false)
        .limit(12);

    if (currentUserId != userId) return const [];

    return response
        .whereType<Map>()
        .map((row) => LocationData.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<LocationData> saveLocation(
    LocationData location, {
    bool makeDefault = true,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final local = location.copyWith(
        isDefault: true,
        updatedAt: DateTime.now(),
      );
      await _cacheLocation(local);
      return local;
    }

    final userId = user.id;
    final payload = location.toDatabaseMap(userId);
    late final Map<String, dynamic> savedRow;

    if (location.id == null) {
      savedRow = Map<String, dynamic>.from(
        await _client
            .from('collection_addresses')
            .insert(payload)
            .select()
            .single(),
      );
    } else {
      savedRow = Map<String, dynamic>.from(
        await _client
            .from('collection_addresses')
            .update(payload)
            .eq('id', location.id!)
            .eq('user_id', userId)
            .select()
            .single(),
      );
    }

    _ensureCurrentUser(userId);

    var saved = LocationData.fromMap(savedRow);
    if (makeDefault) {
      saved = await _selectLocationForUser(saved, userId);
    } else if (saved.isDefault) {
      await _cacheLocation(saved, userId: userId);
    }
    return saved;
  }

  Future<LocationData> selectLocation(LocationData location) async {
    final user = _client.auth.currentUser;
    if (user == null || location.id == null) {
      final local = location.copyWith(
        isDefault: true,
        updatedAt: DateTime.now(),
      );
      await _cacheLocation(local, userId: user?.id);
      return local;
    }

    return _selectLocationForUser(location, user.id);
  }

  Future<LocationData?> deleteLocation(LocationData location) async {
    final user = _client.auth.currentUser;
    if (user == null || location.id == null) {
      await clearSavedLocation(userId: user?.id);
      return null;
    }

    final userId = user.id;
    final response = await _client.rpc(
      'delete_collection_address',
      params: {'p_address_id': location.id},
    );
    _ensureCurrentUser(userId);

    final payload = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final rawSelected = payload['selected_address'];
    if (rawSelected is Map) {
      final selected = LocationData.fromMap(
        Map<String, dynamic>.from(rawSelected),
      );
      await _cacheLocation(selected, userId: userId);
      return selected;
    }

    await _removeCachedLocation(userId);
    return null;
  }

  Future<LocationData> _selectLocationForUser(
    LocationData location,
    String userId,
  ) async {
    final response = await _client.rpc(
      'set_default_collection_address',
      params: {'p_address_id': location.id},
    );
    _ensureCurrentUser(userId);

    final row = response is Map
        ? Map<String, dynamic>.from(response)
        : response is List && response.isNotEmpty && response.first is Map
        ? Map<String, dynamic>.from(response.first as Map)
        : <String, dynamic>{};

    final selected = row.isEmpty
        ? location.copyWith(isDefault: true, updatedAt: DateTime.now())
        : LocationData.fromMap(row);
    await _cacheLocation(selected, userId: userId);
    return selected;
  }

  Future<LocationData?> resolveLocation(LocationSelectionMode mode) async {
    final position = await resolveDevicePosition(mode);
    if (position == null) return null;
    return reverseGeocodeCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
      mode: mode,
      source: 'gps',
      accuracyMeters: position.accuracy,
    );
  }

  Future<Position?> resolveDevicePosition(LocationSelectionMode mode) async {
    if (!await isLocationServiceEnabled()) return null;

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: mode == LocationSelectionMode.precise
            ? LocationAccuracy.high
            : LocationAccuracy.low,
        timeLimit: const Duration(seconds: 16),
      ),
    );
  }

  Future<LocationData> reverseGeocodeCoordinates({
    required double latitude,
    required double longitude,
    LocationSelectionMode mode = LocationSelectionMode.precise,
    String source = 'map_pin',
    double? accuracyMeters,
    double? distanceFromDeviceMeters,
  }) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    final place = placemarks.isNotEmpty ? placemarks.first : null;
    final address = mode == LocationSelectionMode.precise
        ? _formatPreciseAddress(place)
        : _formatApproximateAddress(place);

    return LocationData(
      type: mode == LocationSelectionMode.precise
          ? LocationType.precise
          : LocationType.approximate,
      label: 'Current location',
      displayAddress: address,
      addressLine1: _joinNonEmpty([place?.name, place?.street]),
      locality: _clean(place?.subLocality),
      city: _clean(place?.locality),
      state: _clean(place?.administrativeArea),
      postalCode: _clean(place?.postalCode),
      countryCode: _clean(place?.isoCountryCode) ?? 'IN',
      latitude: latitude,
      longitude: longitude,
      locationSource: source,
      provider: 'device',
      accuracyMeters: accuracyMeters,
      distanceFromDeviceMeters: distanceFromDeviceMeters,
      validationStatus: 'geocoded',
      geocodedAt: DateTime.now(),
      serviceabilityStatus: 'unverified',
      updatedAt: DateTime.now(),
    );
  }

  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<LocationData?> _loadCachedLocation(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_locationStorageKey(userId));

    if (userId != null) {
      await Future.wait(_legacyUnscopedStorageKeys.map(prefs.remove));
    }

    if (raw == null || raw.trim().isEmpty) return null;

    try {
      return LocationData.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _removeCachedLocation(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_locationStorageKey(userId));
  }

  Future<void> _cacheLocation(
    LocationData location, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationStorageKey(userId), location.toJson());
  }

  void _ensureCurrentUser(String expectedUserId) {
    if (currentUserId != expectedUserId) {
      throw StateError('The signed-in account changed. Please try again.');
    }
  }

  static String _locationStorageKey(String? userId) {
    return _scopedKey(_storageKeyPrefix, userId);
  }

  static String _initialBootstrapStorageKey(String userId) {
    return _scopedKey(_initialBootstrapKeyPrefix, userId);
  }

  static String _scopedKey(String prefix, String? userId) {
    final value = userId?.trim();
    final scope = value == null || value.isEmpty ? 'guest' : value;
    return '$prefix:$scope';
  }

  String _formatPreciseAddress(Placemark? place) {
    return _joinNonEmpty([
          place?.name,
          place?.street,
          place?.subLocality,
          place?.locality,
          place?.administrativeArea,
          place?.postalCode,
        ]) ??
        'Current location';
  }

  String _formatApproximateAddress(Placemark? place) {
    return _joinNonEmpty([
          place?.subLocality,
          place?.locality,
          place?.administrativeArea,
        ]) ??
        'Current area';
  }

  String? _joinNonEmpty(Iterable<String?> values) {
    final parts = values
        .map(_clean)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    return parts.isEmpty ? null : parts.join(', ');
  }

  String? _clean(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
