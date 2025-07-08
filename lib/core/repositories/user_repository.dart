import '../../shared/models/user_model.dart';
import 'base_repository.dart';

/// Repository for managing user data
class UserRepository extends BaseRepository<UserModel> {
  @override
  String get collectionName => 'users';

  @override
  UserModel fromMap(Map<String, dynamic> map) => UserModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(UserModel model) => model.toMap();

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    return getWhere('role', role.toString().split('.').last);
  }

  /// Get users stream by role
  Stream<List<UserModel>> getUsersStreamByRole(UserRole role) {
    return getStreamWhere('role', role.toString().split('.').last);
  }

  /// Get users for a specific school
  Future<List<UserModel>> getUsersForSchool(String schoolId) async {
    return getWhere('schoolId', schoolId);
  }

  /// Get users stream for a specific school
  Stream<List<UserModel>> getUsersStreamForSchool(String schoolId) {
    return getStreamWhere('schoolId', schoolId);
  }

  /// Get active users
  Future<List<UserModel>> getActiveUsers() async {
    return getWhere('isActive', true);
  }

  /// Get active users stream
  Stream<List<UserModel>> getActiveUsersStream() {
    return getStreamWhere('isActive', true);
  }

  /// Get verified users
  Future<List<UserModel>> getVerifiedUsers() async {
    return getWhere('isVerified', true);
  }

  /// Get verified users stream
  Stream<List<UserModel>> getVerifiedUsersStream() {
    return getStreamWhere('isVerified', true);
  }

  /// Search users by name
  Future<List<UserModel>> searchByName(String query) async {
    try {
      final querySnapshot = await collection
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering if compound queries are not set up
      final allUsers = await getActiveUsers();
      return allUsers
          .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Search users by email
  Future<List<UserModel>> searchByEmail(String query) async {
    try {
      final querySnapshot = await collection
          .where('isActive', isEqualTo: true)
          .orderBy('email')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering if compound queries are not set up
      final allUsers = await getActiveUsers();
      return allUsers
          .where((user) => user.email.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Update user FCM token
  Future<void> updateFCMToken(String userId, String fcmToken) async {
    await updateById(userId, {'fcmToken': fcmToken});
  }

  /// Update user verification status
  Future<void> updateVerificationStatus(String userId, bool isVerified) async {
    await updateById(userId, {
      'isVerified': isVerified,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update user active status
  Future<void> updateActiveStatus(String userId, bool isActive) async {
    await updateById(userId, {
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update user role
  Future<void> updateUserRole(String userId, UserRole role) async {
    await updateById(userId, {
      'role': role.toString().split('.').last,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update user school
  Future<void> updateUserSchool(String userId, String? schoolId) async {
    await updateById(userId, {
      'schoolId': schoolId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get users with specific permissions
  Future<List<UserModel>> getUsersWithPermission(String permission) async {
    try {
      final querySnapshot = await collection
          .where('permissions', arrayContains: permission)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allUsers = await getActiveUsers();
      return allUsers
          .where((user) => user.permissions?.contains(permission) ?? false)
          .toList();
    }
  }

  /// Get users by multiple roles
  Future<List<UserModel>> getUsersByRoles(List<UserRole> roles) async {
    final roleStrings = roles.map((role) => role.toString().split('.').last).toList();
    return getWhereIn('role', roleStrings);
  }

  /// Get school admins for a specific school
  Future<List<UserModel>> getSchoolAdmins(String schoolId) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('role', isEqualTo: UserRole.schoolAdmin.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback approach
      final schoolUsers = await getUsersForSchool(schoolId);
      return schoolUsers
          .where((user) => user.role == UserRole.schoolAdmin && user.isActive)
          .toList();
    }
  }

  /// Get drivers for a specific school
  Future<List<UserModel>> getSchoolDrivers(String schoolId) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('role', isEqualTo: UserRole.driver.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback approach
      final schoolUsers = await getUsersForSchool(schoolId);
      return schoolUsers
          .where((user) => user.role == UserRole.driver && user.isActive)
          .toList();
    }
  }

  /// Get parents for a specific school
  Future<List<UserModel>> getSchoolParents(String schoolId) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('role', isEqualTo: UserRole.parent.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback approach
      final schoolUsers = await getUsersForSchool(schoolId);
      return schoolUsers
          .where((user) => user.role == UserRole.parent && user.isActive)
          .toList();
    }
  }

  /// Get super admins
  Future<List<UserModel>> getSuperAdmins() async {
    return getUsersByRole(UserRole.superAdmin);
  }

  /// Check if user exists by email
  Future<bool> userExistsByEmail(String email) async {
    final users = await getWhere('email', email);
    return users.isNotEmpty;
  }

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    final users = await getWhere('email', email);
    return users.isNotEmpty ? users.first : null;
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    final allUsers = await getAll();
    
    return {
      'total': allUsers.length,
      'active': allUsers.where((user) => user.isActive).length,
      'verified': allUsers.where((user) => user.isVerified).length,
      'parents': allUsers.where((user) => user.role == UserRole.parent).length,
      'drivers': allUsers.where((user) => user.role == UserRole.driver).length,
      'schoolAdmins': allUsers.where((user) => user.role == UserRole.schoolAdmin).length,
      'superAdmins': allUsers.where((user) => user.role == UserRole.superAdmin).length,
    };
  }
}
