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
  final List<Map<String, dynamic>> timeline;
  final DateTime createdAt;

  Order({
    required this.orderId,
    required this.userId,
    required this.prescriptionImagePath,
    required this.status,
    required this.testList,
    required this.price,
    this.agentId,
    required this.timeline,
    required this.createdAt,
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
      timeline: List<Map<String, dynamic>>.from(json['timeline'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
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
    List<Map<String, dynamic>>? timeline,
    DateTime? createdAt,
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
      timeline: timeline ?? this.timeline,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
