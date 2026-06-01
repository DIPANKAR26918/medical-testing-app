import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/index.dart';
import '../widgets/index.dart';

/// Test status tracking screen similar to Amazon order tracking
class TestStatusScreen extends StatefulWidget {
  const TestStatusScreen({super.key});

  @override
  State<TestStatusScreen> createState() => _TestStatusScreenState();
}

class _TestStatusScreenState extends State<TestStatusScreen> {
  late FirestoreService _firestoreService;
  late AuthService _authService;
  late String _userId;
  final int _currentNavIndex = 2;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _authService = AuthService();
    _userId = _authService.getUserId() ?? '';
  }

  /// Handle bottom navigation taps
  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/upload');
        break;
      case 2:
        // Already on test status screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Test Status'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () async {
                  await _authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/auth');
                  }
                },
                child: Text(AppStrings.logout),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Order>>(
        stream: _firestoreService.getUserOrders(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoadingWidget(message: AppStrings.loading);
          }

          if (snapshot.hasError) {
            return AppErrorWidget(
              message: '${AppStrings.error}: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return AppEmptyWidget(
              message: 'No test orders yet',
              icon: Icons.assignment,
              onAction: () {
                Navigator.of(context).pushReplacementNamed('/upload');
              },
              actionLabel: AppStrings.uploadPrescription,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return TestStatusCard(order: order);
            },
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

/// Test status card showing tracking timeline
class TestStatusCard extends StatelessWidget {
  final Order order;

  const TestStatusCard({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    final status = order.status.toLowerCase();
    final isCompleted = status == 'completed';
    final isProcessing = status == 'processing';
    final isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderId.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${order.createdAt.toString().split('.')[0]}',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Timeline
            _buildTimeline(isCompleted, isProcessing, isPending),

            const SizedBox(height: AppTheme.paddingMedium),

            // Test details
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingSmall),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tests Ordered:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.testList.isNotEmpty
                        ? order.testList.join(', ')
                        : 'Not specified',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(bool isCompleted, bool isProcessing, bool isPending) {
    return Column(
      children: [
        // Step 1: Order Placed
        _buildTimelineStep('Order Placed', true, Icons.check_circle),
        _buildTimelineConnector(true),

        // Step 2: Processing
        _buildTimelineStep(
          'Processing',
          isProcessing || isCompleted,
          isCompleted ? Icons.check_circle : Icons.pending_actions,
        ),
        _buildTimelineConnector(isCompleted),

        // Step 3: Completed
        _buildTimelineStep('Completed', isCompleted, Icons.check_circle),
      ],
    );
  }

  Widget _buildTimelineStep(String label, bool isActive, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: isActive ? AppTheme.lightGreen : AppTheme.textLight,
          size: 24,
        ),
        const SizedBox(width: AppTheme.paddingSmall),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppTheme.lightGreen : AppTheme.textLight,
            fontSize: AppTheme.fontSizeSmall,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector(bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 24,
        width: 24,
        child: Center(
          child: Container(
            width: 2,
            height: 20,
            color: isActive ? AppTheme.lightGreen : AppTheme.borderColor,
          ),
        ),
      ),
    );
  }
}
