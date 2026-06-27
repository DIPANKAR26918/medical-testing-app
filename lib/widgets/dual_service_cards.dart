// lib/widgets/dual_service_cards.dart
import 'package:flutter/material.dart';
import '../screens/lab_tests_at_home_page.dart';

class DualServiceCards extends StatelessWidget {
  const DualServiceCards({super.key});

  static const _primary = Color(0xFF0E7490);
  static const _cta = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return Column(children: [_homeCollectionCard(context)]);
  }

  Widget _homeCollectionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF7FBFC)],
        ),
        border: Border.all(color: const Color(0xFFE7EEF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F8),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Text(
              "FREE HOME COLLECTION",
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: .5,
              ),
            ),
          ),

          const SizedBox(height: 18),

          /// TITLE
          const Text(
            "Quality Lab Tests\nAt Your Doorstep",
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -.8,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Certified diagnostic tests with doorstep sample collection and fast digital reports.",
            style: TextStyle(
              color: Colors.black.withValues(alpha: .65),
              fontSize: 14.5,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 18),

          /// SOCIAL PROOF
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.star_outlined, color: Colors.amber),

                SizedBox(width: 8),

                Expanded(
                  child: Text(
                    "4.9 rating • Trusted by 12,000+ families",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          /// HERO IMAGE
          const SizedBox(height: 24),

          /// TRUST POINTS
          const _TrustRow(
            icon: Icons.verified_user_outlined,
            text: "NABL certified partner laboratories",
          ),

          SizedBox(height: 14),

          const _TrustRow(
            icon: Icons.access_time_filled_outlined,
            text: "Doorstep sample collection in 60 mins",
          ),

          SizedBox(height: 14),

          const _TrustRow(
            icon: Icons.description_outlined,
            text: "Digital reports delivered within 24 hours",
          ),

          const SizedBox(height: 10),

          /// SAVINGS STRIP
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.savings_outlined,
                  color: Colors.green.shade700,
                  size: 28,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    "Save up to ₹1200 compared to local diagnostic centres.",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// CTA
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LabTestsPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _cta,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                "Book Free Home Collection",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              "No advance payment • Free cancellation",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F7F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF0E7490), size: 20),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
