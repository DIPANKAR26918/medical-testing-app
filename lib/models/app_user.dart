// User model for authentication and user data
class AppUser {
  final String userId;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final DateTime createdAt;

  AppUser({
    required this.userId,
    this.email,
    this.phoneNumber,
    this.displayName,
    required this.createdAt,
  });

  // Convert Supabase row to AppUser object
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['id'] ?? json['user_id'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'],
      displayName: json['display_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  // Convert AppUser object to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'email': email,
      'phone_number': phoneNumber,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
