import 'package:cloud_firestore/cloud_firestore.dart' as fb;
import '../models/index.dart';

/// Service for Firestore database operations
class FirestoreService {
  final fb.FirebaseFirestore _firestore = fb.FirebaseFirestore.instance;

  /// Create a new order
  Future<Order> createOrder(Order order) async {
    try {
      fb.DocumentReference ref = await _firestore
          .collection('orders')
          .add(order.toJson());

      return order.copyWith(orderId: ref.id);
    } on fb.FirebaseException catch (e) {
      throw 'Failed to create order: ${e.message}';
    }
  }

  /// Get a single order by ID
  Future<Order?> getOrder(String orderId) async {
    try {
      fb.DocumentSnapshot doc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        return Order.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } on fb.FirebaseException catch (e) {
      throw 'Failed to get order: ${e.message}';
    }
  }

  /// Get all orders for a user (real-time stream)
  Stream<List<Order>> getUserOrders(String userId) {
    try {
      return _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((fb.QuerySnapshot snapshot) {
            return snapshot.docs.map((fb.DocumentSnapshot doc) {
              return Order.fromJson(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();
          });
    } on fb.FirebaseException catch (e) {
      throw 'Failed to fetch orders: ${e.message}';
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
    } on fb.FirebaseException catch (e) {
      throw 'Failed to update order status: ${e.message}';
    }
  }

  /// Assign an agent to an order
  Future<void> assignAgent(String orderId, String agentId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'agentId': agentId,
        'status': 'assigned',
      });
    } on fb.FirebaseException catch (e) {
      throw 'Failed to assign agent: ${e.message}';
    }
  }

  /// Update order test list
  Future<void> updateTestList(String orderId, List<String> testList) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'testList': testList,
      });
    } on fb.FirebaseException catch (e) {
      throw 'Failed to update test list: ${e.message}';
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
    } on fb.FirebaseException catch (e) {
      throw 'Failed to delete order: ${e.message}';
    }
  }
}
