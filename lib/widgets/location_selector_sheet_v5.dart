import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../config/location_feature_config.dart';
import '../models/location_data.dart';
import '../screens/location_map_picker_screen.dart';
import '../screens/manual_collection_address_screen.dart';
import '../services/location_intelligence_service.dart';
import '../services/location_service.dart';
import '../utils/location_display_formatter.dart';

class LocationSelectorSheet extends StatefulWidget {
  const LocationSelectorSheet({this.currentLocation, super.key});

  final LocationData? currentLocation;

  @override
  State<LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  final _service = LocationService();
  final _intelligence = LocationIntelligenceService();

  List<LocationData> _saved = const [];
  bool _loading = true;
  bool _locating = false;
  bool _selecting = false;
  String? _error;
  Future<bool> Function()? _errorAction;
  String? _errorActionLabel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await _service.loadSavedLocations();
      if (!mounted) return;
      setState(() {
        _saved = values;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Saved address load failed: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _showError('Saved addresses could not be loaded.');
      });
    }
  }

  void _showError(
    String message, {
    Future<bool> Function()? action,
    String? actionLabel,
  }) {
    _error = message;
    _errorAction = action;
    _errorActionLabel = actionLabel;
  }

  void _clearError() {
    _error = null;
    _errorAction = null;
    _errorActionLabel = null;
  }

  Future<void> _useCurrentLocation() async {
    if (_locating || _selecting) return;
    setState(() {
      _locating = true;
      _clearError();
    });

    try {
      if (!await _service.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _showError(
            'Your phone location is turned off.',
            action: _service.openLocationSettings,
            actionLabel: 'Turn on',
          );
        });
        return;
      }

      var permission = await _service.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _service.requestPermission();
      }
      if (!mounted) return;

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locating = false;
          _showError(
            'Location permission is blocked for Testified.',
            action: _service.openAppSettings,
            actionLabel: 'Settings',
          );
        });
        return;
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _locating = false;
          _showError('Allow location access, or enter the address manually.');
        });
        return;
      }

      final position = await _service.resolveDevicePosition(
        LocationSelectionMode.precise,
      );
      if (!mounted) return;
      if (position == null) {
        setState(() {
          _locating = false;
          _showError('We could not get a GPS fix. Move near a window and retry.');
        });
        return;
      }

      final readable = await _readablePosition(position);
      if (!mounted) return;
      setState(() => _locating = false);
      await _openMap(initialLocation: readable);
    } catch (error, stackTrace) {
      debugPrint('Current-location flow failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _locating = false;
        _showError('Location took too long. Retry, or search for a landmark.');
      });
    }
  }

  Future<LocationData> _readablePosition(Position position) async {
    if (_intelligence.isEnabled) {
      try {
        final location = await _intelligence.reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        return location.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          locationSource: 'gps',
          accuracyMeters: position.accuracy,
        );
      } catch (error) {
        debugPrint('Server geocoder fallback: $error');
      }
    }

    try {
      return await _service.reverseGeocodeCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        source: 'gps',
        accuracyMeters: position.accuracy,
      );
    } catch (error) {
      debugPrint('Device geocoder fallback: $error');
      return LocationData(
        type: LocationType.precise,
        label: 'Current location',
        displayAddress: 'Pinned collection point',
        latitude: position.latitude,
        longitude: position.longitude,
        locationSource: 'gps',
        provider: 'device',
        accuracyMeters: position.accuracy,
        validationStatus: 'coordinates_only',
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> _searchAreaOrLandmark() async {
    if (_selecting || _locating) return;
    _clearError();
    if (!LocationFeatureConfig.googleMapsEnabled) {
      setState(() {
        _showError(
          'Google Maps is disabled for this build. Enable the Maps build setting instead of falling back to manual entry.',
        );
      });
      return;
    }
    await _openMap(
      initialLocation: widget.currentLocation?.hasCoordinates == true
          ? widget.currentLocation
          : _saved.where((value) => value.isDefault).firstOrNull,
      focusSearch: true,
    );
  }

  Future<void> _openMap({
    LocationData? initialLocation,
    bool focusSearch = false,
  }) async {
    final pinned = await openLocationMapPicker(
      context,
      initialLocation: initialLocation,
      focusSearch: focusSearch,
    );
    if (!mounted || pinned == null) return;

    final saved = await openManualCollectionAddressScreen(
      context,
      initialLocation: pinned,
    );
    if (!mounted || saved == null) return;
    Navigator.pop(context, saved);
  }

  Future<void> _enterManually() async {
    if (_selecting || _locating) return;
    _clearError();
    final saved = await openManualCollectionAddressScreen(context);
    if (!mounted || saved == null) return;
    Navigator.pop(context, saved);
  }

  Future<void> _selectAddress(LocationData address) async {
    if (_selecting || _locating) return;
    setState(() {
      _selecting = true;
      _clearError();
    });
    try {
      final selected = await _service.selectLocation(address);
      if (!mounted) return;
      Navigator.pop(context, selected);
    } catch (error) {
      debugPrint('Address selection failed: $error');
      if (!mounted) return;
      setState(() {
        _selecting = false;
        _showError('This address could not be activated. Please retry.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: .94,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: _Palette.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _Header(onClose: () => Navigator.pop(context)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  children: [
                    const Text(
                      'How should we find you?',
                      style: TextStyle(
                        color: _Palette.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Choose one method. Search opens the map; manual entry stays completely separate.',
                      style: TextStyle(
                        color: _Palette.text,
                        fontSize: 12.3,
                        height: 1.4,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _ErrorCard(
                        message: _error!,
                        action: _errorAction,
                        actionLabel: _errorActionLabel,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _ActionCard(
                      primary: true,
                      icon: Icons.my_location_rounded,
                      title: _locating
                          ? 'Finding your location…'
                          : 'Use current location',
                      subtitle: 'Pin the exact collection entrance on the map',
                      loading: _locating,
                      onTap: _locating ? null : _useCurrentLocation,
                    ),
                    const SizedBox(height: 11),
                    _ActionCard(
                      icon: Icons.search_rounded,
                      title: 'Search area or landmark',
                      subtitle: 'Search a school, hospital, road, bus stand or PIN',
                      onTap: _searchAreaOrLandmark,
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _enterManually,
                        icon: const Icon(
                          Icons.edit_location_alt_outlined,
                          size: 19,
                        ),
                        label: const Text('Enter address manually'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Saved addresses',
                            style: TextStyle(
                              color: _Palette.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (_saved.isNotEmpty)
                          Text(
                            '${_saved.length} saved',
                            style: const TextStyle(
                              color: _Palette.muted,
                              fontSize: 11.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_loading)
                      const _AddressSkeleton()
                    else if (_saved.isEmpty)
                      const _EmptySavedState()
                    else
                      for (var index = 0; index < _saved.length; index++) ...[
                        _SavedAddressCard(
                          address: _saved[index],
                          active: _saved[index].isDefault ||
                              _saved[index].id == widget.currentLocation?.id,
                          disabled: _selecting,
                          onTap: () => _selectAddress(_saved[index]),
                        ),
                        if (index != _saved.length - 1)
                          const SizedBox(height: 10),
                      ],
                    const SizedBox(height: 18),
                    const _PrivacyNote(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 11),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _Palette.border)),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD7DCE5),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 46),
              const Expanded(
                child: Text(
                  'Collection address',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _Palette.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 46,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool primary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? _Palette.primary : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: primary ? null : Border.all(color: _Palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primary
                      ? Colors.white.withValues(alpha: .16)
                      : _Palette.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Icon(
                        icon,
                        color: primary ? Colors.white : _Palette.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primary ? Colors.white : _Palette.ink,
                        fontSize: 14.6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: primary
                            ? Colors.white.withValues(alpha: .82)
                            : _Palette.text,
                        fontSize: 11.4,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: primary ? Colors.white : _Palette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.address,
    required this.active,
    required this.disabled,
    required this.onTap,
  });

  final LocationData address;
  final bool active;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = address.label.toLowerCase() == 'work'
        ? Icons.work_outline_rounded
        : address.label.toLowerCase() == 'other'
            ? Icons.location_on_outlined
            : Icons.home_outlined;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? _Palette.primary : _Palette.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: active
                      ? _Palette.primarySoft
                      : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: active ? _Palette.primary : _Palette.text,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            address.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _Palette.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 7),
                          const _ActiveBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      locationReadableAddress(address),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _Palette.text,
                        fontSize: 11.8,
                        height: 1.4,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(height: 7),
                      const Text(
                        'Used for new sample collections and report delivery',
                        style: TextStyle(
                          color: _Palette.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: active ? _Palette.primary : _Palette.muted,
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _Palette.primarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Active',
        style: TextStyle(
          color: _Palette.primary,
          fontSize: 9.3,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    this.action,
    this.actionLabel,
  });

  final String message;
  final Future<bool> Function()? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB54708),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A2E0E),
                fontSize: 11.7,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (action != null && actionLabel != null)
            TextButton(onPressed: action, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _AddressSkeleton extends StatelessWidget {
  const _AddressSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF2),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _EmptySavedState extends StatelessWidget {
  const _EmptySavedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.border),
      ),
      child: const Text(
        'No saved address yet. Add one once and it will be ready for future bookings.',
        style: TextStyle(
          color: _Palette.text,
          fontSize: 12,
          height: 1.45,
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, color: _Palette.muted, size: 18),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Your exact pin and phone number stay private and are used only for booking and collection logistics.',
            style: TextStyle(
              color: _Palette.muted,
              fontSize: 11.3,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Palette {
  const _Palette._();

  static const background = Color(0xFFF6F8FC);
  static const primary = Color(0xFF1769E8);
  static const primarySoft = Color(0xFFEDF4FF);
  static const ink = Color(0xFF101828);
  static const text = Color(0xFF475467);
  static const muted = Color(0xFF7C8AA3);
  static const border = Color(0xFFD8DEE8);
}
