import 'package:flutter/material.dart';

import '../../models/index.dart';
import '../../services/index.dart';
import 'home_constants.dart';

class RecentOrdersSection extends StatelessWidget {
  const RecentOrdersSection({super.key, required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Your Recent Orders',
                style: HomeTextStyles.sectionTitle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildOrdersList(context),
      ],
    );
  }

  Widget _buildOrdersList(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return _EmptyStateCard(
        title: 'Log in to see your orders',
        subtitle: 'Track collections, reports, and past bookings here.',
        icon: Icons.lock_outline_rounded,
      );
    }

    final firestoreService = FirestoreService();

    return StreamBuilder<List<Order>>(
      stream: firestoreService.getUserOrders(userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return _EmptyStateCard(
            title: 'No recent orders yet',
            subtitle: 'Book your first test and keep everything in one place.',
            icon: Icons.receipt_long_rounded,
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _OrderCard(order: order);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.border),
        boxShadow: [
          BoxShadow(
            color: HomeColors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: HomeColors.blueAccent.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: HomeColors.blueAccent,
          ),
        ),
        title: Text(
          order.testList.isEmpty ? 'Prescription review' : 'Test booking',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: HomeColors.deepBlue,
          ),
        ),
        subtitle: Text(
          _readableStatus(order.status),
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: HomeColors.textHint,
        ),
        onTap: () =>
            Navigator.pushNamed(context, '/order-details', arguments: order),
      ),
    );
  }

  String _readableStatus(String value) {
    final words = value
        .trim()
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'Update pending';

    final text = words.join(' ');
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HomeColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: HomeColors.blueAccent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: HomeColors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.2,
                    fontWeight: FontWeight.w900,
                    color: HomeColors.deepBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.7,
                    color: Colors.grey.shade600,
                    height: 1.25,
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
