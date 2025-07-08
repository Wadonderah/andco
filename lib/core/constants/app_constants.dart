class AppConstants {
  // App Info
  static const String appName = 'Andco';
  static const String appTagline = 'Smart School Transport';
  static const String appDescription = 'A secure, AI-powered, parent-focused school transport solution';
  
  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 800);
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  static const double iconXXLarge = 64.0;
  
  // User Roles
  static const String roleParent = 'parent';
  static const String roleDriver = 'driver';
  static const String roleSchoolAdmin = 'school_admin';
  static const String roleSuperAdmin = 'super_admin';
  
  // Routes
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String authRoute = '/auth';
  static const String parentDashboardRoute = '/parent-dashboard';
  static const String driverDashboardRoute = '/driver-dashboard';
  static const String schoolAdminDashboardRoute = '/school-admin-dashboard';
  static const String superAdminDashboardRoute = '/super-admin-dashboard';
}
