import 'package:flutter/material.dart';

import 'home/home_constants.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key, this.unreadCount = 0, this.onTap});

  final int unreadCount;
  final VoidCallback? onTap;

  static const Color _ink = HomeColors.textPrimary;

  @override
  Widget build(BuildContext context) {
    final badgeLabel = unreadCount > 9 ? '9+' : '$unreadCount';

    return Semantics(
      button: true,
      label: unreadCount > 0
          ? 'Notifications, $unreadCount unread'
          : 'Notifications',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HomeColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x07111B30),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: _ink,
                  size: 22,
                ),
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
