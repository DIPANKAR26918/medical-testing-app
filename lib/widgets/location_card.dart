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
  static const Color _teal = Color(0xFF0E9F8A);
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
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: .04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
      borderRadius: BorderRadius.circular(18),
      onTap: _openLocationSelector,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: .04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .03),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: _teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivering to',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.black.withValues(alpha: .55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: _openLocationSelector,
                    child: Text(
                      'Choose area',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: _deepBlue,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: _deepBlue,
                        decorationThickness: 1.4,
                      ),
                    ),
                  ),
                ],
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
      borderRadius: BorderRadius.circular(18),
      onTap: _openLocationSelector,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: .04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .03),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: _teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivering to',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.black.withValues(alpha: .55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _location.displayAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: _deepBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
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
      borderRadius: BorderRadius.circular(18),
      onTap: _openLocationSelector,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: .04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .03),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _deepBlue.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.home_rounded, size: 20, color: _deepBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _location.displayAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: _deepBlue,
                  fontWeight: FontWeight.w800,
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
