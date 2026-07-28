import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medical_diagnostic_app/models/collection_slot.dart';
import 'package:medical_diagnostic_app/models/medical_test.dart';
import 'package:medical_diagnostic_app/models/order.dart';
import 'package:medical_diagnostic_app/screens/direct_booking_success_screen.dart';
import 'package:medical_diagnostic_app/screens/order_details_screen.dart';
import 'package:medical_diagnostic_app/utils/app_theme.dart';

void main() {
  test('Order preserves the Supabase booking source', () {
    final direct = Order.fromJson({
      'id': 91,
      'user_id': 'user-id',
      'booking_source': 'direct_test',
      'fulfillment_mode': 'home_collection',
      'prescription_image_url': null,
      'status': 'confirmed',
      'test_list': ['Blood Sugar Test'],
      'price': 56,
      'collection_slot_start_at': '2026-07-29T03:30:00Z',
      'collection_slot_end_at': '2026-07-29T05:30:00Z',
      'collection_slot_timezone': 'Asia/Kolkata',
      'timeline': <Map<String, dynamic>>[],
      'created_at': '2026-07-28T05:12:00Z',
    });
    final legacy = Order.fromJson({
      'id': 92,
      'user_id': 'user-id',
      'status': 'uploaded',
      'test_list': <String>[],
      'price': 0,
      'timeline': <Map<String, dynamic>>[],
      'created_at': '2026-07-28T05:12:00Z',
    });

    expect(direct.isDirectTestBooking, isTrue);
    expect(direct.hasBookedSlot, isTrue);
    expect(direct.collectionSlot!.fullLabel, contains('9:00 AM – 11:00 AM'));
    expect(direct.toJson()['booking_source'], 'direct_test');
    expect(direct.toJson()['fulfillment_mode'], 'home_collection');
    expect(legacy.isPrescriptionBooking, isTrue);
  });

  test('Kolkata collection windows are persisted as UTC instants', () {
    final slot = CollectionSlot.forKolkataDate(
      DateTime(2026, 7, 29),
      startHour: 9,
    );

    expect(slot.startUtc, DateTime.utc(2026, 7, 29, 3, 30));
    expect(slot.endUtc, DateTime.utc(2026, 7, 29, 5, 30));
    expect(slot.toRpcParams(), {
      'p_slot_start_at': '2026-07-29T03:30:00.000Z',
      'p_slot_end_at': '2026-07-29T05:30:00.000Z',
    });
  });

  testWidgets('direct order details lead with the booked test', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: OrderDetailsScreen(order: _directOrder()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Booked test'), findsOneWidget);
    expect(find.text('Blood Sugar Test'), findsOneWidget);
    expect(find.text('Booking total'), findsOneWidget);
    expect(find.text('Estimated total'), findsNothing);
    expect(find.textContaining('C9CH+J7Q'), findsNothing);

    final testTop = tester.getTopLeft(find.text('Blood Sugar Test')).dy;
    final statusTop = tester.getTopLeft(find.text('Collection scheduled')).dy;
    expect(testTop, lessThan(statusTop));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('direct tracking never shows prescription review steps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: TrackingUpdatesScreen(order: _directOrder()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Collection scheduled'), findsOneWidget);
    expect(find.text('Agent assigned'), findsOneWidget);
    expect(find.text('Agent on the way'), findsOneWidget);
    expect(find.text('Sample at lab'), findsOneWidget);
    expect(find.text('Report delivered'), findsOneWidget);
    expect(find.text('Prescription received'), findsNothing);
    expect(find.text('Medical review'), findsNothing);
    expect(find.text('Your approval'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('lab appointment tracking skips home collection stages', (
    tester,
  ) async {
    final labOrder = _directOrder().copyWith(
      fulfillmentMode: 'lab_visit',
      status: 'assigned',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: TrackingUpdatesScreen(order: labOrder),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Lab appointment scheduled'), findsOneWidget);
    expect(find.text('Agent assigned'), findsOneWidget);
    expect(find.text('Sample at lab'), findsOneWidget);
    expect(find.text('Agent on the way'), findsNothing);
    expect(find.text('Sample collected'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('success hand-off is full screen and opens the exact order', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: DirectBookingSuccessScreen(
          order: _directOrder(),
          tests: [_bloodSugarTest()],
          displayDuration: const Duration(milliseconds: 100),
          feedbackEnabled: false,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('direct-booking-success-screen')),
      findsOneWidget,
    );
    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(find.text('Blood Sugar Test'), findsOneWidget);
    expect(find.textContaining('9:00 AM – 11:00 AM IST'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(OrderDetailsScreen), findsOneWidget);
    expect(find.text('Blood Sugar Test'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('checkout and notification regressions remain locked down', () {
    final checkout = File(
      'lib/screens/frictionless_test_booking_screen.dart',
    ).readAsStringSync();
    final bookings =
        File('lib/screens/bookings_screen.dart').readAsStringSync();
    final localNotifications =
        File('lib/services/notification_service.dart').readAsStringSync();
    final androidManifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final pushFunction = File(
      'supabase/functions/deliver-notification/index.ts',
    ).readAsStringSync();

    expect(
      RegExp(r'_ReviewSummary\(').allMatches(checkout),
      hasLength(1),
      reason: 'The duplicate count summary must not be mounted in checkout.',
    );
    expect(checkout, isNot(contains('showGeneralDialog<void>')));
    expect(checkout, contains("'Total'"));
    expect(bookings, contains("ValueKey('booking-search-field')"));
    expect(bookings, contains('MedicalCategoryIllustration('));
    expect(localNotifications, contains('importance: Importance.max'));
    expect(localNotifications, contains('priority: Priority.max'));
    expect(
      localNotifications,
      contains('visibility: NotificationVisibility.private'),
    );
    expect(
      localNotifications,
      contains("'testified_medical_updates_v2'"),
    );
    expect(androidManifest, contains('testified_medical_updates_v2'));
    expect(pushFunction, contains('testified_medical_updates_v2'));
    expect(pushFunction, contains('notification_priority: "PRIORITY_MAX"'));
    expect(pushFunction, contains('visibility: "PRIVATE"'));
    expect(pushFunction, contains('event_time: notificationEventTime'));
  });
}

Order _directOrder() {
  return Order(
    orderId: '91',
    userId: 'user-id',
    prescriptionImagePath: '',
    bookingSource: 'direct_test',
    fulfillmentMode: 'home_collection',
    status: 'confirmed',
    testList: const ['Blood Sugar Test'],
    price: 56,
    patientName: 'Dipankar Sarkar',
    patientLocationAddress: 'C9CH+J7Q, Pundibari, West Bengal, 736165',
    timeline: [
      {
        'status': 'confirmed',
        'timestamp': '2026-07-28T05:12:00Z',
        'source': 'direct_test',
      },
    ],
    createdAt: DateTime.utc(2026, 7, 28, 5, 12),
    collectionSlot: CollectionSlot(
      startUtc: DateTime.utc(2026, 7, 29, 3, 30),
      endUtc: DateTime.utc(2026, 7, 29, 5, 30),
    ),
  );
}

MedicalTest _bloodSugarTest() {
  return MedicalTest.fromJson({
    'id': 'blood-sugar-test',
    'name_sheet': 'Blood Sugar Test',
    'common_name': 'Blood Sugar Test',
    'category': 'Diabetes and Blood Sugar',
    'test_type': 'individual',
    'mrp': 70,
    'reporting_time': 'Same day',
    'sample_source_label': 'Blood sample',
    'home_collection_available': true,
    'lab_visit_required': false,
    'special_handling_required': false,
    'is_popular': true,
    'included_parameters': <String>[],
    'gender': 'any',
  });
}
