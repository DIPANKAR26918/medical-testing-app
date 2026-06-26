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
  static const Color _deepBlue = Color(0xFF0F172A);

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
    return Container(
      key: const ValueKey('loading'),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .36)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Checking location...',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _deepBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChooseAreaState() {
    return InkWell(
      key: const ValueKey('none'),
      borderRadius: BorderRadius.circular(12),
      onTap: _openLocationSelector,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .42),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .36)),
        ),
        child: Row(
          children: [
            const Icon(Icons.home_rounded, size: 23, color: _deepBlue),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: _deepBlue,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: 'HOME ',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(text: 'Choose sample collection area'),
                  ],
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApproximateState() {
    return InkWell(
      key: const ValueKey('approximate'),
      borderRadius: BorderRadius.circular(12),
      onTap: _openLocationSelector,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .42),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .36)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 23, color: _deepBlue),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: _deepBlue,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(
                      text: 'HOME ',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(text: _location.displayAddress),
                  ],
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreciseState() {
    return InkWell(
      key: const ValueKey('precise'),
      borderRadius: BorderRadius.circular(12),
      onTap: _openLocationSelector,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .42),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .36)),
        ),
        child: Row(
          children: [
            const Icon(Icons.home_rounded, size: 23, color: _deepBlue),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: _deepBlue,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(
                      text: 'HOME ',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(text: _location.displayAddress),
                  ],
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}
