import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'auth_service.dart';
import '../../shared/models/user_model.dart';

/// Service for managing security and access control
class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();
  
  SecurityService._();

  final AuthService _authService = AuthService.instance;

  /// Check if current user has permission to perform an action
  Future<bool> hasPermission(String permission, {Map<String, dynamic>? context}) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      final userProfile = await _authService.getUserProfile(user.uid);
      if (userProfile == null || !userProfile.isActive) return false;

      return _checkPermission(userProfile, permission, context);
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Permission check failed');
      return false;
    }
  }

  /// Check permission based on user role and context
  bool _checkPermission(UserModel user, String permission, Map<String, dynamic>? context) {
    // Super admin has all permissions
    if (user.isSuperAdmin) return true;

    // Check role-based permissions
    switch (permission) {
      // User management permissions
      case 'users.read':
        return user.isSchoolAdmin || user.isSuperAdmin;
      case 'users.create':
        return user.isSchoolAdmin || user.isSuperAdmin;
      case 'users.update':
        return _canUpdateUser(user, context);
      case 'users.delete':
        return user.isSuperAdmin;

      // Children management permissions
      case 'children.read':
        return _canReadChildren(user, context);
      case 'children.create':
        return user.isParent || user.isSchoolAdmin || user.isSuperAdmin;
      case 'children.update':
        return _canUpdateChildren(user, context);
      case 'children.delete':
        return user.isSchoolAdmin || user.isSuperAdmin;

      // Bus management permissions
      case 'buses.read':
        return _canReadBuses(user, context);
      case 'buses.create':
        return user.isSchoolAdmin || user.isSuperAdmin;
      case 'buses.update':
        return _canUpdateBuses(user, context);
      case 'buses.delete':
        return user.isSchoolAdmin || user.isSuperAdmin;

      // Route management permissions
      case 'routes.read':
        return _canReadRoutes(user, context);
      case 'routes.create':
        return user.isSchoolAdmin || user.isSuperAdmin;
      case 'routes.update':
        return user.isSchoolAdmin || user.isSuperAdmin;
      case 'routes.delete':
        return user.isSchoolAdmin || user.isSuperAdmin;

      // Trip management permissions
      case 'trips.read':
        return _canReadTrips(user, context);
      case 'trips.create':
        return user.isDriver || user.isSchoolAdmin || user.isSuperAdmin;
      case 'trips.update':
        return _canUpdateTrips(user, context);
      case 'trips.delete':
        return user.isSchoolAdmin || user.isSuperAdmin;

      // Check-in permissions
      case 'checkins.read':
        return _canReadCheckins(user, context);
      case 'checkins.create':
        return user.isDriver || user.isSchoolAdmin || user.isSuperAdmin;
      case 'checkins.update':
        return _canUpdateCheckins(user, context);
      case 'checkins.delete':
        return user.isSchoolAdmin || user.isSuperAdmin;

      // Payment permissions
      case 'payments.read':
        return _canReadPayments(user, context);
      case 'payments.create':
        return user.isParent || user.isSchoolAdmin || user.isSuperAdmin;
      case 'payments.update':
        return _canUpdatePayments(user, context);
      case 'payments.delete':
        return user.isSuperAdmin;

      // Notification permissions
      case 'notifications.read':
        return _canReadNotifications(user, context);
      case 'notifications.create':
        return user.isDriver || user.isSchoolAdmin || user.isSuperAdmin;
      case 'notifications.update':
        return _canUpdateNotifications(user, context);
      case 'notifications.delete':
        return _canDeleteNotifications(user, context);

      // Incident permissions
      case 'incidents.read':
        return _canReadIncidents(user, context);
      case 'incidents.create':
        return user.isDriver || user.isSchoolAdmin || user.isSuperAdmin;
      case 'incidents.update':
        return _canUpdateIncidents(user, context);
      case 'incidents.delete':
        return user.isSchoolAdmin || user.isSuperAdmin;

      // Report permissions
      case 'reports.read':
        return user.isSchoolAdmin || user.isSuperAdmin;
      case 'reports.create':
        return user.isSchoolAdmin || user.isSuperAdmin;
      case 'reports.export':
        return user.isSchoolAdmin || user.isSuperAdmin;

      // Analytics permissions
      case 'analytics.read':
        return user.isSchoolAdmin || user.isSuperAdmin;
      case 'analytics.create':
        return user.isSuperAdmin;

      // School management permissions
      case 'schools.read':
        return _canReadSchools(user, context);
      case 'schools.create':
        return user.isSuperAdmin;
      case 'schools.update':
        return _canUpdateSchools(user, context);
      case 'schools.delete':
        return user.isSuperAdmin;

      // File upload permissions
      case 'files.upload.profile':
        return true; // All authenticated users can upload profile pictures
      case 'files.upload.child_photo':
        return user.isParent || user.isSchoolAdmin || user.isSuperAdmin;
      case 'files.upload.document':
        return true; // All authenticated users can upload documents
      case 'files.upload.bus_image':
        return user.isDriver || user.isSchoolAdmin || user.isSuperAdmin;
      case 'files.upload.incident_media':
        return user.isDriver || user.isSchoolAdmin || user.isSuperAdmin;

      default:
        return false;
    }
  }

  // Helper methods for specific permission checks

  bool _canUpdateUser(UserModel user, Map<String, dynamic>? context) {
    if (user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final targetUserId = context['userId'] as String?;
    final targetSchoolId = context['schoolId'] as String?;
    
    // Users can update their own profile
    if (targetUserId == user.uid) return true;
    
    // School admin can update users in their school
    if (user.isSchoolAdmin && targetSchoolId == user.schoolId) return true;
    
    return false;
  }

  bool _canReadChildren(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final parentId = context['parentId'] as String?;
    final schoolId = context['schoolId'] as String?;
    final busId = context['busId'] as String?;
    
    // Parent can read their own children
    if (user.isParent && parentId == user.uid) return true;
    
    // Driver can read children on their assigned buses
    if (user.isDriver && busId != null) {
      // Check if driver is assigned to this bus
      return true; // This would need to be checked against driver's assigned buses
    }
    
    return false;
  }

  bool _canUpdateChildren(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final parentId = context['parentId'] as String?;
    
    // Parent can update their own children (limited fields)
    if (user.isParent && parentId == user.uid) return true;
    
    return false;
  }

  bool _canReadBuses(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final driverId = context['driverId'] as String?;
    final schoolId = context['schoolId'] as String?;
    
    // Driver can read their assigned buses
    if (user.isDriver && driverId == user.uid) return true;
    
    // Users can read buses in their school
    if (schoolId == user.schoolId) return true;
    
    return false;
  }

  bool _canUpdateBuses(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final driverId = context['driverId'] as String?;
    final updateFields = context['updateFields'] as List<String>?;
    
    // Driver can update location and status of their assigned bus
    if (user.isDriver && driverId == user.uid && updateFields != null) {
      final allowedFields = ['currentLatitude', 'currentLongitude', 'lastLocationUpdate', 'status'];
      return updateFields.every((field) => allowedFields.contains(field));
    }
    
    return false;
  }

  bool _canReadRoutes(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final schoolId = context['schoolId'] as String?;
    final busId = context['busId'] as String?;
    
    // Driver can read routes for their assigned buses
    if (user.isDriver && busId != null) return true;
    
    // Parent can read routes their children are assigned to
    if (user.isParent) return true; // This would need additional checks
    
    // Users can read routes in their school
    if (schoolId == user.schoolId) return true;
    
    return false;
  }

  bool _canReadTrips(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final driverId = context['driverId'] as String?;
    final childrenIds = context['childrenIds'] as List<String>?;
    
    // Driver can read their trips
    if (user.isDriver && driverId == user.uid) return true;
    
    // Parent can read trips involving their children
    if (user.isParent && childrenIds != null) {
      // Check if any of the children belong to this parent
      return true; // This would need additional checks
    }
    
    return false;
  }

  bool _canUpdateTrips(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final driverId = context['driverId'] as String?;
    
    // Driver can update their trips
    if (user.isDriver && driverId == user.uid) return true;
    
    return false;
  }

  bool _canReadCheckins(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final driverId = context['driverId'] as String?;
    final childId = context['childId'] as String?;
    
    // Driver can read check-ins they created
    if (user.isDriver && driverId == user.uid) return true;
    
    // Parent can read check-ins for their children
    if (user.isParent && childId != null) {
      // Check if child belongs to this parent
      return true; // This would need additional checks
    }
    
    return false;
  }

  bool _canUpdateCheckins(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final driverId = context['driverId'] as String?;
    final timestamp = context['timestamp'] as DateTime?;
    
    // Driver can update their check-ins within time limit
    if (user.isDriver && driverId == user.uid && timestamp != null) {
      final now = DateTime.now();
      final timeDiff = now.difference(timestamp).inHours;
      return timeDiff < 1; // 1 hour time limit
    }
    
    return false;
  }

  bool _canReadPayments(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final userId = context['userId'] as String?;
    
    // User can read their own payments
    if (userId == user.uid) return true;
    
    return false;
  }

  bool _canUpdatePayments(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final userId = context['userId'] as String?;
    final updateFields = context['updateFields'] as List<String>?;
    
    // User can update their own payments (limited fields)
    if (userId == user.uid && updateFields != null) {
      final allowedFields = ['metadata'];
      return updateFields.every((field) => allowedFields.contains(field));
    }
    
    return false;
  }

  bool _canReadNotifications(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final userId = context['userId'] as String?;
    
    // User can read their own notifications
    if (userId == user.uid) return true;
    
    return false;
  }

  bool _canUpdateNotifications(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final userId = context['userId'] as String?;
    final updateFields = context['updateFields'] as List<String>?;
    
    // User can mark their own notifications as read
    if (userId == user.uid && updateFields != null) {
      final allowedFields = ['isRead', 'readAt'];
      return updateFields.every((field) => allowedFields.contains(field));
    }
    
    return false;
  }

  bool _canDeleteNotifications(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final userId = context['userId'] as String?;
    
    // User can delete their own notifications
    if (userId == user.uid) return true;
    
    return false;
  }

  bool _canReadIncidents(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final reportedBy = context['reportedBy'] as String?;
    
    // Driver can read incidents they reported
    if (user.isDriver && reportedBy == user.uid) return true;
    
    return false;
  }

  bool _canUpdateIncidents(UserModel user, Map<String, dynamic>? context) {
    if (user.isSchoolAdmin || user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final reportedBy = context['reportedBy'] as String?;
    final updateFields = context['updateFields'] as List<String>?;
    
    // Driver can update incidents they reported (limited fields)
    if (user.isDriver && reportedBy == user.uid && updateFields != null) {
      final allowedFields = ['description', 'severity', 'status'];
      return updateFields.every((field) => allowedFields.contains(field));
    }
    
    return false;
  }

  bool _canReadSchools(UserModel user, Map<String, dynamic>? context) {
    if (user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final schoolId = context['schoolId'] as String?;
    
    // User can read their own school
    if (schoolId == user.schoolId) return true;
    
    return false;
  }

  bool _canUpdateSchools(UserModel user, Map<String, dynamic>? context) {
    if (user.isSuperAdmin) return true;
    if (context == null) return false;
    
    final schoolId = context['schoolId'] as String?;
    
    // School admin can update their own school
    if (user.isSchoolAdmin && schoolId == user.schoolId) return true;
    
    return false;
  }

  /// Validate data based on security rules
  bool validateData(String collection, Map<String, dynamic> data, {String? operation}) {
    try {
      switch (collection) {
        case 'users':
          return _validateUserData(data, operation);
        case 'children':
          return _validateChildData(data, operation);
        case 'buses':
          return _validateBusData(data, operation);
        case 'routes':
          return _validateRouteData(data, operation);
        default:
          return true; // Allow by default for other collections
      }
    } catch (e) {
      debugPrint('Data validation failed: $e');
      return false;
    }
  }

  bool _validateUserData(Map<String, dynamic> data, String? operation) {
    // Validate required fields
    if (operation == 'create') {
      final requiredFields = ['uid', 'name', 'email', 'role'];
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null) {
          return false;
        }
      }
    }
    
    // Validate email format
    if (data.containsKey('email')) {
      final email = data['email'] as String;
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return false;
      }
    }
    
    // Validate role
    if (data.containsKey('role')) {
      final validRoles = ['parent', 'driver', 'schoolAdmin', 'superAdmin'];
      if (!validRoles.contains(data['role'])) {
        return false;
      }
    }
    
    return true;
  }

  bool _validateChildData(Map<String, dynamic> data, String? operation) {
    // Validate required fields
    if (operation == 'create') {
      final requiredFields = ['name', 'parentId', 'schoolId', 'grade', 'className', 'dateOfBirth'];
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null) {
          return false;
        }
      }
    }
    
    // Validate date of birth
    if (data.containsKey('dateOfBirth')) {
      try {
        final dob = DateTime.parse(data['dateOfBirth'].toString());
        final now = DateTime.now();
        final age = now.year - dob.year;
        if (age < 3 || age > 18) {
          return false; // Age should be between 3 and 18
        }
      } catch (e) {
        return false;
      }
    }
    
    return true;
  }

  bool _validateBusData(Map<String, dynamic> data, String? operation) {
    // Validate required fields
    if (operation == 'create') {
      final requiredFields = ['busNumber', 'licensePlate', 'schoolId', 'capacity', 'model', 'manufacturer', 'year'];
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null) {
          return false;
        }
      }
    }
    
    // Validate capacity
    if (data.containsKey('capacity')) {
      final capacity = data['capacity'] as int?;
      if (capacity == null || capacity < 1 || capacity > 100) {
        return false;
      }
    }
    
    // Validate year
    if (data.containsKey('year')) {
      final year = data['year'] as int?;
      final currentYear = DateTime.now().year;
      if (year == null || year < 1990 || year > currentYear + 1) {
        return false;
      }
    }
    
    return true;
  }

  bool _validateRouteData(Map<String, dynamic> data, String? operation) {
    // Validate required fields
    if (operation == 'create') {
      final requiredFields = ['name', 'schoolId', 'type', 'startTime', 'endTime'];
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null) {
          return false;
        }
      }
    }
    
    // Validate route type
    if (data.containsKey('type')) {
      final validTypes = ['pickup', 'dropoff', 'roundTrip'];
      if (!validTypes.contains(data['type'])) {
        return false;
      }
    }
    
    return true;
  }
}
