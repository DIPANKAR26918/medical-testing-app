import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_data.dart';

class LocationService {
  static const String _storageKey = 'saved_location_data';

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
    await prefs.remove(_storageKey);
  }

  Future<void> saveLocation(LocationData location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, location.toJson());
  }

  Future<LocationData?> loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      return LocationData.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<LocationData?> resolveLocation(LocationSelectionMode mode) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: mode == LocationSelectionMode.precise
          ? LocationAccuracy.high
          : LocationAccuracy.low,
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final placemark = placemarks.isNotEmpty ? placemarks.first : null;

    final address = mode == LocationSelectionMode.precise
        ? _formatPreciseAddress(placemark)
        : _formatApproximateAddress(placemark);

    return LocationData(
      type: mode == LocationSelectionMode.precise
          ? LocationType.precise
          : LocationType.approximate,
      displayAddress: address,
      latitude: position.latitude,
      longitude: position.longitude,
      updatedAt: DateTime.now(),
    );
  }

  String _formatPreciseAddress(Placemark? place) {
    if (place == null) return 'Current location';

    final parts = <String>[
      place.name ?? '',
      place.street ?? '',
      place.subLocality ?? '',
      place.locality ?? '',
    ].where((e) => e.trim().isNotEmpty).toList();

    if (parts.isEmpty) {
      return 'Current location';
    }

    return _joinParts(parts);
  }

  String _formatApproximateAddress(Placemark? place) {
    if (place == null) return 'Current area';

    final parts = <String>[
      place.subLocality ?? '',
      place.locality ?? '',
      place.administrativeArea ?? '',
    ].where((e) => e.trim().isNotEmpty).toList();

    if (parts.isEmpty) {
      return 'Current area';
    }

    return _joinParts(parts);
  }

  String _joinParts(List<String> parts) {
    return parts.join(', ');
  }
}
