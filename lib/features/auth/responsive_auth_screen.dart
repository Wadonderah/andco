import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/responsive_auth_button.dart';
import '../../shared/widgets/responsive_auth_form.dart';

class ResponsiveAuthScreen extends ConsumerStatefulWidget {
  final UserRole userRole;
  final String roleTitle;
  final Color roleColor;

  const ResponsiveAuthScreen({
    super.key,
    required this.userRole,
    required this.roleTitle,
    required this.roleColor,
  });

  @override
  ConsumerState<ResponsiveAuthScreen> createState() => _ResponsiveAuthScreenState();
}

class _ResponsiveAuthScreenState extends ConsumerState<ResponsiveAuthScreen> {
  AuthFormMode _currentMode = AuthFormMode.login;
  bool _showLogoutDemo = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.value;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text('${widget.roleTitle} Authentication'),
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                setState(() {
                  _showLogoutDemo = true;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              children: [
                SizedBox(height: isSmallScreen ? 20 : 40),
                _buildLogo(isSmallScreen),
                SizedBox(height: isSmallScreen ? 20 : 32),
                _buildTitle(isSmallScreen),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildSubtitle(isSmallScreen),
                SizedBox(height: isSmallScreen ? 32 : 48),
                
                if (currentUser != null && !_showLogoutDemo) ...[
                  _buildUserInfo(currentUser, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  _buildLoggedInActions(isSmallScreen),
                ] else if (_showLogoutDemo) ...[
                  ResponsiveAuthForm(
                    mode: AuthFormMode.logout,
                    userRole: widget.userRole,
                    themeColor: widget.roleColor,
                    onSuccess: () {
                      setState(() {
                        _showLogoutDemo = false;
                      });
                      _showSuccessMessage('Signed out successfully!');
                    },
                    showModeToggle: false,
                    showSocialAuth: false,
                  ),
                ] else ...[
                  ResponsiveAuthForm(
                    mode: _currentMode,
                    userRole: widget.userRole,
                    themeColor: widget.roleColor,
                    onSuccess: () {
                      _showSuccessMessage('Authentication successful!');
                    },
                    onModeChange: () {
                      setState(() {
                        _currentMode = _currentMode == AuthFormMode.login 
                            ? AuthFormMode.register 
                            : AuthFormMode.login;
                      });
                    },
                    showModeToggle: true,
                    showSocialAuth: true,
                  ),
                ],
                
                SizedBox(height: isSmallScreen ? 32 : 48),
                _buildButtonDemos(isSmallScreen),
                SizedBox(height: isSmallScreen ? 20 : 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 80 : 100,
      height: isSmallScreen ? 80 : 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.roleColor,
            widget.roleColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.roleColor.withValues(alpha: 0.3),
            blurRadius: isSmallScreen ? 20 : 25,
            offset: Offset(0, isSmallScreen ? 8 : 10),
          ),
        ],
      ),
      child: Icon(
        _getRoleIcon(),
        color: Colors.white,
        size: isSmallScreen ? 40 : 50,
      ),
    );
  }

  IconData _getRoleIcon() {
    switch (widget.userRole) {
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

  Widget _buildTitle(bool isSmallScreen) {
    return Text(
      'AndCo ${widget.roleTitle}',
      style: TextStyle(
        fontSize: isSmallScreen ? 28 : 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(bool isSmallScreen) {
    return Text(
      'Responsive Authentication Interface',
      style: TextStyle(
        fontSize: isSmallScreen ? 14 : 16,
        color: Colors.grey[400],
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUserInfo(UserModel user, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 30 : 40,
            backgroundColor: widget.roleColor,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: isSmallScreen ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            user.name,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            user.email,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: widget.roleColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.roleTitle,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: widget.roleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInActions(bool isSmallScreen) {
    return Column(
      children: [
        ResponsiveAuthButton(
          text: 'Go to Dashboard',
          type: AuthButtonType.primary,
          size: isSmallScreen ? AuthButtonSize.medium : AuthButtonSize.large,
          customColor: widget.roleColor,
          icon: Icons.dashboard,
          onPressed: () {
            _showSuccessMessage('Navigating to ${widget.roleTitle} Dashboard...');
          },
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        ResponsiveAuthButton(
          text: 'Sign Out',
          type: AuthButtonType.logout,
          size: isSmallScreen ? AuthButtonSize.medium : AuthButtonSize.large,
          icon: Icons.logout,
          onPressed: () {
            setState(() {
              _showLogoutDemo = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildButtonDemos(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Responsive Button Examples',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          // Different button types
          ResponsiveAuthButton(
            text: 'Primary Button',
            type: AuthButtonType.primary,
            size: AuthButtonSize.large,
            customColor: widget.roleColor,
            onPressed: () => _showSuccessMessage('Primary button pressed!'),
          ),
          const SizedBox(height: 12),
          
          ResponsiveAuthButton(
            text: 'Secondary Button',
            type: AuthButtonType.secondary,
            size: AuthButtonSize.large,
            customColor: widget.roleColor,
            onPressed: () => _showSuccessMessage('Secondary button pressed!'),
          ),
          const SizedBox(height: 12),
          
          ResponsiveAuthButton(
            text: 'Outlined Button',
            type: AuthButtonType.outlined,
            size: AuthButtonSize.large,
            onPressed: () => _showSuccessMessage('Outlined button pressed!'),
          ),
          const SizedBox(height: 12),
          
          // Different sizes
          Row(
            children: [
              Expanded(
                child: ResponsiveAuthButton(
                  text: 'Small',
                  type: AuthButtonType.primary,
                  size: AuthButtonSize.small,
                  customColor: widget.roleColor,
                  onPressed: () => _showSuccessMessage('Small button!'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ResponsiveAuthButton(
                  text: 'Medium',
                  type: AuthButtonType.primary,
                  size: AuthButtonSize.medium,
                  customColor: widget.roleColor,
                  onPressed: () => _showSuccessMessage('Medium button!'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ResponsiveAuthButton(
                  text: 'Large',
                  type: AuthButtonType.primary,
                  size: AuthButtonSize.large,
                  customColor: widget.roleColor,
                  onPressed: () => _showSuccessMessage('Large button!'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: widget.roleColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
