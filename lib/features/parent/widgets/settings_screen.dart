import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _whatsappNotifications = true;
  bool _locationSharing = true;
  bool _biometricAuth = false;
  String _language = 'English';
  final String _emergencyContact = '+1 234 567 8900';

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
    final isSelected = Theme.of(context).brightness ==
        (mode == ThemeMode.light
            ? Brightness.light
            : mode == ThemeMode.dark
                ? Brightness.dark
                : MediaQuery.of(context).platformBrightness);

    return GestureDetector(
      onTap: () {
        // TODO: Implement theme switching with provider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label theme selected')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.parentColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.parentColor) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? AppColors.parentColor : AppColors.textSecondary,
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.language, color: AppColors.parentColor),
        title: const Text('Language'),
        subtitle: Text(_language),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showLanguageSelector,
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
        onTap: _editEmergencyContact,
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
                    onPressed: _showPrivacyPolicy,
                    child: const Text('Privacy Policy'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showTermsOfService,
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

  void _showLanguageSelector() {
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

  void _editEmergencyContact() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Emergency contact editing will be implemented')),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password change will be implemented')),
    );
  }

  void _deleteAccount() {
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

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy will be displayed')),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms of service will be displayed')),
    );
  }
}
