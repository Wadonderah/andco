import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedDriverSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedDriverSettingsScreen({super.key});

  @override
  ConsumerState<EnhancedDriverSettingsScreen> createState() =>
      _EnhancedDriverSettingsScreenState();
}

class _EnhancedDriverSettingsScreenState
    extends ConsumerState<EnhancedDriverSettingsScreen> {
  bool _isLoading = false;

  // Navigation settings
  bool _voiceNavigation = true;
  bool _trafficAlerts = true;
  bool _routeOptimization = true;
  String _mapStyle = 'Standard';

  // Notification settings
  bool _pushNotifications = true;
  bool _emergencyAlerts = true;
  bool _routeUpdates = true;
  bool _studentAlerts = true;
  bool _safetyReminders = true;

  // Safety settings
  bool _autoSafetyCheck = true;
  bool _speedAlerts = true;
  bool _breakReminders = true;
  int _speedLimit = 50;

  // App settings
  String _language = 'English';
  String _theme = 'System';
  bool _offlineMode = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Settings'),
        backgroundColor: AppColors.driverColor,
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

          // Navigation Settings
          _buildNavigationSettings(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Notification Settings
          _buildNotificationSettings(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Safety Settings
          _buildSafetySettings(),

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
            backgroundColor: AppColors.driverColor.withOpacity(0.1),
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? Icon(Icons.person, size: 30, color: AppColors.driverColor)
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
                    color: AppColors.driverColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Driver',
                    style: TextStyle(
                      color: AppColors.driverColor,
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
              backgroundColor: AppColors.driverColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSettings() {
    return _buildSettingsSection(
      'Navigation & Routes',
      Icons.navigation,
      [
        _buildSwitchTile(
          'Voice Navigation',
          'Enable voice-guided turn-by-turn directions',
          _voiceNavigation,
          (value) => setState(() => _voiceNavigation = value),
        ),
        _buildSwitchTile(
          'Traffic Alerts',
          'Receive real-time traffic updates and alerts',
          _trafficAlerts,
          (value) => setState(() => _trafficAlerts = value),
        ),
        _buildSwitchTile(
          'Route Optimization',
          'Automatically optimize routes for efficiency',
          _routeOptimization,
          (value) => setState(() => _routeOptimization = value),
        ),
        _buildSelectionTile(
          'Map Style',
          _mapStyle,
          Icons.map,
          () => _selectMapStyle(),
        ),
      ],
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
          'Emergency Alerts',
          'Receive emergency and SOS notifications',
          _emergencyAlerts,
          (value) => setState(() => _emergencyAlerts = value),
        ),
        _buildSwitchTile(
          'Route Updates',
          'Get notified about route changes',
          _routeUpdates,
          (value) => setState(() => _routeUpdates = value),
        ),
        _buildSwitchTile(
          'Student Alerts',
          'Notifications about student attendance',
          _studentAlerts,
          (value) => setState(() => _studentAlerts = value),
        ),
        _buildSwitchTile(
          'Safety Reminders',
          'Reminders for safety checks and procedures',
          _safetyReminders,
          (value) => setState(() => _safetyReminders = value),
        ),
      ],
    );
  }

  Widget _buildSafetySettings() {
    return _buildSettingsSection(
      'Safety & Compliance',
      Icons.security,
      [
        _buildSwitchTile(
          'Auto Safety Check',
          'Automatically prompt for daily safety checks',
          _autoSafetyCheck,
          (value) => setState(() => _autoSafetyCheck = value),
        ),
        _buildSwitchTile(
          'Speed Alerts',
          'Alert when exceeding speed limits',
          _speedAlerts,
          (value) => setState(() => _speedAlerts = value),
        ),
        _buildSwitchTile(
          'Break Reminders',
          'Remind to take breaks during long routes',
          _breakReminders,
          (value) => setState(() => _breakReminders = value),
        ),
        _buildSliderTile(
          'Speed Limit Alert',
          'Alert when exceeding $_speedLimit km/h',
          _speedLimit.toDouble(),
          30.0,
          80.0,
          (value) => setState(() => _speedLimit = value.round()),
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
          'Language',
          _language,
          Icons.language,
          () => _selectLanguage(),
        ),
        _buildSelectionTile(
          'Theme',
          _theme,
          Icons.palette,
          () => _selectTheme(),
        ),
        _buildSwitchTile(
          'Offline Mode',
          'Enable offline functionality when available',
          _offlineMode,
          (value) => setState(() => _offlineMode = value),
        ),
        _buildActionTile(
          'Clear Cache',
          'Free up storage space',
          Icons.cleaning_services,
          () => _clearCache(),
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
          'Change Password',
          'Update your account password',
          Icons.lock,
          () => _changePassword(),
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
              Icon(icon, color: AppColors.driverColor, size: 20),
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
      activeColor: AppColors.driverColor,
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
          activeColor: AppColors.driverColor,
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

  void _selectMapStyle() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Map Style'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Standard', 'Satellite', 'Terrain', 'Hybrid'].map((style) {
            return RadioListTile<String>(
              title: Text(style),
              value: style,
              groupValue: _mapStyle,
              onChanged: (value) {
                setState(() => _mapStyle = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
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
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
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

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully')),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password change coming soon')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
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
                backgroundColor: AppColors.driverColor),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
