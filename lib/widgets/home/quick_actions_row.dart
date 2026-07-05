import 'package:flutter/material.dart';

import 'home_constants.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    this.onSearchTap,
    this.onUploadTap,
    this.onTrackTap,
  });

  final VoidCallback? onSearchTap;
  final VoidCallback? onUploadTap;
  final VoidCallback? onTrackTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.search_rounded,
            title: 'Search tests',
            subtitle: 'Find fast',
            color: HomeColors.blueAccent,
            onTap: onSearchTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.upload_file_outlined,
            title: 'Upload Rx',
            subtitle: 'Get help',
            color: HomeColors.orange,
            onTap: onUploadTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.receipt_long_rounded,
            title: 'Track order',
            subtitle: 'Live status',
            color: HomeColors.orange,
            onTap: onTrackTap,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .96),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeTextStyles.badgeLabel,
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeTextStyles.badgeCaption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
