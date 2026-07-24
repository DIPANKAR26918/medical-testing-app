import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medical_test.dart';
import '../models/order.dart';

class DirectBookingService {
  DirectBookingService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Order> createBooking({
    required Iterable<MedicalTest> tests,
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

    if (hasHomeCollection &&
        (collectionAddressId == null || collectionAddressId.trim().isEmpty)) {
      throw const DirectBookingException('Choose a collection address.');
    }

    try {
      final response = await _client.rpc(
        'create_direct_test_booking',
        params: <String, dynamic>{
          'p_test_ids': testIds,
          'p_collection_address_id': collectionAddressId,
        },
      );

      final row = _singleRow(response);
      return Order.fromJson(row);
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
