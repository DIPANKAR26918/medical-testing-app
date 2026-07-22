import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/location_feature_config.dart';
import '../models/location_data.dart';
import '../screens/location_map_picker_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressLineController =
      TextEditingController();
  final TextEditingController _addressLine2Controller =
      TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<LocationData> _addresses = const [];
  LocationData? _draft;
  LocationData? _editingAddress;
  String? _selectedId;
  bool _loading = true;
  bool _locating = false;
  bool _saving = false;
  bool _showAddressForm = false;
  String _label = 'Home';
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentLocation?.id;
    _loadAddresses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressLineController.dispose();
    _addressLine2Controller.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _landmarkController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await _locationService.loadSavedLocations();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        if (_selectedId == null) {
          for (final address in addresses) {
            if (address.isDefault) {
              _selectedId = address.id;
              break;
            }
          }
        }
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
      final current = await _locationService.resolveLocation(
        LocationSelectionMode.precise,
      );
      if (!mounted) return;
      if (current == null) {
        final permission = await _locationService.checkPermission();
        if (!mounted) return;
        setState(() {
          _locating = false;
          _error = permission == LocationPermission.deniedForever
              ? 'Location access is blocked. Enable it from app settings.'
              : 'Turn on location, or add the collection address yourself.';
        });
        return;
      }

      var draft = current;
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
        draft = pinned;
      }
      _openAddressForm(draft);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _error = 'Current location is unavailable. Please try again.';
      });
    }
  }

  Future<void> _addNewAddress({bool focusSearch = false}) async {
    if (LocationFeatureConfig.googleMapsEnabled) {
      final initial = widget.currentLocation?.hasCoordinates == true
          ? widget.currentLocation
          : null;
      final pinned = await openLocationMapPicker(
        context,
        initialLocation: initial,
        focusSearch: focusSearch,
      );
      if (!mounted || pinned == null) return;
      _openAddressForm(pinned);
      return;
    }
    _openAddressForm(
      LocationData(
        type: LocationType.manual,
        displayAddress: '',
        locationSource: 'manual',
        provider: 'manual',
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _changePinnedLocation() async {
    final draft = _draft;
    if (draft == null || !LocationFeatureConfig.googleMapsEnabled) return;
    final pinned = await openLocationMapPicker(
      context,
      initialLocation: draft,
    );
    if (!mounted || pinned == null) return;

    _draft = pinned.copyWith(
      id: _editingAddress?.id,
      label: _label,
      addressLine1: _addressLineController.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      landmark: _landmarkController.text.trim(),
      recipientName: _recipientController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );
    _areaController.text = pinned.locality ?? '';
    _cityController.text = pinned.city ?? '';
    _stateController.text = pinned.state ?? '';
    _postalController.text = pinned.postalCode ?? '';
    setState(() => _error = null);
  }

  void _openAddressForm(LocationData draft, {LocationData? editing}) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final fallbackName =
        metadata['full_name']?.toString().trim() ??
        metadata['name']?.toString().trim() ??
        '';

    _draft = draft;
    _editingAddress = editing;
    _label = editing?.label ??
        (draft.label == 'Current location' ? 'Home' : draft.label);
    _addressLineController.text = draft.addressLine1 ?? '';
    _addressLine2Controller.text = draft.addressLine2 ?? '';
    _areaController.text = draft.locality ?? '';
    _cityController.text = draft.city ?? '';
    _stateController.text = draft.state ?? '';
    _postalController.text = draft.postalCode ?? '';
    _landmarkController.text = draft.landmark ?? '';
    _recipientController.text = draft.recipientName ?? fallbackName;
    _phoneController.text = draft.phoneNumber ?? user?.phone ?? '';
    setState(() {
      _showAddressForm = true;
      _locating = false;
      _error = null;
    });
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

  Future<void> _saveAddress() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final draft = _draft;
    if (draft == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final addressLine1 = _addressLineController.text.trim();
    final addressLine2 = _addressLine2Controller.text.trim();
    final area = _areaController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final postalCode = _postalController.text.trim();
    final displayAddress = [
      addressLine1,
      addressLine2,
      area,
      city,
      state,
      postalCode,
    ].where((value) => value.isNotEmpty).toSet().join(', ');

    final editing = _editingAddress;
    final shouldSelect =
        editing == null || editing.id == _selectedId || editing.isDefault;
    try {
      final saved = await _locationService.saveLocation(
        draft.copyWith(
          id: editing?.id ?? draft.id,
          type: draft.hasCoordinates
              ? LocationType.precise
              : LocationType.manual,
          label: _label,
          displayAddress: displayAddress,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          locality: area,
          city: city,
          state: state,
          postalCode: postalCode,
          landmark: _landmarkController.text.trim(),
          recipientName: _recipientController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          validationStatus: draft.hasCoordinates ? 'confirmed' : 'unverified',
          updatedAt: DateTime.now(),
        ),
        makeDefault: shouldSelect,
      );
      if (!mounted) return;
      if (shouldSelect) {
        Navigator.pop(context, saved);
        return;
      }
      setState(() {
        _showAddressForm = false;
        _saving = false;
        _editingAddress = null;
        _draft = null;
      });
      await _loadAddresses();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Address could not be saved. Check the details and retry.';
      });
    }
  }

  Future<void> _editAddress(LocationData address) async {
    _openAddressForm(address, editing: address);
  }

  Future<void> _deleteAddress(LocationData address) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeleteAddressConfirmation(address: address),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final fallback = await _locationService.deleteLocation(address);
      if (!mounted) return;
      final deletedSelected =
          address.id == _selectedId || address.isDefault;
      if (deletedSelected) {
        Navigator.pop(context, fallback ?? LocationData.empty);
        return;
      }
      setState(() => _saving = false);
      await _loadAddresses();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Address could not be deleted.';
      });
    }
  }

  List<LocationData> get _visibleAddresses {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _addresses;
    return _addresses.where((address) {
      return [
        address.label,
        address.displayAddress,
        address.recipientName,
        address.phoneNumber,
        address.postalCode,
      ].whereType<String>().join(' ').toLowerCase().contains(query);
    }).toList(growable: false);
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
            color: _LocationPalette.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _SheetHeader(
                formMode: _showAddressForm,
                onBack: () => setState(() {
                  _showAddressForm = false;
                  _editingAddress = null;
                  _draft = null;
                  _error = null;
                }),
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
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
    final visible = _visibleAddresses;
    return ListView(
      key: const ValueKey('address-picker'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _AddressSearchField(
          controller: _searchController,
          mapSearchEnabled: LocationFeatureConfig.googleMapsEnabled,
          onTap: () => _addNewAddress(focusSearch: true),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        if (_error != null) ...[
          _LocationError(
            message: _error!,
            onSettings: _error!.contains('settings')
                ? _locationService.openAppSettings
                : null,
          ),
          const SizedBox(height: 12),
        ],
        _QuickActionRow(
          icon: Icons.my_location_rounded,
          title: _locating ? 'Finding your location…' : 'Use current location',
          highlighted: true,
          loading: _locating,
          onTap: _locating ? null : _useCurrentLocation,
        ),
        const SizedBox(height: 10),
        _QuickActionRow(
          icon: Icons.add_rounded,
          title: 'Add new address',
          onTap: _saving ? null : _addNewAddress,
        ),
        const SizedBox(height: 24),
        const Text(
          'Saved addresses',
          style: TextStyle(
            color: _LocationPalette.ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -.2,
          ),
        ),
        const SizedBox(height: 11),
        if (_loading)
          for (var index = 0; index < 2; index++) ...[
            const _AddressSkeleton(),
            const SizedBox(height: 10),
          ]
        else if (visible.isEmpty)
          _EmptyAddressState(isSearch: _query.trim().isNotEmpty)
        else
          for (var index = 0; index < visible.length; index++) ...[
            _SavedAddressCard(
              address: visible[index],
              active:
                  visible[index].id == _selectedId ||
                  (_selectedId == null && visible[index].isDefault),
              disabled: _saving,
              onTap: () => _selectAddress(visible[index]),
              onEdit: () => _editAddress(visible[index]),
              onDelete: () => _deleteAddress(visible[index]),
            ),
            if (index != visible.length - 1) const SizedBox(height: 10),
          ],
        const SizedBox(height: 20),
        const _PrivacyNote(),
      ],
    );
  }

  Widget _buildAddressForm() {
    final draft = _draft;
    return Form(
      key: _formKey,
      child: ListView(
        key: const ValueKey('address-form'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (draft?.hasCoordinates == true) ...[
            _PinnedAddressPreview(
              location: draft!,
              onChange: LocationFeatureConfig.googleMapsEnabled
                  ? _changePinnedLocation
                  : null,
            ),
            const SizedBox(height: 18),
          ],
          if (_error != null) ...[
            _LocationError(message: _error!),
            const SizedBox(height: 14),
          ],
          const _SectionLabel('Save as'),
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
          const SizedBox(height: 20),
          const _SectionLabel('Address details'),
          const SizedBox(height: 10),
          _AddressField(
            controller: _addressLineController,
            label: 'House, flat or building',
            hint: 'e.g. Flat 3B, Sunrise Apartment',
            icon: Icons.home_outlined,
            validator: _requiredAddress,
          ),
          const SizedBox(height: 11),
          _AddressField(
            controller: _addressLine2Controller,
            label: 'Floor, block or street (optional)',
            hint: 'e.g. Block C, 2nd floor',
            icon: Icons.apartment_outlined,
          ),
          const SizedBox(height: 11),
          _AddressField(
            controller: _areaController,
            label: 'Area or locality',
            hint: 'e.g. Pundibari',
            icon: Icons.location_city_outlined,
            validator: _requiredAddress,
          ),
          const SizedBox(height: 11),
          _AddressField(
            controller: _landmarkController,
            label: 'Landmark (optional)',
            hint: 'Near a gate, pharmacy or school',
            icon: Icons.flag_outlined,
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AddressField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'City',
                  validator: _requiredAddress,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AddressField(
                  controller: _stateController,
                  label: 'State',
                  hint: 'State',
                  validator: _requiredAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _AddressField(
            controller: _postalController,
            label: 'PIN code',
            hint: '6-digit PIN',
            icon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (!RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')) {
                return 'Enter a valid 6-digit PIN';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Collection contact'),
          const SizedBox(height: 10),
          _AddressField(
            controller: _recipientController,
            label: 'Patient or contact name',
            hint: 'Who should we contact?',
            icon: Icons.person_outline_rounded,
            validator: _requiredAddress,
          ),
          const SizedBox(height: 11),
          _AddressField(
            controller: _phoneController,
            label: 'Phone number',
            hint: '10-digit mobile number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
              if (digits.length < 10 || digits.length > 12) {
                return 'Enter a valid mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _saving ? null : _saveAddress,
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
                  : Text(
                      _editingAddress == null
                          ? 'Save & use this address'
                          : 'Save changes',
                      style: const TextStyle(fontWeight: FontWeight.w900),
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
  const _SheetHeader({
    required this.formMode,
    required this.onBack,
    required this.onClose,
  });

  final bool formMode;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 13),
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
          const SizedBox(height: 10),
          Row(
            children: [
              if (formMode)
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              else
                const SizedBox(width: 10),
              Expanded(
                child: Text(
                  formMode ? 'Address details' : 'Select collection address',
                  style: const TextStyle(
                    color: _LocationPalette.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.35,
                  ),
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

class _AddressSearchField extends StatelessWidget {
  const _AddressSearchField({
    required this.controller,
    required this.mapSearchEnabled,
    required this.onTap,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool mapSearchEnabled;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: mapSearchEnabled,
      onTap: mapSearchEnabled ? onTap : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: mapSearchEnabled
            ? 'Search area, street or PIN code'
            : 'Search your saved addresses',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _LocationPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _LocationPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _LocationPalette.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.highlighted = false,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? _LocationPalette.primarySoft : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFBCD3FA)
                  : _LocationPalette.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 25,
                height: 25,
                child: loading
                    ? const CircularProgressIndicator(strokeWidth: 2.2)
                    : Icon(
                        icon,
                        color: highlighted
                            ? _LocationPalette.primary
                            : _LocationPalette.ink,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: highlighted
                        ? _LocationPalette.primary
                        : _LocationPalette.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
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
    required this.onEdit,
    required this.onDelete,
  });

  final LocationData address;
  final bool active;
  final bool disabled;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                width: 42,
                height: 52,
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
                            address.recipientName?.trim().isNotEmpty == true
                                ? address.recipientName!
                                : address.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _LocationPalette.ink,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 7),
                          const _SelectedBadge(),
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
                    if (address.phoneNumber?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            color: _LocationPalette.muted,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            address.phoneNumber!,
                            style: const TextStyle(
                              color: _LocationPalette.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: !disabled,
                tooltip: 'Address actions',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: _LocationPalette.muted,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit address'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Delete address'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _LocationPalette.primarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Selected',
        style: TextStyle(
          color: _LocationPalette.primary,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PinnedAddressPreview extends StatelessWidget {
  const _PinnedAddressPreview({required this.location, this.onChange});

  final LocationData location;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _LocationPalette.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: _LocationPalette.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pinned collection point',
                  style: TextStyle(
                    color: _LocationPalette.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location.displayAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _LocationPalette.text,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onChange != null)
            TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _DeleteAddressConfirmation extends StatelessWidget {
  const _DeleteAddressConfirmation({required this.address});

  final LocationData address;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delete this address?',
              style: TextStyle(
                color: _LocationPalette.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              address.displayAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _LocationPalette.text,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep address'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD92D20),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _LocationPalette.ink,
        fontSize: 13,
        fontWeight: FontWeight.w900,
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
            TextButton(onPressed: onSettings, child: const Text('Settings')),
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
      height: 116,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF2),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  const _EmptyAddressState({required this.isSearch});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _LocationPalette.border),
      ),
      child: Text(
        isSearch
            ? 'No saved address matches this search.'
            : 'No saved address yet. Add one once and it will be ready for future bookings.',
        style: const TextStyle(
          color: _LocationPalette.text,
          fontSize: 12.5,
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
        Icon(Icons.lock_outline_rounded, size: 16, color: _LocationPalette.muted),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'Your precise address is private and is used only for bookings and collection logistics.',
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
