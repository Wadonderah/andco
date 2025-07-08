import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class ParentalControlScreen extends StatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isParentModeEnabled = false;
  bool _requirePinForSettings = true;
  bool _requirePinForPayments = true;
  bool _requirePinForChat = false;
  bool _allowEmergencyAccess = true;
  bool _restrictCameraAccess = false;
  bool _limitNotifications = false;
  
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  
  final List<AppFeature> _appFeatures = [
    AppFeature(
      id: 'bus_tracking',
      name: 'Bus Tracking',
      description: 'Real-time bus location and ETA',
      icon: Icons.location_on,
      isLocked: false,
      isEssential: true,
    ),
    AppFeature(
      id: 'notifications',
      name: 'Notifications',
      description: 'Push notifications and alerts',
      icon: Icons.notifications,
      isLocked: false,
      isEssential: true,
    ),
    AppFeature(
      id: 'chat',
      name: 'Chat with Driver',
      description: 'In-app messaging with driver',
      icon: Icons.chat,
      isLocked: false,
      isEssential: false,
    ),
    AppFeature(
      id: 'payments',
      name: 'Payments',
      description: 'Payment management and history',
      icon: Icons.payment,
      isLocked: true,
      isEssential: false,
    ),
    AppFeature(
      id: 'settings',
      name: 'Settings',
      description: 'App configuration and preferences',
      icon: Icons.settings,
      isLocked: true,
      isEssential: false,
    ),
    AppFeature(
      id: 'camera',
      name: 'Camera Access',
      description: 'Live camera feed and photos',
      icon: Icons.camera_alt,
      isLocked: false,
      isEssential: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadParentalSettings();
  }

  Future<void> _loadParentalSettings() async {
    // Load settings from secure storage
    // This would typically load from encrypted shared preferences
    setState(() {
      // Mock loaded settings
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parental Controls'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showParentAuthentication,
            icon: Icon(_isParentModeEnabled ? Icons.lock_open : Icons.lock),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Features'),
            Tab(text: 'Restrictions'),
            Tab(text: 'Schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeaturesTab(),
          _buildRestrictionsTab(),
          _buildScheduleTab(),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isParentModeEnabled ? Icons.admin_panel_settings : Icons.child_care,
                color: _isParentModeEnabled ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Text(
                _isParentModeEnabled ? 'Parent Mode Active' : 'Child Mode Active',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isParentModeEnabled ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          
          if (!_isParentModeEnabled)
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(color: AppColors.info),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: AppColors.info),
                  SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      'Some features are restricted. Ask a parent to unlock them.',
                      style: TextStyle(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          const Text(
            'App Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          
          Expanded(
            child: ListView.builder(
              itemCount: _appFeatures.length,
              itemBuilder: (context, index) {
                final feature = _appFeatures[index];
                return _buildFeatureCard(feature);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(AppFeature feature) {
    final isAccessible = !feature.isLocked || _isParentModeEnabled;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isAccessible 
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          ),
          child: Icon(
            feature.icon,
            color: isAccessible ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(
          feature.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isAccessible ? null : AppColors.textSecondary,
          ),
        ),
        subtitle: Text(
          feature.description,
          style: TextStyle(
            color: isAccessible ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (feature.isEssential)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Essential',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (_isParentModeEnabled && !feature.isEssential)
              Switch(
                value: !feature.isLocked,
                onChanged: (value) => _toggleFeatureLock(feature),
                activeColor: AppColors.success,
              )
            else
              Icon(
                isAccessible ? Icons.check_circle : Icons.lock,
                color: isAccessible ? AppColors.success : AppColors.error,
              ),
          ],
        ),
        onTap: isAccessible ? () => _accessFeature(feature) : () => _showFeatureLocked(feature),
      ),
    );
  }

  Widget _buildRestrictionsTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Require PIN for Settings'),
                  subtitle: const Text('Protect app settings with PIN'),
                  value: _requirePinForSettings,
                  onChanged: _isParentModeEnabled ? (value) {
                    setState(() {
                      _requirePinForSettings = value;
                    });
                  } : null,
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Require PIN for Payments'),
                  subtitle: const Text('Protect payment features with PIN'),
                  value: _requirePinForPayments,
                  onChanged: _isParentModeEnabled ? (value) {
                    setState(() {
                      _requirePinForPayments = value;
                    });
                  } : null,
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Require PIN for Chat'),
                  subtitle: const Text('Protect messaging features with PIN'),
                  value: _requirePinForChat,
                  onChanged: _isParentModeEnabled ? (value) {
                    setState(() {
                      _requirePinForChat = value;
                    });
                  } : null,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          const Text(
            'Access Controls',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Allow Emergency Access'),
                  subtitle: const Text('Always allow emergency features'),
                  value: _allowEmergencyAccess,
                  onChanged: _isParentModeEnabled ? (value) {
                    setState(() {
                      _allowEmergencyAccess = value;
                    });
                  } : null,
                  activeColor: AppColors.success,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Restrict Camera Access'),
                  subtitle: const Text('Limit access to camera features'),
                  value: _restrictCameraAccess,
                  onChanged: _isParentModeEnabled ? (value) {
                    setState(() {
                      _restrictCameraAccess = value;
                    });
                  } : null,
                  activeColor: AppColors.warning,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Limit Notifications'),
                  subtitle: const Text('Reduce non-essential notifications'),
                  value: _limitNotifications,
                  onChanged: _isParentModeEnabled ? (value) {
                    setState(() {
                      _limitNotifications = value;
                    });
                  } : null,
                  activeColor: AppColors.info,
                ),
              ],
            ),
          ),
          
          if (_isParentModeEnabled) ...[
            const SizedBox(height: AppConstants.paddingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveParentalSettings,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usage Schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quiet Hours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  const Text(
                    'During quiet hours, only essential features are available.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeSelector(
                          'Start Time',
                          _quietHoursStart,
                          (time) => setState(() => _quietHoursStart = time),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildTimeSelector(
                          'End Time',
                          _quietHoursEnd,
                          (time) => setState(() => _quietHoursEnd = time),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  _buildStatusRow('Current Time', _getCurrentTime()),
                  _buildStatusRow('Quiet Hours Active', _isQuietHoursActive() ? 'Yes' : 'No'),
                  _buildStatusRow('Available Features', _getAvailableFeatureCount().toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        InkWell(
          onTap: _isParentModeEnabled ? () async {
            final selectedTime = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (selectedTime != null) {
              onChanged(selectedTime);
            }
          } : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: _isParentModeEnabled ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: TextStyle(
                    color: _isParentModeEnabled ? null : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Methods
  Future<void> _showParentAuthentication() async {
    if (_isParentModeEnabled) {
      setState(() {
        _isParentModeEnabled = false;
      });
      return;
    }

    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (canCheckBiometrics && isDeviceSupported) {
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access parental controls',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        
        if (didAuthenticate) {
          setState(() {
            _isParentModeEnabled = true;
          });
        }
      } else {
        _showPinDialog();
      }
    } catch (e) {
      _showPinDialog();
    }
  }

  void _showPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Parent PIN'),
        content: const TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'PIN',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isParentModeEnabled = true;
              });
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _toggleFeatureLock(AppFeature feature) {
    setState(() {
      feature.isLocked = !feature.isLocked;
    });
  }

  void _accessFeature(AppFeature feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Accessing ${feature.name}...')),
    );
  }

  void _showFeatureLocked(AppFeature feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Locked'),
        content: Text('${feature.name} is currently locked by parental controls.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showParentAuthentication();
            },
            child: const Text('Ask Parent'),
          ),
        ],
      ),
    );
  }

  void _saveParentalSettings() {
    // Save settings to secure storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parental control settings saved'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _getCurrentTime() {
    final now = TimeOfDay.now();
    return now.format(context);
  }

  bool _isQuietHoursActive() {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _quietHoursStart.hour * 60 + _quietHoursStart.minute;
    final endMinutes = _quietHoursEnd.hour * 60 + _quietHoursEnd.minute;
    
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  int _getAvailableFeatureCount() {
    if (_isQuietHoursActive()) {
      return _appFeatures.where((f) => f.isEssential).length;
    }
    return _appFeatures.where((f) => !f.isLocked).length;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Data Models
class AppFeature {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  bool isLocked;
  final bool isEssential;

  AppFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isLocked,
    required this.isEssential,
  });
}
