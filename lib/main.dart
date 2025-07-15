import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/services/ai/ai_service_manager.dart';
import 'core/services/firebase_service.dart';
import 'core/services/integration_service.dart';
import 'core/services/theme_service.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService.instance
      .initialize(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize all external APIs and AI agents
  try {
    await IntegrationService.instance.initializeAllServices(
      isProduction: false, // Set to true for production
    );

    // Initialize AI Service Manager
    final aiManager = AIServiceManager.instance;
    await aiManager.initialize(isProduction: kReleaseMode);

    debugPrint('🎉 All external APIs and AI agents initialized successfully!');
  } catch (e) {
    debugPrint('⚠️ Some services failed to initialize: $e');
    // App can still run with partial functionality
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: AndcoApp(),
    ),
  );
}

class AndcoApp extends ConsumerWidget {
  const AndcoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeServiceProvider);
    final themeService = ref.read(themeServiceProvider.notifier);

    // Get system brightness for theme determination
    final brightness = MediaQuery.platformBrightnessOf(context);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: themeService.getThemeData(Brightness.light),
      darkTheme: themeService.getThemeData(Brightness.dark),
      themeMode: _getThemeMode(themeState.themeMode, brightness),
      home: const SplashScreen(),
    );
  }

  ThemeMode _getThemeMode(
      AppThemeMode appThemeMode, Brightness systemBrightness) {
    switch (appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.custom:
        return systemBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light;
    }
  }
}
