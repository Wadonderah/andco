import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'child_model.g.dart';

@HiveType(typeId: 2)
class ChildModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String parentId;

  @HiveField(3)
  final String schoolId;

  @HiveField(4)
  final String grade;

  @HiveField(5)
  final String className;

  @HiveField(6)
  final String? photoUrl;

  @HiveField(7)
  final DateTime dateOfBirth;

  @HiveField(8)
  final String? medicalInfo;

  @HiveField(9)
  final String? emergencyContact;

  @HiveField(10)
  final String? emergencyContactPhone;

  @HiveField(11)
  final String? busId;

  @HiveField(12)
  final String? routeId;

  @HiveField(13)
  final String? pickupStopId;

  @HiveField(14)
  final String? dropoffStopId;

  @HiveField(15)
  final bool isActive;

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime updatedAt;

  @HiveField(18)
  final Map<String, dynamic>? metadata;

  ChildModel({
    required this.id,
    required this.name,
    required this.parentId,
    required this.schoolId,
    required this.grade,
    required this.className,
    this.photoUrl,
    required this.dateOfBirth,
    this.medicalInfo,
    this.emergencyContact,
    this.emergencyContactPhone,
    this.busId,
    this.routeId,
    this.pickupStopId,
    this.dropoffStopId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      parentId: map['parentId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      grade: map['grade'] ?? '',
      className: map['className'] ?? '',
      photoUrl: map['photoUrl'],
      dateOfBirth: map['dateOfBirth'] is Timestamp 
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : DateTime.parse(map['dateOfBirth']),
      medicalInfo: map['medicalInfo'],
      emergencyContact: map['emergencyContact'],
      emergencyContactPhone: map['emergencyContactPhone'],
      busId: map['busId'],
      routeId: map['routeId'],
      pickupStopId: map['pickupStopId'],
      dropoffStopId: map['dropoffStopId'],
      isActive: map['isActive'] ?? true,
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
      'name': name,
      'parentId': parentId,
      'schoolId': schoolId,
      'grade': grade,
      'className': className,
      'photoUrl': photoUrl,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'medicalInfo': medicalInfo,
      'emergencyContact': emergencyContact,
      'emergencyContactPhone': emergencyContactPhone,
      'busId': busId,
      'routeId': routeId,
      'pickupStopId': pickupStopId,
      'dropoffStopId': dropoffStopId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  ChildModel copyWith({
    String? id,
    String? name,
    String? parentId,
    String? schoolId,
    String? grade,
    String? className,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? medicalInfo,
    String? emergencyContact,
    String? emergencyContactPhone,
    String? busId,
    String? routeId,
    String? pickupStopId,
    String? dropoffStopId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      schoolId: schoolId ?? this.schoolId,
      grade: grade ?? this.grade,
      className: className ?? this.className,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      pickupStopId: pickupStopId ?? this.pickupStopId,
      dropoffStopId: dropoffStopId ?? this.dropoffStopId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  bool get hasTransportAssigned => busId != null && routeId != null;
  bool get hasPickupStop => pickupStopId != null;
  bool get hasDropoffStop => dropoffStopId != null;
  bool get hasEmergencyContact => emergencyContact != null && emergencyContactPhone != null;
}
