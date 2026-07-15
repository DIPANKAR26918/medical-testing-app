import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_data.dart';

class LocationService {
  LocationService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const String _storageKey = 'saved_location_data_v2';
  static const String _legacyStorageKey = 'saved_location_data';

  final SupabaseClient _client;

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

  Future<void> clearSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_storageKey),
      prefs.remove(_legacyStorageKey),
    ]);
  }

  Future<LocationData?> loadSavedLocation({bool syncAccount = true}) async {
    final cached = await _loadCachedLocation();
    if (!syncAccount || _client.auth.currentUser == null) return cached;

    try {
      final addresses = await loadSavedLocations();
      if (addresses.isEmpty) return cached;
      final selected = addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () => addresses.first,
      );
      await _cacheLocation(selected);
      return selected;
    } catch (_) {
      return cached;
    }
  }

  Future<List<LocationData>> loadSavedLocations() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final cached = await _loadCachedLocation();
      return cached == null ? const [] : [cached];
    }

    final response = await _client
        .from('collection_addresses')
        .select()
        .eq('user_id', user.id)
        .order('is_default', ascending: false)
        .order('last_used_at', ascending: false)
        .limit(12);

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

    final payload = location.toDatabaseMap(user.id);
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
            .eq('user_id', user.id)
            .select()
            .single(),
      );
    }

    var saved = LocationData.fromMap(savedRow);
    if (makeDefault) saved = await selectLocation(saved);
    await _cacheLocation(saved);
    return saved;
  }

  Future<LocationData> selectLocation(LocationData location) async {
    final user = _client.auth.currentUser;
    if (user == null || location.id == null) {
      final local = location.copyWith(
        isDefault: true,
        updatedAt: DateTime.now(),
      );
      await _cacheLocation(local);
      return local;
    }

    final response = await _client.rpc(
      'set_default_collection_address',
      params: {'p_address_id': location.id},
    );
    final row = response is Map
        ? Map<String, dynamic>.from(response)
        : response is List && response.isNotEmpty && response.first is Map
        ? Map<String, dynamic>.from(response.first as Map)
        : <String, dynamic>{};

    final selected = row.isEmpty
        ? location.copyWith(isDefault: true, updatedAt: DateTime.now())
        : LocationData.fromMap(row);
    await _cacheLocation(selected);
    return selected;
  }

  Future<LocationData?> resolveLocation(LocationSelectionMode mode) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: mode == LocationSelectionMode.precise
            ? LocationAccuracy.high
            : LocationAccuracy.low,
        timeLimit: const Duration(seconds: 16),
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
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
      latitude: position.latitude,
      longitude: position.longitude,
      serviceabilityStatus: 'unverified',
      updatedAt: DateTime.now(),
    );
  }

  Future<LocationData?> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(_storageKey) ?? prefs.getString(_legacyStorageKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      return LocationData.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheLocation(LocationData location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, location.toJson());
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
