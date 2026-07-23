import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/location_feature_config.dart';
import '../models/location_data.dart';
import '../screens/location_map_picker_screen.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _house = TextEditingController();
  final _area = TextEditingController();
  final _landmark = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pin = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();

  List<LocationData> _saved = const [];
  LocationData? _draft;
  String _label = 'Home';
  bool _loading = true;
  bool _locating = false;
  bool _saving = false;
  bool _showForm = false;
  String? _error;
  Future<bool> Function()? _errorAction;
  String? _errorActionLabel;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    for (final controller in [
      _house,
      _area,
      _landmark,
      _city,
      _state,
      _pin,
      _contact,
      _phone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSaved() async {
    try {
      final addresses = await _service.loadSavedLocations();
      if (!mounted) return;
      setState(() {
        _saved = addresses;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _setError('Saved addresses could not be loaded.');
      });
    }
  }

  void _setError(
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
    if (_locating) return;
    setState(() {
      _locating = true;
      _clearError();
    });

    try {
      final enabled = await _service.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _setError(
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
          _setError(
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
          _setError('Allow location access, or search for your area manually.');
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
          _setError('We could not get a GPS fix. Move near a window and retry.');
        });
        return;
      }

      final current = await _resolveReadableLocation(position);
      if (!mounted) return;

      var selected = current;
      if (LocationFeatureConfig.googleMapsEnabled) {
        final pinned = await openLocationMapPicker(
          context,
          initialLocation: current,
        );
        if (!mounted) return;
        if (pinned == null) {
          setState(() => _locating = false);
          return;
        }
        selected = pinned;
      }
      _openForm(selected);
    } catch (error, stackTrace) {
      debugPrint('Current-location resolution failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _locating = false;
        _setError(
          'Location took too long. Retry, or search for a nearby landmark.',
        );
      });
    }
  }

  Future<LocationData> _resolveReadableLocation(Position position) async {
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
        debugPrint('Server reverse geocoding failed; using device fallback: $error');
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
      debugPrint('Device reverse geocoding failed; keeping exact pin: $error');
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

  Future<void> _searchLocation() async {
    if (!LocationFeatureConfig.googleMapsEnabled) {
      _openManual();
      return;
    }
    final selected = await openLocationMapPicker(
      context,
      initialLocation: widget.currentLocation?.hasCoordinates == true
          ? widget.currentLocation
          : null,
      focusSearch: true,
    );
    if (mounted && selected != null) _openForm(selected);
  }

  void _openManual() {
    _openForm(
      LocationData(
        type: LocationType.manual,
        displayAddress: '',
        locationSource: 'manual',
        provider: 'manual',
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _openForm(LocationData location) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    _draft = location;
    _label = location.label == 'Current location' ? 'Home' : location.label;
    _house.text = stripLocationCodes(location.addressLine1 ?? '');
    _area.text = stripLocationCodes(location.locality ?? '');
    _landmark.text = stripLocationCodes(location.landmark ?? '');
    _city.text = stripLocationCodes(location.city ?? '');
    _state.text = stripLocationCodes(location.state ?? '');
    _pin.text = stripLocationCodes(location.postalCode ?? '');
    _contact.text = location.recipientName ??
        metadata['full_name']?.toString().trim() ??
        metadata['name']?.toString().trim() ??
        '';
    _phone.text = location.phoneNumber ?? user?.phone ?? '';
    setState(() {
      _showForm = true;
      _locating = false;
      _clearError();
    });
  }

  Future<void> _saveAddress() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _saving = true;
      _clearError();
    });

    final parts = [
      _house.text.trim(),
      if (_house.text.trim().isEmpty) landmarkPhrase(_landmark.text),
      _area.text.trim(),
      if (_house.text.trim().isNotEmpty) landmarkPhrase(_landmark.text),
      _city.text.trim(),
      _state.text.trim(),
      _pin.text.trim(),
    ];
    final seen = <String>{};
    final displayAddress = parts
        .map(stripLocationCodes)
        .where((part) => part.isNotEmpty && seen.add(part.toLowerCase()))
        .join(', ');

    try {
      final saved = await _service.saveLocation(
        draft.copyWith(
          type: draft.hasCoordinates
              ? LocationType.precise
              : LocationType.manual,
          label: _label,
          displayAddress: displayAddress.isEmpty
              ? locationReadableAddress(draft)
              : displayAddress,
          addressLine1: _house.text.trim(),
          locality: _area.text.trim(),
          landmark: _landmark.text.trim(),
          city: _city.text.trim(),
          state: _state.text.trim(),
          postalCode: _pin.text.trim(),
          recipientName: _contact.text.trim(),
          phoneNumber: _phone.text.trim(),
          validationStatus: draft.hasCoordinates ? 'confirmed' : 'unverified',
          updatedAt: DateTime.now(),
        ),
      );
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      debugPrint('Saving collection address failed: $error');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _setError('Address could not be saved. Check the details and retry.');
      });
    }
  }

  Future<void> _selectSaved(LocationData address) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final selected = await _service.selectLocation(address);
      if (mounted) Navigator.pop(context, selected);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _setError('This address could not be selected.');
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
            color: Color(0xFFF6F8FC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _Header(
                form: _showForm,
                onBack: () => setState(() {
                  _showForm = false;
                  _draft = null;
                  _clearError();
                }),
                onClose: () => Navigator.pop(context),
              ),
              Expanded(child: _showForm ? _buildForm() : _buildPicker()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPicker() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        const Text(
          'How should we find you?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose one method. We will ask only for details needed by the collector.',
          style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF475467)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _ErrorCard(
            message: _error!,
            action: _errorAction,
            actionLabel: _errorActionLabel,
          ),
        ],
        const SizedBox(height: 14),
        _ActionCard(
          primary: true,
          icon: Icons.my_location_rounded,
          title: _locating ? 'Finding your location…' : 'Use current location',
          subtitle: 'Best option — pin the collection entrance',
          loading: _locating,
          onTap: _locating ? null : _useCurrentLocation,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.search_rounded,
          title: 'Search area or landmark',
          subtitle: 'School, hospital, road, bus stand or PIN',
          onTap: _searchLocation,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _openManual,
            icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
            label: const Text('Enter address manually'),
          ),
        ),
        if (_loading || _saved.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Saved addresses',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 9),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2)
          else
            for (final address in _saved) ...[
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: address.isDefault
                        ? const Color(0xFF1769E8)
                        : const Color(0xFFD8DEE8),
                  ),
                ),
                leading: const Icon(Icons.home_outlined),
                title: Text(
                  address.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  locationReadableAddress(address),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _saving ? null : () => _selectSaved(address),
              ),
              const SizedBox(height: 9),
            ],
        ],
        const SizedBox(height: 16),
        const Text(
          'Your exact pin and phone number stay private and are used only for booking and collection logistics.',
          style: TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF7C8AA3)),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              children: [
                if (_draft?.hasCoordinates == true)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on_rounded),
                      title: const Text('Exact collection pin'),
                      subtitle: Text(locationReadableAddress(_draft!)),
                      trailing: TextButton(
                        onPressed: _searchLocation,
                        child: const Text('Change'),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Home', label: Text('Home')),
                    ButtonSegment(value: 'Work', label: Text('Work')),
                    ButtonSegment(value: 'Other', label: Text('Other')),
                  ],
                  selected: {_label},
                  onSelectionChanged: (value) =>
                      setState(() => _label = value.first),
                ),
                const SizedBox(height: 18),
                _field(_area, 'Area or locality', required: true),
                _field(_house, 'House, flat or building (optional)'),
                _field(_landmark, 'Nearby landmark'),
                _field(_city, 'City / district'),
                _field(_state, 'State'),
                _field(_pin, 'PIN code', keyboard: TextInputType.number),
                const SizedBox(height: 14),
                _field(_contact, 'Patient or contact name', required: true),
                _field(
                  _phone,
                  'Phone number',
                  required: true,
                  keyboard: TextInputType.phone,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorCard(message: _error!),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _saveAddress,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save & use this address'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: TextCapitalization.words,
        validator: required
            ? (value) => (value ?? '').trim().length < 2 ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.form,
    required this.onBack,
    required this.onClose,
  });

  final bool form;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: form
                ? IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back))
                : null,
          ),
          Expanded(
            child: Text(
              form ? 'Confirm address' : 'Collection address',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(
            width: 46,
            child: IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
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
    final foreground = primary ? Colors.white : const Color(0xFF101828);
    return Material(
      color: primary ? const Color(0xFF1769E8) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              loading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Icon(icon, color: foreground, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: primary
                            ? Colors.white.withValues(alpha: .82)
                            : const Color(0xFF475467),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: foreground),
            ],
          ),
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
          const Icon(Icons.info_outline, color: Color(0xFFB54708)),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
          if (action != null)
            TextButton(
              onPressed: () => action!(),
              child: Text(actionLabel ?? 'Open'),
            ),
        ],
      ),
    );
  }
}
