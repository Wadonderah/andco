import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/modern_role_selection_screen.dart';
import '../../features/driver/driver_dashboard.dart';
import '../../features/onboarding/enhanced_onboarding_screen.dart';
import '../../features/onboarding/enhanced_splash_screen.dart';
import '../../features/onboarding/permission_request_screen.dart';
import '../../features/parent/parent_dashboard.dart';
import '../../features/school_admin/school_admin_dashboard.dart';
import '../../features/super_admin/enhanced_super_admin_dashboard.dart';
import '../../shared/models/user_model.dart';
import '../providers/app_initialization_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

/// Provider for the app router
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      return _handleRedirect(ref, context, state);
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const EnhancedSplashScreen(),
      ),

      // Onboarding flow
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const EnhancedOnboardingScreen(),
      ),

      // Permission request
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => const PermissionRequestScreen(),
      ),

      // Role selection
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const ModernRoleSelectionScreen(),
      ),

      // Parent dashboard
      GoRoute(
        path: '/parent-dashboard',
        name: 'parent-dashboard',
        builder: (context, state) => const ParentDashboard(),
      ),

      // Driver dashboard
      GoRoute(
        path: '/driver-dashboard',
        name: 'driver-dashboard',
        builder: (context, state) => const DriverDashboard(),
      ),

      // School admin dashboard
      GoRoute(
        path: '/school-admin-dashboard',
        name: 'school-admin-dashboard',
        builder: (context, state) => const SchoolAdminDashboard(),
      ),

      // Super admin dashboard
      GoRoute(
        path: '/super-admin-dashboard',
        name: 'super-admin-dashboard',
        builder: (context, state) => const EnhancedSuperAdminDashboard(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Handle route redirects based on app state
String? _handleRedirect(Ref ref, BuildContext context, GoRouterState state) {
  final currentLocation = state.uri.toString();

  // Don't redirect if we're already on splash screen during initialization
  if (currentLocation == '/splash') {
    return null;
  }

  // Check app initialization state
  final initState = ref.read(appInitializationProvider);
  if (!initState.isInitialized && !initState.hasError) {
    return '/splash';
  }

  // If initialization failed, stay on splash for retry
  if (initState.hasError) {
    return '/splash';
  }

  // App is initialized, check user state
  final authState = ref.read(authControllerProvider);
  final onboardingState = ref.read(onboardingStateProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        // User is authenticated, redirect to appropriate dashboard
        return _getAuthenticatedUserRoute(user, currentLocation);
      } else {
        // User not authenticated, check onboarding state
        return _getUnauthenticatedUserRoute(onboardingState, currentLocation);
      }
    },
    loading: () {
      // Still loading auth state, stay on current route or go to splash
      return currentLocation == '/splash' ? null : '/splash';
    },
    error: (error, stack) {
      // Auth error, check onboarding state
      return _getUnauthenticatedUserRoute(onboardingState, currentLocation);
    },
  );
}

/// Get route for authenticated user
String? _getAuthenticatedUserRoute(UserModel user, String currentLocation) {
  final expectedRoute = _getDashboardRoute(user.role);

  // If user is on the correct dashboard, don't redirect
  if (currentLocation == expectedRoute) {
    return null;
  }

  // If user is on splash, onboarding, permissions, or role selection, redirect to dashboard
  if (currentLocation == '/splash' ||
      currentLocation == '/onboarding' ||
      currentLocation == '/permissions' ||
      currentLocation == '/role-selection') {
    return expectedRoute;
  }

  // Allow access to other dashboards (for testing or admin purposes)
  return null;
}

/// Get route for unauthenticated user
String? _getUnauthenticatedUserRoute(
    OnboardingState onboardingState, String currentLocation) {
  // Check if user should see onboarding
  if (onboardingState.isFirstTime || !onboardingState.hasCompletedOnboarding) {
    if (currentLocation != '/onboarding') {
      return '/onboarding';
    }
    return null;
  }

  // Check if user should see permissions request
  if (!onboardingState.hasRequestedPermissions) {
    if (currentLocation != '/permissions') {
      return '/permissions';
    }
    return null;
  }

  // User has completed onboarding and permissions, show role selection
  if (currentLocation != '/role-selection') {
    return '/role-selection';
  }

  return null;
}

/// Get dashboard route for user role
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

/// Navigation helper methods
extension AppRouterExtension on GoRouter {
  /// Navigate to splash screen
  void goToSplash() => go('/splash');

  /// Navigate to onboarding
  void goToOnboarding() => go('/onboarding');

  /// Navigate to permissions
  void goToPermissions() => go('/permissions');

  /// Navigate to role selection
  void goToRoleSelection() => go('/role-selection');

  /// Navigate to appropriate dashboard based on user role
  void goToDashboard(UserRole role) {
    go(_getDashboardRoute(role));
  }

  /// Navigate to parent dashboard
  void goToParentDashboard() => go('/parent-dashboard');

  /// Navigate to driver dashboard
  void goToDriverDashboard() => go('/driver-dashboard');

  /// Navigate to school admin dashboard
  void goToSchoolAdminDashboard() => go('/school-admin-dashboard');

  /// Navigate to super admin dashboard
  void goToSuperAdminDashboard() => go('/super-admin-dashboard');
}

/// Router state provider for listening to route changes
final routerStateProvider = Provider<GoRouterState?>((ref) {
  // This would need to be implemented with a proper state notifier
  // For now, return null as a placeholder
  return null;
});

/// Current route provider
final currentRouteProvider = Provider<String>((ref) {
  final router = ref.watch(appRouterProvider);
  return router.routerDelegate.currentConfiguration.uri.toString();
});

/// Navigation service for programmatic navigation
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  static NavigationService get instance => _instance;
  NavigationService._internal();

  GoRouter? _router;

  void setRouter(GoRouter router) {
    _router = router;
  }

  void goToSplash() => _router?.goToSplash();
  void goToOnboarding() => _router?.goToOnboarding();
  void goToPermissions() => _router?.goToPermissions();
  void goToRoleSelection() => _router?.goToRoleSelection();
  void goToDashboard(UserRole role) => _router?.goToDashboard(role);
  void goToParentDashboard() => _router?.goToParentDashboard();
  void goToDriverDashboard() => _router?.goToDriverDashboard();
  void goToSchoolAdminDashboard() => _router?.goToSchoolAdminDashboard();
  void goToSuperAdminDashboard() => _router?.goToSuperAdminDashboard();
}
