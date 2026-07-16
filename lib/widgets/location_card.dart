import 'package:flutter/material.dart';

import '../models/location_data.dart';
import '../services/location_service.dart';
import 'location_selector_sheet.dart';

class LocationCard extends StatefulWidget {
  const LocationCard({this.onChanged, super.key});

  final ValueChanged<LocationData>? onChanged;

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  final LocationService _locationService = LocationService();

  LocationData _location = LocationData.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrapLocation();
  }

  Future<void> _bootstrapLocation() async {
    // Saved addresses load before any GPS permission prompt. This keeps the
    // header useful even when the user denied location access previously.
    final saved = await _locationService.loadSavedLocation();
    if (!mounted) return;
    setState(() {
      _location = saved ?? LocationData.empty;
      _loading = false;
    });
    if (saved != null) widget.onChanged?.call(saved);
  }

  Future<void> _openLocationSelector() async {
    final selected = await showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .38),
      builder: (_) => LocationSelectorSheet(currentLocation: _location),
    );
    if (selected == null || !mounted) return;

    setState(() => _location = selected);
    widget.onChanged?.call(selected);
  }

  String _shortAddress(String value) {
    final parts = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    return parts.isEmpty ? 'Choose collection address' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final title = _loading
        ? 'Loading saved address'
        : _location.isEmpty
        ? 'Choose collection address'
        : _shortAddress(_location.displayAddress);
    final subtitle = _loading
        ? 'Please wait'
        : _location.isEmpty
        ? 'Check slots in your area'
        : '${_location.label} • ${_location.serviceabilityLabel}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _loading ? null : _openLocationSelector,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE7E5)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _loading
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _location.label.toLowerCase() == 'work'
                            ? Icons.work_outline_rounded
                            : Icons.location_on_rounded,
                        color: const Color(0xFF08766C),
                        size: 21,
                      ),
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
                        color: Color(0xFF101828),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 10.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF667085),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
