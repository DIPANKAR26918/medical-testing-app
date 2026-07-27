import 'dart:convert';

import 'medical_test.dart';

const legacyMedicalTestRecentSearchesStorageKey =
    'medical_test_recent_searches_v2';
const medicalTestRecentSearchesStorageKey =
    'medical_test_recent_searches_v3';

class RecentTestSearch {
  const RecentTestSearch({
    required this.testId,
    required this.name,
    required this.category,
  });

  final String testId;
  final String name;
  final String category;

  factory RecentTestSearch.fromTest(MedicalTest test) {
    return RecentTestSearch(
      testId: test.id,
      name: test.displayName,
      category: test.category,
    );
  }

  String toStorageValue() {
    return jsonEncode({
      'test_id': testId,
      'name': name,
      'category': category,
    });
  }

  static RecentTestSearch? tryParse(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;

      final json = Map<String, dynamic>.from(decoded);
      final testId = json['test_id']?.toString().trim() ?? '';
      final name = json['name']?.toString().trim() ?? '';
      final category = json['category']?.toString().trim() ?? '';
      if (testId.isEmpty || name.isEmpty || category.isEmpty) return null;

      return RecentTestSearch(
        testId: testId,
        name: name,
        category: category,
      );
    } on FormatException {
      return null;
    }
  }
}

List<RecentTestSearch> decodeRecentTestSearches(Iterable<String> values) {
  return values
      .map(RecentTestSearch.tryParse)
      .whereType<RecentTestSearch>()
      .take(6)
      .toList(growable: false);
}

List<RecentTestSearch> recordRecentTestSelection(
  Iterable<RecentTestSearch> current,
  MedicalTest selected,
) {
  final next = RecentTestSearch.fromTest(selected);
  return <RecentTestSearch>[
    next,
    ...current.where((item) => item.testId != next.testId),
  ].take(6).toList(growable: false);
}
