import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../enhanced_onboarding_screen.dart';

class OnboardingPageWidget extends StatefulWidget {
  final OnboardingPageData pageData;
  final bool isLastPage;
  final Function(UserRole)? onRoleSelected;

  const OnboardingPageWidget({
    super.key,
    required this.pageData,
    this.isLastPage = false,
    this.onRoleSelected,
  });

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  void _startAnimations() {
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          // Icon section
          Expanded(
            flex: 2,
            child: _buildIconSection(),
          ),
          
          // Content section
          Expanded(
            flex: 3,
            child: _buildContentSection(),
          ),
          
          // Role selection (only on last page)
          if (widget.isLastPage)
            Expanded(
              flex: 2,
              child: _buildRoleSelection(),
            ),
        ],
      ),
    );
  }

  Widget _buildIconSection() {
    return Center(
      child: AnimatedBuilder(
        animation: _iconAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _iconAnimation.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: widget.pageData.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.pageData.color.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.pageData.color.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                widget.pageData.icon,
                size: 70,
                color: widget.pageData.color,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentSection() {
    return AnimatedBuilder(
      animation: _textAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _textAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  widget.pageData.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppConstants.paddingSmall),
                
                // Subtitle
                Text(
                  widget.pageData.subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: widget.pageData.color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Description
                Text(
                  widget.pageData.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Features list
                _buildFeaturesList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: widget.pageData.features.map((feature) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: widget.pageData.color,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Text(
                    feature,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      children: [
        Text(
          'Select your role to continue',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppConstants.paddingLarge),
        
        // Role buttons
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppConstants.paddingMedium,
            mainAxisSpacing: AppConstants.paddingMedium,
            childAspectRatio: 1.2,
            children: [
              _buildRoleButton(
                UserRole.parent,
                'Parent',
                Icons.family_restroom,
                AppColors.parentColor,
              ),
              _buildRoleButton(
                UserRole.driver,
                'Driver',
                Icons.directions_bus,
                AppColors.driverColor,
              ),
              _buildRoleButton(
                UserRole.schoolAdmin,
                'School Admin',
                Icons.school,
                AppColors.schoolAdminColor,
              ),
              _buildRoleButton(
                UserRole.superAdmin,
                'Super Admin',
                Icons.admin_panel_settings,
                AppColors.superAdminColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton(UserRole role, String title, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onRoleSelected?.call(role),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
