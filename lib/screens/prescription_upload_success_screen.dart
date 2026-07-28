import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/device_feedback_service.dart';
import 'direct_booking_success_screen.dart';

/// Full-screen hand-off from upload to the live prescription booking details.
class PrescriptionUploadSuccessScreen extends StatelessWidget {
  const PrescriptionUploadSuccessScreen({
    required this.order,
    this.displayDuration = const Duration(milliseconds: 2400),
    this.feedbackEnabled = true,
    this.liveUpdatesOnDetails = true,
    super.key,
  });

  final Order order;
  final Duration displayDuration;
  final bool feedbackEnabled;
  final bool liveUpdatesOnDetails;

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
  Widget build(BuildContext context) {
    return DirectBookingSuccessScreen(
      order: order,
      tests: const [],
      displayDuration: displayDuration,
      feedbackEnabled: feedbackEnabled,
      feedbackCallback: DeviceFeedbackService.playPrescriptionSuccess,
      liveUpdatesOnDetails: liveUpdatesOnDetails,
      title: 'Prescription uploaded',
      message:
          'Our medical experts will review it and suggest the right tests for you at no extra cost.',
      showBookingSummary: false,
      loadingLabel: 'Opening booking updates…',
      semanticsLabel:
          'Prescription uploaded. Medical experts will review it and suggest tests at no extra cost. Opening booking updates.',
      screenKey: const ValueKey('prescription-upload-success-screen'),
    );
  }
}
