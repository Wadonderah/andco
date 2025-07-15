import 'package:flutter/foundation.dart';

import 'face_detection_service.dart';
import 'firebase_service.dart';
import 'geolocation_service.dart';
import 'maps_service.dart';
import 'mpesa_service.dart';
import 'notification_service.dart';
import 'sms_service.dart';
import 'stripe_service.dart';
import 'weather_service.dart';
import 'whatsapp_service.dart';

/// Comprehensive integration service that manages all external APIs and AI agents
class IntegrationService {
  static IntegrationService? _instance;
  static IntegrationService get instance =>
      _instance ??= IntegrationService._();

  IntegrationService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize all services with timeout and dependency management
  Future<void> initializeAllServices({
    bool isProduction = false,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    if (_isInitialized) return;

    debugPrint('🚀 Starting integration service initialization...');

    try {
      // Initialize core Firebase service first with retry mechanism
      await FirebaseService.instance
          .initialize(
            maxRetries: maxRetries,
            retryDelay: const Duration(seconds: 2),
          )
          .timeout(timeout);
      debugPrint('✅ Firebase service initialized');

      // Initialize services in parallel with timeouts
      await Future.wait([
        _initializePaymentServices(isProduction).timeout(timeout),
        _initializeCommunicationServices().timeout(timeout),
        _initializeLocationServices().timeout(timeout),
        _initializeAIServices().timeout(timeout),
        _initializeUtilityServices().timeout(timeout),
      ], eagerError: false)
          .catchError((e) {
        debugPrint('⚠️ Some service initializations failed: $e');
        // Continue with partial initialization
      });

      _isInitialized = true;

      debugPrint('🎉 Integration services initialized');

      // Log initialization status
      await FirebaseService.instance.logEvent(
        'integration_service_initialized',
        {
          'is_production': isProduction,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Integration service initialization failed: $e');
      await FirebaseService.instance.logError(
        e,
        stackTrace,
        reason: 'Integration service initialization failed',
      );
      rethrow;
    }
  }

  /// Initialize payment services
  Future<void> _initializePaymentServices(bool isProduction) async {
    debugPrint('💳 Initializing payment services...');

    try {
      // Initialize Stripe
      await StripeService.instance.initialize(isProduction: isProduction);
      debugPrint('✅ Stripe service initialized');
    } catch (e) {
      debugPrint('⚠️ Stripe initialization failed: $e');
    }

    try {
      // Initialize M-Pesa
      await MPesaService.instance.initialize(isProduction: isProduction);
      debugPrint('✅ M-Pesa service initialized');
    } catch (e) {
      debugPrint('⚠️ M-Pesa initialization failed: $e');
    }
  }

  /// Initialize communication services
  Future<void> _initializeCommunicationServices() async {
    debugPrint('📱 Initializing communication services...');

    try {
      // Initialize enhanced notifications
      await NotificationService.instance.initialize();
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('⚠️ Notification service initialization failed: $e');
    }

    try {
      // Initialize WhatsApp
      await WhatsAppService().initialize();
      debugPrint('✅ WhatsApp service initialized');
    } catch (e) {
      debugPrint('⚠️ WhatsApp initialization failed: $e');
    }

    try {
      // Initialize SMS services
      await SmsService.instance.initialize();
      debugPrint('✅ SMS service initialized');
    } catch (e) {
      debugPrint('⚠️ SMS service initialization failed: $e');
    }
  }

  /// Initialize location and mapping services
  Future<void> _initializeLocationServices() async {
    debugPrint('🗺️ Initializing location services...');

    try {
      // Initialize Maps service
      await MapsService.instance.initialize();
      debugPrint('✅ Maps service initialized');
    } catch (e) {
      debugPrint('⚠️ Maps service initialization failed: $e');
    }

    try {
      // Initialize IP Geolocation
      await GeolocationService.instance.initialize();
      debugPrint('✅ Geolocation service initialized');
    } catch (e) {
      debugPrint('⚠️ Geolocation service initialization failed: $e');
    }
  }

  /// Initialize AI and ML services
  Future<void> _initializeAIServices() async {
    debugPrint('🤖 Initializing AI services...');

    try {
      // Initialize Face Detection
      await FaceDetectionService.instance.initialize();
      debugPrint('✅ Face detection service initialized');
    } catch (e) {
      debugPrint('⚠️ Face detection initialization failed: $e');
    }
  }

  /// Initialize utility services
  Future<void> _initializeUtilityServices() async {
    debugPrint('🌤️ Initializing utility services...');

    try {
      // Initialize Weather service
      await WeatherService.instance.initialize();
      debugPrint('✅ Weather service initialized');
    } catch (e) {
      debugPrint('⚠️ Weather service initialization failed: $e');
    }
  }

  /// Get service status summary
  Map<String, bool> getServiceStatus() {
    return {
      'firebase': FirebaseService.instance.isInitialized,
      'stripe': StripeService.instance.isInitialized,
      'mpesa': MPesaService.instance.isInitialized,
      'notifications':
          true, // NotificationService doesn't expose isInitialized publicly
      'whatsapp': WhatsAppService().isInitialized,
      'sms': SmsService.instance.isInitialized,
      'maps': MapsService.instance.isInitialized,
      'geolocation': GeolocationService.instance.isInitialized,
      'face_detection': FaceDetectionService.instance.isInitialized,
      'weather': WeatherService.instance.isInitialized,
    };
  }

  /// Send comprehensive emergency alert
  Future<EmergencyAlertResult> sendEmergencyAlert({
    required String emergencyType,
    required String location,
    required List<String> phoneNumbers,
    String? additionalInfo,
  }) async {
    final results = <String, bool>{};

    // Send push notifications
    try {
      await NotificationService.instance.sendNotificationRequest(
        type: 'emergency_alert',
        data: {
          'title': 'EMERGENCY ALERT',
          'body': '$emergencyType at $location',
          'emergency_type': emergencyType,
          'location': location,
          'priority': 'high',
          'timestamp': DateTime.now().toIso8601String(),
          if (additionalInfo != null) 'additional_info': additionalInfo,
        },
        userIds: phoneNumbers, // This would be user IDs in real implementation
      );
      results['push_notifications'] = true;
    } catch (e) {
      results['push_notifications'] = false;
      debugPrint('Emergency push notification failed: $e');
    }

    // Send SMS alerts
    try {
      final smsResults = await SmsService.instance.sendBulkSms(
        recipients: phoneNumbers,
        message:
            'EMERGENCY: $emergencyType at $location. ${additionalInfo ?? ""}',
      );
      results['sms'] = smsResults.every((r) => r.success);
    } catch (e) {
      results['sms'] = false;
      debugPrint('Emergency SMS failed: $e');
    }

    // Send WhatsApp messages
    try {
      bool whatsappSuccess = true;
      for (final phoneNumber in phoneNumbers) {
        final success = await WhatsAppService().sendTextMessage(
          phoneNumber,
          '🚨 EMERGENCY ALERT 🚨\n\nType: $emergencyType\nLocation: $location\n\n${additionalInfo ?? ""}\n\nPlease respond immediately.',
        );
        if (!success) whatsappSuccess = false;
      }
      results['whatsapp'] = whatsappSuccess;
    } catch (e) {
      results['whatsapp'] = false;
      debugPrint('Emergency WhatsApp failed: $e');
    }

    await FirebaseService.instance.logEvent('emergency_alert_sent', {
      'emergency_type': emergencyType,
      'location': location,
      'recipient_count': phoneNumbers.length,
      'results': results,
    });

    return EmergencyAlertResult(
      success: results.values.any((success) => success),
      results: results,
      emergencyType: emergencyType,
      location: location,
    );
  }

  /// Comprehensive user verification
  Future<UserVerificationResult> verifyUser({
    required String userId,
    String? expectedLocation,
    bool requireFaceVerification = false,
  }) async {
    final verificationSteps = <String, bool>{};
    final warnings = <String>[];

    // IP-based location verification
    try {
      final securityAssessment =
          await GeolocationService.instance.assessLoginSecurity(
        userId: userId,
        lastKnownCountry: expectedLocation,
      );

      verificationSteps['location_check'] =
          securityAssessment.riskLevel != SecurityRiskLevel.high;
      warnings.addAll(securityAssessment.warnings);
    } catch (e) {
      verificationSteps['location_check'] = false;
      warnings.add('Location verification failed');
    }

    // Regional access check
    try {
      final regionCheck = await GeolocationService.instance.checkUserRegion();
      verificationSteps['region_check'] = regionCheck.isAllowed;
      if (!regionCheck.isAllowed) {
        warnings.add(regionCheck.reason);
      }
    } catch (e) {
      verificationSteps['region_check'] = false;
      warnings.add('Region check failed');
    }

    // Face verification (if required)
    if (requireFaceVerification) {
      // This would be implemented with actual face comparison logic
      verificationSteps['face_verification'] = false;
      warnings
          .add('Face verification required but not implemented in this demo');
    }

    final isVerified = verificationSteps.values.every((step) => step);

    await FirebaseService.instance.logEvent('user_verification_completed', {
      'user_id': userId,
      'is_verified': isVerified,
      'verification_steps': verificationSteps,
      'warning_count': warnings.length,
    });

    return UserVerificationResult(
      isVerified: isVerified,
      verificationSteps: verificationSteps,
      warnings: warnings,
      userId: userId,
    );
  }

  /// Get comprehensive system health
  Future<SystemHealthReport> getSystemHealth() async {
    final serviceStatus = getServiceStatus();
    final healthyServices =
        serviceStatus.values.where((status) => status).length;
    final totalServices = serviceStatus.length;

    final healthPercentage = (healthyServices / totalServices * 100).round();

    SystemHealthStatus overallStatus;
    if (healthPercentage >= 90) {
      overallStatus = SystemHealthStatus.healthy;
    } else if (healthPercentage >= 70) {
      overallStatus = SystemHealthStatus.degraded;
    } else {
      overallStatus = SystemHealthStatus.unhealthy;
    }

    await FirebaseService.instance.logEvent('system_health_checked', {
      'overall_status': overallStatus.name,
      'health_percentage': healthPercentage,
      'healthy_services': healthyServices,
      'total_services': totalServices,
    });

    return SystemHealthReport(
      overallStatus: overallStatus,
      healthPercentage: healthPercentage,
      serviceStatus: serviceStatus,
      timestamp: DateTime.now(),
    );
  }
}

/// Emergency alert result model
class EmergencyAlertResult {
  final bool success;
  final Map<String, bool> results;
  final String emergencyType;
  final String location;

  EmergencyAlertResult({
    required this.success,
    required this.results,
    required this.emergencyType,
    required this.location,
  });
}

/// User verification result model
class UserVerificationResult {
  final bool isVerified;
  final Map<String, bool> verificationSteps;
  final List<String> warnings;
  final String userId;

  UserVerificationResult({
    required this.isVerified,
    required this.verificationSteps,
    required this.warnings,
    required this.userId,
  });
}

/// System health report model
class SystemHealthReport {
  final SystemHealthStatus overallStatus;
  final int healthPercentage;
  final Map<String, bool> serviceStatus;
  final DateTime timestamp;

  SystemHealthReport({
    required this.overallStatus,
    required this.healthPercentage,
    required this.serviceStatus,
    required this.timestamp,
  });
}

/// System health status enum
enum SystemHealthStatus {
  healthy,
  degraded,
  unhealthy,
}

extension SystemHealthStatusExtension on SystemHealthStatus {
  String get displayName {
    switch (this) {
      case SystemHealthStatus.healthy:
        return 'Healthy';
      case SystemHealthStatus.degraded:
        return 'Degraded';
      case SystemHealthStatus.unhealthy:
        return 'Unhealthy';
    }
  }
}
