import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({required this.onUploadPrescription, super.key});

  final VoidCallback onUploadPrescription;

  static const _reports = [
    _ReportData(
      title: 'Complete Blood Count',
      date: '27 Jun 2026',
      lab: 'Testified Partner Lab',
      status: 'Ready',
      resultNote: '21 markers checked',
      color: _ReportsPalette.indigo,
    ),
    _ReportData(
      title: 'Liver Function Test',
      date: '18 Jun 2026',
      lab: 'HealthSure Diagnostics',
      status: 'Reviewed',
      resultNote: 'Doctor review added',
      color: _ReportsPalette.blue,
    ),
    _ReportData(
      title: 'Vitamin D',
      date: '02 Jun 2026',
      lab: 'Prime Pathology',
      status: 'Ready',
      resultNote: 'Deficiency screening',
      color: _ReportsPalette.indigo,
    ),
  ];

  void _showAction(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      children: [
        _ReportsHeader(onUploadPrescription: onUploadPrescription),
        const SizedBox(height: 14),
        const _ReportVaultHero(),
        const SizedBox(height: 10),
        const _ReportTrustStrip(),
        const SizedBox(height: 18),
        _PrescriptionNudge(onTap: onUploadPrescription),
        const SizedBox(height: 20),
        const _SectionTitle(
          title: 'Recent reports',
          subtitle: 'View, download, or share verified lab reports.',
        ),
        const SizedBox(height: 10),
        for (final report in _reports) ...[
          _ReportCard(
            report: report,
            onView: () => _showAction(context, 'Report will open here'),
            onShare: () => _showAction(context, 'Report shared'),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        const _StorageNote(),
      ],
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({required this.onUploadPrescription});

  final VoidCallback onUploadPrescription;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: TextStyle(
                  color: _ReportsPalette.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Your secure health records, ready when you need them.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ReportsPalette.muted,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 42,
          child: OutlinedButton.icon(
            onPressed: onUploadPrescription,
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Upload'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ReportsPalette.coral,
              side: const BorderSide(color: _ReportsPalette.border),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportVaultHero extends StatelessWidget {
  const _ReportVaultHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ReportsPalette.heroStart, _ReportsPalette.heroEnd],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ReportsPalette.mintBorder),
        boxShadow: [
          BoxShadow(
            color: _ReportsPalette.indigo.withValues(alpha: .08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LightPill(text: 'Secure report vault'),
          const SizedBox(height: 12),
          const Text(
            '3 reports ready to view',
            style: TextStyle(
              color: _ReportsPalette.ink,
              fontSize: 23,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download, share with doctors, or keep reports safely in your app.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ReportsPalette.muted,
              fontSize: 12.8,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _VaultMetric(value: '3', label: 'Ready reports'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _VaultMetric(value: '1', label: 'Reviewed'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _VaultMetric(value: '100%', label: 'Private'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportTrustStrip extends StatelessWidget {
  const _ReportTrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _surfaceDecoration(shadow: false),
      child: const Row(
        children: [
          Expanded(
            child: _TrustItem(icon: Icons.verified_rounded, label: 'Verified'),
          ),
          _VerticalDivider(),
          Expanded(
            child: _TrustItem(icon: Icons.lock_rounded, label: 'Encrypted'),
          ),
          _VerticalDivider(),
          Expanded(
            child: _TrustItem(
              icon: Icons.ios_share_rounded,
              label: 'Easy share',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionNudge extends StatelessWidget {
  const _PrescriptionNudge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _ReportsPalette.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.upload_file_rounded, color: _ReportsPalette.coral),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Have a doctor prescription?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ReportsPalette.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Upload it and we will suggest matching low-cost tests.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ReportsPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _ReportsPalette.coral),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onView,
    required this.onShare,
  });

  final _ReportData report;
  final VoidCallback onView;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: report.color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assignment_rounded, color: report.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ReportsPalette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.date} | ${report.lab}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ReportsPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.resultNote,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(label: report.status, color: report.color),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ReportsPalette.primary,
                    side: const BorderSide(color: _ReportsPalette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ReportsPalette.indigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageNote extends StatelessWidget {
  const _StorageNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(shadow: false),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_rounded, color: _ReportsPalette.success),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Reports are stored privately and can be shared only when you choose.',
              style: TextStyle(
                color: _ReportsPalette.ink,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ReportsPalette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: _ReportsPalette.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VaultMetric extends StatelessWidget {
  const _VaultMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ReportsPalette.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ReportsPalette.indigo,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ReportsPalette.ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _ReportsPalette.success, size: 17),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ReportsPalette.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _ReportsPalette.border,
    );
  }
}

class _LightPill extends StatelessWidget {
  const _LightPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _ReportsPalette.indigo.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _ReportsPalette.indigo,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReportData {
  const _ReportData({
    required this.title,
    required this.date,
    required this.lab,
    required this.status,
    required this.resultNote,
    required this.color,
  });

  final String title;
  final String date;
  final String lab;
  final String status;
  final String resultNote;
  final Color color;
}

class _ReportsPalette {
  const _ReportsPalette._();

  static const Color heroStart = Color(0xFFF8FBFF);
  static const Color heroEnd = Color(0xFFEFF6FF);
  static const Color mintBorder = Color(0xFFD9E7FF);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE5E7EB);
  static const Color primary = Color(0xFF1D4ED8);
  static const Color blue = primary;
  static const Color indigo = Color(0xFF4F46E5);
  static const Color coral = Color(0xFFF97316);
  static const Color success = Color(0xFF16A34A);
}

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 8)),
];

BoxDecoration _surfaceDecoration({bool shadow = true}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _ReportsPalette.border),
    boxShadow: shadow ? _softShadow : null,
  );
}
