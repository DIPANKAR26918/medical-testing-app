import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medical_parameter_guide.dart';

class MedicalParameterGuideService {
  MedicalParameterGuideService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static final MedicalParameterGuideService shared =
      MedicalParameterGuideService();

  final SupabaseClient _client;
  final Map<String, Future<MedicalParameterGuide?>> _cache = {};

  Future<MedicalParameterGuide?> fetchGuide(String parameter) {
    final key = _cacheKey(parameter);
    if (key.isEmpty) return Future<MedicalParameterGuide?>.value();

    return _cache.putIfAbsent(key, () => _fetchAndEvictOnError(parameter, key));
  }

  Future<MedicalParameterGuide?> _fetchAndEvictOnError(
    String parameter,
    String key,
  ) async {
    try {
      final response = await _client.rpc(
        'get_medical_parameter_guide',
        params: {'p_parameter': parameter.trim()},
      );

      if (response is Map) {
        return MedicalParameterGuide.fromJson(
          Map<String, dynamic>.from(response),
        );
      }

      if (response is Iterable) {
        final rows = response.whereType<Map>();
        if (rows.isEmpty) return null;
        return MedicalParameterGuide.fromJson(
          Map<String, dynamic>.from(rows.first),
        );
      }

      return null;
    } catch (_) {
      _cache.remove(key);
      rethrow;
    }
  }

  static String _cacheKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
