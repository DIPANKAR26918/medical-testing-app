import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../widgets/home/home_constants.dart';
import 'medical_test_detail_screen.dart';
import 'order_details_screen.dart';
import 'prescription_review_screen.dart';

/// Resolves an opaque push payload through the signed-in user's RLS session.
///
/// The notification itself never carries an order, prescription, or test
/// record. This route fetches the referenced record only after authentication
/// and then renders the same screen the user would reach inside the app.
class NotificationDestinationScreen extends StatefulWidget {
  const NotificationDestinationScreen({required this.target, super.key});

  final PushNotificationTarget target;

  @override
  State<NotificationDestinationScreen> createState() =>
      _NotificationDestinationScreenState();
}

class _NotificationDestinationScreenState
    extends State<NotificationDestinationScreen> {
  late Future<Object?> _destinationFuture;

  @override
  void initState() {
    super.initState();
    _destinationFuture = _loadDestination();
  }

  Future<Object?> _loadDestination() {
    return switch (widget.target.destination) {
      PushNotificationDestination.orderDetails ||
      PushNotificationDestination.prescriptionReview =>
        FirestoreService().getOrder(widget.target.orderId!),
      PushNotificationDestination.testDetails =>
        MedicalTestCatalogService().fetchTestById(widget.target.medicalTestId!),
      _ => Future<Object?>.value(),
    };
  }

  void _retry() {
    setState(() => _destinationFuture = _loadDestination());
  }

  void _openFallback() {
    final fallbackTab =
        widget.target.destination == PushNotificationDestination.testDetails
        ? 0
        : 1;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
      arguments: {'tabIndex': fallbackTab},
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Object?>(
      future: _destinationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DestinationLoadingScreen();
        }

        final destination = snapshot.data;
        if (destination is Order) {
          // A test-list notification can remain in the phone tray after the
          // user has approved it elsewhere. Resolve against the current order
          // state so a stale tap cannot reopen an already-completed decision.
          final openReview = shouldOpenPrescriptionReview(destination.status);

          return openReview
              ? PrescriptionReviewScreen(order: destination)
              : OrderDetailsScreen(order: destination);
        }

        if (destination is MedicalTest) {
          return MedicalTestDetailScreen(test: destination);
        }

        return _DestinationErrorScreen(
          onRetry: _retry,
          onFallback: _openFallback,
          fallbackLabel:
              widget.target.destination ==
                  PushNotificationDestination.testDetails
              ? 'Browse tests'
              : 'View bookings',
        );
      },
    );
  }
}

class _DestinationLoadingScreen extends StatelessWidget {
  const _DestinationLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Opening your update…',
                style: TextStyle(
                  color: HomeColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationErrorScreen extends StatelessWidget {
  const _DestinationErrorScreen({
    required this.onRetry,
    required this.onFallback,
    required this.fallbackLabel,
  });

  final VoidCallback onRetry;
  final VoidCallback onFallback;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        backgroundColor: HomeColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Testified update'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: HomeColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: HomeColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'This update could not be opened',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HomeColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'The record may have changed, or your connection may be offline. Try again once.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HomeColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: onFallback, child: Text(fallbackLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
