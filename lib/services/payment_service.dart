import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';

class RazorpayCheckoutSession {
  const RazorpayCheckoutSession({
    required this.bookingOrderId,
    required this.razorpayOrderId,
    required this.keyId,
    required this.amountPaise,
    required this.currency,
    required this.description,
    this.prefillName,
    this.prefillContact,
    this.prefillEmail,
  });

  final String bookingOrderId;
  final String razorpayOrderId;
  final String keyId;
  final int amountPaise;
  final String currency;
  final String description;
  final String? prefillName;
  final String? prefillContact;
  final String? prefillEmail;

  factory RazorpayCheckoutSession.fromJson(Map<String, dynamic> json) {
    final bookingOrderId = json['booking_order_id']?.toString().trim() ?? '';
    final razorpayOrderId = json['razorpay_order_id']?.toString().trim() ?? '';
    final keyId = json['key_id']?.toString().trim() ?? '';
    final amountPaise = _parsePositiveInt(json['amount']);
    final currency = json['currency']?.toString().trim().toUpperCase() ?? '';
    final description =
        json['description']?.toString().trim() ?? 'Diagnostic test booking';
    final prefill = json['prefill'] is Map
        ? Map<String, dynamic>.from(json['prefill'] as Map)
        : const <String, dynamic>{};

    if (bookingOrderId.isEmpty ||
        razorpayOrderId.isEmpty ||
        keyId.isEmpty ||
        amountPaise == null ||
        currency != 'INR') {
      throw const PaymentException(
        'Payment could not be started. Please try again.',
        code: 'invalid_checkout_session',
      );
    }

    return RazorpayCheckoutSession(
      bookingOrderId: bookingOrderId,
      razorpayOrderId: razorpayOrderId,
      keyId: keyId,
      amountPaise: amountPaise,
      currency: currency,
      description: description,
      prefillName: _optionalText(prefill['name']),
      prefillContact: _optionalText(prefill['contact']),
      prefillEmail: _optionalText(prefill['email']),
    );
  }

  Map<String, dynamic> toCheckoutOptions() {
    final prefill = <String, String>{
      if (prefillName != null) 'name': prefillName!,
      if (prefillContact != null) 'contact': prefillContact!,
      if (prefillEmail != null) 'email': prefillEmail!,
    };

    return <String, dynamic>{
      'key': keyId,
      'amount': amountPaise,
      'currency': currency,
      'name': 'Testified',
      'description': description,
      'order_id': razorpayOrderId,
      if (prefill.isNotEmpty) 'prefill': prefill,
      'theme': <String, String>{'color': '#2563EB'},
      'retry': <String, dynamic>{'enabled': true, 'max_count': 4},
      'timeout': 600,
      'modal': <String, bool>{'confirm_close': true},
    };
  }

