import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

///import 'supabase_options.dart';
import 'models/index.dart';
import 'screens/index.dart';
import 'utils/index.dart';

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

  runApp(const MedicalDiagnosticApp());
}

class MedicalDiagnosticApp extends StatefulWidget {
  const MedicalDiagnosticApp({super.key});

  @override
  State<MedicalDiagnosticApp> createState() => _MedicalDiagnosticAppState();
}

class _MedicalDiagnosticAppState extends State<MedicalDiagnosticApp> {
  // Global key to navigate without context if needed
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      if (!mounted) return;

      if (event == AuthChangeEvent.signedIn && session != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // Required for the listener navigation
      title: AppStrings.appTitle,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,

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
        '/home': (context) => const MainNavigationScreen(),
        '/upload': (context) => const UploadPrescriptionScreen(),
        '/test-status': (context) => const TestStatusScreen(),
        '/order-details': (context) {
          final order = ModalRoute.of(context)?.settings.arguments as Order?;
          if (order != null) {
            return OrderDetailsScreen(order: order);
          }
          return const MainNavigationScreen();
        },
      },
    );
  }
}
