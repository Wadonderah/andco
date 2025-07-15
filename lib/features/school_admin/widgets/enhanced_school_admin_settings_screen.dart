import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedSchoolAdminSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedSchoolAdminSettingsScreen({super.key});

  @override
  ConsumerState<EnhancedSchoolAdminSettingsScreen> createState() =>
      _EnhancedSchoolAdminSettingsScreenState();
}

class _EnhancedSchoolAdminSettingsScreenState
    extends ConsumerState<EnhancedSchoolAdminSettingsScreen> {
  bool _isLoading = false;

  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _emergencyAlerts = true;
  bool _attendanceAlerts = true;
  bool _routeUpdates = true;
  bool _parentFeedback = true;

  // School settings
  bool _autoApproveDrivers = false;
  bool _requireParentApproval = true;
  bool _enableOfflineMode = true;
  bool _allowBulkOperations = true;
  String _defaultLanguage = 'English';
  String _timeZone = 'UTC-5 (Eastern)';
  String _theme = 'System';

  // Security settings
  bool _twoFactorAuth = false;
  bool _sessionTimeout = true;
  int _sessionTimeoutMinutes = 30;
  bool _auditLogging = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: authState.when(
          data: (user) =>
              user != null ? _buildSettingsContent(user) : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          _buildProfileSection(user),

          const SizedBox(height: AppConstants.paddingLarge),

          // Notification Settings
          _buildNotificationSettings(),

          const SizedBox(height: AppConstants.paddingLarge),

          // School Settings
          _buildSchoolSettings(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Security Settings
          _buildSecuritySettings(),

          const SizedBox(height: AppConstants.paddingLarge),

          // App Settings
          _buildAppSettings(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Account Actions
          _buildAccountActions(),
        ],
      ),
    );
  }

  Widget _buildProfileSection(user) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.schoolAdminColor.withValues(alpha: 0.1),
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? Icon(Icons.person,
                    size: 30, color: AppColors.schoolAdminColor)
                : null,
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.schoolAdminColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'School Administrator',
                    style: TextStyle(
                      color: AppColors.schoolAdminColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editProfile(),
            icon: const Icon(Icons.edit),
            style: IconButton.styleFrom(
              backgroundColor:
                  AppColors.schoolAdminColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsSection(
      'Notifications',
      Icons.notifications,
      [
        _buildSwitchTile(
          'Push Notifications',
          'Receive notifications on your device',
          _pushNotifications,
          (value) => setState(() => _pushNotifications = value),
        ),
        _buildSwitchTile(
          'Email Notifications',
          'Receive notifications via email',
          _emailNotifications,
          (value) => setState(() => _emailNotifications = value),
        ),
        _buildSwitchTile(
          'SMS Notifications',
          'Receive notifications via SMS',
          _smsNotifications,
          (value) => setState(() => _smsNotifications = value),
        ),
        _buildSwitchTile(
          'Emergency Alerts',
          'Receive emergency and SOS notifications',
          _emergencyAlerts,
          (value) => setState(() => _emergencyAlerts = value),
        ),
        _buildSwitchTile(
          'Attendance Alerts',
          'Get notified about attendance issues',
          _attendanceAlerts,
          (value) => setState(() => _attendanceAlerts = value),
        ),
        _buildSwitchTile(
          'Route Updates',
          'Notifications about route changes',
          _routeUpdates,
          (value) => setState(() => _routeUpdates = value),
        ),
        _buildSwitchTile(
          'Parent Feedback',
          'Notifications for new parent feedback',
          _parentFeedback,
          (value) => setState(() => _parentFeedback = value),
        ),
      ],
    );
  }

  Widget _buildSchoolSettings() {
    return _buildSettingsSection(
      'School Management',
      Icons.school,
      [
        _buildSwitchTile(
          'Auto-Approve Drivers',
          'Automatically approve verified drivers',
          _autoApproveDrivers,
          (value) => setState(() => _autoApproveDrivers = value),
        ),
        _buildSwitchTile(
          'Require Parent Approval',
          'Parents must approve route assignments',
          _requireParentApproval,
          (value) => setState(() => _requireParentApproval = value),
        ),
        _buildSwitchTile(
          'Enable Offline Mode',
          'Allow offline functionality when available',
          _enableOfflineMode,
          (value) => setState(() => _enableOfflineMode = value),
        ),
        _buildSwitchTile(
          'Allow Bulk Operations',
          'Enable bulk student and route operations',
          _allowBulkOperations,
          (value) => setState(() => _allowBulkOperations = value),
        ),
        _buildSelectionTile(
          'Default Language',
          _defaultLanguage,
          Icons.language,
          () => _selectLanguage(),
        ),
        _buildSelectionTile(
          'Time Zone',
          _timeZone,
          Icons.access_time,
          () => _selectTimeZone(),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSettingsSection(
      'Security & Privacy',
      Icons.security,
      [
        _buildSwitchTile(
          'Two-Factor Authentication',
          'Add extra security to your account',
          _twoFactorAuth,
          (value) => setState(() => _twoFactorAuth = value),
        ),
        _buildSwitchTile(
          'Session Timeout',
          'Automatically log out after inactivity',
          _sessionTimeout,
          (value) => setState(() => _sessionTimeout = value),
        ),
        _buildSliderTile(
          'Session Timeout Duration',
          'Auto-logout after $_sessionTimeoutMinutes minutes',
          _sessionTimeoutMinutes.toDouble(),
          15.0,
          120.0,
          (value) => setState(() => _sessionTimeoutMinutes = value.round()),
        ),
        _buildSwitchTile(
          'Audit Logging',
          'Log all administrative actions',
          _auditLogging,
          (value) => setState(() => _auditLogging = value),
        ),
        _buildActionTile(
          'Change Password',
          'Update your account password',
          Icons.lock,
          () => _changePassword(),
        ),
        _buildActionTile(
          'View Audit Log',
          'Review recent administrative actions',
          Icons.history,
          () => _viewAuditLog(),
        ),
      ],
    );
  }

  Widget _buildAppSettings() {
    return _buildSettingsSection(
      'App Settings',
      Icons.settings,
      [
        _buildSelectionTile(
          'Theme',
          _theme,
          Icons.palette,
          () => _selectTheme(),
        ),
        _buildActionTile(
          'Clear Cache',
          'Free up storage space',
          Icons.cleaning_services,
          () => _clearCache(),
        ),
        _buildActionTile(
          'Export Data',
          'Download school data backup',
          Icons.download,
          () => _exportData(),
        ),
        _buildActionTile(
          'App Version',
          'Version 1.0.0 (Build 100)',
          Icons.info,
          () => _showAppInfo(),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    return _buildSettingsSection(
      'Account',
      Icons.account_circle,
      [
        _buildActionTile(
          'Manage Users',
          'Add or remove admin users',
          Icons.group,
          () => _manageUsers(),
        ),
        _buildActionTile(
          'School Profile',
          'Update school information',
          Icons.business,
          () => _editSchoolProfile(),
        ),
        _buildActionTile(
          'Contact Support',
          'Get help with your account',
          Icons.support_agent,
          () => _contactSupport(),
        ),
        _buildActionTile(
          'Sign Out',
          'Sign out of your account',
          Icons.logout,
          () => _signOut(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.schoolAdminColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.schoolAdminColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionTile(
      String title, String subtitle, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isDestructive ? AppColors.error : AppColors.textSecondary),
      title: Text(title,
          style: TextStyle(color: isDestructive ? AppColors.error : null)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSelectionTile(
      String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSliderTile(String title, String subtitle, double value,
      double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          contentPadding: EdgeInsets.zero,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: AppColors.schoolAdminColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Please log in to access settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  // Action methods
  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile editing coming soon')),
    );
  }

  void _selectLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Spanish', 'French', 'German'].map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _defaultLanguage,
              onChanged: (value) {
                setState(() => _defaultLanguage = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _selectTimeZone() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Time Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'UTC-5 (Eastern)',
            'UTC-6 (Central)',
            'UTC-7 (Mountain)',
            'UTC-8 (Pacific)',
          ].map((timeZone) {
            return RadioListTile<String>(
              title: Text(timeZone),
              value: timeZone,
              groupValue: _timeZone,
              onChanged: (value) {
                setState(() => _timeZone = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _selectTheme() {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final themeState = ref.watch(themeServiceProvider);
          final themeService = ref.read(themeServiceProvider.notifier);

          return AlertDialog(
            title: const Text('Select Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppThemeMode.values.map((mode) {
                return RadioListTile<AppThemeMode>(
                  title: Text(ThemeService.getThemeModeDisplayName(mode)),
                  value: mode,
                  groupValue: themeState.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeService.setThemeMode(value);
                      setState(() =>
                          _theme = ThemeService.getThemeModeDisplayName(value));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${ThemeService.getThemeModeDisplayName(value)} theme selected'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password change coming soon')),
    );
  }

  void _viewAuditLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit log viewing coming soon')),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully')),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export coming soon')),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AndCo School Transport'),
            Text('Version: 1.0.0'),
            Text('Build: 100'),
            Text('© 2024 AndCo Technologies'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _manageUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User management coming soon')),
    );
  }

  void _editSchoolProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('School profile editing coming soon')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support contact coming soon')),
    );
  }

  void _signOut() async {
    final confirmed = await _showConfirmDialog(
      'Sign Out',
      'Are you sure you want to sign out?',
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authControllerProvider.notifier).signOut();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.schoolAdminColor),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
