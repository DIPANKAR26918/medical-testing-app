import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medical_test.dart';
import '../models/order.dart';
import '../utils/app_theme.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';
import 'order_details_screen.dart';

/// A short, full-screen hand-off between confirmation and the new booking.
///
/// The screen deliberately has no dismiss action. It gives the user one clear
/// success signal, names the booked test, and then opens that exact order.
class DirectBookingSuccessScreen extends StatefulWidget {
  const DirectBookingSuccessScreen({
    required this.order,
    required this.tests,
    this.displayDuration = const Duration(milliseconds: 2400),
    this.feedbackEnabled = true,
    super.key,
  });

  final Order order;
  final List<MedicalTest> tests;
  final Duration displayDuration;
  final bool feedbackEnabled;

  @override
  State<DirectBookingSuccessScreen> createState() =>
      _DirectBookingSuccessScreenState();
}

class _DirectBookingSuccessScreenState
    extends State<DirectBookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  late final Animation<double> _contentOpacity;
  Timer? _navigationTimer;
  bool _openingBooking = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _checkScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .58, curve: Curves.elasticOut),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.22, .72, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _navigationTimer = Timer(widget.displayDuration, _openBooking);
    if (widget.feedbackEnabled) {
      unawaited(_playFeedback());
    }
  }

  Future<void> _playFeedback() async {
    await Future<void>.delayed(const Duration(milliseconds: 310));
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    await HapticFeedback.mediumImpact();
  }

  void _openBooking() {
    if (!mounted || _openingBooking) return;
    _openingBooking = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: OrderDetailsScreen(order: widget.order),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstTest = widget.tests.isEmpty ? null : widget.tests.first;
    final fallbackName = widget.order.testList.isEmpty
        ? 'Medical test booking'
        : widget.order.testList.first;
    final testName = firstTest?.displayName ?? fallbackName;
    final additionalCount = (widget.tests.isNotEmpty
            ? widget.tests.length
            : widget.order.testList.length) -
        1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const ValueKey('direct-booking-success-screen'),
        backgroundColor: const Color(0xFFF8FAFF),
        body: SafeArea(
          child: Semantics(
            liveRegion: true,
            label: 'Booking and appointment slot confirmed. Opening details.',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    children: [
                      const Spacer(flex: 2),
                      SizedBox(
                        width: 142,
                        height: 142,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: .72 + (.28 * _controller.value),
                              child: Container(
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF8F1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFC8EAD8),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 94,
                              height: 94,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x1F166B4B),
                                    blurRadius: 24,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Transform.scale(
                                scale: _checkScale.value,
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF16845A),
                                  size: 53,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: _contentOpacity.value,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            12 * (1 - _contentOpacity.value),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Booking confirmed',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF101828),
                                  fontSize: 26,
                                  height: 1.15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.45,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.order.collectionSlot == null
                                    ? 'Your booking is saved. We’ll keep you updated at every step.'
                                    : 'Your slot is ${widget.order.collectionSlot!.fullLabel}.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 13.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFDCE6F5),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0D17213A),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    if (firstTest != null)
                                      MedicalTestIconBadge(
                                        test: firstTest,
                                        size: 54,
                                        useHero: false,
                                      )
                                    else
                                      Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF4FF),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.science_outlined,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            testName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF101828),
                                              fontSize: 14.5,
                                              height: 1.25,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            additionalCount > 0
                                                ? '+$additionalCount more tests'
                                                : firstTest
                                                        ?.collectionLabel ??
                                                    'Booking received',
                                            style: const TextStyle(
                                              color: Color(0xFF667085),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Color(0xFF2563EB),
                          strokeWidth: 2.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Opening your booking…',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
