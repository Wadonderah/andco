import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test configuration and setup utilities
class TestConfig {
  static bool _initialized = false;

  /// Initialize test environment
  static Future<void> initialize() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    // Setup Firebase mocks
    await _setupFirebaseMocks();

    // Setup method channel mocks
    _setupMethodChannelMocks();

    // Setup test data
    await _setupTestData();

    _initialized = true;
  }

  /// Setup Firebase mocks for testing
  static Future<void> _setupFirebaseMocks() async {
    // Mock Firebase Core
    setupFirebaseCoreMocks();

    // Mock Firebase Auth
    setupFirebaseAuthMocks();

    // Mock Firestore
    setupFirestoreMocks();
  }

  /// Setup method channel mocks
  static void _setupMethodChannelMocks() {
    // Mock location services
    const MethodChannel('flutter.baseflow.com/geolocator')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getCurrentPosition':
          return {
            'latitude': 40.7128,
            'longitude': -74.0060,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'accuracy': 10.0,
            'altitude': 0.0,
            'heading': 0.0,
            'speed': 0.0,
            'speedAccuracy': 0.0,
          };
        case 'getLocationAccuracy':
          return 'high';
        case 'requestPermission':
          return 'granted';
        default:
          return null;
      }
    });

    // Mock Google Maps
    const MethodChannel('plugins.flutter.io/google_maps_flutter')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });

    // Mock Firebase Messaging
    const MethodChannel('plugins.flutter.io/firebase_messaging')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getToken':
          return 'mock_fcm_token';
        case 'requestPermission':
          return {'authorizationStatus': 1};
        default:
          return null;
      }
    });

    // Mock URL Launcher
    const MethodChannel('plugins.flutter.io/url_launcher')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return true;
    });

    // Mock Image Picker
    const MethodChannel('plugins.flutter.io/image_picker')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return '/mock/image/path.jpg';
    });

    // Mock File Picker
    const MethodChannel('miguelruivo.flutter.plugins.filepicker')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return {
        'paths': ['/mock/file/path.pdf'],
        'names': ['mock_file.pdf'],
        'bytes': null,
      };
    });
  }

  /// Setup test data
  static Future<void> _setupTestData() async {
    // Create mock user data
    TestData.createMockUsers();

    // Create mock school data
    TestData.createMockSchools();

    // Create mock route data
    TestData.createMockRoutes();

    // Create mock payment data
    TestData.createMockPayments();
  }

  /// Clean up test environment
  static Future<void> cleanup() async {
    // Clear test data
    TestData.clear();

    // Reset method channel handlers
    _resetMethodChannelHandlers();

    _initialized = false;
  }

  /// Reset method channel handlers
  static void _resetMethodChannelHandlers() {
    // Reset location services
    const MethodChannel('flutter.baseflow.com/geolocator')
        .setMockMethodCallHandler(null);

    // Reset Google Maps
    const MethodChannel('plugins.flutter.io/google_maps_flutter')
        .setMockMethodCallHandler(null);

    // Reset Firebase Messaging
    const MethodChannel('plugins.flutter.io/firebase_messaging')
        .setMockMethodCallHandler(null);

    // Reset URL Launcher
    const MethodChannel('plugins.flutter.io/url_launcher')
        .setMockMethodCallHandler(null);

    // Reset Image Picker
    const MethodChannel('plugins.flutter.io/image_picker')
        .setMockMethodCallHandler(null);

    // Reset File Picker
    const MethodChannel('miguelruivo.flutter.plugins.filepicker')
        .setMockMethodCallHandler(null);
  }
}

/// Mock Firebase setup utilities
void setupFirebaseCoreMocks() {
  // Mock Firebase.initializeApp
  // This would typically be done with firebase_core_platform_interface mocks
}

void setupFirebaseAuthMocks() {
  // Mock Firebase Auth methods
  // This would typically be done with firebase_auth_mocks package
}

void setupFirestoreMocks() {
  // Mock Firestore methods
  // This would typically be done with cloud_firestore_mocks package
}

/// Test data management
class TestData {
  static final Map<String, dynamic> _mockData = {};

