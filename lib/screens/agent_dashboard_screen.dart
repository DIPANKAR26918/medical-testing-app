import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/index.dart';
import '../widgets/index.dart';

/// Agent dashboard screen to manage pending orders
class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  /// Get current agent ID
  String get _agentId => _authService.getUserId() ?? '';

  /// Show success snack bar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snack bar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Assign agent to order
  Future<void> _assignAgentToOrder(Order order) async {
    try {
      await _firestoreService.assignAgent(order.orderId, _agentId);
      _showSuccessSnackBar(
        '${LocalizationKeys.assigned.tr()} - ${order.orderId.substring(0, 8)}',
      );
    } catch (e) {
      _showErrorSnackBar('${LocalizationKeys.error.tr()}: $e');
    }
  }

  /// Update order status
  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await _firestoreService.updateOrderStatus(order.orderId, newStatus);
      _showSuccessSnackBar(LocalizationKeys.success.tr());
    } catch (e) {
      _showErrorSnackBar('${LocalizationKeys.error.tr()}: $e');
    }
  }

  /// Get next available status
  String _getNextStatus(String currentStatus) {
    const statusFlow = {
      'uploaded': 'confirmed',
      'confirmed': 'assigned',
      'assigned': 'collected',
      'collected': 'testing',
      'testing': 'completed',
    };
    return statusFlow[currentStatus] ?? 'completed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text('Pending Orders'), centerTitle: true),
      body: StreamBuilder<List<Order>>(
        stream: _firestoreService.getPendingOrders(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoadingWidget(message: LocalizationKeys.loading.tr());
          }

          // Error state
          if (snapshot.hasError) {
            return AppErrorWidget(
              message: '${LocalizationKeys.error.tr()}: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return AppEmptyWidget(
              icon: Icons.inbox,
              message: 'No pending orders available',
            );
          }

          // Display orders
          final orders = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(order);
              },
            ),
          );
        },
      ),
    );
  }

  /// Build order card widget
  Widget _buildOrderCard(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${LocalizationKeys.orderId.tr()} #${order.orderId.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeXLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingSmall),
                      Text(
                        AppHelpers.formatDateTime(order.createdAt),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: order.status, isLarge: true),
              ],
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            const Divider(),
            const SizedBox(height: AppTheme.paddingMedium),

            // Prescription Image
            if (order.prescriptionImagePath.isNotEmpty)
              FutureBuilder<String>(
                future: _storageService.createSignedUrl(
                  order.prescriptionImagePath,
                  expiresInSeconds: 3600,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusLarge,
                        ),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusLarge,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 32),
                      ),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusLarge,
                    ),
                    child: Image.network(
                      snapshot.data!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusLarge,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 32),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusLarge,
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Order Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Test Count
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationKeys.testList.tr(),
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: AppTheme.paddingSmall),
                        Text(
                          '${order.testList.length}',
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.paddingMedium),

                // Price
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationKeys.price.tr(),
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: AppTheme.paddingSmall),
                        Text(
                          'BDT ${order.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Test List Display
            if (order.testList.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tests Required:',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Wrap(
                      spacing: AppTheme.paddingSmall,
                      runSpacing: AppTheme.paddingSmall,
                      children: order.testList
                          .map(
                            (test) => Chip(
                              label: Text(test),
                              backgroundColor: Colors.blue[100],
                              labelStyle: const TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Action Buttons
            Row(
              children: [
                // Assign Button
                if (order.agentId == null || order.agentId!.isEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _assignAgentToOrder(order),
                      icon: const Icon(Icons.assignment),
                      label: const Text('Assign to Me'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.paddingMedium,
                        ),
                      ),
                    ),
                  ),

                if (order.agentId != null && order.agentId!.isNotEmpty)
                  const SizedBox(width: AppTheme.paddingSmall),

                // Update Status Button
                if (order.agentId == _agentId)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final nextStatus = _getNextStatus(order.status);
                        _updateOrderStatus(order, nextStatus);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Update Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.paddingMedium,
                        ),
                      ),
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
