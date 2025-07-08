import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String? phoneNumber;

  @HiveField(4)
  final String? profileImageUrl;

  @HiveField(5)
  final UserRole role;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final bool isVerified;

  @HiveField(10)
  final String? schoolId;

  @HiveField(11)
  final Map<String, dynamic>? metadata;

  @HiveField(12)
  final List<String>? permissions;

  @HiveField(13)
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isVerified = false,
    this.schoolId,
    this.metadata,
    this.permissions,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.parent,
      ),
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt']),
      isActive: map['isActive'] ?? true,
      isVerified: map['isVerified'] ?? false,
      schoolId: map['schoolId'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      permissions: map['permissions'] != null ? List<String>.from(map['permissions']) : null,
      fcmToken: map['fcmToken'],
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isVerified': isVerified,
      'schoolId': schoolId,
      'metadata': metadata,
      'permissions': permissions,
      'fcmToken': fcmToken,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isVerified,
    String? schoolId,
    Map<String, dynamic>? metadata,
    List<String>? permissions,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      schoolId: schoolId ?? this.schoolId,
      metadata: metadata ?? this.metadata,
      permissions: permissions ?? this.permissions,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  // Helper methods for role checking
  bool get isParent => role == UserRole.parent;
  bool get isDriver => role == UserRole.driver;
  bool get isSchoolAdmin => role == UserRole.schoolAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;

  // Helper method to check permissions
  bool hasPermission(String permission) {
    return permissions?.contains(permission) ?? false;
  }

  // Get display name for role
  String get roleDisplayName {
    switch (role) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.driver:
        return 'Driver';
      case UserRole.schoolAdmin:
        return 'School Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }
}

@HiveType(typeId: 1)
enum UserRole {
  @HiveField(0)
  parent,

  @HiveField(1)
  driver,

  @HiveField(2)
  schoolAdmin,

  @HiveField(3)
  superAdmin,
}
