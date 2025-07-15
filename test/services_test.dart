import 'package:andco/core/services/firebase_service.dart';
import 'package:andco/core/services/integration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseService Tests', () {
    late FirebaseService firebaseService;

    setUp(() async {
      // Get singleton instance
      firebaseService = FirebaseService.instance;
    });

    test('Firebase service singleton pattern', () {
      // Act
      final instance1 = FirebaseService.instance;
      final instance2 = FirebaseService.instance;

      // Assert
      expect(instance1, same(instance2));
      expect(instance1, isA<FirebaseService>());
    });

    test('Firebase initialization fails gracefully without Firebase config',
        () async {
      // Act & Assert - This should fail in test environment without Firebase config
      expect(
        () => firebaseService.initialize(
          maxRetries: 2,
          retryDelay: const Duration(milliseconds: 100),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'Firebase service provides access to Firebase instances when initialized',
        () {
      // Act & Assert - These should throw when Firebase is not initialized
      expect(() => firebaseService.auth, throwsA(isA<Exception>()));
      expect(() => firebaseService.firestore, throwsA(isA<Exception>()));
      expect(() => firebaseService.storage, throwsA(isA<Exception>()));
      expect(() => firebaseService.messaging, throwsA(isA<Exception>()));
      expect(() => firebaseService.analytics, throwsA(isA<Exception>()));
      expect(() => firebaseService.crashlytics, throwsA(isA<Exception>()));
    });

    test('Firebase service initialization status', () {
      // Act & Assert
      expect(firebaseService.isInitialized, isA<bool>());
      // Initially should be false in test environment
      expect(firebaseService.isInitialized, isFalse);
    });

    test('FCM token returns null when Firebase not initialized', () async {
      // Act
      final token = await firebaseService.getFCMToken();

      // Assert - Should return null when Firebase is not initialized
      expect(token, isNull);
    });

    test('Analytics event logging handles uninitialized state', () async {
      // Arrange
      const eventName = 'test_event';
      final parameters = {'param1': 'value1', 'param2': 'value2'};

      // Act & Assert - Should complete without throwing when Firebase not initialized
      expect(
        firebaseService.logEvent(eventName, parameters),
        completes,
      );
    });

    test('Crashlytics error logging handles uninitialized state', () async {
      // Arrange
      final testException = Exception('Test error');
      final testStackTrace = StackTrace.current;
      const testReason = 'Test reason';

      // Act & Assert - Should complete without throwing when Firebase not initialized
      expect(
        firebaseService.logError(
          testException,
          testStackTrace,
          reason: testReason,
        ),
        completes,
      );
    });

    test('Topic subscription handles uninitialized state', () async {
      // Arrange
      const testTopic = 'test_topic';

      // Act & Assert - Should complete without throwing when Firebase not initialized
      expect(firebaseService.subscribeToTopic(testTopic), completes);
      expect(firebaseService.unsubscribeFromTopic(testTopic), completes);
    });

    test('User properties management handles uninitialized state', () async {
      // Arrange
      const testProperties = {'prop1': 'value1', 'prop2': 'value2'};

      // Act & Assert - Should complete without throwing when Firebase not initialized
      expect(firebaseService.setUserProperties(testProperties), completes);
      expect(
        firebaseService.setUserProperty('prop1', 'value1'),
        completes,
      );
    });

    test('Analytics collection toggle handles uninitialized state', () async {
      // Act & Assert - Should complete without throwing when Firebase not initialized
      expect(firebaseService.setAnalyticsCollectionEnabled(true), completes);
      expect(firebaseService.setAnalyticsCollectionEnabled(false), completes);
    });
  });

  group('IntegrationService Tests', () {
    late IntegrationService integrationService;

    setUp(() {
      integrationService = IntegrationService.instance;
    });

    test('Service initialization with timeout', () async {
      // Act & Assert
      expect(
        () => integrationService.initializeAllServices(
          isProduction: false,
          timeout: const Duration(seconds: 5),
          maxRetries: 2,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('System health check returns valid report', () async {
      // Act
      final healthReport = await integrationService.getSystemHealth();

      // Assert
      expect(healthReport, isNotNull);
      expect(healthReport.healthPercentage, isA<int>());
      expect(healthReport.overallStatus, isA<SystemHealthStatus>());
      expect(healthReport.serviceStatus, isA<Map<String, bool>>());
      expect(healthReport.timestamp, isA<DateTime>());
    });

    test('System health status classification', () async {
      // Act
      final healthReport = await integrationService.getSystemHealth();

      // Assert
      if (healthReport.healthPercentage >= 90) {
        expect(healthReport.overallStatus, equals(SystemHealthStatus.healthy));
      } else if (healthReport.healthPercentage >= 70) {
        expect(healthReport.overallStatus, equals(SystemHealthStatus.degraded));
      } else {
        expect(
            healthReport.overallStatus, equals(SystemHealthStatus.unhealthy));
      }
    });

    test('Emergency alert sends to multiple channels', () async {
      // Arrange
      const testPhoneNumbers = ['+1234567890', '+0987654321'];
      const testLocation = 'Test Location';
      const testEmergencyType = 'Test Emergency';

      // Act
      final result = await integrationService.sendEmergencyAlert(
        emergencyType: testEmergencyType,
        location: testLocation,
        phoneNumbers: testPhoneNumbers,
        additionalInfo: 'Test additional info',
      );

      // Assert
      expect(result, isA<EmergencyAlertResult>());
      expect(result.emergencyType, equals(testEmergencyType));
      expect(result.location, equals(testLocation));
      expect(result.results, isA<Map<String, bool>>());
      expect(result.results.keys,
          containsAll(['push_notifications', 'sms', 'whatsapp']));
    });

    test('User verification handles multiple verification steps', () async {
      // Arrange
      const testUserId = 'test-user-123';
      const testLocation = 'US';

      // Act
      final result = await integrationService.verifyUser(
        userId: testUserId,
        expectedLocation: testLocation,
        requireFaceVerification: true,
      );

      // Assert
      expect(result, isA<UserVerificationResult>());
      expect(result.userId, equals(testUserId));
      expect(result.verificationSteps, isA<Map<String, bool>>());
      expect(
        result.verificationSteps.keys,
        containsAll(['location_check', 'region_check', 'face_verification']),
      );
      expect(result.warnings, isA<List<String>>());
    });

    test('User verification without face verification', () async {
      // Arrange
      const testUserId = 'test-user-123';
      const testLocation = 'US';

      // Act
      final result = await integrationService.verifyUser(
        userId: testUserId,
        expectedLocation: testLocation,
        requireFaceVerification: false,
      );

      // Assert
      expect(result, isA<UserVerificationResult>());
      expect(
          result.verificationSteps.containsKey('face_verification'), isFalse);
      expect(
        result.verificationSteps.keys,
        containsAll(['location_check', 'region_check']),
      );
    });

    test('Service status reporting', () {
      // Act
      final status = integrationService.getServiceStatus();

      // Assert
      expect(status, isA<Map<String, bool>>());
      expect(
        status.keys,
        containsAll([
          'firebase',
          'stripe',
          'mpesa',
          'notifications',
          'whatsapp',
          'sms',
          'maps',
          'geolocation',
          'face_detection',
          'weather',
        ]),
      );
    });
  });
}
