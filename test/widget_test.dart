import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medical_diagnostic_app/models/location_data.dart';
import 'package:medical_diagnostic_app/models/medical_test.dart';
import 'package:medical_diagnostic_app/screens/home_dashboard_screen.dart';
import 'package:medical_diagnostic_app/screens/medical_test_detail_screen.dart';
import 'package:medical_diagnostic_app/widgets/medical_test_catalog/home_medical_test_discovery.dart';
import 'package:medical_diagnostic_app/widgets/medical_test_catalog/medical_test_catalog_widgets.dart';

void main() {
  test('LocationData round-trips through JSON', () {
    final location = LocationData(
      type: LocationType.precise,
      displayAddress: '123 Main Street',
      latitude: 12.34,
      longitude: 56.78,
      updatedAt: DateTime.utc(2024, 1, 1),
    );

    final restored = LocationData.fromJson(location.toJson());

    expect(restored.displayAddress, '123 Main Street');
    expect(restored.latitude, 12.34);
    expect(restored.longitude, 56.78);
    expect(restored.isPrecise, isTrue);
  });

  test('MedicalTest parses Supabase values and formats its price', () {
    final test = MedicalTest.fromJson({
      'id': 'test-id',
      'name_sheet': 'Complete Blood Count',
      'common_name': 'CBC',
      'category': 'Blood Tests',
      'test_type': 'panel',
      'mrp': '499.00',
      'home_collection_available': true,
      'lab_visit_required': false,
      'special_handling_required': false,
      'is_popular': true,
      'included_parameters': ['Haemoglobin', 'Platelets'],
      'gender': 'any',
    });

    expect(test.displayName, 'CBC');
    expect(test.priceLabel, '₹499');
    expect(test.testTypeLabel, 'Test panel');
    expect(test.includedParameters, hasLength(2));
  });

  test('HomeMedicalTestFeed parses category modules', () {
    final feed = HomeMedicalTestFeed.fromJson({
      'feed_id': 'feed-id',
      'generated_at': '2026-07-14T17:21:53Z',
      'categories': [
        {
          'name': 'Kidney',
          'total_count': 8,
          'tests': [
            {
              'id': 'kidney-test',
              'name_sheet': 'Creatinine',
              'category': 'Kidney',
              'test_type': 'individual',
              'home_collection_available': true,
              'lab_visit_required': false,
              'special_handling_required': false,
              'is_popular': true,
              'included_parameters': <String>[],
              'gender': 'any',
            },
          ],
        },
      ],
    });

    expect(feed.feedId, 'feed-id');
    expect(feed.categories, hasLength(1));
    expect(feed.categories.single.totalCount, 8);
    expect(feed.categories.single.tests.single.displayName, 'Creatinine');
  });

  testWidgets('Medical test card presents key booking information', (
    tester,
  ) async {
    var tapped = false;
    final medicalTest = _catalogueTest();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 210,
              child: MedicalTestCompactCard(
                test: medicalTest,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('CBC'), findsOneWidget);
    expect(find.text('₹499'), findsOneWidget);
    expect(find.text('Same day'), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);

    await tester.tap(find.byType(MedicalTestCompactCard));
    expect(tapped, isTrue);
  });

  testWidgets('Medical test detail keeps essential facts above the fold', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MedicalTestDetailScreen(test: _catalogueTest())),
    );
    await tester.pumpAndSettle();

    expect(find.text('CBC'), findsOneWidget);
    expect(find.text('₹499'), findsOneWidget);
    expect(find.text('Home sample collection available'), findsOneWidget);
    expect(find.text('Everything you need to know'), findsOneWidget);
  });

  testWidgets('Home shows a full dashboard skeleton while the feed changes', (
    tester,
  ) async {
    final feedCompleter = Completer<HomeMedicalTestFeed>();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeDashboardScreen(
          onBookTest: () {},
          onViewReports: () {},
          onUploadPrescription: () {},
          onSearch: () {},
          onViewCategories: () {},
          homeFeedLoader: () => feedCompleter.future,
          profileLoader: () async => null,
        ),
      ),
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-full-skeleton')),
      findsOneWidget,
    );
    expect(find.text('Explore tests by health need'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    feedCompleter.complete(_homeFeed('loaded-feed', 'Blood Tests'));
    await tester.pump();
  });

  testWidgets('Discovery relies on pull-to-refresh instead of a refresh icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeMedicalTestDiscovery(
              feed: _homeFeed('feed-id', 'Kidney'),
              isLoading: false,
              onRetry: () {},
              onTestTap: (_) {},
              onCategoryTap: (_) {},
              onAllCategoriesTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Explore tests by health need'), findsOneWidget);
    expect(find.byTooltip('Refresh test recommendations'), findsNothing);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    expect(find.text('All tests'), findsOneWidget);
  });
}

HomeMedicalTestFeed _homeFeed(String feedId, String category) {
  return HomeMedicalTestFeed(
    feedId: feedId,
    generatedAt: DateTime.utc(2026, 7, 15),
    categories: [
      HomeMedicalTestCategory(
        name: category,
        totalCount: 1,
        tests: [_catalogueTest(category: category)],
      ),
    ],
  );
}

MedicalTest _catalogueTest({String category = 'Blood Tests'}) {
  return MedicalTest.fromJson({
    'id': 'test-id',
    'name_sheet': 'Complete Blood Count',
    'common_name': 'CBC',
    'category': category,
    'test_type': 'panel',
    'mrp': 499,
    'reporting_time': 'Same day',
    'sample_source_label': 'Blood sample',
    'purpose': 'Checks major blood-cell groups.',
    'preparation': 'No fasting is required.',
    'home_collection_available': true,
    'lab_visit_required': false,
    'special_handling_required': false,
    'is_popular': true,
    'parameter_count': 2,
    'included_parameters': ['Haemoglobin', 'Platelets'],
    'gender': 'any',
  });
}
