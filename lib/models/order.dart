import 'medical_test.dart';

// Order model for Supabase database
class Order {
  final String orderId;
  final String userId;
  final String prescriptionImagePath;
  final String
  status; // uploaded, confirmed, assigned, collected, testing, completed
  final List<String> testList;
  final double price;
  final String? agentId;
  final String? patientName;
  final String? patientPhoneNumber;
  final int? patientAge;
  final String? patientGender;
  final String? collectionAddressId;
  final String? patientLocationAddress;
  final double? patientLocationLatitude;
  final double? patientLocationLongitude;
  final String? patientLocationType;
  final List<Map<String, dynamic>> timeline;
  final DateTime createdAt;
  final DateTime? reviewStartedAt;
  final DateTime? testsPreparedAt;
  final DateTime? userConfirmedAt;

  Order({
    required this.orderId,
    required this.userId,
    required this.prescriptionImagePath,
    required this.status,
    required this.testList,
    required this.price,
    this.agentId,
    this.patientName,
    this.patientPhoneNumber,
    this.patientAge,
    this.patientGender,
    this.collectionAddressId,
    this.patientLocationAddress,
    this.patientLocationLatitude,
    this.patientLocationLongitude,
    this.patientLocationType,
    required this.timeline,
    required this.createdAt,
    this.reviewStartedAt,
    this.testsPreparedAt,
    this.userConfirmedAt,
  });

  // Convert Supabase row to Order object
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['id'].toString(),
      userId: json['user_id'] ?? '',
      prescriptionImagePath: json['prescription_image_url'] ?? '',
      status: json['status'] ?? 'uploaded',
      testList: List<String>.from(json['test_list'] ?? []),
      price: (json['price'] ?? 0).toDouble(),
      agentId: json['agent_id'],
      patientName: json['patient_name'],
      patientPhoneNumber: json['patient_phone_number'],
      patientAge: _parseAge(json['patient_age']),
      patientGender: json['patient_gender'],
      collectionAddressId: json['collection_address_id']?.toString(),
      patientLocationAddress: json['patient_location_address'],
      patientLocationLatitude: _parseDouble(json['patient_latitude']),
      patientLocationLongitude: _parseDouble(json['patient_longitude']),
      patientLocationType: json['patient_location_type'],
      timeline: List<Map<String, dynamic>>.from(json['timeline'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      reviewStartedAt: _parseDate(json['review_started_at']),
      testsPreparedAt: _parseDate(json['tests_prepared_at']),
      userConfirmedAt: _parseDate(json['user_confirmed_at']),
    );
  }

  // Convert Order object to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'prescription_image_url': prescriptionImagePath,
      'status': status,
      'test_list': testList,
      'price': price,
      'agent_id': agentId,
      'patient_name': patientName,
      'patient_phone_number': patientPhoneNumber,
      'patient_age': patientAge,
      'patient_gender': patientGender,
      'collection_address_id': collectionAddressId,
      'patient_location_address': patientLocationAddress,
      'patient_latitude': patientLocationLatitude,
      'patient_longitude': patientLocationLongitude,
      'patient_location_type': patientLocationType,
      'timeline': timeline,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create a copy with updated fields (for immutability)
  Order copyWith({
    String? orderId,
    String? userId,
    String? prescriptionImagePath,
    String? status,
    List<String>? testList,
    double? price,
    String? agentId,
    String? patientName,
    String? patientPhoneNumber,
    int? patientAge,
    String? patientGender,
    String? collectionAddressId,
    String? patientLocationAddress,
    double? patientLocationLatitude,
    double? patientLocationLongitude,
    String? patientLocationType,
    List<Map<String, dynamic>>? timeline,
    DateTime? createdAt,
    DateTime? reviewStartedAt,
    DateTime? testsPreparedAt,
    DateTime? userConfirmedAt,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      prescriptionImagePath:
          prescriptionImagePath ?? this.prescriptionImagePath,
      status: status ?? this.status,
      testList: testList ?? this.testList,
      price: price ?? this.price,
      agentId: agentId ?? this.agentId,
      patientName: patientName ?? this.patientName,
      patientPhoneNumber: patientPhoneNumber ?? this.patientPhoneNumber,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      collectionAddressId: collectionAddressId ?? this.collectionAddressId,
      patientLocationAddress:
          patientLocationAddress ?? this.patientLocationAddress,
      patientLocationLatitude:
          patientLocationLatitude ?? this.patientLocationLatitude,
      patientLocationLongitude:
          patientLocationLongitude ?? this.patientLocationLongitude,
      patientLocationType: patientLocationType ?? this.patientLocationType,
      timeline: timeline ?? this.timeline,
      createdAt: createdAt ?? this.createdAt,
      reviewStartedAt: reviewStartedAt ?? this.reviewStartedAt,
      testsPreparedAt: testsPreparedAt ?? this.testsPreparedAt,
      userConfirmedAt: userConfirmedAt ?? this.userConfirmedAt,
    );
  }

  static int? _parseAge(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class PrescriptionOrderTest {
  const PrescriptionOrderTest({
    required this.test,
    required this.selectedByUser,
  });

  final MedicalTest test;
  final bool selectedByUser;

  factory PrescriptionOrderTest.fromJson(Map<String, dynamic> json) {
    final nested = json['medical_tests'];
    final testJson = nested is Map
        ? Map<String, dynamic>.from(nested)
        : <String, dynamic>{'id': json['medical_test_id']};
    return PrescriptionOrderTest(
      test: MedicalTest.fromJson(testJson),
      selectedByUser: json['selected_by_user'] == true,
    );
  }
}
