import 'package:flutter/material.dart';

import 'home_constants.dart';

/// A subtle social-proof banner that builds trust through numbers.
///
/// Uses authority bias ("ICMR guidelines") and social proof ("12,000+ families")
/// to psychologically reassure users the app is legitimate.
class SocialProofBanner extends StatelessWidget {
  const SocialProofBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HomeColors.teal.withValues(alpha: .06),
            HomeColors.blueAccent.withValues(alpha: .04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.teal.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: HomeColors.teal.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: HomeColors.teal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trusted by 12,000+ families',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: HomeColors.deepBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NABL accredited labs • ICMR approved protocols',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.teal.withValues(alpha: .85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
