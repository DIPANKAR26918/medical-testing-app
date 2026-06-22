// lib/widgets/dual_service_cards.dart
import 'package:flutter/material.dart';
import '../screens/lab_tests_at_home_page.dart';

class DualServiceCards extends StatelessWidget {
  const DualServiceCards({super.key});

  static const double _cardWidth = 275;
  static const double _cardHeight = 542;

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
                image: "assets/images/lab_tests_at_home_image.png",
                badgeText: "MOST POPULAR",
                title: "Get Tested\nat Home",
                subtitle: "No travel. No waiting.",
                socialProof: "⭐ Chosen by 95% of users",
                features: const [
                  "Sample collection in 60 mins",
                  "Reports within 24 hrs",
                  "Certified professionals",
                ],
                ctaText: "Book Home Collection",
                accent: const Color(0xFF0E8C93),
                bg: const Color(0xFFEFFCF8),
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
                image: "assets/images/book_tests_at_partner_labs_image.png",
                badgeText: "ADVANCED TESTS",
                title: "Visit a\nPartner Lab",
                subtitle: "For MRI, CT & specialized tests",
                socialProof: "🏥 100+ trusted partner labs",
                features: const [
                  "Premium diagnostic centres",
                  "Flexible appointment slots",
                  "Expert technicians",
                ],
                ctaText: "Find Nearby Labs",
                accent: const Color(0xFF2563EB),
                bg: const Color(0xFFF5F9FF),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard({
    required BuildContext context,
    required String image,
    required String badgeText,
    required String title,
    required String subtitle,
    required String socialProof,
    required List<String> features,
    required String ctaText,
    required Color accent,
    required Color bg,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bg, Colors.white],
          ),
          border: Border.all(color: accent.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .10),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Center(child: Image.asset(image, height: 120)),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: TextStyle(
                color: Colors.black.withValues(alpha: .65),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 18),

            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 15, color: accent),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: .10)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_alt_rounded, color: accent, size: 20),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      socialProof,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ctaText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(width: 8),

                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
