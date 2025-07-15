import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class DriverSOSScreen extends StatefulWidget {
  const DriverSOSScreen({super.key});

  @override
  State<DriverSOSScreen> createState() => _DriverSOSScreenState();
}

class _DriverSOSScreenState extends State<DriverSOSScreen>
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
      name: 'Dispatch Center',
      phone: '+1 234 567 8900',
      type: ContactType.dispatch,
      isDefault: true,
    ),
    EmergencyContact(
      name: 'School Principal',
      phone: '+1 234 567 8901',
      type: ContactType.school,
      isDefault: true,
    ),
    EmergencyContact(
      name: 'Transportation Manager',
      phone: '+1 234 567 8902',
      type: ContactType.management,
      isDefault: true,
    ),
  ];

  final List<IncidentType> _incidentTypes = [
    IncidentType(
      id: 'medical',
      name: 'Medical Emergency',
      icon: Icons.medical_services,
      color: AppColors.error,
      description: 'Student or driver medical emergency',
    ),
    IncidentType(
      id: 'accident',
      name: 'Vehicle Accident',
      icon: Icons.car_crash,
      color: AppColors.error,
      description: 'Traffic accident or collision',
    ),
    IncidentType(
      id: 'breakdown',
      name: 'Vehicle Breakdown',
      icon: Icons.build,
      color: AppColors.warning,
      description: 'Mechanical failure or breakdown',
    ),
    IncidentType(
      id: 'behavior',
      name: 'Student Behavior',
      icon: Icons.warning,
      color: AppColors.warning,
      description: 'Disruptive or dangerous behavior',
    ),
    IncidentType(
      id: 'weather',
      name: 'Weather Emergency',
      icon: Icons.thunderstorm,
      color: AppColors.info,
      description: 'Severe weather conditions',
    ),
    IncidentType(
      id: 'security',
      name: 'Security Threat',
      icon: Icons.security,
      color: AppColors.error,
      description: 'Security or safety threat',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              children: [
                // Driver Info Card
                Card(
                  color: AppColors.driverColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.driverColor,
                          child: const Text(
                            'MW',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mike Wilson',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'Bus #001 • Route A • 12 Students',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                color: AppColors.success,
                                size: 8,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ON ROUTE',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // Warning Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                    border:
                        Border.all(color: AppColors.warning.withOpacity(0.3)),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                            ),
                            Text(
                              'This will immediately alert dispatch, school, and emergency services.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge * 2),

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
                              scale:
                                  _isCountingDown ? _scaleAnimation.value : 1.0,
                              child: GestureDetector(
                                onTap:
                                    _isCountingDown ? _cancelSOS : _activateSOS,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: _isSOSActive
                                        ? AppColors.error
                                        : AppColors.error.withOpacity(0.8),
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
                                        _isCountingDown
                                            ? Icons.cancel
                                            : Icons.emergency,
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
                      : 'Tap to activate emergency alert',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppConstants.paddingLarge * 2),

                // Quick Incident Buttons
                Text(
                  'Quick Incident Report',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppConstants.paddingMedium,
                    mainAxisSpacing: AppConstants.paddingMedium,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _incidentTypes.length,
                  itemBuilder: (context, index) {
                    final incident = _incidentTypes[index];
                    return _buildIncidentCard(incident);
                  },
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // Emergency Contacts
                Text(
                  'Emergency Contacts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                ..._emergencyContacts
                    .map((contact) => _buildEmergencyContactCard(contact)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentCard(IncidentType incident) {
    return Card(
      child: InkWell(
        onTap: () => _reportIncident(incident),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: incident.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  incident.icon,
                  color: incident.color,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                incident.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                incident.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
                  'AUTO',
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
      case ContactType.dispatch:
        return AppColors.driverColor;
      case ContactType.school:
        return AppColors.schoolAdminColor;
      case ContactType.management:
        return AppColors.info;
    }
  }

  IconData _getContactIcon(ContactType type) {
    switch (type) {
      case ContactType.emergency:
        return Icons.local_hospital;
      case ContactType.dispatch:
        return Icons.radio;
      case ContactType.school:
        return Icons.school;
      case ContactType.management:
        return Icons.business;
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
            Text('• Dispatch Center'),
            Text('• School Administration'),
            Text('• Transportation Manager'),
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
            child: const Text('Situation Resolved'),
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

  void _reportIncident(IncidentType incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report ${incident.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(incident.icon, color: incident.color, size: 48),
            const SizedBox(height: 16),
            Text(incident.description),
            const SizedBox(height: 16),
            const Text('This will notify dispatch and school administration.'),
          ],
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
                  content: Text('${incident.name} reported'),
                  backgroundColor: incident.color,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: incident.color),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _quickCall(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: AppColors.driverColor,
      ),
    );
  }

  void _showSOSSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS settings will be implemented')),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }
}

enum ContactType { emergency, dispatch, school, management }

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

class IncidentType {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  IncidentType({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}
