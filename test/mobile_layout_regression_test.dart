import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_diagnostic_app/models/medical_test.dart';
import 'package:medical_diagnostic_app/models/order.dart';
import 'package:medical_diagnostic_app/screens/bookings_screen.dart';
import 'package:medical_diagnostic_app/screens/medical_test_detail_screen.dart';
import 'package:medical_diagnostic_app/screens/order_details_screen.dart';
import 'package:medical_diagnostic_app/widgets/app_mobile_viewport.dart';
import 'package:medical_diagnostic_app/widgets/medical_test_catalog/home_medical_test_discovery.dart';

void main() {
  const mobileSizes = [
    Size(320, 640),
    Size(360, 800),
    Size(390, 844),
    Size(430, 932),
  ];

  testWidgets('App keeps accessible text scaling inside its tested range', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );
    double? scaledFontSize;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return AppMobileViewport(child: child ?? const SizedBox.shrink());
        },
        home: Builder(
          builder: (context) {
            scaledFontSize = MediaQuery.textScalerOf(context).scale(10);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(scaledFontSize, 13);
  });

  testWidgets('Home test catalogue has no overflow across mobile widths', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue =
        AppMobileViewport.maximumTextScale;
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );

    for (final size in mobileSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return AppMobileViewport(child: child ?? const SizedBox.shrink());
          },
          home: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: HomeMedicalTestDiscovery(
                  feed: _homeFeed,
                  isLoading: false,
                  onRetry: () {},
                  onTestTap: (_) {},
                  onCategoryTap: (_) {},
                  onAllCategoriesTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Home catalogue overflowed at ${size.width} logical pixels.',
      );
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Test details have no overflow across mobile widths', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue =
        AppMobileViewport.maximumTextScale;
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );

    for (final size in mobileSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return AppMobileViewport(child: child ?? const SizedBox.shrink());
          },
          home: MedicalTestDetailScreen(test: _test),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Test details overflowed at ${size.width} logical pixels.',
      );
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Order details have no overflow across mobile widths', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue =
        AppMobileViewport.maximumTextScale;
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );

    for (final size in mobileSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return AppMobileViewport(child: child ?? const SizedBox.shrink());
          },
          home: OrderDetailsScreen(
            order: _responsiveOrder,
            liveUpdates: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));

      expect(
        tester.takeException(),
        isNull,
        reason: 'Order details overflowed at ${size.width} logical pixels.',
      );
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Bookings list has no overflow across mobile widths', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue =
        AppMobileViewport.maximumTextScale;
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );

    for (final size in mobileSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return AppMobileViewport(child: child ?? const SizedBox.shrink());
          },
          home: Scaffold(
            body: SafeArea(
              child: BookingsScreen(
                onBookNewTest: () {},
                ordersStream: Stream.value(_responsiveBookings),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Bookings overflowed at ${size.width} logical pixels.',
      );
    }

    await tester.binding.setSurfaceSize(null);
  });
}

final _responsiveOrder = Order.fromJson({
  'id': 93,
  'user_id': 'responsive-user',
  'booking_source': 'direct_test',
  'fulfillment_mode': 'home_collection',
  'status': 'confirmed',
  'test_list': [
    'Comprehensive Complete Blood Count and Cell Review',
  ],
  'price': 1999,
  'patient_location_address':
      'Near Pundibari-kadamtala Over bridge, Division, Kalarayerkuthi, West Bengal, 736165',
  'collection_slot_start_at': '2026-07-29T05:30:00Z',
  'collection_slot_end_at': '2026-07-29T07:30:00Z',
  'collection_slot_timezone': 'Asia/Kolkata',
  'timeline': <Map<String, dynamic>>[],
  'created_at': '2026-07-28T05:00:00Z',
});

final _responsiveBookings = [
  Order.fromJson({
    'id': 93,
    'user_id': 'responsive-user',
    'booking_source': 'direct_test',
    'fulfillment_mode': 'home_collection',
    'status': 'confirmed',
    'test_list': [
      'Comprehensive Complete Blood Count and Cell Review',
    ],
    'price': 1999,
    'patient_name': 'Dipangkar Sarkar',
    'timeline': <Map<String, dynamic>>[],
    'created_at': '2026-07-28T05:00:00Z',
  }),
  Order.fromJson({
    'id': 92,
    'user_id': 'responsive-user',
    'booking_source': 'direct_test',
    'fulfillment_mode': 'home_collection',
    'status': 'booking_requested',
    'test_list': ['Liver Function Test'],
    'price': 679,
    'patient_name': 'A family member with a long name',
    'timeline': <Map<String, dynamic>>[],
    'created_at': '2026-07-27T16:48:00Z',
  }),
];

final _test = MedicalTest.fromJson({
  'id': 'responsive-test',
  'name_sheet': 'Comprehensive Complete Blood Count and Cell Review',
  'common_name': 'Complete Blood Count (CBC) with Differential',
  'category': 'Blood Tests and Coagulation',
  'test_type': 'panel',
  'mrp': 2499,
  'reporting_time': 'Same day after laboratory verification',
  'sample_source_label': 'Venous blood sample',
  'purpose': 'Checks the major blood-cell groups and related measurements.',
  'preparation': 'No fasting is usually needed unless your clinician says so.',
  'home_collection_available': true,
  'lab_visit_required': false,
  'special_handling_required': false,
  'is_popular': true,
  'parameter_count': 3,
  'included_parameters': ['Haemoglobin', 'Platelets', 'White blood cells'],
  'gender': 'any',
});

final _homeFeed = HomeMedicalTestFeed(
  feedId: 'mobile-layout',
  generatedAt: DateTime.utc(2026, 7, 27),
  categories: [
    HomeMedicalTestCategory(
      name: 'Blood Tests and Coagulation',
      totalCount: 4,
      tests: List<MedicalTest>.generate(
        4,
        (index) => MedicalTest.fromJson({
          'id': 'responsive-$index',
          'name_sheet':
              'Comprehensive Diagnostic Blood Test ${index + 1}',
          'category': 'Blood Tests and Coagulation',
          'test_type': 'panel',
          'mrp': 2499 + index,
          'reporting_time': 'Same day',
          'sample_source_label': 'Venous blood sample',
          'home_collection_available': true,
          'lab_visit_required': false,
          'special_handling_required': false,
          'is_popular': true,
          'parameter_count': 12,
          'included_parameters': <String>[],
          'gender': 'any',
        }),
      ),
    ),
  ],
);
