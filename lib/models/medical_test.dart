class MedicalTest {
  const MedicalTest({
    required this.id,
    required this.nameSheet,
    required this.category,
    required this.testType,
    required this.homeCollectionAvailable,
    required this.labVisitRequired,
    required this.specialHandlingRequired,
    required this.isPopular,
    required this.includedParameters,
    required this.gender,
    this.testCode,
    this.commonName,
    this.mrp,
    this.reportingTime,
    this.sampleTypeVolume,
    this.bodySystem,
    this.purpose,
    this.preparation,
    this.ageRecommendation,
    this.minAge,
    this.maxAge,
    this.parameterCount,
    this.sampleSource,
    this.sampleSourceLabel,
    this.sampleCollectionNote,
  });

  final String id;
  final String? testCode;
  final String nameSheet;
  final String? commonName;
  final double? mrp;
  final String? reportingTime;
  final String? sampleTypeVolume;
  final String category;
  final String? bodySystem;
  final String testType;
  final String? purpose;
  final String? preparation;
  final String? ageRecommendation;
  final bool homeCollectionAvailable;
  final bool labVisitRequired;
  final bool specialHandlingRequired;
  final bool isPopular;
  final int? minAge;
  final int? maxAge;
  final String gender;
  final int? parameterCount;
  final List<String> includedParameters;
  final String? sampleSource;
  final String? sampleSourceLabel;
  final String? sampleCollectionNote;

  factory MedicalTest.fromJson(Map<String, dynamic> json) {
    return MedicalTest(
      id: _text(json['id']) ?? '',
      testCode: _text(json['test_code']),
      nameSheet: _text(json['name_sheet']) ?? 'Medical test',
      commonName: _text(json['common_name']),
      mrp: _double(json['mrp']),
      reportingTime: _text(json['reporting_time']),
      sampleTypeVolume: _text(json['sample_type_volume']),
      category: _text(json['category']) ?? 'Specialised Tests',
      bodySystem: _text(json['body_system']),
      testType: _text(json['test_type']) ?? 'individual',
      purpose: _text(json['purpose']),
      preparation: _text(json['preparation']),
      ageRecommendation: _text(json['age_recommendation']),
      homeCollectionAvailable: _boolean(
        json['home_collection_available'],
        fallback: true,
      ),
      labVisitRequired: _boolean(json['lab_visit_required']),
      specialHandlingRequired: _boolean(
        json['special_handling_required'],
      ),
      isPopular: _boolean(json['is_popular']),
      minAge: _integer(json['min_age']),
      maxAge: _integer(json['max_age']),
      gender: _text(json['gender']) ?? 'any',
      parameterCount: _integer(json['parameter_count']),
      includedParameters: _stringList(json['included_parameters']),
      sampleSource: _text(json['sample_source']),
      sampleSourceLabel: _text(json['sample_source_label']),
      sampleCollectionNote: _text(json['sample_collection_note']),
    );
  }

  String get displayName {
    final familiarName = commonName?.trim();
    return familiarName == null || familiarName.isEmpty
        ? nameSheet
        : familiarName;
  }

  bool get hasDifferentOfficialName {
    final familiarName = commonName?.trim();
    return familiarName != null &&
        familiarName.isNotEmpty &&
        familiarName.toLowerCase() != nameSheet.trim().toLowerCase();
  }

  String get priceLabel {
    final price = mrp;
    if (price == null) return 'Price at booking';

    final amount = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '₹$amount';
  }

  String get reportLabel => reportingTime ?? 'Timing at booking';

  String get sampleLabel =>
      sampleSourceLabel ?? sampleTypeVolume ?? 'Sample details at booking';

  String get collectionLabel {
    if (labVisitRequired) return 'Lab visit required';
    if (homeCollectionAvailable) return 'Home collection';
    return 'Check availability';
  }

  String get testTypeLabel {
    switch (testType.toLowerCase()) {
      case 'panel':
        return 'Test panel';
      case 'procedure':
        return 'Procedure';
      default:
        return 'Individual test';
    }
  }

  String? get ageAndGenderLabel {
    final parts = <String>[];
    if (minAge != null && maxAge != null) {
      parts.add('Ages $minAge–$maxAge');
    } else if (minAge != null) {
      parts.add('Age $minAge+');
    } else if (maxAge != null) {
      parts.add('Up to age $maxAge');
    } else if (ageRecommendation != null) {
      parts.add(ageRecommendation!);
    }

    switch (gender.toLowerCase()) {
      case 'male':
        parts.add('For men');
        break;
      case 'female':
        parts.add('For women');
        break;
    }

    return parts.isEmpty ? null : parts.join(' • ');
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _integer(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _boolean(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return fallback;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const [];

    return List<String>.unmodifiable(
      value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty),
    );
  }
}

class HomeMedicalTestFeed {
  const HomeMedicalTestFeed({
    required this.feedId,
    required this.generatedAt,
    required this.categories,
  });

  final String feedId;
  final DateTime generatedAt;
  final List<HomeMedicalTestCategory> categories;

  factory HomeMedicalTestFeed.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final categories = rawCategories is Iterable
        ? rawCategories
              .whereType<Map>()
              .map(
                (item) => HomeMedicalTestCategory.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((category) => category.tests.isNotEmpty)
              .toList(growable: false)
        : const <HomeMedicalTestCategory>[];

    return HomeMedicalTestFeed(
      feedId: json['feed_id']?.toString() ?? '',
      generatedAt:
          DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
          DateTime.now(),
      categories: categories,
    );
  }
}

class HomeMedicalTestCategory {
  const HomeMedicalTestCategory({
    required this.name,
    required this.totalCount,
    required this.tests,
  });

  final String name;
  final int totalCount;
  final List<MedicalTest> tests;

  factory HomeMedicalTestCategory.fromJson(Map<String, dynamic> json) {
    final rawTests = json['tests'];
    final tests = rawTests is Iterable
        ? rawTests
              .whereType<Map>()
              .map(
                (item) => MedicalTest.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
        : const <MedicalTest>[];

    return HomeMedicalTestCategory(
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Specialised Tests',
      totalCount: MedicalTest._integer(json['total_count']) ?? tests.length,
      tests: tests,
    );
  }
}

class MedicalTestCategorySummary {
  const MedicalTestCategorySummary({
    required this.name,
    required this.testCount,
    required this.popularCount,
  });

  final String name;
  final int testCount;
  final int popularCount;

  factory MedicalTestCategorySummary.fromJson(Map<String, dynamic> json) {
    return MedicalTestCategorySummary(
      name: json['category']?.toString().trim().isNotEmpty == true
          ? json['category'].toString().trim()
          : 'Specialised Tests',
      testCount: MedicalTest._integer(json['test_count']) ?? 0,
      popularCount: MedicalTest._integer(json['popular_count']) ?? 0,
    );
  }
}
