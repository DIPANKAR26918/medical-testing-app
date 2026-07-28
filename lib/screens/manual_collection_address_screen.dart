import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_data.dart';
import '../services/location_service.dart';
import '../utils/location_display_formatter.dart';

Future<LocationData?> openManualCollectionAddressScreen(
  BuildContext context, {
  LocationData? initialLocation,
}) {
  return Navigator.of(context).push<LocationData>(
    MaterialPageRoute<LocationData>(
      builder: (_) => ManualCollectionAddressScreen(
        initialLocation: initialLocation,
      ),
    ),
  );
}

class ManualCollectionAddressScreen extends StatefulWidget {
  const ManualCollectionAddressScreen({this.initialLocation, super.key});

  final LocationData? initialLocation;

  @override
  State<ManualCollectionAddressScreen> createState() =>
      _ManualCollectionAddressScreenState();
}

class _ManualCollectionAddressScreenState
    extends State<ManualCollectionAddressScreen> {
  final _service = LocationService();
  final _formKey = GlobalKey<FormState>();
  final _area = TextEditingController();
  final _house = TextEditingController();
  final _street = TextEditingController();
  final _landmark = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pin = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();

  late LocationData _draft;
  String _label = 'Home';
  bool _showMore = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    _draft = initial ??
        LocationData(
          type: LocationType.manual,
          displayAddress: '',
          locationSource: 'manual',
          provider: 'manual',
          updatedAt: DateTime.now(),
        );
    _label = initial?.label == 'Current location'
        ? 'Home'
        : initial?.label ?? 'Home';
    _hydrate(initial);
  }

  void _hydrate(LocationData? value) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};

    _area.text = stripLocationCodes(value?.locality ?? '');
    _house.text = stripLocationCodes(value?.addressLine1 ?? '');
    _street.text = stripLocationCodes(value?.addressLine2 ?? '');
    _landmark.text = stripLocationCodes(value?.landmark ?? '');
    _city.text = stripLocationCodes(value?.city ?? '');
    _state.text = stripLocationCodes(value?.state ?? '');
    _pin.text = stripLocationCodes(value?.postalCode ?? '');
    _contact.text = value?.recipientName ??
        metadata['full_name']?.toString().trim() ??
        metadata['name']?.toString().trim() ??
        '';
    _phone.text = value?.phoneNumber ?? user?.phone ?? '';
    _showMore = !(_city.text.isNotEmpty &&
        _state.text.isNotEmpty &&
        _pin.text.isNotEmpty);
  }

  @override
  void dispose() {
    for (final controller in [
      _area,
      _house,
      _street,
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

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final house = _house.text.trim();
    final street = _street.text.trim();
    final area = _area.text.trim();
    final landmark = _landmark.text.trim();
    final city = _city.text.trim();
    final state = _state.text.trim();
    final pin = _pin.text.trim();
    final parts = <String>[
      house,
      street,
      if (house.isEmpty) landmarkPhrase(landmark),
      area,
      if (house.isNotEmpty) landmarkPhrase(landmark),
      city,
      state,
      pin,
    ];
    final seen = <String>{};
    final displayAddress = parts
        .map(stripLocationCodes)
        .where((part) =>
            part.isNotEmpty && seen.add(part.toLowerCase()))
        .join(', ');

    try {
      final saved = await _service.saveLocation(
        _draft.copyWith(
          type: _draft.hasCoordinates
              ? LocationType.precise
              : LocationType.manual,
          label: _label,
          displayAddress: displayAddress,
          addressLine1: house,
          addressLine2: street,
          locality: area,
          landmark: landmark,
          city: city,
          state: state,
          postalCode: pin,
          recipientName: _contact.text.trim(),
          phoneNumber: _phone.text.trim(),
          validationStatus:
              _draft.hasCoordinates ? 'confirmed' : 'manual_confirmed',
          updatedAt: DateTime.now(),
        ),
        makeDefault: true,
      );
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      debugPrint('Manual address save failed: $error');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Address could not be saved. Check the details and retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = _draft.hasCoordinates;
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
        title: Text(hasPin ? 'Add address details' : 'Enter address manually'),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _Palette.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  if (hasPin) ...[
                    _PinnedLocationCard(location: _draft),
                    const SizedBox(height: 20),
                  ],
                  const _SectionTitle(
                    title: 'Save as',
                    subtitle: 'Choose a label you will recognise later.',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Home', 'Work', 'Other']
                        .map(
                          (value) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: value == 'Other' ? 0 : 8,
                              ),
                              child: ChoiceChip(
                                label: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    value,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                selected: _label == value,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _label = value),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Collection address',
                    subtitle:
                        'No formal house name? Area plus a road-visible landmark is enough.',
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _area,
                    label: 'Area or locality',
                    hint: 'e.g. Pundibari',
                    icon: Icons.location_city_outlined,
                    validator: _required,
                  ),
                  const SizedBox(height: 11),
                  _Field(
                    controller: _house,
                    label: 'House, flat or building (optional)',
                    hint: 'Leave blank when there is no formal name',
                    icon: Icons.home_outlined,
                  ),
                  const SizedBox(height: 11),
                  _Field(
                    controller: _landmark,
                    label: 'Nearby landmark',
                    hint: 'School, hospital, road or bus stand',
                    icon: Icons.flag_outlined,
                    validator: (value) {
                      if (_house.text.trim().isEmpty &&
                          (value ?? '').trim().length < 2) {
                        return 'Add a house/building or nearby landmark';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const _RoadVisibleHint(),
                  const SizedBox(height: 13),
                  _MoreDetailsCard(
                    expanded: _showMore,
                    onChanged: (value) =>
                        setState(() => _showMore = value),
                    child: Column(
                      children: [
                        _Field(
                          controller: _street,
                          label: 'Street, block or floor (optional)',
                          hint: 'e.g. Main Road, Block C',
                          icon: Icons.apartment_outlined,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Field(
                                controller: _city,
                                label: 'City / district',
                                hint: 'City',
                                validator: _required,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _Field(
                                controller: _state,
                                label: 'State',
                                hint: 'State',
                                validator: _required,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _Field(
                          controller: _pin,
                          label: 'PIN code',
                          hint: '6-digit PIN',
                          icon: Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number,
                          validator: _pinValidator,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Collection contact',
                    subtitle:
                        'Used only if the collector cannot identify the entrance.',
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _contact,
                    label: 'Patient or contact name',
                    hint: 'Who should the collector call?',
                    icon: Icons.person_outline_rounded,
                    validator: _required,
                  ),
                  const SizedBox(height: 11),
                  _Field(
                    controller: _phone,
                    label: 'Phone number',
                    hint: '10-digit mobile number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: _phoneValidator,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorCard(message: _error!),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _Palette.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _Palette.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Text(
                            'Save & use this address',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      (value ?? '').trim().length < 2 ? 'Required' : null;

  String? _pinValidator(String? value) {
    final clean = (value ?? '').trim();
    if (!RegExp(r'^\d{6}$').hasMatch(clean)) {
      return 'Enter a valid 6-digit PIN';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 12) {
      return 'Enter a valid mobile number';
    }
    return null;
  }
}

class _PinnedLocationCard extends StatelessWidget {
  const _PinnedLocationCard({required this.location});

  final LocationData location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBED4FA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded, color: _Palette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exact collection pin selected',
                  style: TextStyle(
                    color: _Palette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locationReadableAddress(location),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _Palette.text,
                    fontSize: 11.7,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _Palette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: _Palette.text,
            fontSize: 11.7,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 21),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _Palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _Palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _Palette.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _RoadVisibleHint extends StatelessWidget {
  const _RoadVisibleHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              color: _Palette.primary, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Use a landmark visible from the road. Raw map codes are never shown as your address.',
              style: TextStyle(
                color: _Palette.text,
                fontSize: 11.4,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreDetailsCard extends StatelessWidget {
  const _MoreDetailsCard({
    required this.expanded,
    required this.onChanged,
    required this.child,
  });

  final bool expanded;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _Palette.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: const Border(),
        collapsedShape: const Border(),
        title: const Text(
          'More address details',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
        ),
        subtitle: const Text(
          'Street, city, state and PIN',
          style: TextStyle(fontSize: 10.8),
        ),
        children: [child],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

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
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFB54708), size: 20),
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
        ],
      ),
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
  static const border = Color(0xFFD8DEE8);
}
