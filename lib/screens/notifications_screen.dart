import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../utils/app_time.dart';
import '../widgets/home/home_constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Set<String> _allowedRoutes = {
    '/home',
    '/search',
    '/all-categories',
    '/upload',
    '/test-status',
  };

  final NotificationService _notifications = NotificationService.instance;
  late final Stream<List<AppNotification>> _notificationStream;
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _notificationStream = _notifications.watchNotifications();
  }

  Future<void> _markAllRead() async {
    if (_isMarkingAllRead) return;

    setState(() => _isMarkingAllRead = true);
    try {
      await _notifications.markAllRead();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark notifications as read.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (notification.isUnread) {
      try {
        await _notifications.markRead(notification.id);
      } catch (_) {
        // Opening the related content is still useful if the read update fails.
      }
    }

    if (!mounted) return;
    final route = notification.data['route']?.toString();
    if (route == null || !_allowedRoutes.contains(route)) return;

    if (route == '/home') {
      final tabIndex =
          int.tryParse(
            notification.data['tab_index']?.toString() ??
                notification.data['tabIndex']?.toString() ??
                '',
          ) ??
          1;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {'tabIndex': tabIndex.clamp(0, 3).toInt()},
      );
      return;
    }

    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        backgroundColor: HomeColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 4,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: HomeColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -.25,
          ),
        ),
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream: _notificationStream,
            builder: (context, snapshot) {
              final hasUnread =
                  snapshot.data?.any((notification) => notification.isUnread) ??
                  false;
              if (!hasUnread) return const SizedBox.shrink();

              return TextButton(
                onPressed: _isMarkingAllRead ? null : _markAllRead,
                child: _isMarkingAllRead
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Mark all read'),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const _NotificationMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Updates are unavailable',
              body: 'Check your connection and try again in a moment.',
            );
          }

          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return const _NotificationMessage(
              icon: Icons.notifications_none_rounded,
              title: 'You’re all caught up',
              body: 'Booking, collection and report updates will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () => _openNotification(notification),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  IconData get _icon {
    return switch (notification.kind) {
      'report' || 'report_ready' => Icons.description_rounded,
      'booking' || 'order_update' => Icons.event_available_rounded,
      'collection' => Icons.home_work_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final unread = notification.isUnread;

    return Material(
      color: unread ? const Color(0xFFF4F8FF) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread ? const Color(0xFFBDD3FA) : HomeColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: unread
                      ? const Color(0xFFE4EEFF)
                      : const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, size: 22, color: HomeColors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: HomeColors.textPrimary,
                              fontSize: 14.5,
                              height: 1.25,
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: HomeColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        color: HomeColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      AppTime.formatKolkata(
                        notification.createdAt,
                        pattern: 'd MMM, h:mm a',
                        includeTimeZone: true,
                      ),
                      style: const TextStyle(
                        color: HomeColors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: HomeColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HomeColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HomeColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
