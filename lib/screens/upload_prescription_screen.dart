import 'package:flutter/material.dart';

import '../widgets/prescription_upload_card.dart';

class UploadPrescriptionScreen extends StatelessWidget {
  const UploadPrescriptionScreen({super.key});

  static const Color _deepBlue = Color(0xFF0F172A);
  static const Color _softBg = Color(0xFFFFFBF7);
  static const Color _success = Color(0xFF16A34A);
  static const Color _blue = Color(0xFF1D4ED8);
  static const Color _orange = Color(0xFFF97316);
  static const Color _indigo = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _ScreenHeader(onBack: () => Navigator.maybePop(context)),
            const SizedBox(height: 18),
            const _TrustPanel(),
            const SizedBox(height: 16),
            const PrescriptionUploadCard(),
            const SizedBox(height: 4),
            const _ProcessCard(),
            const SizedBox(height: 14),
            const _PrivacyCard(),
          ],
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: UploadPrescriptionScreen._deepBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Rx',
                style: TextStyle(
                  color: UploadPrescriptionScreen._deepBlue,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Book the right lab tests from a prescription, without guessing test names.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustPanel extends StatelessWidget {
  const _TrustPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FCFF), Color(0xFFEFF6FF)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9E7FF)),
        boxShadow: [
          BoxShadow(
            color: UploadPrescriptionScreen._blue.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .78),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: UploadPrescriptionScreen._success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reviewed before booking',
                  style: TextStyle(
                    color: UploadPrescriptionScreen._deepBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We read your prescription and suggest the matching tests for confirmation.',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    height: 1.35,
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

class _ProcessCard extends StatelessWidget {
  const _ProcessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: TextStyle(
              color: UploadPrescriptionScreen._deepBlue,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          _StepRow(
            icon: Icons.file_upload_outlined,
            title: 'Upload prescription',
            subtitle: 'Take a photo or choose one from gallery.',
            color: UploadPrescriptionScreen._orange,
          ),
          SizedBox(height: 12),
          _StepRow(
            icon: Icons.biotech_rounded,
            title: 'We map the tests',
            subtitle: 'The prescription is converted into bookable lab tests.',
            color: UploadPrescriptionScreen._indigo,
          ),
          SizedBox(height: 12),
          _StepRow(
            icon: Icons.event_available_rounded,
            title: 'Confirm booking',
            subtitle: 'Pick home collection or partner lab visit.',
            color: UploadPrescriptionScreen._orange,
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(color: const Color(0xFFF8FAFC)),
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, color: UploadPrescriptionScreen._success),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your prescription is used only to prepare your test booking and report flow.',
              style: TextStyle(
                color: UploadPrescriptionScreen._deepBlue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: UploadPrescriptionScreen._deepBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

BoxDecoration _cardDecoration({Color color = Colors.white}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .035),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
