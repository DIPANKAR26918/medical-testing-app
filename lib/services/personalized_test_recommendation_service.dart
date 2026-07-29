import '../models/app_user.dart';
import '../models/medical_test.dart';
import 'medical_test_catalog_service.dart';
import 'test_view_history_service.dart';

enum PersonalizedRecommendationSource { activity, preventive }

class PersonalizedTestRecommendation {
  const PersonalizedTestRecommendation({
    required this.test,
    required this.source,
    required this.badgeLabel,
    required this.reason,
    this.guidanceSourceLabel,
    this.guidanceSourceUrl,
  });

  final MedicalTest test;
  final PersonalizedRecommendationSource source;
  final String badgeLabel;
  final String reason;
  final String? guidanceSourceLabel;
  final String? guidanceSourceUrl;
}

class PersonalizedTestRecommendations {
  const PersonalizedTestRecommendations({
    required this.fromActivity,
    required this.preventive,
    required this.profileNeedsDetails,
  });

  final List<PersonalizedTestRecommendation> fromActivity;
  final List<PersonalizedTestRecommendation> preventive;
  final bool profileNeedsDetails;

  bool get isEmpty => fromActivity.isEmpty && preventive.isEmpty;
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
    TestViewSignalRepository? viewHistory,
  }) : _catalogRepository =
           catalogRepository ?? MedicalTestCatalogService(),
       _viewHistory = viewHistory ?? TestViewHistoryService.shared;

  static const _ncdProgrammeUrl =
      'https://ncd.mohfw.gov.in/ncdlandingassets/aboutus.html';
  static const _anaemiaMuktBharatUrl =
      'https://nhm.gov.in/index1.php?lang=1&level=3&lid=797&sublinkid=1448';

  final MedicalTestRecommendationRepository _catalogRepository;
  final TestViewSignalRepository _viewHistory;

  Future<PersonalizedTestRecommendations> loadFor(AppUser? profile) async {
    final rules = preventiveRulesFor(profile);
    final activityFuture = _loadActivityRecommendations();
    final preventiveFuture = _loadPreventiveRecommendations(rules);
    final results = await Future.wait([
      activityFuture,
      preventiveFuture,
    ]);

    return PersonalizedTestRecommendations(
      fromActivity: results[0],
      preventive: results[1],
      profileNeedsDetails: !_hasUsableProfile(profile),
    );
  }

  Future<void> clearActivity() => _viewHistory.clearHistory();

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

  Future<List<PersonalizedTestRecommendation>>
  _loadActivityRecommendations() async {
    try {
      final signals = await _viewHistory.loadSignals(limit: 4);
      if (signals.isEmpty) return const [];

      final tests = await _catalogRepository.fetchTestsByIds(
        signals.map((signal) => signal.testId),
      );
      final signalsById = {
        for (final signal in signals) signal.testId: signal,
      };

      return tests.map((test) {
        final signal = signalsById[test.id]!;
        return PersonalizedTestRecommendation(
          test: test,
          source: PersonalizedRecommendationSource.activity,
          badgeLabel: _activityBadge(signal.viewCount),
          reason: signal.viewCount == 1
              ? 'Continue from a test you recently viewed.'
              : 'Easy access to a test you keep checking.',
        );
      }).toList(growable: false);
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

  static String _activityBadge(int viewCount) {
    if (viewCount <= 1) return 'Recently viewed';
    if (viewCount == 2) return 'Viewed twice';
    return 'Viewed $viewCount times';
  }
}
