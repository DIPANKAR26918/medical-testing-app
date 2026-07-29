import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medical_diagnostic_app/models/collection_slot.dart';
import 'package:medical_diagnostic_app/models/medical_test.dart';
import 'package:medical_diagnostic_app/models/order.dart';
import 'package:medical_diagnostic_app/screens/direct_booking_success_screen.dart';
import 'package:medical_diagnostic_app/screens/order_details_screen.dart';
import 'package:medical_diagnostic_app/utils/app_theme.dart';
import 'package:medical_diagnostic_app/utils/app_time.dart';
import 'package:medical_diagnostic_app/widgets/collection_slot_picker.dart';

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
        home: OrderDetailsScreen(
          order: _directOrder(),
          liveUpdates: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Booked test'), findsOneWidget);
    expect(find.text('Blood Sugar Test'), findsOneWidget);
    expect(find.text('Booking total'), findsOneWidget);
    expect(find.text('Estimated total'), findsNothing);
    expect(find.textContaining('C9CH+J7Q'), findsNothing);
    expect(find.text('Collection details'), findsOneWidget);
    expect(find.text('Sample collection slot'), findsOneWidget);
    expect(find.text('Collection address'), findsOneWidget);
    expect(find.text('Booking progress'), findsOneWidget);
    expect(find.text('Pickup is scheduled for this address.'), findsNothing);
    expect(
      find.byKey(const ValueKey('booked-tests-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('collection-details-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('booking-progress-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('booking-progress-timeline-action')),
      findsOneWidget,
    );

    final testTop = tester.getTopLeft(find.text('Blood Sugar Test')).dy;
    final statusTop = tester.getTopLeft(find.text('Collection scheduled')).dy;
    expect(testTop, lessThan(statusTop));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('missing direct slot has one clear action and no fake progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: OrderDetailsScreen(
          order: _directOrderWithoutSlot(),
          liveUpdates: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Collection details'), findsOneWidget);
    expect(find.text('Sample collection slot'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);
    expect(
      find.text('Choose the day and two-hour window before booking.'),
      findsOneWidget,
    );
    expect(find.text('Collection address'), findsOneWidget);
    expect(find.text('Booking progress'), findsNothing);
    expect(find.text('Choose your appointment slot'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('direct tracking never shows prescription review steps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: TrackingUpdatesScreen(
          order: _directOrder(),
          liveUpdates: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Collection scheduled'), findsWidgets);
    expect(find.text('Agent assigned'), findsWidgets);
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
        home: TrackingUpdatesScreen(
          order: labOrder,
          liveUpdates: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Lab appointment scheduled'), findsOneWidget);
    expect(find.text('Agent assigned'), findsWidgets);
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
          liveUpdatesOnDetails: false,
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

  testWidgets('collection slot list scrolls without overflowing compact phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final tomorrow = AppTime.kolkataToday().add(const Duration(days: 1));
    final current = CollectionSlot.forKolkataDate(tomorrow, startHour: 7);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showCollectionSlotPicker(
                    context,
                    current: current,
                    labVisit: false,
                  ),
                  child: const Text('Choose slot'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Choose slot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('collection-slot-list')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final lastSlot = CollectionSlot.forKolkataDate(
      tomorrow,
      startHour: 17,
    ).timeLabel;
    final slotList = find.byKey(const ValueKey('collection-slot-list'));
    final slotScrollable = find.descendant(
      of: slotList,
      matching: find.byType(Scrollable),
    );
    expect(slotScrollable, findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(lastSlot),
      180,
      scrollable: slotScrollable,
    );
    expect(find.text(lastSlot), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('prescription confirmation reuses the full-screen booking success', () {
    final review = File(
      'lib/screens/prescription_review_screen.dart',
    ).readAsStringSync();

    expect(review, contains('DirectBookingSuccessScreen('));
    expect(review, isNot(contains('_BookingConfirmedSheet')));
  });

  test('test details open the shared checkout without a catalogue hop', () {
    final details = File(
      'lib/screens/medical_test_detail_screen.dart',
    ).readAsStringSync();
    final booking = File(
      'lib/screens/frictionless_test_booking_screen.dart',
    ).readAsStringSync();
    final checkout = File(
      'lib/screens/direct_test_checkout_screen.dart',
    ).readAsStringSync();
    final app = File('lib/main.dart').readAsStringSync();

    expect(details, contains('startDirectTestBookingFlow('));
    expect(details, isNot(contains("pushNamed('/all-categories'")));
    expect(details, contains("ValueKey('test-detail-booking-cta')"));
    expect(booking, contains('startDirectTestBookingFlow('));
    expect(booking, isNot(contains('final MedicalTest? initialTest;')));
    expect(checkout, contains('Future<bool> startDirectTestBookingFlow('));
    expect(
      checkout,
      contains('Future<Order?> showDirectTestBookingSheet('),
    );
    expect(checkout, contains('isScrollControlled: true'));
    expect(checkout, contains('useSafeArea: true'));
    expect(
      app,
      contains('const FrictionlessTestBookingScreen()'),
    );
  });

  test('bottom navigation icons use the standard 24 logical pixels', () {
    final navigation = File('lib/screens/home_screen.dart').readAsStringSync();

    expect(navigation, contains('size: 24'));
    expect(navigation, isNot(contains('size: selected ? 28 : 27')));
  });

  test('checkout and notification regressions remain locked down', () {
    final checkout =
        File('lib/screens/direct_test_checkout_screen.dart').readAsStringSync();
    final bookings =
        File('lib/screens/bookings_screen.dart').readAsStringSync();
    final localNotifications =
        File('lib/services/notification_service.dart').readAsStringSync();
    final androidManifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final pushFunction = File(
      'supabase/functions/deliver-notification/index.ts',
    ).readAsStringSync();

    expect(checkout, isNot(contains('_ReviewSummary(')));
    expect(checkout, isNot(contains('showGeneralDialog<void>')));
    expect(checkout, contains("'Total'"));
    expect(checkout, contains("'Selected test'"));
    expect(checkout, contains("'Collection details'"));
    expect(bookings, isNot(contains("ValueKey('booking-search-field')")));
    expect(bookings, isNot(contains('class _BookingSearchField')));
    expect(bookings, isNot(contains('class _BookingTabs')));
    expect(bookings, isNot(contains('_selectedTab')));
    expect(bookings, contains("ValueKey('bookings-flat-list')"));
    expect(bookings, contains("'My bookings'"));
    expect(
      bookings,
      contains('if (index > 0) const SizedBox(height: 12)'),
    );
    expect(bookings, isNot(contains('const Divider(')));
    expect(
      bookings,
      contains('padding: const EdgeInsets.fromLTRB(20, 18, 14, 18)'),
    );
    expect(bookings, contains("final statusHeadline = '\${status.label}"));
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

Order _directOrderWithoutSlot() {
  return Order(
    orderId: '92',
    userId: 'user-id',
    prescriptionImagePath: '',
    bookingSource: 'direct_test',
    fulfillmentMode: 'home_collection',
    status: 'booking_requested',
    testList: const ['CRP Inflammation Test'],
    price: 319,
    patientName: 'Dipankar Sarkar',
    patientLocationAddress: 'C9CH+J7Q, Pundibari, West Bengal, 736165',
    timeline: [
      {
        'status': 'booking_requested',
        'timestamp': '2026-07-28T05:12:00Z',
        'source': 'direct_test',
      },
    ],
    createdAt: DateTime.utc(2026, 7, 28, 5, 12),
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
