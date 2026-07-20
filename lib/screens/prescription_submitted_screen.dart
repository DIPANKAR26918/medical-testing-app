import 'package:flutter/material.dart';

import '../models/index.dart';
import '../utils/index.dart';

/// Final hand-off after a prescription and collection address are submitted.
///
/// This is intentionally a full screen rather than a dismissible bottom sheet:
/// submission is a meaningful state change and the next action must be clear.
class PrescriptionSubmittedScreen extends StatelessWidget {
  const PrescriptionSubmittedScreen({required this.order, super.key});

  final Order order;

  void _openBookings(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
      arguments: const {'tabIndex': 1},
    );
  }

  void _openHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
      arguments: const {'tabIndex': 0},
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _openBookings(context);
      },
      child: Scaffold(
        backgroundColor: PrescriptionFlowTheme.background,
        appBar: AppBar(
          backgroundColor: PrescriptionFlowTheme.background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => _openHome(context),
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
            children: [
              const _SuccessHero(),
              const SizedBox(height: 22),
              _RequestSummary(order: order),
              const SizedBox(height: 16),
              const _NextStepsCard(),
              const SizedBox(height: 16),
              const _ApprovalPromise(),
            ],
          ),
        ),
        bottomNavigationBar: _SubmittedBottomBar(
          onTrack: () => _openBookings(context),
          onHome: () => _openHome(context),
        ),
      ),
    );
  }
}

class _SuccessHero extends StatelessWidget {
  const _SuccessHero();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SuccessMark(),
        SizedBox(height: 20),
        Text(
          'Prescription sent for review',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PrescriptionFlowTheme.ink,
            fontSize: 26,
            height: 1.14,
            fontWeight: FontWeight.w900,
            letterSpacing: -.65,
          ),
        ),
        SizedBox(height: 9),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'A verified team member will map the prescribed tests. You will review every test before anything is booked.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PrescriptionFlowTheme.text,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        color: PrescriptionFlowTheme.successContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: PrescriptionFlowTheme.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _RequestSummary extends StatelessWidget {
  const _RequestSummary({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final address = order.patientLocationAddress?.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: PrescriptionFlowTheme.card(),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.receipt_long_outlined,
            label: 'Request ID',
            value: '#${order.orderId}',
          ),
          if (address != null && address.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            _SummaryRow(
              icon: Icons.location_on_outlined,
              label: 'Collection address',
              value: address,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: PrescriptionFlowTheme.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: PrescriptionFlowTheme.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: PrescriptionFlowTheme.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PrescriptionFlowTheme.ink,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: PrescriptionFlowTheme.card(shadow: false),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next',
            style: TextStyle(
              color: PrescriptionFlowTheme.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -.25,
            ),
          ),
          SizedBox(height: 18),
          _TimelineStep(
            number: '1',
            title: 'Medical review',
            description: 'The prescribed tests are mapped to our catalogue.',
            active: true,
          ),
          _TimelineStep(
            number: '2',
            title: 'Your approval',
            description: 'Choose the tests you want and check the total price.',
          ),
          _TimelineStep(
            number: '3',
            title: 'Collection arranged',
            description:
                'Booking and home collection move ahead after approval.',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.number,
    required this.title,
    required this.description,
    this.active = false,
    this.last = false,
  });

  final String number;
  final String title;
  final String description;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? PrescriptionFlowTheme.primary
        : PrescriptionFlowTheme.strongOutline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Column(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: TextStyle(
                    color: active ? Colors.white : PrescriptionFlowTheme.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!last)
                Container(
                  width: 2,
                  height: 54,
                  color: PrescriptionFlowTheme.outline,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3, bottom: last ? 12 : 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PrescriptionFlowTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: PrescriptionFlowTheme.text,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ApprovalPromise extends StatelessWidget {
  const _ApprovalPromise();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: PrescriptionFlowTheme.card(
        color: PrescriptionFlowTheme.primaryContainer,
        borderColor: PrescriptionFlowTheme.primaryOutline,
        radius: 18,
        shadow: false,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: PrescriptionFlowTheme.primary,
            size: 21,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Nothing is booked or charged until you review and confirm the prepared test list.',
              style: TextStyle(
                color: PrescriptionFlowTheme.ink,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedBottomBar extends StatelessWidget {
  const _SubmittedBottomBar({required this.onTrack, required this.onHome});

  final VoidCallback onTrack;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: PrescriptionFlowTheme.outline)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1410213D),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onHome,
                child: const Text('Back to home'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: onTrack,
                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                  label: const Text('Track review'),
                  style: PrescriptionFlowTheme.filledButtonStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
