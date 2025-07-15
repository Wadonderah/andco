import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/andco_logo.dart';
import '../auth/modern_role_selection_screen.dart';
import 'permission_request_screen.dart';
import 'widgets/onboarding_page_widget.dart';
import 'widgets/role_specific_onboarding_widget.dart';

class EnhancedOnboardingScreen extends ConsumerStatefulWidget {
  const EnhancedOnboardingScreen({super.key});

  @override
  ConsumerState<EnhancedOnboardingScreen> createState() =>
      _EnhancedOnboardingScreenState();
}

class _EnhancedOnboardingScreenState
    extends ConsumerState<EnhancedOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentPage = 0;
  bool _showRoleSpecific = false;
  UserRole? _selectedRole;

  // General onboarding pages
  final List<OnboardingPageData> _generalPages = [
    OnboardingPageData(
      title: 'Welcome to AndCo',
      subtitle: 'Safe School Transport',
      description:
          'Your trusted partner for secure, efficient, and smart school transportation management.',
      icon: Icons.waving_hand,
      color: AppColors.primary,
      features: [
        'Real-time GPS tracking',
        'Instant notifications',
        'Secure communication',
        'AI-powered optimization',
      ],
    ),
    OnboardingPageData(
      title: 'Real-Time Safety',
      subtitle: 'Peace of Mind',
      description:
          'Track your child\'s journey with live GPS updates, arrival notifications, and emergency alerts.',
      icon: Icons.shield_outlined,
      color: AppColors.secondary,
      features: [
        'Live location tracking',
        'Pickup & drop-off alerts',
        'Emergency SOS system',
        'Route deviation alerts',
      ],
    ),
    OnboardingPageData(
      title: 'Smart Communication',
      subtitle: 'Stay Connected',
      description:
          'Seamless communication between parents, drivers, and school administrators.',
      icon: Icons.chat_bubble_outline,
      color: AppColors.accent,
      features: [
        'In-app messaging',
        'Push notifications',
        'SMS alerts',
        'Voice announcements',
      ],
    ),
    OnboardingPageData(
      title: 'Choose Your Role',
      subtitle: 'Personalized Experience',
      description:
          'Select your role to get a customized experience designed specifically for your needs.',
      icon: Icons.people_outline,
      color: AppColors.parentColor,
      features: [
        'Parent dashboard',
        'Driver interface',
        'School admin panel',
        'Super admin controls',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surface,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with skip button
              _buildHeader(),

              // Logo
              _buildLogo(),

              // Main content
              Expanded(
                child: _showRoleSpecific && _selectedRole != null
                    ? _buildRoleSpecificContent()
                    : _buildGeneralOnboarding(),
              ),

              // Bottom navigation
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (only show in role-specific view)
          if (_showRoleSpecific)
            IconButton(
              onPressed: _goBackToGeneral,
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
              ),
            )
          else
            const SizedBox(width: 48),

          // Page indicator or role indicator
          if (_showRoleSpecific && _selectedRole != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: _getRoleColor(_selectedRole!).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                border: Border.all(color: _getRoleColor(_selectedRole!)),
              ),
              child: Text(
                _getRoleTitle(_selectedRole!),
                style: TextStyle(
                  color: _getRoleColor(_selectedRole!),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Row(
              children: List.generate(
                _generalPages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
              ),
            ),

          // Skip button
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              'Skip',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.paddingLarge),
      child: AndcoLogo(size: 60, showShadow: false),
    );
  }

  Widget _buildGeneralOnboarding() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: _generalPages.length,
      itemBuilder: (context, index) {
        return OnboardingPageWidget(
          pageData: _generalPages[index],
          isLastPage: index == _generalPages.length - 1,
          onRoleSelected: _showRoleSpecificOnboarding,
        );
      },
    );
  }

  Widget _buildRoleSpecificContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RoleSpecificOnboardingWidget(
        role: _selectedRole!,
        onCompleted: _completeOnboarding,
      ),
    );
  }

  Widget _buildBottomNavigation() {
    if (_showRoleSpecific) {
      return Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _completeOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedRole != null
                  ? _getRoleColor(_selectedRole!)
                  : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              ),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Row(
        children: [
          // Previous button
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusLarge),
                  ),
                ),
                child: const Text('Previous'),
              ),
            )
          else
            const Expanded(child: SizedBox()),

          const SizedBox(width: AppConstants.paddingMedium),

          // Next button
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _currentPage == _generalPages.length - 1 ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                ),
              ),
              child: Text(
                _currentPage == _generalPages.length - 1
                    ? 'Choose Role'
                    : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _generalPages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.shortAnimationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppConstants.shortAnimationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _showRoleSpecificOnboarding(UserRole role) {
    setState(() {
      _selectedRole = role;
      _showRoleSpecific = true;
    });

    _fadeController.forward().then((_) {
      _fadeController.reverse();
    });

    // Save selected role
    ref.read(onboardingStateProvider.notifier).setSelectedRole(role);
  }

  void _goBackToGeneral() {
    setState(() {
      _showRoleSpecific = false;
      _selectedRole = null;
    });
  }

  void _completeOnboarding() async {
    // Mark onboarding as completed
    await ref.read(onboardingStateProvider.notifier).completeOnboarding();

    // Check if permissions should be requested
    final shouldRequestPermissions =
        ref.read(onboardingStateProvider.notifier).shouldRequestPermissions();
    if (shouldRequestPermissions) {
      // Navigate to permission request screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PermissionRequestScreen(),
          ),
        );
      }
    } else {
      // Navigate directly to role selection
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ModernRoleSelectionScreen(),
          ),
        );
      }
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return AppColors.parentColor;
      case UserRole.driver:
        return AppColors.driverColor;
      case UserRole.schoolAdmin:
        return AppColors.schoolAdminColor;
      case UserRole.superAdmin:
        return AppColors.superAdminColor;
    }
  }

  String _getRoleTitle(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.driver:
        return 'Driver';
      case UserRole.schoolAdmin:
        return 'School Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }
}

/// Onboarding page data model
class OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
  });
}
