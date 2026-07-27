import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_diagnostic_app/models/medical_test.dart';
import 'package:medical_diagnostic_app/models/recent_test_search.dart';
import 'package:medical_diagnostic_app/screens/search_screen.dart';
import 'package:medical_diagnostic_app/services/medical_test_catalog_service.dart';
import 'package:medical_diagnostic_app/utils/medical_test_search.dart';
import 'package:medical_diagnostic_app/widgets/app_mobile_viewport.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('single-letter search keeps displayed-name prefixes only', () {
    final filtered = enforceSingleLetterPrefixResults('e', [
      _result(_test('eosinophil', 'Eosinophil Count')),
      _result(_test('egfr', 'eGFR Kidney Filtration')),
      _result(_test('cbc', 'Complete Blood Count')),
    ]);

    expect(
      filtered.map((result) => result.test.displayName),
      ['Eosinophil Count', 'eGFR Kidney Filtration'],
    );
  });

  test('multi-letter search preserves ranked typo-tolerant results', () {
    final results = [
      _result(_test('liver', 'Liver Function Test')),
      _result(_test('lipase', 'Lipase - Serum')),
    ];

    expect(enforceSingleLetterPrefixResults('livr', results), results);
  });

  test('recent searches store the selected test instead of typed text', () {
    final selected = _test('liver', 'Liver Function Test');
    final recent = recordRecentTestSelection(const [], selected);
    final restored = decodeRecentTestSearches(
      recent.map((item) => item.toStorageValue()),
    );

    expect(restored, hasLength(1));
    expect(restored.single.testId, 'liver');
    expect(restored.single.name, 'Liver Function Test');
    expect(restored.single.category, 'Liver Tests');
  });

  testWidgets('idle search shows selected tests from structured history', (
    tester,
  ) async {
    final recent = RecentTestSearch.fromTest(
      _test('liver', 'Liver Function Test'),
    );
    SharedPreferences.setMockInitialValues({
      legacyMedicalTestRecentSearchesStorageKey: ['l'],
      medicalTestRecentSearchesStorageKey: [recent.toStorageValue()],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(catalogService: _FakeSearchRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Liver Function Test'), findsWidgets);
    expect(find.text('l'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.containsKey(legacyMedicalTestRecentSearchesStorageKey),
      isFalse,
    );
  });

  testWidgets('typed search uses a clean suggestion list without match labels', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return AppMobileViewport(child: child ?? const SizedBox.shrink());
        },
        home: SearchScreen(catalogService: _FakeSearchRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Browse by category'), findsOneWidget);
    expect(find.text('Popular tests'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('medical-test-search-field')),
      'e',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Eosinophil Count'), findsOneWidget);
    expect(find.byIcon(Icons.north_west_rounded), findsOneWidget);
    expect(find.text('Closest spelling match'), findsNothing);
    expect(find.textContaining('best matches'), findsNothing);
    expect(find.textContaining('Ranked by'), findsNothing);
    expect(find.text('Browse by category'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeSearchRepository implements MedicalTestSearchRepository {
  @override
  Future<List<MedicalTestCategorySummary>> fetchCategories() async {
    return const [
      MedicalTestCategorySummary(
        name: 'Blood Tests',
        testCount: 2,
        popularCount: 2,
      ),
    ];
  }

  @override
  Future<List<MedicalTestSearchResult>> searchTests(
    String query, {
    String? category,
    int limit = 30,
  }) async {
    if (query.trim().isNotEmpty) {
      return [_result(_test('eosinophil', 'Eosinophil Count'))];
    }

    return [
      _result(_test('cbc', 'Complete Blood Count')),
      _result(_test('liver', 'Liver Function Test')),
    ];
  }
}

MedicalTestSearchResult _result(MedicalTest test) {
  return MedicalTestSearchResult(
    test: test,
    relevance: 100,
    matchReason: 'Closest spelling match',
  );
}

MedicalTest _test(String id, String name) {
  return MedicalTest.fromJson({
    'id': id,
    'name_sheet': name,
    'category': name.startsWith('Liver') ? 'Liver Tests' : 'Blood Tests',
    'test_type': 'individual',
    'mrp': 499,
    'reporting_time': 'Same day',
    'home_collection_available': true,
    'lab_visit_required': false,
    'special_handling_required': false,
    'is_popular': true,
    'included_parameters': <String>[],
    'gender': 'any',
  });
}
