import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String testifiedNotificationChannelId = 'testified_updates';

/// Firebase invokes this entry point in a background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

enum PushNotificationDestination {
  home,
  bookings,
  reports,
  orderDetails,
  prescriptionReview,
  testDetails,
}

/// A small, allow-listed navigation contract for notification payloads.
///
/// The server sends only opaque record IDs and a destination name. The app
/// resolves those IDs through the authenticated Supabase session before
/// showing any order or medical-test information.
class PushNotificationTarget {
  const PushNotificationTarget({
    required this.destination,
    this.orderId,
    this.medicalTestId,
  });

  final PushNotificationDestination destination;
  final String? orderId;
  final String? medicalTestId;

  bool get needsAuthenticatedLookup =>
      destination == PushNotificationDestination.orderDetails ||
      destination == PushNotificationDestination.prescriptionReview ||
      destination == PushNotificationDestination.testDetails;

  int get homeTabIndex => switch (destination) {
    PushNotificationDestination.reports => 2,
    PushNotificationDestination.bookings => 1,
    _ => 0,
  };

  factory PushNotificationTarget.fromData(Map<String, dynamic> data) {
    final destination = _normalize(data['destination']);
    final status = _normalize(data['status']);
    final orderId = _validOrderId(data['order_id']);
    final medicalTestId = _validUuid(
      data['medical_test_id'] ?? data['test_id'],
    );

    if (_testDestinations.contains(destination)) {
      return medicalTestId == null
          ? const PushNotificationTarget(
              destination: PushNotificationDestination.home,
            )
          : PushNotificationTarget(
              destination: PushNotificationDestination.testDetails,
              medicalTestId: medicalTestId,
            );
    }

    if (_reviewDestinations.contains(destination)) {
      return orderId == null
          ? const PushNotificationTarget(
              destination: PushNotificationDestination.bookings,
            )
          : PushNotificationTarget(
              destination: PushNotificationDestination.prescriptionReview,
              orderId: orderId,
            );
    }

    if (_orderDestinations.contains(destination)) {
      return orderId == null
          ? const PushNotificationTarget(
              destination: PushNotificationDestination.bookings,
            )
          : PushNotificationTarget(
              destination: PushNotificationDestination.orderDetails,
              orderId: orderId,
            );
    }

    if (_reportDestinations.contains(destination)) {
      return const PushNotificationTarget(
        destination: PushNotificationDestination.reports,
      );
    }

    if (_bookingDestinations.contains(destination)) {
      return const PushNotificationTarget(
        destination: PushNotificationDestination.bookings,
      );
    }

    if (destination == 'home') {
      return const PushNotificationTarget(
        destination: PushNotificationDestination.home,
      );
    }

    if (medicalTestId != null) {
      return PushNotificationTarget(
        destination: PushNotificationDestination.testDetails,
        medicalTestId: medicalTestId,
      );
    }

    if (orderId != null) {
      final reviewReady = _reviewStatuses.contains(status);
      return PushNotificationTarget(
        destination: reviewReady
            ? PushNotificationDestination.prescriptionReview
            : PushNotificationDestination.orderDetails,
        orderId: orderId,
      );
    }

    if (_reportStatuses.contains(status) || _legacyTabIndex(data) == 2) {
      return const PushNotificationTarget(
        destination: PushNotificationDestination.reports,
      );
    }

    if (_legacyTabIndex(data) == 1) {
      return const PushNotificationTarget(
        destination: PushNotificationDestination.bookings,
      );
    }

    return const PushNotificationTarget(
      destination: PushNotificationDestination.home,
    );
  }

  static const Set<String> _testDestinations = {
    'test_detail',
    'test_details',
    'medical_test',
  };
  static const Set<String> _reviewDestinations = {
    'prescription_review',
    'review_tests',
    'tests_ready',
  };
  static const Set<String> _orderDestinations = {
    'order_details',
    'booking_details',
  };
  static const Set<String> _reportDestinations = {
    'report',
    'reports',
    'report_details',
  };
  static const Set<String> _bookingDestinations = {
    'booking',
    'bookings',
    'test_status',
  };
  static const Set<String> _reviewStatuses = {
    'awaiting_user_approval',
    'test_list_prepared',
    'tests_prepared',
  };
  static const Set<String> _reportStatuses = {
    'completed',
    'report_ready',
    'reports_ready',
  };

  static String _normalize(Object? value) {
    return value?.toString().trim().toLowerCase().replaceAll(
          RegExp(r'[-\s]+'),
          '_',
        ) ??
        '';
  }

  static String? _validOrderId(Object? value) {
    final text = value?.toString().trim() ?? '';
    final parsed = int.tryParse(text);
    return parsed != null && parsed > 0 ? text : null;
  }

  static String? _validUuid(Object? value) {
    final text = value?.toString().trim() ?? '';
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-'
      r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuid.hasMatch(text) ? text : null;
  }

  static int? _legacyTabIndex(Map<String, dynamic> data) {
    return int.tryParse(
      data['tab_index']?.toString() ?? data['tabIndex']?.toString() ?? '',
    );
  }
}

