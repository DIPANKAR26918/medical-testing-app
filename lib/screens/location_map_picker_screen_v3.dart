import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/location_feature_config.dart';
import '../models/location_data.dart';
import '../models/location_place_suggestion.dart';
import '../services/fast_device_position_resolver.dart';
import '../services/location_intelligence_service.dart';
import '../services/location_service.dart';
import '../utils/location_display_formatter.dart';

Future<LocationData?> openLocationMapPicker(
  BuildContext context, {
  LocationData? initialLocation,
  bool focusSearch = false,
}) {
  return Navigator.of(context).push<LocationData>(
    MaterialPageRoute<LocationData>(
      builder: (_) => LocationMapPickerScreen(
        initialLocation: initialLocation,
        focusSearch: focusSearch,
      ),
    ),
  );
}

class LocationMapPickerScreen extends StatefulWidget {
  const LocationMapPickerScreen({
    this.initialLocation,
    this.focusSearch = false,
    super.key,
  });

  final LocationData? initialLocation;
  final bool focusSearch;

  @override
  State<LocationMapPickerScreen> createState() =>
      _LocationMapPickerScreenState();
}

class _LocationMapPickerScreenState extends State<LocationMapPickerScreen> {
  static const LatLng _indiaCenter = LatLng(22.9734, 78.6569);
  static const double _summaryInset = 276;
  static const Duration _pinResolveBudget = Duration(milliseconds: 1900);
  static const Duration _cameraIdleDebounce = Duration(milliseconds: 170);

  final _locationService = LocationService();
  final _positionResolver = FastDevicePositionResolver();
  final _intelligence = LocationIntelligenceService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final Map<String, LocationData> _geocodeCache = {};

