// Order model for Firestore database
class Order {
  final String orderId;
  final String userId;
  final String prescriptionImageUrl;
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
    required this.prescriptionImageUrl,
    required this.status,
    required this.testList,
    required this.price,
    this.agentId,
    required this.timeline,
    required this.createdAt,
  });

  // Convert Firestore document to Order object
  factory Order.fromJson(Map<String, dynamic> json, String docId) {
    return Order(
      orderId: docId,
      userId: json['userId'] ?? '',
      prescriptionImageUrl: json['prescriptionImageUrl'] ?? '',
      status: json['status'] ?? 'uploaded',
      testList: List<String>.from(json['testList'] ?? []),
      price: (json['price'] ?? 0).toDouble(),
      agentId: json['agentId'],
      timeline: List<Map<String, dynamic>>.from(json['timeline'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toDate().toString())
          : DateTime.now(),
    );
  }

  // Convert Order object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'prescriptionImageUrl': prescriptionImageUrl,
      'status': status,
      'testList': testList,
      'price': price,
      'agentId': agentId,
      'timeline': timeline,
      'createdAt': createdAt,
    };
  }

  // Create a copy with updated fields (for immutability)
  Order copyWith({
    String? orderId,
    String? userId,
    String? prescriptionImageUrl,
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
      prescriptionImageUrl: prescriptionImageUrl ?? this.prescriptionImageUrl,
      status: status ?? this.status,
      testList: testList ?? this.testList,
      price: price ?? this.price,
      agentId: agentId ?? this.agentId,
      timeline: timeline ?? this.timeline,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
