import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medical_test.dart';

class MedicalTestCatalogService {
  MedicalTestCatalogService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

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
    final response = await _client.rpc(
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

  Future<List<MedicalTestCategorySummary>> fetchCategories() async {
    final response = await _client.rpc('get_medical_test_categories');
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
    final response = await _client
        .from('medical_tests')
        .select(_testColumns)
        .eq('is_active', true)
        .eq('category', category)
        .order('is_popular', ascending: false)
        .order('display_order')
        .order('name_sheet');

    return response
        .whereType<Map>()
        .map(
          (item) => MedicalTest.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _jsonObject(dynamic response) {
    if (response is Map) return Map<String, dynamic>.from(response);

    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }

    throw const FormatException('The medical-test feed response was invalid.');
  }
}
