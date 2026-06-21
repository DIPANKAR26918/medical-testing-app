// lib/widgets/dual_service_cards.dart
import 'package:flutter/material.dart';
import '../screens/lab_tests_at_home_page.dart';

class DualServiceCards extends StatelessWidget {
  const DualServiceCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _serviceCard(
          context: context,
          title: "Lab Tests\nat Home",
          desc: "Book tests and get sample collection at your doorstep.",
          image: "assets/images/home_service.png",
          bg: const Color(0xFFF5FCFA),
          accent: const Color(0xFF14B8A6),
          badgeText: "Trusted",
          bottomText: "Safe • Reliable • Confidential",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LabTestsPage()),
            );
          },
        ),

        const SizedBox(width: 16),

        _serviceCard(
          context: context,
          title: "Book Tests at\nPartner Labs",
          desc: "Schedule advanced tests & scans at trusted labs.",
          image: "assets/images/lab_calendar.png",
          bg: const Color(0xFFF5F9FF),
          accent: const Color(0xFF3B82F6),
          badgeText: "Premium",
          bottomText: "Certified Labs • Accurate Results",
        ),
      ],
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 420,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),

          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bg, Colors.white],
          ),

          border: Border.all(color: accent.withValues(alpha: .15), width: 1.5),

          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .08),
              blurRadius: 30,
              spreadRadius: 1,
              offset: const Offset(0, 12),
            ),
          ],
        ),

        child: Stack(
          children: [
            // Background circle
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: .05),
                ),
              ),
            ),

            Positioned(
              bottom: -20,
              right: -10,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: .03),
                ),
              ),
            ),

            Positioned(
              top: 30,
              left: -10,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: .05),
                ),
              ),
            ),

            Positioned(
              right: 25,
              top: 110,
              child: Column(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: .45),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (badgeText == "Premium")
              Positioned(
                right: 35,
                top: 170,
                child: Icon(
                  Icons.auto_awesome,
                  color: accent.withValues(alpha: .4),
                  size: 28,
                ),
              ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badge
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: accent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          badgeText,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Image
                Center(
                  child: Container(
                    height: 130,
                    width: 130,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: .10),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(image, height: 130, fit: BoxFit.contain),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.black.withValues(alpha: .65),
                  ),
                ),

                const Spacer(),

                // Bottom Trust Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: accent.withValues(alpha: .12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 18, color: accent),

                      const SizedBox(width: 8),

                      Flexible(
                        child: Text(
                          bottomText,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: .85)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(30),

                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, right: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                badgeText == "Trusted"
                                    ? "Book Now"
                                    : "Schedule Now",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),

                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: accent,
                                size: 28,
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
}
