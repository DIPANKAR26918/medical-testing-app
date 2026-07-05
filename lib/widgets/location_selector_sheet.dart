import 'package:flutter/material.dart';

import '../models/location_data.dart';

class LocationSelectorSheet extends StatelessWidget {
  const LocationSelectorSheet({super.key});

  static const Color _deepBlue = Color(0xFF0F172A);
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Set your delivery location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _deepBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select whether you want a precise GPS address or a broader area zone for delivery.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _ModeCard(
              icon: Icons.my_location_rounded,
              iconColor: _primary,
              title: 'Precise location',
              subtitle: 'Exact delivery point with GPS coordinates.',
              highlight: true,
              onTap: () =>
                  Navigator.pop(context, LocationSelectionMode.precise),
            ),
            const SizedBox(height: 14),
            _ModeCard(
              icon: Icons.location_city_rounded,
              iconColor: _deepBlue,
              title: 'Approximate location',
              subtitle: 'City or area level delivery coverage.',
              onTap: () =>
                  Navigator.pop(context, LocationSelectionMode.approximate),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight
                ? const Color(0xFF1D4ED8).withValues(alpha: .18)
                : const Color(0xFFD1D5DB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
