import 'package:flutter/material.dart';

import '../models/location_data.dart';
import '../models/medical_test.dart';
import '../models/collection_slot.dart';
import '../models/order.dart';
import '../services/direct_booking_service.dart';
import '../services/location_service.dart';
import '../utils/app_theme.dart';
import '../utils/location_display_formatter.dart';
import '../widgets/location_selector_sheet_v5.dart';
import '../widgets/collection_slot_picker.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';
import 'direct_booking_success_screen.dart';

Future<bool> startDirectTestBookingFlow(
  BuildContext context, {
  required List<MedicalTest> tests,
  VoidCallback? onBookingConfirmed,
}) async {
  if (tests.isEmpty) return false;

  final bookedOrder = await showDirectTestBookingSheet(
    context,
    tests: tests,
  );
  if (!context.mounted || bookedOrder == null) return false;

  onBookingConfirmed?.call();
  if (!context.mounted) return false;

  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => DirectBookingSuccessScreen(
        order: bookedOrder,
        tests: tests,
      ),
    ),
  );
  return true;
}

Future<Order?> showDirectTestBookingSheet(
  BuildContext context, {
  required List<MedicalTest> tests,
}) {
  return showModalBottomSheet<Order>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .36),
    routeSettings: const RouteSettings(name: 'direct-test-booking-checkout'),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: .9,
      child: Material(
        color: _Palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: DirectTestCheckoutScreen(
          tests: tests,
          modal: true,
          onBookingCreated: (order) =>
              Navigator.of(sheetContext).pop(order),
        ),
      ),
    ),
  );
}

class DirectTestCheckoutScreen extends StatefulWidget {
  const DirectTestCheckoutScreen({
    required this.tests,
    this.modal = false,
    this.onBookingCreated,
    super.key,
  });

  final List<MedicalTest> tests;
  final bool modal;
  final ValueChanged<Order>? onBookingCreated;

  @override
  State<DirectTestCheckoutScreen> createState() =>
      _DirectTestCheckoutScreenState();
}

class _DirectTestCheckoutScreenState extends State<DirectTestCheckoutScreen> {
  final DirectBookingService _bookingService = DirectBookingService();
  final LocationService _locationService = LocationService();

  LocationData? _address;
  CollectionSlot? _collectionSlot;
  bool _loadingAddress = true;
  bool _submitting = false;

  bool get _requiresLabVisit =>
      widget.tests.every((test) => test.labVisitRequired);

  bool get _requiresHomeCollection => !_requiresLabVisit;

  double get _mrpTotal => widget.tests.totalMrp;

  double get _total => widget.tests.totalSellingPrice;

  bool get _canSubmit {
    if (_submitting || widget.tests.isEmpty) return false;
    if (_collectionSlot == null) return false;
    if (_requiresLabVisit) return true;
    return _address?.id?.trim().isNotEmpty == true &&
        _address?.serviceabilityStatus != 'unavailable';
  }

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    if (!_requiresHomeCollection) {
      if (mounted) setState(() => _loadingAddress = false);
      return;
    }

    try {
      final address = await _locationService.loadSavedLocation();
      if (!mounted) return;
      setState(() {
        _address = address;
        _loadingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAddress = false);
    }
  }

  Future<void> _chooseAddress() async {
    if (_submitting) return;

    final selected = await showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationSelectorSheet(currentLocation: _address),
    );

    if (!mounted || selected == null) return;
    setState(() => _address = selected);
  }

  Future<void> _chooseSlot() async {
    if (_submitting) return;
    final selected = await showCollectionSlotPicker(
      context,
      current: _collectionSlot,
      labVisit: _requiresLabVisit,
    );
    if (!mounted || selected == null) return;
    setState(() => _collectionSlot = selected);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_requiresHomeCollection &&
        (_address?.id?.trim().isNotEmpty != true ||
            _address?.serviceabilityStatus == 'unavailable')) {
      await _chooseAddress();
      return;
    }
    if (_collectionSlot == null) {
      await _chooseSlot();
      return;
    }
    if (!_canSubmit) return;

    setState(() => _submitting = true);

    try {
      final bookedOrder = await _bookingService.createBooking(
        tests: widget.tests,
        collectionSlot: _collectionSlot!,
        collectionAddressId: _requiresHomeCollection ? _address?.id : null,
      );
      if (!mounted) return;

      final onBookingCreated = widget.onBookingCreated;
      if (onBookingCreated != null) {
        onBookingCreated(bookedOrder);
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DirectBookingSuccessScreen(
            order: bookedOrder,
            tests: widget.tests,
          ),
        ),
      );
    } on DirectBookingException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('Booking could not be created. Please retry.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.modal,
        backgroundColor: _Palette.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(widget.modal ? 'Confirm booking' : 'Review booking'),
        actions: widget.modal
            ? [
                IconButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 126),
          children: [
            _SectionCard(
              title: widget.tests.length == 1
                  ? 'Selected test'
                  : 'Selected tests',
              highlighted: true,
              child: Column(
                children: [
                  for (var index = 0; index < widget.tests.length; index++) ...[
                    _SelectedTestRow(test: widget.tests[index]),
                    if (index != widget.tests.length - 1)
                      const Divider(height: 1, color: _Palette.divider),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Collection details'),
            const SizedBox(height: 8),
            if (_requiresHomeCollection)
              _AddressCard(
                loading: _loadingAddress,
                address: _address,
                onChange: _chooseAddress,
              )
            else
              const _LabVisitCard(),
            const SizedBox(height: 14),
            CollectionSlotPickerCard(
              slot: _collectionSlot,
              labVisit: _requiresLabVisit,
              enabled: !_submitting,
              onChoose: _chooseSlot,
            ),
            const SizedBox(height: 14),
            const _WhatHappensNextCard(),
          ],
        ),
      ),
      bottomNavigationBar: _CheckoutBar(
        mrpTotal: _mrpTotal,
        total: _total,
        enabled: !_submitting &&
            (!_requiresHomeCollection || !_loadingAddress),
        submitting: _submitting,
        actionLabel: _requiresHomeCollection &&
                (_address?.id?.trim().isNotEmpty != true ||
                    _address?.serviceabilityStatus == 'unavailable')
            ? 'Add address'
            : _collectionSlot == null
            ? 'Choose slot'
            : 'Confirm booking',
        onSubmit: _submit,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _Palette.ink,
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.15,
      ),
    );
  }
}

