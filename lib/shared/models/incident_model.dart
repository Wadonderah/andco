import 'package:cloud_firestore/cloud_firestore.dart';

/// Incident model for tracking safety events, delays, and issues
class IncidentModel {
  final String id;
  final String schoolId;
  final String? routeId;
  final String? busId;
  final String? driverId;
  final String? childId;
  final IncidentType type;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String title;
  final String description;
  final DateTime incidentTime;
  final double? latitude;
  final double? longitude;
  final String? location;
  final List<String> photoUrls;
  final String reportedBy;
  final String? assignedTo;
  final List<IncidentAction> actions;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  IncidentModel({
    required this.id,
    required this.schoolId,
    this.routeId,
    this.busId,
    this.driverId,
    this.childId,
    required this.type,
    required this.severity,
    required this.status,
    required this.title,
    required this.description,
    required this.incidentTime,
    this.latitude,
    this.longitude,
    this.location,
    required this.photoUrls,
    required this.reportedBy,
    this.assignedTo,
    required this.actions,
    this.resolvedAt,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory IncidentModel.fromMap(Map<String, dynamic> map) {
    return IncidentModel(
      id: map['id'] ?? '',
      schoolId: map['schoolId'] ?? '',
      routeId: map['routeId'],
      busId: map['busId'],
      driverId: map['driverId'],
      childId: map['childId'],
      type: IncidentType.values.firstWhere(
        (e) => e.toString() == 'IncidentType.${map['type']}',
        orElse: () => IncidentType.other,
      ),
      severity: IncidentSeverity.values.firstWhere(
        (e) => e.toString() == 'IncidentSeverity.${map['severity']}',
        orElse: () => IncidentSeverity.low,
      ),
      status: IncidentStatus.values.firstWhere(
        (e) => e.toString() == 'IncidentStatus.${map['status']}',
        orElse: () => IncidentStatus.open,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      incidentTime: (map['incidentTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      location: map['location'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      reportedBy: map['reportedBy'] ?? '',
      assignedTo: map['assignedTo'],
      actions: (map['actions'] as List<dynamic>?)
          ?.map((action) => IncidentAction.fromMap(action as Map<String, dynamic>))
          .toList() ?? [],
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      resolutionNotes: map['resolutionNotes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'routeId': routeId,
      'busId': busId,
      'driverId': driverId,
      'childId': childId,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'status': status.toString().split('.').last,
      'title': title,
      'description': description,
      'incidentTime': Timestamp.fromDate(incidentTime),
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'photoUrls': photoUrls,
      'reportedBy': reportedBy,
      'assignedTo': assignedTo,
      'actions': actions.map((action) => action.toMap()).toList(),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolutionNotes': resolutionNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  IncidentModel copyWith({
    String? id,
    String? schoolId,
    String? routeId,
    String? busId,
    String? driverId,
    String? childId,
    IncidentType? type,
    IncidentSeverity? severity,
    IncidentStatus? status,
    String? title,
    String? description,
    DateTime? incidentTime,
    double? latitude,
    double? longitude,
    String? location,
    List<String>? photoUrls,
    String? reportedBy,
    String? assignedTo,
    List<IncidentAction>? actions,
    DateTime? resolvedAt,
    String? resolutionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      routeId: routeId ?? this.routeId,
      busId: busId ?? this.busId,
      driverId: driverId ?? this.driverId,
      childId: childId ?? this.childId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      incidentTime: incidentTime ?? this.incidentTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      photoUrls: photoUrls ?? this.photoUrls,
      reportedBy: reportedBy ?? this.reportedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      actions: actions ?? this.actions,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isOpen => status == IncidentStatus.open;
  bool get isInProgress => status == IncidentStatus.inProgress;
  bool get isResolved => status == IncidentStatus.resolved;
  bool get isClosed => status == IncidentStatus.closed;
  bool get isCritical => severity == IncidentSeverity.critical;
  bool get isHigh => severity == IncidentSeverity.high;
  
  String get statusDisplayName {
    switch (status) {
      case IncidentStatus.open:
        return 'Open';
      case IncidentStatus.inProgress:
        return 'In Progress';
      case IncidentStatus.resolved:
        return 'Resolved';
      case IncidentStatus.closed:
        return 'Closed';
    }
  }

  String get severityDisplayName {
    switch (severity) {
      case IncidentSeverity.low:
        return 'Low';
      case IncidentSeverity.medium:
        return 'Medium';
      case IncidentSeverity.high:
        return 'High';
      case IncidentSeverity.critical:
        return 'Critical';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case IncidentType.safety:
        return 'Safety';
      case IncidentType.medical:
        return 'Medical';
      case IncidentType.behavioral:
        return 'Behavioral';
      case IncidentType.mechanical:
        return 'Mechanical';
      case IncidentType.delay:
        return 'Delay';
      case IncidentType.accident:
        return 'Accident';
      case IncidentType.weather:
        return 'Weather';
      case IncidentType.other:
        return 'Other';
    }
  }
}

/// Incident action model for tracking follow-up actions
class IncidentAction {
  final String id;
  final String actionType;
  final String description;
  final String performedBy;
  final DateTime performedAt;
  final String? notes;

  IncidentAction({
    required this.id,
    required this.actionType,
    required this.description,
    required this.performedBy,
    required this.performedAt,
    this.notes,
  });

  factory IncidentAction.fromMap(Map<String, dynamic> map) {
    return IncidentAction(
      id: map['id'] ?? '',
      actionType: map['actionType'] ?? '',
      description: map['description'] ?? '',
      performedBy: map['performedBy'] ?? '',
      performedAt: (map['performedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actionType': actionType,
      'description': description,
      'performedBy': performedBy,
      'performedAt': Timestamp.fromDate(performedAt),
      'notes': notes,
    };
  }
}

/// Incident type enum
enum IncidentType {
  safety,
  medical,
  behavioral,
  mechanical,
  delay,
  accident,
  weather,
  other,
}

/// Incident severity enum
enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

/// Incident status enum
enum IncidentStatus {
  open,
  inProgress,
  resolved,
  closed,
}

/// Feedback model for parent and driver feedback
class FeedbackModel {
  final String id;
  final String schoolId;
  final String? routeId;
  final String? driverId;
  final String? childId;
  final FeedbackType type;
  final FeedbackCategory category;
  final FeedbackStatus status;
  final String title;
  final String description;
  final int rating; // 1-5 stars
  final String submittedBy;
  final String submitterRole;
  final String? assignedTo;
  final String? response;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  FeedbackModel({
    required this.id,
    required this.schoolId,
    this.routeId,
    this.driverId,
    this.childId,
    required this.type,
    required this.category,
    required this.status,
    required this.title,
    required this.description,
    required this.rating,
    required this.submittedBy,
    required this.submitterRole,
    this.assignedTo,
    this.response,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] ?? '',
      schoolId: map['schoolId'] ?? '',
      routeId: map['routeId'],
      driverId: map['driverId'],
      childId: map['childId'],
      type: FeedbackType.values.firstWhere(
        (e) => e.toString() == 'FeedbackType.${map['type']}',
        orElse: () => FeedbackType.general,
      ),
      category: FeedbackCategory.values.firstWhere(
        (e) => e.toString() == 'FeedbackCategory.${map['category']}',
        orElse: () => FeedbackCategory.general,
      ),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.toString() == 'FeedbackStatus.${map['status']}',
        orElse: () => FeedbackStatus.pending,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rating: map['rating'] ?? 1,
      submittedBy: map['submittedBy'] ?? '',
      submitterRole: map['submitterRole'] ?? '',
      assignedTo: map['assignedTo'],
      response: map['response'],
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'routeId': routeId,
      'driverId': driverId,
      'childId': childId,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'title': title,
      'description': description,
      'rating': rating,
      'submittedBy': submittedBy,
      'submitterRole': submitterRole,
      'assignedTo': assignedTo,
      'response': response,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  // Helper methods
  bool get isPending => status == FeedbackStatus.pending;
  bool get isInProgress => status == FeedbackStatus.inProgress;
  bool get isResolved => status == FeedbackStatus.resolved;
  bool get isPositive => rating >= 4;
  bool get isNegative => rating <= 2;
}

/// Feedback type enum
enum FeedbackType {
  complaint,
  suggestion,
  compliment,
  general,
}

/// Feedback category enum
enum FeedbackCategory {
  driver,
  route,
  safety,
  communication,
  service,
  general,
}

/// Feedback status enum
enum FeedbackStatus {
  pending,
  inProgress,
  resolved,
}