  GoogleMapController? _mapController;
  Timer? _searchDebounce;
  Timer? _pinResolveDebounce;
  late String _sessionToken;
  late LatLng _target;
  LatLng? _devicePosition;
  LocationData? _draft;
  List<LocationPlaceSuggestion> _suggestions = const [];
  bool _resolving = true;
  bool _searching = false;
  bool _movingToDevice = false;
  bool _programmaticCameraMove = false;
  bool _userMovedMap = false;
  int _resolveGeneration = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sessionToken = _newSessionToken();
    final initial = widget.initialLocation;
    _target = initial?.hasCoordinates == true
        ? LatLng(initial!.latitude!, initial.longitude!)
        : _indiaCenter;
    _draft = initial?.hasCoordinates == true ? initial : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusSearch) _searchFocus.requestFocus();
      unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _pinResolveDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.initialLocation?.hasCoordinates == true) {
      unawaited(_captureFreshDeviceOrigin());
      _schedulePinResolution(immediate: true);
      return;
    }

    final cached = await _positionResolver.lastKnown();
    if (!mounted) return;

    if (cached != null) {
      await _acceptDevicePosition(cached, animate: true, force: true);
      unawaited(_captureFreshDeviceOrigin(refineTarget: true));
      return;
    }

    final fresh = await _positionResolver.fresh();
    if (!mounted) return;
    if (fresh != null) {
      await _acceptDevicePosition(fresh, animate: true, force: true);
      return;
    }

    setState(() {
      _resolving = false;
      _error = 'Search for your area, or turn on location and tap the target button.';
    });
  }

  Future<void> _captureFreshDeviceOrigin({bool refineTarget = false}) async {
    final fresh = await _positionResolver.fresh();
    if (!mounted || fresh == null) return;

    final shouldMoveTarget = refineTarget && !_userMovedMap;
    await _acceptDevicePosition(
      fresh,
      animate: shouldMoveTarget,
      force: shouldMoveTarget,
    );
  }

  Future<void> _acceptDevicePosition(
    Position position, {
    required bool animate,
    required bool force,
  }) async {
    final point = LatLng(position.latitude, position.longitude);
    _devicePosition = point;

    if (!force && _userMovedMap) {
      if (mounted) setState(() {});
      return;
    }

    _target = point;
    _draft = _coordinatesOnlyDraft(point, distance: 0);
    if (mounted) {
      setState(() {
        _resolving = true;
        _error = null;
      });
    }

    if (animate) await _moveCamera(point, zoom: 17.8);
    _schedulePinResolution(immediate: true);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final zoom = _target == _indiaCenter ? 5.2 : 17.8;
    unawaited(_moveCamera(_target, zoom: zoom));
  }

  Future<void> _moveCamera(LatLng point, {required double zoom}) async {
    final controller = _mapController;
    if (controller == null) return;

    _programmaticCameraMove = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point, zoom: zoom),
        ),
        duration: const Duration(milliseconds: 360),
      );
    } finally {
      _programmaticCameraMove = false;
    }
  }

  void _onCameraMoveStarted() {
    _searchFocus.unfocus();
    _pinResolveDebounce?.cancel();
    if (!_programmaticCameraMove) _userMovedMap = true;

    if (mounted) {
      setState(() {
        _resolving = true;
        _error = null;
        _suggestions = const [];
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    _target = position.target;
  }

  void _onCameraIdle() {
    _schedulePinResolution();
  }

  void _schedulePinResolution({bool immediate = false}) {
    _pinResolveDebounce?.cancel();
    if (immediate) {
      unawaited(_resolveTarget());
      return;
    }
    _pinResolveDebounce = Timer(
      _cameraIdleDebounce,
      () => unawaited(_resolveTarget()),
    );
  }

  Future<void> _resolveTarget() async {
    final target = _target;
    final generation = ++_resolveGeneration;
    final distance = _distanceFromDevice(target);
    final cacheKey = _coordinateCacheKey(target);
    final cached = _geocodeCache[cacheKey];

    if (cached != null) {
      if (!mounted || generation != _resolveGeneration) return;
      setState(() {
        _draft = cached.copyWith(
          latitude: target.latitude,
          longitude: target.longitude,
          locationSource: 'map_pin',
          distanceFromDeviceMeters: distance,
        );
        _resolving = false;
        _error = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _draft = _coordinatesOnlyDraft(target, distance: distance);
        _resolving = true;
        _error = null;
      });
    }

    final attempts = <Future<LocationData>>[
      _locationService
          .reverseGeocodeCoordinates(
            latitude: target.latitude,
            longitude: target.longitude,
            distanceFromDeviceMeters: distance,
          )
          .timeout(const Duration(milliseconds: 1750)),
      if (_intelligence.isEnabled)
        _intelligence.reverseGeocode(
          latitude: target.latitude,
          longitude: target.longitude,
        ),
    ];

    try {
      final location = await _firstSuccessful(
        attempts,
        timeout: _pinResolveBudget,
      );
      if (!mounted || generation != _resolveGeneration) return;

      final resolved = location.copyWith(
        latitude: target.latitude,
        longitude: target.longitude,
        locationSource: 'map_pin',
        distanceFromDeviceMeters: distance,
      );
      _geocodeCache[cacheKey] = resolved;
      if (_geocodeCache.length > 80) {
        _geocodeCache.remove(_geocodeCache.keys.first);
      }

      setState(() {
        _draft = resolved;
        _resolving = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || generation != _resolveGeneration) return;
      debugPrint('Fast pin resolution fallback: $error');
      setState(() {
        _draft = _coordinatesOnlyDraft(target, distance: distance);
        _resolving = false;
        _error = null;
      });
    }
  }

  Future<T> _firstSuccessful<T>(
    List<Future<T>> attempts, {
    required Duration timeout,
  }) {
    if (attempts.isEmpty) {
      return Future<T>.error(StateError('No location resolver is available.'));
    }

    final completer = Completer<T>();
    var failures = 0;
    Object? lastError;
    StackTrace? lastStack;

    for (final attempt in attempts) {
      attempt.then((value) {
        if (!completer.isCompleted) completer.complete(value);
      }, onError: (Object error, StackTrace stackTrace) {
        failures += 1;
        lastError = error;
        lastStack = stackTrace;
        if (failures == attempts.length && !completer.isCompleted) {
          completer.completeError(lastError!, lastStack);
        }
      });
    }

    return completer.future.timeout(timeout);
  }

  Future<void> _moveToCurrentLocation() async {
    if (_movingToDevice) return;
    setState(() {
      _movingToDevice = true;
      _error = null;
    });

    final position = await _positionResolver.fresh(
      budget: const Duration(milliseconds: 2500),
      highAccuracy: true,
    );
    final fallback = position ?? await _positionResolver.lastKnown();
    if (!mounted) return;

    if (fallback == null) {
      setState(() {
        _movingToDevice = false;
        _error = 'Location is unavailable. Check GPS permission and try again.';
      });
      return;
    }

    _userMovedMap = false;
    await _acceptDevicePosition(fallback, animate: true, force: true);
    if (mounted) setState(() => _movingToDevice = false);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _suggestions = const [];
        _searching = false;
        _error = null;
      });
      return;
    }

    if (!_intelligence.isEnabled) {
      setState(() {
        _suggestions = const [];
        _searching = false;
        _error = null;
      });
      return;
    }

    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 260), () async {
      try {
        final suggestions = await _intelligence.autocomplete(
          input: query,
          sessionToken: _sessionToken,
          originLatitude: _devicePosition?.latitude ?? _target.latitude,
          originLongitude: _devicePosition?.longitude ?? _target.longitude,
        );
        if (!mounted || _searchController.text.trim() != query) return;
        setState(() {
          _suggestions = suggestions;
          _searching = false;
          _error = suggestions.isEmpty
              ? 'No suggestion found. Press search to locate the typed address.'
              : null;
        });
      } catch (error) {
        if (!mounted || _searchController.text.trim() != query) return;
        setState(() {
          _suggestions = const [];
          _searching = false;
          _error = 'Press search to locate the typed address.';
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    setState(() {
      _suggestions = const [];
      _searching = false;
      _error = null;
    });
  }

  Future<void> _submitSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.length < 2 || _searching) return;

    _searchFocus.unfocus();
    setState(() {
      _searching = true;
      _suggestions = const [];
      _error = null;
    });

    try {
      final results = await geo
          .locationFromAddress(query)
          .timeout(const Duration(milliseconds: 2000));
      if (!mounted || results.isEmpty) {
        throw StateError('No location found');
      }

      final result = results.first;
      await _selectCoordinate(
        LatLng(result.latitude, result.longitude),
        searchLabel: query,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = 'We could not locate that search. Add a nearby road, PIN or landmark.';
      });
    }
  }

  Future<void> _selectSuggestion(LocationPlaceSuggestion suggestion) async {
    _searchFocus.unfocus();
    setState(() {
      _searching = true;
      _suggestions = const [];
      _error = null;
    });

    try {
      LocationData? location;
      if (_intelligence.isEnabled) {
        try {
          location = await _intelligence.placeDetails(
            placeId: suggestion.placeId,
            sessionToken: _sessionToken,
          );
        } catch (_) {
          location = null;
        }
      }

      if (location?.hasCoordinates == true) {
        final point = LatLng(location!.latitude!, location.longitude!);
        final distance = _distanceFromDevice(point);
        _target = point;
        _draft = location.copyWith(
          distanceFromDeviceMeters: distance,
          locationSource: 'search',
        );
        _searchController.text = suggestion.primaryText;
        _userMovedMap = true;
        await _moveCamera(point, zoom: 17.8);
        if (!mounted) return;
        setState(() {
          _searching = false;
          _resolving = false;
        });
        _sessionToken = _newSessionToken();
        return;
      }

      final fallbackQuery = [
        suggestion.primaryText,
        suggestion.secondaryText,
      ].where((value) => value.trim().isNotEmpty).join(', ');
      await _submitSearch(fallbackQuery);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = 'That location could not be opened. Try a nearby landmark.';
      });
    }
  }

  Future<void> _selectCoordinate(
    LatLng point, {
    required String searchLabel,
  }) async {
    _target = point;
    _draft = _coordinatesOnlyDraft(
      point,
      distance: _distanceFromDevice(point),
    );
    _searchController.text = searchLabel;
    _userMovedMap = true;
    await _moveCamera(point, zoom: 17.8);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _resolving = true;
    });
    _schedulePinResolution(immediate: true);
  }

  double? _distanceFromDevice(LatLng target) {
    final device = _devicePosition;
    if (device == null) return null;
    return _locationService.distanceBetween(
      startLatitude: device.latitude,
      startLongitude: device.longitude,
      endLatitude: target.latitude,
      endLongitude: target.longitude,
    );
  }

  Set<Polyline> get _distanceGuide {
    final device = _devicePosition;
    if (device == null) return const {};
    final distance = _distanceFromDevice(_target);
    if (distance == null || distance < 12) return const {};

    return {
      Polyline(
        polylineId: const PolylineId('device-to-pin'),
        points: [device, _target],
        color: _Palette.primary,
        width: 4,
        patterns: [PatternItem.dash(14), PatternItem.gap(10)],
        geodesic: true,
      ),
    };
  }

  LocationData _coordinatesOnlyDraft(LatLng point, {double? distance}) {
    return LocationData(
      type: LocationType.precise,
      displayAddress: 'Pinned collection point',
      latitude: point.latitude,
      longitude: point.longitude,
      locationSource: 'map_pin',
      provider: 'device',
      distanceFromDeviceMeters: distance,
      validationStatus: 'coordinates_only',
      updatedAt: DateTime.now(),
    );
  }

  String _coordinateCacheKey(LatLng point) {
    return '${point.latitude.toStringAsFixed(4)}:'
        '${point.longitude.toStringAsFixed(4)}';
  }

  String _newSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  void _confirmSelection() {
    final draft = _draft;
    if (draft == null) return;
    Navigator.pop(
      context,
      draft.copyWith(
        validationStatus:
            draft.validationStatus == 'coordinates_only' ? 'pin_confirmed' : 'confirmed',
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!LocationFeatureConfig.googleMapsEnabled) {
      return const Scaffold(
        body: Center(child: Text('Google Maps is disabled for this build.')),
      );
    }

    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Choose collection point'),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE4E8EF)),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _target,
                zoom: widget.initialLocation?.hasCoordinates == true ? 17.8 : 5.2,
              ),
              style: _detailRichMapStyle,
              mapType: MapType.normal,
              liteModeEnabled: false,
              minMaxZoomPreference: const MinMaxZoomPreference(14, 20.5),
              onMapCreated: _onMapCreated,
              onCameraMoveStarted: _onCameraMoveStarted,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: _devicePosition != null,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              buildingsEnabled: true,
              indoorViewEnabled: true,
              trafficEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              polylines: _distanceGuide,
              padding: const EdgeInsets.only(bottom: _summaryInset),
            ),
          ),
          Positioned.fill(
            bottom: _summaryInset,
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: _CenterPin(
                    label: _draft?.locality ?? _draft?.city,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 12,
            child: _SearchField(
              controller: _searchController,
              focusNode: _searchFocus,
              searching: _searching,
              onChanged: _onSearchChanged,
              onSubmitted: _submitSearch,
              onClear: _clearSearch,
            ),
          ),
          if (_suggestions.isNotEmpty)
            Positioned(
              left: 14,
              right: 14,
              top: 78,
              child: _SuggestionPanel(
                suggestions: _suggestions,
                onSelected: _selectSuggestion,
              ),
            ),
          Positioned(
            right: 16,
            bottom: _summaryInset + 14,
            child: _RoundButton(
              icon: Icons.my_location_rounded,
              loading: _movingToDevice,
              onTap: _moveToCurrentLocation,
            ),
          ),
          if (_error != null && _suggestions.isEmpty)
            Positioned(
              left: 16,
              right: 76,
              bottom: _summaryInset + 18,
              child: _MapNotice(message: _error!),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _LocationSummary(
              location: _draft,
              resolving: _resolving,
              onConfirm: _draft == null ? null : _confirmSelection,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.searching,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 7,
      shadowColor: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(17),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search area, landmark, street or PIN',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: searching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({required this.suggestions, required this.onSelected});

  final List<LocationPlaceSuggestion> suggestions;
  final ValueChanged<LocationPlaceSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 9,
      shadowColor: Colors.black.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 330),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              onTap: () => onSelected(suggestion),
              leading: const Icon(
                Icons.location_on_outlined,
                color: _Palette.primary,
              ),
              title: Text(
                suggestion.primaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                [
                  if (suggestion.distanceMeters != null)
                    _distanceText(suggestion.distanceMeters!),
                  suggestion.secondaryText,
                ].where((value) => value.isNotEmpty).join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({
    required this.location,
    required this.resolving,
    required this.onConfirm,
  });

  final LocationData? location;
  final bool resolving;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final title = location?.locality?.trim().isNotEmpty == true
        ? location!.locality!
        : location?.city?.trim().isNotEmpty == true
            ? location!.city!
            : 'Pinned collection point';
    final address = location == null
        ? 'Finding the collection point…'
        : locationReadableAddress(location!);
    final distance = location?.distanceFromDeviceMeters;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A101828),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Deliver to',
                    style: TextStyle(
                      color: _Palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (resolving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFD8DEE8)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5FF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: _Palette.primary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _Palette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _Palette.text,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (distance != null && distance >= 20) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: distance > 5000
                      ? const Color(0xFFFFF4E8)
                      : const Color(0xFFFFF1D3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_distanceText(distance)} away from your current location',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7A4B00),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: _Palette.primary,
                  disabledBackgroundColor: const Color(0xFFE1E4E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Add address details',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final readableLabel = stripLocationCodes(label ?? '');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: _Palette.ink,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Text(
            'Place pin at the exact entrance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Icon(
          Icons.location_on_rounded,
          color: _Palette.ink,
          size: 50,
          shadows: [Shadow(color: Colors.white, blurRadius: 4)],
        ),
        if (readableLabel.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _Palette.primary, width: 1.2),
            ),
            child: Text(
              readableLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _Palette.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: .16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: _Palette.primary, size: 27),
          ),
        ),
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x1A101828), blurRadius: 14)],
      ),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _Palette.text,
          fontSize: 10.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _distanceText(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final kilometers = meters / 1000;
  return '${kilometers < 10 ? kilometers.toStringAsFixed(1) : kilometers.round()} km';
}

