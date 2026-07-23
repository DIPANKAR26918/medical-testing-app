import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/location_feature_config.dart';
import '../models/location_data.dart';
import '../screens/location_map_picker_screen.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _house = TextEditingController();
  final _street = TextEditingController();
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
  bool _form = false;
  bool _more = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _house, _street, _area, _landmark, _city, _state, _pin, _contact, _phone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await _service.loadSavedLocations();
      if (mounted) setState(() { _saved = values; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Saved addresses could not be loaded.'; });
    }
  }

  Future<void> _useCurrent() async {
    if (_locating) return;
    setState(() { _locating = true; _error = null; });
    try {
      final current = await _service.resolveLocation(LocationSelectionMode.precise);
      if (!mounted) return;
      if (current == null) {
        final permission = await _service.checkPermission();
        setState(() {
          _locating = false;
          _error = permission == LocationPermission.deniedForever
              ? 'Location access is blocked. Enable it from app settings.'
              : 'Turn on location or enter the address manually.';
        });
        return;
      }
      var result = current;
      if (LocationFeatureConfig.googleMapsEnabled) {
        final pinned = await openLocationMapPicker(context, initialLocation: current);
        if (!mounted) return;
        if (pinned == null) { setState(() => _locating = false); return; }
        result = pinned;
      }
      _openForm(result);
    } catch (_) {
      if (mounted) setState(() { _locating = false; _error = 'Current location is unavailable. Try again.'; });
    }
  }

  Future<void> _searchMap() async {
    if (!LocationFeatureConfig.googleMapsEnabled) { _openManual(); return; }
    final pinned = await openLocationMapPicker(
      context,
      initialLocation: widget.currentLocation?.hasCoordinates == true
          ? widget.currentLocation
          : null,
      focusSearch: true,
    );
    if (mounted && pinned != null) _openForm(pinned);
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

  void _openForm(LocationData location) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    _draft = location;
    _label = location.label == 'Current location' ? 'Home' : location.label;
    _house.text = stripLocationCodes(location.addressLine1 ?? '');
    _street.text = stripLocationCodes(location.addressLine2 ?? '');
    _area.text = stripLocationCodes(location.locality ?? '');
    _landmark.text = stripLocationCodes(location.landmark ?? '');
    _city.text = stripLocationCodes(location.city ?? '');
    _state.text = stripLocationCodes(location.state ?? '');
    _pin.text = stripLocationCodes(location.postalCode ?? '');
    _contact.text = location.recipientName ??
        metadata['full_name']?.toString().trim() ??
        metadata['name']?.toString().trim() ?? '';
    _phone.text = location.phoneNumber ?? user?.phone ?? '';
    _more = !location.hasCoordinates || _city.text.isEmpty || _state.text.isEmpty;
    setState(() { _form = true; _locating = false; _error = null; });
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final draft = _draft;
    if (draft == null) return;
    setState(() { _saving = true; _error = null; });
    final parts = <String>[
      _house.text.trim(),
      _street.text.trim(),
      if (_house.text.trim().isEmpty) landmarkPhrase(_landmark.text),
      _area.text.trim(),
      if (_house.text.trim().isNotEmpty) landmarkPhrase(_landmark.text),
      _city.text.trim(), _state.text.trim(), _pin.text.trim(),
    ];
    final seen = <String>{};
    final display = parts
        .map(stripLocationCodes)
        .where((value) => value.isNotEmpty && seen.add(value.toLowerCase()))
        .join(', ');
    try {
      final saved = await _service.saveLocation(draft.copyWith(
        type: draft.hasCoordinates ? LocationType.precise : LocationType.manual,
        label: _label,
        displayAddress: display.isEmpty ? locationReadableAddress(draft) : display,
        addressLine1: _house.text.trim(),
        addressLine2: _street.text.trim(),
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
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Address could not be saved. Check the details and retry.'; });
    }
  }

  Future<void> _select(LocationData value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final selected = await _service.selectLocation(value);
      if (mounted) Navigator.pop(context, selected);
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'This address could not be selected.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: .94,
        child: Container(
          decoration: const BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            _Header(
              form: _form,
              onBack: () => setState(() { _form = false; _draft = null; _error = null; }),
              onClose: () => Navigator.pop(context),
            ),
            Expanded(child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _form ? _addressForm() : _picker(),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _picker() => ListView(
    key: const ValueKey('location-picker-v2'),
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
    children: [
      const Text('How should we find you?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _C.ink)),
      const SizedBox(height: 4),
      const Text('Choose one method. We will ask only for details needed by the collector.', style: TextStyle(fontSize: 12.5, height: 1.4, color: _C.text)),
      const SizedBox(height: 16),
      if (_error != null) ...[_Error(message: _error!, settings: _error!.contains('settings') ? _service.openAppSettings : null), const SizedBox(height: 12)],
      _Action(
        primary: true,
        icon: Icons.my_location_rounded,
        title: _locating ? 'Finding your location…' : 'Use current location',
        subtitle: 'Best option — pin the collection entrance',
        loading: _locating,
        onTap: _locating ? null : _useCurrent,
      ),
      const SizedBox(height: 10),
      _Action(
        icon: Icons.search_rounded,
        title: 'Search area or landmark',
        subtitle: 'School, hospital, road, bus stand or PIN',
        onTap: _searchMap,
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
        const SizedBox(height: 10),
        const Text('Saved addresses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _C.ink)),
        const SizedBox(height: 9),
        if (_loading)
          Container(height: 82, decoration: BoxDecoration(color: const Color(0xFFE8ECF2), borderRadius: BorderRadius.circular(17)))
        else
          for (final value in _saved) ...[
            _Saved(value: value, active: value.id == widget.currentLocation?.id || value.isDefault, onTap: () => _select(value)),
            const SizedBox(height: 9),
          ],
      ],
      const SizedBox(height: 16),
      const _Privacy(),
    ],
  );

  Widget _addressForm() => Form(
    key: _formKey,
    child: Column(
      key: const ValueKey('location-form-v2'),
      children: [
        Expanded(child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          children: [
            if (_draft?.hasCoordinates == true) ...[
              _PinPreview(location: _draft!, onChange: _searchMap),
              const SizedBox(height: 17),
            ],
            if (_error != null) ...[_Error(message: _error!), const SizedBox(height: 12)],
            const Text('Save as', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: _C.ink)),
            const SizedBox(height: 8),
            Row(children: ['Home', 'Work', 'Other'].map((value) => Expanded(child: Padding(
              padding: EdgeInsets.only(right: value == 'Other' ? 0 : 8),
              child: ChoiceChip(
                label: SizedBox(width: double.infinity, child: Text(value, textAlign: TextAlign.center)),
                selected: _label == value,
                showCheckmark: false,
                onSelected: (_) => setState(() => _label = value),
              ),
            ))).toList()),
            const SizedBox(height: 20),
            const Text('Collection details', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: _C.ink)),
            const SizedBox(height: 4),
            const Text('No house number? The exact pin plus a nearby landmark is enough.', style: TextStyle(fontSize: 11.8, height: 1.4, color: _C.text)),
            const SizedBox(height: 10),
            _Field(controller: _area, label: 'Area or locality', hint: 'e.g. Pundibari', icon: Icons.location_city_outlined, validator: _required),
            const SizedBox(height: 10),
            _Field(controller: _house, label: 'House, flat or building (optional)', hint: 'Leave blank when there is no formal name', icon: Icons.home_outlined),
            const SizedBox(height: 10),
            _Field(controller: _landmark, label: 'Nearby landmark', hint: 'School, hospital, road or bus stand', icon: Icons.flag_outlined),
            const SizedBox(height: 8),
            const _Hint(),
            const SizedBox(height: 10),
            ExpansionTile(
              initiallyExpanded: _more,
              onExpansionChanged: (value) => _more = value,
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: _C.border)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: _C.border)),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              title: const Text('More address details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
              subtitle: const Text('Street, city, state and PIN', style: TextStyle(fontSize: 10.8)),
              children: [
                _Field(controller: _street, label: 'Street, block or floor (optional)', hint: 'e.g. Main Road, Block C', icon: Icons.apartment_outlined),
                const SizedBox(height: 9),
                Row(children: [
                  Expanded(child: _Field(controller: _city, label: 'City / district', hint: 'City')),
                  const SizedBox(width: 8),
                  Expanded(child: _Field(controller: _state, label: 'State', hint: 'State')),
                ]),
                const SizedBox(height: 9),
                _Field(controller: _pin, label: 'PIN code', hint: '6-digit PIN', icon: Icons.pin_drop_outlined, keyboard: TextInputType.number, validator: _pinValidator),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Collection contact', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: _C.ink)),
            const SizedBox(height: 9),
            _Field(controller: _contact, label: 'Patient or contact name', hint: 'Who should the collector call?', icon: Icons.person_outline_rounded, validator: _required),
            const SizedBox(height: 10),
            _Field(controller: _phone, label: 'Phone number', hint: '10-digit mobile number', icon: Icons.phone_outlined, keyboard: TextInputType.phone, validator: _phoneValidator),
            const SizedBox(height: 7),
            const Text('The collector may call only when the entrance is difficult to identify.', style: TextStyle(fontSize: 11.1, height: 1.35, color: _C.muted)),
          ],
        )),
        SafeArea(top: false, child: Container(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: _C.border))),
          child: SizedBox(width: double.infinity, height: 52, child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: _saving
                ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                : const Text('Save & use this address', style: TextStyle(fontWeight: FontWeight.w900)),
          )),
        )),
      ],
    ),
  );

  String? _required(String? value) => (value ?? '').trim().length < 2 ? 'Required' : null;
  String? _pinValidator(String? value) {
    final clean = (value ?? '').trim();
    return clean.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(clean) ? 'Enter a valid PIN' : null;
  }
  String? _phoneValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length < 10 || digits.length > 12 ? 'Enter a valid mobile number' : null;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.form, required this.onBack, required this.onClose});
  final bool form;
  final VoidCallback onBack;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 9, 8, 11),
    decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: _C.border))),
    child: Column(children: [
      Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD7DCE5), borderRadius: BorderRadius.circular(99))),
      const SizedBox(height: 8),
      Row(children: [
        SizedBox(width: 46, child: form ? IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)) : null),
        Expanded(child: Text(form ? 'Confirm address' : 'Collection address', textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _C.ink))),
        SizedBox(width: 46, child: IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded))),
      ]),
    ]),
  );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.title, required this.subtitle, required this.onTap, this.primary = false, this.loading = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool primary;
  final bool loading;
  @override
  Widget build(BuildContext context) => Material(
    color: primary ? _C.primary : Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: primary ? null : Border.all(color: _C.border)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: primary ? Colors.white.withValues(alpha: .16) : _C.soft, borderRadius: BorderRadius.circular(14)), child: loading ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2)) : Icon(icon, color: primary ? Colors.white : _C.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: primary ? Colors.white : _C.ink)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontSize: 11.3, height: 1.3, color: primary ? Colors.white.withValues(alpha: .82) : _C.text)),
        ])),
        Icon(Icons.chevron_right_rounded, color: primary ? Colors.white : _C.muted),
      ]),
    )),
  );
}

