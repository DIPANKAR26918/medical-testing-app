// User model for authentication and user data
import '../utils/app_time.dart';

class AppUser {
  final String userId;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? fullName;
  final int? age;
  final String? gender;
  final DateTime createdAt;

  AppUser({
    required this.userId,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.fullName,
    this.age,
    this.gender,
    required this.createdAt,
  });

  String get name {
    final storedName = fullName?.trim();
    if (storedName != null && storedName.isNotEmpty) return storedName;

    final legacyName = displayName?.trim();
    if (legacyName != null && legacyName.isNotEmpty) return legacyName;

    return 'Testified user';
  }

  String get initials {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'T';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  // Convert Supabase row to AppUser object
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['id'] ?? json['user_id'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'],
      displayName: json['display_name'],
      fullName: json['full_name'],
      age: _parseAge(json['age']),
      gender: json['gender'],
      createdAt: AppTime.parseUtc(json['created_at']) ?? AppTime.nowUtc(),
    );
  }

  // Convert AppUser object to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'email': email,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'created_at': AppTime.utcIsoString(createdAt),
    };
  }

  static int? _parseAge(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
