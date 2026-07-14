import 'package:flutter/material.dart';

import '../widgets/prescription_upload_card.dart';

const Color _screenBackground = Color(0xFFF8FAFD);
const Color _screenInk = Color(0xFF12172B);
//const Color _screenText = Color(0xFF71809A);
//const Color _screenPrimary = Color(0xFF2F67F5);
//const Color _screenPrimarySoft = Color(0xFFEEF4FF);
//const Color _screenBorder = Color(0xFFE2E9F3);

class UploadPrescriptionScreen extends StatelessWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _UploadScreenHeader(onBack: () => Navigator.maybePop(context)),
            const Expanded(child: PrescriptionUploadCard()),
          ],
        ),
      ),
    );
  }
}

class _UploadScreenHeader extends StatelessWidget {
  const _UploadScreenHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _screenBackground,
      padding: const EdgeInsets.fromLTRB(14, 14, 22, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _screenInk,
                  size: 25,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload prescription',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _screenInk,
                    fontSize: 22,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.36,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'We’ll prepare the right tests for you',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color.fromARGB(255, 76, 77, 79),
                    fontSize: 14.5,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
