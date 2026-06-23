// lib/widgets/dual_service_cards.dart
import 'package:flutter/material.dart';
import '../screens/lab_tests_at_home_page.dart';

class DualServiceCards extends StatelessWidget {
  const DualServiceCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _homeCollectionCard(context),

          const SizedBox(height: 12),

          _advancedTestsBanner(context),
        ],
      ),
    );
  }

  Widget _homeCollectionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Colors.white],
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          /// Top badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
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
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
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

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Get Tested\nAt Home",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Sample collection at your doorstep in just 60 mins.",
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
                height: 90,
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// Social proof
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber),

                SizedBox(width: 8),

                Expanded(
                  child: Text(
                    "4.9 ★ Trusted by 12,000+ families",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Chip(icon: Icons.verified_rounded, text: "NABL Labs"),

              _Chip(icon: Icons.access_time_rounded, text: "60 min collection"),

              _Chip(icon: Icons.description_rounded, text: "Reports in 24 hrs"),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.savings_rounded, color: Colors.green.shade700),

                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    "Pay up to 20% less than local diagnostic centres.",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 56,
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
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Book Home Collection",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "No advance payment required",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _advancedTestsBanner(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {},

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF4FF),
          borderRadius: BorderRadius.circular(22),
        ),

        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: Color(0xFF2563EB),
              ),
            ),

            const SizedBox(width: 14),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Need MRI, CT Scan or X-Ray?",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),

                  SizedBox(height: 4),

                  Text(
                    "100+ trusted partner labs near you",
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
