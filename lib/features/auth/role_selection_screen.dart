import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/role_navigation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/andco_logo.dart';
import '../driver/driver_dashboard.dart';
import '../parent/parent_dashboard.dart';
import '../school_admin/school_admin_dashboard.dart';
import '../super_admin/super_admin_dashboard.dart';
import 'driver/driver_auth_screen.dart';
import 'parent/parent_auth_screen.dart';
import 'school_admin/school_admin_auth_screen.dart';
import 'super_admin/super_admin_auth_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final bool isAfterSignup;
  final User? user;

  const RoleSelectionScreen({
    super.key,
    this.isAfterSignup = false,
    this.user,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  final List<RoleOption> _roles = [
    RoleOption(
      id: AppConstants.roleParent,
      title: 'Parent',
      subtitle: 'Track your child\'s school transport',
      description:
          'Monitor your child\'s bus location, receive real-time updates, and communicate with drivers.',
      icon: Icons.family_restroom,
      color: AppColors.parentColor,
      features: [
        'Real-time bus tracking',
        'Pickup/drop-off notifications',
        'Driver communication',
        'Trip history',
        'Emergency alerts',
      ],
    ),
    RoleOption(
      id: AppConstants.roleDriver,
      title: 'Driver',
      subtitle: 'Manage routes and student pickups',
      description:
          'Navigate optimized routes, manage student attendance, and ensure safe transportation.',
      icon: Icons.drive_eta,
      color: AppColors.driverColor,
      features: [
        'Smart route navigation',
        'Student manifest with photos',
        'Attendance tracking',
        'Emergency SOS system',
        'Daily safety checks',
      ],
    ),
    RoleOption(
      id: AppConstants.roleSchoolAdmin,
      title: 'School Admin',
      subtitle: 'Oversee school transport operations',
      description:
          'Manage students, buses, routes, and monitor overall transport operations.',
      icon: Icons.school,
      color: AppColors.schoolAdminColor,
      features: [
        'Student & bus management',
        'Route planning',
        'Driver oversight',
        'Reports & analytics',
        'Incident monitoring',
      ],
    ),
    RoleOption(
      id: AppConstants.roleSuperAdmin,
      title: 'Super Admin',
      subtitle: 'Manage entire platform',
      description:
          'Full platform control with advanced analytics, user management, and system configuration.',
      icon: Icons.admin_panel_settings,
      color: AppColors.superAdminColor,
      features: [
        'Multi-school management',
        'Platform analytics',
        'User administration',
        'System configuration',
        'Financial oversight',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Role Cards
              Expanded(
                child: _buildRoleCards(),
              ),

              // Continue Button
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          const AndcoLogo(size: 60, showShadow: false)
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            'Choose Your Role',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Select how you\'ll be using ${AppConstants.appName}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildRoleCards() {
    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      itemCount: _roles.length,
      itemBuilder: (context, index) {
        final role = _roles[index];
        final isSelected = _selectedRole == role.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          child: _buildRoleCard(role, isSelected, index),
        );
      },
    );
  }

  Widget _buildRoleCard(RoleOption role, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: isSelected
              ? role.color.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(
            color: isSelected
                ? role.color
                : AppColors.border.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? role.color.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: role.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Icon(
                role.icon,
                color: role.color,
                size: AppConstants.iconLarge,
              ),
            ),

            const SizedBox(width: AppConstants.paddingMedium),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? role.color : AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? role.color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? role.color : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 100).ms, duration: 600.ms)
        .slideX(begin: 0.3);
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              _selectedRole != null && !_isLoading ? _navigateToAuth : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.isAfterSignup ? 'Complete Setup' : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms);
  }

  void _navigateToAuth() async {
    if (_selectedRole == null) return;

    // For Super Admin, check dynamic email restriction
    if (_selectedRole == AppConstants.roleSuperAdmin) {
      final currentUser = widget.user ?? FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // User is already signed in, check if they can access super admin
        final canAccess =
            await RoleNavigationService.canAccessSuperAdmin(currentUser.email);
        if (!canAccess) {
          _showSuperAdminError();
          return;
        }
      }
      // If no user is signed in, allow access to auth screen for signup/signin
    }

    if (widget.isAfterSignup && widget.user != null) {
      // Save role to Firestore and navigate to dashboard
      _saveRoleAndNavigate();
    } else {
      // Navigate to auth screen
      _navigateToAuthScreen();
    }
  }

  void _navigateToAuthScreen() {
    Widget authScreen;
    switch (_selectedRole!) {
      case AppConstants.roleParent:
        authScreen = const ParentAuthScreen();
        break;
      case AppConstants.roleDriver:
        authScreen = const DriverAuthScreen();
        break;
      case AppConstants.roleSchoolAdmin:
        authScreen = const SchoolAdminAuthScreen();
        break;
      case AppConstants.roleSuperAdmin:
        authScreen = const SuperAdminAuthScreen();
        break;
      default:
        authScreen = const ParentAuthScreen();
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => authScreen),
    );
  }

  Future<void> _saveRoleAndNavigate() async {
    if (_selectedRole == null || widget.user == null) return;

    setState(() => _isLoading = true);

    try {
      // Convert role string to UserRole enum
      UserRole userRole;
      switch (_selectedRole!) {
        case AppConstants.roleParent:
          userRole = UserRole.parent;
          break;
        case AppConstants.roleDriver:
          userRole = UserRole.driver;
          break;
        case AppConstants.roleSchoolAdmin:
          userRole = UserRole.schoolAdmin;
          break;
        case AppConstants.roleSuperAdmin:
          userRole = UserRole.superAdmin;
          break;
        default:
          userRole = UserRole.parent;
      }

      // Create user profile
      final userModel = UserModel(
        uid: widget.user!.uid,
        name: widget.user!.displayName ?? 'User',
        email: widget.user!.email ?? '',
        phoneNumber: widget.user!.phoneNumber,
        role: userRole,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        isVerified: widget.user!.emailVerified,
      );

      // Save to Firestore
      await AuthService.instance.createUserProfile(userModel);

      // Navigate to appropriate dashboard
      _navigateToDashboard(userRole);
    } catch (e) {
      _showError('Failed to save user profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard(UserRole role) {
    Widget dashboard;
    switch (role) {
      case UserRole.parent:
        dashboard = const ParentDashboard();
        break;
      case UserRole.driver:
        dashboard = const DriverDashboard();
        break;
      case UserRole.schoolAdmin:
        dashboard = const SchoolAdminDashboard();
        break;
      case UserRole.superAdmin:
        dashboard = const SuperAdminDashboard();
        break;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => dashboard),
      (route) => false,
    );
  }

  void _showSuperAdminError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Restricted'),
        content: const Text(
          'Super Admin access is restricted to authorized personnel only. '
          'Please contact support if you believe this is an error.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class RoleOption {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;

  RoleOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
  });
}
