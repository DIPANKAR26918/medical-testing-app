import '../utils/app_time.dart';

class CollectionSlot {
  const CollectionSlot({
    required this.startUtc,
    required this.endUtc,
    this.timeZone = AppTime.timeZoneName,
  });

  final DateTime startUtc;
  final DateTime endUtc;
  final String timeZone;

  factory CollectionSlot.forKolkataDate(
    DateTime date, {
    required int startHour,
  }) {
    final start = AppTime.fromKolkataWallClock(date, hour: startHour);
    return CollectionSlot(
      startUtc: start,
      endUtc: start.add(const Duration(hours: 2)),
    );
  }

  static CollectionSlot? fromOrderJson(Map<String, dynamic> json) {
    final start = AppTime.parseUtc(json['collection_slot_start_at']);
    final end = AppTime.parseUtc(json['collection_slot_end_at']);
    if (start == null || end == null || !end.isAfter(start)) return null;

    final rawTimeZone = json['collection_slot_timezone']?.toString().trim();
    return CollectionSlot(
      startUtc: start,
      endUtc: end,
      timeZone: rawTimeZone == null || rawTimeZone.isEmpty
          ? AppTime.timeZoneName
          : rawTimeZone,
    );
  }

  String get dateLabel =>
      AppTime.formatKolkata(startUtc, pattern: 'EEE, d MMM');

  String get timeLabel {
    final start = AppTime.formatKolkata(startUtc, pattern: 'h:mm a');
    final end = AppTime.formatKolkata(endUtc, pattern: 'h:mm a');
    return '$start – $end ${AppTime.timeZoneAbbreviation}';
  }

  String get fullLabel => '$dateLabel · $timeLabel';

  Map<String, dynamic> toRpcParams() {
    return <String, dynamic>{
      'p_slot_start_at': AppTime.utcIsoString(startUtc),
      'p_slot_end_at': AppTime.utcIsoString(endUtc),
    };
  }
}
