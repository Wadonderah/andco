import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/auth/role_selection_screen.dart';
import '../../features/driver/driver_dashboard.dart';
import '../../features/parent/parent_dashboard.dart';
import '../../features/school_admin/school_admin_dashboard.dart';
import '../../features/super_admin/super_admin_dashboard.dart';
import '../../shared/models/user_model.dart';
import '../services/auth_service.dart';

/// Service for handling role-based navigation
class RoleNavigationService {
  static RoleNavigationService? _instance;
  static RoleNavigationService get instance =>
      _instance ??= RoleNavigationService._();

  RoleNavigationService._();

  /// Navigate to appropriate dashboard based on user role
  /// If user has no role, navigate to role selection screen
  Future<void> navigateBasedOnRole(BuildContext context,
      {bool replace = true}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // User not authenticated, handle accordingly
        return;
      }

      // Get user profile from Firestore
      final userProfile =
          await AuthService.instance.getUserProfile(currentUser.uid);

      if (userProfile == null) {
        // User has no profile, navigate to role selection
        _navigateToRoleSelection(context, currentUser, replace);
        return;
      }

      // Navigate to appropriate dashboard
      _navigateToDashboard(context, userProfile.role, replace);
    } catch (e) {
      debugPrint('Error navigating based on role: $e');
      // On error, navigate to role selection as fallback
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _navigateToRoleSelection(context, currentUser, replace);
      }
    }
  }

  /// Navigate to role selection screen
  void _navigateToRoleSelection(BuildContext context, User user, bool replace) {
    final roleSelectionScreen = RoleSelectionScreen(
      isAfterSignup: true,
      user: user,
    );

    if (replace) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => roleSelectionScreen),
        (route) => false,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => roleSelectionScreen),
      );
    }
  }

  /// Navigate to appropriate dashboard based on role
  void _navigateToDashboard(BuildContext context, UserRole role, bool replace) {
    Widget dashboard;

    switch (role) {
      case UserRole.parent:
        dashboard = const ParentDashboard();
        break;
      case UserRole.driver:
        dashboard = const DriverDashboard();
        break;
      case UserRole.schoolAdmin:
        dashboard = const SchoolAdminDashboard();
        break;
      case UserRole.superAdmin:
        dashboard = const SuperAdminDashboard();
        break;
    }

    if (replace) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => dashboard),
        (route) => false,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => dashboard),
      );
    }
  }

  /// Get dashboard widget for a specific role
  Widget getDashboardForRole(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return const ParentDashboard();
      case UserRole.driver:
        return const DriverDashboard();
      case UserRole.schoolAdmin:
        return const SchoolAdminDashboard();
      case UserRole.superAdmin:
        return const SuperAdminDashboard();
    }
  }

  /// Check if user can access super admin role
  static bool canAccessSuperAdmin(String? email) {
    return email == 'admin@andco.com';
  }

  /// Check if super admin already exists in the system
  static Future<bool> superAdminExists() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: 'admin@andco.com')
          .where('role', isEqualTo: 'superAdmin')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if super admin exists: $e');
      return false;
    }
  }

  /// Get all users for super admin (only accessible by super admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user is super admin
      final userProfile =
          await AuthService.instance.getUserProfile(currentUser.uid);
      if (userProfile?.role != UserRole.superAdmin) {
        throw Exception('Access denied: Super Admin role required');
      }

      // Fetch all users from Firestore
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      rethrow;
    }
  }

  /// Update user role (only accessible by super admin)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user is super admin
      final userProfile =
          await AuthService.instance.getUserProfile(currentUser.uid);
      if (userProfile?.role != UserRole.superAdmin) {
        throw Exception('Access denied: Super Admin role required');
      }

      // Update user role in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    }
  }

  /// Delete user (only accessible by super admin)
  Future<void> deleteUser(String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user is super admin
      final userProfile =
          await AuthService.instance.getUserProfile(currentUser.uid);
      if (userProfile?.role != UserRole.superAdmin) {
        throw Exception('Access denied: Super Admin role required');
      }

      // Don't allow super admin to delete themselves
      if (userId == currentUser.uid) {
        throw Exception('Cannot delete your own account');
      }

      // Delete user from Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }
}
