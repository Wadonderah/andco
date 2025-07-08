import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/notification_model.dart';
import 'base_repository.dart';

/// Repository for managing notification data
class NotificationRepository extends BaseRepository<NotificationModel> {
  @override
  String get collectionName => 'notifications';

  @override
  NotificationModel fromMap(Map<String, dynamic> map) => NotificationModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(NotificationModel model) => model.toMap();

  /// Get notifications for a specific user
  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    return getWhere('userId', userId);
  }

  /// Get notifications stream for a specific user
  Stream<List<NotificationModel>> getNotificationsStreamForUser(String userId) {
    return getStreamWhere('userId', userId);
  }

  /// Get notifications for a specific school
  Future<List<NotificationModel>> getNotificationsForSchool(String schoolId) async {
    return getWhere('schoolId', schoolId);
  }

  /// Get notifications stream for a specific school
  Stream<List<NotificationModel>> getNotificationsStreamForSchool(String schoolId) {
    return getStreamWhere('schoolId', schoolId);
  }

  /// Get notifications by type
  Future<List<NotificationModel>> getNotificationsByType(NotificationType type) async {
    return getWhere('type', type.toString().split('.').last);
  }

  /// Get notifications stream by type
  Stream<List<NotificationModel>> getNotificationsStreamByType(NotificationType type) {
    return getStreamWhere('type', type.toString().split('.').last);
  }

  /// Get notifications by priority
  Future<List<NotificationModel>> getNotificationsByPriority(NotificationPriority priority) async {
    return getWhere('priority', priority.toString().split('.').last);
  }

  /// Get notifications stream by priority
  Stream<List<NotificationModel>> getNotificationsStreamByPriority(NotificationPriority priority) {
    return getStreamWhere('priority', priority.toString().split('.').last);
  }

  /// Get unread notifications for user
  Future<List<NotificationModel>> getUnreadNotificationsForUser(String userId) async {
    try {
      final querySnapshot = await collection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final userNotifications = await getNotificationsForUser(userId);
      return userNotifications.where((notification) => !notification.isRead).toList();
    }
  }

  /// Get unread notifications stream for user
  Stream<List<NotificationModel>> getUnreadNotificationsStreamForUser(String userId) {
    try {
      return collection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      // Fallback to filtering user notifications stream
      return getNotificationsStreamForUser(userId)
          .map((notifications) => notifications.where((n) => !n.isRead).toList());
    }
  }

  /// Get read notifications for user
  Future<List<NotificationModel>> getReadNotificationsForUser(String userId) async {
    try {
      final querySnapshot = await collection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final userNotifications = await getNotificationsForUser(userId);
      return userNotifications.where((notification) => notification.isRead).toList();
    }
  }

  /// Get recent notifications (last 30 days)
  Future<List<NotificationModel>> getRecentNotifications({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    try {
      final querySnapshot = await collection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allNotifications = await getAll();
      return allNotifications
          .where((notification) => notification.createdAt.isAfter(startDate))
          .toList();
    }
  }

  /// Get user recent notifications
  Future<List<NotificationModel>> getUserRecentNotifications(
    String userId, {
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    try {
      final querySnapshot = await collection
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback approach
      final userNotifications = await getNotificationsForUser(userId);
      return userNotifications
          .where((notification) => notification.createdAt.isAfter(startDate))
          .toList();
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await updateById(notificationId, {
      'isRead': true,
      'readAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now().toIso8601String();
    
    for (final id in notificationIds) {
      batch.update(collection.doc(id), {
        'isRead': true,
        'readAt': now,
        'updatedAt': now,
      });
    }
    
    await batch.commit();
  }

  /// Mark all user notifications as read
  Future<void> markAllAsReadForUser(String userId) async {
    final unreadNotifications = await getUnreadNotificationsForUser(userId);
    final notificationIds = unreadNotifications.map((n) => n.id).toList();
    
    if (notificationIds.isNotEmpty) {
      await markMultipleAsRead(notificationIds);
    }
  }

  /// Delete expired notifications
  Future<void> deleteExpiredNotifications() async {
    final now = DateTime.now();
    
    try {
      final querySnapshot = await collection
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      // Fallback to individual deletions
      final allNotifications = await getAll();
      final expiredNotifications = allNotifications
          .where((notification) => 
              notification.expiresAt != null && 
              notification.expiresAt!.isBefore(now))
          .toList();
      
      for (final notification in expiredNotifications) {
        await deleteById(notification.id);
      }
    }
  }

  /// Get notification count for user
  Future<int> getNotificationCountForUser(String userId) async {
    final notifications = await getNotificationsForUser(userId);
    return notifications.length;
  }

  /// Get unread notification count for user
  Future<int> getUnreadNotificationCountForUser(String userId) async {
    final unreadNotifications = await getUnreadNotificationsForUser(userId);
    return unreadNotifications.length;
  }

  /// Search notifications by title or body
  Future<List<NotificationModel>> searchNotifications(String query) async {
    final allNotifications = await getAll();
    return allNotifications
        .where((notification) =>
            notification.title.toLowerCase().contains(query.toLowerCase()) ||
            notification.body.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Search user notifications by title or body
  Future<List<NotificationModel>> searchUserNotifications(
    String userId,
    String query,
  ) async {
    final userNotifications = await getNotificationsForUser(userId);
    return userNotifications
        .where((notification) =>
            notification.title.toLowerCase().contains(query.toLowerCase()) ||
            notification.body.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Get notifications within date range
  Future<List<NotificationModel>> getNotificationsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await collection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allNotifications = await getAll();
      return allNotifications
          .where((notification) =>
              notification.createdAt.isAfter(startDate) &&
              notification.createdAt.isBefore(endDate))
          .toList();
    }
  }

  /// Get user notifications within date range
  Future<List<NotificationModel>> getUserNotificationsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await collection
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback approach
      final userNotifications = await getNotificationsForUser(userId);
      return userNotifications
          .where((notification) =>
              notification.createdAt.isAfter(startDate) &&
              notification.createdAt.isBefore(endDate))
          .toList();
    }
  }

  /// Get notification statistics for user
  Future<Map<String, int>> getUserNotificationStatistics(String userId) async {
    final notifications = await getNotificationsForUser(userId);
    
    return {
      'total': notifications.length,
      'unread': notifications.where((n) => !n.isRead).length,
      'read': notifications.where((n) => n.isRead).length,
      'high_priority': notifications.where((n) => n.priority == NotificationPriority.high).length,
      'normal_priority': notifications.where((n) => n.priority == NotificationPriority.normal).length,
      'low_priority': notifications.where((n) => n.priority == NotificationPriority.low).length,
    };
  }

  /// Get notification statistics by type
  Future<Map<String, int>> getNotificationStatisticsByType() async {
    final notifications = await getAll();
    final stats = <String, int>{};
    
    for (final type in NotificationType.values) {
      final typeNotifications = notifications.where((n) => n.type == type);
      stats[type.toString().split('.').last] = typeNotifications.length;
    }
    
    return stats;
  }

  /// Clean up old notifications (older than specified days)
  Future<void> cleanupOldNotifications({int days = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    try {
      final querySnapshot = await collection
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      // Fallback to individual deletions
      final allNotifications = await getAll();
      final oldNotifications = allNotifications
          .where((notification) => notification.createdAt.isBefore(cutoffDate))
          .toList();
      
      for (final notification in oldNotifications) {
        await deleteById(notification.id);
      }
    }
  }
}
