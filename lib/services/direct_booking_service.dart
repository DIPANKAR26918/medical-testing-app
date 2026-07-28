import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/collection_slot.dart';
import '../models/medical_test.dart';
import '../models/order.dart';

class DirectBookingService {
  DirectBookingService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Order> createBooking({
    required Iterable<MedicalTest> tests,
    required CollectionSlot collectionSlot,
    String? collectionAddressId,
  }) async {
    final selectedTests = tests.toList(growable: false);
    final testIds = selectedTests
        .map((test) => test.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (testIds.isEmpty) {
      throw const DirectBookingException('Select at least one medical test.');
    }

    if (testIds.length != selectedTests.length) {
      throw const DirectBookingException(
        'One or more selected tests are invalid. Refresh the catalogue and retry.',
      );
    }

    final hasLabVisit = selectedTests.any((test) => test.labVisitRequired);
    final hasHomeCollection = selectedTests.any(
      (test) => !test.labVisitRequired,
    );

    if (hasLabVisit && hasHomeCollection) {
      throw const DirectBookingException(
        'Lab-visit and home-collection tests must be booked separately.',
      );
    }

    final normalizedAddressId = collectionAddressId?.trim();

    try {
      final response = await _client.rpc(
        'create_direct_test_booking',
        params: <String, dynamic>{
          'p_test_ids': testIds,
          'p_collection_address_id':
              normalizedAddressId == null || normalizedAddressId.isEmpty
                  ? null
                  : normalizedAddressId,
          ...collectionSlot.toRpcParams(),
        },
      );

      final row = _singleRow(response);
      return Order.fromJson(row);
    } on PostgrestException catch (error) {
      throw DirectBookingException(error.message);
    }
  }

  Future<Order> scheduleExistingBooking({
    required String orderId,
    required CollectionSlot collectionSlot,
  }) async {
    try {
      final response = await _client.rpc(
        'schedule_direct_test_booking',
        params: <String, dynamic>{
          'p_order_id': int.parse(orderId),
          ...collectionSlot.toRpcParams(),
        },
      );
      return Order.fromJson(_singleRow(response));
    } on PostgrestException catch (error) {
      throw DirectBookingException(error.message);
    }
  }

  Map<String, dynamic> _singleRow(dynamic response) {
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }

    throw const DirectBookingException(
      'The booking response was invalid. Please retry.',
    );
  }
}

class DirectBookingException implements Exception {
  const DirectBookingException(this.message);

  final String message;

  @override
  String toString() => message;
}
