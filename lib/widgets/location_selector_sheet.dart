import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_data.dart';
import '../services/location_service.dart';

class LocationSelectorSheet extends StatefulWidget {
  const LocationSelectorSheet({this.currentLocation, super.key});

  final LocationData? currentLocation;

  @override
  State<LocationSelectorSheet> createState() =>
      _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  final LocationService _locationService = LocationService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _addressLineController =
      TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  List<LocationData> _addresses = const [];
  bool _loading = true;
  bool _locating = false;
  bool _saving = false;
  bool _showAddressForm = false;
  String _label = 'Home';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await _locationService.loadSavedLocations();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Saved addresses could not be loaded.';
        _loading = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _error = null;
    });

    try {
      final resolved = await _locationService.resolveLocation(
        LocationSelectionMode.precise,
      );
      if (!mounted) return;

      if (resolved == null) {
        final permission = await _locationService.checkPermission();
        if (!mounted) return;
        setState(() {
          _locating = false;
          _error = permission == LocationPermission.deniedForever
              ? 'Location access is blocked. Enable it from app settings.'
              : 'Could not detect your location. Add an address manually.';
        });
        return;
      }

      final saved = await _locationService.saveLocation(resolved);
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _error = 'Location could not be saved. Please try again.';
      });
    }
  }

  Future<void> _selectAddress(LocationData address) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final selected = await _locationService.selectLocation(address);
      if (!mounted) return;
      Navigator.pop(context, selected);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'This address could not be selected.';
      });
    }
  }

  Future<void> _saveManualAddress() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final parts = <String>[
      _addressLineController.text.trim(),
      _areaController.text.trim(),
      _cityController.text.trim(),
      _stateController.text.trim(),
      _postalController.text.trim(),
    ].where((item) => item.isNotEmpty).toList(growable: false);

    try {
      final saved = await _locationService.saveLocation(
        LocationData(
          type: LocationType.manual,
          label: _label,
          displayAddress: parts.join(', '),
          addressLine1: _addressLineController.text.trim(),
          locality: _areaController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalController.text.trim(),
          landmark: _landmarkController.text.trim(),
          updatedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Address could not be saved. Check the details and retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: .91,
        child: Container(
          decoration: const BoxDecoration(
            color: _LocationPalette.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _SheetHeader(onClose: () => Navigator.pop(context)),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _showAddressForm
                      ? _buildAddressForm()
                      : _buildAddressPicker(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressPicker() {
    return ListView(
      key: const ValueKey('address-picker'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        if (_error != null) ...[
          _LocationError(
            message: _error!,
            onSettings: _error!.contains('settings')
                ? _locationService.openAppSettings
                : null,
          ),
          const SizedBox(height: 12),
        ],
        _CurrentLocationAction(
          loading: _locating,
          onTap: _useCurrentLocation,
        ),
        const SizedBox(height: 10),
        _ManualAddressAction(
          onTap: () => setState(() {
            _showAddressForm = true;
            _error = null;
          }),
        ),
        const SizedBox(height: 24),
        const _ListTitle(
          title: 'Saved collection addresses',
          subtitle: 'Synced securely to your account',
        ),
        const SizedBox(height: 11),
        if (_loading)
          for (var index = 0; index < 2; index++) ...[
            Container(
              height: 104,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF2),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 10),
          ]
        else if (_addresses.isEmpty)
          const _NoSavedAddress()
        else
          for (var index = 0; index < _addresses.length; index++) ...[
            _SavedAddressCard(
              address: _addresses[index],
              active:
                  _addresses[index].id == widget.currentLocation?.id ||
                  _addresses[index].isDefault,
              disabled: _saving,
              onTap: () => _selectAddress(_addresses[index]),
            ),
            if (index != _addresses.length - 1) const SizedBox(height: 10),
          ],
        const SizedBox(height: 22),
        const _PrivacyNote(),
      ],
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: ListView(
        key: const ValueKey('address-form'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _showAddressForm = false),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: _ListTitle(
                  title: 'Add collection address',
                  subtitle: 'Use the exact entrance or pickup point',
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _LocationError(message: _error!),
          ],
          const SizedBox(height: 18),
          const Text(
            'Save as',
            style: TextStyle(
              color: _LocationPalette.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            children: ['Home', 'Work', 'Other']
                .map(
                  (label) => ChoiceChip(
                    label: Text(label),
                    selected: _label == label,
                    onSelected: (_) => setState(() => _label = label),
                    showCheckmark: false,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          _AddressField(
            controller: _addressLineController,
            label: 'Flat, house, building or street',
            hint: 'e.g. Flat 3B, 24 Lake Road',
            icon: Icons.home_outlined,
            validator: _requiredAddress,
          ),
          const SizedBox(height: 12),
          _AddressField(
            controller: _areaController,
            label: 'Area or locality',
            hint: 'e.g. Salt Lake Sector 1',
            icon: Icons.location_city_outlined,
            validator: _requiredAddress,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AddressField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'Kolkata',
                  validator: _requiredAddress,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AddressField(
                  controller: _stateController,
                  label: 'State',
                  hint: 'West Bengal',
                  validator: _requiredAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AddressField(
            controller: _postalController,
            label: 'PIN code',
            hint: '6-digit PIN',
            icon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              final pin = value?.trim() ?? '';
              if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
                return 'Enter a valid 6-digit PIN';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _AddressField(
            controller: _landmarkController,
            label: 'Landmark (optional)',
            hint: 'Near hospital, gate or shop',
            icon: Icons.flag_outlined,
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _saving ? null : _saveManualAddress,
              style: FilledButton.styleFrom(
                backgroundColor: _LocationPalette.primary,
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
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String? _requiredAddress(String? value) {
    if ((value ?? '').trim().length < 2) return 'Required';
    return null;
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _LocationPalette.border)),
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose collection address',
                      style: TextStyle(
                        color: _LocationPalette.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.35,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'We’ll use it for availability and home collection',
                      style: TextStyle(
                        color: _LocationPalette.muted,
                        fontSize: 12.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationAction extends StatelessWidget {
  const _CurrentLocationAction({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: loading
          ? const SizedBox(
              width: 21,
              height: 21,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : const Icon(
              Icons.my_location_rounded,
              color: _LocationPalette.primary,
            ),
      title: loading ? 'Detecting your location…' : 'Use current location',
      subtitle: 'Best accuracy for the collection executive',
      onTap: loading ? null : onTap,
      highlighted: true,
    );
  }
}

class _ManualAddressAction extends StatelessWidget {
  const _ManualAddressAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: const Icon(
        Icons.add_location_alt_outlined,
        color: _LocationPalette.ink,
      ),
      title: 'Add address manually',
      subtitle: 'House, area, city and PIN code',
      onTap: onTap,
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? _LocationPalette.primarySoft : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFBCD3FA)
                  : _LocationPalette.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 30, child: Center(child: icon)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _LocationPalette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _LocationPalette.muted,
                        fontSize: 11.7,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _LocationPalette.muted,
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? _LocationPalette.primary
                  : _LocationPalette.border,
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: active
                      ? _LocationPalette.primarySoft
                      : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  address.label.toLowerCase() == 'work'
                      ? Icons.work_outline_rounded
                      : Icons.home_outlined,
                  color: active
                      ? _LocationPalette.primary
                      : _LocationPalette.text,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label,
                          style: const TextStyle(
                            color: _LocationPalette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _LocationPalette.primarySoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'SELECTED',
                              style: TextStyle(
                                color: _LocationPalette.primary,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .45,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      address.displayAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _LocationPalette.text,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      address.serviceabilityLabel,
                      style: const TextStyle(
                        color: Color(0xFF16803C),
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? _LocationPalette.primary : Colors.transparent,
                  border: Border.all(
                    color: active
                        ? _LocationPalette.primary
                        : _LocationPalette.muted.withValues(alpha: .55),
                    width: 1.7,
                  ),
                ),
                child: active
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListTitle extends StatelessWidget {
  const _ListTitle({required this.title, required this.subtitle});

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
            color: _LocationPalette.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: _LocationPalette.muted,
            fontSize: 11.7,
          ),
        ),
      ],
    );
  }
}

class _NoSavedAddress extends StatelessWidget {
  const _NoSavedAddress();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _LocationPalette.border),
      ),
      child: const Text(
        'No saved address yet. Use GPS or add one manually; it will appear here next time.',
        style: TextStyle(
          color: _LocationPalette.text,
          fontSize: 12.5,
          height: 1.45,
        ),
      ),
    );
  }
}

class _LocationError extends StatelessWidget {
  const _LocationError({required this.message, this.onSettings});

  final String message;
  final Future<bool> Function()? onSettings;

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
          if (onSettings != null)
            TextButton(
              onPressed: onSettings,
              child: const Text('Settings'),
            ),
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _LocationPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _LocationPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _LocationPalette.primary,
            width: 1.5,
          ),
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
        Icon(Icons.lock_outline_rounded, size: 16, color: _LocationPalette.muted),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'Your precise address is private and is only used for your bookings and collection logistics.',
            style: TextStyle(
              color: _LocationPalette.muted,
              fontSize: 10.8,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationPalette {
  const _LocationPalette._();

  static const background = Color(0xFFF7F9FC);
  static const ink = Color(0xFF101828);
  static const text = Color(0xFF475467);
  static const muted = Color(0xFF7C8AA3);
  static const border = Color(0xFFE2E7F0);
  static const primary = Color(0xFF1769E8);
  static const primarySoft = Color(0xFFEAF2FF);
}
