import 'package:flutter/material.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key, this.unreadCount = 0, this.onTap});

  final int unreadCount;
  final VoidCallback? onTap;

  static const Color _ink = Color(0xFF172521);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE7E2)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x091A332E),
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
            right: 7,
            top: 7,
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
