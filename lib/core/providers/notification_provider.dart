import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../../shared/models/user_model.dart';

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Notification state for managing notification data
class NotificationState {
  final List<RemoteMessage> notifications;
  final bool isInitialized;
  final String? fcmToken;
  final List<String> subscribedTopics;

  const NotificationState({
    this.notifications = const [],
    this.isInitialized = false,
    this.fcmToken,
    this.subscribedTopics = const [],
  });

  NotificationState copyWith({
    List<RemoteMessage>? notifications,
    bool? isInitialized,
    String? fcmToken,
    List<String>? subscribedTopics,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isInitialized: isInitialized ?? this.isInitialized,
      fcmToken: fcmToken ?? this.fcmToken,
      subscribedTopics: subscribedTopics ?? this.subscribedTopics,
    );
  }
}

/// Notification controller for managing notification state
class NotificationController extends StateNotifier<NotificationState> {
  NotificationController() : super(const NotificationState()) {
    _initialize();
  }

  final NotificationService _notificationService = NotificationService.instance;

  /// Initialize notification service
  Future<void> _initialize() async {
    await _notificationService.initialize(
      onMessageReceived: _handleMessageReceived,
      onMessageOpenedApp: _handleMessageOpenedApp,
    );
    
    state = state.copyWith(
      isInitialized: true,
      fcmToken: _notificationService.fcmToken,
    );
  }

  /// Handle received message
  void _handleMessageReceived(RemoteMessage message) {
    final updatedNotifications = [...state.notifications, message];
    state = state.copyWith(notifications: updatedNotifications);
  }

  /// Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    _notificationService.handleNotificationTap(message);
  }

  /// Subscribe to topics based on user role
  Future<void> subscribeToUserTopics(UserModel user, {
    List<String>? childIds,
    List<String>? busIds,
  }) async {
    final topics = <String>[];
    
    switch (user.role) {
      case UserRole.parent:
        if (user.schoolId != null) {
          await _notificationService.subscribeToSchoolTopics(user.schoolId!);
          topics.addAll(['school_${user.schoolId}', 'school_${user.schoolId}_announcements']);
        }
        
        if (childIds != null) {
          await _notificationService.subscribeToParentTopics(user.uid, childIds);
          topics.add('parent_${user.uid}');
          for (final childId in childIds) {
            topics.addAll(['child_$childId', 'child_${childId}_pickup', 'child_${childId}_dropoff']);
          }
        }
        break;
        
      case UserRole.driver:
        if (user.schoolId != null) {
          await _notificationService.subscribeToSchoolTopics(user.schoolId!);
          topics.addAll(['school_${user.schoolId}', 'school_${user.schoolId}_announcements']);
        }
        
        if (busIds != null) {
          await _notificationService.subscribeToDriverTopics(user.uid, busIds);
          topics.add('driver_${user.uid}');
          for (final busId in busIds) {
            topics.addAll(['bus_$busId', 'bus_${busId}_route', 'bus_${busId}_maintenance']);
          }
        }
        break;
        
      case UserRole.schoolAdmin:
        if (user.schoolId != null) {
          await _notificationService.subscribeToSchoolTopics(user.schoolId!);
          await _notificationService.subscribeToAdminTopics(user.schoolId!);
          topics.addAll([
            'school_${user.schoolId}',
            'school_${user.schoolId}_announcements',
            'school_${user.schoolId}_admin',
            'school_${user.schoolId}_incidents',
            'school_${user.schoolId}_reports',
            'school_${user.schoolId}_maintenance',
          ]);
        }
        break;
        
      case UserRole.superAdmin:
        // Super admin gets notifications from all schools
        await _notificationService.subscribeToTopic('super_admin');
        await _notificationService.subscribeToTopic('all_schools');
        topics.addAll(['super_admin', 'all_schools']);
        break;
    }
    
    state = state.copyWith(subscribedTopics: topics);
  }

  /// Send pickup notification
  Future<void> sendPickupNotification({
    required String childId,
    required String childName,
    required String busNumber,
    required int estimatedMinutes,
  }) async {
    await _notificationService.sendPickupNotification(
      childId: childId,
      childName: childName,
      busNumber: busNumber,
      estimatedMinutes: estimatedMinutes,
    );
  }

  /// Send dropoff notification
  Future<void> sendDropoffNotification({
    required String childId,
    required String childName,
    required String busNumber,
    required int estimatedMinutes,
  }) async {
    await _notificationService.sendDropoffNotification(
      childId: childId,
      childName: childName,
      busNumber: busNumber,
      estimatedMinutes: estimatedMinutes,
    );
  }

  /// Send emergency notification
  Future<void> sendEmergencyNotification({
    required String schoolId,
    required String message,
    required String severity,
    Map<String, dynamic>? additionalData,
  }) async {
    await _notificationService.sendEmergencyNotification(
      schoolId: schoolId,
      message: message,
      severity: severity,
      additionalData: additionalData,
    );
  }

  /// Send payment notification
  Future<void> sendPaymentNotification({
    required String userId,
    required String status,
    required double amount,
    required String currency,
    String? transactionId,
  }) async {
    await _notificationService.sendPaymentNotification(
      userId: userId,
      status: status,
      amount: amount,
      currency: currency,
      transactionId: transactionId,
    );
  }

  /// Send maintenance notification
  Future<void> sendMaintenanceNotification({
    required String busId,
    required String busNumber,
    required String message,
    required String type,
  }) async {
    await _notificationService.sendMaintenanceNotification(
      busId: busId,
      busNumber: busNumber,
      message: message,
      type: type,
    );
  }

  /// Mark notification as read
  void markAsRead(String messageId) {
    final updatedNotifications = state.notifications
        .where((notification) => notification.messageId != messageId)
        .toList();
    state = state.copyWith(notifications: updatedNotifications);
  }

  /// Clear all notifications
  void clearAllNotifications() {
    state = state.copyWith(notifications: []);
    _notificationService.clearAllNotifications();
  }

  /// Get unread notification count
  int get unreadCount => state.notifications.length;

  /// Get notifications by type
  List<RemoteMessage> getNotificationsByType(String type) {
    return state.notifications
        .where((notification) => notification.data['type'] == type)
        .toList();
  }

  /// Subscribe to additional topic
  Future<void> subscribeToTopic(String topic) async {
    await _notificationService.subscribeToTopic(topic);
    final updatedTopics = [...state.subscribedTopics, topic];
    state = state.copyWith(subscribedTopics: updatedTopics);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _notificationService.unsubscribeFromTopic(topic);
    final updatedTopics = state.subscribedTopics
        .where((t) => t != topic)
        .toList();
    state = state.copyWith(subscribedTopics: updatedTopics);
  }
}

