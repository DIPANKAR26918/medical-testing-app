import 'package:flutter/material.dart';

import '../location_card.dart';
import '../notification_button.dart';
import '../search_bar.dart';
import 'home_constants.dart';

/// The primary clinical entry point on the Testified home screen.
///
/// Location, greeting and search live on one high-contrast surface so the
/// first screenful has a single, obvious hierarchy on compact phones.
class HomeTopExperience extends StatelessWidget {
  const HomeTopExperience({
    required this.firstName,
    required this.hour,
    required this.onNotificationTap,
    required this.onSearch,
    super.key,
  });

  final String firstName;
  final int hour;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearch;

  String get _salutation {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = firstName.isEmpty
        ? _salutation
        : '$_salutation, $firstName';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1758C9), Color(0xFF2874EA)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x242563EB),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -74,
            top: 78,
            child: _HeaderOrb(size: 220, opacity: .07),
          ),
          const Positioned(
            left: -70,
            bottom: -92,
            child: _HeaderOrb(size: 190, opacity: .045),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UtilityRow(onNotificationTap: onNotificationTap),
                const SizedBox(height: 25),
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.45,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'What would you like to take care of today?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: 12.8,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 19),
                HomeSearchBar(onTap: onSearch),
                const SizedBox(height: 17),
                const _TrustStrip(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityRow extends StatelessWidget {
  const _UtilityRow({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: LocationCard()),
        const SizedBox(width: 10),
        NotificationButton(unreadCount: 0, onTap: onNotificationTap),
      ],
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _TrustItem(
            icon: Icons.verified_rounded,
            label: 'Verified labs',
          ),
        ),
        _TrustDivider(),
        Expanded(
          child: _TrustItem(
            icon: Icons.home_work_outlined,
            label: 'Home collection',
          ),
        ),
        _TrustDivider(),
        Expanded(
          child: _TrustItem(
            icon: Icons.lock_outline_rounded,
            label: 'Private by design',
          ),
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.2,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white.withValues(alpha: .24),
    );
  }
}

class _HeaderOrb extends StatelessWidget {
  const _HeaderOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
