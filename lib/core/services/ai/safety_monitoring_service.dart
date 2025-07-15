import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'base_ai_service.dart';

/// Predictive Safety Agent using device sensors and ML algorithms
class SafetyMonitoringService extends BaseAIService
    with RateLimitMixin, CacheMixin<SafetyAnalysisResult> {
  AIServiceStatus _status = AIServiceStatus.uninitialized;
  bool _isEnabled = true;
  bool _isInitialized = false;
  SafetyMonitoringConfig _config = const SafetyMonitoringConfig();

  // Sensor data streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _locationSubscription;

  // Safety monitoring data
  final List<SensorReading> _sensorHistory = [];
  final List<DrivingEvent> _drivingEvents = [];
  SafetyScore? _currentSafetyScore;

  // ML model for anomaly detection
  late AnomalyDetectionModel _anomalyModel;

  @override
  String get serviceName => 'Predictive Safety Agent';

  @override
  bool get isEnabled => _isEnabled;

  @override
  bool get isInitialized => _isInitialized;

  @override
  AIServiceStatus get status => _status;

  @override
  Future<void> initialize({Map<String, dynamic>? config}) async {
    try {
      _status = AIServiceStatus.initializing;

      if (config != null) {
        _config = SafetyMonitoringConfig.fromJson(config);
      }

      // Initialize ML model for anomaly detection
      _anomalyModel = AnomalyDetectionModel();
      await _anomalyModel.initialize();

      // Set up caching
      setCacheConfig(const CacheConfig(
        enabled: true,
        cacheDuration: Duration(minutes: 5),
        maxCacheSize: 20,
        persistCache: false,
      ));

      // Load historical safety data
      await _loadHistoricalData();

      _isInitialized = true;
      _status = AIServiceStatus.ready;

      debugPrint('✅ Safety Monitoring Service initialized');
    } catch (e) {
      _status = AIServiceStatus.error;
      debugPrint('❌ Failed to initialize Safety Monitoring Service: $e');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await _stopMonitoring();
    _sensorHistory.clear();
    _drivingEvents.clear();
    clearCache();
    _isInitialized = false;
    _status = AIServiceStatus.uninitialized;
  }

  @override
  Future<void> enable() async {
    _isEnabled = true;
    if (_isInitialized) {
      _status = AIServiceStatus.ready;
    }
  }

  @override
  Future<void> disable() async {
    _isEnabled = false;
    await _stopMonitoring();
    _status = AIServiceStatus.disabled;
  }

  @override
  Future<AIServiceHealth> getHealthStatus() async {
    final isHealthy =
        _isEnabled && _isInitialized && _status != AIServiceStatus.error;

    return AIServiceHealth(
      serviceName: serviceName,
      status: _status,
      isHealthy: isHealthy,
      lastCheck: DateTime.now(),
      metrics: {
        'sensorReadings': _sensorHistory.length,
        'drivingEvents': _drivingEvents.length,
        'currentSafetyScore': _currentSafetyScore?.overallScore ?? 0.0,
        'isMonitoring': _accelerometerSubscription != null,
      },
    );
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return _config.toJson();
  }

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    _config = SafetyMonitoringConfig.fromJson(config);
  }

  @override
  Future<void> reset() async {
    _sensorHistory.clear();
    _drivingEvents.clear();
    _currentSafetyScore = null;
    clearCache();
    _status = AIServiceStatus.ready;
  }

  /// Start safety monitoring
  Future<void> startMonitoring() async {
    if (!_isEnabled || !_isInitialized) {
      throw AIServiceException('Service not available');
    }

    try {
      _status = AIServiceStatus.running;

      // Start accelerometer monitoring
      _accelerometerSubscription = accelerometerEvents.listen(
        _onAccelerometerEvent,
        onError: (error) => debugPrint('Accelerometer error: $error'),
      );

      // Start gyroscope monitoring
      _gyroscopeSubscription = gyroscopeEvents.listen(
        _onGyroscopeEvent,
        onError: (error) => debugPrint('Gyroscope error: $error'),
      );

      // Start location monitoring
      _startLocationMonitoring();

      debugPrint('🔍 Safety monitoring started');
    } catch (e) {
      _status = AIServiceStatus.error;
      debugPrint('❌ Failed to start safety monitoring: $e');
      rethrow;
    }
  }

  /// Stop safety monitoring
  Future<void> _stopMonitoring() async {
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    await _locationSubscription?.cancel();

    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _locationSubscription = null;

    if (_status == AIServiceStatus.running) {
      _status = AIServiceStatus.ready;
    }

    debugPrint('🛑 Safety monitoring stopped');
  }

  /// Start location monitoring for speed and route analysis
  void _startLocationMonitoring() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onLocationUpdate,
      onError: (error) => debugPrint('Location error: $error'),
    );
  }

  /// Handle accelerometer events
  void _onAccelerometerEvent(AccelerometerEvent event) {
    final reading = SensorReading(
      type: SensorType.accelerometer,
      x: event.x,
      y: event.y,
      z: event.z,
      timestamp: DateTime.now(),
    );

    _addSensorReading(reading);
    _analyzeAcceleration(reading);
  }

  /// Handle gyroscope events
  void _onGyroscopeEvent(GyroscopeEvent event) {
    final reading = SensorReading(
      type: SensorType.gyroscope,
      x: event.x,
      y: event.y,
      z: event.z,
      timestamp: DateTime.now(),
    );

    _addSensorReading(reading);
    _analyzeRotation(reading);
  }

  /// Handle location updates
  void _onLocationUpdate(Position position) {
    _analyzeSpeed(position);
    _analyzeLocation(position);
  }

  /// Add sensor reading to history
  void _addSensorReading(SensorReading reading) {
    _sensorHistory.add(reading);

    // Keep only recent readings (last 5 minutes)
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    _sensorHistory.removeWhere((r) => r.timestamp.isBefore(cutoff));
  }

  /// Analyze acceleration data for harsh events
  void _analyzeAcceleration(SensorReading reading) {
    final magnitude = sqrt(
        reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);

    // Detect harsh acceleration/braking (threshold: 2.5 m/s²)
    if (magnitude > _config.harshAccelerationThreshold) {
      final event = DrivingEvent(
        type: DrivingEventType.harshAcceleration,
        severity:
            _calculateSeverity(magnitude, _config.harshAccelerationThreshold),
        timestamp: reading.timestamp,
        sensorData: reading,
        description:
            'Harsh acceleration detected: ${magnitude.toStringAsFixed(2)} m/s²',
      );

      _addDrivingEvent(event);
    }

    // Detect sudden stops (negative acceleration)
    if (reading.y < -_config.harshBrakingThreshold) {
      final event = DrivingEvent(
        type: DrivingEventType.harshBraking,
        severity:
            _calculateSeverity(reading.y.abs(), _config.harshBrakingThreshold),
        timestamp: reading.timestamp,
        sensorData: reading,
        description:
            'Harsh braking detected: ${reading.y.toStringAsFixed(2)} m/s²',
      );

      _addDrivingEvent(event);
    }
  }

  /// Analyze rotation data for sharp turns
  void _analyzeRotation(SensorReading reading) {
    final magnitude = sqrt(
        reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);

    // Detect sharp turns (threshold: 1.5 rad/s)
    if (magnitude > _config.sharpTurnThreshold) {
      final event = DrivingEvent(
        type: DrivingEventType.sharpTurn,
        severity: _calculateSeverity(magnitude, _config.sharpTurnThreshold),
        timestamp: reading.timestamp,
        sensorData: reading,
        description:
            'Sharp turn detected: ${magnitude.toStringAsFixed(2)} rad/s',
      );

      _addDrivingEvent(event);
    }
  }

  /// Analyze speed for speeding violations
  void _analyzeSpeed(Position position) {
    final speedKmh = position.speed * 3.6; // Convert m/s to km/h

    // Check for speeding (configurable speed limit)
    if (speedKmh > _config.speedLimitKmh) {
      final event = DrivingEvent(
        type: DrivingEventType.speeding,
        severity: _calculateSeverity(speedKmh, _config.speedLimitKmh),
        timestamp: DateTime.now(),
        locationData: position,
        description: 'Speeding detected: ${speedKmh.toStringAsFixed(1)} km/h',
      );

      _addDrivingEvent(event);
    }
  }

  /// Analyze location for route deviations
  void _analyzeLocation(Position position) {
    // This would integrate with route data to detect deviations
    // For now, we'll implement a basic geofencing check

    // Check if outside designated school zones (placeholder)
    if (_isOutsideDesignatedArea(position)) {
      final event = DrivingEvent(
        type: DrivingEventType.routeDeviation,
        severity: EventSeverity.medium,
        timestamp: DateTime.now(),
        locationData: position,
        description: 'Route deviation detected',
      );

      _addDrivingEvent(event);
    }
  }

  /// Add driving event and trigger analysis
  void _addDrivingEvent(DrivingEvent event) {
    _drivingEvents.add(event);

    // Keep only recent events (last 24 hours)
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _drivingEvents.removeWhere((e) => e.timestamp.isBefore(cutoff));

    // Trigger real-time safety analysis
    _performRealTimeSafetyAnalysis();

    // Save to persistent storage
    _saveDrivingEvent(event);
  }

  /// Perform real-time safety analysis
  void _performRealTimeSafetyAnalysis() {
    final recentEvents = _drivingEvents
        .where(
          (e) =>
              DateTime.now().difference(e.timestamp) <
              const Duration(minutes: 30),
        )
        .toList();

    // Use ML model for anomaly detection
    final anomalyScore = _anomalyModel.detectAnomalies(_sensorHistory);

    // Calculate current safety score
    _currentSafetyScore = _calculateSafetyScore(recentEvents, anomalyScore);

    // Trigger alerts if necessary
    if (_currentSafetyScore!.overallScore < _config.criticalSafetyThreshold) {
      _triggerSafetyAlert(_currentSafetyScore!);
    }
  }

  /// Calculate safety score based on recent events and ML analysis
  SafetyScore _calculateSafetyScore(
      List<DrivingEvent> recentEvents, double anomalyScore) {
    double baseScore = 100.0;

    // Deduct points for each event type
    for (final event in recentEvents) {
      switch (event.type) {
        case DrivingEventType.harshAcceleration:
          baseScore -= event.severity.index * 5;
          break;
        case DrivingEventType.harshBraking:
          baseScore -= event.severity.index * 7;
          break;
        case DrivingEventType.sharpTurn:
          baseScore -= event.severity.index * 4;
          break;
        case DrivingEventType.speeding:
          baseScore -= event.severity.index * 10;
          break;
        case DrivingEventType.routeDeviation:
          baseScore -= event.severity.index * 3;
          break;
        case DrivingEventType.anomaly:
          baseScore -= event.severity.index * 8;
          break;
      }
    }

    // Factor in ML anomaly score
    baseScore -= anomalyScore * 20;

    // Ensure score is within bounds
    baseScore = baseScore.clamp(0.0, 100.0);

    return SafetyScore(
      overallScore: baseScore,
      accelerationScore: _calculateComponentScore(
          recentEvents, DrivingEventType.harshAcceleration),
      brakingScore:
          _calculateComponentScore(recentEvents, DrivingEventType.harshBraking),
      turningScore:
          _calculateComponentScore(recentEvents, DrivingEventType.sharpTurn),
      speedScore:
          _calculateComponentScore(recentEvents, DrivingEventType.speeding),
      routeScore: _calculateComponentScore(
          recentEvents, DrivingEventType.routeDeviation),
      anomalyScore: (1.0 - anomalyScore) * 100,
      timestamp: DateTime.now(),
    );
  }

  /// Calculate component-specific safety score
  double _calculateComponentScore(
      List<DrivingEvent> events, DrivingEventType type) {
    final typeEvents = events.where((e) => e.type == type).toList();
    if (typeEvents.isEmpty) return 100.0;

    double score = 100.0;
    for (final event in typeEvents) {
      score -= event.severity.index * 10;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Calculate event severity
  EventSeverity _calculateSeverity(double value, double threshold) {
    final ratio = value / threshold;

    if (ratio < 1.5) return EventSeverity.low;
    if (ratio < 2.0) return EventSeverity.medium;
    if (ratio < 3.0) return EventSeverity.high;
    return EventSeverity.critical;
  }

  /// Check if position is outside designated area
  bool _isOutsideDesignatedArea(Position position) {
    // Placeholder implementation
    // In a real app, this would check against predefined geofences
    return false;
  }

  /// Trigger safety alert
  void _triggerSafetyAlert(SafetyScore safetyScore) {
    debugPrint('🚨 Safety alert triggered: Score ${safetyScore.overallScore}');

    // This would integrate with the notification system
    // For now, we'll just log the alert
  }

  /// Load historical safety data
  Future<void> _loadHistoricalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString('safety_events');

      if (eventsJson != null) {
        final eventsList = json.decode(eventsJson) as List;
        _drivingEvents.addAll(
          eventsList.map((e) => DrivingEvent.fromJson(e)).toList(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load historical safety data: $e');
    }
  }

  /// Save driving event to persistent storage
  Future<void> _saveDrivingEvent(DrivingEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = _drivingEvents.map((e) => e.toJson()).toList();
      await prefs.setString('safety_events', json.encode(eventsJson));
    } catch (e) {
      debugPrint('⚠️ Failed to save driving event: $e');
    }
  }

  /// Get safety analysis for a specific time period
  Future<AIServiceResult<SafetyAnalysisResult>> getSafetyAnalysis({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      if (!_isEnabled || !_isInitialized) {
        return AIServiceResult.failure('Service not available');
      }

      final start =
          startTime ?? DateTime.now().subtract(const Duration(hours: 24));
      final end = endTime ?? DateTime.now();

      final cacheKey =
          '${start.millisecondsSinceEpoch}_${end.millisecondsSinceEpoch}';

      // Check cache
      final cached = getCached(cacheKey);
      if (cached != null) {
        return AIServiceResult.success(cached);
      }

      // Filter events by time period
      final periodEvents = _drivingEvents
          .where(
            (e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end),
          )
          .toList();

      // Generate analysis
      final analysis = SafetyAnalysisResult(
        timeRange: DateTimeRange(start: start, end: end),
        totalEvents: periodEvents.length,
        eventsByType: _groupEventsByType(periodEvents),
        safetyScore: _currentSafetyScore ?? SafetyScore.defaultScore(),
        recommendations: _generateSafetyRecommendations(periodEvents),
        trends: _analyzeSafetyTrends(periodEvents),
        timestamp: DateTime.now(),
      );

      // Cache the result
      setCached(cacheKey, analysis);

      return AIServiceResult.success(analysis);
    } catch (e) {
      debugPrint('❌ Safety analysis failed: $e');
      return AIServiceResult.failure(e.toString());
    }
  }

  /// Group events by type for analysis
  Map<DrivingEventType, int> _groupEventsByType(List<DrivingEvent> events) {
    final grouped = <DrivingEventType, int>{};

    for (final event in events) {
      grouped[event.type] = (grouped[event.type] ?? 0) + 1;
    }

    return grouped;
  }

  /// Generate safety recommendations
  List<SafetyRecommendation> _generateSafetyRecommendations(
      List<DrivingEvent> events) {
    final recommendations = <SafetyRecommendation>[];

    final eventCounts = _groupEventsByType(events);

    // Analyze patterns and generate recommendations
    if ((eventCounts[DrivingEventType.harshAcceleration] ?? 0) > 3) {
      recommendations.add(const SafetyRecommendation(
        type: RecommendationType.drivingBehavior,
        priority: RecommendationPriority.high,
        title: 'Reduce Harsh Acceleration',
        description:
            'Multiple harsh acceleration events detected. Practice smoother acceleration.',
        actionItems: [
          'Gradually increase speed when starting',
          'Anticipate traffic flow changes',
          'Maintain safe following distance',
        ],
      ));
    }

    if ((eventCounts[DrivingEventType.speeding] ?? 0) > 2) {
      recommendations.add(const SafetyRecommendation(
        type: RecommendationType.speedControl,
        priority: RecommendationPriority.critical,
        title: 'Speed Limit Compliance',
        description:
            'Speeding violations detected. Maintain appropriate speed limits.',
        actionItems: [
          'Monitor speedometer regularly',
          'Use cruise control when appropriate',
          'Allow extra time for trips',
        ],
      ));
    }

    return recommendations;
  }

  /// Analyze safety trends
  SafetyTrends _analyzeSafetyTrends(List<DrivingEvent> events) {
    // Group events by hour to analyze patterns
    final hourlyEvents = <int, int>{};

    for (final event in events) {
      final hour = event.timestamp.hour;
      hourlyEvents[hour] = (hourlyEvents[hour] ?? 0) + 1;
    }

    // Find peak risk hours
    final peakHours = hourlyEvents.entries
        .where((e) => e.value > 2)
        .map((e) => e.key)
        .toList();

    return SafetyTrends(
      improvementRate: _calculateImprovementRate(events),
      peakRiskHours: peakHours,
      mostCommonEvent: _getMostCommonEventType(events),
      weeklyPattern: _analyzeWeeklyPattern(events),
    );
  }

  /// Calculate improvement rate
  double _calculateImprovementRate(List<DrivingEvent> events) {
    if (events.length < 10) return 0.0;

    // Compare first half vs second half of events
    final midpoint = events.length ~/ 2;
    final firstHalf = events.take(midpoint).length;
    final secondHalf = events.skip(midpoint).length;

    if (firstHalf == 0) return 0.0;

    return ((firstHalf - secondHalf) / firstHalf) * 100;
  }

  /// Get most common event type
  DrivingEventType? _getMostCommonEventType(List<DrivingEvent> events) {
    if (events.isEmpty) return null;

    final counts = _groupEventsByType(events);
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Analyze weekly pattern
  Map<int, double> _analyzeWeeklyPattern(List<DrivingEvent> events) {
    final weeklyEvents = <int, int>{};

    for (final event in events) {
      final weekday = event.timestamp.weekday;
      weeklyEvents[weekday] = (weeklyEvents[weekday] ?? 0) + 1;
    }

    // Convert to percentages
    final total = events.length;
    return weeklyEvents
        .map((day, count) => MapEntry(day, (count / total) * 100));
  }
}

/// Configuration for Safety Monitoring Service
class SafetyMonitoringConfig extends AIServiceConfig {
  final double harshAccelerationThreshold;
  final double harshBrakingThreshold;
  final double sharpTurnThreshold;
  final double speedLimitKmh;
  final double criticalSafetyThreshold;
  final bool enableRealTimeAlerts;
  final Duration monitoringInterval;

  const SafetyMonitoringConfig({
    super.enabled = true,
    this.harshAccelerationThreshold = 2.5, // m/s²
    this.harshBrakingThreshold = 2.5, // m/s²
    this.sharpTurnThreshold = 1.5, // rad/s
    this.speedLimitKmh = 60.0, // km/h
    this.criticalSafetyThreshold = 50.0, // safety score
    this.enableRealTimeAlerts = true,
    this.monitoringInterval = const Duration(seconds: 1),
    super.rateLimitConfig,
    super.cacheConfig,
    super.customConfig = const {},
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'harshAccelerationThreshold': harshAccelerationThreshold,
      'harshBrakingThreshold': harshBrakingThreshold,
      'sharpTurnThreshold': sharpTurnThreshold,
      'speedLimitKmh': speedLimitKmh,
      'criticalSafetyThreshold': criticalSafetyThreshold,
      'enableRealTimeAlerts': enableRealTimeAlerts,
      'monitoringIntervalMs': monitoringInterval.inMilliseconds,
      'rateLimitConfig': rateLimitConfig?.toJson(),
      'cacheConfig': cacheConfig?.toJson(),
      'customConfig': customConfig,
    };
  }

  factory SafetyMonitoringConfig.fromJson(Map<String, dynamic> json) {
    return SafetyMonitoringConfig(
      enabled: json['enabled'] ?? true,
      harshAccelerationThreshold:
          json['harshAccelerationThreshold']?.toDouble() ?? 2.5,
      harshBrakingThreshold: json['harshBrakingThreshold']?.toDouble() ?? 2.5,
      sharpTurnThreshold: json['sharpTurnThreshold']?.toDouble() ?? 1.5,
      speedLimitKmh: json['speedLimitKmh']?.toDouble() ?? 60.0,
      criticalSafetyThreshold:
          json['criticalSafetyThreshold']?.toDouble() ?? 50.0,
      enableRealTimeAlerts: json['enableRealTimeAlerts'] ?? true,
      monitoringInterval:
          Duration(milliseconds: json['monitoringIntervalMs'] ?? 1000),
      rateLimitConfig: json['rateLimitConfig'] != null
          ? RateLimitConfig.fromJson(json['rateLimitConfig'])
          : null,
      cacheConfig: json['cacheConfig'] != null
          ? CacheConfig.fromJson(json['cacheConfig'])
          : null,
      customConfig: Map<String, dynamic>.from(json['customConfig'] ?? {}),
    );
  }
}

/// Sensor reading data
class SensorReading {
  final SensorType type;
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const SensorReading({
    required this.type,
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'x': x,
      'y': y,
      'z': z,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      type: SensorType.values.firstWhere((e) => e.name == json['type']),
      x: json['x']?.toDouble() ?? 0.0,
      y: json['y']?.toDouble() ?? 0.0,
      z: json['z']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Sensor types
enum SensorType {
  accelerometer,
  gyroscope,
  magnetometer,
}

/// Driving event data
class DrivingEvent {
  final DrivingEventType type;
  final EventSeverity severity;
  final DateTime timestamp;
  final SensorReading? sensorData;
  final Position? locationData;
  final String description;

  const DrivingEvent({
    required this.type,
    required this.severity,
    required this.timestamp,
    this.sensorData,
    this.locationData,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'sensorData': sensorData?.toJson(),
      'locationData': locationData != null
          ? {
              'latitude': locationData!.latitude,
              'longitude': locationData!.longitude,
              'speed': locationData!.speed,
            }
          : null,
      'description': description,
    };
  }

  factory DrivingEvent.fromJson(Map<String, dynamic> json) {
    return DrivingEvent(
      type: DrivingEventType.values.firstWhere((e) => e.name == json['type']),
      severity:
          EventSeverity.values.firstWhere((e) => e.name == json['severity']),
      timestamp: DateTime.parse(json['timestamp']),
      sensorData: json['sensorData'] != null
          ? SensorReading.fromJson(json['sensorData'])
          : null,
      locationData: json['locationData'] != null
          ? Position(
              latitude: json['locationData']['latitude'],
              longitude: json['locationData']['longitude'],
              timestamp: DateTime.parse(json['timestamp']),
              accuracy: 0.0,
              altitude: 0.0,
              heading: 0.0,
              speed: json['locationData']['speed'] ?? 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            )
          : null,
      description: json['description'] ?? '',
    );
  }
}

/// Driving event types
enum DrivingEventType {
  harshAcceleration,
  harshBraking,
  sharpTurn,
  speeding,
  routeDeviation,
  anomaly,
}

/// Event severity levels
enum EventSeverity {
  low,
  medium,
  high,
  critical,
}

/// Safety score data
class SafetyScore {
  final double overallScore;
  final double accelerationScore;
  final double brakingScore;
  final double turningScore;
  final double speedScore;
  final double routeScore;
  final double anomalyScore;
  final DateTime timestamp;

  const SafetyScore({
    required this.overallScore,
    required this.accelerationScore,
    required this.brakingScore,
    required this.turningScore,
    required this.speedScore,
    required this.routeScore,
    required this.anomalyScore,
    required this.timestamp,
  });

  factory SafetyScore.defaultScore() {
    return SafetyScore(
      overallScore: 100.0,
      accelerationScore: 100.0,
      brakingScore: 100.0,
      turningScore: 100.0,
      speedScore: 100.0,
      routeScore: 100.0,
      anomalyScore: 100.0,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'accelerationScore': accelerationScore,
      'brakingScore': brakingScore,
      'turningScore': turningScore,
      'speedScore': speedScore,
      'routeScore': routeScore,
      'anomalyScore': anomalyScore,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Safety analysis result
class SafetyAnalysisResult {
  final DateTimeRange timeRange;
  final int totalEvents;
  final Map<DrivingEventType, int> eventsByType;
  final SafetyScore safetyScore;
  final List<SafetyRecommendation> recommendations;
  final SafetyTrends trends;
  final DateTime timestamp;

  const SafetyAnalysisResult({
    required this.timeRange,
    required this.totalEvents,
    required this.eventsByType,
    required this.safetyScore,
    required this.recommendations,
    required this.trends,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'timeRange': {
        'start': timeRange.start.toIso8601String(),
        'end': timeRange.end.toIso8601String(),
      },
      'totalEvents': totalEvents,
      'eventsByType': eventsByType.map((k, v) => MapEntry(k.name, v)),
      'safetyScore': safetyScore.toJson(),
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'trends': trends.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Date time range
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({
    required this.start,
    required this.end,
  });
}

/// Safety recommendation
class SafetyRecommendation {
  final RecommendationType type;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final List<String> actionItems;

  const SafetyRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'priority': priority.name,
      'title': title,
      'description': description,
      'actionItems': actionItems,
    };
  }
}

/// Recommendation types
enum RecommendationType {
  drivingBehavior,
  speedControl,
  routePlanning,
  vehicleMaintenance,
  training,
}

/// Recommendation priority
enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}

/// Safety trends analysis
class SafetyTrends {
  final double improvementRate;
  final List<int> peakRiskHours;
  final DrivingEventType? mostCommonEvent;
  final Map<int, double> weeklyPattern;

  const SafetyTrends({
    required this.improvementRate,
    required this.peakRiskHours,
    this.mostCommonEvent,
    required this.weeklyPattern,
  });

  Map<String, dynamic> toJson() {
    return {
      'improvementRate': improvementRate,
      'peakRiskHours': peakRiskHours,
      'mostCommonEvent': mostCommonEvent?.name,
      'weeklyPattern': weeklyPattern,
    };
  }
}

/// Simple anomaly detection model using statistical methods
class AnomalyDetectionModel {
  final List<double> _baseline = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    // Initialize with default baseline values
    // In a real implementation, this would load a pre-trained model
    _isInitialized = true;
  }

  /// Detect anomalies in sensor data
  double detectAnomalies(List<SensorReading> readings) {
    if (!_isInitialized || readings.isEmpty) return 0.0;

    // Simple statistical anomaly detection
    final accelerometerReadings =
        readings.where((r) => r.type == SensorType.accelerometer).toList();

    if (accelerometerReadings.length < 10) return 0.0;

    // Calculate magnitude for each reading
    final magnitudes = accelerometerReadings.map((r) {
      return sqrt(r.x * r.x + r.y * r.y + r.z * r.z);
    }).toList();

    // Calculate mean and standard deviation
    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance =
        magnitudes.map((m) => pow(m - mean, 2)).reduce((a, b) => a + b) /
            magnitudes.length;
    final stdDev = sqrt(variance);

    // Count outliers (values beyond 2 standard deviations)
    final outliers =
        magnitudes.where((m) => (m - mean).abs() > 2 * stdDev).length;

    // Return anomaly score (0.0 = no anomalies, 1.0 = all anomalies)
    return (outliers / magnitudes.length).clamp(0.0, 1.0);
  }
}
