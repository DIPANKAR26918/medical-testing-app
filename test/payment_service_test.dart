import 'package:flutter_test/flutter_test.dart';
import 'package:medical_diagnostic_app/models/order.dart';
import 'package:medical_diagnostic_app/services/payment_service.dart';

void main() {
  group('Razorpay checkout session', () {
    test('uses only server-issued public checkout values', () {
      final session = RazorpayCheckoutSession.fromJson({
        'booking_order_id': 42,
        'razorpay_order_id': 'order_test_42',
        'key_id': 'rzp_test_public',
        'amount': 49900,
        'currency': 'INR',
        'description': 'CBC',
        'prefill': {
          'name': 'Test Patient',
          'contact': '+919876543210',
          'email': '',
        },
      });

      final options = session.toCheckoutOptions();

      expect(options['key'], 'rzp_test_public');
      expect(options['order_id'], 'order_test_42');
      expect(options['amount'], 49900);
      expect(options['currency'], 'INR');
      expect(options, isNot(contains('key_secret')));
      expect(options, isNot(contains('webhook_secret')));
      expect(
        options['prefill'],
        {
          'name': 'Test Patient',
          'contact': '+919876543210',
        },
      );
    });

    test('rejects an invalid server checkout payload', () {
      expect(
        () => RazorpayCheckoutSession.fromJson({
          'booking_order_id': 42,
          'razorpay_order_id': 'order_test_42',
          'key_id': 'rzp_test_public',
          'amount': 0,
          'currency': 'INR',
        }),
        throwsA(
          isA<PaymentException>().having(
            (error) => error.code,
            'code',
            'invalid_checkout_session',
          ),
        ),
      );
    });
  });

  group('Order payment state', () {
    test('allows retry only while a paid booking is still pending', () {
      final pendingOrder = Order.fromJson({
        'id': 42,
        'user_id': 'user-id',
        'status': 'payment_pending',
        'payment_status': 'failed',
        'test_list': ['CBC'],
        'price': 499,
        'timeline': <Map<String, dynamic>>[],
        'created_at': '2026-07-29T00:00:00Z',
      });

      expect(pendingOrder.requiresOnlinePayment, isTrue);
      expect(pendingOrder.isPaid, isFalse);
    });

    test('recognizes a captured and finalized booking', () {
      final paidOrder = Order.fromJson({
        'id': 42,
        'user_id': 'user-id',
        'status': 'confirmed',
        'payment_status': 'paid',
        'payment_provider': 'razorpay',
        'paid_at': '2026-07-29T00:05:00Z',
        'test_list': ['CBC'],
        'price': 499,
        'timeline': <Map<String, dynamic>>[],
        'created_at': '2026-07-29T00:00:00Z',
      });

      expect(paidOrder.requiresOnlinePayment, isFalse);
      expect(paidOrder.isPaid, isTrue);
      expect(paidOrder.paymentProvider, 'razorpay');
    });

    test('keeps a refunded booking out of the retry flow', () {
      final refundedOrder = Order.fromJson({
        'id': 42,
        'user_id': 'user-id',
        'status': 'confirmed',
        'payment_status': 'refunded',
        'payment_provider': 'razorpay',
        'paid_at': '2026-07-29T00:05:00Z',
        'test_list': ['CBC'],
        'price': 499,
        'timeline': <Map<String, dynamic>>[],
        'created_at': '2026-07-29T00:00:00Z',
      });

      expect(refundedOrder.requiresOnlinePayment, isFalse);
      expect(refundedOrder.isPaid, isTrue);
      expect(refundedOrder.hasRefund, isTrue);
    });
  });
}
