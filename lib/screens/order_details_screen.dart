import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fb;
import 'package:easy_localization/easy_localization.dart';
import '../models/index.dart';
import '../utils/index.dart';
import '../widgets/index.dart';

/// Screen displaying detailed information about an order
class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(LocalizationKeys.orderDetails.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationKeys.status.tr(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  StatusBadge(status: order.status, isLarge: true),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Timeline / Tracking
            Text(
              'Tracking',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.timeline.isEmpty
                    ? [
                        Text(
                          'No tracking available',
                          style: const TextStyle(color: AppTheme.textLight),
                        ),
                      ]
                    : order.timeline.map((entry) {
                        final status = entry['status'] ?? '';
                        final message = entry['message'] ?? '';
                        final ts = entry['timestamp'];
                        DateTime time;
                        try {
                          if (ts is String) {
                            time = DateTime.parse(ts);
                          } else if (ts is fb.Timestamp) {
                            time = ts.toDate();
                          } else {
                            time = DateTime.now();
                          }
                        } catch (_) {
                          time = DateTime.now();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.paddingSmall,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: AppTheme.paddingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      status.tr(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppTheme.paddingXSmall,
                                    ),
                                    Text(
                                      message,
                                      style: const TextStyle(
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppHelpers.formatDateTime(time),
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: AppTheme.fontSizeSmall,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Order Information
            _buildInfoCard(
              title: LocalizationKeys.orderId.tr(),
              value: '#${order.orderId}',
              icon: Icons.receipt,
            ),
            const SizedBox(height: AppTheme.paddingSmall),

            _buildInfoCard(
              title: LocalizationKeys.created.tr(),
              value: AppHelpers.formatDateTime(order.createdAt),
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: AppTheme.paddingSmall),

            _buildInfoCard(
              title: LocalizationKeys.userId.tr(),
              value: order.userId,
              icon: Icons.person,
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Prescription Image
            if (order.prescriptionImageUrl.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationKeys.prescription.tr(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusLarge,
                    ),
                    child: Image.network(
                      order.prescriptionImageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 250,
                          color: AppTheme.backgroundColor,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: AppTheme.backgroundColor,
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                ],
              ),

            // Test List
            Text(
              LocalizationKeys.testList.tr(),
              style: const TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.testList.isEmpty
                    ? [
                        Text(
                          LocalizationKeys.noTestsAssigned.tr(),
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: AppTheme.fontSizeMedium,
                          ),
                        ),
                      ]
                    : order.testList
                          .map(
                            (test) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.paddingSmall,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryColor,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.paddingMedium),
                                  Expanded(
                                    child: Text(
                                      test,
                                      style: const TextStyle(
                                        fontSize: AppTheme.fontSizeMedium,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
              ),
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Price and Agent Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LocalizationKeys.price.tr(),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textLight,
                        ),
                      ),
                      Text(
                        AppHelpers.formatCurrency(order.price),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.paddingMedium,
                    ),
                    child: const Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LocalizationKeys.agentName.tr(),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textLight,
                        ),
                      ),
                      Text(
                        order.agentId?.isNotEmpty == true
                            ? order.agentId!
                            : LocalizationKeys.notAssigned.tr(),
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: order.agentId?.isNotEmpty == true
                              ? AppTheme.textDark
                              : AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingXLarge),
          ],
        ),
      ),
    );
  }

  /// Build info card widget
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
