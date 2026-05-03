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

  // Convert Firestore document to AppUser object
  factory AppUser.fromJson(Map<String, dynamic> json, String userId) {
    return AppUser(
      userId: userId,
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      displayName: json['displayName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toDate().toString())
          : DateTime.now(),
    );
  }

  // Convert AppUser object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'createdAt': createdAt,
    };
  }
}
