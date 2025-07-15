import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/school_model.dart';
import '../services/firebase_service.dart';
import 'base_repository.dart';

/// Repository for managing school data and approval workflows
class SchoolRepository extends BaseRepository<SchoolModel> {
  @override
  String get collectionName => 'schools';

  @override
  SchoolModel fromMap(Map<String, dynamic> map) => SchoolModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(SchoolModel model) => model.toMap();

  /// Get schools by status
  Future<List<SchoolModel>> getSchoolsByStatus(SchoolStatus status) async {
    try {
      final querySnapshot = await collection
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting schools by status: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get schools by status: $status',
      );
      return [];
    }
  }

  /// Get schools by status stream
  Stream<List<SchoolModel>> getSchoolsByStatusStream(SchoolStatus status) {
    return collection
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get pending schools for approval
  Future<List<SchoolModel>> getPendingSchools() async {
    return await getSchoolsByStatus(SchoolStatus.pending);
  }

  /// Get pending schools stream
  Stream<List<SchoolModel>> getPendingSchoolsStream() {
    return getSchoolsByStatusStream(SchoolStatus.pending);
  }

  /// Get active schools
  Future<List<SchoolModel>> getActiveSchools() async {
    return await getSchoolsByStatus(SchoolStatus.active);
  }

  /// Get active schools stream
  Stream<List<SchoolModel>> getActiveSchoolsStream() {
    return getSchoolsByStatusStream(SchoolStatus.active);
  }

  /// Approve school
  Future<void> approveSchool(String schoolId, String approvedBy,
      {String? notes}) async {
    try {
      final now = DateTime.now();
      await update(schoolId, {
        'status': SchoolStatus.active.toString().split('.').last,
        'approvedAt': Timestamp.fromDate(now),
        'approvedBy': approvedBy,
        'updatedAt': Timestamp.fromDate(now),
        'rejectionReason': null, // Clear any previous rejection reason
      });

      // Log approval event
      await FirebaseService.instance.logEvent('school_approved', {
        'school_id': schoolId,
        'approved_by': approvedBy,
        'approved_at': now.toIso8601String(),
        if (notes != null) 'notes': notes,
      });

      debugPrint('✅ School approved: $schoolId by $approvedBy');
    } catch (e) {
      debugPrint('❌ Error approving school: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to approve school: $schoolId',
      );
      rethrow;
    }
  }

  /// Reject school
  Future<void> rejectSchool(
      String schoolId, String rejectedBy, String reason) async {
    try {
      final now = DateTime.now();
      await update(schoolId, {
        'status': SchoolStatus.rejected.toString().split('.').last,
        'rejectionReason': reason,
        'updatedAt': Timestamp.fromDate(now),
        'approvedAt': null,
        'approvedBy': null,
      });

      // Log rejection event
      await FirebaseService.instance.logEvent('school_rejected', {
        'school_id': schoolId,
        'rejected_by': rejectedBy,
        'rejected_at': now.toIso8601String(),
        'reason': reason,
      });

      debugPrint('❌ School rejected: $schoolId by $rejectedBy - $reason');
    } catch (e) {
      debugPrint('❌ Error rejecting school: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to reject school: $schoolId',
      );
      rethrow;
    }
  }

  /// Suspend school
  Future<void> suspendSchool(
      String schoolId, String suspendedBy, String reason) async {
    try {
      final now = DateTime.now();
      await update(schoolId, {
        'status': SchoolStatus.suspended.toString().split('.').last,
        'suspensionReason': reason,
        'suspendedBy': suspendedBy,
        'suspendedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Log suspension event
      await FirebaseService.instance.logEvent('school_suspended', {
        'school_id': schoolId,
        'suspended_by': suspendedBy,
        'suspended_at': now.toIso8601String(),
        'reason': reason,
      });

      debugPrint('⚠️ School suspended: $schoolId by $suspendedBy - $reason');
    } catch (e) {
      debugPrint('❌ Error suspending school: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to suspend school: $schoolId',
      );
      rethrow;
    }
  }

  /// Reactivate school
  Future<void> reactivateSchool(String schoolId, String reactivatedBy) async {
    try {
      final now = DateTime.now();
      await update(schoolId, {
        'status': SchoolStatus.active.toString().split('.').last,
        'reactivatedBy': reactivatedBy,
        'reactivatedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'suspensionReason': null,
        'suspendedBy': null,
        'suspendedAt': null,
      });

      // Log reactivation event
      await FirebaseService.instance.logEvent('school_reactivated', {
        'school_id': schoolId,
        'reactivated_by': reactivatedBy,
        'reactivated_at': now.toIso8601String(),
      });

      debugPrint('✅ School reactivated: $schoolId by $reactivatedBy');
    } catch (e) {
      debugPrint('❌ Error reactivating school: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to reactivate school: $schoolId',
      );
      rethrow;
    }
  }

  /// Update school statistics
  Future<void> updateSchoolStats(
    String schoolId, {
    int? studentCount,
    int? driverCount,
    int? busCount,
    int? routeCount,
    double? monthlyRevenue,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'lastActivity': Timestamp.fromDate(DateTime.now()),
      };

      if (studentCount != null) updates['studentCount'] = studentCount;
      if (driverCount != null) updates['driverCount'] = driverCount;
      if (busCount != null) updates['busCount'] = busCount;
      if (routeCount != null) updates['routeCount'] = routeCount;
      if (monthlyRevenue != null) updates['monthlyRevenue'] = monthlyRevenue;

      await update(schoolId, updates);
    } catch (e) {
      debugPrint('❌ Error updating school stats: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to update school stats: $schoolId',
      );
      rethrow;
    }
  }

  /// Search schools by name or email
  Future<List<SchoolModel>> searchSchools(String query) async {
    try {
      if (query.isEmpty) return [];

      final queryLower = query.toLowerCase();

      // Search by name
      final nameQuery = await collection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Search by email
      final emailQuery = await collection
          .where('contactEmail', isGreaterThanOrEqualTo: queryLower)
          .where('contactEmail', isLessThanOrEqualTo: '$queryLower\uf8ff')
          .get();

      final schools = <String, SchoolModel>{};

      // Add results from name search
      for (final doc in nameQuery.docs) {
        schools[doc.id] = fromMap(doc.data() as Map<String, dynamic>);
      }

      // Add results from email search
      for (final doc in emailQuery.docs) {
        schools[doc.id] = fromMap(doc.data() as Map<String, dynamic>);
      }

      return schools.values.toList();
    } catch (e) {
      debugPrint('❌ Error searching schools: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to search schools: $query',
      );
      return [];
    }
  }

  /// Get schools with pagination
  Future<List<SchoolModel>> getSchoolsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    SchoolStatus? status,
  }) async {
    try {
      Query query = collection.orderBy('createdAt', descending: true);

      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting paginated schools: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get paginated schools',
      );
      return [];
    }
  }

  /// Get all schools stream
  Stream<List<SchoolModel>> getAllStream() {
    return collection.orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get school statistics summary
  Future<Map<String, int>> getSchoolStatsSummary() async {
    try {
      final allSchools = await getAll();

      final stats = <String, int>{
        'total': allSchools.length,
        'pending': 0,
        'active': 0,
        'rejected': 0,
        'suspended': 0,
        'inactive': 0,
      };

      for (final school in allSchools) {
        switch (school.status) {
          case SchoolStatus.pending:
            stats['pending'] = (stats['pending'] ?? 0) + 1;
            break;
          case SchoolStatus.active:
            stats['active'] = (stats['active'] ?? 0) + 1;
            break;
          case SchoolStatus.rejected:
            stats['rejected'] = (stats['rejected'] ?? 0) + 1;
            break;
          case SchoolStatus.suspended:
            stats['suspended'] = (stats['suspended'] ?? 0) + 1;
            break;
          case SchoolStatus.inactive:
            stats['inactive'] = (stats['inactive'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Error getting school stats summary: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get school stats summary',
      );
      return {
        'total': 0,
        'pending': 0,
        'active': 0,
        'rejected': 0,
        'suspended': 0,
        'inactive': 0,
      };
    }
  }
}
