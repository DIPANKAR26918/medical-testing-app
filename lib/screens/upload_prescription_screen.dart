import 'package:flutter/material.dart';

import '../utils/index.dart';
import '../widgets/prescription_upload_card.dart';

class UploadPrescriptionScreen extends StatelessWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrescriptionFlowTheme.background,
      appBar: AppBar(
        backgroundColor: PrescriptionFlowTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton.filledTonal(
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: PrescriptionFlowTheme.surface,
              foregroundColor: PrescriptionFlowTheme.ink,
              side: const BorderSide(color: PrescriptionFlowTheme.outline),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
        ),
        titleSpacing: 8,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book via prescription',
              style: TextStyle(
                color: PrescriptionFlowTheme.ink,
                fontSize: 20,
                height: 1.15,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Upload once, approve every test',
              style: TextStyle(
                color: PrescriptionFlowTheme.text,
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: const SafeArea(top: false, child: PrescriptionUploadCard()),
    );
  }
}
