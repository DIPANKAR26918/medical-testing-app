import 'package:flutter/material.dart';

import 'location_card.dart';
import 'notification_button.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.onNotificationTap,
    this.notificationCount = 0,
  });

  final VoidCallback? onNotificationTap;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: LocationCard()),
        const SizedBox(width: 10),
        NotificationButton(
          unreadCount: notificationCount,
          onTap: onNotificationTap,
        ),
      ],
    );
  }
}
