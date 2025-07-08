import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../firebase_options.dart';
import '../../shared/models/bus_model.dart';
import '../../shared/models/checkin_model.dart';
import '../../shared/models/child_model.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/trip_model.dart';
import '../../shared/models/user_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'security_service.dart';
import 'storage_service.dart';

/// Service for initializing all Firebase services and dependencies
class FirebaseInitializationService {
  static FirebaseInitializationService? _instance;
  static FirebaseInitializationService get instance =>
      _instance ??= FirebaseInitializationService._();

  FirebaseInitializationService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize all Firebase services and dependencies
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Starting Firebase initialization...');

      // Step 1: Initialize Hive for local storage
      await _initializeHive();
      debugPrint('✅ Hive initialized');

      // Step 2: Initialize Firebase core services
      await FirebaseService.instance.initialize(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase core services initialized');

      // Step 3: Authentication service is ready (no initialization needed)
      debugPrint('✅ Authentication service ready');

      // Step 4: Initialize notification service
      await NotificationService.instance.initialize(
        onMessageReceived: _handleForegroundMessage,
        onMessageOpenedApp: _handleMessageOpenedApp,
      );
      debugPrint('✅ Notification service initialized');

      // Step 5: Initialize security service
      SecurityService.instance;
      debugPrint('✅ Security service initialized');

      // Step 6: Initialize storage service
      StorageService.instance;
      debugPrint('✅ Storage service initialized');

      // Step 7: Set up error handling
      await _setupErrorHandling();
      debugPrint('✅ Error handling configured');

      // Step 8: Set up analytics
      await _setupAnalytics();
      debugPrint('✅ Analytics configured');

      _isInitialized = true;
      debugPrint('🎉 Firebase initialization completed successfully!');

      // Log initialization event
      await FirebaseService.instance.logEvent('app_initialized', {
        'platform': defaultTargetPlatform.name,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Firebase initialization failed: $e');
      await FirebaseService.instance
          .logError(e, stackTrace, reason: 'Firebase initialization failed');
      rethrow;
    }
  }

  /// Initialize Hive local storage with all model adapters
  Future<void> _initializeHive() async {
    await Hive.initFlutter();

    // Register all Hive adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserRoleAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ChildModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(BusModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(BusStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(RouteModelAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(RouteStopAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RouteTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(TripModelAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(LocationDataAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TripTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(TripStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(CheckinModelAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(CheckinMethodAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(CheckinStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(PaymentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(PaymentStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(PaymentMethodAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(NotificationModelAdapter());
    }
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(NotificationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(NotificationPriorityAdapter());
    }

    // Open Hive boxes
    await _openHiveBoxes();
  }

  /// Open all required Hive boxes
  Future<void> _openHiveBoxes() async {
    try {
      await Future.wait([
        Hive.openBox<UserModel>('users'),
        Hive.openBox<ChildModel>('children'),
        Hive.openBox<BusModel>('buses'),
        Hive.openBox<RouteModel>('routes'),
        Hive.openBox<TripModel>('trips'),
        Hive.openBox<CheckinModel>('checkins'),
        Hive.openBox<PaymentModel>('payments'),
        Hive.openBox<NotificationModel>('notifications'),
        Hive.openBox('settings'),
        Hive.openBox('cache'),
      ]);
    } catch (e) {
      debugPrint('Error opening Hive boxes: $e');
      // Try to open boxes individually if batch opening fails
      await _openHiveBoxesIndividually();
    }
  }

  /// Open Hive boxes individually as fallback
  Future<void> _openHiveBoxesIndividually() async {
    final boxNames = [
      'users',
      'children',
      'buses',
      'routes',
      'trips',
      'checkins',
      'payments',
      'notifications',
      'settings',
      'cache'
    ];

    for (final boxName in boxNames) {
      try {
        await Hive.openBox(boxName);
      } catch (e) {
        debugPrint('Failed to open box $boxName: $e');
        // Continue with other boxes even if one fails
      }
    }
  }

  /// Handle foreground push notifications
  void _handleForegroundMessage(dynamic message) {
    debugPrint('Received foreground message: ${message.toString()}');
    // Handle the message (show in-app notification, update UI, etc.)
  }

  /// Handle notification tap when app is opened
  void _handleMessageOpenedApp(dynamic message) {
    debugPrint('App opened from notification: ${message.toString()}');
    // Handle navigation based on notification data
  }

  /// Set up global error handling
  Future<void> _setupErrorHandling() async {
    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseService.instance.logError(
        details.exception,
        details.stack,
        reason: 'Flutter error: ${details.context}',
      );
    };

    // Set up platform error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseService.instance.logError(
        error,
        stack,
        reason: 'Platform error',
      );
      return true;
    };
  }

  /// Set up analytics configuration
  Future<void> _setupAnalytics() async {
    try {
      // Enable analytics collection
      await FirebaseService.instance.setAnalyticsCollectionEnabled(true);

      // Set default analytics parameters
      await FirebaseService.instance.setDefaultEventParameters({
        'app_version': '1.0.0', // This should come from package info
        'platform': defaultTargetPlatform.name,
      });

      // Set user properties
      await FirebaseService.instance
          .setUserProperty('app_type', 'school_transport');
    } catch (e) {
      debugPrint('Failed to setup analytics: $e');
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    try {
      // Close all Hive boxes
      await Hive.close();

      _isInitialized = false;
      debugPrint('🧹 Firebase services disposed');
    } catch (e) {
      debugPrint('Error disposing Firebase services: $e');
    }
  }

  /// Check if all services are healthy
  Future<Map<String, bool>> healthCheck() async {
    final health = <String, bool>{};

    try {
      // Check Firebase connection
      health['firebase'] = FirebaseService.instance.isInitialized;

      // Check authentication (service is always ready if Firebase is initialized)
      health['auth'] = FirebaseService.instance.isInitialized;

      // Check Hive
      health['hive'] = Hive.isBoxOpen('settings');

      // Check notification service
      health['notifications'] = NotificationService.instance.fcmToken != null;

      // Overall health
      health['overall'] = health.values.every((isHealthy) => isHealthy);
    } catch (e) {
      debugPrint('Health check failed: $e');
      health['overall'] = false;
    }

    return health;
  }

  /// Get initialization status
  Map<String, dynamic> getInitializationStatus() {
    return {
      'isInitialized': _isInitialized,
      'firebase': FirebaseService.instance.isInitialized,
      'auth': FirebaseService.instance.isInitialized,
      'hive': Hive.isBoxOpen('settings'),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reinitialize services (useful for error recovery)
  Future<void> reinitialize() async {
    debugPrint('🔄 Reinitializing Firebase services...');

    _isInitialized = false;

    try {
      await dispose();
      await initialize();
      debugPrint('✅ Firebase services reinitialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to reinitialize Firebase services: $e');
      rethrow;
    }
  }
}
