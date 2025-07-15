import 'package:cloud_firestore/cloud_firestore.dart';

/// School model for managing school information and approval workflow
class SchoolModel {
  final String id;
  final String name;
  final String address;
  final String contactEmail;
  final String contactPhone;
  final String principalName;
  final String? principalEmail;
  final String? principalPhone;
  final String? website;
  final String? description;
  final SchoolStatus status;
  final SchoolType type;
  final String subscriptionPlan;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final String? approvedBy; // Super Admin ID who approved
  final String? rejectionReason;
  final Map<String, double>? coordinates;
  final List<String> documents; // Required documents for approval
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;
  
  // Statistics (calculated fields)
  final int studentCount;
  final int driverCount;
  final int busCount;
  final int routeCount;
  final double monthlyRevenue;
  final DateTime? lastActivity;

  SchoolModel({
    required this.id,
    required this.name,
    required this.address,
    required this.contactEmail,
    required this.contactPhone,
    required this.principalName,
    this.principalEmail,
    this.principalPhone,
    this.website,
    this.description,
    required this.status,
    required this.type,
    required this.subscriptionPlan,
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
    this.coordinates,
    this.documents = const [],
    this.settings,
    this.metadata,
    this.studentCount = 0,
    this.driverCount = 0,
    this.busCount = 0,
    this.routeCount = 0,
    this.monthlyRevenue = 0.0,
    this.lastActivity,
  });

  factory SchoolModel.fromMap(Map<String, dynamic> map) {
    return SchoolModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      principalName: map['principalName'] ?? '',
      principalEmail: map['principalEmail'],
      principalPhone: map['principalPhone'],
      website: map['website'],
      description: map['description'],
      status: SchoolStatus.values.firstWhere(
        (e) => e.toString() == 'SchoolStatus.${map['status']}',
        orElse: () => SchoolStatus.pending,
      ),
      type: SchoolType.values.firstWhere(
        (e) => e.toString() == 'SchoolType.${map['type']}',
        orElse: () => SchoolType.elementary,
      ),
      subscriptionPlan: map['subscriptionPlan'] ?? 'basic',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      approvedBy: map['approvedBy'],
      rejectionReason: map['rejectionReason'],
      coordinates: map['coordinates'] != null 
        ? Map<String, double>.from(map['coordinates'])
        : null,
      documents: List<String>.from(map['documents'] ?? []),
      settings: map['settings'],
      metadata: map['metadata'],
      studentCount: map['studentCount'] ?? 0,
      driverCount: map['driverCount'] ?? 0,
      busCount: map['busCount'] ?? 0,
      routeCount: map['routeCount'] ?? 0,
      monthlyRevenue: (map['monthlyRevenue'] ?? 0.0).toDouble(),
      lastActivity: (map['lastActivity'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'principalName': principalName,
      'principalEmail': principalEmail,
      'principalPhone': principalPhone,
      'website': website,
      'description': description,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'subscriptionPlan': subscriptionPlan,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'coordinates': coordinates,
      'documents': documents,
      'settings': settings,
      'metadata': metadata,
      'studentCount': studentCount,
      'driverCount': driverCount,
      'busCount': busCount,
      'routeCount': routeCount,
      'monthlyRevenue': monthlyRevenue,
      'lastActivity': lastActivity != null ? Timestamp.fromDate(lastActivity!) : null,
    };
  }

  SchoolModel copyWith({
    String? id,
    String? name,
    String? address,
    String? contactEmail,
    String? contactPhone,
    String? principalName,
    String? principalEmail,
    String? principalPhone,
    String? website,
    String? description,
    SchoolStatus? status,
    SchoolType? type,
    String? subscriptionPlan,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectionReason,
    Map<String, double>? coordinates,
    List<String>? documents,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
    int? studentCount,
    int? driverCount,
    int? busCount,
    int? routeCount,
    double? monthlyRevenue,
    DateTime? lastActivity,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      principalName: principalName ?? this.principalName,
      principalEmail: principalEmail ?? this.principalEmail,
      principalPhone: principalPhone ?? this.principalPhone,
      website: website ?? this.website,
      description: description ?? this.description,
      status: status ?? this.status,
      type: type ?? this.type,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      coordinates: coordinates ?? this.coordinates,
      documents: documents ?? this.documents,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
      studentCount: studentCount ?? this.studentCount,
      driverCount: driverCount ?? this.driverCount,
      busCount: busCount ?? this.busCount,
      routeCount: routeCount ?? this.routeCount,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  // Helper methods
  bool get isPending => status == SchoolStatus.pending;
  bool get isActive => status == SchoolStatus.active;
  bool get isRejected => status == SchoolStatus.rejected;
  bool get isSuspended => status == SchoolStatus.suspended;
  bool get isInactive => status == SchoolStatus.inactive;

  bool get hasRequiredDocuments => documents.isNotEmpty;
  bool get isApproved => status == SchoolStatus.active && approvedAt != null;

  String get statusDisplayName {
    switch (status) {
      case SchoolStatus.pending:
        return 'Pending Approval';
      case SchoolStatus.active:
        return 'Active';
      case SchoolStatus.rejected:
        return 'Rejected';
      case SchoolStatus.suspended:
        return 'Suspended';
      case SchoolStatus.inactive:
        return 'Inactive';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case SchoolType.elementary:
        return 'Elementary School';
      case SchoolType.middle:
        return 'Middle School';
      case SchoolType.high:
        return 'High School';
      case SchoolType.combined:
        return 'Combined School';
      case SchoolType.private:
        return 'Private School';
      case SchoolType.charter:
        return 'Charter School';
    }
  }
}

/// School status enum for approval workflow
enum SchoolStatus {
  pending,    // Awaiting Super Admin approval
  active,     // Approved and operational
  rejected,   // Rejected by Super Admin
  suspended,  // Temporarily suspended
  inactive,   // Deactivated
}

/// School type enum
enum SchoolType {
  elementary,
  middle,
  high,
  combined,
  private,
  charter,
}

/// School approval request model
class SchoolApprovalRequest {
  final String schoolId;
  final String requestedBy; // User ID who requested approval
  final DateTime requestedAt;
  final String? notes;
  final List<String> attachments;
  final Map<String, dynamic>? additionalInfo;

  SchoolApprovalRequest({
    required this.schoolId,
    required this.requestedBy,
    required this.requestedAt,
    this.notes,
    this.attachments = const [],
    this.additionalInfo,
  });

  factory SchoolApprovalRequest.fromMap(Map<String, dynamic> map) {
    return SchoolApprovalRequest(
      schoolId: map['schoolId'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
      attachments: List<String>.from(map['attachments'] ?? []),
      additionalInfo: map['additionalInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'requestedBy': requestedBy,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'notes': notes,
      'attachments': attachments,
      'additionalInfo': additionalInfo,
    };
  }
}
