import '../models/app_user.dart';
import '../models/medical_test.dart';
import 'medical_test_catalog_service.dart';
import 'test_view_history_service.dart';

enum PersonalizedRecommendationSource { discovery, preventive }

class PersonalizedTestRecommendation {
  const PersonalizedTestRecommendation({
    required this.test,
    required this.source,
    required this.badgeLabel,
    required this.reason,
    this.strategy = 'preventive',
    this.modelVersion,
    this.guidanceSourceLabel,
    this.guidanceSourceUrl,
  });

  final MedicalTest test;
  final PersonalizedRecommendationSource source;
  final String badgeLabel;
  final String reason;
  final String strategy;
  final String? modelVersion;
  final String? guidanceSourceLabel;
  final String? guidanceSourceUrl;
}

class PersonalizedTestRecommendations {
  const PersonalizedTestRecommendations({
    required this.forYou,
    required this.preventive,
    required this.profileNeedsDetails,
    required this.hasBehavioralSignals,
  });

  final List<PersonalizedTestRecommendation> forYou;
  final List<PersonalizedTestRecommendation> preventive;
  final bool profileNeedsDetails;
  final bool hasBehavioralSignals;

  bool get isEmpty => forYou.isEmpty && preventive.isEmpty;
}

class PreventiveTestRule {
  const PreventiveTestRule({
    required this.testCode,
    required this.badgeLabel,
    required this.reason,
    required this.sourceLabel,
    required this.sourceUrl,
  });

  final String testCode;
  final String badgeLabel;
  final String reason;
  final String sourceLabel;
  final String sourceUrl;
}

class PersonalizedTestRecommendationService {
  PersonalizedTestRecommendationService({
    MedicalTestRecommendationRepository? catalogRepository,
    TestInteractionSignalRepository? interactionHistory,
  }) : _catalogRepository =
           catalogRepository ?? MedicalTestCatalogService(),
       _interactionHistory =
           interactionHistory ?? TestViewHistoryService.shared;

  static const _ncdProgrammeUrl =
      'https://ncd.mohfw.gov.in/ncdlandingassets/aboutus.html';
  static const _anaemiaMuktBharatUrl =
      'https://nhm.gov.in/index1.php?lang=1&level=3&lid=797&sublinkid=1448';

  final MedicalTestRecommendationRepository _catalogRepository;
  final TestInteractionSignalRepository _interactionHistory;

  Future<PersonalizedTestRecommendations> loadFor(AppUser? profile) async {
    final rules = preventiveRulesFor(profile);
    final signals = await _safeLoadSignals();
    final results = await Future.wait([
      _loadForYou(profile, signals),
      _loadPreventiveRecommendations(rules),
    ]);

    final preventive = results[1];
    final preventiveIds = preventive
        .map((recommendation) => recommendation.test.id)
        .toSet();
    final forYou = results[0]
        .where(
          (recommendation) =>
              !preventiveIds.contains(recommendation.test.id),
        )
        .toList(growable: false);

    return PersonalizedTestRecommendations(
      forYou: forYou,
      preventive: preventive,
      profileNeedsDetails: !_hasUsableProfile(profile),
      hasBehavioralSignals: signals.isNotEmpty,
    );
  }

  Future<void> clearActivity() => _interactionHistory.clearHistory();

  List<PreventiveTestRule> preventiveRulesFor(AppUser? profile) {
    final age = profile?.age;
    final gender = _normalizedGender(profile?.gender);
    if (age == null || age < 18 || age > 120) return const [];

    final rules = <PreventiveTestRule>[];

    if (age >= 30) {
      rules.add(
        const PreventiveTestRule(
          testCode: 'G0060 - G0065',
          badgeLabel: 'Age 30+ screening',
          reason:
              'India’s NCD programme starts diabetes screening at age 30. '
              'A blood sugar test is one screening option.',
          sourceLabel: 'MoHFW National NCD Programme',
          sourceUrl: _ncdProgrammeUrl,
        ),
      );
    }

    if (gender == 'female' && age >= 20 && age <= 49) {
      rules.add(
        const PreventiveTestRule(
          testCode: 'H0002',
          badgeLabel: 'Women 20–49',
          reason:
              'Anaemia Mukt Bharat includes women aged 20–49. '
              'A haemoglobin check can support anaemia screening.',
          sourceLabel: 'NHM Anaemia Mukt Bharat',
          sourceUrl: _anaemiaMuktBharatUrl,
        ),
      );
    }

    return List<PreventiveTestRule>.unmodifiable(rules);
  }

  Future<List<TestInterestSignal>> _safeLoadSignals() async {
    try {
      return await _interactionHistory.loadSignals(limit: 40);
    } catch (_) {
      return const [];
    }
  }

  Future<List<PersonalizedTestRecommendation>> _loadForYou(
    AppUser? profile,
    List<TestInterestSignal> signals,
  ) async {
    try {
      final candidates = await _catalogRepository
          .fetchPersonalizedCandidates(
            interactionSignals: signals.map((signal) => signal.toRpcJson()),
            age: profile?.age,
            gender: _normalizedGender(profile?.gender),
            limit: 10,
          );

      return candidates
          .map(
            (candidate) => PersonalizedTestRecommendation(
              test: candidate.test,
              source: PersonalizedRecommendationSource.discovery,
              badgeLabel: candidate.badgeLabel,
              reason: candidate.reason,
              strategy: candidate.strategy,
              modelVersion: candidate.modelVersion,
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return _loadRecentFallback(signals);
    }
  }

  Future<List<PersonalizedTestRecommendation>> _loadRecentFallback(
    List<TestInterestSignal> signals,
  ) async {
    if (signals.isEmpty) return const [];

    try {
      final recentSignals = signals.take(4).toList(growable: false);
      final tests = await _catalogRepository.fetchTestsByIds(
        recentSignals.map((signal) => signal.testId),
      );
      return tests
          .map(
            (test) => PersonalizedTestRecommendation(
              test: test,
              source: PersonalizedRecommendationSource.discovery,
              badgeLabel: 'Continue',
              reason: 'Continue exploring a test you recently opened.',
              strategy: 'continue',
              modelVersion: 'local-fallback-v1',
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<PersonalizedTestRecommendation>>
  _loadPreventiveRecommendations(List<PreventiveTestRule> rules) async {
    if (rules.isEmpty) return const [];

    try {
      final tests = await _catalogRepository.fetchTestsByCodes(
        rules.map((rule) => rule.testCode),
      );
      final rulesByCode = {for (final rule in rules) rule.testCode: rule};

      return tests.map((test) {
        final rule = rulesByCode[test.testCode]!;
        return PersonalizedTestRecommendation(
          test: test,
          source: PersonalizedRecommendationSource.preventive,
          badgeLabel: rule.badgeLabel,
          reason: rule.reason,
          strategy: 'preventive',
          guidanceSourceLabel: rule.sourceLabel,
          guidanceSourceUrl: rule.sourceUrl,
        );
      }).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  bool _hasUsableProfile(AppUser? profile) {
    final age = profile?.age;
    return age != null &&
        age >= 18 &&
        age <= 120 &&
        _normalizedGender(profile?.gender) != null;
  }

  String? _normalizedGender(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'female':
      case 'woman':
      case 'women':
      case 'f':
        return 'female';
      case 'male':
      case 'man':
      case 'men':
      case 'm':
        return 'male';
      default:
        return null;
    }
  }
}