  /// Create mock users for testing
  static void createMockUsers() {
    _mockData['users'] = [
      {
        'id': 'parent_1',
        'email': 'parent@test.com',
        'name': 'John Parent',
        'role': 'parent',
        'children': ['child_1', 'child_2'],
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      },
      {
        'id': 'driver_1',
        'email': 'driver@test.com',
        'name': 'Mike Driver',
        'role': 'driver',
        'licenseNumber': 'DL123456',
        'isApproved': true,
        'isActive': true,
        'assignedRouteId': 'route_1',
        'createdAt': DateTime.now().subtract(const Duration(days: 20)),
      },
      {
        'id': 'admin_1',
        'email': 'admin@school.com',
        'name': 'Sarah Admin',
        'role': 'school_admin',
        'schoolId': 'school_1',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 15)),
      },
      {
        'id': 'super_admin_1',
        'email': 'admin@andco.com',
        'name': 'Super Admin',
        'role': 'super_admin',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 100)),
      },
    ];
  }

  /// Create mock schools for testing
  static void createMockSchools() {
    _mockData['schools'] = [
      {
        'id': 'school_1',
        'name': 'Test Elementary School',
        'address': '123 School Street, Test City',
        'principalName': 'Dr. Jane Principal',
        'contactEmail': 'principal@school.com',
        'contactPhone': '+1234567890',
        'isApproved': true,
        'isActive': true,
        'subscriptionPlan': 'premium',
        'maxStudents': 500,
        'maxDrivers': 20,
        'createdAt': DateTime.now().subtract(const Duration(days: 60)),
      },
      {
        'id': 'school_2',
        'name': 'Pending School',
        'address': '456 Pending Avenue, Test City',
        'principalName': 'Mr. Bob Pending',
        'contactEmail': 'pending@school.com',
        'contactPhone': '+1234567891',
        'isApproved': false,
        'isActive': true,
        'subscriptionPlan': 'basic',
        'maxStudents': 200,
        'maxDrivers': 10,
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      },
    ];
  }

  /// Create mock routes for testing
  static void createMockRoutes() {
    _mockData['routes'] = [
      {
        'id': 'route_1',
        'name': 'Route A - Morning',
        'schoolId': 'school_1',
        'driverId': 'driver_1',
        'isActive': true,
        'stops': [
          {
            'id': 'stop_1',
            'name': 'Main Street Stop',
            'latitude': 40.7128,
            'longitude': -74.0060,
            'estimatedTime': '08:00',
            'students': ['child_1'],
          },
          {
            'id': 'stop_2',
            'name': 'Park Avenue Stop',
            'latitude': 40.7589,
            'longitude': -73.9851,
            'estimatedTime': '08:15',
            'students': ['child_2'],
          },
        ],
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
      },
    ];
  }

  /// Create mock payments for testing
  static void createMockPayments() {
    _mockData['payments'] = [
      {
        'id': 'payment_1',
        'userId': 'parent_1',
        'amount': 100.0,
        'currency': 'USD',
        'paymentMethod': 'stripe',
        'status': 'completed',
        'description': 'Monthly transport fee',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'id': 'payment_2',
        'userId': 'parent_1',
        'amount': 50.0,
        'currency': 'KES',
        'paymentMethod': 'mpesa',
        'status': 'pending',
        'description': 'Additional trip fee',
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
    ];
  }

  /// Get mock data by type
  static List<Map<String, dynamic>> getMockData(String type) {
    return List<Map<String, dynamic>>.from(_mockData[type] ?? []);
  }

  /// Get mock data by ID
  static Map<String, dynamic>? getMockDataById(String type, String id) {
    final data = getMockData(type);
    try {
      return data.firstWhere((item) => item['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Add mock data
  static void addMockData(String type, Map<String, dynamic> data) {
    if (_mockData[type] == null) {
      _mockData[type] = <Map<String, dynamic>>[];
    }
    _mockData[type].add(data);
  }

  /// Update mock data
  static void updateMockData(
      String type, String id, Map<String, dynamic> updates) {
    final data = getMockData(type);
    final index = data.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      data[index] = {...data[index], ...updates};
    }
  }

  /// Delete mock data
  static void deleteMockData(String type, String id) {
    final data = getMockData(type);
    data.removeWhere((item) => item['id'] == id);
  }

  /// Clear all mock data
  static void clear() {
    _mockData.clear();
  }
}

/// Test utilities
class TestUtils {
  /// Create a test widget with proper setup
  static Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }

  /// Wait for animations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  /// Simulate network delay
  static Future<void> simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Generate random test data
  static String generateRandomId() {
    return 'test_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Create mock timestamp
  static Timestamp createMockTimestamp([DateTime? dateTime]) {
    return Timestamp.fromDate(dateTime ?? DateTime.now());
  }
}

/// Test constants
class TestConstants {
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'password123';
  static const String testPhoneNumber = '+1234567890';
  static const String testSchoolId = 'test_school_id';
  static const String testUserId = 'test_user_id';
  static const String testRouteId = 'test_route_id';
  static const String testPaymentId = 'test_payment_id';

  static const double testLatitude = 40.7128;
  static const double testLongitude = -74.0060;

  static const Duration testTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
}
