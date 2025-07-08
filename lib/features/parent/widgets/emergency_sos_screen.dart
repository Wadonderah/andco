import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isSOSActive = false;
  bool _isCountingDown = false;
  int _countdown = 5;
  
  final List<EmergencyContact> _emergencyContacts = [
    EmergencyContact(
      name: 'Emergency Services',
      phone: '911',
      type: ContactType.emergency,
      isDefault: true,
    ),
    EmergencyContact(
      name: 'School Security',
      phone: '+1 234 567 8900',
      type: ContactType.school,
      isDefault: true,
    ),
    EmergencyContact(
      name: 'Bus Driver - Mike Wilson',
      phone: '+1 234 567 8901',
      type: ContactType.driver,
      isDefault: true,
    ),
    EmergencyContact(
      name: 'Spouse - John Johnson',
      phone: '+1 234 567 8902',
      type: ContactType.family,
      isDefault: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _countdownController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showSOSSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.error.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              children: [
                // Warning Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: AppColors.warning,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Use Only',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                            Text(
                              'This will alert emergency contacts and authorities. Use only in genuine emergencies.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // SOS Button
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isSOSActive ? _pulseAnimation.value : 1.0,
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isCountingDown ? _scaleAnimation.value : 1.0,
                              child: GestureDetector(
                                onTap: _isCountingDown ? _cancelSOS : _activateSOS,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: _isSOSActive ? AppColors.error : AppColors.error.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.error.withOpacity(0.4),
                                        blurRadius: _isSOSActive ? 30 : 20,
                                        spreadRadius: _isSOSActive ? 10 : 5,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isCountingDown ? Icons.cancel : Icons.emergency,
                                        color: Colors.white,
                                        size: 60,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isCountingDown ? 'CANCEL' : 'SOS',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      if (_isCountingDown) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _countdown.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Instructions
                Text(
                  _isCountingDown 
                      ? 'Tap to cancel emergency alert'
                      : 'Tap and hold to activate emergency alert',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
                
                // Emergency Contacts
                Text(
                  'Emergency Contacts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: _emergencyContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _emergencyContacts[index];
                      return _buildEmergencyContactCard(contact);
                    },
                  ),
                ),
                
                // Quick Call Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _quickCall('911'),
                        icon: const Icon(Icons.local_hospital),
                        label: const Text('Call 911'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _quickCall(_emergencyContacts[1].phone),
                        icon: const Icon(Icons.school),
                        label: const Text('Call School'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(EmergencyContact contact) {
    final color = _getContactColor(contact.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getContactIcon(contact.type),
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(contact.phone),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _quickCall(contact.phone),
              icon: const Icon(Icons.phone),
              style: IconButton.styleFrom(
                backgroundColor: color.withOpacity(0.1),
                foregroundColor: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getContactColor(ContactType type) {
    switch (type) {
      case ContactType.emergency:
        return AppColors.error;
      case ContactType.school:
        return AppColors.schoolAdminColor;
      case ContactType.driver:
        return AppColors.driverColor;
      case ContactType.family:
        return AppColors.parentColor;
    }
  }

  IconData _getContactIcon(ContactType type) {
    switch (type) {
      case ContactType.emergency:
        return Icons.local_hospital;
      case ContactType.school:
        return Icons.school;
      case ContactType.driver:
        return Icons.drive_eta;
      case ContactType.family:
        return Icons.family_restroom;
    }
  }

  void _activateSOS() {
    if (_isCountingDown) return;
    
    setState(() {
      _isCountingDown = true;
      _countdown = 5;
    });
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    _countdownController.forward();
    
    // Start countdown
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isCountingDown && mounted) {
        setState(() {
          _countdown--;
        });
        
        HapticFeedback.selectionClick();
        
        if (_countdown > 0) {
          _startCountdown();
        } else {
          _triggerSOS();
        }
      }
    });
  }

  void _cancelSOS() {
    setState(() {
      _isCountingDown = false;
      _isSOSActive = false;
      _countdown = 5;
    });
    
    _countdownController.reset();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency alert cancelled'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _triggerSOS() {
    setState(() {
      _isCountingDown = false;
      _isSOSActive = true;
    });
    
    // Continuous haptic feedback
    HapticFeedback.heavyImpact();
    
    // Show SOS triggered dialog
    _showSOSTriggeredDialog();
    
    // Send alerts to all emergency contacts
    _sendEmergencyAlerts();
  }

  void _showSOSTriggeredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emergency, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('SOS ACTIVATED'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Emergency alerts have been sent to:'),
            SizedBox(height: 16),
            Text('• Emergency Services (911)'),
            Text('• School Security'),
            Text('• Bus Driver'),
            Text('• Emergency Contacts'),
            SizedBox(height: 16),
            Text('Help is on the way!'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deactivateSOS();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('I\'m Safe Now'),
          ),
        ],
      ),
    );
  }

  void _sendEmergencyAlerts() {
    // Simulate sending alerts
    for (var contact in _emergencyContacts.where((c) => c.isDefault)) {
      _sendAlert(contact);
    }
  }

  void _sendAlert(EmergencyContact contact) {
    // Simulate sending alert
    print('Sending emergency alert to ${contact.name} at ${contact.phone}');
  }

  void _deactivateSOS() {
    setState(() {
      _isSOSActive = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS deactivated - Stay safe!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _quickCall(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showSOSSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SOS Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ListTile(
              leading: const Icon(Icons.contacts),
              title: const Text('Manage Emergency Contacts'),
              subtitle: const Text('Add, edit, or remove emergency contacts'),
              onTap: () {
                Navigator.pop(context);
                _manageEmergencyContacts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Countdown Duration'),
              subtitle: const Text('Change SOS activation countdown time'),
              onTap: () {
                Navigator.pop(context);
                _changeCountdownDuration();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Location Sharing'),
              subtitle: const Text('Configure automatic location sharing'),
              onTap: () {
                Navigator.pop(context);
                _configureLocationSharing();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _manageEmergencyContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency contacts management will be implemented')),
    );
  }

  void _changeCountdownDuration() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Countdown duration settings will be implemented')),
    );
  }

  void _configureLocationSharing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location sharing settings will be implemented')),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }
}

enum ContactType { emergency, school, driver, family }

class EmergencyContact {
  final String name;
  final String phone;
  final ContactType type;
  final bool isDefault;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.type,
    required this.isDefault,
  });
}
