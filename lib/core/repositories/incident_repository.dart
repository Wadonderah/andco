import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/incident_model.dart';
import '../services/firebase_service.dart';
import 'base_repository.dart';

/// Repository for managing incidents and safety events
class IncidentRepository extends BaseRepository<IncidentModel> {
  @override
  String get collectionName => 'incidents';

  @override
  IncidentModel fromMap(Map<String, dynamic> map) => IncidentModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(IncidentModel model) => model.toMap();

  /// Get incidents by school
  Stream<List<IncidentModel>> getIncidentsBySchool(String schoolId) {
    return collection
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get incidents by status
  Stream<List<IncidentModel>> getIncidentsByStatus(
      String schoolId, IncidentStatus status) {
    return collection
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get incidents by severity
  Stream<List<IncidentModel>> getIncidentsBySeverity(
      String schoolId, IncidentSeverity severity) {
    return collection
        .where('schoolId', isEqualTo: schoolId)
        .where('severity', isEqualTo: severity.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get incidents by route
  Stream<List<IncidentModel>> getIncidentsByRoute(String routeId) {
    return collection
        .where('routeId', isEqualTo: routeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get incidents by driver
  Stream<List<IncidentModel>> getIncidentsByDriver(String driverId) {
    return collection
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get open incidents for school
  Stream<List<IncidentModel>> getOpenIncidents(String schoolId) {
    return collection
        .where('schoolId', isEqualTo: schoolId)
        .where('status', whereIn: ['open', 'inProgress'])
        .orderBy('severity', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get critical incidents for school
  Stream<List<IncidentModel>> getCriticalIncidents(String schoolId) {
    return collection
        .where('schoolId', isEqualTo: schoolId)
        .where('severity', isEqualTo: 'critical')
        .where('status', whereIn: ['open', 'inProgress'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Update incident status
  Future<void> updateIncidentStatus(String incidentId, IncidentStatus status,
      {String? notes}) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == IncidentStatus.resolved ||
          status == IncidentStatus.closed) {
        updateData['resolvedAt'] = Timestamp.fromDate(DateTime.now());
        if (notes != null) {
          updateData['resolutionNotes'] = notes;
        }
      }

      await update(incidentId, updateData);
    } catch (e) {
      debugPrint('❌ Error updating incident status: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to update incident status',
      );
      rethrow;
    }
  }

  /// Assign incident to user
  Future<void> assignIncident(String incidentId, String assignedTo) async {
    try {
      await update(incidentId, {
        'assignedTo': assignedTo,
        'status': IncidentStatus.inProgress.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('❌ Error assigning incident: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to assign incident',
      );
      rethrow;
    }
  }

  /// Add action to incident
  Future<void> addIncidentAction(
      String incidentId, IncidentAction action) async {
    try {
      final incident = await getById(incidentId);
      if (incident == null) throw Exception('Incident not found');

      final updatedActions = [...incident.actions, action];
      await update(incidentId, {
        'actions': updatedActions.map((a) => a.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('❌ Error adding incident action: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to add incident action',
      );
      rethrow;
    }
  }

  /// Get incident statistics for school
  Future<Map<String, dynamic>> getIncidentStatistics(String schoolId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // Get all incidents for the school
      final allIncidents =
          await collection.where('schoolId', isEqualTo: schoolId).get();

      final incidents = allIncidents.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Calculate statistics
      final totalIncidents = incidents.length;
      final openIncidents = incidents.where((i) => i.isOpen).length;
      final criticalIncidents = incidents.where((i) => i.isCritical).length;
      final monthlyIncidents =
          incidents.where((i) => i.createdAt.isAfter(startOfMonth)).length;
      final weeklyIncidents =
          incidents.where((i) => i.createdAt.isAfter(startOfWeek)).length;

      // Calculate resolution time
      final resolvedIncidents = incidents.where((i) => i.isResolved).toList();
      double avgResolutionTime = 0;
      if (resolvedIncidents.isNotEmpty) {
        final totalResolutionTime = resolvedIncidents
            .where((i) => i.resolvedAt != null)
            .map((i) => i.resolvedAt!.difference(i.createdAt).inHours)
            .fold(0, (sum, hours) => sum + hours);
        avgResolutionTime = totalResolutionTime / resolvedIncidents.length;
      }

      // Group by type
      final incidentsByType = <String, int>{};
      for (final incident in incidents) {
        final type = incident.typeDisplayName;
        incidentsByType[type] = (incidentsByType[type] ?? 0) + 1;
      }

      return {
        'totalIncidents': totalIncidents,
        'openIncidents': openIncidents,
        'criticalIncidents': criticalIncidents,
        'monthlyIncidents': monthlyIncidents,
        'weeklyIncidents': weeklyIncidents,
        'avgResolutionTimeHours': avgResolutionTime,
        'incidentsByType': incidentsByType,
        'resolutionRate': totalIncidents > 0
            ? (resolvedIncidents.length / totalIncidents * 100).round()
            : 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting incident statistics: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get incident statistics',
      );
      return {};
    }
  }

  /// Search incidents
  Future<List<IncidentModel>> searchIncidents(
      String schoolId, String query) async {
    try {
      if (query.isEmpty) return [];

      final queryLower = query.toLowerCase();

      // Search by title
      final titleQuery = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Search by description
      final descQuery = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('description', isGreaterThanOrEqualTo: queryLower)
          .where('description', isLessThanOrEqualTo: '$queryLower\uf8ff')
          .get();

      final incidents = <String, IncidentModel>{};

      // Add results from title search
      for (final doc in titleQuery.docs) {
        incidents[doc.id] = fromMap(doc.data() as Map<String, dynamic>);
      }

      // Add results from description search
      for (final doc in descQuery.docs) {
        incidents[doc.id] = fromMap(doc.data() as Map<String, dynamic>);
      }

      return incidents.values.toList();
    } catch (e) {
      debugPrint('❌ Error searching incidents: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to search incidents',
      );
      return [];
    }
  }

  /// Get incidents with pagination
  Future<List<IncidentModel>> getIncidentsPaginated({
    required String schoolId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    IncidentStatus? status,
    IncidentSeverity? severity,
  }) async {
    try {
      Query query = collection
          .where('schoolId', isEqualTo: schoolId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      if (severity != null) {
        query = query.where('severity',
            isEqualTo: severity.toString().split('.').last);
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
      debugPrint('❌ Error getting paginated incidents: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get paginated incidents',
      );
      return [];
    }
  }
}
