import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase service for initializing and managing Firebase services
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  // Firebase instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;
  FirebaseMessaging get messaging => FirebaseMessaging.instance;
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase services
  Future<void> initialize({FirebaseOptions? options}) async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase for production use

      // Initialize Firebase
      await Firebase.initializeApp(options: options);

      // Configure Firestore settings
      await _configureFirestore();

      // Initialize Firebase Messaging
      await _initializeMessaging();

      // Initialize Crashlytics
      await _initializeCrashlytics();

      // Initialize Analytics
      await _initializeAnalytics();

      _isInitialized = true;
      debugPrint('Firebase services initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
      rethrow; // Don't continue if Firebase fails to initialize
    }
  }

  /// Check if Firebase Messaging is supported on this platform
  bool _isMessagingSupported() {
    // Firebase Messaging is supported on iOS, Android, and Web
    // Not supported on Windows, macOS, Linux desktop
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android ||
        kIsWeb;
  }

  /// Check if Firebase Crashlytics is supported on this platform
  bool _isCrashlyticsSupported() {
    // Crashlytics is supported on iOS and Android
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  /// Check if Firebase Analytics is supported on this platform
  bool _isAnalyticsSupported() {
    // Analytics is supported on iOS, Android, and Web
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android ||
        kIsWeb;
  }

  /// Configure Firestore settings
  Future<void> _configureFirestore() async {
    try {
      // Configure cache settings for all platforms
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      debugPrint(
          'Firestore configured successfully for ${kIsWeb ? 'web' : 'mobile/desktop'}');
    } catch (e) {
      debugPrint('Failed to configure Firestore: $e');
      // Continue without persistence if it fails
    }
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeMessaging() async {
    try {
      // Check if messaging is supported on this platform
      if (!_isMessagingSupported()) {
        debugPrint('Firebase Messaging not supported on this platform');
        return;
      }

      // Request permission for notifications
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission for notifications');
      } else {
        debugPrint(
            'User declined or has not accepted permission for notifications');
      }

      // Get FCM token
      String? token = await messaging.getToken();
      debugPrint('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      debugPrint('Firebase Messaging initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase Messaging: $e');
    }
  }

  /// Initialize Crashlytics
  Future<void> _initializeCrashlytics() async {
    try {
      // Check if Crashlytics is supported on this platform
      if (!_isCrashlyticsSupported()) {
        debugPrint('Firebase Crashlytics not supported on this platform');
        return;
      }

      // Enable Crashlytics collection
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Set user identifier
      if (auth.currentUser != null) {
        await crashlytics.setUserIdentifier(auth.currentUser!.uid);
      }

      debugPrint('Firebase Crashlytics initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase Crashlytics: $e');
    }
  }

  /// Initialize Analytics
  Future<void> _initializeAnalytics() async {
    try {
      // Check if Analytics is supported on this platform
      if (!_isAnalyticsSupported()) {
        debugPrint('Firebase Analytics not supported on this platform');
        return;
      }

      // Enable Analytics collection
      await analytics.setAnalyticsCollectionEnabled(!kDebugMode);

      debugPrint('Firebase Analytics initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase Analytics: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Data: ${message.data}');
    // TODO: Navigate to appropriate screen based on message data
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      if (!_isMessagingSupported()) {
        debugPrint('Firebase Messaging not supported on this platform');
        return null;
      }
      return await messaging.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      if (!_isMessagingSupported()) {
        debugPrint('Firebase Messaging not supported on this platform');
        return;
      }
      await messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (!_isMessagingSupported()) {
        debugPrint('Firebase Messaging not supported on this platform');
        return;
      }
      await messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Log custom event to Analytics
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      if (!_isAnalyticsSupported()) {
        debugPrint('Firebase Analytics not supported on this platform');
        return;
      }
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Failed to log event $name: $e');
    }
  }

  /// Log error to Crashlytics
  Future<void> logError(dynamic exception, StackTrace? stackTrace,
      {String? reason}) async {
    try {
      if (!_isCrashlyticsSupported()) {
        debugPrint('Firebase Crashlytics not supported on this platform');
        return;
      }
      await crashlytics.recordError(exception, stackTrace, reason: reason);
    } catch (e) {
      debugPrint('Failed to log error to Crashlytics: $e');
    }
  }

  /// Set user properties for Analytics
  Future<void> setUserProperties(Map<String, String> properties) async {
    try {
      if (!_isAnalyticsSupported()) {
        debugPrint('Firebase Analytics not supported on this platform');
        return;
      }
      for (final entry in properties.entries) {
        await analytics.setUserProperty(name: entry.key, value: entry.value);
      }
    } catch (e) {
      debugPrint('Failed to set user properties: $e');
    }
  }

  /// Set a single user property for Analytics
  Future<void> setUserProperty(String name, String value) async {
    try {
      if (!_isAnalyticsSupported()) {
        debugPrint('Firebase Analytics not supported on this platform');
        return;
      }
      await analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Failed to set user property $name: $e');
    }
  }

  /// Enable or disable analytics collection
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      if (!_isAnalyticsSupported()) {
        debugPrint('Firebase Analytics not supported on this platform');
        return;
      }
      await analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('Failed to set analytics collection enabled: $e');
    }
  }

  /// Set default event parameters for Analytics
  Future<void> setDefaultEventParameters(Map<String, Object> parameters) async {
    try {
      if (!_isAnalyticsSupported()) {
        debugPrint('Firebase Analytics not supported on this platform');
        return;
      }
      await analytics.setDefaultEventParameters(parameters);
    } catch (e) {
      debugPrint('Failed to set default event parameters: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Received background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}
