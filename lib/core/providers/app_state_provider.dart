import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared/models/user_model.dart';
import '../services/firebase_service.dart';
import 'app_initialization_provider.dart';
import 'auth_provider.dart';
import 'onboarding_provider.dart';

/// Provider for overall app state
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});

/// App state model
class AppState {
  final AppPhase phase;
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final OnboardingState onboardingState;
  final AppInitializationState initializationState;

  const AppState({
    this.phase = AppPhase.initializing,
    this.isLoading = false,
    this.error,
    this.user,
    required this.onboardingState,
    required this.initializationState,
  });

  AppState copyWith({
    AppPhase? phase,
    bool? isLoading,
    String? error,
    UserModel? user,
    OnboardingState? onboardingState,
    AppInitializationState? initializationState,
  }) {
    return AppState(
      phase: phase ?? this.phase,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
      onboardingState: onboardingState ?? this.onboardingState,
      initializationState: initializationState ?? this.initializationState,
    );
  }

  /// Check if app is ready for user interaction
  bool get isReady => phase != AppPhase.initializing && !isLoading && error == null;

  /// Check if user is authenticated
  bool get isAuthenticated => user != null;

  /// Check if onboarding is needed
  bool get needsOnboarding => onboardingState.isFirstTime || !onboardingState.hasCompletedOnboarding;

  /// Check if permissions are needed
  bool get needsPermissions => !onboardingState.hasRequestedPermissions;

  /// Get the appropriate route for current state
  String get appropriateRoute {
    if (!initializationState.isInitialized) {
      return '/splash';
    }

    if (isAuthenticated) {
      return _getDashboardRoute(user!.role);
    }

    if (needsOnboarding) {
      return '/onboarding';
    }

    if (needsPermissions) {
      return '/permissions';
    }

    return '/role-selection';
  }

  String _getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return '/parent-dashboard';
      case UserRole.driver:
        return '/driver-dashboard';
      case UserRole.schoolAdmin:
        return '/school-admin-dashboard';
      case UserRole.superAdmin:
        return '/super-admin-dashboard';
    }
  }
}

/// App phases
enum AppPhase {
  initializing,
  onboarding,
  permissions,
  authentication,
  authenticated,
  error,
}

/// App state notifier
class AppStateNotifier extends StateNotifier<AppState> {
  final Ref ref;

  AppStateNotifier(this.ref) : super(AppState(
    onboardingState: const OnboardingState(),
    initializationState: const AppInitializationState(),
  )) {
    _initialize();
  }

  /// Initialize app state monitoring
  void _initialize() {
    // Listen to initialization state changes
    ref.listen<AppInitializationState>(appInitializationProvider, (previous, next) {
      _updateInitializationState(next);
    });

    // Listen to auth state changes
    ref.listen<AsyncValue<UserModel?>>(authControllerProvider, (previous, next) {
      _updateAuthState(next);
    });

    // Listen to onboarding state changes
    ref.listen<OnboardingState>(onboardingStateProvider, (previous, next) {
      _updateOnboardingState(next);
    });

    // Start initialization
    ref.read(appInitializationProvider.notifier).initializeApp();
  }

  /// Update initialization state
  void _updateInitializationState(AppInitializationState initState) {
    state = state.copyWith(
      initializationState: initState,
      isLoading: initState.isInitializing,
      error: initState.hasError ? initState.errorMessage : null,
    );

    if (initState.isInitialized) {
      _determinePhase();
    } else if (initState.hasError) {
      state = state.copyWith(phase: AppPhase.error);
    }
  }

  /// Update auth state
  void _updateAuthState(AsyncValue<UserModel?> authState) {
    authState.when(
      data: (user) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          error: null,
        );
        _determinePhase();
      },
      loading: () {
        state = state.copyWith(isLoading: true);
      },
      error: (error, stack) {
        state = state.copyWith(
          error: error.toString(),
          isLoading: false,
        );
        _determinePhase();
      },
    );
  }

  /// Update onboarding state
  void _updateOnboardingState(OnboardingState onboardingState) {
    state = state.copyWith(onboardingState: onboardingState);
    _determinePhase();
  }

  /// Determine current app phase
  void _determinePhase() {
    if (!state.initializationState.isInitialized) {
      state = state.copyWith(phase: AppPhase.initializing);
      return;
    }

    if (state.error != null) {
      state = state.copyWith(phase: AppPhase.error);
      return;
    }

    if (state.user != null) {
      state = state.copyWith(phase: AppPhase.authenticated);
      return;
    }

    if (state.needsOnboarding) {
      state = state.copyWith(phase: AppPhase.onboarding);
      return;
    }

    if (state.needsPermissions) {
      state = state.copyWith(phase: AppPhase.permissions);
      return;
    }

    state = state.copyWith(phase: AppPhase.authentication);
  }

  /// Handle app errors
  void handleError(String error, {StackTrace? stackTrace}) {
    state = state.copyWith(
      error: error,
      phase: AppPhase.error,
      isLoading: false,
    );

    // Log error to Firebase
    FirebaseService.instance.logError(
      Exception(error),
      stackTrace ?? StackTrace.current,
      reason: 'App state error',
    );
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
    _determinePhase();
  }

  /// Retry initialization
  Future<void> retryInitialization() async {
    state = state.copyWith(
      error: null,
      phase: AppPhase.initializing,
    );
    
    await ref.read(appInitializationProvider.notifier).retryInitialization();
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    await ref.read(onboardingStateProvider.notifier).completeOnboarding();
  }

  /// Mark permissions as requested
  Future<void> markPermissionsRequested() async {
    await ref.read(onboardingStateProvider.notifier).markPermissionsRequested();
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      state = state.copyWith(
        user: null,
        phase: AppPhase.authentication,
      );
    } catch (e) {
      handleError('Failed to sign out: $e');
    }
  }

  /// Reset app state (for testing or user reset)
  Future<void> resetAppState() async {
    try {
      // Reset onboarding state
      await ref.read(onboardingStateProvider.notifier).resetOnboardingState();
      
      // Sign out user
      await signOut();
      
      // Reset to initial state
      state = AppState(
        phase: AppPhase.onboarding,
        onboardingState: const OnboardingState(
          isFirstTime: true,
          hasCompletedOnboarding: false,
          hasRequestedPermissions: false,
        ),
        initializationState: state.initializationState,
      );

      // Log reset event
      await FirebaseService.instance.logEvent('app_state_reset', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      handleError('Failed to reset app state: $e');
    }
  }

  /// Get user-friendly phase description
  String getPhaseDescription() {
    switch (state.phase) {
      case AppPhase.initializing:
        return 'Starting up...';
      case AppPhase.onboarding:
        return 'Welcome to AndCo';
      case AppPhase.permissions:
        return 'Setting up permissions';
      case AppPhase.authentication:
        return 'Ready to sign in';
      case AppPhase.authenticated:
        return 'Welcome back!';
      case AppPhase.error:
        return 'Something went wrong';
    }
  }

  /// Check if specific feature is available
  bool isFeatureAvailable(String feature) {
    if (!state.isReady) return false;
    
    switch (feature) {
      case 'location':
        return state.onboardingState.hasRequestedPermissions;
      case 'notifications':
        return state.onboardingState.hasRequestedPermissions;
      case 'dashboard':
        return state.isAuthenticated;
      default:
        return true;
    }
  }
}
