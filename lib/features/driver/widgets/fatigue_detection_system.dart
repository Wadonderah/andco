import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class FatigueDetectionSystem extends StatefulWidget {
  final Function(FatigueAlert) onFatigueDetected;
  final bool isEnabled;

  const FatigueDetectionSystem({
    super.key,
    required this.onFatigueDetected,
    this.isEnabled = true,
  });

  @override
  State<FatigueDetectionSystem> createState() => _FatigueDetectionSystemState();
}

class _FatigueDetectionSystemState extends State<FatigueDetectionSystem>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  Timer? _analysisTimer;
  Timer? _behaviorTimer;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  FatigueLevel _currentFatigueLevel = FatigueLevel.normal;
  bool _isAnalyzing = false;
  bool _cameraInitialized = false;
  
  // Fatigue detection metrics
  int _blinkCount = 0;
  int _yawnCount = 0;
  int _headNodCount = 0;
  double _eyeClosureDuration = 0.0;
  double _drivingTime = 0.0;
  double _lastAlertTime = 0.0;
  
  // Behavioral analysis
  List<double> _accelerometerData = [];
  List<double> _gyroscopeData = [];
  double _steeringVariability = 0.0;
  double _speedVariability = 0.0;
  
  // AI model simulation data
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isEnabled) {
      _initializeFatigueDetection();
    }
  }

  Future<void> _initializeFatigueDetection() async {
    await _initializeCamera();
    _startSensorMonitoring();
    _startFatigueAnalysis();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Use front camera for driver monitoring
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        
        setState(() {
          _cameraInitialized = true;
        });
        
        debugPrint('Fatigue detection camera initialized');
      }
    } catch (e) {
      debugPrint('Failed to initialize fatigue detection camera: $e');
    }
  }

  void _startSensorMonitoring() {
    // Monitor accelerometer for sudden movements
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      _accelerometerData.add(sqrt(event.x * event.x + event.y * event.y + event.z * event.z));
      if (_accelerometerData.length > 100) {
        _accelerometerData.removeAt(0);
      }
    });
    
    // Monitor gyroscope for head movements
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      _gyroscopeData.add(sqrt(event.x * event.x + event.y * event.y + event.z * event.z));
      if (_gyroscopeData.length > 100) {
        _gyroscopeData.removeAt(0);
      }
    });
    
    // Analyze behavioral patterns every 5 seconds
    _behaviorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _analyzeBehavioralPatterns();
    });
  }

  void _startFatigueAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_cameraInitialized && widget.isEnabled) {
        _performFatigueAnalysis();
      }
    });
  }

  void _performFatigueAnalysis() {
    setState(() {
      _isAnalyzing = true;
      _drivingTime += 2.0 / 60.0; // Add 2 seconds in minutes
    });
    
    // Simulate AI-based fatigue detection
    _simulateEyeDetection();
    _simulateYawnDetection();
    _simulateHeadPoseAnalysis();
    
    // Calculate fatigue score
    final fatigueScore = _calculateFatigueScore();
    final newFatigueLevel = _determineFatigueLevel(fatigueScore);
    
    if (newFatigueLevel != _currentFatigueLevel) {
      setState(() {
        _currentFatigueLevel = newFatigueLevel;
      });
      
      if (_currentFatigueLevel != FatigueLevel.normal) {
        _triggerFatigueAlert(fatigueScore);
      }
    }
    
    setState(() {
      _isAnalyzing = false;
    });
  }

  void _simulateEyeDetection() {
    // Simulate eye closure detection
    final eyeClosureProb = _random.nextDouble();
    if (eyeClosureProb > 0.85) {
      _eyeClosureDuration += 2.0;
      if (_eyeClosureDuration > 3.0) {
        _blinkCount++;
        _eyeClosureDuration = 0.0;
      }
    } else {
      _eyeClosureDuration = 0.0;
    }
  }

  void _simulateYawnDetection() {
    // Simulate yawn detection
    final yawnProb = _random.nextDouble();
    if (yawnProb > 0.95) {
      _yawnCount++;
    }
  }

  void _simulateHeadPoseAnalysis() {
    // Simulate head nodding detection
    if (_gyroscopeData.isNotEmpty) {
      final avgGyro = _gyroscopeData.reduce((a, b) => a + b) / _gyroscopeData.length;
      if (avgGyro > 2.0) {
        _headNodCount++;
      }
    }
  }

  void _analyzeBehavioralPatterns() {
    if (_accelerometerData.isNotEmpty) {
      // Calculate steering variability (simulated)
      final avgAccel = _accelerometerData.reduce((a, b) => a + b) / _accelerometerData.length;
      _steeringVariability = _accelerometerData.map((x) => (x - avgAccel).abs()).reduce((a, b) => a + b) / _accelerometerData.length;
    }
    
    // Simulate speed variability
    _speedVariability = _random.nextDouble() * 5.0;
  }

  double _calculateFatigueScore() {
    double score = 0.0;
    
    // Eye-based indicators (40% weight)
    score += (_blinkCount > 20 ? 0.4 : _blinkCount / 50.0 * 0.4);
    score += (_eyeClosureDuration > 2.0 ? 0.3 : _eyeClosureDuration / 5.0 * 0.3);
    
    // Yawn detection (20% weight)
    score += (_yawnCount > 3 ? 0.2 : _yawnCount / 10.0 * 0.2);
    
    // Head pose (15% weight)
    score += (_headNodCount > 5 ? 0.15 : _headNodCount / 20.0 * 0.15);
    
    // Driving time (15% weight)
    score += (_drivingTime > 120 ? 0.15 : _drivingTime / 240.0 * 0.15);
    
    // Behavioral patterns (10% weight)
    score += (_steeringVariability > 2.0 ? 0.1 : _steeringVariability / 5.0 * 0.1);
    
    return score.clamp(0.0, 1.0);
  }

  FatigueLevel _determineFatigueLevel(double score) {
    if (score >= 0.8) return FatigueLevel.critical;
    if (score >= 0.6) return FatigueLevel.high;
    if (score >= 0.4) return FatigueLevel.moderate;
    if (score >= 0.2) return FatigueLevel.low;
    return FatigueLevel.normal;
  }

  void _triggerFatigueAlert(double fatigueScore) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Prevent alert spam
    if (now - _lastAlertTime < 30) return;
    
    _lastAlertTime = now;
    
    final alert = FatigueAlert(
      level: _currentFatigueLevel,
      score: fatigueScore,
      timestamp: DateTime.now(),
      indicators: FatigueIndicators(
        blinkCount: _blinkCount,
        yawnCount: _yawnCount,
        headNodCount: _headNodCount,
        eyeClosureDuration: _eyeClosureDuration,
        drivingTime: _drivingTime,
        steeringVariability: _steeringVariability,
      ),
      recommendations: _generateRecommendations(),
    );
    
    widget.onFatigueDetected(alert);
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    
    switch (_currentFatigueLevel) {
      case FatigueLevel.low:
        recommendations.addAll([
          'Take a 5-minute break',
          'Drink some water',
          'Adjust your seating position',
        ]);
        break;
      
      case FatigueLevel.moderate:
        recommendations.addAll([
          'Take a 15-minute break',
          'Get some fresh air',
          'Do light stretching exercises',
          'Consider switching drivers',
        ]);
        break;
      
      case FatigueLevel.high:
        recommendations.addAll([
          'Take a 30-minute break immediately',
          'Find a safe place to rest',
          'Contact supervisor',
          'Do not continue driving',
        ]);
        break;
      
      case FatigueLevel.critical:
        recommendations.addAll([
          'STOP DRIVING IMMEDIATELY',
          'Pull over safely',
          'Contact emergency services if needed',
          'Arrange alternative transportation',
        ]);
        break;
      
      case FatigueLevel.normal:
        break;
    }
    
    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: _getFatigueColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: _getFatigueColor()),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isAnalyzing ? _pulseAnimation.value : 1.0,
                    child: Icon(
                      Icons.visibility,
                      color: _getFatigueColor(),
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fatigue Detection: ${_currentFatigueLevel.displayName}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getFatigueColor(),
                      ),
                    ),
                    Text(
                      'Driving time: ${_drivingTime.toStringAsFixed(0)} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isAnalyzing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          
          if (_currentFatigueLevel != FatigueLevel.normal) ...[
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              children: [
                _buildMetric('Blinks', _blinkCount.toString()),
                _buildMetric('Yawns', _yawnCount.toString()),
                _buildMetric('Head Nods', _headNodCount.toString()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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

  Color _getFatigueColor() {
    switch (_currentFatigueLevel) {
      case FatigueLevel.normal:
        return AppColors.success;
      case FatigueLevel.low:
        return AppColors.info;
      case FatigueLevel.moderate:
        return AppColors.warning;
      case FatigueLevel.high:
        return AppColors.error;
      case FatigueLevel.critical:
        return Colors.red[900]!;
    }
  }

  void resetDetection() {
    setState(() {
      _blinkCount = 0;
      _yawnCount = 0;
      _headNodCount = 0;
      _eyeClosureDuration = 0.0;
      _drivingTime = 0.0;
      _currentFatigueLevel = FatigueLevel.normal;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _analysisTimer?.cancel();
    _behaviorTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }
}

// Data Models
enum FatigueLevel {
  normal('Normal'),
  low('Low Fatigue'),
  moderate('Moderate Fatigue'),
  high('High Fatigue'),
  critical('Critical Fatigue');

  const FatigueLevel(this.displayName);
  final String displayName;
}

class FatigueAlert {
  final FatigueLevel level;
  final double score;
  final DateTime timestamp;
  final FatigueIndicators indicators;
  final List<String> recommendations;

  FatigueAlert({
    required this.level,
    required this.score,
    required this.timestamp,
    required this.indicators,
    required this.recommendations,
  });
}

class FatigueIndicators {
  final int blinkCount;
  final int yawnCount;
  final int headNodCount;
  final double eyeClosureDuration;
  final double drivingTime;
  final double steeringVariability;

  FatigueIndicators({
    required this.blinkCount,
    required this.yawnCount,
    required this.headNodCount,
    required this.eyeClosureDuration,
    required this.drivingTime,
    required this.steeringVariability,
  });
}
