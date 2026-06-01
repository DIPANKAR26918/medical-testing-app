import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_options.dart';
import 'models/index.dart';
import 'screens/index.dart';
import 'utils/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MedicalDiagnosticApp());
}

class MedicalDiagnosticApp extends StatefulWidget {
  const MedicalDiagnosticApp({super.key});

  @override
  State<MedicalDiagnosticApp> createState() => _MedicalDiagnosticAppState();
}

class _MedicalDiagnosticAppState extends State<MedicalDiagnosticApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/home': (context) => const HomeScreen(),
        '/upload': (context) => const UploadPrescriptionScreen(),
        '/test-status': (context) => const TestStatusScreen(),
        '/order-details': (context) {
          final order = ModalRoute.of(context)?.settings.arguments as Order?;
          if (order != null) {
            return OrderDetailsScreen(order: order);
          }
          return const HomeScreen();
        },
      },
    );
  }
}
