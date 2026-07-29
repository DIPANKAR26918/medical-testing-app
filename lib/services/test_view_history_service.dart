import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medical_test.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

enum TestInteractionType {
  detailView,
  searchOpen,
  categoryOpen,
  recommendationOpen,
  bookingStart,
  bookingConfirmation,
}

abstract interface class TestInteractionSignalRepository {
  Future<List<TestInterestSignal>> loadSignals({int limit = 40});

  Future<void> clearHistory();
}

class TestInterestSignal {
  const TestInterestSignal({
    required this.testId,
    required this.detailViews,
    required this.searchOpens,
    required this.categoryOpens,
    required this.recommendationOpens,
    required this.bookingStarts,
    required this.bookingConfirmations,
    required this.lastInteractedAt,
  });

  final String testId;
  final int detailViews;
  final int searchOpens;
  final int categoryOpens;
  final int recommendationOpens;
  final int bookingStarts;
  final int bookingConfirmations;
  final DateTime lastInteractedAt;

  int get totalInteractions =>
      detailViews +
      searchOpens +
      categoryOpens +
      recommendationOpens +
      bookingStarts +
      bookingConfirmations;

  double get weightedStrength =>
      detailViews * 2.5 +
      searchOpens * 4 +
      categoryOpens * 2 +
      recommendationOpens * 1.25 +
      bookingStarts * 7 +
      bookingConfirmations * 10;

  double scoreAt(DateTime now) {
    final elapsed = now.toUtc().difference(lastInteractedAt);
    final ageDays =
        math.max(0, elapsed.inMinutes) /
        (Duration.minutesPerHour * Duration.hoursPerDay);
    return math.log(1 + weightedStrength) * math.exp(-ageDays / 30);
  }

  TestInterestSignal increment(
    TestInteractionType type,
    DateTime interactedAt,
  ) {
    int bump(int value) => math.min(value + 1, 99);

    return TestInterestSignal(
      testId: testId,
      detailViews: type == TestInteractionType.detailView
          ? bump(detailViews)
          : detailViews,
      searchOpens: type == TestInteractionType.searchOpen
          ? bump(searchOpens)
          : searchOpens,
      categoryOpens: type == TestInteractionType.categoryOpen
          ? bump(categoryOpens)
          : categoryOpens,
      recommendationOpens: type == TestInteractionType.recommendationOpen
          ? bump(recommendationOpens)
          : recommendationOpens,
      bookingStarts: type == TestInteractionType.bookingStart
          ? bump(bookingStarts)
          : bookingStarts,
      bookingConfirmations: type == TestInteractionType.bookingConfirmation
          ? bump(bookingConfirmations)
          : bookingConfirmations,
      lastInteractedAt: interactedAt.toUtc(),
    );
  }

  Map<String, dynamic> toRpcJson() {
    return {
      'test_id': testId,
      'detail_views': detailViews,
      'search_opens': searchOpens,
      'category_opens': categoryOpens,
      'recommendation_opens': recommendationOpens,
      'booking_starts': bookingStarts,
      'booking_confirmations': bookingConfirmations,
      'last_interacted_at': lastInteractedAt.toUtc().toIso8601String(),
    };
  }

  String toStorageValue() => jsonEncode(toRpcJson());

  static TestInterestSignal? fromStorageValue(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;

      final json = Map<String, dynamic>.from(decoded);
      final testId = json['test_id']?.toString().trim() ?? '';
      final lastInteractedAt = DateTime.tryParse(
        json['last_interacted_at']?.toString() ??
            json['last_viewed_at']?.toString() ??
            '',
      );

      if (testId.isEmpty || lastInteractedAt == null) return null;

      final detailViews = _nonNegativeCount(
        json['detail_views'] ?? json['view_count'],
      );
      final signal = TestInterestSignal(
        testId: testId,
        detailViews: detailViews,
        searchOpens: _nonNegativeCount(json['search_opens']),
        categoryOpens: _nonNegativeCount(json['category_opens']),
        recommendationOpens: _nonNegativeCount(
          json['recommendation_opens'],
        ),
        bookingStarts: _nonNegativeCount(json['booking_starts']),
        bookingConfirmations: _nonNegativeCount(
          json['booking_confirmations'],
        ),
        lastInteractedAt: lastInteractedAt.toUtc(),
      );

      return signal.totalInteractions == 0 ? null : signal;
    } catch (_) {
      return null;
    }
  }

  static int _nonNegativeCount(dynamic value) {
    final count = switch (value) {
      final int number => number,
      final num number => number.toInt(),
      final value => int.tryParse(value?.toString() ?? '') ?? 0,
    };
    return count.clamp(0, 99).toInt();
  }
}

/// Keeps a compact interest profile on the device.
///
/// Only catalogue IDs, bounded event counts and the last interaction time are
/// stored. Test names, categories, symptoms and search phrases are excluded.
/// Supabase receives this compact payload only while ranking and does not
/// persist it.
class TestViewHistoryService implements TestInteractionSignalRepository {
  TestViewHistoryService({
    SharedPreferencesLoader? preferencesLoader,
    String? Function()? userIdProvider,
    DateTime Function()? now,
  }) : _preferencesLoader =
           preferencesLoader ?? SharedPreferences.getInstance,
       _userIdProvider = userIdProvider ?? _currentSupabaseUserId,
       _now = now ?? DateTime.now;

