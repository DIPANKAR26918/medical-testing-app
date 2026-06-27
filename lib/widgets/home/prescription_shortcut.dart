import 'package:flutter/material.dart';

import 'home_constants.dart';

class PrescriptionShortcut extends StatelessWidget {
  const PrescriptionShortcut({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: HomeDecorations.card(),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: HomeColors.teal.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.note_alt_rounded, color: HomeColors.teal),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload prescription', style: HomeTextStyles.cardTitle),
                  SizedBox(height: 4),
                  Text(
                    'Not sure which tests to book? Let us map it for you.',
                    style: HomeTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: HomeColors.orange.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: HomeColors.orange,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
