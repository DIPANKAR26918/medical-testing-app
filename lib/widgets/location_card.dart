import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_data.dart';
import '../services/location_service.dart';
import 'location_selector_sheet.dart';

class LocationCard extends StatefulWidget {
  const LocationCard({super.key});

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  static const Color _ink = Color(0xFF101828);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _primary = Color(0xFF1D4ED8);
  static const Color _primarySoft = Color(0xFFEFF6FF);

  final LocationService _locationService = LocationService();

  LocationData _location = LocationData.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrapLocation();
  }

  Future<void> _bootstrapLocation() async {
    final permission = await _locationService.checkPermission();

    if (!mounted) return;

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _location = LocationData.empty;
        _loading = false;
      });
      return;
    }

    final savedLocation = await _locationService.loadSavedLocation();

    if (!mounted) return;

    setState(() {
      _location = savedLocation ?? LocationData.empty;
      _loading = false;
    });
  }

  Future<void> _openLocationSelector() async {
    final mode = await showModalBottomSheet<LocationSelectionMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationSelectorSheet(),
    );

    if (mode == null) return;

    final selectedLocation = await _locationService.resolveLocation(mode);

    if (!mounted) return;

    if (selectedLocation == null) {
      final permission = await _locationService.checkPermission();

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      if (permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Location permission is permanently denied. Open app settings to enable it.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                _locationService.openAppSettings();
              },
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Location could not be fetched. Please try again.'),
          ),
        );
      }
      return;
    }

    await _locationService.saveLocation(selectedLocation);

    if (!mounted) return;

    setState(() {
      _location = selectedLocation;
    });
  }

  String _shortAddress(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return 'Choose pickup area';

    final parts = cleaned
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0]}, ${parts[1]}';
    }

    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _loading
          ? _buildLoadingState()
          : _location.isEmpty
          ? _buildChooseAreaState()
          : _location.isPrecise
          ? _buildPreciseState()
          : _buildApproximateState(),
    );
  }

  Widget _buildLoadingState() {
    return _LocationShell(
      key: const ValueKey('loading'),
      icon: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(color: _primary, strokeWidth: 2),
      ),
      title: 'Checking location',
      subtitle: 'For sample collection',
      onTap: null,
    );
  }

  Widget _buildChooseAreaState() {
    return _LocationShell(
      key: const ValueKey('none'),
      icon: const Icon(Icons.home_rounded, color: _primary, size: 22),
      title: 'Choose pickup area',
      subtitle: 'For sample collection',
      onTap: _openLocationSelector,
    );
  }

  Widget _buildApproximateState() {
    return _LocationShell(
      key: const ValueKey('approximate'),
      icon: const Icon(Icons.location_on_rounded, color: _primary, size: 22),
      title: _shortAddress(_location.displayAddress),
      subtitle: 'Pickup area',
      onTap: _openLocationSelector,
    );
  }

  Widget _buildPreciseState() {
    return _LocationShell(
      key: const ValueKey('precise'),
      icon: const Icon(Icons.home_rounded, color: _primary, size: 22),
      title: _shortAddress(_location.displayAddress),
      subtitle: 'Home sample collection',
      onTap: _openLocationSelector,
    );
  }
}

class _LocationShell extends StatelessWidget {
  const _LocationShell({
    required super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _LocationCardState._border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _LocationCardState._primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: icon,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _LocationCardState._ink,
                        fontSize: 13.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _LocationCardState._muted,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _LocationCardState._muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
