import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_diagnostic_app/models/medical_test.dart';
import 'package:medical_diagnostic_app/widgets/medical_test_catalog/home_medical_test_discovery.dart';

void main() {
  testWidgets(
    'home categories use a two-column medical catalogue grid',
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
                  generatedAt: DateTime.utc(2026, 7, 24),
                  categories: [
                    HomeMedicalTestCategory(
                      name: 'Blood Tests',
                      totalCount: 31,
                      tests: _medicalTests('blood', 'Blood Tests'),
                    ),
                    HomeMedicalTestCategory(
                      name: 'Liver',
                      totalCount: 19,
                      tests: _medicalTests('liver', 'Liver'),
                    ),
                    HomeMedicalTestCategory(
                      name: 'Thyroid',
                      totalCount: 10,
                      tests: _medicalTests('thyroid', 'Thyroid'),
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
      const firstBloodCardKey = ValueKey('home-test-card-blood-0');
      const secondBloodCardKey = ValueKey('home-test-card-blood-1');
      const thirdBloodCardKey = ValueKey('home-test-card-blood-2');

      final bloodModule = find.byKey(bloodModuleKey);
      final liverModule = find.byKey(liverModuleKey);
      final thyroidModule = find.byKey(thyroidModuleKey);
      final firstBloodCard = find.byKey(firstBloodCardKey);
      final secondBloodCard = find.byKey(secondBloodCardKey);
      final thirdBloodCard = find.byKey(thirdBloodCardKey);

      expect(bloodModule, findsOneWidget);
      expect(liverModule, findsOneWidget);
      expect(thyroidModule, findsOneWidget);
      expect(tester.getSize(bloodModule).height, greaterThan(520));
      expect(tester.getSize(liverModule), tester.getSize(bloodModule));
      expect(tester.getSize(thyroidModule), tester.getSize(bloodModule));

      final firstCardSize = tester.getSize(firstBloodCard);
      expect(firstCardSize.height, 214);
      expect(tester.getSize(secondBloodCard), firstCardSize);
      expect(tester.getSize(thirdBloodCard), firstCardSize);

      final firstTopLeft = tester.getTopLeft(firstBloodCard);
      final secondTopLeft = tester.getTopLeft(secondBloodCard);
      final thirdTopLeft = tester.getTopLeft(thirdBloodCard);
      expect(secondTopLeft.dy, firstTopLeft.dy);
      expect(secondTopLeft.dx, greaterThan(firstTopLeft.dx));
      expect(thirdTopLeft.dy, greaterThan(firstTopLeft.dy));
      expect(thirdTopLeft.dx, firstTopLeft.dx);

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
      expect(find.text('Tests by health need'), findsOneWidget);
      expect(find.text('LAB TEST CATALOGUE'), findsNothing);
      expect(find.text('Popular'), findsNWidgets(12));
      expect(find.text('At home'), findsNWidgets(12));
      expect(find.text('Same day'), findsNWidgets(12));
      expect(find.text('20% off'), findsNWidgets(12));
      expect(
        find.byKey(const ValueKey('home-test-visual-blood-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-test-price-blood-0')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('View all').first);
      expect(openedCategory, 'Blood Tests');

      await tester.tap(firstBloodCard);
      expect(openedTest, 'blood-0');
    },
  );

  testWidgets('home test cards stay clear on compact phones', (tester) async {
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HomeMedicalTestDiscovery(
              feed: HomeMedicalTestFeed(
                feedId: 'compact-layout',
                generatedAt: DateTime.utc(2026, 7, 29),
                categories: [
                  HomeMedicalTestCategory(
                    name: 'Blood Tests',
                    totalCount: 31,
                    tests: _medicalTests('compact', 'Blood Tests'),
                  ),
                ],
              ),
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
    await tester.pumpAndSettle();

    const cardKey = ValueKey('home-test-card-compact-0');
    const artworkKey = ValueKey('home-test-artwork-compact-0');
    const statusKey = ValueKey('home-test-status-compact-0');
    const collectionKey = ValueKey('home-test-collection-compact-0');

    final card = find.byKey(cardKey);
    final artwork = find.byKey(artworkKey);
    final status = find.byKey(statusKey);
    final collection = find.byKey(collectionKey);

    expect(tester.getSize(card).height, 228);
    expect(
      tester.getTopRight(status).dx,
      lessThanOrEqualTo(tester.getTopLeft(artwork).dx),
    );
    expect(
      tester.getTopRight(collection).dx,
      lessThanOrEqualTo(tester.getTopLeft(artwork).dx),
    );
    expect(find.text('At home'), findsNWidgets(4));
    expect(find.text('Same day'), findsNWidgets(4));
    expect(find.text('20% off'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}

List<MedicalTest> _medicalTests(String prefix, String category) {
  return List<MedicalTest>.generate(
    4,
    (index) => MedicalTest.fromJson({
      'id': '$prefix-$index',
      'name_sheet': 'Comprehensive Diagnostic Test ${index + 1}',
      'category': category,
      'test_type': 'individual',
      'mrp': 499 + index,
      'reporting_time': 'Same day',
      'sample_source_label': 'Blood sample',
      'home_collection_available': true,
      'lab_visit_required': false,
      'special_handling_required': false,
      'is_popular': true,
      'included_parameters': <String>[],
      'gender': 'any',
    }),
    growable: false,
  );
}
