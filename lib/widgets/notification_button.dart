import 'package:flutter/material.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key, this.unreadCount = 0, this.onTap});

  final int unreadCount;
  final VoidCallback? onTap;

  static const Color _deepBlue = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: .04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .03),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: _deepBlue,
              size: 24,
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: unreadCount > 9 ? 18 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              alignment: Alignment.center,
            ),
          ),
      ],
    );
  }
}
