// lib/widgets/dual_service_cards.dart
import 'package:flutter/material.dart';
import '../screens/lab_tests_at_home_page.dart';

class DualServiceCards extends StatelessWidget {
  const DualServiceCards({super.key});

  static const double _cardWidth = 235;
  static const double _cardHeight = 430;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: _cardWidth,
              child: _serviceCard(
                context: context,
                title: "Lab Tests\nat Home",
                desc: "Book tests and get sample collection at your doorstep.",
                image: "assets/images/lab_tests_at_home_image.png",
                bg: const Color(0xFFF4FBF9),
                accent: const Color(0xFF14B8A6),
                badgeText: "Trusted",
                bottomText: "Safe • Reliable • Confidential",
                ctaText: "Book Now",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LabTestsPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: _cardWidth,
              child: _serviceCard(
                context: context,
                title: "Book Tests at\nPartner Labs",
                desc: "Schedule advanced tests and scans at trusted labs.",
                image: "assets/images/book_tests_at_partner_labs_image.png",
                bg: const Color(0xFFF5F9FF),
                accent: const Color(0xFF3B82F6),
                badgeText: "Premium",
                bottomText: "Certified Labs • Accurate Results",
                ctaText: "Schedule Now",
                onTap: null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard({
    required BuildContext context,
    required String title,
    required String desc,
    required String image,
    required Color bg,
    required Color accent,
    required String badgeText,
    required String bottomText,
    required String ctaText,
    VoidCallback? onTap,
  }) {
    final bool tappable = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(34),
      child: Container(
        height: _cardHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bg, Colors.white],
          ),
          border: Border.all(color: accent.withValues(alpha: .12), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .08),
              blurRadius: 28,
              spreadRadius: 0,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: .03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // subtle background geometry
            Positioned(
              top: -42,
              right: -38,
              child: _circle(138, accent.withValues(alpha: .05)),
            ),
            Positioned(
              top: 34,
              left: -24,
              child: _circle(150, accent.withValues(alpha: .035)),
            ),
            Positioned(
              bottom: -26,
              right: -14,
              child: _circle(92, accent.withValues(alpha: .03)),
            ),

            // premium accent only where it helps
            if (badgeText == "Premium")
              Positioned(
                right: 18,
                top: 156,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: accent.withValues(alpha: .28),
                  size: 22,
                ),
              ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top badge
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: accent.withValues(alpha: .08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .035),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: accent, size: 15),
                        const SizedBox(width: 5),
                        Text(
                          badgeText,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: .1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // image
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: const Offset(-8, -2),
                    child: Image.asset(image, height: 120, fit: BoxFit.contain),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    letterSpacing: -.25,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  desc,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.black.withValues(alpha: .64),
                  ),
                ),

                const SizedBox(height: 10),

                // utility strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .82),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: accent.withValues(alpha: .10)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded, size: 16, color: accent),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          bottomText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // CTA
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [accent, accent.withValues(alpha: .88)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .28),
                        blurRadius: 18,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      onTap: tappable ? onTap : null,
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, right: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ctaText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  letterSpacing: .1,
                                ),
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: accent,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
