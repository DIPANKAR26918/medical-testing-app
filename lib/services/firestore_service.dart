import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/index.dart';

/// Service for Supabase PostgreSQL database operations
class FirestoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new order
  Future<Order> createOrder(Order order, {AppUser? patient}) async {
    final payload = <String, dynamic>{
      'user_id': order.userId,
      'prescription_image_url': order.prescriptionImagePath,
      'status': order.status,
      'test_list': order.testList,
      'price': order.price,
      'agent_id': order.agentId,
      'timeline': order.timeline,
      'created_at': order.createdAt.toIso8601String(),
      'collection_address_id': order.collectionAddressId,
      'patient_location_address': order.patientLocationAddress,
      'patient_latitude': order.patientLocationLatitude,
      'patient_longitude': order.patientLocationLongitude,
      'patient_location_type': order.patientLocationType,
    };
    final patientSnapshot = _patientSnapshotFields(order, patient);
    payload.addAll(patientSnapshot);

    try {
      return await _insertOrder(payload);
    } on PostgrestException catch (e) {
      if (patientSnapshot.isNotEmpty && _isMissingPatientSnapshotColumn(e)) {
        final fallbackPayload = Map<String, dynamic>.from(payload)
          ..removeWhere((key, value) => key.startsWith('patient_'));

        try {
          return await _insertOrder(fallbackPayload);
        } on PostgrestException catch (fallbackError) {
          throw 'Failed to create order: ${fallbackError.message}';
        }
      }

      throw 'Failed to create order: ${e.message}';
    }
  }

  Future<Order> _insertOrder(Map<String, dynamic> payload) async {
    final response = await _supabase.from('orders').insert(payload).select();

    if (response.isEmpty) {
      throw Exception('Failed to create order');
    }

    return Order.fromJson(response.first);
  }

  /// Get a single order by ID
  Future<Order?> getOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('id', int.parse(orderId))
          .single();

      return Order.fromJson(response);
    } on PostgrestException {
      return null;
    }
  }

  Future<List<PrescriptionOrderTest>> fetchPrescriptionTests(
    String orderId,
  ) async {
    final response = await _supabase
        .from('order_tests')
        .select(
          'medical_test_id,selected_by_user,'
          'medical_tests('
          'id,test_code,name_sheet,common_name,mrp,reporting_time,'
          'sample_type_volume,category,body_system,test_type,purpose,'
          'preparation,age_recommendation,home_collection_available,'
          'lab_visit_required,special_handling_required,is_popular,min_age,'
          'max_age,gender,parameter_count,included_parameters,sample_source,'
          'sample_source_label,sample_collection_note,display_order)',
        )
        .eq('order_id', int.parse(orderId));

    final tests = response
        .whereType<Map>()
        .map(
          (row) => PrescriptionOrderTest.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: true);
    tests.sort((a, b) => a.test.displayName.compareTo(b.test.displayName));
    return List<PrescriptionOrderTest>.unmodifiable(tests);
  }

  Future<Order> confirmPrescriptionBooking(
    String orderId,
    Iterable<String> selectedTestIds,
  ) async {
    try {
      final response = await _supabase.rpc(
        'confirm_prescription_booking',
        params: {
          'p_order_id': int.parse(orderId),
          'p_selected_test_ids': selectedTestIds.toList(growable: false),
        },
      );
      if (response is Map) {
        return Order.fromJson(Map<String, dynamic>.from(response));
      }
      if (response is List && response.isNotEmpty && response.first is Map) {
        return Order.fromJson(
          Map<String, dynamic>.from(response.first as Map),
        );
      }
      throw const FormatException('Booking confirmation response was invalid.');
    } on PostgrestException catch (error) {
      throw Exception(error.message);
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
          return data.map(Order.fromJson).toList();
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
          return data.map(Order.fromJson).toList();
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
          return data.map(Order.fromJson).toList();
        });
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updatedTimeline = await _addToTimeline(orderId, {
        'status': newStatus,
        'timestamp': now,
      });

      await _supabase
          .from('orders')
          .update({'status': newStatus, 'timeline': updatedTimeline})
          .eq('id', int.parse(orderId));
    } on PostgrestException catch (e) {
      throw 'Failed to update order status: ${e.message}';
    }
  }

  /// Assign an agent to an order
  Future<void> assignAgent(String orderId, String agentId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updatedTimeline = await _addToTimeline(orderId, {
        'status': 'assigned',
        'agent_id': agentId,
        'timestamp': now,
      });

      await _supabase
          .from('orders')
          .update({
            'agent_id': agentId,
            'status': 'assigned',
            'timeline': updatedTimeline,
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

  Map<String, dynamic> _patientSnapshotFields(Order order, AppUser? patient) {
    final patientName = _cleanPatientName(order.patientName ?? patient?.name);
    final patientPhoneNumber = _cleanText(
      order.patientPhoneNumber ?? patient?.phoneNumber,
    );
    final patientGender = _cleanText(order.patientGender ?? patient?.gender);
    final patientAge = order.patientAge ?? patient?.age;

    return <String, dynamic>{
      'patient_name': ?patientName,
      'patient_phone_number': ?patientPhoneNumber,
      'patient_age': ?patientAge,
      'patient_gender': ?patientGender,
    };
  }

  String? _cleanPatientName(String? value) {
    final cleanValue = _cleanText(value);
    if (cleanValue == null || cleanValue == 'Testified user') return null;
    return cleanValue;
  }

  String? _cleanText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  bool _isMissingPatientSnapshotColumn(PostgrestException error) {
    final details = [
      error.message,
      error.details,
      error.hint,
      error.code,
    ].whereType<String>().join(' ').toLowerCase();

    return details.contains('patient_') ||
        details.contains('could not find') ||
        details.contains('column');
  }
}