// ignore: unused_element
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.count,
    required this.mrpTotal,
    required this.total,
    required this.requiresLabVisit,
  });

  final int count;
  final double mrpTotal;
  final double total;
  final bool requiresLabVisit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Palette.primarySoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE8FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              requiresLabVisit
                  ? Icons.apartment_rounded
                  : Icons.home_work_outlined,
              color: _Palette.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'test' : 'tests'} selected',
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  requiresLabVisit
                      ? 'Lab visit required'
                      : 'Home sample collection',
                  style: const TextStyle(
                    color: _Palette.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 116,
            child: DiscountedPrice(
              mrp: mrpTotal,
              sellingPrice: total,
              showMrpLabel: false,
              mrpFontSize: 10,
              priceFontSize: 18,
              priceColor: _Palette.ink,
              alignment: WrapAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.highlighted = false,
  });

  final String title;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: highlighted ? _Palette.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? const Color(0xFFCADBFF) : _Palette.border,
          width: highlighted ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Text(
              title,
              style: const TextStyle(
                color: _Palette.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: highlighted ? const Color(0xFFD7E3FA) : _Palette.divider,
          ),
          child,
        ],
      ),
    );
  }
}

class _SelectedTestRow extends StatelessWidget {
  const _SelectedTestRow({required this.test});

  final MedicalTest test;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          MedicalTestIconBadge(test: test, size: 54, useHero: false),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontSize: 14.5,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  test.collectionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _Palette.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 108,
            child: MedicalTestPrice(
              test: test,
              showMrpLabel: false,
              mrpFontSize: 9.2,
              priceFontSize: 13.5,
              priceColor: _Palette.ink,
              alignment: WrapAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.loading,
    required this.address,
    required this.onChange,
  });

  final bool loading;
  final LocationData? address;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final unavailable = address?.serviceabilityStatus == 'unavailable';
    final currentAddress = address;
    final readableAddress = currentAddress == null
        ? ''
        : locationReadableAddress(currentAddress);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unavailable ? const Color(0xFFF1C6CC) : _Palette.border,
        ),
      ),
      child: loading
          ? const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Loading collection address',
                  style: TextStyle(
                    color: _Palette.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _Palette.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: _Palette.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collection address',
                        style: TextStyle(
                          color: _Palette.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        readableAddress.isNotEmpty
                            ? readableAddress
                            : 'Choose where the sample should be collected.',
                        style: TextStyle(
                          color: unavailable
                              ? const Color(0xFFB4233C)
                              : _Palette.muted,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (unavailable) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Home collection is unavailable here. Choose another address.',
                          style: TextStyle(
                            color: Color(0xFFB4233C),
                            fontSize: 11.5,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onChange,
                  child: Text(address == null ? 'Choose' : 'Change'),
                ),
              ],
            ),
    );
  }
}

class _LabVisitCard extends StatelessWidget {
  const _LabVisitCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.apartment_rounded, color: _Palette.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lab visit required',
                  style: TextStyle(
                    color: _Palette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'The support team will confirm the available lab and visit instructions.',
                  style: TextStyle(
                    color: _Palette.muted,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
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

class _WhatHappensNextCard extends StatelessWidget {
  const _WhatHappensNextCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: _Palette.primary,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Collection and report updates will appear in Bookings.',
              style: TextStyle(
                color: _Palette.muted,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _Palette.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: _Palette.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _Palette.muted,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.mrpTotal,
    required this.total,
    required this.enabled,
    required this.submitting,
    required this.actionLabel,
    required this.onSubmit,
  });

  final double mrpTotal;
  final double total;
  final bool enabled;
  final bool submitting;
  final String actionLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _Palette.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, -7),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DiscountedPrice(
                    mrp: mrpTotal,
                    sellingPrice: total,
                    showMrpLabel: false,
                    mrpFontSize: 9.8,
                    priceFontSize: 18,
                    priceColor: _Palette.ink,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Total',
                    style: const TextStyle(
                      color: _Palette.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: enabled ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Palette.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD7DEE9),
                  disabledForegroundColor: const Color(0xFF8793A6),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Palette {
  const _Palette._();

  static const Color background = Color(0xFFF7F9FC);
  static const Color ink = Color(0xFF101828);
  static const Color muted = Color(0xFF667085);
  static const Color primary = Color(0xFF2563EB);
  static const Color primarySoft = Color(0xFFEEF4FF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF1F6);
}
