import '../utils/app_time.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.kind,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String kind;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'general',
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : const <String, dynamic>{},
      createdAt:
          AppTime.parseUtc(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      readAt: AppTime.parseUtc(json['read_at']),
    );
  }
}