const String _detailRichMapStyle = '''
[
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#f3f5f7"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry",
    "stylers": [{"visibility": "on"}, {"color": "#e7ebf0"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"visibility": "on"}, {"color": "#c8d2dc"}, {"weight": 1.7}]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry",
    "stylers": [{"visibility": "on"}, {"color": "#b9c7d4"}, {"weight": 1.5}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"visibility": "on"}, {"color": "#f1c86b"}, {"weight": 2.2}]
  },
  {
    "featureType": "road",
    "elementType": "labels",
    "stylers": [{"visibility": "on"}]
  },
  {
    "featureType": "poi",
    "elementType": "all",
    "stylers": [{"visibility": "on"}]
  },
  {
    "featureType": "poi.school",
    "elementType": "all",
    "stylers": [{"visibility": "on"}]
  },
  {
    "featureType": "poi.medical",
    "elementType": "all",
    "stylers": [{"visibility": "on"}]
  },
  {
    "featureType": "transit",
    "elementType": "all",
    "stylers": [{"visibility": "on"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels",
    "stylers": [{"visibility": "on"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#cde7f5"}]
  }
]
''';

class _Palette {
  const _Palette._();

  static const primary = Color(0xFF1769E8);
  static const ink = Color(0xFF101828);
  static const text = Color(0xFF475467);
  static const background = Color(0xFFF6F8FC);
}
