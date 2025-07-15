import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance model for tracking student pickup/dropoff
class AttendanceModel {
  final String id;
  final String childId;
  final String routeId;
  final String busId;
  final String driverId;
  final String stopId;
  final DateTime date;
  final AttendanceType type;
  final AttendanceStatus status;
  final DateTime? scheduledTime;
  final DateTime? actualTime;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? photoUrl;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  AttendanceModel({
    required this.id,
    required this.childId,
    required this.routeId,
    required this.busId,
    required this.driverId,
    required this.stopId,
    required this.date,
    required this.type,
    required this.status,
    this.scheduledTime,
    this.actualTime,
    this.latitude,
    this.longitude,
    this.notes,
    this.photoUrl,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? '',
      childId: map['childId'] ?? '',
      routeId: map['routeId'] ?? '',
      busId: map['busId'] ?? '',
      driverId: map['driverId'] ?? '',
      stopId: map['stopId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: AttendanceType.values.firstWhere(
        (e) => e.toString() == 'AttendanceType.${map['type']}',
        orElse: () => AttendanceType.pickup,
      ),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == 'AttendanceStatus.${map['status']}',
        orElse: () => AttendanceStatus.scheduled,
      ),
      scheduledTime: (map['scheduledTime'] as Timestamp?)?.toDate(),
      actualTime: (map['actualTime'] as Timestamp?)?.toDate(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      notes: map['notes'],
      photoUrl: map['photoUrl'],
      isVerified: map['isVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'routeId': routeId,
      'busId': busId,
      'driverId': driverId,
      'stopId': stopId,
      'date': Timestamp.fromDate(date),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'scheduledTime': scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,
      'actualTime': actualTime != null ? Timestamp.fromDate(actualTime!) : null,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'photoUrl': photoUrl,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? childId,
    String? routeId,
    String? busId,
    String? driverId,
    String? stopId,
    DateTime? date,
    AttendanceType? type,
    AttendanceStatus? status,
    DateTime? scheduledTime,
    DateTime? actualTime,
    double? latitude,
    double? longitude,
    String? notes,
    String? photoUrl,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      routeId: routeId ?? this.routeId,
      busId: busId ?? this.busId,
      driverId: driverId ?? this.driverId,
      stopId: stopId ?? this.stopId,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isPickup => type == AttendanceType.pickup;
  bool get isDropoff => type == AttendanceType.dropoff;
  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isLate => status == AttendanceStatus.late;
  bool get isCompleted => status == AttendanceStatus.present || status == AttendanceStatus.absent;
  
  bool get isOnTime {
    if (actualTime == null || scheduledTime == null) return false;
    return actualTime!.difference(scheduledTime!).inMinutes.abs() <= 5;
  }

  String get statusDisplayName {
    switch (status) {
      case AttendanceStatus.scheduled:
        return 'Scheduled';
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.early:
        return 'Early';
      case AttendanceStatus.noShow:
        return 'No Show';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case AttendanceType.pickup:
        return 'Pickup';
      case AttendanceType.dropoff:
        return 'Dropoff';
    }
  }
}

/// Attendance type enum
enum AttendanceType {
  pickup,
  dropoff,
}

/// Attendance status enum
enum AttendanceStatus {
  scheduled,
  present,
  absent,
  late,
  early,
  noShow,
}

/// Daily attendance summary model
class DailyAttendanceSummary {
  final String id;
  final String routeId;
  final String driverId;
  final DateTime date;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int earlyCount;
  final int noShowCount;
  final List<AttendanceModel> attendances;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyAttendanceSummary({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.date,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.earlyCount,
    required this.noShowCount,
    required this.attendances,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyAttendanceSummary.fromMap(Map<String, dynamic> map) {
    return DailyAttendanceSummary(
      id: map['id'] ?? '',
      routeId: map['routeId'] ?? '',
      driverId: map['driverId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalStudents: map['totalStudents'] ?? 0,
      presentCount: map['presentCount'] ?? 0,
      absentCount: map['absentCount'] ?? 0,
      lateCount: map['lateCount'] ?? 0,
      earlyCount: map['earlyCount'] ?? 0,
      noShowCount: map['noShowCount'] ?? 0,
      attendances: (map['attendances'] as List<dynamic>?)
          ?.map((attendance) => AttendanceModel.fromMap(attendance as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'driverId': driverId,
      'date': Timestamp.fromDate(date),
      'totalStudents': totalStudents,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'lateCount': lateCount,
      'earlyCount': earlyCount,
      'noShowCount': noShowCount,
      'attendances': attendances.map((attendance) => attendance.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods
  double get attendanceRate => totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0;
  double get punctualityRate => presentCount > 0 ? ((presentCount - lateCount) / presentCount) * 100 : 0;
  bool get isComplete => (presentCount + absentCount + noShowCount) == totalStudents;
}

/// Safety check model for daily vehicle inspections
class SafetyCheckModel {
  final String id;
  final String driverId;
  final String busId;
  final DateTime date;
  final SafetyCheckType type;
  final List<SafetyCheckItem> items;
  final SafetyCheckStatus status;
  final String? notes;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  SafetyCheckModel({
    required this.id,
    required this.driverId,
    required this.busId,
    required this.date,
    required this.type,
    required this.items,
    required this.status,
    this.notes,
    required this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SafetyCheckModel.fromMap(Map<String, dynamic> map) {
    return SafetyCheckModel(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      busId: map['busId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: SafetyCheckType.values.firstWhere(
        (e) => e.toString() == 'SafetyCheckType.${map['type']}',
        orElse: () => SafetyCheckType.preTrip,
      ),
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => SafetyCheckItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      status: SafetyCheckStatus.values.firstWhere(
        (e) => e.toString() == 'SafetyCheckStatus.${map['status']}',
        orElse: () => SafetyCheckStatus.pending,
      ),
      notes: map['notes'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'busId': busId,
      'date': Timestamp.fromDate(date),
      'type': type.toString().split('.').last,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods
  bool get isPassed => status == SafetyCheckStatus.passed;
  bool get isFailed => status == SafetyCheckStatus.failed;
  bool get hasCriticalIssues => items.any((item) => item.isCritical && !item.isPassed);
  int get passedItemsCount => items.where((item) => item.isPassed).length;
  int get failedItemsCount => items.where((item) => !item.isPassed).length;
}

/// Safety check item model
class SafetyCheckItem {
  final String id;
  final String name;
  final String description;
  final bool isPassed;
  final bool isCritical;
  final String? notes;
  final String? photoUrl;

  SafetyCheckItem({
    required this.id,
    required this.name,
    required this.description,
    required this.isPassed,
    required this.isCritical,
    this.notes,
    this.photoUrl,
  });

  factory SafetyCheckItem.fromMap(Map<String, dynamic> map) {
    return SafetyCheckItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isPassed: map['isPassed'] ?? false,
      isCritical: map['isCritical'] ?? false,
      notes: map['notes'],
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isPassed': isPassed,
      'isCritical': isCritical,
      'notes': notes,
      'photoUrl': photoUrl,
    };
  }
}

/// Safety check type enum
enum SafetyCheckType {
  preTrip,
  postTrip,
  weekly,
  monthly,
}

/// Safety check status enum
enum SafetyCheckStatus {
  pending,
  passed,
  failed,
  needsAttention,
}
