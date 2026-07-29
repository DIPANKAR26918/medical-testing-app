import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_diagnostic_app/models/app_user.dart';
import 'package:medical_diagnostic_app/models/medical_test.dart';
import 'package:medical_diagnostic_app/services/medical_test_catalog_service.dart';
import 'package:medical_diagnostic_app/services/personalized_test_recommendation_service.dart';
import 'package:medical_diagnostic_app/services/test_view_history_service.dart';
import 'package:medical_diagnostic_app/widgets/home/home_personalized_recommendations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('view signals are minimal, ranked and isolated per signed-in user', () async {
    var now = DateTime.utc(2026, 7, 29, 8);
    final firstUserHistory = TestViewHistoryService(
      userIdProvider: () => 'user-one',
      now: () => now,
    );
    final secondUserHistory = TestViewHistoryService(
      userIdProvider: () => 'user-two',
      now: () => now,
    );

    await firstUserHistory.recordView(_test('blood-sugar', 'Blood Sugar Test'));
    now = now.add(const Duration(hours: 1));
    await firstUserHistory.recordView(_test('haemoglobin', 'Hemoglobin Test'));
    now = now.add(const Duration(hours: 1));
    await firstUserHistory.recordView(_test('blood-sugar', 'Blood Sugar Test'));

    final signals = await firstUserHistory.loadSignals();
    final otherUserSignals = await secondUserHistory.loadSignals();
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(
      TestViewHistoryService.storageKeyForUser('user-one'),
    );

    expect(signals.map((signal) => signal.testId), [
      'blood-sugar',
      'haemoglobin',
    ]);
    expect(signals.first.viewCount, 2);
    expect(otherUserSignals, isEmpty);
    expect(stored, isNotNull);
    final serialized = stored!.join();
    expect(serialized, isNot(contains('Blood Sugar Test')));
    expect(serialized, isNot(contains('Blood Tests')));
  });

  test('preventive rules stay inside official age and gender cohorts', () {
    final service = PersonalizedTestRecommendationService(
      catalogRepository: _FakeCatalogRepository(const []),
      viewHistory: _FakeViewHistory(),
    );

    expect(service.preventiveRulesFor(_profile(age: 29, gender: 'male')), isEmpty);
    expect(
      service
          .preventiveRulesFor(_profile(age: 30, gender: 'male'))
          .map((rule) => rule.testCode),
      ['G0060 - G0065'],
    );
    expect(
      service
          .preventiveRulesFor(_profile(age: 35, gender: 'female'))
          .map((rule) => rule.testCode),
      ['G0060 - G0065', 'H0002'],
    );
    expect(
      service
          .preventiveRulesFor(_profile(age: 50, gender: 'female'))
          .map((rule) => rule.testCode),
      ['G0060 - G0065'],
    );
  });

  testWidgets('personalized rails explain every suggestion without diagnosis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final viewedTest = _test('viewed', 'Blood Sugar Test');
    final preventiveTest = _test('preventive', 'Hemoglobin Test');
    String? openedTestId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: HomePersonalizedRecommendations(
              recommendations: PersonalizedTestRecommendations(
                fromActivity: [
                  PersonalizedTestRecommendation(
                    test: viewedTest,
                    source: PersonalizedRecommendationSource.activity,
                    badgeLabel: 'Viewed 3 times',
                    reason: 'Easy access to a test you keep checking.',
                  ),
                ],
                preventive: [
                  PersonalizedTestRecommendation(
                    test: preventiveTest,
                    source: PersonalizedRecommendationSource.preventive,
                    badgeLabel: 'Women 20–49',
                    reason:
                        'Anaemia Mukt Bharat includes women aged 20–49. '
                        'A haemoglobin check can support anaemia screening.',
                    guidanceSourceLabel: 'NHM Anaemia Mukt Bharat',
                    guidanceSourceUrl: 'https://nhm.gov.in/',
                  ),
                ],
                profileNeedsDetails: false,
              ),
              isLoading: false,
              onTestTap: (test) => openedTestId = test.id,
              onClearActivity: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Picked for you'), findsOneWidget);
    expect(find.text('Based on what you viewed'), findsOneWidget);
    expect(find.text('Preventive checks for you'), findsOneWidget);
    expect(find.textContaining('not a diagnosis'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('personalized-activity-viewed')),
    );
    expect(openedTestId, 'viewed');

    await tester.tap(find.text('Why these?'));
    await tester.pumpAndSettle();

    expect(find.text('How recommendations work'), findsOneWidget);
    expect(find.text('Your viewing activity stays here'), findsOneWidget);
    expect(find.text('Preventive, not predictive'), findsOneWidget);
  });
}

AppUser _profile({required int age, required String gender}) {
  return AppUser(
    userId: 'user',
    age: age,
    gender: gender,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

MedicalTest _test(String id, String name) {
  return MedicalTest.fromJson({
    'id': id,
    'test_code': id,
    'name_sheet': name,
    'common_name': name,
    'category': 'Blood Tests',
    'test_type': 'individual',
    'mrp': 250,
    'reporting_time': 'Same Day',
    'home_collection_available': true,
    'lab_visit_required': false,
    'special_handling_required': false,
    'is_popular': true,
    'included_parameters': <String>[],
    'gender': 'any',
  });
}

class _FakeCatalogRepository implements MedicalTestRecommendationRepository {
  const _FakeCatalogRepository(this.tests);

  final List<MedicalTest> tests;

  @override
  Future<List<MedicalTest>> fetchTestsByCodes(
    Iterable<String> testCodes,
  ) async {
    final codes = testCodes.toSet();
    return tests.where((test) => codes.contains(test.testCode)).toList();
  }

  @override
  Future<List<MedicalTest>> fetchTestsByIds(Iterable<String> testIds) async {
    final ids = testIds.toSet();
    return tests.where((test) => ids.contains(test.id)).toList();
  }
}

class _FakeViewHistory implements TestViewSignalRepository {
  @override
  Future<void> clearHistory() async {}

  @override
  Future<List<TestViewSignal>> loadSignals({int limit = 4}) async {
    return const [];
  }
}
