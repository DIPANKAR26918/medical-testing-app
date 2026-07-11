import 'package:flutter/material.dart';
import '../utils/index.dart';

/// Status badge widget to display order status
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isLarge;

  const StatusBadge({required this.status, this.isLarge = false, super.key});

  /// Get color based on status
  Color _getStatusColor() {
    switch (status) {
      case 'uploaded':
        return const Color(0xFFFFC107); // Amber
      case 'processing':
        return const Color(0xFFFFC107); // Amber
      case 'confirmed':
        return const Color(0xFF2196F3); // Blue
      case 'booking_requested':
        return const Color(0xFFFF9800); // Orange
      case 'booking_confirmed':
        return const Color(0xFF2196F3); // Blue
      case 'assigned':
        return const Color(0xFF9C27B0); // Purple
      case 'collected':
        return const Color(0xFFFF9800); // Orange
      case 'testing':
        return const Color(0xFFF44336); // Red
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF757575); // Gray
    }
  }

  /// Get icon based on status
  IconData _getStatusIcon() {
    switch (status) {
      case 'uploaded':
        return Icons.cloud_upload;
      case 'processing':
        return Icons.pending_actions;
      case 'confirmed':
        return Icons.check_circle;
      case 'booking_requested':
        return Icons.event_note;
      case 'booking_confirmed':
        return Icons.event_available;
      case 'assigned':
        return Icons.assignment;
      case 'collected':
        return Icons.local_shipping;
      case 'testing':
        return Icons.science;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final icon = _getStatusIcon();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? AppTheme.paddingMedium : AppTheme.paddingSmall,
        vertical: isLarge ? AppTheme.paddingSmall : AppTheme.paddingXSmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isLarge ? 20 : 16),
          const SizedBox(width: AppTheme.paddingSmall),
          Text(
            AppStrings.statusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: isLarge
                  ? AppTheme.fontSizeMedium
                  : AppTheme.fontSizeSmall,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