/// Provider for notification controller
final notificationControllerProvider = StateNotifierProvider<NotificationController, NotificationState>((ref) {
  return NotificationController();
});

/// Provider for unread notification count
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(notificationControllerProvider);
  return notificationState.notifications.length;
});

/// Provider for notifications by type
final notificationsByTypeProvider = Provider.family<List<RemoteMessage>, String>((ref, type) {
  final notificationState = ref.watch(notificationControllerProvider);
  return notificationState.notifications
      .where((notification) => notification.data['type'] == type)
      .toList();
});

/// Provider for checking if notifications are enabled
final notificationsEnabledProvider = Provider<bool>((ref) {
  final notificationState = ref.watch(notificationControllerProvider);
  return notificationState.isInitialized && notificationState.fcmToken != null;
});

/// Provider for FCM token
final fcmTokenProvider = Provider<String?>((ref) {
  final notificationState = ref.watch(notificationControllerProvider);
  return notificationState.fcmToken;
});

/// Provider for subscribed topics
final subscribedTopicsProvider = Provider<List<String>>((ref) {
  final notificationState = ref.watch(notificationControllerProvider);
  return notificationState.subscribedTopics;
});

/// Notification types enum
enum NotificationType {
  pickupAlert,
  dropoffAlert,
  emergencyAlert,
  paymentStatus,
  maintenanceAlert,
  announcement,
  incident,
  report,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.pickupAlert:
        return 'pickup_alert';
      case NotificationType.dropoffAlert:
        return 'dropoff_alert';
      case NotificationType.emergencyAlert:
        return 'emergency_alert';
      case NotificationType.paymentStatus:
        return 'payment_status';
      case NotificationType.maintenanceAlert:
        return 'maintenance_alert';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.incident:
        return 'incident';
      case NotificationType.report:
        return 'report';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.pickupAlert:
        return 'Pickup Alert';
      case NotificationType.dropoffAlert:
        return 'Drop-off Alert';
      case NotificationType.emergencyAlert:
        return 'Emergency Alert';
      case NotificationType.paymentStatus:
        return 'Payment Status';
      case NotificationType.maintenanceAlert:
        return 'Maintenance Alert';
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.incident:
        return 'Incident';
      case NotificationType.report:
        return 'Report';
    }
  }
}
