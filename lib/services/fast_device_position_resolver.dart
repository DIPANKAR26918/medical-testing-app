import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

/// Produces a usable map origin quickly, then allows the UI to refine it with a
/// fresher fix without blocking the first frame.
class FastDevicePositionResolver {
  FastDevicePositionResolver({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  final LocationService _locationService;

  Future<bool> ensureLocationReady() async {
    if (!await _locationService.isLocationServiceEnabled()) return false;

    var permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _locationService.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> lastKnown() async {
    if (!await ensureLocationReady()) return null;
    try {
      return await Geolocator.getLastKnownPosition().timeout(
        const Duration(milliseconds: 450),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Position?> fresh({
    Duration budget = const Duration(milliseconds: 2400),
    bool highAccuracy = false,
  }) async {
    if (!await ensureLocationReady()) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy:
              highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
          timeLimit: budget,
        ),
      ).timeout(budget);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Position?> bestEffort({
    Duration budget = const Duration(milliseconds: 2400),
    bool highAccuracy = false,
  }) async {
    final cached = await lastKnown();
    if (cached != null && cached.accuracy <= 350) return cached;

    final live = await fresh(budget: budget, highAccuracy: highAccuracy);
    return live ?? cached;
  }
}
