import 'package:flutter/material.dart';

import 'home_constants.dart';

class PartnerLabsBanner extends StatelessWidget {
  const PartnerLabsBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomeColors.blueLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD9E7FF)),
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
                color: HomeColors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need MRI, CT Scan or X-Ray?',
                    style: TextStyle(
                      fontSize: 15.2,
                      fontWeight: FontWeight.w900,
                      color: HomeColors.deepBlue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Find trusted partner labs and save up to 20%.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
              color: HomeColors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }
}
