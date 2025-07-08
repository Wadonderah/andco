import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';
import 'auth_service.dart';

/// Service for managing push notifications
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseService.instance.messaging;
  
  bool _isInitialized = false;
  String? _fcmToken;
  
  // Notification handlers
  Function(RemoteMessage)? _onMessageReceived;
  Function(RemoteMessage)? _onMessageOpenedApp;
  Function(RemoteMessage)? _onBackgroundMessage;

  /// Initialize notification service
  Future<void> initialize({
    Function(RemoteMessage)? onMessageReceived,
    Function(RemoteMessage)? onMessageOpenedApp,
    Function(RemoteMessage)? onBackgroundMessage,
  }) async {
    if (_isInitialized) return;

    try {
      // Set handlers
      _onMessageReceived = onMessageReceived;
      _onMessageOpenedApp = onMessageOpenedApp;
      _onBackgroundMessage = onBackgroundMessage;

      // Request permission
      await _requestPermission();
      
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      // Update user's FCM token in Firestore
      await _updateUserFCMToken();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      // Handle notification when app is opened from terminated state
      await _handleInitialMessage();
      
      _isInitialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Notification service initialization failed');
      debugPrint('Failed to initialize notification service: $e');
    }
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission for notifications');
    } else {
      debugPrint('User declined or has not accepted permission for notifications');
    }
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
      _onMessageReceived?.call(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped (background): ${message.messageId}');
      _onMessageOpenedApp?.call(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  /// Handle initial message when app is opened from terminated state
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.messageId}');
      _onMessageOpenedApp?.call(initialMessage);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification or in-app notification
    _showInAppNotification(message);
  }

  /// Show in-app notification
  void _showInAppNotification(RemoteMessage message) {
    // This would typically show a banner or dialog
    // For now, we'll just log it
    debugPrint('Showing in-app notification: ${message.notification?.title}');
  }

  /// Update user's FCM token in Firestore
  Future<void> _updateUserFCMToken() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user != null && _fcmToken != null) {
        await AuthService.instance.updateUserProfile(user.uid, {
          'fcmToken': _fcmToken,
        });
      }
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
    }
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
      
      await FirebaseService.instance.logEvent('topic_subscribed', {
        'topic': topic,
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Topic subscription failed');
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
      
      await FirebaseService.instance.logEvent('topic_unsubscribed', {
        'topic': topic,
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Topic unsubscription failed');
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Subscribe to school-specific topics
  Future<void> subscribeToSchoolTopics(String schoolId) async {
    await Future.wait([
      subscribeToTopic('school_$schoolId'),
      subscribeToTopic('school_${schoolId}_announcements'),
      subscribeToTopic('school_${schoolId}_emergencies'),
    ]);
  }

  /// Subscribe to parent-specific topics
  Future<void> subscribeToParentTopics(String parentId, List<String> childIds) async {
    final subscriptions = <Future<void>>[
      subscribeToTopic('parent_$parentId'),
    ];
    
    for (final childId in childIds) {
      subscriptions.addAll([
        subscribeToTopic('child_$childId'),
        subscribeToTopic('child_${childId}_pickup'),
        subscribeToTopic('child_${childId}_dropoff'),
      ]);
    }
    
    await Future.wait(subscriptions);
  }

  /// Subscribe to driver-specific topics
  Future<void> subscribeToDriverTopics(String driverId, List<String> busIds) async {
    final subscriptions = <Future<void>>[
      subscribeToTopic('driver_$driverId'),
    ];
    
    for (final busId in busIds) {
      subscriptions.addAll([
        subscribeToTopic('bus_$busId'),
        subscribeToTopic('bus_${busId}_route'),
        subscribeToTopic('bus_${busId}_maintenance'),
      ]);
    }
    
    await Future.wait(subscriptions);
  }

  /// Subscribe to admin-specific topics
  Future<void> subscribeToAdminTopics(String schoolId) async {
    await Future.wait([
      subscribeToTopic('school_${schoolId}_admin'),
      subscribeToTopic('school_${schoolId}_incidents'),
      subscribeToTopic('school_${schoolId}_reports'),
      subscribeToTopic('school_${schoolId}_maintenance'),
    ]);
  }

  /// Send notification data to server (for server-side sending)
  Future<void> sendNotificationRequest({
    required String type,
    required Map<String, dynamic> data,
    List<String>? userIds,
    List<String>? topics,
  }) async {
    try {
      // This would typically call your backend API to send notifications
      // For now, we'll just log the request
      debugPrint('Notification request: $type');
      debugPrint('Data: $data');
      debugPrint('Users: $userIds');
      debugPrint('Topics: $topics');
      
      await FirebaseService.instance.logEvent('notification_requested', {
        'type': type,
        'user_count': userIds?.length ?? 0,
        'topic_count': topics?.length ?? 0,
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Notification request failed');
    }
  }

  /// Send pickup notification
  Future<void> sendPickupNotification({
    required String childId,
    required String childName,
    required String busNumber,
    required int estimatedMinutes,
  }) async {
    await sendNotificationRequest(
      type: 'pickup_alert',
      data: {
        'childId': childId,
        'childName': childName,
        'busNumber': busNumber,
        'estimatedMinutes': estimatedMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      },
      topics: ['child_${childId}_pickup'],
    );
  }

  /// Send dropoff notification
  Future<void> sendDropoffNotification({
    required String childId,
    required String childName,
    required String busNumber,
    required int estimatedMinutes,
  }) async {
    await sendNotificationRequest(
      type: 'dropoff_alert',
      data: {
        'childId': childId,
        'childName': childName,
        'busNumber': busNumber,
        'estimatedMinutes': estimatedMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      },
      topics: ['child_${childId}_dropoff'],
    );
  }

  /// Send emergency notification
  Future<void> sendEmergencyNotification({
    required String schoolId,
    required String message,
    required String severity, // 'low', 'medium', 'high', 'critical'
    Map<String, dynamic>? additionalData,
  }) async {
    await sendNotificationRequest(
      type: 'emergency_alert',
      data: {
        'schoolId': schoolId,
        'message': message,
        'severity': severity,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalData,
      },
      topics: ['school_${schoolId}_emergencies'],
    );
  }

  /// Send payment notification
  Future<void> sendPaymentNotification({
    required String userId,
    required String status, // 'success', 'failed', 'pending'
    required double amount,
    required String currency,
    String? transactionId,
  }) async {
    await sendNotificationRequest(
      type: 'payment_status',
      data: {
        'status': status,
        'amount': amount,
        'currency': currency,
        'transactionId': transactionId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      userIds: [userId],
    );
  }

  /// Send maintenance notification
  Future<void> sendMaintenanceNotification({
    required String busId,
    required String busNumber,
    required String message,
    required String type, // 'scheduled', 'urgent', 'completed'
  }) async {
    await sendNotificationRequest(
      type: 'maintenance_alert',
      data: {
        'busId': busId,
        'busNumber': busNumber,
        'message': message,
        'maintenanceType': type,
        'timestamp': DateTime.now().toIso8601String(),
      },
      topics: ['bus_${busId}_maintenance'],
    );
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      // This would clear notifications from the system tray
      // Implementation depends on platform-specific code
      debugPrint('Clearing all notifications');
    } catch (e) {
      debugPrint('Failed to clear notifications: $e');
    }
  }

  /// Handle notification tap navigation
  void handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    
    switch (type) {
      case 'pickup_alert':
      case 'dropoff_alert':
        // Navigate to child tracking screen
        _navigateToChildTracking(data['childId']);
        break;
      case 'emergency_alert':
        // Navigate to emergency screen
        _navigateToEmergency(data['schoolId']);
        break;
      case 'payment_status':
        // Navigate to payment history
        _navigateToPayments();
        break;
      case 'maintenance_alert':
        // Navigate to maintenance screen
        _navigateToMaintenance(data['busId']);
        break;
      default:
        // Navigate to home screen
        _navigateToHome();
    }
  }

  // Navigation helper methods (to be implemented based on your routing)
  void _navigateToChildTracking(String? childId) {
    debugPrint('Navigate to child tracking: $childId');
  }

  void _navigateToEmergency(String? schoolId) {
    debugPrint('Navigate to emergency: $schoolId');
  }

  void _navigateToPayments() {
    debugPrint('Navigate to payments');
  }

  void _navigateToMaintenance(String? busId) {
    debugPrint('Navigate to maintenance: $busId');
  }

  void _navigateToHome() {
    debugPrint('Navigate to home');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Received background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
  
  // Handle background message processing here
  // This could include updating local storage, showing notifications, etc.
}
