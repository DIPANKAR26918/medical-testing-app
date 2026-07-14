import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({
    required this.onUploadPrescription,
    this.onBookTest,
    this.reports = const <ReportListItem>[],
    this.onOpenReport,
    this.onShareReport,
    super.key,
  });

  final VoidCallback onUploadPrescription;
  final VoidCallback? onBookTest;
  final List<ReportListItem> reports;
  final ValueChanged<ReportListItem>? onOpenReport;
  final ValueChanged<ReportListItem>? onShareReport;

  @override
  Widget build(BuildContext context) {
    final hasReports = reports.isNotEmpty;

    return ColoredBox(
      color: _ReportsPalette.background,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 116),
        children: [
          _ReportsHeader(
            hasReports: hasReports,
            onUploadPrescription: onUploadPrescription,
          ),
          const SizedBox(height: 18),
          if (!hasReports)
            _EmptyReportsState(
              onBookTest: onBookTest ?? onUploadPrescription,
              onUploadPrescription: onUploadPrescription,
            )
          else ...[
            _ReportsSummaryCard(reportCount: reports.length),
            const SizedBox(height: 14),
            const _SectionHeader(title: 'Recent reports'),
            const SizedBox(height: 10),
            for (final report in reports) ...[
              _ReportCard(
                report: report,
                onOpen: () => onOpenReport?.call(report),
                onShare: () => onShareReport?.call(report),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class ReportListItem {
  const ReportListItem({
    required this.id,
    required this.title,
    required this.dateLabel,
    this.labName,
    this.status = 'Ready',
    this.note,
    this.canShare = true,
  });

  final String id;
  final String title;
  final String dateLabel;
  final String? labName;
  final String status;
  final String? note;
  final bool canShare;
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({
    required this.hasReports,
    required this.onUploadPrescription,
  });

  final bool hasReports;
  final VoidCallback onUploadPrescription;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: TextStyle(
                  color: _ReportsPalette.ink,
                  fontSize: 26,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Your medical reports in one place',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ReportsPalette.muted,
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (hasReports) ...[
          const SizedBox(width: 12),
          SizedBox(
            height: 42,
            child: OutlinedButton.icon(
              onPressed: onUploadPrescription,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Upload'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ReportsPalette.primary,
                side: const BorderSide(color: _ReportsPalette.border),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyReportsState extends StatelessWidget {
  const _EmptyReportsState({
    required this.onBookTest,
    required this.onUploadPrescription,
  });

  final VoidCallback onBookTest;
  final VoidCallback onUploadPrescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ReportsPalette.border),
        boxShadow: _ReportsPalette.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _ReportsPalette.primary.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: _ReportsPalette.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No reports available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ReportsPalette.ink,
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Your lab reports will appear here after a test is completed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ReportsPalette.muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onBookTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ReportsPalette.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Book a test'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: onUploadPrescription,
              style: OutlinedButton.styleFrom(
                foregroundColor: _ReportsPalette.primary,
                side: const BorderSide(color: _ReportsPalette.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Upload prescription'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsSummaryCard extends StatelessWidget {
  const _ReportsSummaryCard({required this.reportCount});

  final int reportCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ReportsPalette.border),
        boxShadow: _ReportsPalette.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _ReportsPalette.success.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: _ReportsPalette.success,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reportCount == 1
                  ? '1 report ready to view'
                  : '$reportCount reports ready to view',
              style: const TextStyle(
                color: _ReportsPalette.ink,
                fontSize: 15.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _ReportsPalette.ink,
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onOpen,
    required this.onShare,
  });

  final ReportListItem report;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);
    final meta = _metaText(report);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _ReportsPalette.border),
            boxShadow: _ReportsPalette.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _ReportsPalette.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: _ReportsPalette.primary,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ReportsPalette.ink,
                              fontSize: 15.5,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ReportsPalette.muted,
                              fontSize: 12.8,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (report.note != null &&
                              report.note!.trim().isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              report.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ReportsPalette.softMuted,
                                fontSize: 12,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(label: report.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (report.canShare) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.ios_share_rounded, size: 17),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ReportsPalette.primary,
                          side: const BorderSide(color: _ReportsPalette.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.visibility_rounded, size: 17),
                      label: const Text('View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ReportsPalette.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _metaText(ReportListItem report) {
    final lab = report.labName?.trim();

    if (lab != null && lab.isNotEmpty) {
      return '${report.dateLabel} • $lab';
    }

    return report.dateLabel;
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'ready':
        return _ReportsPalette.primary;
      case 'reviewed':
        return _ReportsPalette.success;
      case 'processing':
        return _ReportsPalette.warning;
      default:
        return _ReportsPalette.muted;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReportsPalette {
  const _ReportsPalette._();

  static const Color background = Color(0xFFFAFBFC);

  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color softMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE6EAF0);

  static const Color primary = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: .025),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}
