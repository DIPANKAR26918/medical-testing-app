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
      color: Color(0xFF087E86),
    ),
    _ReportData(
      title: 'Liver Function Test',
      date: '18 Jun 2026',
      lab: 'HealthSure Diagnostics',
      status: 'Reviewed',
      color: Color(0xFF2563EB),
    ),
    _ReportData(
      title: 'Vitamin D',
      date: '02 Jun 2026',
      lab: 'Prime Pathology',
      status: 'Ready',
      color: Color(0xFF0F766E),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      children: [
        _Header(onUploadPrescription: onUploadPrescription),
        const SizedBox(height: 18),
        const _InsightsCard(),
        const SizedBox(height: 18),
        const Text(
          'Recent reports',
          style: TextStyle(
            color: Color(0xFF0B2538),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        for (final report in _reports) ...[
          _ReportCard(report: report),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onUploadPrescription});

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
                  color: Color(0xFF0B2538),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Your verified health records, ready to view or share.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: onUploadPrescription,
          icon: const Icon(Icons.upload_file_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF087E86),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(color: const Color(0xFF063B4C)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health trend stable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '3 reports uploaded this month. CBC markers are within normal range.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .78),
                    height: 1.35,
                    fontSize: 12.5,
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final _ReportData report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
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
                    color: Color(0xFF0B2538),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.date} - ${report.lab}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Chip(label: report.status, color: report.color),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded, size: 19, color: report.color),
                  const SizedBox(width: 10),
                  Icon(Icons.ios_share_rounded, size: 19, color: report.color),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
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
    required this.color,
  });

  final String title;
  final String date;
  final String lab;
  final String status;
  final Color color;
}

BoxDecoration _cardDecoration({Color color = Colors.white}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: color == Colors.white ? const Color(0xFFE2E8F0) : color),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .035),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
