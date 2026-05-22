import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/index.dart';
import '../utils/index.dart';
import 'status_badge.dart';

/// Order card widget to display order in list
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderCard({required this.order, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.paddingMedium),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.paddingSmall),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.science,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: AppTheme.paddingSmall),
                          Expanded(
                            child: Text(
                              '${order.testList.length} ${LocalizationKeys.testList.tr()}',
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.paddingMedium),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.paddingSmall),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.currency_rupee,
                            color: AppTheme.lightGreen,
                            size: 18,
                          ),
                          const SizedBox(width: AppTheme.paddingSmall),
                          Text(
                            AppHelpers.formatCurrency(order.price),
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.lightGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