  static int? _parsePositiveInt(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static String? _optionalText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class PaymentService {
  PaymentService({SupabaseClient? client}) : _providedClient = client;

  final SupabaseClient? _providedClient;

  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  Razorpay? _razorpay;
  Completer<_CheckoutResponse>? _checkoutCompleter;
  bool _disposed = false;

  static bool get isCheckoutSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<Order> payForOrder(Order order) async {
    if (_disposed) {
      throw const PaymentException(
        'Payment is unavailable on this screen. Please reopen the booking.',
        code: 'payment_service_disposed',
      );
    }

    // The migration ships behind a server-side rollout switch. Orders remain
    // immediately confirmed until that switch is enabled.
    if (!order.requiresOnlinePayment) return order;

    if (!isCheckoutSupported) {
      throw const PaymentException(
        'Razorpay Checkout is available in the Android and iOS app.',
        code: 'unsupported_platform',
      );
    }

    final preparation = await _prepareCheckout(order);
    if (preparation.alreadyPaidOrder != null) {
      return preparation.alreadyPaidOrder!;
    }

    final session = preparation.session!;
    final checkoutResponse = await _openCheckout(session);
    if (checkoutResponse.orderId != session.razorpayOrderId) {
      throw const PaymentException(
        'Payment details did not match this booking. No booking was confirmed.',
        code: 'checkout_order_mismatch',
      );
    }

    return _verifyPayment(session, checkoutResponse);
  }

  Future<_CheckoutPreparation> _prepareCheckout(Order order) async {
    final bookingOrderId = _bookingOrderNumber(order.orderId);
    final response = await _invoke(
      'create-razorpay-order',
      body: <String, dynamic>{'order_id': bookingOrderId},
    );
    final data = _responseMap(response.data);

    if (response.status == 202 && data['payment_status'] == 'processing') {
      throw const PaymentException(
        'Payment is being confirmed. Check Bookings again in a moment.',
        code: 'payment_processing',
        processing: true,
      );
    }
    if (response.status < 200 || response.status >= 300) {
      throw PaymentException(
        _messageForServerError(data['error']),
        code: data['error']?.toString(),
      );
    }

    if (data['already_paid'] == true) {
      return _CheckoutPreparation(
        alreadyPaidOrder: _orderFromPayload(data['order']),
      );
    }

    return _CheckoutPreparation(
      session: RazorpayCheckoutSession.fromJson(data),
    );
  }

  Future<_CheckoutResponse> _openCheckout(
    RazorpayCheckoutSession session,
  ) async {
    if (_checkoutCompleter != null) {
      throw const PaymentException(
        'A payment is already open.',
        code: 'checkout_already_open',
      );
    }

    final checkout = _ensureCheckout();
    final completer = Completer<_CheckoutResponse>();
    _checkoutCompleter = completer;

    try {
      checkout.open(session.toCheckoutOptions());
      return await completer.future.timeout(
        const Duration(minutes: 11),
        onTimeout: () => throw const PaymentException(
          'Payment timed out. You can safely try again.',
          code: 'checkout_timeout',
        ),
      );
    } on PaymentException {
      rethrow;
    } catch (_) {
      throw const PaymentException(
        'Razorpay Checkout could not be opened. Please try again.',
        code: 'checkout_open_failed',
      );
    } finally {
      if (identical(_checkoutCompleter, completer)) {
        _checkoutCompleter = null;
      }
    }
  }

  Razorpay _ensureCheckout() {
    final existing = _razorpay;
    if (existing != null) return existing;

    final checkout = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _razorpay = checkout;
    return checkout;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId?.trim() ?? '';
    final orderId = response.orderId?.trim() ?? '';
    final signature = response.signature?.trim() ?? '';
    if (paymentId.isEmpty || orderId.isEmpty || signature.isEmpty) {
      _completeCheckoutError(
        const PaymentException(
          'Razorpay returned an incomplete payment response.',
          code: 'incomplete_checkout_response',
        ),
      );
      return;
    }

    final completer = _checkoutCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(
        _CheckoutResponse(
          paymentId: paymentId,
          orderId: orderId,
          signature: signature,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final cancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    final message = cancelled
        ? 'Payment cancelled. Your booking has not been confirmed.'
        : switch (response.code) {
            Razorpay.NETWORK_ERROR =>
              'Network interrupted the payment. Check your connection and retry.',
            Razorpay.TLS_ERROR =>
              'A secure payment connection could not be created.',
            _ => 'Payment was not completed. You can safely try again.',
          };
    _completeCheckoutError(
      PaymentException(
        message,
        code: cancelled ? 'checkout_cancelled' : 'checkout_failed',
        cancelled: cancelled,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse _) {
    _completeCheckoutError(
      const PaymentException(
        'The wallet payment is being confirmed. Check Bookings in a moment.',
        code: 'payment_processing',
        processing: true,
      ),
    );
  }

  void _completeCheckoutError(PaymentException error) {
    final completer = _checkoutCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }

  Future<Order> _verifyPayment(
    RazorpayCheckoutSession session,
    _CheckoutResponse checkout,
  ) async {
    final response = await _invoke(
      'verify-razorpay-payment',
      body: <String, dynamic>{
        'booking_order_id': _bookingOrderNumber(session.bookingOrderId),
        'razorpay_order_id': checkout.orderId,
        'razorpay_payment_id': checkout.paymentId,
        'razorpay_signature': checkout.signature,
      },
    );
    final data = _responseMap(response.data);

    if (response.status == 202 && data['payment_status'] == 'processing') {
      throw const PaymentException(
        'Payment was received and is being confirmed. Check Bookings in a moment.',
        code: 'payment_processing',
        processing: true,
      );
    }
    if (response.status < 200 || response.status >= 300) {
      throw PaymentException(
        _messageForServerError(data['error']),
        code: data['error']?.toString(),
      );
    }

    final paidOrder = _orderFromPayload(data['order']);
    if (!paidOrder.isPaid) {
      throw const PaymentException(
        'Payment is still being confirmed. Check Bookings in a moment.',
        code: 'payment_processing',
        processing: true,
      );
    }
    return paidOrder;
  }

  Future<FunctionResponse> _invoke(
    String functionName, {
    required Map<String, dynamic> body,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const PaymentException(
        'Your session expired. Sign in again before paying.',
        code: 'authentication_required',
      );
    }

    try {
      return await _client.functions.invoke(
        functionName,
        headers: <String, String>{
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: body,
      );
    } on FunctionException catch (error) {
      return FunctionResponse(data: error.details, status: error.status);
    } catch (_) {
      throw const PaymentException(
        'Could not reach the payment service. Check your connection and retry.',
        code: 'payment_service_unreachable',
      );
    }
  }

  static Map<String, dynamic> _responseMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return const <String, dynamic>{};
      }
    }
    return const <String, dynamic>{};
  }

  static int _bookingOrderNumber(String rawValue) {
    final value = int.tryParse(rawValue);
    if (value == null || value <= 0) {
      throw const PaymentException(
        'This booking cannot be used for payment.',
        code: 'invalid_booking_order',
      );
    }
    return value;
  }

  static Order _orderFromPayload(dynamic value) {
    if (value is Map) {
      return Order.fromJson(Map<String, dynamic>.from(value));
    }
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Order.fromJson(Map<String, dynamic>.from(value.first as Map));
    }
    throw const PaymentException(
      'The confirmed booking response was invalid.',
      code: 'invalid_paid_order',
    );
  }

  static String _messageForServerError(dynamic rawCode) {
    return switch (rawCode?.toString()) {
      'authentication_required' =>
        'Your session expired. Sign in again before paying.',
      'payments_not_configured' =>
        'Online payment is being configured. Please try again later.',
      'payment_provider_unavailable' || 'payment_verification_unavailable' =>
        'Razorpay is temporarily unavailable. Please try again.',
      'payment_initialization_in_progress' =>
        'Payment is already being prepared. Please try again in a moment.',
      'booking_total_changed' =>
        'The booking total changed. Reopen the booking and review it again.',
      'invalid_booking_total' =>
        'The booking total is invalid. Contact support before paying.',
      'invalid_payment_signature' || 'payment_details_do_not_match' =>
        'Payment verification failed. No booking was confirmed.',
      'payment_not_captured' =>
        'Payment is not captured yet. Check Bookings in a moment.',
      'booking_not_found' ||
      'payment_attempt_not_found' => 'This payment booking could not be found.',
      'booking_not_awaiting_payment' =>
        'This booking is no longer awaiting payment.',
      _ => 'Payment could not be completed. Please try again.',
    };
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _completeCheckoutError(
      const PaymentException(
        'Payment screen closed.',
        code: 'payment_screen_closed',
        cancelled: true,
      ),
    );
    _razorpay?.clear();
    _razorpay = null;
  }
}

class PaymentException implements Exception {
  const PaymentException(
    this.message, {
    this.code,
    this.cancelled = false,
    this.processing = false,
  });

  final String message;
  final String? code;
  final bool cancelled;
  final bool processing;

  @override
  String toString() => message;
}

class _CheckoutPreparation {
  const _CheckoutPreparation({this.session, this.alreadyPaidOrder})
    : assert((session == null) != (alreadyPaidOrder == null));

  final RazorpayCheckoutSession? session;
  final Order? alreadyPaidOrder;
}

class _CheckoutResponse {
  const _CheckoutResponse({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}
