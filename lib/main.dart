import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/index.dart';
import 'screens/index.dart';
import 'utils/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize easy_localization
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('bn')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MedicalDiagnosticApp(),
    ),
  );
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
      title: 'Medical Diagnostic',
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,

      // Localization support
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Route navigation
      initialRoute: '/language',
      routes: {
        '/language': (context) => const LanguageSelectionScreen(),
        '/auth': (context) => const AuthenticationScreen(),
        '/home': (context) => const HomeScreen(),
        '/upload': (context) => const UploadPrescriptionScreen(),
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
