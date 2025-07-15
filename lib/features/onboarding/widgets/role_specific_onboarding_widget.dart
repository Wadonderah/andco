import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_model.dart';

class RoleSpecificOnboardingWidget extends StatefulWidget {
  final UserRole role;
  final VoidCallback onCompleted;

  const RoleSpecificOnboardingWidget({
    super.key,
    required this.role,
    required this.onCompleted,
  });

  @override
  State<RoleSpecificOnboardingWidget> createState() => _RoleSpecificOnboardingWidgetState();
}

class _RoleSpecificOnboardingWidgetState extends State<RoleSpecificOnboardingWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentPage = 0;
  late List<RoleFeature> _features;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _features = _getRoleFeatures(widget.role);
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Feature pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _features.length,
              itemBuilder: (context, index) {
                return _buildFeaturePage(_features[index]);
              },
            ),
          ),
          
          // Page indicators
          _buildPageIndicators(),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.paddingMedium,
            ),
            decoration: BoxDecoration(
              color: _getRoleColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: _getRoleColor()),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(),
                  color: _getRoleColor(),
                  size: 24,
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Text(
                  '${_getRoleTitle()} Features',
                  style: TextStyle(
                    color: _getRoleColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Discover what makes ${_getRoleTitle()} experience special',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePage(RoleFeature feature) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          // Feature icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _getRoleColor().withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getRoleColor().withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              feature.icon,
              size: 50,
              color: _getRoleColor(),
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Feature title
          Text(
            feature.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppConstants.paddingMedium),
          
          // Feature description
          Text(
            feature.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Feature benefits
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Benefits:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  ...feature.benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: _getRoleColor(),
                          size: 20,
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                        Expanded(
                          child: Text(
                            benefit,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _features.length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == _currentPage ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == _currentPage ? _getRoleColor() : AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
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
                  side: BorderSide(color: _getRoleColor()),
                  padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(color: _getRoleColor()),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          
          const SizedBox(width: AppConstants.paddingMedium),
          
          // Next/Complete button
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == _features.length - 1 ? widget.onCompleted : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getRoleColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                ),
              ),
              child: Text(
                _currentPage == _features.length - 1 ? 'Get Started' : 'Next',
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
    if (_currentPage < _features.length - 1) {
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

  Color _getRoleColor() {
    switch (widget.role) {
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

  IconData _getRoleIcon() {
    switch (widget.role) {
      case UserRole.parent:
        return Icons.family_restroom;
      case UserRole.driver:
        return Icons.directions_bus;
      case UserRole.schoolAdmin:
        return Icons.school;
      case UserRole.superAdmin:
        return Icons.admin_panel_settings;
    }
  }

  String _getRoleTitle() {
    switch (widget.role) {
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

  List<RoleFeature> _getRoleFeatures(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return [
          RoleFeature(
            title: 'Real-Time Tracking',
            description: 'Track your child\'s bus location in real-time with GPS precision.',
            icon: Icons.location_on,
            benefits: [
              'Live GPS tracking of school bus',
              'Estimated arrival times',
              'Route progress updates',
              'Geofence notifications',
            ],
          ),
          RoleFeature(
            title: 'Smart Notifications',
            description: 'Stay informed with intelligent alerts and updates.',
            icon: Icons.notifications_active,
            benefits: [
              'Pickup and drop-off alerts',
              'Delay notifications',
              'Emergency alerts',
              'Schedule changes',
            ],
          ),
          RoleFeature(
            title: 'Child Safety',
            description: 'Comprehensive safety features for peace of mind.',
            icon: Icons.shield,
            benefits: [
              'SOS emergency button',
              'Driver verification',
              'Safe zone monitoring',
              'Attendance tracking',
            ],
          ),
        ];
      case UserRole.driver:
        return [
          RoleFeature(
            title: 'Smart Routes',
            description: 'AI-optimized routes with real-time traffic updates.',
            icon: Icons.route,
            benefits: [
              'Traffic-aware routing',
              'Fuel-efficient paths',
              'Dynamic rerouting',
              'Voice navigation',
            ],
          ),
          RoleFeature(
            title: 'Student Management',
            description: 'Easy student check-in/out with photo verification.',
            icon: Icons.people,
            benefits: [
              'Photo-based student ID',
              'Swipe check-in/out',
              'Attendance tracking',
              'Parent notifications',
            ],
          ),
          RoleFeature(
            title: 'Safety Tools',
            description: 'Comprehensive safety and emergency features.',
            icon: Icons.security,
            benefits: [
              'Emergency SOS system',
              'Vehicle safety checks',
              'Incident reporting',
              'Offline support',
            ],
          ),
        ];
      case UserRole.schoolAdmin:
        return [
          RoleFeature(
            title: 'Fleet Management',
            description: 'Complete oversight of school transportation fleet.',
            icon: Icons.directions_bus,
            benefits: [
              'Bus and driver management',
              'Route optimization',
              'Performance analytics',
              'Maintenance scheduling',
            ],
          ),
          RoleFeature(
            title: 'Student Administration',
            description: 'Comprehensive student and parent management.',
            icon: Icons.school,
            benefits: [
              'Student profile management',
              'Parent communication',
              'Attendance monitoring',
              'Route assignments',
            ],
          ),
          RoleFeature(
            title: 'Reports & Analytics',
            description: 'Detailed insights and reporting capabilities.',
            icon: Icons.analytics,
            benefits: [
              'Usage analytics',
              'Performance reports',
              'Financial tracking',
              'Data export options',
            ],
          ),
        ];
      case UserRole.superAdmin:
        return [
          RoleFeature(
            title: 'Platform Control',
            description: 'Ultimate control over the entire platform.',
            icon: Icons.admin_panel_settings,
            benefits: [
              'School approval system',
              'User management',
              'System configuration',
              'Platform monitoring',
            ],
          ),
          RoleFeature(
            title: 'Financial Oversight',
            description: 'Complete financial monitoring and control.',
            icon: Icons.account_balance,
            benefits: [
              'Revenue analytics',
              'Payment processing',
              'Financial reporting',
              'Dispute resolution',
            ],
          ),
          RoleFeature(
            title: 'System Analytics',
            description: 'Advanced analytics and business intelligence.',
            icon: Icons.insights,
            benefits: [
              'Platform-wide analytics',
              'Performance monitoring',
              'User behavior insights',
              'Growth metrics',
            ],
          ),
        ];
    }
  }
}

class RoleFeature {
  final String title;
  final String description;
  final IconData icon;
  final List<String> benefits;

  const RoleFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.benefits,
  });
}
