import 'package:flutter/material.dart';

import '../location_card.dart';
import '../notification_button.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    this.onNotificationTap,
    this.notificationCount = 0,
  });

  final VoidCallback? onNotificationTap;
  final int notificationCount;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning \u2600\ufe0f';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Let\'s take care of your health',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: .80),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: LocationCard()),
              const SizedBox(width: 10),
              NotificationButton(
                unreadCount: notificationCount,
                onTap: onNotificationTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