  static final TestViewHistoryService shared = TestViewHistoryService();

  static const _storagePrefix = 'medical_test_interest_history_v2';
  static const _legacyStoragePrefix = 'medical_test_view_history_v1';
  static const _maxStoredTests = 40;
  static const _retention = Duration(days: 90);

  final SharedPreferencesLoader _preferencesLoader;
  final String? Function() _userIdProvider;
  final DateTime Function() _now;
  Future<void> _writeQueue = Future<void>.value();

  static String storageKeyForUser(String? userId) {
    return _keyFor(_storagePrefix, userId);
  }

  static String legacyStorageKeyForUser(String? userId) {
    return _keyFor(_legacyStoragePrefix, userId);
  }

  @override
  Future<List<TestInterestSignal>> loadSignals({int limit = 40}) async {
    if (limit <= 0) return const [];

    await _writeQueue;
    final preferences = await _preferencesLoader();
    final now = _now().toUtc();
    final signals = _readSignals(preferences)
      ..sort((first, second) {
        final scoreComparison = second
            .scoreAt(now)
            .compareTo(first.scoreAt(now));
        if (scoreComparison != 0) return scoreComparison;
        return second.lastInteractedAt.compareTo(first.lastInteractedAt);
      });

    return List<TestInterestSignal>.unmodifiable(signals.take(limit));
  }

  Future<void> recordView(MedicalTest test) {
    return recordInteraction(test, TestInteractionType.detailView);
  }

  Future<void> recordInteraction(
    MedicalTest test,
    TestInteractionType type,
  ) {
    return recordInteractions([test], type);
  }

  Future<void> recordInteractions(
    Iterable<MedicalTest> tests,
    TestInteractionType type,
  ) {
    final normalizedTests = <String>{};
    for (final test in tests) {
      final id = test.id.trim();
      if (id.isNotEmpty) normalizedTests.add(id);
    }
    if (normalizedTests.isEmpty) return Future<void>.value();

    return _enqueueWrite(() async {
      final preferences = await _preferencesLoader();
      final signals = _readSignals(preferences);
      final signalsById = {for (final signal in signals) signal.testId: signal};
      final now = _now().toUtc();

      for (final testId in normalizedTests) {
        final existing = signalsById[testId] ?? _emptySignal(testId, now);
        signalsById[testId] = existing.increment(type, now);
      }

      final updated = signalsById.values.toList()
        ..sort(
          (first, second) =>
              second.scoreAt(now).compareTo(first.scoreAt(now)),
        );
      await _persistSignals(preferences, updated.take(_maxStoredTests));
    });
  }

  @override
  Future<void> clearHistory() {
    return _enqueueWrite(() async {
      final preferences = await _preferencesLoader();
      await Future.wait([
        preferences.remove(_storageKey),
        preferences.remove(_legacyStorageKey),
      ]);
    });
  }

  Future<void> _enqueueWrite(Future<void> Function() operation) {
    final queued = _writeQueue.then((_) => operation());
    _writeQueue = queued.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return queued;
  }

  Future<void> _persistSignals(
    SharedPreferences preferences,
    Iterable<TestInterestSignal> signals,
  ) async {
    await preferences.setStringList(
      _storageKey,
      signals.map((signal) => signal.toStorageValue()).toList(growable: false),
    );
    await preferences.remove(_legacyStorageKey);
  }

  List<TestInterestSignal> _readSignals(SharedPreferences preferences) {
    final stored = preferences.getStringList(_storageKey);
    final values = stored == null || stored.isEmpty
        ? preferences.getStringList(_legacyStorageKey) ?? const <String>[]
        : stored;
    final cutoff = _now().toUtc().subtract(_retention);

    return values
        .map(TestInterestSignal.fromStorageValue)
        .whereType<TestInterestSignal>()
        .where((signal) => !signal.lastInteractedAt.isBefore(cutoff))
        .toList();
  }

  TestInterestSignal _emptySignal(String testId, DateTime now) {
    return TestInterestSignal(
      testId: testId,
      detailViews: 0,
      searchOpens: 0,
      categoryOpens: 0,
      recommendationOpens: 0,
      bookingStarts: 0,
      bookingConfirmations: 0,
      lastInteractedAt: now,
    );
  }

  String get _storageKey => storageKeyForUser(_safeUserId());
  String get _legacyStorageKey => legacyStorageKeyForUser(_safeUserId());

  String? _safeUserId() {
    try {
      return _userIdProvider();
    } catch (_) {
      return null;
    }
  }

  static String _keyFor(String prefix, String? userId) {
    final normalized = userId?.trim();
    return normalized == null || normalized.isEmpty
        ? '${prefix}_local'
        : '${prefix}_$normalized';
  }

  static String? _currentSupabaseUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }
}
