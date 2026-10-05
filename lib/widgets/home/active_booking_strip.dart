import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import 'home_constants.dart';

class ActiveBookingStrip extends StatelessWidget {
  const ActiveBookingStrip({
    required this.orders,
    required this.onOrderTap,
    super.key,
  });

  final List<Order> orders;
  final ValueChanged<Order> onOrderTap;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Semantics(
            header: true,
            child: const Text(
              'Your Active Orders',
              style: HomeTextStyles.sectionTitle,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 102,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _ActiveBookingCard(
                order: order,
                onTap: () => onOrderTap(order),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActiveBookingCard extends StatelessWidget {
  const _ActiveBookingCard({
    required this.order,
    required this.onTap,
  });

  final Order order;
  final VoidCallback onTap;

  String _statusLabel(String status) {
    switch (status) {
      case 'uploaded':
        return 'Under Review';
      case 'confirmed':
        return 'Confirmed';
      case 'assigned':
        return 'Agent Assigned';
      case 'collected':
        return 'Sample Collected';
      case 'testing':
        return 'Processing';
      case 'completed':
        return 'Report Ready';
      case 'payment_pending':
        return 'Payment Pending';
      default:
        if (status.isEmpty) return '';
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'assigned':
        return HomeColors.statusGreen;
      case 'collected':
      case 'testing':
        return HomeColors.statusAmber;
      case 'completed':
        return HomeColors.primary;
      default:
        return HomeColors.textMuted;
    }
  }

  bool _isInProgress(String status) {
    return ['confirmed', 'assigned', 'collected', 'testing'].contains(status);
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(order.status);
    final statusColor = _statusColor(order.status);
    final inProgress = _isInProgress(order.status);
    
    String testNameText = 'Prescription Order';
    if (order.testList.isNotEmpty) {
      if (order.testList.length == 1) {
        testNameText = order.testList.first;
      } else {
        testNameText = '${order.testList.first} + ${order.testList.length - 1} more';
      }
    }

    final dateStr = DateFormat('MMM d, yyyy').format(order.createdAt);

    return Semantics(
      button: true,
      label: 'Order status: $statusLabel for $testNameText. Booked on $dateStr.',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: statusColor,
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (inProgress) ...[
                        const _PulsingDot(),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    testNameText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: HomeColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Booked on $dateStr',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: HomeColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: (1.5 - _animation.value).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: HomeColors.statusGreen,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
