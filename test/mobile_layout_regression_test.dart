import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_diagnostic_app/models/medical_test.dart';
import 'package:medical_diagnostic_app/screens/medical_test_detail_screen.dart';
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
}

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
