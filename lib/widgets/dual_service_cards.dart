// lib/widgets/dual_service_cards.dart
import 'package:flutter/material.dart';
import '../screens/lab_tests_at_home_page.dart';

class DualServiceCards extends StatelessWidget {
  const DualServiceCards({super.key});

  static const double _cardHeight = 375;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _homeCollectionCard(context),
          const SizedBox(width: 14),
          _partnerLabCard(),
        ],
      ),
    );
  }

  Widget _homeCollectionCard(BuildContext context) {
    return Container(
      width: 315,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        ),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP BADGES
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  "MOST BOOKED",
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  "SAVE 20%",
                  style: TextStyle(
                    color: Color(0xFFEA580C),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Get Tested\nAt Home",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Skip travel. Save money.",
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: .65),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              Image.asset(
                "assets/images/lab_tests_at_home_image.png",
                height: 82,
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// SOCIAL PROOF
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber),

                SizedBox(width: 6),

                Expanded(
                  child: Text(
                    "4.9 ★ • Trusted by 12,000+ families",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.verified_rounded, text: "NABL Labs"),

              _InfoChip(
                icon: Icons.access_time_rounded,
                text: "60 min collection",
              ),

              _InfoChip(
                icon: Icons.description_rounded,
                text: "Reports in 24 hrs",
              ),
            ],
          ),

          const Spacer(),

          /// VALUE + CTA
          Row(
            children: [
              Expanded(
                child: Text(
                  "Up to 20% cheaper\nthan local labs",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),

              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LabTestsPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFF97316),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "Book Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _partnerLabCard() {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Text(
              "ADVANCED TESTS",
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "MRI, CT Scan\n& X-Ray",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "100+ trusted diagnostic centres",
            style: TextStyle(color: Colors.black.withValues(alpha: .65)),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                "Find Nearby Labs",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF0F766E)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