/// Owns notification permission, FCM token lifecycle and notification taps.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        testifiedNotificationChannelId,
        'Testified updates',
        description: 'Booking, collection and report updates from Testified.',
        importance: Importance.high,
      );

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  Map<String, dynamic>? _pendingNavigationData;
  String? _currentToken;
  bool _initialized = false;
  bool _permissionRequested = false;
  bool _permissionGranted = false;

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    _navigatorKey = navigatorKey;
    _messengerKey = messengerKey;
    if (_initialized) {
      _flushPendingNavigation();
      return;
    }
    _initialized = true;
    _messaging = FirebaseMessaging.instance;
    final messaging = _messaging!;

    await _initializeLocalNotifications();

    try {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error) {
      _log('Could not configure foreground presentation', error);
    }

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => openNotificationData(message.data),
    );
    _tokenSubscription = messaging.onTokenRefresh.listen(_handleTokenRefresh);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      authState,
    ) {
      if (authState.session != null) {
        unawaited(_enableForAuthenticatedUser());
        _flushPendingNavigation();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        _currentToken = null;
      }
    });

    await _captureLaunchNotification();

    if (Supabase.instance.client.auth.currentUser != null) {
      await _enableForAuthenticatedUser();
      _flushPendingNavigation();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    try {
      await _localNotifications.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          final data = _decodePayload(response.payload);
          if (data != null) openNotificationData(data);
        },
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    } catch (error) {
      _log('Could not initialize local notifications', error);
    }
  }

  Future<void> _captureLaunchNotification() async {
    final messaging = _messaging;
    if (messaging == null) return;

    try {
      final remoteMessage = await messaging.getInitialMessage();
      if (remoteMessage != null) {
        _pendingNavigationData = remoteMessage.data;
      }

      final localLaunch = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (localLaunch?.didNotificationLaunchApp ?? false) {
        final data = _decodePayload(localLaunch?.notificationResponse?.payload);
        if (data != null) _pendingNavigationData = data;
      }
    } catch (error) {
      _log('Could not inspect the launch notification', error);
    }
  }

  Future<void> _enableForAuthenticatedUser() async {
    final messaging = _messaging;
    if (messaging == null) return;
    if (Supabase.instance.client.auth.currentUser == null) return;

    if (!_permissionRequested) {
      _permissionRequested = true;
      try {
        final settings = await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        _permissionGranted =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
        if (!_permissionGranted) {
          _messengerKey?.currentState?.showSnackBar(
            const SnackBar(
              content: Text(
                'Push notifications are off. Enable them in phone settings to receive booking and report updates.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (error) {
        _log('Could not request notification permission', error);
      }
    }

    if (!_permissionGranted) return;
    await _registerCurrentDevice();
  }

  Future<void> _registerCurrentDevice() async {
    final messaging = _messaging;
    if (messaging == null) return;

    try {
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _setDeviceRegistration(token: token, enabled: true);
      _currentToken = token;
    } catch (error) {
      _log('Could not register this device for push notifications', error);
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    if (!_permissionGranted || token.isEmpty) return;

    try {
      final previousToken = _currentToken;
      if (previousToken != null && previousToken != token) {
        await _setDeviceRegistration(token: previousToken, enabled: false);
      }

      await _setDeviceRegistration(token: token, enabled: true);
      _currentToken = token;
    } catch (error) {
      _log('Could not refresh the push token', error);
    }
  }

  Future<void> _setDeviceRegistration({
    required String token,
    required bool enabled,
  }) async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final platform = _platformName;
    if (session == null || platform == null) return;

    final response = await supabase.functions.invoke(
      'register-push-device',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {'token': token, 'platform': platform, 'enabled': enabled},
    );

    if (response.status < 200 || response.status >= 300) {
      throw StateError('Device registration returned ${response.status}.');
    }
  }

  Future<void> deactivateCurrentDevice() async {
    final messaging = _messaging;
    if (!_initialized || messaging == null) return;

    try {
      final token = _currentToken ?? await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _setDeviceRegistration(token: token, enabled: false);
      _currentToken = null;
    } catch (error) {
      // A failed cleanup must never trap a user in their account.
      _log('Could not deactivate the push token during sign out', error);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    try {
      await _localNotifications.show(
        id:
            (message.messageId ?? message.sentTime?.toIso8601String() ?? body)
                .hashCode &
            0x7fffffff,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            testifiedNotificationChannelId,
            'Testified updates',
            channelDescription:
                'Booking, collection and report updates from Testified.',
            icon: 'ic_notification',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF2563EB),
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (error) {
      _log('Could not display a foreground notification', error);
    }
  }

  void openNotificationData(Map<String, dynamic> data) {
    final navigator = _navigatorKey?.currentState;
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    if (navigator == null || !isAuthenticated) {
      _pendingNavigationData = data;
      return;
    }

    final target = PushNotificationTarget.fromData(data);
    if (target.needsAuthenticatedLookup) {
      navigator.pushNamed('/notification-destination', arguments: target);
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
      arguments: {'tabIndex': target.homeTabIndex},
    );
  }

  void _flushPendingNavigation() {
    final data = _pendingNavigationData;
    if (data == null) return;

    _pendingNavigationData = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openNotificationData(data);
    });
  }

  Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  String? get _platformName {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _authSubscription?.cancel();
    _foregroundSubscription = null;
    _openedSubscription = null;
    _tokenSubscription = null;
    _authSubscription = null;
    _navigatorKey = null;
    _messengerKey = null;
    _pendingNavigationData = null;
    _currentToken = null;
    _messaging = null;
    _initialized = false;
    _permissionRequested = false;
    _permissionGranted = false;
  }

  void _log(String message, Object error) {
    if (kDebugMode) debugPrint('$message: $error');
  }
}
