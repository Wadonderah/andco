import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/hive_service.dart';
import '../services/offline_service.dart';
import 'auth_provider.dart';
import 'onboarding_provider.dart';

/// Provider for app initialization state
final appInitializationProvider =
    StateNotifierProvider<AppInitializationNotifier, AppInitializationState>(
        (ref) {
  return AppInitializationNotifier(ref);
});

/// App initialization state model
class AppInitializationState {
  final bool isInitializing;
  final bool isInitialized;
  final bool hasError;
  final String? errorMessage;
  final double progress;
  final String currentStep;
  final AppRoute nextRoute;

  const AppInitializationState({
    this.isInitializing = false,
    this.isInitialized = false,
    this.hasError = false,
    this.errorMessage,
    this.progress = 0.0,
    this.currentStep = 'Starting...',
    this.nextRoute = AppRoute.splash,
  });

  AppInitializationState copyWith({
    bool? isInitializing,
    bool? isInitialized,
    bool? hasError,
    String? errorMessage,
    double? progress,
    String? currentStep,
    AppRoute? nextRoute,
  }) {
    return AppInitializationState(
      isInitializing: isInitializing ?? this.isInitializing,
      isInitialized: isInitialized ?? this.isInitialized,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      nextRoute: nextRoute ?? this.nextRoute,
    );
  }
}

/// App routes enum
enum AppRoute {
  splash,
  onboarding,
  roleSelection,
  authentication,
  parentDashboard,
  driverDashboard,
  schoolAdminDashboard,
  superAdminDashboard,
}

/// App initialization notifier
class AppInitializationNotifier extends StateNotifier<AppInitializationState> {
  final Ref ref;

  AppInitializationNotifier(this.ref) : super(const AppInitializationState());

  /// Initialize the app
  Future<void> initializeApp() async {
    state = state.copyWith(
      isInitializing: true,
      hasError: false,
      errorMessage: null,
      progress: 0.0,
      currentStep: 'Initializing Firebase...',
    );

    try {
      // Step 1: Initialize Firebase (20%)
      await _initializeFirebase();
      state = state.copyWith(
          progress: 0.2, currentStep: 'Setting up local storage...');

      // Step 2: Initialize Hive (40%)
      await _initializeHive();
      state = state.copyWith(
          progress: 0.4, currentStep: 'Loading user preferences...');

      // Step 3: Load onboarding state (60%)
      await _loadOnboardingState();
      state = state.copyWith(
          progress: 0.6, currentStep: 'Checking authentication...');

      // Step 4: Check authentication state (80%)
      await _checkAuthenticationState();
      state = state.copyWith(
          progress: 0.8, currentStep: 'Initializing services...');

      // Step 5: Initialize other services (100%)
      await _initializeServices();
      state = state.copyWith(progress: 1.0, currentStep: 'Ready!');

      // Determine next route
      final nextRoute = await _determineNextRoute();

      state = state.copyWith(
        isInitializing: false,
        isInitialized: true,
        nextRoute: nextRoute,
        currentStep: 'Initialization complete',
      );

      // Log successful initialization
      await FirebaseService.instance.logEvent('app_initialization_success', {
        'next_route': nextRoute.toString(),
        'initialization_time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        hasError: true,
        errorMessage: e.toString(),
        currentStep: 'Initialization failed',
      );

      // Log initialization error
      await FirebaseService.instance.logEvent('app_initialization_error', {
        'error': e.toString(),
        'step': state.currentStep,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Initialize Firebase
  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      await FirebaseService.instance.initialize();
    } catch (e) {
      throw Exception('Firebase initialization failed: $e');
    }
  }

  /// Initialize Hive local storage
  Future<void> _initializeHive() async {
    try {
      await HiveService.instance.initialize();
    } catch (e) {
      throw Exception('Hive initialization failed: $e');
    }
  }

  /// Load onboarding state
  Future<void> _loadOnboardingState() async {
    try {
      // The onboarding provider will automatically load its state
      await Future.delayed(
          const Duration(milliseconds: 500)); // Allow provider to load
    } catch (e) {
      throw Exception('Onboarding state loading failed: $e');
    }
  }

  /// Check authentication state
  Future<void> _checkAuthenticationState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is logged in, the AuthController will automatically load their profile
        // through its _init() method when auth state changes are detected
        await Future.delayed(
            const Duration(milliseconds: 100)); // Allow auth state to propagate
      }
    } catch (e) {
      // Non-critical error, continue initialization
      print('Authentication check warning: $e');
    }
  }

  /// Initialize other services
  Future<void> _initializeServices() async {
    try {
      // Initialize offline service
      await OfflineService().initialize();

      // Add other service initializations here
      await Future.delayed(
          const Duration(milliseconds: 300)); // Simulate service initialization
    } catch (e) {
      throw Exception('Services initialization failed: $e');
    }
  }

  /// Determine the next route based on app state
  Future<AppRoute> _determineNextRoute() async {
    try {
      final authState = ref.read(authControllerProvider);
      final onboardingState = ref.read(onboardingStateProvider);

      // Check if user is authenticated
      return await authState.when(
        data: (user) async {
          if (user != null) {
            // User is authenticated, go to appropriate dashboard
            switch (user.role) {
              case UserRole.parent:
                return AppRoute.parentDashboard;
              case UserRole.driver:
                return AppRoute.driverDashboard;
              case UserRole.schoolAdmin:
                return AppRoute.schoolAdminDashboard;
              case UserRole.superAdmin:
                return AppRoute.superAdminDashboard;
            }
          } else {
            // User not authenticated
            if (onboardingState.isFirstTime ||
                !onboardingState.hasCompletedOnboarding) {
              return AppRoute.onboarding;
            } else {
              return AppRoute.roleSelection;
            }
          }
        },
        loading: () async => AppRoute.authentication,
        error: (error, stack) async {
          // Authentication error, show role selection
          if (onboardingState.isFirstTime ||
              !onboardingState.hasCompletedOnboarding) {
            return AppRoute.onboarding;
          } else {
            return AppRoute.roleSelection;
          }
        },
      );
    } catch (e) {
      // Fallback to onboarding on error
      return AppRoute.onboarding;
    }
  }

  /// Retry initialization
  Future<void> retryInitialization() async {
    await initializeApp();
  }

  /// Get route name for navigation
  String getRouteName(AppRoute route) {
    switch (route) {
      case AppRoute.splash:
        return '/splash';
      case AppRoute.onboarding:
        return '/onboarding';
      case AppRoute.roleSelection:
        return '/role-selection';
      case AppRoute.authentication:
        return '/auth';
      case AppRoute.parentDashboard:
        return '/parent-dashboard';
      case AppRoute.driverDashboard:
        return '/driver-dashboard';
      case AppRoute.schoolAdminDashboard:
        return '/school-admin-dashboard';
      case AppRoute.superAdminDashboard:
        return '/super-admin-dashboard';
    }
  }
}
