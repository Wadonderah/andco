import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 18)
class NotificationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String? schoolId;

  @HiveField(3)
  final NotificationType type;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final String body;

  @HiveField(6)
  final Map<String, dynamic> data;

  @HiveField(7)
  final NotificationPriority priority;

  @HiveField(8)
  final bool isRead;

  @HiveField(9)
  final DateTime? readAt;

  @HiveField(10)
  final String? imageUrl;

  @HiveField(11)
  final String? actionUrl;

  @HiveField(12)
  final DateTime? expiresAt;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime updatedAt;

  @HiveField(15)
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    this.schoolId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    this.readAt,
    this.imageUrl,
    this.actionUrl,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      schoolId: map['schoolId'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.general,
      ),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : {},
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == 'NotificationPriority.${map['priority']}',
        orElse: () => NotificationPriority.normal,
      ),
      isRead: map['isRead'] ?? false,
      readAt: map['readAt'] is Timestamp 
          ? (map['readAt'] as Timestamp).toDate()
          : map['readAt'] != null 
              ? DateTime.parse(map['readAt'])
              : null,
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
      expiresAt: map['expiresAt'] is Timestamp 
          ? (map['expiresAt'] as Timestamp).toDate()
          : map['expiresAt'] != null 
              ? DateTime.parse(map['expiresAt'])
              : null,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt']),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'schoolId': schoolId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'data': data,
      'priority': priority.toString().split('.').last,
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? schoolId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? readAt,
    String? imageUrl,
    String? actionUrl,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasAction => actionUrl != null && actionUrl!.isNotEmpty;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isUnread => !isRead;

  Duration get age => DateTime.now().difference(createdAt);

  String get priorityDisplayName {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  String get typeDisplayName {
    switch (type) {
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
      case NotificationType.general:
        return 'General';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

@HiveType(typeId: 19)
enum NotificationType {
  @HiveField(0)
  pickupAlert,

  @HiveField(1)
  dropoffAlert,

  @HiveField(2)
  emergencyAlert,

  @HiveField(3)
  paymentStatus,

  @HiveField(4)
  maintenanceAlert,

  @HiveField(5)
  announcement,

  @HiveField(6)
  incident,

  @HiveField(7)
  report,

  @HiveField(8)
  general,
}

@HiveType(typeId: 20)
enum NotificationPriority {
  @HiveField(0)
  low,

  @HiveField(1)
  normal,

  @HiveField(2)
  high,

  @HiveField(3)
  urgent,
}
