import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'profile_management_screen.dart';

class EnhancedSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  ConsumerState<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends ConsumerState<EnhancedSettingsScreen> {
  bool _isLoading = false;
  
  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pickupAlerts = true;
  bool _dropoffAlerts = true;
  bool _emergencyAlerts = true;
  bool _paymentReminders = true;
  
  // Privacy settings
  bool _locationSharing = true;
  bool _dataSharing = false;
  bool _analyticsSharing = true;
  
  // Security settings
  bool _biometricAuth = false;
  bool _twoFactorAuth = false;
  
  // App settings
  String _language = 'English';
  String _theme = 'System';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: authState.when(
          data: (user) => user != null ? _buildSettingsContent(user) : _buildLoginPrompt(),
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
          
          // Privacy Settings
          _buildPrivacySettings(),
          
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.parentColor.withOpacity(0.1),
                backgroundImage: user.profileImageUrl != null 
                  ? NetworkImage(user.profileImageUrl!) 
                  : null,
                child: user.profileImageUrl == null 
                  ? Icon(Icons.person, size: 30, color: AppColors.parentColor)
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
                    if (user.phoneNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phoneNumber!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _navigateToProfile(),
                icon: const Icon(Icons.edit),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.parentColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.paddingMedium),
          
          Row(
            children: [
              Expanded(
                child: _buildProfileStat('Children', '2'),
              ),
              Expanded(
                child: _buildProfileStat('Active Routes', '1'),
              ),
              Expanded(
                child: _buildProfileStat('Member Since', '2023'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.parentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
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
        const Divider(),
        _buildSwitchTile(
          'Pickup Alerts',
          'Get notified when child is picked up',
          _pickupAlerts,
          (value) => setState(() => _pickupAlerts = value),
        ),
        _buildSwitchTile(
          'Drop-off Alerts',
          'Get notified when child is dropped off',
          _dropoffAlerts,
          (value) => setState(() => _dropoffAlerts = value),
        ),
        _buildSwitchTile(
          'Emergency Alerts',
          'Receive emergency notifications',
          _emergencyAlerts,
          (value) => setState(() => _emergencyAlerts = value),
        ),
        _buildSwitchTile(
          'Payment Reminders',
          'Get reminded about upcoming payments',
          _paymentReminders,
          (value) => setState(() => _paymentReminders = value),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return _buildSettingsSection(
      'Privacy',
      Icons.privacy_tip,
      [
        _buildSwitchTile(
          'Location Sharing',
          'Share your location with school and driver',
          _locationSharing,
          (value) => setState(() => _locationSharing = value),
        ),
        _buildSwitchTile(
          'Data Sharing',
          'Share usage data to improve the app',
          _dataSharing,
          (value) => setState(() => _dataSharing = value),
        ),
        _buildSwitchTile(
          'Analytics',
          'Help us improve with anonymous analytics',
          _analyticsSharing,
          (value) => setState(() => _analyticsSharing = value),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSettingsSection(
      'Security',
      Icons.security,
      [
        _buildSwitchTile(
          'Biometric Authentication',
          'Use fingerprint or face ID to unlock',
          _biometricAuth,
          (value) => setState(() => _biometricAuth = value),
        ),
        _buildSwitchTile(
          'Two-Factor Authentication',
          'Add extra security to your account',
          _twoFactorAuth,
          (value) => setState(() => _twoFactorAuth = value),
        ),
        _buildActionTile(
          'Change Password',
          'Update your account password',
          Icons.lock,
          () => _changePassword(),
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
          'Export Data',
          'Download your account data',
          Icons.download,
          () => _exportData(),
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
        _buildActionTile(
          'Delete Account',
          'Permanently delete your account',
          Icons.delete_forever,
          () => _deleteAccount(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
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
              Icon(icon, color: AppColors.parentColor, size: 20),
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.parentColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary),
      title: Text(title, style: TextStyle(color: isDestructive ? AppColors.error : null)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSelectionTile(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileManagementScreen(),
      ),
    );
  }

  void _selectLanguage() {
    // TODO: Implement language selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language selection coming soon')),
    );
  }

  void _selectTheme() {
    // TODO: Implement theme selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme selection coming soon')),
    );
  }

  void _changePassword() {
    // TODO: Implement password change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password change coming soon')),
    );
  }

  void _clearCache() {
    // TODO: Implement cache clearing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully')),
    );
  }

  void _exportData() {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export coming soon')),
    );
  }

  void _contactSupport() {
    // TODO: Implement support contact
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

  void _deleteAccount() async {
    final confirmed = await _showConfirmDialog(
      'Delete Account',
      'Are you sure you want to permanently delete your account? This action cannot be undone.',
      isDestructive: true,
    );
    
    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authControllerProvider.notifier).deleteAccount();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message, {bool isDestructive = false}) async {
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
              backgroundColor: isDestructive ? AppColors.error : AppColors.parentColor,
            ),
            child: Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
