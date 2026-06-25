import 'package:flutter/material.dart';

import '../models/location_data.dart';

class LocationSelectorSheet extends StatelessWidget {
  const LocationSelectorSheet({super.key});

  static const Color _deepBlue = Color(0xFF0F172A);
  static const Color _teal = Color(0xFF0E9F8A);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
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
            const SizedBox(height: 18),
            Text(
              'Choose location mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: .88),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick how you want the app to set your delivery area.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.black.withValues(alpha: .77),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            _OptionCard(
              icon: Icons.my_location_rounded,
              iconBg: const Color(0xFFE7FFF9),
              iconColor: _teal,
              title: 'Precise location',
              subtitle: 'Uses GPS for exact delivery point.',
              onTap: () {
                Navigator.pop(context, LocationSelectionMode.precise);
              },
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.location_city_rounded,
              iconBg: const Color(0xFFEFF4FF),
              iconColor: _deepBlue,
              title: 'Approximate location',
              subtitle: 'Uses city / area level delivery zone.',
              onTap: () {
                Navigator.pop(context, LocationSelectionMode.approximate);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: .05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: LocationSelectorSheet._deepBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: Colors.black.withValues(alpha: .58),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
