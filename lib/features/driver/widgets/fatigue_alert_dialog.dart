import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import 'fatigue_detection_system.dart';

class FatigueAlertDialog extends StatefulWidget {
  final FatigueAlert alert;
  final VoidCallback onDismiss;
  final VoidCallback onTakeBreak;
  final VoidCallback onContactSupervisor;

  const FatigueAlertDialog({
    super.key,
    required this.alert,
    required this.onDismiss,
    required this.onTakeBreak,
    required this.onContactSupervisor,
  });

  @override
  State<FatigueAlertDialog> createState() => _FatigueAlertDialogState();
}

class _FatigueAlertDialogState extends State<FatigueAlertDialog>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isAcknowledged = false;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _shakeAnimation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start shaking for critical alerts
    if (widget.alert.level == FatigueLevel.critical) {
      _shakeController.repeat();
      _startCountdown();
    }

    // Vibrate device
    _vibrateDevice();
  }

  void _vibrateDevice() {
    switch (widget.alert.level) {
      case FatigueLevel.low:
        HapticFeedback.lightImpact();
        break;
      case FatigueLevel.moderate:
        HapticFeedback.mediumImpact();
        break;
      case FatigueLevel.high:
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 200), () {
          HapticFeedback.heavyImpact();
        });
        break;
      case FatigueLevel.critical:
        for (int i = 0; i < 3; i++) {
          Future.delayed(Duration(milliseconds: i * 300), () {
            HapticFeedback.heavyImpact();
          });
        }
        break;
      case FatigueLevel.normal:
        break;
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _isAcknowledged,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: _buildAlertContent(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlertContent() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getAlertColor(),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: _getAlertColor().withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Alert Header
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getAlertColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getAlertIcon(),
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Alert Title
          Text(
            _getAlertTitle(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _getAlertColor(),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Fatigue Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getAlertColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Fatigue Score: ${(widget.alert.score * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getAlertColor(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Alert Message
          Text(
            _getAlertMessage(),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Fatigue Indicators
          _buildFatigueIndicators(),
          const SizedBox(height: 20),

          // Recommendations
          _buildRecommendations(),
          const SizedBox(height: 24),

          // Countdown for critical alerts
          if (widget.alert.level == FatigueLevel.critical &&
              _countdown > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Auto-action in $_countdown seconds',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFatigueIndicators() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detected Indicators:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildIndicator(
                  'Blinks',
                  widget.alert.indicators.blinkCount.toString(),
                  Icons.visibility),
              _buildIndicator(
                  'Yawns',
                  widget.alert.indicators.yawnCount.toString(),
                  Icons.sentiment_very_dissatisfied),
              _buildIndicator(
                  'Head Nods',
                  widget.alert.indicators.headNodCount.toString(),
                  Icons.accessibility),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildIndicator(
                  'Eye Closure',
                  '${widget.alert.indicators.eyeClosureDuration.toStringAsFixed(1)}s',
                  Icons.remove_red_eye),
              _buildIndicator(
                  'Drive Time',
                  '${widget.alert.indicators.drivingTime.toStringAsFixed(0)}m',
                  Icons.access_time),
              _buildIndicator(
                  'Steering',
                  widget.alert.indicators.steeringVariability
                      .toStringAsFixed(1),
                  Icons.drive_eta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.info),
              SizedBox(width: 8),
              Text(
                'Recommendations:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.alert.recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.info)),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.alert.level == FatigueLevel.critical) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isAcknowledged = true;
                });
                widget.onContactSupervisor();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.phone),
              label: const Text('Contact Supervisor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isAcknowledged = true;
              });
              widget.onTakeBreak();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.pause),
            label: Text(widget.alert.level == FatigueLevel.critical
                ? 'Stop Driving'
                : 'Take Break'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getAlertColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (widget.alert.level != FatigueLevel.critical) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isAcknowledged = true;
                });
                widget.onDismiss();
                Navigator.of(context).pop();
              },
              child: const Text('I\'m Alert - Continue'),
            ),
          ),
        ],
      ],
    );
  }

  Color _getAlertColor() {
    switch (widget.alert.level) {
      case FatigueLevel.low:
        return AppColors.info;
      case FatigueLevel.moderate:
        return AppColors.warning;
      case FatigueLevel.high:
        return AppColors.error;
      case FatigueLevel.critical:
        return Colors.red[900]!;
      case FatigueLevel.normal:
        return AppColors.success;
    }
  }

  IconData _getAlertIcon() {
    switch (widget.alert.level) {
      case FatigueLevel.low:
        return Icons.info;
      case FatigueLevel.moderate:
        return Icons.warning;
      case FatigueLevel.high:
        return Icons.error;
      case FatigueLevel.critical:
        return Icons.dangerous;
      case FatigueLevel.normal:
        return Icons.check_circle;
    }
  }

  String _getAlertTitle() {
    switch (widget.alert.level) {
      case FatigueLevel.low:
        return 'Fatigue Detected';
      case FatigueLevel.moderate:
        return 'Moderate Fatigue';
      case FatigueLevel.high:
        return 'High Fatigue Alert';
      case FatigueLevel.critical:
        return 'CRITICAL FATIGUE';
      case FatigueLevel.normal:
        return 'All Good';
    }
  }

  String _getAlertMessage() {
    switch (widget.alert.level) {
      case FatigueLevel.low:
        return 'Early signs of fatigue detected. Consider taking a short break to stay alert.';
      case FatigueLevel.moderate:
        return 'Moderate fatigue levels detected. It\'s recommended to take a break soon.';
      case FatigueLevel.high:
        return 'High fatigue levels detected. You should take a break immediately for safety.';
      case FatigueLevel.critical:
        return 'CRITICAL fatigue levels detected. Stop driving immediately for your safety and the safety of passengers.';
      case FatigueLevel.normal:
        return 'You\'re alert and ready to drive safely.';
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
