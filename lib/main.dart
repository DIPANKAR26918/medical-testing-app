import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

///import 'supabase_options.dart';
import 'models/index.dart';
import 'screens/index.dart';
import 'services/index.dart';
import 'utils/index.dart';
import 'widgets/app_mobile_viewport.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://jfimeyukzzorjzlhrtuf.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpmaW1leXVrenpvcmp6bGhydHVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxMTM4OTQsImV4cCI6MjA5NDY4OTg5NH0.3A7zTCxI95Kjd7tW78Z-2ZXMjKzVGO5-nhIUgtL8ygQ',
    // This tells Supabase to use the internal PKCE flow for mobile deep links
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await _clearRetiredRecommendationPreferences();

  var pushNotificationsEnabled = false;
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    pushNotificationsEnabled = true;
  } catch (error) {
    // Android is configured through google-services.json. iOS remains usable
    // until its GoogleService-Info.plist is added by the release team.
    if (kDebugMode) debugPrint('Firebase push is unavailable: $error');
  }

  runApp(Testified(pushNotificationsEnabled: pushNotificationsEnabled));
}

Future<void> _clearRetiredRecommendationPreferences() async {
  const retiredPrefixes = <String>[
    'medical_test_interest_history_v2_',
    'medical_test_view_history_v1_',
  ];

  try {
    final preferences = await SharedPreferences.getInstance();
    final retiredKeys = preferences.getKeys().where(
      (key) => retiredPrefixes.any(key.startsWith),
    );
    await Future.wait(retiredKeys.map(preferences.remove));
  } catch (error) {
    if (kDebugMode) {
      debugPrint('Could not clear retired recommendation data: $error');
    }
  }
}

class Testified extends StatefulWidget {
  const Testified({this.pushNotificationsEnabled = false, super.key});

  final bool pushNotificationsEnabled;

  @override
  State<Testified> createState() => _TestifiedState();
}

class _TestifiedState extends State<Testified> {
  // Global key to navigate without context if needed
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final AuthService _authService = AuthService();
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _resolvingAuthRedirect = false;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = _authService.authStateChanges.listen((data) {
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.signedIn &&
          session != null &&
          _isGoogleAuthUser(session.user)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _routeAfterOAuthSignIn();
        });
      }
    });

    if (widget.pushNotificationsEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          PushNotificationService.instance.initialize(
            navigatorKey: _navigatorKey,
            messengerKey: _messengerKey,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    if (widget.pushNotificationsEnabled) {
      unawaited(PushNotificationService.instance.dispose());
    }
    super.dispose();
  }

  bool _isGoogleAuthUser(User user) {
    final provider = user.appMetadata['provider']?.toString();
    if (provider == 'google') return true;

    final providers = user.appMetadata['providers'];
    if (providers is Iterable) {
      return providers
          .map((provider) => provider.toString())
          .contains('google');
    }

    return providers?.toString().contains('google') ?? false;
  }

  Future<void> _routeAfterOAuthSignIn() async {
    if (_resolvingAuthRedirect) return;

    _resolvingAuthRedirect = true;

    try {
      final resolution = await _authService.resolveCurrentAuthProfile();
      if (!mounted) return;

      _openResolvedProfile(resolution);
    } catch (e) {
      if (!mounted) return;

      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/auth',
        (route) => false,
      );

      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      _resolvingAuthRedirect = false;
    }
  }

  void _openResolvedProfile(AuthProfileResolution resolution) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    if (resolution.needsProfileCompletion) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            phoneNumber: resolution.phoneNumber,
            email: resolution.email,
            initialName: resolution.displayName,
          ),
        ),
        (route) => false,
      );
    } else {
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // Required for the listener navigation
      scaffoldMessengerKey: _messengerKey,
      title: AppStrings.appTitle,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior(),
      navigatorObservers: [appRouteObserver],
      builder: (context, child) {
        return AppMobileViewport(child: child ?? const SizedBox.shrink());
      },

      // Route navigation
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const WelcomeScreen(),
        '/auth': (context) => const AuthenticationScreen(),
        '/otp': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String;
          return OtpScreen(phoneNumber: phoneNumber);
        },
        '/complete-profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          if (args is AuthProfileResolution) {
            return CompleteProfileScreen(
              phoneNumber: args.phoneNumber,
              email: args.email,
              initialName: args.displayName,
            );
          }

          if (args is Map<String, dynamic>) {
            return CompleteProfileScreen(
              phoneNumber: args['phoneNumber'] as String?,
              email: args['email'] as String?,
              initialName: args['initialName'] as String?,
            );
          }

          return const CompleteProfileScreen();
        },
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          var initialIndex = 0;

          if (args is int) {
            initialIndex = args;
          } else if (args is Map<String, dynamic>) {
            initialIndex = args['tabIndex'] as int? ?? 0;
          }

          return MainNavigationScreen(initialIndex: initialIndex);
        },
        '/search': (context) => const SearchScreen(),
        '/all-categories': (context) =>
            const FrictionlessTestBookingScreen(),
        '/upload': (context) => const UploadPrescriptionScreen(),
        '/test-status': (context) => const TestStatusScreen(),
        '/notification-destination': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final target = args is PushNotificationTarget
              ? args
              : PushNotificationTarget.fromData(
                  args is Map
                      ? Map<String, dynamic>.from(args)
                      : const <String, dynamic>{},
                );
          return NotificationDestinationScreen(target: target);
        },
        '/order-details': (context) {
          final order = ModalRoute.of(context)?.settings.arguments as Order?;
          if (order != null) {
            if (shouldOpenPrescriptionReview(order.status)) {
              return PrescriptionReviewScreen(order: order);
            }
            return OrderDetailsScreen(order: order);
          }
          return const MainNavigationScreen();
        },
      },
    );
  }
}
