import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../utils/app_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({
    required this.onBookNewTest,
    this.onUploadPrescription,
    super.key,
  });

  final VoidCallback onBookNewTest;
  final VoidCallback? onUploadPrescription;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  int _selectedTab = 0;

  bool get _showActiveOrders => _selectedTab == 0;

  @override
  Widget build(BuildContext context) {
    final userId = _authService.getUserId();

    if (userId == null || userId.isEmpty) {
      return _buildBody(orders: const <Order>[], isLoading: false);
    }

    return StreamBuilder<List<Order>>(
      stream: _firestoreService.getUserOrders(userId),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? const <Order>[];

        return _buildBody(
          orders: orders,
          isLoading:
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData,
          error: snapshot.error,
        );
      },
    );
  }

  Widget _buildBody({
    required List<Order> orders,
    required bool isLoading,
    Object? error,
  }) {
    final activeOrders = orders.where((order) => !_isPastOrder(order)).toList();

    final pastOrders = orders.where(_isPastOrder).toList();

    final visibleOrders = _showActiveOrders ? activeOrders : pastOrders;

    final hasAnyOrder = orders.isNotEmpty;

    return ColoredBox(
      color: _BookingPalette.background,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 116),
        children: [
          _BookingsHeader(onBookNewTest: widget.onBookNewTest),
          const SizedBox(height: 18),

          _BookingTabs(
            selectedIndex: _selectedTab,
            onChanged: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
          ),
          const SizedBox(height: 14),

          if (isLoading) ...[
            const _OrdersLoadingCard(),
          ] else if (error != null) ...[
            _OrdersErrorCard(
              onRetry: () {
                setState(() {});
              },
            ),
          ] else if (visibleOrders.isEmpty) ...[
            _EmptyBookingsState(
              variant: _emptyStateVariant(hasAnyOrder: hasAnyOrder),
              onUploadPrescription: _openUploadPrescription,
              onBookTest: widget.onBookNewTest,
            ),
          ] else ...[
            for (final order in visibleOrders) ...[
              _OrderCard(
                order: order,
                isPast: _isPastOrder(order),
                onTap: () => _openOrderDetails(order),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  _EmptyBookingsVariant _emptyStateVariant({required bool hasAnyOrder}) {
    if (!hasAnyOrder) {
      return _EmptyBookingsVariant.noBookings;
    }

    if (_showActiveOrders) {
      return _EmptyBookingsVariant.noActiveBookings;
    }

    return _EmptyBookingsVariant.noPastBookings;
  }

  void _openUploadPrescription() {
    final callback = widget.onUploadPrescription;

    if (callback != null) {
      callback();
      return;
    }

    widget.onBookNewTest();
  }

  void _openOrderDetails(Order order) {
    Navigator.pushNamed(context, '/order-details', arguments: order);
  }

  bool _isPastOrder(Order order) {
    final status = order.status
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    return status == 'completed' ||
        status == 'done' ||
        status == 'report_delivered' ||
        status == 'cancelled' ||
        status == 'canceled';
  }
}

class _BookingsHeader extends StatelessWidget {
  const _BookingsHeader({required this.onBookNewTest});

  final VoidCallback onBookNewTest;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bookings',
                style: TextStyle(
                  color: _BookingPalette.ink,
                  fontSize: 26,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Track your test bookings',
                style: TextStyle(
                  color: _BookingPalette.muted,
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            onPressed: onBookNewTest,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Book'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _BookingPalette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingTabs extends StatelessWidget {
  const _BookingTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _BookingPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Active',
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              label: 'Past',
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _BookingPalette.ink : _BookingPalette.muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isPast,
    required this.onTap,
  });

  final Order order;
  final bool isPast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = _titleFor(order);
    final subtitle = _subtitleFor(order);
    final statusLabel = _statusLabel(order);
    final statusColor = _statusColor(order);
    final dateText = _formatDate(order.createdAt);
    final patientText = _patientLabel(order);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _BookingPalette.border),
            boxShadow: _BookingPalette.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderIcon(order: order, isPast: isPast),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _BookingPalette.ink,
                              fontSize: 15.5,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _BookingPalette.muted,
                              fontSize: 12.8,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  _StatusChip(label: statusLabel, color: statusColor),
                ],
              ),

              const SizedBox(height: 14),

              _OrderMetaRow(
                dateText: dateText,
                patientText: patientText,
                orderId: _shortOrderId(order.orderId),
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _OrderProgressLabel(order: order, isPast: isPast),
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Text(
                    'View details',
                    style: TextStyle(
                      color: _BookingPalette.primary,
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: _BookingPalette.primary,
                    size: 17,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _titleFor(Order order) {
    final hasPrescription = order.prescriptionImagePath.trim().isNotEmpty;

    final tests = order.testList
        .map((test) => test.trim())
        .where((test) => test.isNotEmpty)
        .toList();

    if (hasPrescription && tests.isEmpty) {
      return 'Prescription under review';
    }

    if (tests.length == 1) {
      return tests.first;
    }

    if (tests.length > 1) {
      return '${tests.length} tests booked';
    }

    if (hasPrescription) {
      return 'Prescription uploaded';
    }

    return 'Lab test booking';
  }

  static String _subtitleFor(Order order) {
    final hasPrescription = order.prescriptionImagePath.trim().isNotEmpty;

    final tests = order.testList
        .map((test) => test.trim())
        .where((test) => test.isNotEmpty)
        .toList();

    if (hasPrescription && tests.isEmpty) {
      return 'We’re preparing your test list.';
    }

    if (tests.length > 1) {
      return tests.take(3).join(', ');
    }

    if (hasPrescription) {
      return 'Prescription uploaded successfully.';
    }

    return 'Your booking details are available here.';
  }

  static String _statusLabel(Order order) {
    final status = order.status
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (status) {
      case 'uploaded':
      case 'prescription_uploaded':
        return 'Reviewing';

      case 'reviewing':
      case 'under_review':
      case 'processing':
      case 'prescription_reviewing':
        return 'Reviewing';

      case 'test_list_prepared':
      case 'tests_prepared':
      case 'awaiting_user_approval':
        return 'Review tests';

      case 'confirmed':
      case 'booking_confirmed':
        return 'Confirmed';

      case 'assigned':
      case 'agent_assigned':
      case 'assigned_agent':
        return 'Assigned';

      case 'agent_out_for_collection':
      case 'out_for_collection':
        return 'On the way';

      case 'collected':
      case 'sample_collected':
        return 'Collected';

      case 'testing':
      case 'sample_testing':
      case 'sample_processing':
        return 'Testing';

      case 'report_preparing':
      case 'report_in_making':
        return 'Preparing report';

      case 'report_ready':
        return 'Report ready';

      case 'completed':
      case 'done':
      case 'report_delivered':
        return 'Completed';

      case 'cancelled':
      case 'canceled':
        return 'Cancelled';

      default:
        if (status.isEmpty) {
          return 'Processing';
        }

        return _titleCase(status);
    }
  }

  static Color _statusColor(Order order) {
    final status = order.status
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (status) {
      case 'uploaded':
      case 'prescription_uploaded':
      case 'reviewing':
      case 'under_review':
      case 'processing':
      case 'prescription_reviewing':
        return _BookingPalette.warning;

      case 'test_list_prepared':
      case 'tests_prepared':
      case 'awaiting_user_approval':
      case 'confirmed':
      case 'booking_confirmed':
      case 'assigned':
      case 'agent_assigned':
      case 'assigned_agent':
      case 'agent_out_for_collection':
      case 'out_for_collection':
        return _BookingPalette.primary;

      case 'collected':
      case 'sample_collected':
      case 'testing':
      case 'sample_testing':
      case 'sample_processing':
      case 'report_preparing':
      case 'report_in_making':
        return _BookingPalette.indigo;

      case 'report_ready':
      case 'completed':
      case 'done':
      case 'report_delivered':
        return _BookingPalette.success;

      case 'cancelled':
      case 'canceled':
        return _BookingPalette.danger;

      default:
        return _BookingPalette.muted;
    }
  }

  static String _patientLabel(Order order) {
    final patientName = order.patientName?.trim();

    if (patientName != null && patientName.isNotEmpty) {
      return patientName;
    }

    return 'Self';
  }

  static String _shortOrderId(String orderId) {
    final value = orderId.trim();

    if (value.isEmpty) {
      return 'Order';
    }

    final shortId = value.length > 8 ? value.substring(0, 8) : value;

    return '#$shortId';
  }

  static String _formatDate(DateTime value) {
    return DateFormat('dd MMM, h:mm a').format(value.toLocal());
  }

  static String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }

    final normalized = value.replaceAll(RegExp(r'[_-]+'), ' ');

    return normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _OrderProgressLabel extends StatelessWidget {
  const _OrderProgressLabel({required this.order, required this.isPast});

  final Order order;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final status = order.status
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    final isCancelled = status == 'cancelled' || status == 'canceled';

    final isCompleted =
        status == 'completed' ||
        status == 'done' ||
        status == 'report_delivered';

    if (isCancelled) {
      return const _StaticProgressLabel(
        icon: Icons.close_rounded,
        label: 'Cancelled',
        color: _BookingPalette.danger,
        backgroundColor: Color(0xFFFFF1F3),
      );
    }

    if (isPast || isCompleted) {
      return const _StaticProgressLabel(
        icon: Icons.check_rounded,
        label: 'Completed',
        color: _BookingPalette.success,
        backgroundColor: Color(0xFFECFDF3),
      );
    }

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CompactProcessingPulse(),
        SizedBox(width: 7),
        Text(
          'Processing',
          style: TextStyle(
            color: Color(0xFF15803D),
            fontSize: 12.2,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StaticProgressLabel extends StatelessWidget {
  const _StaticProgressLabel({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12.2,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Compact processing marker used inside each active booking card.
///
/// Only one ripple is shown per cycle:
/// ripple expands → fades completely → pauses → next ripple begins.
///
/// The complete animation is clipped inside an 18×18 area, so it cannot
/// overflow beyond the booking card.
class _CompactProcessingPulse extends StatefulWidget {
  const _CompactProcessingPulse();

  @override
  State<_CompactProcessingPulse> createState() =>
      _CompactProcessingPulseState();
}

class _CompactProcessingPulseState extends State<_CompactProcessingPulse>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF16A34A);

  static const double _waveDurationPart = 0.68;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return SizedBox(
      width: 18,
      height: 18,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!disableAnimations)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final controllerValue = _controller.value;

                  // Last 32% of every cycle is a clean pause.
                  if (controllerValue > _waveDurationPart) {
                    return const SizedBox.shrink();
                  }

                  final progress = controllerValue / _waveDurationPart;

                  final curvedProgress = Curves.easeOutCubic.transform(
                    progress.clamp(0.0, 1.0),
                  );

                  final waveSize = 7 + ((18 - 7) * curvedProgress);

                  final waveOpacity = 0.30 * (1 - curvedProgress);

                  return Opacity(
                    opacity: waveOpacity,
                    child: Container(
                      width: waveSize,
                      height: waveSize,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),

            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderIcon extends StatelessWidget {
  const _OrderIcon({required this.order, required this.isPast});

  final Order order;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final hasPrescription = order.prescriptionImagePath.trim().isNotEmpty;

    final icon = hasPrescription
        ? Icons.description_rounded
        : isPast
        ? Icons.check_circle_rounded
        : Icons.science_rounded;

    final color = isPast ? _BookingPalette.success : _BookingPalette.primary;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _OrderMetaRow extends StatelessWidget {
  const _OrderMetaRow({
    required this.dateText,
    required this.patientText,
    required this.orderId,
  });

  final String dateText;
  final String patientText;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaPill(icon: Icons.schedule_rounded, label: dateText),
        _MetaPill(icon: Icons.person_rounded, label: patientText),
        _MetaPill(icon: Icons.receipt_long_rounded, label: orderId),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEFF3F7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _BookingPalette.softMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _BookingPalette.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum _EmptyBookingsVariant { noBookings, noActiveBookings, noPastBookings }

class _EmptyBookingsState extends StatelessWidget {
  const _EmptyBookingsState({
    required this.variant,
    required this.onUploadPrescription,
    required this.onBookTest,
  });

  final _EmptyBookingsVariant variant;
  final VoidCallback onUploadPrescription;
  final VoidCallback onBookTest;

  @override
  Widget build(BuildContext context) {
    final data = _copyFor(variant);

    final showUploadButton = variant != _EmptyBookingsVariant.noPastBookings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _BookingPalette.border),
        boxShadow: _BookingPalette.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _BookingPalette.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: _BookingPalette.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _BookingPalette.ink,
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _BookingPalette.muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),

          if (showUploadButton) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onUploadPrescription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _BookingPalette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                child: const Text('Upload prescription'),
              ),
            ),
            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: onBookTest,
              style: OutlinedButton.styleFrom(
                foregroundColor: _BookingPalette.primary,
                side: const BorderSide(color: _BookingPalette.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              child: const Text('Book test'),
            ),
          ),
        ],
      ),
    );
  }

  static _EmptyCopy _copyFor(_EmptyBookingsVariant variant) {
    switch (variant) {
      case _EmptyBookingsVariant.noBookings:
        return const _EmptyCopy(
          title: 'No bookings yet',
          subtitle: 'Upload a prescription or book a lab test to get started.',
        );

      case _EmptyBookingsVariant.noActiveBookings:
        return const _EmptyCopy(
          title: 'No active bookings',
          subtitle: 'New bookings and prescription reviews will appear here.',
        );

      case _EmptyBookingsVariant.noPastBookings:
        return const _EmptyCopy(
          title: 'No past bookings',
          subtitle: 'Completed bookings and reports will appear here.',
        );
    }
  }
}

class _EmptyCopy {
  const _EmptyCopy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _OrdersLoadingCard extends StatelessWidget {
  const _OrdersLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading bookings',
              style: TextStyle(
                color: _BookingPalette.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersErrorCard extends StatelessWidget {
  const _OrdersErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _BookingPalette.danger.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: _BookingPalette.danger,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Bookings could not load right now.',
              style: TextStyle(
                color: _BookingPalette.ink,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BookingPalette {
  const _BookingPalette._();

  static const Color background = Color(0xFFFAFBFC);

  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color softMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE6EAF0);

  static const Color primary = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color danger = Color(0xFFE11D48);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.025),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

BoxDecoration _surfaceDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _BookingPalette.border),
    boxShadow: _BookingPalette.cardShadow,
  );
}
