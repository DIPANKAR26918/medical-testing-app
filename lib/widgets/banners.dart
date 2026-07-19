import 'package:flutter/material.dart';

import 'home/home_constants.dart';

/// A single purposeful editorial card. It replaces the auto-playing promo
/// carousel so the home screen feels calm and health-led, not sales-led.
class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key, this.onExploreTests});

  final VoidCallback? onExploreTests;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Explore preventive health checks',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onExploreTests,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              color: HomeColors.mintSoft,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD5EBE4)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -34,
                  top: -38,
                  child: Container(
                    width: 126,
                    height: 126,
                    decoration: BoxDecoration(
                      color: HomeColors.mint.withValues(alpha: .055),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 15, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite_border_rounded,
                                  color: HomeColors.mint,
                                  size: 15,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'PREVENTIVE CARE',
                                  style: TextStyle(
                                    color: HomeColors.mint,
                                    fontSize: 9.8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .72,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Know more before symptoms begin',
                              style: TextStyle(
                                color: HomeColors.textPrimary,
                                fontSize: 18.5,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Explore routine checks for everyday health, chosen by concern and body system.',
                              style: TextStyle(
                                color: HomeColors.textSecondary,
                                fontSize: 11.5,
                                height: 1.38,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Explore health checks',
                                  style: TextStyle(
                                    color: HomeColors.mint,
                                    fontSize: 11.7,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: HomeColors.mint,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const _PreventiveArtwork(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreventiveArtwork extends StatelessWidget {
  const _PreventiveArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 82,
            height: 98,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .88),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white),
            ),
          ),
          Positioned(
            top: 20,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFDDF2EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                color: HomeColors.mint,
                size: 26,
              ),
            ),
          ),
          Positioned(
            bottom: 21,
            left: 17,
            right: 17,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _HealthBar(height: 12),
                _HealthBar(height: 21),
                _HealthBar(height: 16),
                _HealthBar(height: 27),
              ],
            ),
          ),
          Positioned(
            right: -1,
            top: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: HomeColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: HomeColors.mintSoft, width: 3),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: height,
      decoration: BoxDecoration(
        color: HomeColors.mint.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
