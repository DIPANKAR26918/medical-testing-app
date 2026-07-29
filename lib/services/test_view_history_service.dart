import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medical_test.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

abstract interface class TestViewSignalRepository {
  Future<List<TestViewSignal>> loadSignals({int limit = 4});

  Future<void> clearHistory();
}

class TestViewSignal {
  const TestViewSignal({
    required this.testId,
    required this.viewCount,
    required this.lastViewedAt,
  });

  final String testId;
  final int viewCount;
  final DateTime lastViewedAt;

  String toStorageValue() {
    return jsonEncode({
      'test_id': testId,
      'view_count': viewCount,
      'last_viewed_at': lastViewedAt.toUtc().toIso8601String(),
    });
  }

  static TestViewSignal? fromStorageValue(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;

      final json = Map<String, dynamic>.from(decoded);
      final testId = json['test_id']?.toString().trim() ?? '';
      final viewCount = switch (json['view_count']) {
        final int value => value,
        final num value => value.toInt(),
        final value => int.tryParse(value?.toString() ?? ''),
      };
      final lastViewedAt = DateTime.tryParse(
        json['last_viewed_at']?.toString() ?? '',
      );

      if (testId.isEmpty ||
          viewCount == null ||
          viewCount < 1 ||
          lastViewedAt == null) {
        return null;
      }

      return TestViewSignal(
        testId: testId,
        viewCount: viewCount,
        lastViewedAt: lastViewedAt.toUtc(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Stores only the minimum signal needed for on-device recommendations:
/// catalogue id, count and last-viewed time. Test names, search phrases and
/// symptoms are deliberately not persisted.
class TestViewHistoryService implements TestViewSignalRepository {
  TestViewHistoryService({
    SharedPreferencesLoader? preferencesLoader,
    String? Function()? userIdProvider,
    DateTime Function()? now,
  }) : _preferencesLoader =
           preferencesLoader ?? SharedPreferences.getInstance,
       _userIdProvider = userIdProvider ?? _currentSupabaseUserId,
       _now = now ?? DateTime.now;

  static final TestViewHistoryService shared = TestViewHistoryService();

  static const _storagePrefix = 'medical_test_view_history_v1';
  static const _maxStoredTests = 24;
  static const _retention = Duration(days: 90);

  final SharedPreferencesLoader _preferencesLoader;
  final String? Function() _userIdProvider;
  final DateTime Function() _now;

  static String storageKeyForUser(String? userId) {
    final normalized = userId?.trim();
    return normalized == null || normalized.isEmpty
        ? '${_storagePrefix}_local'
        : '${_storagePrefix}_$normalized';
  }

  @override
  Future<List<TestViewSignal>> loadSignals({int limit = 4}) async {
    if (limit <= 0) return const [];

    final preferences = await _preferencesLoader();
    final signals = _readSignals(preferences)..sort(_compareSignals);

    return List<TestViewSignal>.unmodifiable(signals.take(limit));
  }

  Future<void> recordView(MedicalTest test) async {
    final testId = test.id.trim();
    if (testId.isEmpty) return;

    final preferences = await _preferencesLoader();
    final signals = _readSignals(preferences);
    final existingIndex = signals.indexWhere(
      (signal) => signal.testId == testId,
    );
    final now = _now().toUtc();

    if (existingIndex == -1) {
      signals.add(
        TestViewSignal(
          testId: testId,
          viewCount: 1,
          lastViewedAt: now,
        ),
      );
    } else {
      final existing = signals[existingIndex];
      signals[existingIndex] = TestViewSignal(
        testId: testId,
        viewCount: existing.viewCount + 1,
        lastViewedAt: now,
      );
    }

    signals.sort(_compareSignals);
    await preferences.setStringList(
      _storageKey,
      signals
          .take(_maxStoredTests)
          .map((signal) => signal.toStorageValue())
          .toList(growable: false),
    );
  }

  @override
  Future<void> clearHistory() async {
    final preferences = await _preferencesLoader();
    await preferences.remove(_storageKey);
  }

  String get _storageKey => storageKeyForUser(_safeUserId());

  List<TestViewSignal> _readSignals(SharedPreferences preferences) {
    final cutoff = _now().toUtc().subtract(_retention);
    return (preferences.getStringList(_storageKey) ?? const <String>[])
        .map(TestViewSignal.fromStorageValue)
        .whereType<TestViewSignal>()
        .where((signal) => !signal.lastViewedAt.isBefore(cutoff))
        .toList();
  }

  String? _safeUserId() {
    try {
      return _userIdProvider();
    } catch (_) {
      return null;
    }
  }

  static int _compareSignals(TestViewSignal first, TestViewSignal second) {
    final countComparison = second.viewCount.compareTo(first.viewCount);
    if (countComparison != 0) return countComparison;
    return second.lastViewedAt.compareTo(first.lastViewedAt);
  }

  static String? _currentSupabaseUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }
}
