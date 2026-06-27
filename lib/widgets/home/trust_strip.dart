import 'package:flutter/material.dart';

import 'home_constants.dart';

class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MiniTrustCard(
            icon: Icons.verified_outlined,
            title: 'NABL verified',
            subtitle: 'Reliable labs only',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniTrustCard(
            icon: Icons.timer_outlined,
            title: 'Fast slot',
            subtitle: 'Pick a 60 min window',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniTrustCard(
            icon: Icons.lock_outlined,
            title: 'Private by default',
            subtitle: 'Secure reports & data',
          ),
        ),
      ],
    );
  }
}

class _MiniTrustCard extends StatelessWidget {
  const _MiniTrustCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: HomeColors.teal.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: HomeColors.teal),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeTextStyles.badgeLabel,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: HomeTextStyles.badgeCaption,
          ),
        ],
      ),
    );
  }
}
