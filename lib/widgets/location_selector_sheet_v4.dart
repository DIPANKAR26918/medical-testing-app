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
  final _area = TextEditingController();
  final _house = TextEditingController();
  final _landmark = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pin = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();

  List<LocationData> _saved = const [];
  LocationData? _draft;
  String _label = 'Home';
  String? _error;
  Future<bool> Function()? _errorAction;
  String? _errorActionLabel;
  bool _loading = true;
  bool _locating = false;
  bool _saving = false;
  bool _form = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_area, _house, _landmark, _city, _state, _pin, _contact, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await _service.loadSavedLocations();
      if (!mounted) return;
      setState(() {
        _saved = values;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Saved addresses could not be loaded.';
      });
    }
  }

  void _showError(String message, {Future<bool> Function()? action, String? label}) {
    _error = message;
    _errorAction = action;
    _errorActionLabel = label;
  }

  void _clearError() {
    _error = null;
    _errorAction = null;
    _errorActionLabel = null;
  }

  Future<void> _useCurrent() async {
    if (_locating) return;
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
            label: 'Turn on',
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
            label: 'Settings',
          );
        });
        return;
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _locating = false;
          _showError('Allow location access, or search for your area manually.');
        });
        return;
      }

      final position = await _service.resolveDevicePosition(LocationSelectionMode.precise);
      if (!mounted) return;
      if (position == null) {
        setState(() {
          _locating = false;
          _showError('We could not get a GPS fix. Move near a window and retry.');
        });
        return;
      }

      final current = await _readablePosition(position);
      if (!mounted) return;
      var selected = current;
      if (LocationFeatureConfig.googleMapsEnabled) {
        final pinned = await openLocationMapPicker(context, initialLocation: current);
        if (!mounted) return;
        if (pinned == null) {
          setState(() => _locating = false);
          return;
        }
        selected = pinned;
      }
      _openForm(selected);
    } catch (error, stackTrace) {
      debugPrint('Current location failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _locating = false;
        _showError('Location took too long. Retry, or search for a nearby landmark.');
      });
    }
  }

  Future<LocationData> _readablePosition(Position position) async {
    if (_intelligence.isEnabled) {
      try {
        final value = await _intelligence.reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        return value.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          locationSource: 'gps',
          accuracyMeters: position.accuracy,
        );
      } catch (error) {
        debugPrint('Server reverse geocode fallback: $error');
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
      debugPrint('Device reverse geocode fallback: $error');
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

  Future<void> _search() async {
    if (!LocationFeatureConfig.googleMapsEnabled) {
      _openManual();
      return;
    }
    final value = await openLocationMapPicker(
      context,
      initialLocation: widget.currentLocation?.hasCoordinates == true
          ? widget.currentLocation
          : null,
      focusSearch: true,
    );
    if (mounted && value != null) _openForm(value);
  }

  void _openManual() {
    _openForm(LocationData(
      type: LocationType.manual,
      displayAddress: '',
      locationSource: 'manual',
      provider: 'manual',
      updatedAt: DateTime.now(),
    ));
  }

  void _openForm(LocationData value) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    _draft = value;
    _label = value.label == 'Current location' ? 'Home' : value.label;
    _area.text = stripLocationCodes(value.locality ?? '');
    _house.text = stripLocationCodes(value.addressLine1 ?? '');
    _landmark.text = stripLocationCodes(value.landmark ?? '');
    _city.text = stripLocationCodes(value.city ?? '');
    _state.text = stripLocationCodes(value.state ?? '');
    _pin.text = stripLocationCodes(value.postalCode ?? '');
    _contact.text = value.recipientName ??
        metadata['full_name']?.toString().trim() ??
        metadata['name']?.toString().trim() ??
        '';
    _phone.text = value.phoneNumber ?? user?.phone ?? '';
    setState(() {
      _form = true;
      _locating = false;
      _clearError();
    });
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final draft = _draft;
    if (draft == null) return;
    setState(() => _saving = true);

    final parts = [
      _house.text.trim(),
      if (_house.text.trim().isEmpty) landmarkPhrase(_landmark.text),
      _area.text.trim(),
      _city.text.trim(),
      _state.text.trim(),
      _pin.text.trim(),
    ];
    final seen = <String>{};
    final display = parts
        .map(stripLocationCodes)
        .where((v) => v.isNotEmpty && seen.add(v.toLowerCase()))
        .join(', ');

    try {
      final saved = await _service.saveLocation(draft.copyWith(
        type: draft.hasCoordinates ? LocationType.precise : LocationType.manual,
        label: _label,
        displayAddress: display.isEmpty ? locationReadableAddress(draft) : display,
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
      ));
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      debugPrint('Address save failed: $error');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _showError('Address could not be saved. Check the details and retry.');
      });
    }
  }

  Future<void> _select(LocationData value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final selected = await _service.selectLocation(value);
      if (mounted) Navigator.pop(context, selected);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _showError('This address could not be selected.');
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
          child: Column(children: [
            _header(),
            Expanded(child: _form ? _formView() : _picker()),
          ]),
        ),
      ),
    );
  }

  Widget _header() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
    child: Row(children: [
      SizedBox(
        width: 46,
        child: _form
            ? IconButton(
                onPressed: () => setState(() {
                  _form = false;
                  _draft = null;
                  _clearError();
                }),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
      ),
      Expanded(
        child: Text(
          _form ? 'Confirm address' : 'Collection address',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
      ),
      SizedBox(
        width: 46,
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    ]),
  );

  Widget _picker() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
    children: [
      const Text('How should we find you?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      const Text(
        'Choose one method. We will ask only for details needed by the collector.',
        style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF475467)),
      ),
      if (_error != null) ...[
        const SizedBox(height: 14),
        _errorCard(),
      ],
      const SizedBox(height: 14),
      _action(
        primary: true,
        icon: Icons.my_location_rounded,
        title: _locating ? 'Finding your location…' : 'Use current location',
        subtitle: 'Best option — pin the collection entrance',
        onTap: _locating ? null : _useCurrent,
      ),
      const SizedBox(height: 10),
      _action(
        icon: Icons.search_rounded,
        title: 'Search area or landmark',
        subtitle: 'School, hospital, road, bus stand or PIN',
        onTap: _search,
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
        const Text('Saved addresses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 9),
        if (_loading)
          const LinearProgressIndicator(minHeight: 2)
        else
          for (final value in _saved) ...[
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: value.isDefault ? const Color(0xFF1769E8) : const Color(0xFFD8DEE8),
                ),
              ),
              leading: const Icon(Icons.home_outlined),
              title: Text(value.label, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(locationReadableAddress(value), maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _saving ? null : () => _select(value),
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

  Widget _formView() => Form(
    key: _formKey,
    child: Column(children: [
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
                  trailing: TextButton(onPressed: _search, child: const Text('Change')),
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
              onSelectionChanged: (value) => setState(() => _label = value.first),
            ),
            const SizedBox(height: 18),
            _field(_area, 'Area or locality', isRequired: true),
            _field(_house, 'House, flat or building (optional)'),
            _field(_landmark, 'Nearby landmark'),
            _field(_city, 'City / district'),
            _field(_state, 'State'),
            _field(_pin, 'PIN code', keyboard: TextInputType.number),
            const SizedBox(height: 14),
            _field(_contact, 'Patient or contact name', isRequired: true),
            _field(_phone, 'Phone number', isRequired: true, keyboard: TextInputType.phone),
            if (_error != null) ...[const SizedBox(height: 8), _errorCard()],
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
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save & use this address'),
            ),
          ),
        ),
      ),
    ]),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: TextCapitalization.words,
      validator: isRequired
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

  Widget _action({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool primary = false,
  }) {
    final fg = primary ? Colors.white : const Color(0xFF101828);
    return Material(
      color: primary ? const Color(0xFF1769E8) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            if (_locating && primary)
              const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            else
              Icon(icon, color: fg, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: primary ? Colors.white.withValues(alpha: .82) : const Color(0xFF475467),
                    fontSize: 11.5,
                  ),
                ),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: fg),
          ]),
        ),
      ),
    );
  }

  Widget _errorCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E8),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline, color: Color(0xFFB54708)),
      const SizedBox(width: 9),
      Expanded(child: Text(_error!)),
      if (_errorAction != null)
        TextButton(
          onPressed: () => _errorAction!(),
          child: Text(_errorActionLabel ?? 'Open'),
        ),
    ]),
  );
}
