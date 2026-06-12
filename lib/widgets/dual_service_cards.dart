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
          context, // Pass context for navigation
          "Lab Tests\nat Home",
          "Book tests and get\nsample collection\nat your doorstep.",
          const Color(0xFFF1F8E9),
          Colors.teal.shade400,
          Icons.home_work_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LabTestsPage()),
            );
            // Navigator.push logic here
          },
        ),
        const SizedBox(width: 16),
        _serviceCard(
          context,
          "Book Tests at\nPartner Labs",
          "Schedule advanced\ntests & scans at\ntrusted labs.",
          const Color(0xFFE3F2FD),
          Colors.blue.shade400,
          Icons.calendar_month_outlined,
        ),
      ],
    );
  }

  // --- REUSABLE SERVICE CARD HELPER (Inside the class now) ---
  Widget _serviceCard(
    BuildContext context,
    String title,
    String desc,
    Color bg,
    Color accent,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 230,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 36),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 16,
                backgroundColor: accent,
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
