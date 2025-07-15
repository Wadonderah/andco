import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive super admin service for platform-wide management and oversight
class SuperAdminService {
  static SuperAdminService? _instance;
  static SuperAdminService get instance => _instance ??= SuperAdminService._();

  SuperAdminService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Initialize super admin service
  Future<void> initialize() async {
    try {
      debugPrint('✅ Super Admin service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize super admin service: $e');
      rethrow;
    }
  }

  // ==================== SCHOOL MANAGEMENT ====================

  /// Get all schools in the platform
  Stream<List<Map<String, dynamic>>> getAllSchoolsStream() {
    return _firestore
        .collection('schools')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Get pending school applications
  Stream<List<Map<String, dynamic>>> getPendingSchoolsStream() {
    return _firestore
        .collection('schools')
        .where('isApproved', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Approve school application
  Future<void> approveSchool(
      String schoolId, Map<String, dynamic> approvalData) async {
    try {
      await _firestore.collection('schools').doc(schoolId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
        'approvalNotes': approvalData['notes'],
        'subscriptionPlan': approvalData['plan'] ?? 'basic',
        'maxStudents': approvalData['maxStudents'] ?? 100,
        'maxDrivers': approvalData['maxDrivers'] ?? 10,
      });

      // Send approval notification
      await _sendSchoolApprovalNotification(schoolId, true);

      debugPrint('✅ School approved successfully: $schoolId');
    } catch (e) {
      debugPrint('❌ Failed to approve school: $e');
      rethrow;
    }
  }

  /// Reject school application
  Future<void> rejectSchool(String schoolId, String reason) async {
    try {
      await _firestore.collection('schools').doc(schoolId).update({
        'isApproved': false,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'rejectionReason': reason,
      });

      // Send rejection notification
      await _sendSchoolApprovalNotification(schoolId, false, reason: reason);

      debugPrint('✅ School rejected successfully: $schoolId');
    } catch (e) {
      debugPrint('❌ Failed to reject school: $e');
      rethrow;
    }
  }

  /// Send school approval/rejection notification
  Future<void> _sendSchoolApprovalNotification(String schoolId, bool approved,
      {String? reason}) async {
    try {
      // Get school admin user ID
      final schoolDoc =
          await _firestore.collection('schools').doc(schoolId).get();
      final adminId = schoolDoc.data()?['adminId'] as String?;

      if (adminId != null) {
        await _firestore.collection('notifications').add({
          'userId': adminId,
          'title': approved
              ? 'School Application Approved'
              : 'School Application Rejected',
          'message': approved
              ? 'Your school application has been approved. You can now start managing your school.'
              : 'Your school application has been rejected. Reason: ${reason ?? 'Not specified'}',
          'type': 'school_approval',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'data': {
            'schoolId': schoolId,
            'approved': approved,
            'reason': reason,
          },
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to send school notification: $e');
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Get all platform users with pagination
  Stream<List<Map<String, dynamic>>> getAllUsersStream(
      {String? role, int? limit}) {
    Query query =
        _firestore.collection('users').orderBy('createdAt', descending: true);

    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        return <String, dynamic>{
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Suspend user account
  Future<void> suspendUser(String userId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isSuspended': true,
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedBy': _auth.currentUser?.uid,
        'suspensionReason': reason,
      });

      // Send suspension notification
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Account Suspended',
        'message': 'Your account has been suspended. Reason: $reason',
        'type': 'account_suspension',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'reason': reason,
        },
      });

      debugPrint('✅ User suspended successfully: $userId');
    } catch (e) {
      debugPrint('❌ Failed to suspend user: $e');
      rethrow;
    }
  }

  /// Reactivate user account
  Future<void> reactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isSuspended': false,
        'reactivatedAt': FieldValue.serverTimestamp(),
        'reactivatedBy': _auth.currentUser?.uid,
        'suspensionReason': FieldValue.delete(),
      });

      // Send reactivation notification
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Account Reactivated',
        'message':
            'Your account has been reactivated. You can now access all features.',
        'type': 'account_reactivation',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User reactivated successfully: $userId');
    } catch (e) {
      debugPrint('❌ Failed to reactivate user: $e');
      rethrow;
    }
  }

  // ==================== FINANCIAL OVERSIGHT ====================

  /// Get platform financial overview
  Future<Map<String, dynamic>> getFinancialOverview() async {
    try {
      // Get total revenue from all schools
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('status', isEqualTo: 'completed')
          .get();

      double totalRevenue = 0;
      double monthlyRevenue = 0;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final timestamp = data['createdAt'] as Timestamp?;

        totalRevenue += amount;

        if (timestamp != null && timestamp.toDate().isAfter(startOfMonth)) {
          monthlyRevenue += amount;
        }
      }

      // Get subscription counts
      final schoolsSnapshot = await _firestore
          .collection('schools')
          .where('isApproved', isEqualTo: true)
          .get();

      final subscriptionCounts = <String, int>{};
      for (final doc in schoolsSnapshot.docs) {
        final plan = doc.data()['subscriptionPlan'] as String? ?? 'basic';
        subscriptionCounts[plan] = (subscriptionCounts[plan] ?? 0) + 1;
      }

      return {
        'totalRevenue': totalRevenue,
        'monthlyRevenue': monthlyRevenue,
        'totalSchools': schoolsSnapshot.docs.length,
        'subscriptionCounts': subscriptionCounts,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to get financial overview: $e');
      rethrow;
    }
  }

  /// Get Stripe transactions
  Stream<List<Map<String, dynamic>>> getStripeTransactionsStream() {
    return _firestore
        .collection('payments')
        .where('paymentMethod', isEqualTo: 'stripe')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Get M-Pesa transactions
  Stream<List<Map<String, dynamic>>> getMpesaTransactionsStream() {
    return _firestore
        .collection('payments')
        .where('paymentMethod', isEqualTo: 'mpesa')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // ==================== PLATFORM ANALYTICS ====================

  /// Get comprehensive platform analytics
  Future<Map<String, dynamic>> getPlatformAnalytics() async {
    try {
      // Get user counts by role
      final usersSnapshot = await _firestore.collection('users').get();
      final userCounts = <String, int>{};

      for (final doc in usersSnapshot.docs) {
        final role = doc.data()['role'] as String? ?? 'unknown';
        userCounts[role] = (userCounts[role] ?? 0) + 1;
      }

      // Get active schools count
      final activeSchoolsSnapshot = await _firestore
          .collection('schools')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      // Get total students count
      final studentsSnapshot = await _firestore
          .collection('children')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      // Get total routes count
      final routesSnapshot = await _firestore
          .collection('routes')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      // Get recent activity count (last 24 hours)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final recentActivitySnapshot = await _firestore
          .collection('activity_logs')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .count()
          .get();

      return {
        'userCounts': userCounts,
        'totalUsers': usersSnapshot.docs.length,
        'activeSchools': activeSchoolsSnapshot.count,
        'totalStudents': studentsSnapshot.count,
        'totalRoutes': routesSnapshot.count,
        'recentActivity': recentActivitySnapshot.count,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to get platform analytics: $e');
      rethrow;
    }
  }

  // ==================== SUPPORT MANAGEMENT ====================

  /// Get all support tickets
  Stream<List<Map<String, dynamic>>> getSupportTicketsStream() {
    return _firestore
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Assign support agent to ticket
  Future<void> assignSupportAgent(String ticketId, String agentId) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'assignedAgentId': agentId,
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'assigned',
      });

      debugPrint('✅ Support agent assigned successfully');
    } catch (e) {
      debugPrint('❌ Failed to assign support agent: $e');
      rethrow;
    }
  }

  // ==================== SYSTEM MONITORING ====================

  /// Get system health metrics
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      // Check database connectivity
      final dbHealth = await _checkDatabaseHealth();

      // Check storage health
      final storageHealth = await _checkStorageHealth();

      // Get error logs count (last 24 hours)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final errorLogsSnapshot = await _firestore
          .collection('error_logs')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .count()
          .get();

      return {
        'database': dbHealth,
        'storage': storageHealth,
        'errorCount24h': errorLogsSnapshot.count,
        'uptime':
            '99.9%', // This would be calculated from actual uptime monitoring
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to get system health: $e');
      return {
        'database': 'error',
        'storage': 'error',
        'errorCount24h': -1,
        'uptime': 'unknown',
        'lastChecked': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check database health
  Future<String> _checkDatabaseHealth() async {
    try {
      await _firestore.collection('health_check').doc('test').set({
        'timestamp': FieldValue.serverTimestamp(),
      });
      return 'healthy';
    } catch (e) {
      return 'error';
    }
  }

  /// Check storage health
  Future<String> _checkStorageHealth() async {
    try {
      final ref = _storage.ref().child('health_check.txt');
      await ref
          .putString('health_check_${DateTime.now().millisecondsSinceEpoch}');
      return 'healthy';
    } catch (e) {
      return 'error';
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}
