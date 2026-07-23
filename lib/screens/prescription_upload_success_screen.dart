import 'dart:async';

import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/device_feedback_service.dart';
import '../utils/index.dart';
import 'prescription_submitted_screen.dart';

/// A brief, focused confirmation between a successful upload and its details.
class PrescriptionUploadSuccessScreen extends StatefulWidget {
  const PrescriptionUploadSuccessScreen({
    required this.order,
    this.displayDuration = const Duration(milliseconds: 1550),
    this.feedbackEnabled = true,
    super.key,
  });

  final Order order;
  final Duration displayDuration;
  final bool feedbackEnabled;

  static Route<void> route(Order order) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (context, animation, secondaryAnimation) {
        return PrescriptionUploadSuccessScreen(order: order);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  @override
  State<PrescriptionUploadSuccessScreen> createState() =>
      _PrescriptionUploadSuccessScreenState();
}

class _PrescriptionUploadSuccessScreenState
    extends State<PrescriptionUploadSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _markScale;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentOffset;

  bool _started = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    );
    _markScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .72, curve: Curves.elasticOut),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.22, 1, curve: Curves.easeOutCubic),
    );
    _contentOffset = Tween<Offset>(
      begin: const Offset(0, .16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(.22, 1, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      unawaited(_controller.forward());
    }

    unawaited(_presentConfirmation(reduceMotion: reduceMotion));
  }

  Future<void> _presentConfirmation({required bool reduceMotion}) async {
    if (widget.feedbackEnabled) {
      unawaited(DeviceFeedbackService.playPrescriptionSuccess());
    }

    final minimumDuration = reduceMotion
        ? const Duration(milliseconds: 900)
        : widget.displayDuration;
    await Future<void>.delayed(minimumDuration);
    if (!mounted || _finished) return;

    _finished = true;
    await Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) {
          return PrescriptionSubmittedScreen(order: widget.order);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: PrescriptionFlowTheme.background,
        body: SafeArea(
          child: Semantics(
            liveRegion: true,
            label:
                'Prescription uploaded successfully and sent for medical review.',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final progress = Curves.easeOutCubic.transform(
                        _controller.value,
                      );
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1 - progress)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                            child: Transform.scale(
                              scale: .78 + (progress * .58),
                              child: Container(
                                width: 148,
                                height: 148,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: PrescriptionFlowTheme.success
                                        .withValues(alpha: .18),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ScaleTransition(
                            scale: _markScale,
                            child: const _AnimatedSuccessMark(),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _contentOpacity,
                    child: SlideTransition(
                      position: _contentOffset,
                      child: const Column(
                        children: [
                          Text(
                            'Prescription uploaded',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: PrescriptionFlowTheme.ink,
                              fontSize: 25,
                              height: 1.12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.55,
                            ),
                          ),
                          SizedBox(height: 9),
                          Text(
                            'Sent securely for medical review.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: PrescriptionFlowTheme.text,
                              fontSize: 14,
                              height: 1.42,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  FadeTransition(
                    opacity: _contentOpacity,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: PrescriptionFlowTheme.muted,
                          ),
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Opening review details…',
                          style: TextStyle(
                            color: PrescriptionFlowTheme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSuccessMark extends StatelessWidget {
  const _AnimatedSuccessMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF25A65A),
            PrescriptionFlowTheme.success,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: PrescriptionFlowTheme.success.withValues(alpha: .24),
            blurRadius: 34,
            spreadRadius: 3,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .14),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 42,
          weight: 800,
        ),
      ),
    );
  }
}
