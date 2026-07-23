import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/location_feature_config.dart';
import '../models/location_data.dart';
import '../models/location_place_suggestion.dart';
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

  final _locationService = LocationService();
  final _intelligence = LocationIntelligenceService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  GoogleMapController? _mapController;
  Timer? _searchDebounce;
  late String _sessionToken;
  late LatLng _target;
  LatLng? _devicePosition;
  LocationData? _draft;
  List<LocationPlaceSuggestion> _suggestions = const [];
  bool _resolving = true;
  bool _searching = false;
  bool _movingToDevice = false;
  bool _preserveSelectedSearchResult = false;
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
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.initialLocation?.hasCoordinates == true) {
      await _captureDevicePosition();
      await _resolveTarget();
      return;
    }
    await _moveToCurrentLocation();
  }

  Future<void> _captureDevicePosition() async {
    try {
      final position = await _locationService.resolveDevicePosition(
        LocationSelectionMode.precise,
      );
      if (!mounted || position == null) return;
      setState(() {
        _devicePosition = LatLng(position.latitude, position.longitude);
      });
    } catch (error) {
      debugPrint('Map distance origin unavailable: $error');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final zoom = _target == _indiaCenter ? 5.2 : 17.2;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _target, zoom: zoom),
      ),
      duration: const Duration(milliseconds: 420),
    );
  }

  void _onCameraMoveStarted() {
    _searchFocus.unfocus();
    setState(() {
      _resolving = true;
      _error = null;
      _suggestions = const [];
    });
  }

  void _onCameraMove(CameraPosition position) {
    _target = position.target;
  }

  Future<void> _onCameraIdle() async {
    if (_preserveSelectedSearchResult) {
      _preserveSelectedSearchResult = false;
      if (mounted) setState(() => _resolving = false);
      return;
    }
    await _resolveTarget();
  }

  Future<void> _resolveTarget() async {
    final target = _target;
    final requestKey = '${target.latitude}:${target.longitude}';
    if (mounted) {
      setState(() {
        _resolving = true;
        _error = null;
      });
    }

    final distance = _distanceFromDevice(target);
    try {
      LocationData location;
      if (_intelligence.isEnabled) {
        try {
          location = await _intelligence.reverseGeocode(
            latitude: target.latitude,
            longitude: target.longitude,
          );
        } catch (error) {
          debugPrint('Server pin reverse geocoder fallback: $error');
          location = await _locationService.reverseGeocodeCoordinates(
            latitude: target.latitude,
            longitude: target.longitude,
            distanceFromDeviceMeters: distance,
          );
        }
      } else {
        location = await _locationService.reverseGeocodeCoordinates(
          latitude: target.latitude,
          longitude: target.longitude,
          distanceFromDeviceMeters: distance,
        );
      }

      if (!mounted ||
          requestKey != '${_target.latitude}:${_target.longitude}') {
        return;
      }
      setState(() {
        _draft = location.copyWith(
          latitude: target.latitude,
          longitude: target.longitude,
          locationSource: 'map_pin',
          distanceFromDeviceMeters: distance,
        );
        _resolving = false;
      });
    } catch (error) {
      debugPrint('Pinned address resolution failed: $error');
      if (!mounted ||
          requestKey != '${_target.latitude}:${_target.longitude}') {
        return;
      }
      setState(() {
        _draft = LocationData(
          type: LocationType.precise,
          displayAddress: 'Pinned collection point',
          latitude: target.latitude,
          longitude: target.longitude,
          locationSource: 'map_pin',
          distanceFromDeviceMeters: distance,
          validationStatus: 'coordinates_only',
          updatedAt: DateTime.now(),
        );
        _resolving = false;
        _error = 'Address text is unavailable, but the exact pin is preserved.';
      });
    }
  }

  Future<void> _moveToCurrentLocation() async {
    if (_movingToDevice) return;
    setState(() {
      _movingToDevice = true;
      _error = null;
    });

    try {
      final position = await _locationService.resolveDevicePosition(
        LocationSelectionMode.precise,
      );
      if (!mounted) return;
      if (position == null) {
        setState(() {
          _movingToDevice = false;
          _resolving = _draft == null;
          _error = 'Turn on location access, or search and move the pin.';
        });
        return;
      }

      final target = LatLng(position.latitude, position.longitude);
      _devicePosition = target;
      _target = target;
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 17.2),
        ),
        duration: const Duration(milliseconds: 520),
      );
      if (!mounted) return;
      setState(() => _movingToDevice = false);
      if (_mapController == null) await _resolveTarget();
    } catch (error) {
      debugPrint('Move to current location failed: $error');
      if (!mounted) return;
      setState(() {
        _movingToDevice = false;
        _resolving = _draft == null;
        _error = 'Current location is unavailable. Search or move the pin.';
      });
    }
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
        _error = 'Location search is not configured for this build.';
      });
      return;
    }

    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 360), () async {
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
          _error = suggestions.isEmpty ? 'No matching location found.' : null;
        });
      } catch (error) {
        if (!mounted || _searchController.text.trim() != query) return;
        setState(() {
          _suggestions = const [];
          _searching = false;
          _error = error.toString();
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

  Future<void> _selectSuggestion(LocationPlaceSuggestion suggestion) async {
    _searchFocus.unfocus();
    setState(() {
      _searching = true;
      _suggestions = const [];
      _error = null;
    });

    try {
      var location = await _intelligence.placeDetails(
        placeId: suggestion.placeId,
        sessionToken: _sessionToken,
      );
      if (!mounted || !location.hasCoordinates) return;

      final target = LatLng(location.latitude!, location.longitude!);
      final distance = _distanceFromDevice(target);
      location = location.copyWith(
        distanceFromDeviceMeters: distance,
        locationSource: 'search',
      );
      _target = target;
      _draft = location;
      _preserveSelectedSearchResult = true;
      _searchController.text = suggestion.primaryText;
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 17.2),
        ),
        duration: const Duration(milliseconds: 520),
      );
      if (!mounted) return;
      setState(() {
        _searching = false;
        _resolving = false;
      });
      _sessionToken = _newSessionToken();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = error.toString();
      });
    }
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
    if (distance == null || distance < 8) return const {};
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

  String _newSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
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
                zoom: widget.initialLocation?.hasCoordinates == true ? 17 : 5,
              ),
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
              onConfirm: _draft == null || _resolving
                  ? null
                  : () => Navigator.pop(
                        context,
                        _draft!.copyWith(
                          validationStatus: 'confirmed',
                          updatedAt: DateTime.now(),
                        ),
                      ),
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
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final ValueChanged<String> onChanged;
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
              color: Color(0x1F101828),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deliver to',
              style: TextStyle(
                color: _Palette.ink,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _Palette.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _Palette.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.share_location_rounded,
                      color: _Palette.primary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: resolving
                        ? const _AddressSkeleton()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _Palette.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                location == null
                                    ? 'Move the pin to choose an address'
                                    : locationReadableAddress(location!),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _Palette.text,
                                  fontSize: 11.8,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            if (distance != null && distance >= 8) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: distance > 5000
                      ? const Color(0xFFFFF4E8)
                      : const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_distanceText(distance)} away from your current location',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7A4B00),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _Palette.primary, width: 1.2),
            ),
            child: Text(
              readableLabel,
              style: const TextStyle(
                color: _Palette.primary,
                fontSize: 10.5,
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
      shadowColor: Colors.black.withValues(alpha: .16),
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: _Palette.primary),
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

class _AddressSkeleton extends StatelessWidget {
  const _AddressSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 130,
          height: 15,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDF3),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          height: 11,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F6),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }
}

String _distanceText(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final kilometers = meters / 1000;
  return '${kilometers < 10 ? kilometers.toStringAsFixed(1) : kilometers.round()} km';
}

class _Palette {
  const _Palette._();

  static const background = Color(0xFFF6F8FC);
  static const primary = Color(0xFF1769E8);
  static const primarySoft = Color(0xFFEDF4FF);
  static const ink = Color(0xFF101828);
  static const text = Color(0xFF475467);
  static const border = Color(0xFFD8DEE8);
}
