import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../utils/app_time.dart';
import '../utils/app_theme.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({
    required this.onBookNewTest,
    this.onUploadPrescription,
    this.ordersStream,
    super.key,
  });

  final VoidCallback onBookNewTest;
  final VoidCallback? onUploadPrescription;
  final Stream<List<Order>>? ordersStream;

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
    final providedOrdersStream = widget.ordersStream;
    if (providedOrdersStream != null) {
      return _buildOrdersStream(providedOrdersStream);
    }

    final userId = _authService.getUserId();

    if (userId == null || userId.isEmpty) {
      return _buildBody(orders: const <Order>[], isLoading: false);
    }

    return _buildOrdersStream(_firestoreService.getUserOrders(userId));
  }

  Widget _buildOrdersStream(Stream<List<Order>> stream) {
    return StreamBuilder<List<Order>>(
      stream: stream,
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
    final newestFirstOrders = List<Order>.of(orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final activeOrders = newestFirstOrders
        .where((order) => !_isPastOrder(order))
        .toList();

    final pastOrders = newestFirstOrders.where(_isPastOrder).toList();

    final tabOrders = _showActiveOrders ? activeOrders : pastOrders;
    final hasAnyOrder = orders.isNotEmpty;

    return ColoredBox(
      color: _BookingPalette.background,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 116),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _BookingsHeader(onBookNewTest: widget.onBookNewTest),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _BookingTabs(
              selectedIndex: _selectedTab,
              onChanged: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _OrdersLoadingCard(),
            ),
          ] else if (error != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _OrdersErrorCard(
                onRetry: () {
                  setState(() {});
                },
              ),
            ),
          ] else if (tabOrders.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _EmptyBookingsState(
                variant: _emptyStateVariant(hasAnyOrder: hasAnyOrder),
                onUploadPrescription: _openUploadPrescription,
                onBookTest: widget.onBookNewTest,
              ),
            ),
          ] else ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _OrdersListSurface(
                key: ValueKey<int>(_selectedTab),
                orders: tabOrders,
                isPastOrder: _isPastOrder,
                onOrderTap: _openOrderDetails,
              ),
            ),
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
                  fontSize: 27,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.55,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Track each test from booking to report',
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
          height: 40,
          child: ElevatedButton.icon(
            onPressed: onBookNewTest,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Book test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _BookingPalette.primarySoft,
              foregroundColor: _BookingPalette.primary,
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
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _BookingPalette.border),
        ),
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
          Expanded(
            child: _TabButton(
              label: 'History',
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
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? _BookingPalette.primary
                      : _BookingPalette.muted,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: selected ? 36 : 0,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: _BookingPalette.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersListSurface extends StatelessWidget {
  const _OrdersListSurface({
    required this.orders,
    required this.isPastOrder,
    required this.onOrderTap,
    super.key,
  });

  final List<Order> orders;
  final bool Function(Order) isPastOrder;
  final ValueChanged<Order> onOrderTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('bookings-flat-list'),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border.symmetric(
          horizontal: BorderSide(color: _BookingPalette.divider),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < orders.length; index++) ...[
            if (index > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 104,
                endIndent: 16,
                color: _BookingPalette.divider,
              ),
            _OrderRow(
              order: orders[index],
              isPast: isPastOrder(orders[index]),
              onTap: () => onOrderTap(orders[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.isPast,
    required this.onTap,
  });

  final Order order;
  final bool isPast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final needsApproval = _needsApproval(order);
    final title = titleFor(order);
    final dateText = _formatDate(order.createdAt);
    final patientText = _patientLabel(order);
    final status = _OrderStatusPresentation.forOrder(
      order,
      isPast: isPast,
    );
    final patientLabel = patientText == 'You' ? 'For you' : 'For $patientText';

    return Semantics(
      key: ValueKey<String>('booking-row-${order.orderId}'),
      button: true,
      label: '$title. ${status.label}. Booked $dateText. '
          'Patient $patientText.',
      hint: needsApproval
          ? 'Review and confirm the suggested tests'
          : 'View booking details',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: needsApproval
            ? _BookingPalette.primarySoft.withValues(alpha: 0.45)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _BookingThumbnail(order: order, title: title),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _BookingPalette.ink,
                          fontSize: 15,
                          height: 1.28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _OrderProgressLabel(status: status),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$dateText  •  $patientLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _BookingPalette.muted,
                                fontSize: 11.3,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: needsApproval
                      ? _BookingPalette.primary
                      : _BookingPalette.softMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String titleFor(Order order) {
    if (_needsApproval(order)) {
      return 'Your test list is ready';
    }

    final hasPrescription = order.prescriptionImagePath.trim().isNotEmpty;

    final tests = order.testList
        .map((test) => test.trim())
        .where((test) => test.isNotEmpty)
        .toList();

    if (hasPrescription && tests.isEmpty) {
      return 'Prescription review';
    }

    if (tests.length == 1) {
      return tests.first;
    }

    if (tests.length > 1) {
      return '${tests.first} +${tests.length - 1} more';
    }

    if (hasPrescription) {
      return 'Prescription uploaded';
    }

    return 'Lab test booking';
  }

  static String _patientLabel(Order order) {
    final patientName = order.patientName?.trim();

    if (patientName != null && patientName.isNotEmpty) {
      return patientName;
    }

    return 'You';
  }

  static String _formatDate(DateTime value) {
    return AppTime.formatKolkata(value, pattern: 'dd MMM · h:mm a');
  }

  static bool _needsApproval(Order order) {
    return order.isPrescriptionBooking &&
        _normalizeStatus(order.status) == 'awaiting_user_approval';
  }

  static String _normalizeStatus(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  }
}

class _BookingThumbnail extends StatelessWidget {
  const _BookingThumbnail({required this.order, required this.title});

  final Order order;
  final String title;

  @override
  Widget build(BuildContext context) {
    final prescription = order.isPrescriptionBooking;

    return Container(
      width: 72,
      height: 72,
      padding: EdgeInsets.all(prescription ? 8 : 14),
      decoration: BoxDecoration(
        color: prescription
            ? const Color(0xFFF7F1E8)
            : _BookingPalette.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: prescription
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/prescription_upload_icon.jpeg',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.description_outlined,
                  color: _BookingPalette.primary,
                  size: 30,
                ),
              ),
            )
          : MedicalCategoryIllustration(
              category: title,
              color: _BookingPalette.primary,
            ),
    );
  }
}

class _OrderProgressLabel extends StatelessWidget {
  const _OrderProgressLabel({required this.status});

  final _OrderStatusPresentation status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          status.label,
          style: TextStyle(
            color: status.color,
            fontSize: 11.8,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _OrderStatusPresentation {
  const _OrderStatusPresentation({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  factory _OrderStatusPresentation.forOrder(
    Order order, {
    required bool isPast,
  }) {
    final status = order.status
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    if (order.isPrescriptionBooking && status == 'awaiting_user_approval') {
      return const _OrderStatusPresentation(
        label: 'Action needed',
        color: _BookingPalette.primary,
      );
    }

    if (status == 'cancelled' || status == 'canceled') {
      return const _OrderStatusPresentation(
        label: 'Cancelled',
        color: _BookingPalette.danger,
      );
    }

    if (isPast ||
        status == 'completed' ||
        status == 'done' ||
        status == 'report_delivered') {
      return const _OrderStatusPresentation(
        label: 'Completed',
        color: _BookingPalette.success,
      );
    }

    return switch (status) {
      'uploaded' || 'processing' => const _OrderStatusPresentation(
        label: 'In progress',
        color: _BookingPalette.statusActive,
      ),
      'confirmed' => const _OrderStatusPresentation(
        label: 'Confirmed',
        color: _BookingPalette.success,
      ),
      'booking_requested' => const _OrderStatusPresentation(
        label: 'Confirming',
        color: _BookingPalette.statusActive,
      ),
      'booking_confirmed' => const _OrderStatusPresentation(
        label: 'Confirmed',
        color: _BookingPalette.success,
      ),
      'assigned' => const _OrderStatusPresentation(
        label: 'Agent assigned',
        color: _BookingPalette.statusActive,
      ),
      'agent_out_for_collection' => const _OrderStatusPresentation(
        label: 'On the way',
        color: _BookingPalette.statusActive,
      ),
      'collected' || 'sample_collected' => const _OrderStatusPresentation(
        label: 'Sample collected',
        color: _BookingPalette.statusActive,
      ),
      'sample_out_for_testing' ||
      'sample_received_at_lab' => const _OrderStatusPresentation(
        label: 'At the lab',
        color: _BookingPalette.statusActive,
      ),
      'testing' || 'sample_processing' => const _OrderStatusPresentation(
        label: 'Lab processing',
        color: _BookingPalette.statusActive,
      ),
      'sample_processed' || 'report_ready' =>
        const _OrderStatusPresentation(
          label: 'Report ready',
          color: _BookingPalette.success,
        ),
      'report_out_for_delivery' => const _OrderStatusPresentation(
          label: 'Report on the way',
          color: _BookingPalette.statusActive,
        ),
      _ => const _OrderStatusPresentation(
        label: 'In progress',
        color: _BookingPalette.statusActive,
      ),
    };
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
          title: 'No booking history',
          subtitle: 'Completed and cancelled bookings will appear here.',
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

class _BookingPalette {
  const _BookingPalette._();

  static const Color background = Color(0xFFF7F9FC);

  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF6B778C);
  static const Color softMuted = Color(0xFFA5AFBF);
  static const Color border = Color(0xFFE3E9F2);
  static const Color divider = Color(0xFFEDF1F6);

  static const Color primary = Color(0xFF2563EB);
  static const Color primarySoft = Color(0xFFEEF4FF);
  static const Color statusActive = Color(0xFF4E6F9F);
  static const Color success = Color(0xFF2F855A);
  static const Color danger = Color(0xFFCB3A53);

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
