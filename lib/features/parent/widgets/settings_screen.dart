import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_text_field.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _whatsappNotifications = true;
  bool _locationSharing = true;
  bool _biometricAuth = false;
  String _language = 'English';
  String _emergencyContact = '+1 234 567 8900';

  // Controllers for editing
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _emergencyContactController.text = _emergencyContact;
  }

  @override
  void dispose() {
    _emergencyContactController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 2 : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet
              ? AppConstants.paddingLarge
              : AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Settings Section
              _buildSectionHeader('Appearance', Icons.palette),
              const SizedBox(height: AppConstants.paddingMedium),

              if (isTablet)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 3,
                  crossAxisSpacing: AppConstants.paddingMedium,
                  mainAxisSpacing: AppConstants.paddingSmall,
                  children: [
                    _buildThemeCard(),
                    _buildLanguageCard(),
                  ],
                )
              else ...[
                _buildThemeCard(),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildLanguageCard(),
              ],

              const SizedBox(height: AppConstants.paddingLarge),

              // Notification Settings Section
              _buildSectionHeader('Notifications', Icons.notifications),
              const SizedBox(height: AppConstants.paddingMedium),

              if (isTablet)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 4,
                  crossAxisSpacing: AppConstants.paddingMedium,
                  mainAxisSpacing: AppConstants.paddingSmall,
                  children: [
                    _buildNotificationTile(
                      'Push Notifications',
                      'Receive instant app notifications',
                      Icons.notifications_active,
                      _pushNotifications,
                      (value) => setState(() => _pushNotifications = value),
                    ),
                    _buildNotificationTile(
                      'Email Notifications',
                      'Receive updates via email',
                      Icons.email,
                      _emailNotifications,
                      (value) => setState(() => _emailNotifications = value),
                    ),
                    _buildNotificationTile(
                      'SMS Notifications',
                      'Receive SMS alerts',
                      Icons.sms,
                      _smsNotifications,
                      (value) => setState(() => _smsNotifications = value),
                    ),
                    _buildNotificationTile(
                      'WhatsApp Notifications',
                      'Receive WhatsApp messages',
                      Icons.chat,
                      _whatsappNotifications,
                      (value) => setState(() => _whatsappNotifications = value),
                    ),
                  ],
                )
              else ...[
                _buildNotificationTile(
                  'Push Notifications',
                  'Receive instant app notifications',
                  Icons.notifications_active,
                  _pushNotifications,
                  (value) => setState(() => _pushNotifications = value),
                ),
                _buildNotificationTile(
                  'Email Notifications',
                  'Receive updates via email',
                  Icons.email,
                  _emailNotifications,
                  (value) => setState(() => _emailNotifications = value),
                ),
                _buildNotificationTile(
                  'SMS Notifications',
                  'Receive SMS alerts',
                  Icons.sms,
                  _smsNotifications,
                  (value) => setState(() => _smsNotifications = value),
                ),
                _buildNotificationTile(
                  'WhatsApp Notifications',
                  'Receive WhatsApp messages',
                  Icons.chat,
                  _whatsappNotifications,
                  (value) => setState(() => _whatsappNotifications = value),
                ),
              ],

              const SizedBox(height: AppConstants.paddingLarge),

              // Privacy & Security Section
              _buildSectionHeader('Privacy & Security', Icons.security),
              const SizedBox(height: AppConstants.paddingMedium),

              if (isTablet)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 4,
                  crossAxisSpacing: AppConstants.paddingMedium,
                  mainAxisSpacing: AppConstants.paddingSmall,
                  children: [
                    _buildSecurityTile(
                      'Location Sharing',
                      'Share location with school and driver',
                      Icons.location_on,
                      _locationSharing,
                      (value) => setState(() => _locationSharing = value),
                    ),
                    _buildSecurityTile(
                      'Biometric Authentication',
                      'Use fingerprint or face ID',
                      Icons.fingerprint,
                      _biometricAuth,
                      (value) => setState(() => _biometricAuth = value),
                    ),
                  ],
                )
              else ...[
                _buildSecurityTile(
                  'Location Sharing',
                  'Share location with school and driver',
                  Icons.location_on,
                  _locationSharing,
                  (value) => setState(() => _locationSharing = value),
                ),
                _buildSecurityTile(
                  'Biometric Authentication',
                  'Use fingerprint or face ID',
                  Icons.fingerprint,
                  _biometricAuth,
                  (value) => setState(() => _biometricAuth = value),
                ),
              ],

              const SizedBox(height: AppConstants.paddingLarge),

              // Emergency Settings Section
              _buildSectionHeader('Emergency', Icons.emergency),
              const SizedBox(height: AppConstants.paddingMedium),

              _buildEmergencyContactCard(),

              const SizedBox(height: AppConstants.paddingLarge),

              // Account Actions Section
              _buildSectionHeader('Account', Icons.account_circle),
              const SizedBox(height: AppConstants.paddingMedium),

              if (isTablet)
                Row(
                  children: [
                    Expanded(
                        child: _buildAccountActionCard('Change Password',
                            Icons.lock, AppColors.warning, _changePassword)),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                        child: _buildAccountActionCard(
                            'Delete Account',
                            Icons.delete_forever,
                            AppColors.error,
                            _deleteAccount)),
                  ],
                )
              else ...[
                _buildAccountActionCard('Change Password', Icons.lock,
                    AppColors.warning, _changePassword),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildAccountActionCard('Delete Account', Icons.delete_forever,
                    AppColors.error, _deleteAccount),
              ],

              const SizedBox(height: AppConstants.paddingLarge),

              // App Info
              _buildAppInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.parentColor, size: 24),
        const SizedBox(width: AppConstants.paddingSmall),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.parentColor,
              ),
        ),
      ],
    );
  }

  Widget _buildThemeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.brightness_6, color: AppColors.parentColor),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              children: [
                Expanded(
                  child: _buildThemeOption(
                      'Light', ThemeMode.light, Icons.light_mode),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildThemeOption(
                      'Dark', ThemeMode.dark, Icons.dark_mode),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildThemeOption(
                      'System', ThemeMode.system, Icons.settings_brightness),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String label, ThemeMode mode, IconData icon) {
    return Consumer(
      builder: (context, ref, child) {
        final themeState = ref.watch(themeServiceProvider);
        final themeService = ref.read(themeServiceProvider.notifier);

        // Map ThemeMode to AppThemeMode
        AppThemeMode appThemeMode;
        switch (mode) {
          case ThemeMode.light:
            appThemeMode = AppThemeMode.light;
            break;
          case ThemeMode.dark:
            appThemeMode = AppThemeMode.dark;
            break;
          case ThemeMode.system:
            appThemeMode = AppThemeMode.system;
            break;
        }

        final isSelected = themeState.themeMode == appThemeMode;

        return GestureDetector(
          onTap: () {
            themeService.setThemeMode(appThemeMode);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label theme selected'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.parentColor.withValues(alpha: 0.1)
                  : null,
              borderRadius: BorderRadius.circular(8),
              border:
                  isSelected ? Border.all(color: AppColors.parentColor) : null,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.parentColor
                      : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? AppColors.parentColor
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.language, color: AppColors.parentColor),
        title: const Text('Language'),
        subtitle: Text(_language),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: showLanguageSelector,
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.parentColor),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.parentColor,
      ),
    );
  }

  Widget _buildSecurityTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.parentColor),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.parentColor,
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.emergency, color: AppColors.error),
        title: const Text('Emergency Contact'),
        subtitle: Text(_emergencyContact),
        trailing: const Icon(Icons.edit, size: 16),
        onTap: editEmergencyContact,
      ),
    );
  }

  Widget _buildAccountActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.parentColor),
                const SizedBox(width: AppConstants.paddingSmall),
                Text(
                  'App Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Build', '100'),
            _buildInfoRow('Last Updated', 'January 2024'),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: showPrivacyPolicy,
                    child: const Text('Privacy Policy'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: OutlinedButton(
                    onPressed: showTermsOfService,
                    child: const Text('Terms of Service'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ...['English', 'Spanish', 'French', 'Swahili'].map(
              (lang) => ListTile(
                title: Text(lang),
                trailing: _language == lang
                    ? const Icon(Icons.check, color: AppColors.parentColor)
                    : null,
                onTap: () {
                  setState(() => _language = lang);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void editEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _emergencyContactController,
              label: 'Emergency Contact',
              hint: 'Enter emergency contact number',
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _emergencyContact = _emergencyContactController.text;
              });

              // In a real app, this would update the user profile in Firebase
              // ref.read(authControllerProvider.notifier).updateProfile({
              //   'emergencyContact': _emergencyContact,
              // });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency contact updated'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password change will be implemented')),
    );
  }

  void deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Account deletion will be implemented')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPolicySection('Data Collection',
                    'We collect information you provide directly to us, such as when you create an account, use our services, or contact us for support.'),
                _buildPolicySection('Data Usage',
                    'We use your information to provide, maintain, and improve our services, process transactions, and communicate with you.'),
                _buildPolicySection('Data Sharing',
                    'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.'),
                _buildPolicySection('Data Security',
                    'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.'),
                _buildPolicySection('Your Rights',
                    'You have the right to access, update, or delete your personal information. You may also opt out of certain communications from us.'),
                _buildPolicySection('Contact Us',
                    'If you have any questions about this Privacy Policy, please contact us at privacy@andco.app'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              const url = 'https://andco.app/privacy';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
            child: const Text('View Full Policy'),
          ),
        ],
      ),
    );
  }

  void showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPolicySection('Acceptance of Terms',
                    'By using AndCo School Transport services, you agree to be bound by these Terms of Service.'),
                _buildPolicySection('Service Description',
                    'AndCo provides school transportation management services including route tracking, student management, and communication tools.'),
                _buildPolicySection('User Responsibilities',
                    'You are responsible for maintaining the confidentiality of your account and for all activities that occur under your account.'),
                _buildPolicySection('Service Availability',
                    'We strive to provide continuous service but do not guarantee uninterrupted access to our services.'),
                _buildPolicySection('Limitation of Liability',
                    'AndCo shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of our services.'),
                _buildPolicySection('Termination',
                    'We may terminate or suspend your account at any time for violations of these terms or for any other reason.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              const url = 'https://andco.app/terms';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
            child: const Text('View Full Terms'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _currentPasswordController,
              label: 'Current Password',
              hint: 'Enter your current password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _newPasswordController,
              label: 'New Password',
              hint: 'Enter new password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              hint: 'Confirm new password',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_newPasswordController.text !=
                  _confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (_newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              try {
                // In a real implementation, you would use Firebase Auth to change password
                // await ref.read(authControllerProvider.notifier).changePassword(
                //   _currentPasswordController.text,
                //   _newPasswordController.text,
                // );

                _currentPasswordController.clear();
                _newPasswordController.clear();
                _confirmPasswordController.clear();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error changing password: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action will permanently delete your account and all associated data:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('• Your profile information'),
            const Text('• Your children\'s profiles'),
            const Text('• Payment history'),
            const Text('• All messages and notifications'),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. Are you sure you want to continue?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentContext =
                  context; // Store context before async operations
              Navigator.pop(currentContext);

              // Show loading dialog
              showDialog(
                context: currentContext,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Deleting account...'),
                    ],
                  ),
                ),
              );

              try {
                // In a real implementation, you would use Firebase Auth to delete account
                // await ref.read(authControllerProvider.notifier).deleteAccount();

                // Simulate deletion process
                await Future.delayed(const Duration(seconds: 2));

                if (!mounted) return;

                Navigator.pop(currentContext); // Close loading dialog

                // Navigate to auth screen or app start
                Navigator.of(currentContext).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;

                Navigator.pop(currentContext); // Close loading dialog
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting account: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
