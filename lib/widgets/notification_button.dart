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
            width: 58,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: .5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: _deepBlue,
                  size: 22,
                ),
                if (unreadCount == 0) ...[
                  const SizedBox(width: 3),
                  const Text(
                    '0',
                    style: TextStyle(
                      color: _deepBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
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