class _Saved extends StatelessWidget {
  const _Saved({required this.value, required this.active, required this.onTap});
  final LocationData value;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(17), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: active ? _C.primary : _C.border, width: active ? 1.3 : 1)),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: active ? _C.soft : const Color(0xFFF2F4F7), borderRadius: BorderRadius.circular(12)), child: Icon(value.label.toLowerCase() == 'work' ? Icons.work_outline_rounded : Icons.home_outlined, color: active ? _C.primary : _C.text, size: 20)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: _C.ink)),
        const SizedBox(height: 4),
        Text(locationReadableAddress(value), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, height: 1.35, color: _C.text)),
      ])),
      const Icon(Icons.chevron_right_rounded, color: _C.muted),
    ]),
  )));
}

class _PinPreview extends StatelessWidget {
  const _PinPreview({required this.location, required this.onChange});
  final LocationData location;
  final VoidCallback onChange;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: _C.soft, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFCADCF9))),
    child: Row(children: [
      const Icon(Icons.location_on_rounded, color: _C.primary),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(locationDisplayTitle(location), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: _C.ink)),
        const SizedBox(height: 3),
        Text(locationReadableAddress(location), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.2, height: 1.35, color: _C.text)),
      ])),
      TextButton(onPressed: onChange, child: const Text('Adjust')),
    ]),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, required this.hint, this.icon, this.validator, this.keyboard});
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboard,
    textCapitalization: TextCapitalization.words,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _C.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _C.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(color: const Color(0xFFF3F7FD), borderRadius: BorderRadius.circular(12)),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.lightbulb_outline_rounded, color: _C.primary, size: 17),
      SizedBox(width: 8),
      Expanded(child: Text('Use a landmark visible from the road. Raw map codes are never shown as your address.', style: TextStyle(fontSize: 11.1, height: 1.38, color: _C.text, fontWeight: FontWeight.w600))),
    ]),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, this.settings});
  final String message;
  final Future<bool> Function()? settings;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFF4E8), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: Color(0xFFB54708), size: 20),
      const SizedBox(width: 9),
      Expanded(child: Text(message, style: const TextStyle(fontSize: 11.7, height: 1.35, color: Color(0xFF7A2E0E), fontWeight: FontWeight.w600))),
      if (settings != null) TextButton(onPressed: settings, child: const Text('Settings')),
    ]),
  );
}

class _Privacy extends StatelessWidget {
  const _Privacy();
  @override
  Widget build(BuildContext context) => const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(Icons.lock_outline_rounded, color: _C.muted, size: 18),
    SizedBox(width: 9),
    Expanded(child: Text('Your exact pin and phone number stay private and are used only for booking and collection logistics.', style: TextStyle(fontSize: 11.3, height: 1.4, color: _C.muted))),
  ]);
}

class _C {
  static const bg = Color(0xFFF6F8FC);
  static const primary = Color(0xFF1769E8);
  static const soft = Color(0xFFEDF4FF);
  static const ink = Color(0xFF101828);
  static const text = Color(0xFF475467);
  static const muted = Color(0xFF7C8AA3);
  static const border = Color(0xFFDDE3EC);
}
