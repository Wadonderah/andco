import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'firebase_service.dart';

/// Service for managing push notifications
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseService.instance.messaging;

  // FCM Server Key (replace with your actual server key)
  static const String _serverKey = 'your_fcm_server_key_here';
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

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
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission for notifications');
    } else {
      debugPrint(
          'User declined or has not accepted permission for notifications');
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
      await FirebaseService.instance
          .logError(e, StackTrace.current, reason: 'Topic subscription failed');
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
  Future<void> subscribeToParentTopics(
      String parentId, List<String> childIds) async {
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
  Future<void> subscribeToDriverTopics(
      String driverId, List<String> busIds) async {
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

  /// Send comprehensive payment success notification with receipt
  Future<void> sendPaymentSuccessWithReceipt({
    required String userId,
    required String paymentMethod,
    required double amount,
    required String currency,
    required String transactionId,
    String? receiptNumber,
    String? phoneNumber,
    String? email,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get user's FCM token
      final fcmToken = await _getUserFCMToken(userId);

      // Send push notification
      await sendAdvancedNotification(
        token: fcmToken,
        title: 'Payment Successful! 🎉',
        body:
            'Your $paymentMethod payment of $currency ${amount.toStringAsFixed(2)} has been processed successfully.',
        data: {
          'type': 'payment_success',
          'paymentMethod': paymentMethod,
          'amount': amount,
          'currency': currency,
          'transactionId': transactionId,
          'receiptNumber': receiptNumber,
          ...?additionalData,
        },
        imageUrl: 'https://your-app.com/images/payment-success.png',
        actions: [
          NotificationAction(id: 'view_receipt', title: 'View Receipt'),
          NotificationAction(id: 'download_receipt', title: 'Download'),
        ],
      );

      // Send SMS confirmation if phone number provided
      if (phoneNumber != null) {
        await _sendPaymentSMS(
          phoneNumber: phoneNumber,
          paymentMethod: paymentMethod,
          amount: amount,
          currency: currency,
          transactionId: transactionId,
          receiptNumber: receiptNumber,
        );
      }

      // Send email receipt if email provided
      if (email != null) {
        await _sendEmailReceipt(
          email: email,
          paymentMethod: paymentMethod,
          amount: amount,
          currency: currency,
          transactionId: transactionId,
          receiptNumber: receiptNumber,
          additionalData: additionalData,
        );
      }

      // Log the notification
      await FirebaseService.instance.logEvent('payment_notification_sent', {
        'userId': userId,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'currency': currency,
        'hasEmail': email != null,
        'hasSMS': phoneNumber != null,
      });

      debugPrint(
          '✅ Comprehensive payment notification sent for: $transactionId');
    } catch (e) {
      debugPrint('❌ Error sending payment notification: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to send payment notification');
    }
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

  /// Send advanced notification with rich content
  Future<bool> sendAdvancedNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
    List<NotificationAction>? actions,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final payload = {
        'to': token,
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': data ?? {},
        'priority': priority.value,
        'android': {
          'priority': priority.androidPriority,
          'notification': {
            'channel_id': 'default',
            'sound': 'default',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            if (imageUrl != null) 'image': imageUrl,
            if (actions != null)
              'actions': actions.map((action) => action.toMap()).toList(),
          },
        },
        'apns': {
          'headers': {
            'apns-priority': priority.iosPriority,
          },
          'payload': {
            'aps': {
              'alert': {
                'title': title,
                'body': body,
              },
              'sound': 'default',
              'badge': 1,
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error sending advanced notification: $e');
      return false;
    }
  }

  /// Schedule notification for later delivery
  Future<bool> scheduleNotification({
    required String userId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = {
        'userId': userId,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.toIso8601String(),
        'data': data ?? {},
        'status': 'scheduled',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseService.instance.firestore
          .collection('scheduled_notifications')
          .add(notificationData);

      return true;
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
      return false;
    }
  }

  /// Get user's FCM token from Firestore
  Future<String> _getUserFCMToken(String userId) async {
    try {
      final userDoc = await FirebaseService.instance.firestore
          .collection('users')
          .doc(userId)
          .get();

      return userDoc.data()?['fcmToken'] ?? '';
    } catch (e) {
      debugPrint('❌ Error getting user FCM token: $e');
      return '';
    }
  }

  /// Send payment SMS notification
  Future<void> _sendPaymentSMS({
    required String phoneNumber,
    required String paymentMethod,
    required double amount,
    required String currency,
    required String transactionId,
    String? receiptNumber,
  }) async {
    try {
      final message = receiptNumber != null
          ? 'Payment Successful! Your $paymentMethod payment of $currency ${amount.toStringAsFixed(2)} has been processed. Receipt: $receiptNumber. Transaction ID: $transactionId'
          : 'Payment Successful! Your $paymentMethod payment of $currency ${amount.toStringAsFixed(2)} has been processed. Transaction ID: $transactionId';

      // This would integrate with your SMS service
      debugPrint('📱 SMS sent to $phoneNumber: $message');

      // Log SMS sent
      await FirebaseService.instance.logEvent('payment_sms_sent', {
        'phoneNumber': phoneNumber,
        'paymentMethod': paymentMethod,
        'amount': amount,
      });
    } catch (e) {
      debugPrint('❌ Error sending payment SMS: $e');
    }
  }

  /// Send payment failure SMS
  Future<void> _sendFailureSMS({
    required String phoneNumber,
    required String paymentMethod,
    required double amount,
    required String currency,
    required String reason,
  }) async {
    try {
      final message =
          'Payment Failed: Your $paymentMethod payment of $currency ${amount.toStringAsFixed(2)} could not be processed. Reason: $reason. Please try again or contact support.';

      // This would integrate with your SMS service
      debugPrint('📱 Failure SMS sent to $phoneNumber: $message');

      // Log SMS sent
      await FirebaseService.instance.logEvent('payment_failure_sms_sent', {
        'phoneNumber': phoneNumber,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'reason': reason,
      });
    } catch (e) {
      debugPrint('❌ Error sending failure SMS: $e');
    }
  }

  /// Send email receipt
  Future<void> _sendEmailReceipt({
    required String email,
    required String paymentMethod,
    required double amount,
    required String currency,
    required String transactionId,
    String? receiptNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create receipt data
      final receiptData = {
        'email': email,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'currency': currency,
        'transactionId': transactionId,
        'receiptNumber': receiptNumber,
        'timestamp': DateTime.now().toIso8601String(),
        'additionalData': additionalData,
      };

      // Store receipt in Firestore for email service to process
      await FirebaseService.instance.firestore.collection('email_queue').add({
        'type': 'payment_receipt',
        'to': email,
        'subject': 'Payment Receipt - $currency ${amount.toStringAsFixed(2)}',
        'template': 'payment_receipt',
        'data': receiptData,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('📧 Email receipt queued for: $email');

      // Log email queued
      await FirebaseService.instance.logEvent('payment_email_queued', {
        'email': email,
        'paymentMethod': paymentMethod,
        'amount': amount,
      });
    } catch (e) {
      debugPrint('❌ Error queuing email receipt: $e');
    }
  }
}

/// Notification priority enum
enum NotificationPriority {
  low,
  normal,
  high,
}

extension NotificationPriorityExtension on NotificationPriority {
  String get value {
    switch (this) {
      case NotificationPriority.low:
        return 'normal';
      case NotificationPriority.normal:
        return 'high';
      case NotificationPriority.high:
        return 'high';
    }
  }

  String get androidPriority {
    switch (this) {
      case NotificationPriority.low:
        return 'min';
      case NotificationPriority.normal:
        return 'default';
      case NotificationPriority.high:
        return 'high';
    }
  }

  String get iosPriority {
    switch (this) {
      case NotificationPriority.low:
        return '5';
      case NotificationPriority.normal:
        return '5';
      case NotificationPriority.high:
        return '10';
    }
  }
}

/// Notification action model
class NotificationAction {
  final String id;
  final String title;
  final String? icon;

  NotificationAction({
    required this.id,
    required this.title,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'action': id,
      'title': title,
      if (icon != null) 'icon': icon,
    };
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

  // Call the stored background message handler if it exists
  final instance = NotificationService._instance;
  if (instance != null && instance._onBackgroundMessage != null) {
    instance._onBackgroundMessage!(message);
  }
}

/// Notification item model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String childName;
  final String location;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.childName,
    required this.location,
  });
}

/// Notification types
enum NotificationType {
  pickup,
  dropoff,
  eta,
  delay,
  emergency,
  general,
}

/// Extension to add real-time notification streaming
extension NotificationServiceExtension on NotificationService {
  /// Get notifications stream for current user
  Stream<List<NotificationItem>> getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationItem(
          id: doc.id,
          title: data['title'] ?? 'Notification',
          message: data['message'] ?? '',
          type: _parseNotificationType(data['type']),
          timestamp: data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          isRead: data['isRead'] ?? false,
          childName: data['childName'] ?? '',
          location: data['location'] ?? '',
        );
      }).toList();
    });
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'pickup':
        return NotificationType.pickup;
      case 'dropoff':
        return NotificationType.dropoff;
      case 'eta':
        return NotificationType.eta;
      case 'delay':
        return NotificationType.delay;
      case 'emergency':
        return NotificationType.emergency;
      default:
        return NotificationType.pickup;
    }
  }
}
