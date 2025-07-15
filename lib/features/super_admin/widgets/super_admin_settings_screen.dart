import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class SuperAdminSettingsScreen extends ConsumerStatefulWidget {
  const SuperAdminSettingsScreen({super.key});

  @override
  ConsumerState<SuperAdminSettingsScreen> createState() =>
      _SuperAdminSettingsScreenState();
}

class _SuperAdminSettingsScreenState
    extends ConsumerState<SuperAdminSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Settings'),
        backgroundColor: AppColors.superAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Platform'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admin'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPlatformSettingsTab(),
            _buildSecuritySettingsTab(),
            _buildNotificationSettingsTab(),
            _buildAdminSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Configuration',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // General Settings
          _buildSettingsSection('General Settings', [
            _buildSettingsTile(
                'Maintenance Mode', 'Enable platform maintenance mode', false),
            _buildSettingsTile(
                'New User Registration', 'Allow new user registrations', true),
            _buildSettingsTile('School Auto-Approval',
                'Automatically approve new schools', false),
            _buildSettingsTile('Driver Verification',
                'Require driver background checks', true),
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          // Feature Flags
          _buildSettingsSection('Feature Flags', [
            _buildSettingsTile(
                'Real-time Tracking', 'Enable GPS tracking features', true),
            _buildSettingsTile(
                'Payment Processing', 'Enable payment functionality', true),
            _buildSettingsTile('AI Route Optimization',
                'Enable AI-powered route optimization', true),
            _buildSettingsTile(
                'Offline Mode', 'Enable offline functionality', false),
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          // API Configuration
          _buildSettingsSection('API Configuration', [
            _buildActionTile('Google Maps API',
                'Configure Google Maps integration', Icons.map),
            _buildActionTile('Stripe Configuration',
                'Configure payment processing', Icons.payment),
            _buildActionTile('M-Pesa Settings', 'Configure M-Pesa integration',
                Icons.phone_android),
            _buildActionTile('Firebase Settings', 'Configure Firebase services',
                Icons.cloud),
          ]),
        ],
      ),
    );
  }

  Widget _buildSecuritySettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Configuration',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Authentication Settings
          _buildSettingsSection('Authentication', [
            _buildSettingsTile('Two-Factor Authentication',
                'Require 2FA for admin accounts', true),
            _buildSettingsTile('Password Complexity',
                'Enforce strong password requirements', true),
            _buildSettingsTile(
                'Session Timeout', 'Auto-logout after inactivity', true),
            _buildSettingsTile(
                'IP Whitelisting', 'Restrict admin access by IP', false),
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          // Security Monitoring
          _buildSettingsSection('Security Monitoring', [
            _buildSettingsTile(
                'Failed Login Alerts', 'Alert on multiple failed logins', true),
            _buildSettingsTile('Suspicious Activity Detection',
                'Monitor for unusual patterns', true),
            _buildSettingsTile(
                'Data Encryption', 'Encrypt sensitive data at rest', true),
            _buildSettingsTile(
                'Audit Logging', 'Log all administrative actions', true),
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          // Security Actions
          _buildSettingsSection('Security Actions', [
            _buildActionTile('Security Scan', 'Run comprehensive security scan',
                Icons.security),
            _buildActionTile(
                'Backup Data', 'Create encrypted data backup', Icons.backup),
            _buildActionTile(
                'Review Logs', 'Review security audit logs', Icons.list_alt),
            _buildActionTile('Update Certificates', 'Renew SSL certificates',
                Icons.verified),
          ]),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Configuration',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // System Notifications
          _buildSettingsSection('System Notifications', [
            _buildSettingsTile(
                'System Alerts', 'Receive system health alerts', true),
            _buildSettingsTile(
                'Security Alerts', 'Receive security incident alerts', true),
            _buildSettingsTile(
                'Performance Alerts', 'Receive performance warnings', true),
            _buildSettingsTile('Maintenance Notifications',
                'Receive maintenance reminders', true),
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          // User Notifications
          _buildSettingsSection('User Notifications', [
            _buildSettingsTile(
                'New User Registrations', 'Alert on new user signups', true),
            _buildSettingsTile('School Applications',
                'Alert on new school applications', true),
            _buildSettingsTile(
                'Payment Issues', 'Alert on payment failures', true),
            _buildSettingsTile(
                'Support Escalations', 'Alert on escalated tickets', true),
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          // Notification Channels
          _buildSettingsSection('Notification Channels', [
            _buildActionTile(
                'Email Settings', 'Configure email notifications', Icons.email),
            _buildActionTile(
                'SMS Settings', 'Configure SMS notifications', Icons.sms),
            _buildActionTile('Push Notifications',
                'Configure push notifications', Icons.notifications),
            _buildActionTile('Slack Integration',
                'Configure Slack notifications', Icons.chat),
          ]),
        ],
      ),
    );
  }

  Widget _buildAdminSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Configuration',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Admin Account Settings
          _buildSettingsSection('Admin Account', [
            _buildActionTile(
                'Change Password', 'Update admin password', Icons.lock),
            _buildActionTile('Update Profile',
                'Update admin profile information', Icons.person),
            _buildActionTile('Backup Codes',
                'Generate backup authentication codes', Icons.vpn_key),
            _buildActionTile(
                'Activity Log', 'View admin activity history', Icons.history),
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          // System Management
          _buildSettingsSection('System Management', [
            _buildActionTile('Database Management',
                'Manage database operations', Icons.storage),
            _buildActionTile('Cache Management',
                'Clear and manage system cache', Icons.cached),
            _buildActionTile(
                'Log Management', 'Manage system logs', Icons.description),
            _buildActionTile(
                'Backup Management', 'Manage system backups', Icons.backup),
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          // Emergency Actions
          _buildSettingsSection('Emergency Actions', [
            _buildActionTile('Emergency Shutdown',
                'Emergency platform shutdown', Icons.power_off,
                isDestructive: true),
            _buildActionTile('Reset All Data', 'Factory reset (DANGER)',
                Icons.delete_forever,
                isDestructive: true),
            _buildActionTile(
                'Revoke All Sessions', 'Force logout all users', Icons.logout,
                isDestructive: true),
            _buildActionTile(
                'Lock Platform', 'Lock platform access', Icons.lock,
                isDestructive: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, bool value) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (newValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$title ${newValue ? 'enabled' : 'disabled'}')),
        );
      },
      activeColor: AppColors.superAdminColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon,
      {bool isDestructive = false}) {
    final color = isDestructive ? AppColors.error : AppColors.superAdminColor;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : null,
          fontWeight: isDestructive ? FontWeight.w600 : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        if (isDestructive) {
          _showDestructiveActionDialog(title);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title functionality coming soon')),
          );
        }
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showDestructiveActionDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text(
          'This is a destructive action that cannot be undone. Are you sure you want to proceed with $action?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$action functionality coming soon'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
