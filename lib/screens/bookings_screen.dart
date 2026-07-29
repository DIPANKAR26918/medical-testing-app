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
    this.previewOrders,
    super.key,
  });

  final VoidCallback onBookNewTest;
  final VoidCallback? onUploadPrescription;

  /// Optional static data for previews and deterministic layout tests.
  final List<Order>? previewOrders;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  AuthService? _authService;
  FirestoreService? _firestoreService;

  @override
  Widget build(BuildContext context) {
    final previewOrders = widget.previewOrders;
    if (previewOrders != null) {
      return _buildBody(orders: previewOrders, isLoading: false);
    }

    final userId = (_authService ??= AuthService()).getUserId();

    if (userId == null || userId.isEmpty) {
      return _buildBody(orders: const <Order>[], isLoading: false);
    }

    return _buildOrdersStream(
      (_firestoreService ??= FirestoreService()).getUserOrders(userId),
    );
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

    return ColoredBox(
      color: Colors.white,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 116),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _BookingsHeader(onBookNewTest: widget.onBookNewTest),
          ),
          const SizedBox(height: 28),
          if (isLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _OrdersLoadingState(),
            ),
          ] else if (error != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _OrdersErrorState(
                onRetry: () {
                  setState(() {});
                },
              ),
            ),
          ] else if (newestFirstOrders.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _EmptyBookingsState(
                onUploadPrescription: _openUploadPrescription,
                onBookTest: widget.onBookNewTest,
              ),
            ),
          ] else ...[
            _OrdersListSurface(
              orders: newestFirstOrders,
              isPastOrder: _isPastOrder,
              onOrderTap: _openOrderDetails,
            ),
          ],
        ],
      ),
    );
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
          child: Text(
            'My bookings',
            style: TextStyle(
              color: _BookingPalette.ink,
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.65,
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 48,
          height: 48,
          child: Tooltip(
            message: 'Book a new test',
            child: Semantics(
              button: true,
              label: 'Book a new test',
              child: Material(
                color: _BookingPalette.primarySoft,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onBookNewTest,
                  borderRadius: BorderRadius.circular(16),
                  child: const Icon(
                    Icons.add_rounded,
                    color: _BookingPalette.primary,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
    return Column(
      key: const ValueKey('bookings-flat-list'),
      children: [
        for (var index = 0; index < orders.length; index++) ...[
          if (index > 0)
            const Divider(
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
              color: _BookingPalette.divider,
            ),
          _OrderRow(
            order: orders[index],
            isPast: isPastOrder(orders[index]),
            onTap: () => onOrderTap(orders[index]),
          ),
        ],
      ],
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
    final statusHeadline = '${status.label} · $dateText';

    return Semantics(
      key: ValueKey<String>('booking-row-${order.orderId}'),
      button: true,
      label: '$statusHeadline. $title. Patient $patientText.',
      hint: needsApproval
          ? 'Review and confirm the suggested tests'
          : 'View booking details',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _BookingThumbnail(order: order, title: title),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusHeadline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.18,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '$title  •  $patientLabel',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _BookingPalette.muted,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
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
    return AppTime.formatKolkata(value, pattern: 'dd MMM');
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
      width: 76,
      height: 76,
      padding: EdgeInsets.all(prescription ? 8 : 15),
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

    if (status == 'payment_pending') {
      return _OrderStatusPresentation(
        label: order.paymentStatus == 'failed'
            ? 'Payment failed'
            : 'Payment pending',
        color: order.paymentStatus == 'failed'
            ? _BookingPalette.danger
            : _BookingPalette.primary,
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

class _EmptyBookingsState extends StatelessWidget {
  const _EmptyBookingsState({
    required this.onUploadPrescription,
    required this.onBookTest,
  });

  final VoidCallback onUploadPrescription;
  final VoidCallback onBookTest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 38, 12, 0),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _BookingPalette.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: _BookingPalette.primary,
              size: 31,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No bookings yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _BookingPalette.ink,
              fontSize: 19,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a prescription or book a lab test to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _BookingPalette.muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 48,
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
          SizedBox(
            width: double.infinity,
            height: 48,
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
}

class _OrdersLoadingState extends StatelessWidget {
  const _OrdersLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Row(
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

class _OrdersErrorState extends StatelessWidget {
  const _OrdersErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
}
