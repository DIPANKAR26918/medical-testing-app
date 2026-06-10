import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/index.dart';

/// Service for Supabase PostgreSQL database operations
class FirestoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new order
  Future<Order> createOrder(Order order) async {
    try {
      final response = await _supabase.from('orders').insert({
        'user_id': order.userId,
        'prescription_image_url': order.prescriptionImagePath,
        'status': order.status,
        'test_list': order.testList,
        'price': order.price,
        'agent_id': order.agentId,
        'timeline': order.timeline,
        'created_at': order.createdAt.toIso8601String(),
      }).select();

      if (response.isEmpty) {
        throw Exception('Failed to create order');
      }

      final data = response.first;
      return Order(
        orderId: data['id'].toString(),
        userId: data['user_id'] ?? '',
        prescriptionImagePath: data['prescription_image_url'] ?? '',
        status: data['status'] ?? 'uploaded',
        testList: List<String>.from(data['test_list'] ?? []),
        price: (data['price'] ?? 0).toDouble(),
        agentId: data['agent_id'],
        timeline: List<Map<String, dynamic>>.from(data['timeline'] ?? []),
        createdAt: DateTime.parse(
          data['created_at'] ?? DateTime.now().toIso8601String(),
        ),
      );
    } on PostgrestException catch (e) {
      throw 'Failed to create order: ${e.message}';
    }
  }

  /// Get a single order by ID
  Future<Order?> getOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('id', int.parse(orderId))
          .single();

      return Order(
        orderId: response['id'].toString(),
        userId: response['user_id'] ?? '',
        prescriptionImagePath: response['prescription_image_url'] ?? '',
        status: response['status'] ?? 'uploaded',
        testList: List<String>.from(response['test_list'] ?? []),
        price: (response['price'] ?? 0).toDouble(),
        agentId: response['agent_id'],
        timeline: List<Map<String, dynamic>>.from(response['timeline'] ?? []),
        createdAt: DateTime.parse(
          response['created_at'] ?? DateTime.now().toIso8601String(),
        ),
      );
    } on PostgrestException {
      return null;
    }
  }

  /// Get all orders for a user (real-time stream)
  Stream<List<Order>> getUserOrders(String userId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
          return data.map((item) {
            return Order(
              orderId: item['id'].toString(),
              userId: item['user_id'] ?? '',
              prescriptionImagePath: item['prescription_image_url'] ?? '',
              status: item['status'] ?? 'uploaded',
              testList: List<String>.from(item['test_list'] ?? []),
              price: (item['price'] ?? 0).toDouble(),
              agentId: item['agent_id'],
              timeline: List<Map<String, dynamic>>.from(item['timeline'] ?? []),
              createdAt: DateTime.parse(
                item['created_at'] ?? DateTime.now().toIso8601String(),
              ),
            );
          }).toList();
        });
  }

  /// Get all pending orders for agents (uploaded, confirmed) - real-time stream
  Stream<List<Order>> getPendingOrders() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .inFilter('status', ['uploaded', 'confirmed'])
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
          return data.map((item) {
            return Order(
              orderId: item['id'].toString(),
              userId: item['user_id'] ?? '',
              prescriptionImagePath: item['prescription_image_url'] ?? '',
              status: item['status'] ?? 'uploaded',
              testList: List<String>.from(item['test_list'] ?? []),
              price: (item['price'] ?? 0).toDouble(),
              agentId: item['agent_id'],
              timeline: List<Map<String, dynamic>>.from(item['timeline'] ?? []),
              createdAt: DateTime.parse(
                item['created_at'] ?? DateTime.now().toIso8601String(),
              ),
            );
          }).toList();
        });
  }

  /// Stream pending orders with real-time updates
  Stream<List<Order>> streamPendingOrders() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .inFilter('status', ['uploaded', 'confirmed'])
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
          return data.map((item) {
            return Order(
              orderId: item['id'].toString(),
              userId: item['user_id'] ?? '',
              prescriptionImagePath: item['prescription_image_url'] ?? '',
              status: item['status'] ?? 'uploaded',
              testList: List<String>.from(item['test_list'] ?? []),
              price: (item['price'] ?? 0).toDouble(),
              agentId: item['agent_id'],
              timeline: List<Map<String, dynamic>>.from(item['timeline'] ?? []),
              createdAt: DateTime.parse(
                item['created_at'] ?? DateTime.now().toIso8601String(),
              ),
            );
          }).toList();
        });
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _supabase
          .from('orders')
          .update({
            'status': newStatus,
            'timeline': _addToTimeline(orderId, {
              'status': newStatus,
              'timestamp': now,
            }),
          })
          .eq('id', int.parse(orderId));
    } on PostgrestException catch (e) {
      throw 'Failed to update order status: ${e.message}';
    }
  }

  /// Assign an agent to an order
  Future<void> assignAgent(String orderId, String agentId) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _supabase
          .from('orders')
          .update({
            'agent_id': agentId,
            'status': 'assigned',
            'timeline': _addToTimeline(orderId, {
              'status': 'assigned',
              'agent_id': agentId,
              'timestamp': now,
            }),
          })
          .eq('id', int.parse(orderId));
    } on PostgrestException catch (e) {
      throw 'Failed to assign agent: ${e.message}';
    }
  }

  /// Update order test list
  Future<void> updateTestList(String orderId, List<String> testList) async {
    try {
      await _supabase
          .from('orders')
          .update({'test_list': testList})
          .eq('id', int.parse(orderId));
    } on PostgrestException catch (e) {
      throw 'Failed to update test list: ${e.message}';
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _supabase.from('orders').delete().eq('id', int.parse(orderId));
    } on PostgrestException catch (e) {
      throw 'Failed to delete order: ${e.message}';
    }
  }

  /// Helper method to add to timeline array
  Future<List<Map<String, dynamic>>> _addToTimeline(
    String orderId,
    Map<String, dynamic> timelineEntry,
  ) async {
    try {
      final order = await getOrder(orderId);
      if (order != null) {
        final updatedTimeline = [...order.timeline, timelineEntry];
        return updatedTimeline;
      }
      return [timelineEntry];
    } catch (e) {
      return [timelineEntry];
    }
  }
}
