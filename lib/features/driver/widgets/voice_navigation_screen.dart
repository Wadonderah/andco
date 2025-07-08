import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class VoiceNavigationScreen extends StatefulWidget {
  const VoiceNavigationScreen({super.key});

  @override
  State<VoiceNavigationScreen> createState() => _VoiceNavigationScreenState();
}

class _VoiceNavigationScreenState extends State<VoiceNavigationScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isNavigationActive = false;
  bool _isVoiceEnabled = true;
  bool _isMuted = false;
  double _voiceVolume = 0.8;
  String _selectedVoice = 'Female Voice 1';
  
  final List<NavigationInstruction> _currentInstructions = [
    NavigationInstruction(
      id: '1',
      instruction: 'In 500 meters, turn right onto Oak Avenue',
      distance: '500 m',
      direction: TurnDirection.right,
      streetName: 'Oak Avenue',
      isNext: true,
    ),
    NavigationInstruction(
      id: '2',
      instruction: 'Continue straight for 1.2 kilometers',
      distance: '1.2 km',
      direction: TurnDirection.straight,
      streetName: 'Oak Avenue',
      isNext: false,
    ),
    NavigationInstruction(
      id: '3',
      instruction: 'Turn left onto Pine Road',
      distance: '1.8 km',
      direction: TurnDirection.left,
      streetName: 'Pine Road',
      isNext: false,
    ),
  ];

  final List<String> _voiceOptions = [
    'Female Voice 1',
    'Female Voice 2',
    'Male Voice 1',
    'Male Voice 2',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (_isNavigationActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Navigation'),
        backgroundColor: AppColors.driverColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showNavigationSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation Status Card
            Card(
              color: _isNavigationActive 
                  ? AppColors.success.withOpacity(0.1) 
                  : AppColors.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isNavigationActive ? _pulseAnimation.value : 1.0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isNavigationActive 
                                  ? AppColors.success 
                                  : AppColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isNavigationActive ? Icons.navigation : Icons.navigation_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isNavigationActive ? 'Navigation Active' : 'Navigation Ready',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isNavigationActive ? AppColors.success : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _isNavigationActive 
                                ? 'Route A • 3 stops remaining'
                                : 'Tap to start voice-guided navigation',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _toggleNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isNavigationActive ? AppColors.error : AppColors.success,
                      ),
                      child: Text(_isNavigationActive ? 'Stop' : 'Start'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Voice Controls
            Text(
              'Voice Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  children: [
                    // Voice Enable/Disable
                    SwitchListTile(
                      title: const Text('Voice Guidance'),
                      subtitle: const Text('Enable spoken turn-by-turn directions'),
                      value: _isVoiceEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isVoiceEnabled = value;
                        });
                      },
                      activeColor: AppColors.driverColor,
                      secondary: const Icon(Icons.record_voice_over),
                    ),

                    const Divider(),

                    // Mute Toggle
                    SwitchListTile(
                      title: const Text('Mute Voice'),
                      subtitle: const Text('Temporarily mute voice instructions'),
                      value: _isMuted,
                      onChanged: _isVoiceEnabled ? (value) {
                        setState(() {
                          _isMuted = value;
                        });
                      } : null,
                      activeColor: AppColors.warning,
                      secondary: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                    ),

                    const Divider(),

                    // Volume Control
                    ListTile(
                      leading: const Icon(Icons.volume_up),
                      title: const Text('Voice Volume'),
                      subtitle: Slider(
                        value: _voiceVolume,
                        onChanged: _isVoiceEnabled && !_isMuted ? (value) {
                          setState(() {
                            _voiceVolume = value;
                          });
                        } : null,
                        activeColor: AppColors.driverColor,
                        divisions: 10,
                        label: '${(_voiceVolume * 100).round()}%',
                      ),
                    ),

                    const Divider(),

                    // Voice Selection
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Voice Type'),
                      subtitle: Text(_selectedVoice),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showVoiceSelection,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Current Instructions
            if (_isNavigationActive) ...[
              Text(
                'Current Instructions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              ..._currentInstructions.map((instruction) => _buildInstructionCard(instruction)).toList(),

              const SizedBox(height: AppConstants.paddingLarge),
            ],

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Repeat Instruction',
                    Icons.replay,
                    AppColors.info,
                    _repeatInstruction,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _buildQuickActionCard(
                    'Skip Instruction',
                    Icons.skip_next,
                    AppColors.warning,
                    _skipInstruction,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Report Issue',
                    Icons.report_problem,
                    AppColors.error,
                    _reportNavigationIssue,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _buildQuickActionCard(
                    'Alternative Route',
                    Icons.alt_route,
                    AppColors.success,
                    _findAlternativeRoute,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Test Voice Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testVoice,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Test Voice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.driverColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(NavigationInstruction instruction) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      color: instruction.isNext ? AppColors.driverColor.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getDirectionColor(instruction.direction).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getDirectionIcon(instruction.direction),
                color: _getDirectionColor(instruction.direction),
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instruction.instruction,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: instruction.isNext ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instruction.streetName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  instruction.distance,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: instruction.isNext ? AppColors.driverColor : AppColors.textSecondary,
                  ),
                ),
                if (instruction.isNext)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.driverColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'NEXT',
                      style: TextStyle(
                        color: AppColors.driverColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDirectionIcon(TurnDirection direction) {
    switch (direction) {
      case TurnDirection.left:
        return Icons.turn_left;
      case TurnDirection.right:
        return Icons.turn_right;
      case TurnDirection.straight:
        return Icons.straight;
      case TurnDirection.uTurn:
        return Icons.u_turn_left;
    }
  }

  Color _getDirectionColor(TurnDirection direction) {
    switch (direction) {
      case TurnDirection.left:
        return AppColors.info;
      case TurnDirection.right:
        return AppColors.success;
      case TurnDirection.straight:
        return AppColors.driverColor;
      case TurnDirection.uTurn:
        return AppColors.warning;
    }
  }

  void _toggleNavigation() {
    setState(() {
      _isNavigationActive = !_isNavigationActive;
    });

    if (_isNavigationActive) {
      _pulseController.repeat(reverse: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice navigation started'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      _pulseController.stop();
      _pulseController.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice navigation stopped'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _showVoiceSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Voice Type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ..._voiceOptions.map((voice) => 
              ListTile(
                title: Text(voice),
                trailing: _selectedVoice == voice 
                    ? const Icon(Icons.check, color: AppColors.driverColor) 
                    : null,
                onTap: () {
                  setState(() => _selectedVoice = voice);
                  Navigator.pop(context);
                },
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  void _showNavigationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation settings will be implemented')),
    );
  }

  void _testVoice() {
    if (!_isVoiceEnabled || _isMuted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice is disabled or muted'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing test voice: "$_selectedVoice" at ${(_voiceVolume * 100).round()}% volume'),
        backgroundColor: AppColors.driverColor,
      ),
    );
  }

  void _repeatInstruction() {
    if (_currentInstructions.isNotEmpty) {
      final nextInstruction = _currentInstructions.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Repeating: ${nextInstruction.instruction}')),
      );
    }
  }

  void _skipInstruction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skipping current instruction'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _reportNavigationIssue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation issue reporting will be implemented')),
    );
  }

  void _findAlternativeRoute() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finding alternative route...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

enum TurnDirection { left, right, straight, uTurn }

class NavigationInstruction {
  final String id;
  final String instruction;
  final String distance;
  final TurnDirection direction;
  final String streetName;
  final bool isNext;

  NavigationInstruction({
    required this.id,
    required this.instruction,
    required this.distance,
    required this.direction,
    required this.streetName,
    required this.isNext,
  });
}
