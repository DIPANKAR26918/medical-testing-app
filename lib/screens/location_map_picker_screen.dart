import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/location_feature_config.dart';
import '../models/location_data.dart';
import '../models/location_place_suggestion.dart';
import '../services/location_intelligence_service.dart';
import '../services/location_service.dart';

Future<LocationData?> openLocationMapPicker(
  BuildContext context, {
  LocationData? initialLocation,
  bool focusSearch = false,
}) {
  return Navigator.of(context).push<LocationData>(
    PageRouteBuilder<LocationData>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, animation, secondaryAnimation) =>
          LocationMapPickerScreen(
            initialLocation: initialLocation,
            focusSearch: focusSearch,
          ),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(offset), child: child);
      },
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

  final LocationService _locationService = LocationService();
  final LocationIntelligenceService _intelligence =
      LocationIntelligenceService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

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
      await _resolveTarget();
      return;
    }
    await _moveToCurrentLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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
        } catch (_) {
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
    } catch (_) {
      if (!mounted ||
          requestKey != '${_target.latitude}:${_target.longitude}') {
        return;
      }
      setState(() {
        _draft = LocationData(
          type: LocationType.precise,
          displayAddress: 'Pinned location',
          latitude: target.latitude,
          longitude: target.longitude,
          locationSource: 'map_pin',
          distanceFromDeviceMeters: distance,
          updatedAt: DateTime.now(),
        );
        _resolving = false;
        _error = 'Address details were not found. You can add them next.';
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
    } catch (_) {
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
    if (query.length < 3) {
      setState(() {
        _suggestions = const [];
        _searching = false;
      });
      return;
    }
    if (!_intelligence.isEnabled) {
      setState(() {
        _suggestions = const [];
        _searching = false;
        _error =
            'Map search needs the secure Places setup. Move the pin for now.';
      });
      return;
    }

    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 420), () async {
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

  String _newSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Widget build(BuildContext context) {
    if (!LocationFeatureConfig.googleMapsEnabled) {
      return const Scaffold(
        body: Center(child: Text('Map is not enabled for this build.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
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
              padding: const EdgeInsets.only(bottom: 250),
            ),
          ),
          Positioned.fill(
            bottom: 250,
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: const _CenterPin(),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  _RoundMapButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MapSearchField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      searching: _searching,
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_suggestions.isNotEmpty)
            Positioned(
              left: 64,
              right: 14,
              top: MediaQuery.paddingOf(context).top + 72,
              child: _SuggestionPanel(
                suggestions: _suggestions,
                onSelected: _selectSuggestion,
              ),
            ),
          Positioned(
            right: 16,
            bottom: 272,
            child: _RoundMapButton(
              icon: Icons.my_location_rounded,
              loading: _movingToDevice,
              onTap: _moveToCurrentLocation,
            ),
          ),
          if (_error != null && _suggestions.isEmpty)
            Positioned(
              left: 20,
              right: 78,
              bottom: 276,
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

class _MapSearchField extends StatelessWidget {
  const _MapSearchField({
    required this.controller,
    required this.focusNode,
    required this.searching,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(16),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search area, street or PIN code',
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
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .17),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 310),
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
                color: _MapPalette.primary,
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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
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
            const Text(
              'Collection from',
              style: TextStyle(
                color: _MapPalette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: _MapPalette.primary,
                  size: 24,
                ),
                const SizedBox(width: 9),
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
                                color: _MapPalette.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location?.displayAddress ??
                                  'Move the pin to choose an address',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _MapPalette.text,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            if (distance != null && distance >= 100) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: distance > 5000
                      ? const Color(0xFFFFF4E8)
                      : const Color(0xFFFFF9D9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_distanceText(distance)} from your current location',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7A4B00),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: _MapPalette.primary,
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
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: _MapPalette.ink,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Text(
            'Place the pin at the entrance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Icon(
          Icons.location_on_rounded,
          color: _MapPalette.ink,
          size: 48,
          shadows: [Shadow(color: Colors.white, blurRadius: 4)],
        ),
      ],
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({
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
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: .15),
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: _MapPalette.ink),
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
          color: _MapPalette.text,
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

class _MapPalette {
  const _MapPalette._();

  static const primary = Color(0xFF1769E8);
  static const ink = Color(0xFF101828);
  static const text = Color(0xFF475467);
  static const muted = Color(0xFF7C8AA3);
}
