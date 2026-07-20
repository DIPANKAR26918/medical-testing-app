import 'package:intl/intl.dart';

/// The single time contract used by Testified.
///
/// Supabase/Postgres timestamps stay in UTC. User-facing dates are rendered
/// in Asia/Kolkata (IST, UTC+05:30), regardless of the device timezone.
/// Kolkata does not observe daylight-saving time, so its UTC offset is fixed.
abstract class AppTime {
  static const String timeZoneName = 'Asia/Kolkata';
  static const String timeZoneAbbreviation = 'IST';
  static const Duration kolkataOffset = Duration(hours: 5, minutes: 30);

  static DateTime nowUtc() => DateTime.now().toUtc();

  static String nowUtcIsoString() => nowUtc().toIso8601String();

  static String utcIsoString(DateTime value) => _asUtc(value).toIso8601String();

  /// Parses timestamps returned by Supabase or stored in legacy timeline JSON.
  ///
  /// Some older timeline entries were saved without a `Z` or numeric offset.
  /// Those values were generated as UTC, so they must not be interpreted as
  /// the phone's local time.
  static DateTime? parseUtc(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return _asUtc(value);

    if (value is int) {
      final isSeconds = value.abs() < 100000000000;
      return DateTime.fromMillisecondsSinceEpoch(
        isSeconds ? value * 1000 : value,
        isUtc: true,
      );
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final normalized = _hasExplicitTimeZone(raw) ? raw : '${raw}Z';
    return DateTime.tryParse(normalized)?.toUtc();
  }

  /// Returns the Asia/Kolkata wall-clock representation for display only.
  ///
  /// The returned value retains a UTC flag because Dart has no native IANA
  /// timezone value. Persist the original UTC instant, never this shifted
  /// display value.
  static DateTime toKolkataClock(DateTime value) {
    return _asUtc(value).add(kolkataOffset);
  }

  static int currentKolkataHour() => toKolkataClock(nowUtc()).hour;

  static String formatKolkata(
    DateTime value, {
    required String pattern,
    bool includeTimeZone = false,
  }) {
    final formatted = DateFormat(pattern).format(toKolkataClock(value));
    return includeTimeZone ? '$formatted $timeZoneAbbreviation' : formatted;
  }

  static String formatKolkataCompact(DateTime value) {
    return formatKolkata(value, pattern: 'd MMM, h:mm a');
  }

  static String formatKolkataFull(DateTime value) {
    return formatKolkata(
      value,
      pattern: 'd MMM yyyy, h:mm a',
      includeTimeZone: true,
    );
  }

  static DateTime _asUtc(DateTime value) {
    return value.isUtc ? value : value.toUtc();
  }

  static bool _hasExplicitTimeZone(String value) {
    final timeSeparator = value.lastIndexOf('T') > value.lastIndexOf(' ')
        ? value.lastIndexOf('T')
        : value.lastIndexOf(' ');
    if (timeSeparator < 0) return false;

    final timePart = value.substring(timeSeparator + 1);
    if (timePart.endsWith('Z') || timePart.endsWith('z')) return true;

    return RegExp(r'[+-]\d{2}(?::?\d{2})?$').hasMatch(timePart);
  }
}
