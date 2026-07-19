import 'package:flutter/material.dart';

import '../../models/order.dart';
import 'home_constants.dart';

/// Traya-style journey module adapted to Testified's diagnostics workflow.
///
/// An active booking becomes a compact progress card. If the user has no
/// active booking, the same space explains the prescription-first journey.
class HomeBookingProgress extends StatelessWidget {
  const HomeBookingProgress({
    required this.onOpenBookings,
    required this.onUploadPrescription,
    this.order,
    this.isLoading = false,
    super.key,
  });

  final Order? order;
  final bool isLoading;
  final VoidCallback onOpenBookings;
  final VoidCallback onUploadPrescription;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _JourneyLoadingCard();

    final activeOrder = order;
    if (activeOrder == null) {
      return _PrescriptionJourneyCard(onTap: onUploadPrescription);
    }

    return _ActiveBookingCard(
      order: activeOrder,
      onTap: onOpenBookings,
    );
  }
}

class _ActiveBookingCard extends StatelessWidget {
  const _ActiveBookingCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _BookingStatus.from(order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'Your care journey',
          actionLabel: 'View all',
          onAction: onTap,
        ),
        const SizedBox(height: 13),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: HomeColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x07111B30),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: status.softColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          status.icon,
                          color: status.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HomeColors.textPrimary,
                                fontSize: 16.5,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              status.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HomeColors.textSecondary,
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      _StatusPill(label: status.label, color: status.color),
                      const Spacer(),
                      Text(
                        'Order #${_shortOrderId(order.orderId)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: status.progress,
                      color: status.color,
                      backgroundColor: const Color(0xFFEDF1F6),
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ProgressLabel('Review'),
                      _ProgressLabel('Approve'),
                      _ProgressLabel('Collect'),
                      _ProgressLabel('Report'),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(height: 1, color: HomeColors.borderLight),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tap for the complete booking timeline',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: HomeColors.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Text(
                        'See booking',
                        style: TextStyle(
                          color: HomeColors.primary,
                          fontSize: 11.7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: HomeColors.primary,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrescriptionJourneyCard extends StatelessWidget {
  const _PrescriptionJourneyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Simple from start to finish'),
        const SizedBox(height: 13),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: HomeColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06111B30),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _JourneyStep(
                      number: '1',
                      title: 'Upload',
                      subtitle: 'Share your prescription',
                    ),
                  ),
                  _StepConnector(),
                  Expanded(
                    child: _JourneyStep(
                      number: '2',
                      title: 'We prepare',
                      subtitle: 'Experts map the tests',
                    ),
                  ),
                  _StepConnector(),
                  Expanded(
                    child: _JourneyStep(
                      number: '3',
                      title: 'You approve',
                      subtitle: 'Review before payment',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: HomeColors.textPrimary,
              fontSize: 19.5,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -.3,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: HomeColors.primary,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: HomeColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: HomeColors.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: HomeColors.textPrimary,
            fontSize: 11.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: HomeColors.textMuted,
            fontSize: 9.5,
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 1,
      margin: const EdgeInsets.only(top: 17),
      color: const Color(0xFFD5E3FD),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: HomeColors.textHint,
        fontSize: 9.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _JourneyLoadingCard extends StatelessWidget {
  const _JourneyLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 168,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EDF4),
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(height: 13),
        Container(
          height: 176,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: HomeColors.border),
          ),
        ),
      ],
    );
  }
}

class _BookingStatus {
  const _BookingStatus({
    required this.title,
    required this.description,
    required this.label,
    required this.progress,
    required this.color,
    required this.softColor,
    required this.icon,
  });

  final String title;
  final String description;
  final String label;
  final double progress;
  final Color color;
  final Color softColor;
  final IconData icon;

  factory _BookingStatus.from(Order order) {
    final status = _normaliseStatus(order.status);

    if (_matches(status, const [
      'uploaded',
      'prescription_uploaded',
      'reviewing',
      'under_review',
      'processing',
      'prescription_reviewing',
    ])) {
      return const _BookingStatus(
        title: 'Prescription under review',
        description: 'Our team is preparing the right test list for you.',
        label: 'Reviewing',
        progress: .20,
        color: Color(0xFFD97706),
        softColor: Color(0xFFFFF7E7),
        icon: Icons.manage_search_rounded,
      );
    }

    if (_matches(status, const [
      'processed',
      'test_list_prepared',
      'tests_prepared',
      'awaiting_user_approval',
    ])) {
      return const _BookingStatus(
        title: 'Your test list is ready',
        description: 'Review the mapped tests and approve your booking.',
        label: 'Action needed',
        progress: .40,
        color: HomeColors.primary,
        softColor: HomeColors.primarySoft,
        icon: Icons.fact_check_outlined,
      );
    }

    if (_matches(status, const [
      'confirmed',
      'booking_confirmed',
      'assigned',
      'agent_assigned',
      'assigned_agent',
      'collection_agent_assigned',
      'agent_out_for_collection',
      'out_for_collection',
    ])) {
      return const _BookingStatus(
        title: 'Collection is being arranged',
        description: 'Your booking is confirmed and collection is in progress.',
        label: 'Confirmed',
        progress: .62,
        color: HomeColors.primary,
        softColor: HomeColors.primarySoft,
        icon: Icons.home_work_outlined,
      );
    }

    if (_matches(status, const [
      'collected',
      'sample_collected',
      'sample_out_for_testing',
      'testing',
      'sample_testing',
      'sample_processing',
      'sample_processed',
    ])) {
      return const _BookingStatus(
        title: 'Your sample is at the lab',
        description: 'Testing is in progress. We’ll notify you when it is ready.',
        label: 'Testing',
        progress: .82,
        color: Color(0xFF6D5BD0),
        softColor: Color(0xFFF0EEFB),
        icon: Icons.science_outlined,
      );
    }

    if (_matches(status, const [
      'report_preparing',
      'report_in_making',
      'report_ready',
      'completed',
      'done',
      'report_delivered',
    ])) {
      return const _BookingStatus(
        title: 'Your report is ready',
        description: 'Open your reports to view the completed lab results.',
        label: 'Ready',
        progress: 1,
        color: HomeColors.mint,
        softColor: HomeColors.mintSoft,
        icon: Icons.task_alt_rounded,
      );
    }

    return const _BookingStatus(
      title: 'Booking in progress',
      description: 'Open your booking to see the latest update.',
      label: 'Processing',
      progress: .34,
      color: HomeColors.primary,
      softColor: HomeColors.primarySoft,
      icon: Icons.pending_actions_outlined,
    );
  }
}

bool _matches(String value, List<String> candidates) => candidates.contains(value);

String _normaliseStatus(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
}

String _shortOrderId(String value) {
  final clean = value.trim();
  if (clean.length <= 8) return clean;
  return clean.substring(clean.length - 8);
}
