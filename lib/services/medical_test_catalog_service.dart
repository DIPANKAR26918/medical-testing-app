import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medical_test.dart';
import '../utils/medical_test_search.dart';

abstract interface class MedicalTestSearchRepository {
  Future<List<MedicalTestCategorySummary>> fetchCategories();

  Future<List<MedicalTestSearchResult>> searchTests(
    String query, {
    String? category,
    int limit = 30,
  });
}

abstract interface class MedicalTestRecommendationRepository {
  Future<List<MedicalTest>> fetchTestsByIds(Iterable<String> testIds);

  Future<List<MedicalTest>> fetchTestsByCodes(Iterable<String> testCodes);
}

class MedicalTestCatalogService
    implements
        MedicalTestSearchRepository,
        MedicalTestRecommendationRepository {
  MedicalTestCatalogService({SupabaseClient? client})
    : _client = client;

  SupabaseClient? _client;

  SupabaseClient get _resolvedClient =>
      _client ??= Supabase.instance.client;

  static const String _testColumns =
      'id,test_code,name_sheet,common_name,mrp,reporting_time,'
      'sample_type_volume,category,body_system,test_type,purpose,preparation,'
      'age_recommendation,home_collection_available,lab_visit_required,'
      'special_handling_required,is_popular,min_age,max_age,gender,'
      'parameter_count,included_parameters,sample_source,sample_source_label,'
      'sample_collection_note';

  Future<HomeMedicalTestFeed> fetchHomeFeed({
    int categoryLimit = 8,
    int testsPerCategory = 4,
  }) async {
    final response = await _resolvedClient.rpc(
      'get_home_medical_test_feed',
      params: {
        'p_category_limit': categoryLimit,
        'p_tests_per_category': testsPerCategory,
      },
    );

    final payload = _jsonObject(response);
    final feed = HomeMedicalTestFeed.fromJson(payload);
    if (feed.categories.isEmpty) {
      throw const FormatException('No medical tests are available right now.');
    }
    return feed;
  }

  @override
  Future<List<MedicalTestCategorySummary>> fetchCategories() async {
    final response = await _resolvedClient.rpc('get_medical_test_categories');
    if (response is! Iterable) return const [];

    return response
        .whereType<Map>()
        .map(
          (item) => MedicalTestCategorySummary.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((category) => category.testCount > 0)
        .toList(growable: false);
  }

  Future<List<MedicalTest>> fetchTestsByCategory(String category) async {
    final response = await _resolvedClient
        .from('medical_tests')
        .select(_testColumns)
        .eq('is_active', true)
        .eq('category', category)
        .order('is_popular', ascending: false)
        .order('display_order')
        .order('name_sheet');

    return response
        .whereType<Map>()
        .map((item) => MedicalTest.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<MedicalTest?> fetchTestById(String testId) async {
    final normalizedId = testId.trim();
    if (normalizedId.isEmpty) return null;

    final response = await _resolvedClient
        .from('medical_tests')
        .select(_testColumns)
        .eq('id', normalizedId)
        .eq('is_active', true)
        .maybeSingle();

    return response == null ? null : MedicalTest.fromJson(response);
  }

  @override
  Future<List<MedicalTest>> fetchTestsByIds(
    Iterable<String> testIds,
  ) async {
    final ids = _normalizedValues(testIds);
    if (ids.isEmpty) return const [];

    final response = await _resolvedClient
        .from('medical_tests')
        .select(_testColumns)
        .eq('is_active', true)
        .inFilter('id', ids);

    final tests = response
        .whereType<Map>()
        .map((item) => MedicalTest.fromJson(Map<String, dynamic>.from(item)));
    final testsById = {for (final test in tests) test.id: test};

    return ids.map((id) => testsById[id]).whereType<MedicalTest>().toList(
      growable: false,
    );
  }

  @override
  Future<List<MedicalTest>> fetchTestsByCodes(
    Iterable<String> testCodes,
  ) async {
    final codes = _normalizedValues(testCodes);
    if (codes.isEmpty) return const [];

    final response = await _resolvedClient
        .from('medical_tests')
        .select(_testColumns)
        .eq('is_active', true)
        .inFilter('test_code', codes);

    final tests = response
        .whereType<Map>()
        .map((item) => MedicalTest.fromJson(Map<String, dynamic>.from(item)));
    final testsByCode = {
      for (final test in tests)
        if (test.testCode != null) test.testCode!: test,
    };

    return codes
        .map((code) => testsByCode[code])
        .whereType<MedicalTest>()
        .toList(growable: false);
  }

  @override
  Future<List<MedicalTestSearchResult>> searchTests(
    String query, {
    String? category,
    int limit = 30,
  }) async {
    final response = await _resolvedClient.rpc(
      'search_medical_tests_ranked',
      params: {
        'p_query': query.trim(),
        'p_limit': limit.clamp(1, 60),
        'p_category': category,
      },
    );

    if (response is! Iterable) return const [];

    final results = response
        .whereType<Map>()
        .map(
          (item) =>
              MedicalTestSearchResult.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    return enforceSingleLetterPrefixResults(query, results);
  }

  Map<String, dynamic> _jsonObject(dynamic response) {
    if (response is Map) return Map<String, dynamic>.from(response);

    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }

    throw const FormatException('The medical-test feed response was invalid.');
  }

  List<String> _normalizedValues(Iterable<String> values) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final value in values) {
      final text = value.trim();
      if (text.isNotEmpty && seen.add(text)) normalized.add(text);
    }

    return normalized;
  }
}
