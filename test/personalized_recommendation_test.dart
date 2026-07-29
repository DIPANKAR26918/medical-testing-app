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

  test(
    'multi-signal history is weighted, minimal and isolated per user',
    () async {
      var now = DateTime.utc(2026, 7, 29, 8);
      final firstUserHistory = TestViewHistoryService(
        userIdProvider: () => 'user-one',
        now: () => now,
      );
      final secondUserHistory = TestViewHistoryService(
        userIdProvider: () => 'user-two',
        now: () => now,
      );
      final sugar = _test('blood-sugar', 'Blood Sugar Test');
      final haemoglobin = _test('haemoglobin', 'Hemoglobin Test');

      await firstUserHistory.recordView(sugar);
      now = now.add(const Duration(hours: 1));
      await firstUserHistory.recordInteraction(
        haemoglobin,
        TestInteractionType.searchOpen,
      );
      now = now.add(const Duration(hours: 1));
      await firstUserHistory.recordInteraction(
        sugar,
        TestInteractionType.bookingStart,
      );

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
      expect(signals.first.detailViews, 1);
      expect(signals.first.bookingStarts, 1);
      expect(
        signals.first.weightedStrength,
        greaterThan(signals[1].weightedStrength),
      );
      expect(otherUserSignals, isEmpty);
      expect(stored, isNotNull);

      final serialized = stored!.join();
      expect(serialized, isNot(contains('Blood Sugar Test')));
      expect(serialized, isNot(contains('Blood Tests')));
      expect(serialized, isNot(contains('diabetes symptoms')));
    },
  );

  test('legacy view history migrates without losing the signal', () async {
    final legacyKey = TestViewHistoryService.legacyStorageKeyForUser('user');
    SharedPreferences.setMockInitialValues({
      legacyKey: [
        '{"test_id":"legacy-test","view_count":2,'
            '"last_viewed_at":"2026-07-29T08:00:00.000Z"}',
      ],
    });
    final history = TestViewHistoryService(
      userIdProvider: () => 'user',
      now: () => DateTime.utc(2026, 7, 29, 9),
    );

    final migrated = await history.loadSignals();
    expect(migrated.single.detailViews, 2);

    await history.recordInteraction(
      _test('legacy-test', 'Legacy Test'),
      TestInteractionType.categoryOpen,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(legacyKey), isFalse);
    expect(
      preferences.containsKey(
        TestViewHistoryService.storageKeyForUser('user'),
      ),
      isTrue,
    );
  });

  test('preventive rules stay inside official age and gender cohorts', () {
    final service = PersonalizedTestRecommendationService(
      catalogRepository: _FakeCatalogRepository(),
      interactionHistory: _FakeInteractionHistory(),
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

  test('service forwards compact signals and preserves ranked explanations', () async {
    final rankedTest = _test('ranked', 'Thyroid Profile');
    final repository = _FakeCatalogRepository(
      rankedCandidates: [
        RankedMedicalTestCandidate(
          test: rankedTest,
          score: 7.4,
          strategy: 'related_category',
          badgeLabel: 'More for you',
          reason: 'More from Thyroid based on what you explored.',
          modelVersion: 'hybrid-content-v2',
        ),
      ],
    );
    final service = PersonalizedTestRecommendationService(
      catalogRepository: repository,
      interactionHistory: _FakeInteractionHistory(
        signals: [
          TestInterestSignal(
            testId: 'anchor',
            detailViews: 2,
            searchOpens: 1,
            categoryOpens: 0,
            recommendationOpens: 0,
            bookingStarts: 0,
            bookingConfirmations: 0,
            lastInteractedAt: DateTime.utc(2026, 7, 29, 8),
          ),
        ],
      ),
    );

    final result = await service.loadFor(_profile(age: 29, gender: 'male'));

    expect(repository.receivedSignals.single['test_id'], 'anchor');
    expect(repository.receivedSignals.single['search_opens'], 1);
    expect(result.hasBehavioralSignals, isTrue);
    expect(result.forYou.single.test.id, 'ranked');
    expect(result.forYou.single.strategy, 'related_category');
    expect(result.forYou.single.modelVersion, 'hybrid-content-v2');
  });

  testWidgets('personalized rails explain ranking without diagnosis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recommendedTest = _test('recommended', 'Blood Sugar Test');
    final preventiveTest = _test('preventive', 'Hemoglobin Test');
    String? openedTestId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: HomePersonalizedRecommendations(
              recommendations: PersonalizedTestRecommendations(
                forYou: [
                  PersonalizedTestRecommendation(
                    test: recommendedTest,
                    source: PersonalizedRecommendationSource.discovery,
                    badgeLabel: 'Related',
                    reason:
                        'Related to HbA1c from your recent activity.',
                    strategy: 'related_body',
                    modelVersion: 'hybrid-content-v2',
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
                hasBehavioralSignals: true,
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
    expect(find.text('Recommended for you'), findsOneWidget);
    expect(find.text('Re-ranked from your recent activity'), findsOneWidget);
    expect(find.text('Preventive checks for you'), findsOneWidget);
    expect(find.textContaining('not a diagnosis'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('personalized-discovery-recommended')),
    );
    expect(openedTestId, 'recommended');

    await tester.tap(find.text('Why these?'));
    await tester.pumpAndSettle();

    expect(find.text('How recommendations work'), findsOneWidget);
    expect(find.text('Actions have different weight'), findsOneWidget);
    expect(find.text('Your activity stays on this device'), findsOneWidget);
    expect(find.text('Fresh, but not random'), findsOneWidget);
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
  _FakeCatalogRepository({
    this.tests = const [],
    this.rankedCandidates = const [],
  });

  final List<MedicalTest> tests;
  final List<RankedMedicalTestCandidate> rankedCandidates;
  List<Map<String, dynamic>> receivedSignals = const [];

  @override
  Future<List<RankedMedicalTestCandidate>> fetchPersonalizedCandidates({
    required Iterable<Map<String, dynamic>> interactionSignals,
    int? age,
    String? gender,
    int limit = 10,
  }) async {
    receivedSignals = interactionSignals.toList(growable: false);
    return rankedCandidates;
  }

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

class _FakeInteractionHistory implements TestInteractionSignalRepository {
  const _FakeInteractionHistory({this.signals = const []});

  final List<TestInterestSignal> signals;

  @override
  Future<void> clearHistory() async {}

  @override
  Future<List<TestInterestSignal>> loadSignals({int limit = 40}) async {
    return signals.take(limit).toList(growable: false);
  }
}
