import 'package:flutter/material.dart';

import '../models/location_data.dart';
import '../models/medical_test.dart';
import '../services/direct_booking_service.dart';
import '../services/location_service.dart';
import '../utils/app_theme.dart';
import '../widgets/location_selector_sheet_v5.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';

class DirectTestCheckoutScreen extends StatefulWidget {
  const DirectTestCheckoutScreen({required this.tests, super.key});

  final List<MedicalTest> tests;

  @override
  State<DirectTestCheckoutScreen> createState() =>
      _DirectTestCheckoutScreenState();
}

class _DirectTestCheckoutScreenState
    extends State<DirectTestCheckoutScreen> {
  final DirectBookingService _bookingService = DirectBookingService();
  final LocationService _locationService = LocationService();

  LocationData? _address;
  bool _loadingAddress = true;
  bool _submitting = false;

  bool get _requiresLabVisit =>
      widget.tests.every((test) => test.labVisitRequired);

  bool get _requiresHomeCollection => !_requiresLabVisit;

  double get _total => widget.tests.fold<double>(
        0,
        (sum, test) => sum + (test.mrp ?? 0),
      );

  bool get _canSubmit {
    if (_submitting || widget.tests.isEmpty) return false;
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

  Future<void> _submit() async {
    if (!_canSubmit) {
      if (_requiresHomeCollection) {
        _showMessage('Choose a serviceable collection address first.');
      }
      return;
    }

    setState(() => _submitting = true);

    try {
      await _bookingService.createBooking(
        tests: widget.tests,
        collectionAddressId: _requiresHomeCollection ? _address?.id : null,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF237A52),
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Booking request sent',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _Palette.ink,
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _requiresLabVisit
                    ? 'We’ll confirm the lab and visit details shortly.'
                    : 'We’ll confirm your home collection and keep you updated.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _Palette.muted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('View booking'),
                ),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: 1,
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
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        backgroundColor: _Palette.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text('Review booking'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 126),
          children: [
            _SummaryHeader(
              count: widget.tests.length,
              total: _total,
              requiresLabVisit: _requiresLabVisit,
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Selected tests',
              child: Column(
                children: [
                  for (var index = 0;
                      index < widget.tests.length;
                      index++) ...[
                    _SelectedTestRow(test: widget.tests[index]),
                    if (index != widget.tests.length - 1)
                      const Divider(
                        height: 1,
                        color: _Palette.divider,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_requiresHomeCollection)
              _AddressCard(
                loading: _loadingAddress,
                address: _address,
                onChange: _chooseAddress,
              )
            else
              const _LabVisitCard(),
            const SizedBox(height: 14),
            const _WhatHappensNextCard(),
          ],
        ),
      ),
      bottomNavigationBar: _CheckoutBar(
        count: widget.tests.length,
        total: _total,
        enabled: _canSubmit,
        submitting: _submitting,
        onSubmit: _submit,
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.count,
    required this.total,
    required this.requiresLabVisit,
  });

  final int count;
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
          Text(
            _money(total),
            style: const TextStyle(
              color: _Palette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.border),
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
          const Divider(height: 1, color: _Palette.divider),
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
          MedicalTestIconBadge(test: test, size: 42, useHero: false),
          const SizedBox(width: 12),
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
                    fontSize: 13.5,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  test.reportLabel,
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
          Text(
            test.priceLabel,
            style: const TextStyle(
              color: _Palette.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
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
                        address?.displayAddress.trim().isNotEmpty == true
                            ? address!.displayAddress.trim()
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
          Icon(
            Icons.apartment_rounded,
            color: _Palette.primary,
            size: 24,
          ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next',
            style: TextStyle(
              color: _Palette.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _StepRow(
            number: '1',
            text: 'Test availability and collection details are verified.',
          ),
          SizedBox(height: 10),
          _StepRow(
            number: '2',
            text: 'Your booking status appears in the Bookings tab.',
          ),
          SizedBox(height: 10),
          _StepRow(
            number: '3',
            text: 'You receive updates as the booking progresses.',
          ),
        ],
      ),
    );
  }
}

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
    required this.count,
    required this.total,
    required this.enabled,
    required this.submitting,
    required this.onSubmit,
  });

  final int count;
  final double total;
  final bool enabled;
  final bool submitting;
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
                  Text(
                    _money(total),
                    style: const TextStyle(
                      color: _Palette.ink,
                      fontSize: 18,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count ${count == 1 ? 'test' : 'tests'}',
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
                    : const Text('Request booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double value) {
  final formatted = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '₹$formatted';
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
