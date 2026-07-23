import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medical_diagnostic_app/models/order.dart';
import 'package:medical_diagnostic_app/screens/prescription_submitted_screen.dart';
import 'package:medical_diagnostic_app/screens/prescription_upload_success_screen.dart';
import 'package:medical_diagnostic_app/utils/app_theme.dart';

void main() {
  testWidgets('successful upload pauses on a focused confirmation', (
    tester,
  ) async {
    final order = _prescriptionOrder();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: PrescriptionUploadSuccessScreen(
          order: order,
          displayDuration: const Duration(milliseconds: 100),
          feedbackEnabled: false,
        ),
      ),
    );

    expect(find.text('Prescription uploaded'), findsOneWidget);
    expect(find.text('Sent securely for medical review.'), findsOneWidget);
    expect(find.textContaining(order.orderId), findsNothing);

    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PrescriptionSubmittedScreen), findsOneWidget);
    expect(find.text('Prescription sent for review'), findsOneWidget);
    expect(find.textContaining(order.orderId), findsNothing);
  });

  testWidgets('submitted request does not expose its database identifier', (
    tester,
  ) async {
    final order = _prescriptionOrder();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: PrescriptionSubmittedScreen(order: order),
      ),
    );

    expect(find.text('Review request'), findsOneWidget);
    expect(find.textContaining(order.orderId), findsNothing);
    expect(find.textContaining('#'), findsNothing);
  });

  test('user-facing order views do not format raw database IDs', () {
    const paths = [
      'lib/screens/prescription_submitted_screen.dart',
      'lib/screens/prescription_review_screen.dart',
      'lib/screens/test_status_screen.dart',
      'lib/widgets/home/recent_orders_section.dart',
      'lib/widgets/order_card.dart',
    ];
    final rawIdLabel = RegExp(
      r'(?:Request|Order)?\s*#\$\{(?:widget\.)?order\.orderId',
    );

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(
        rawIdLabel.hasMatch(source),
        isFalse,
        reason: '$path must not expose a Supabase order ID',
      );
    }
  });
}

Order _prescriptionOrder() {
  return Order(
    orderId: '23',
    userId: 'user-id',
    prescriptionImagePath: 'private/prescription.jpg',
    status: 'uploaded',
    testList: const [],
    price: 0,
    patientName: 'Dipankar Sarkar',
    patientLocationAddress: 'Pundibari, West Bengal, 736165',
    timeline: const [],
    createdAt: DateTime.utc(2026, 7, 23, 4, 36),
  );
}
