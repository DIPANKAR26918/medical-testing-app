import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_diagnostic_app/models/medical_test.dart';
import 'package:medical_diagnostic_app/widgets/medical_test_catalog/home_medical_test_discovery.dart';

void main() {
  testWidgets(
    'home category modules use soft medical gradients without decoration',
    (tester) async {
      String? openedCategory;
      String? openedTest;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeMedicalTestDiscovery(
                feed: HomeMedicalTestFeed(
                  feedId: 'layout-regression',
                  generatedAt: DateTime.utc(2026, 7, 23),
                  categories: [
                    HomeMedicalTestCategory(
                      name: 'Blood Tests',
                      totalCount: 31,
                      tests: [_medicalTest('blood-test', 'Blood Tests')],
                    ),
                    HomeMedicalTestCategory(
                      name: 'Liver',
                      totalCount: 14,
                      tests: [_medicalTest('liver-test', 'Liver')],
                    ),
                    HomeMedicalTestCategory(
                      name: 'Thyroid',
                      totalCount: 9,
                      tests: [_medicalTest('thyroid-test', 'Thyroid')],
                    ),
                  ],
                ),
                isLoading: false,
                onRetry: () {},
                onTestTap: (test) => openedTest = test.id,
                onCategoryTap: (category) => openedCategory = category,
                onAllCategoriesTap: () {},
              ),
            ),
          ),
        ),
      );

      const bloodModuleKey = ValueKey('home-category-module-Blood Tests');
      const liverModuleKey = ValueKey('home-category-module-Liver');
      const thyroidModuleKey = ValueKey('home-category-module-Thyroid');
      const bloodCardKey = ValueKey('home-test-card-blood-test');
      const liverCardKey = ValueKey('home-test-card-liver-test');
      const thyroidCardKey = ValueKey('home-test-card-thyroid-test');

      final bloodModule = find.byKey(bloodModuleKey);
      final liverModule = find.byKey(liverModuleKey);
      final thyroidModule = find.byKey(thyroidModuleKey);
      final bloodCard = find.byKey(bloodCardKey);
      final liverCard = find.byKey(liverCardKey);
      final thyroidCard = find.byKey(thyroidCardKey);

      expect(bloodModule, findsOneWidget);
      expect(liverModule, findsOneWidget);
      expect(thyroidModule, findsOneWidget);
      expect(tester.getSize(bloodModule).height, 408);
      expect(tester.getSize(liverModule), tester.getSize(bloodModule));
      expect(tester.getSize(thyroidModule), tester.getSize(bloodModule));

      final bloodCardSize = tester.getSize(bloodCard);
      expect(bloodCardSize.width, 238);
      expect(bloodCardSize.height, greaterThanOrEqualTo(276));
      expect(tester.getSize(liverCard), bloodCardSize);
      expect(tester.getSize(thyroidCard), bloodCardSize);

      final bloodDecoration =
          tester.widget<Container>(bloodModule).decoration! as BoxDecoration;
      final liverDecoration =
          tester.widget<Container>(liverModule).decoration! as BoxDecoration;
      final thyroidDecoration =
          tester.widget<Container>(thyroidModule).decoration! as BoxDecoration;

      expect(bloodDecoration.color, isNull);
      expect((bloodDecoration.gradient! as LinearGradient).colors, const [
        Color(0xFFD5E7F5),
        Color(0xFFEEF6FB),
      ]);
      expect((liverDecoration.gradient! as LinearGradient).colors, const [
        Color(0xFFD5F3E9),
        Color(0xFFEFFBF7),
      ]);
      expect((thyroidDecoration.gradient! as LinearGradient).colors, const [
        Color(0xFFE7E2FF),
        Color(0xFFF5F3FF),
      ]);

      final decorativeCircles = find.descendant(
        of: bloodModule,
        matching: find.byWidgetPredicate((widget) {
          final decoration = switch (widget) {
            Container(:final decoration) => decoration,
            DecoratedBox(:final decoration) => decoration,
            _ => null,
          };
          return decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle;
        }),
      );
      final categoryGradients = find.descendant(
        of: bloodModule,
        matching: find.byWidgetPredicate((widget) {
          final decoration = switch (widget) {
            Container(:final decoration) => decoration,
            DecoratedBox(:final decoration) => decoration,
            _ => null,
          };
          return decoration is BoxDecoration && decoration.gradient != null;
        }),
      );

      expect(decorativeCircles, findsNothing);
      expect(categoryGradients, findsOneWidget);
      expect(find.text('LAB TEST CATALOGUE'), findsOneWidget);
      expect(find.text('Common'), findsNWidgets(3));

      await tester.tap(find.text('See tests').first);
      expect(openedCategory, 'Blood Tests');

      await tester.tap(bloodCard);
      expect(openedTest, 'blood-test');
    },
  );
}

MedicalTest _medicalTest(String id, String category) {
  return MedicalTest.fromJson({
    'id': id,
    'name_sheet': 'Comprehensive Diagnostic Test With A Longer Name',
    'category': category,
    'test_type': 'individual',
    'mrp': 499,
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
