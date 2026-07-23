import 'package:flutter/material.dart';

import '../models/index.dart';
import '../utils/index.dart';

/// Final hand-off after a prescription and collection address are submitted.
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
          toolbarHeight: 52,
          backgroundColor: PrescriptionFlowTheme.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => _openHome(context),
              tooltip: 'Back to home',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const _SuccessHero(),
              const SizedBox(height: 20),
              _RequestSummary(order: order),
              const SizedBox(height: 14),
              const _NextStepsCard(),
            ],
          ),
        ),
        bottomNavigationBar: _SubmittedBottomBar(
          onTrack: () => _openBookings(context),
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
        SizedBox(height: 14),
        Text(
          'Prescription sent for review',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PrescriptionFlowTheme.ink,
            fontSize: 24,
            height: 1.16,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
        SizedBox(height: 7),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'We’ll map the prescribed tests. You’ll approve the list before booking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PrescriptionFlowTheme.text,
              fontSize: 13.5,
              height: 1.45,
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
      width: 66,
      height: 66,
      decoration: const BoxDecoration(
        color: PrescriptionFlowTheme.successContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: PrescriptionFlowTheme.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 27),
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
      padding: const EdgeInsets.all(16),
      decoration: PrescriptionFlowTheme.card(shadow: false),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: PrescriptionFlowTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: PrescriptionFlowTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Review request',
                  style: TextStyle(
                    color: PrescriptionFlowTheme.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (address != null && address.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 13),
              child: Divider(height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: PrescriptionFlowTheme.primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collection address',
                        style: TextStyle(
                          color: PrescriptionFlowTheme.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PrescriptionFlowTheme.ink,
                          fontSize: 13,
                          height: 1.38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: PrescriptionFlowTheme.card(shadow: false),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next',
            style: TextStyle(
              color: PrescriptionFlowTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -.2,
            ),
          ),
          SizedBox(height: 17),
          Row(
            children: [
              _StepDot(number: '1', active: true),
              Expanded(child: _StepConnector()),
              _StepDot(number: '2'),
              Expanded(child: _StepConnector()),
              _StepDot(number: '3'),
            ],
          ),
          SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepLabel('Medical review'),
              _StepLabel('Your approval'),
              _StepLabel('Collection arranged'),
            ],
          ),
          SizedBox(height: 14),
          Divider(height: 1),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: PrescriptionFlowTheme.primary,
                size: 18,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Nothing is booked or charged until you approve.',
                  style: TextStyle(
                    color: PrescriptionFlowTheme.text,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
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

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, this.active = false});

  final String number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 27,
      height: 27,
      decoration: BoxDecoration(
        color: active
            ? PrescriptionFlowTheme.primary
            : PrescriptionFlowTheme.strongOutline,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: TextStyle(
          color: active ? Colors.white : PrescriptionFlowTheme.text,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Container(height: 2, color: PrescriptionFlowTheme.outline);
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: PrescriptionFlowTheme.ink,
          fontSize: 11.5,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SubmittedBottomBar extends StatelessWidget {
  const _SubmittedBottomBar({required this.onTrack});

  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: PrescriptionFlowTheme.outline)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1010213D),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: onTrack,
            icon: const Icon(Icons.receipt_long_outlined, size: 20),
            label: const Text('Track review'),
            style: PrescriptionFlowTheme.filledButtonStyle(),
          ),
        ),
      ),
    );
  }
}
