import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_diagnostic_app/models/medical_test.dart';
import 'package:medical_diagnostic_app/widgets/medical_test_catalog/home_medical_test_discovery.dart';

void main() {
  testWidgets(
    'home category modules stay equal, roomy, and free of warm gradients',
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
      const bloodCardKey = ValueKey('home-test-card-blood-test');

      final bloodModule = find.byKey(bloodModuleKey);
      final liverModule = find.byKey(liverModuleKey);
      final bloodCard = find.byKey(bloodCardKey);

      expect(bloodModule, findsOneWidget);
      expect(liverModule, findsOneWidget);
      expect(tester.getSize(bloodModule).height, 392);
      expect(tester.getSize(liverModule), tester.getSize(bloodModule));
      expect(tester.getSize(bloodCard), const Size(238, 284));

      final moduleWidget = tester.widget<Container>(bloodModule);
      final moduleDecoration = moduleWidget.decoration! as BoxDecoration;
      expect(moduleDecoration.color, const Color(0xFFF8FAFD));
      expect(moduleDecoration.gradient, isNull);

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
      final decorativeGradients = find.descendant(
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
      expect(decorativeGradients, findsNothing);

      await tester.tap(find.text('View all').first);
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
