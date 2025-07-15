import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/attendance_model.dart';
import '../services/firebase_service.dart';
import 'base_repository.dart';

/// Repository for managing attendance data
class AttendanceRepository extends BaseRepository<AttendanceModel> {
  AttendanceRepository();

  @override
  String get collectionName => 'attendance';

  @override
  AttendanceModel fromMap(Map<String, dynamic> map) =>
      AttendanceModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(AttendanceModel model) => model.toMap();

  /// Get attendance by route and date
  Future<List<AttendanceModel>> getAttendanceByRouteAndDate(
      String routeId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await collection
          .where('routeId', isEqualTo: routeId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date')
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting attendance by route and date: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get attendance by route and date: $routeId, $date',
      );
      return [];
    }
  }

  /// Get attendance by route and date stream
  Stream<List<AttendanceModel>> getAttendanceByRouteAndDateStream(
      String routeId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return collection
        .where('routeId', isEqualTo: routeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get attendance by child
  Future<List<AttendanceModel>> getAttendanceByChild(String childId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = collection.where('childId', isEqualTo: childId);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.orderBy('date', descending: true).get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting attendance by child: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get attendance by child: $childId',
      );
      return [];
    }
  }

  /// Get attendance by child stream
  Stream<List<AttendanceModel>> getAttendanceByChildStream(String childId,
      {DateTime? startDate, DateTime? endDate}) {
    Query query = collection.where('childId', isEqualTo: childId);

    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query =
          query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.orderBy('date', descending: true).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Mark attendance
  Future<void> markAttendance(
    String childId,
    String routeId,
    String busId,
    String driverId,
    String stopId,
    AttendanceType type,
    AttendanceStatus status, {
    double? latitude,
    double? longitude,
    String? notes,
    String? photoUrl,
  }) async {
    try {
      final now = DateTime.now();
      final attendanceId =
          '${childId}_${routeId}_${type.toString().split('.').last}_${now.millisecondsSinceEpoch}';

      final attendance = AttendanceModel(
        id: attendanceId,
        childId: childId,
        routeId: routeId,
        busId: busId,
        driverId: driverId,
        stopId: stopId,
        date: now,
        type: type,
        status: status,
        actualTime: now,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
        photoUrl: photoUrl,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      );

      await create(attendance);

      // Log attendance event
      await FirebaseService.instance.logEvent('attendance_marked', {
        'child_id': childId,
        'route_id': routeId,
        'type': type.toString().split('.').last,
        'status': status.toString().split('.').last,
        'driver_id': driverId,
        'marked_at': now.toIso8601String(),
      });

      debugPrint('✅ Attendance marked: $childId - $status');
    } catch (e) {
      debugPrint('❌ Error marking attendance: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to mark attendance for child: $childId',
      );
      rethrow;
    }
  }

  /// Update attendance status
  Future<void> updateAttendanceStatus(
      String attendanceId, AttendanceStatus status,
      {String? notes}) async {
    try {
      await update(attendanceId, {
        'status': status.toString().split('.').last,
        'notes': notes,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Log attendance update event
      await FirebaseService.instance.logEvent('attendance_updated', {
        'attendance_id': attendanceId,
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Attendance updated: $attendanceId - $status');
    } catch (e) {
      debugPrint('❌ Error updating attendance: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to update attendance: $attendanceId',
      );
      rethrow;
    }
  }

  /// Get daily attendance summary
  Future<DailyAttendanceSummary> getDailyAttendanceSummary(
      String routeId, DateTime date) async {
    try {
      final attendances = await getAttendanceByRouteAndDate(routeId, date);

      final presentCount =
          attendances.where((a) => a.status == AttendanceStatus.present).length;
      final absentCount =
          attendances.where((a) => a.status == AttendanceStatus.absent).length;
      final lateCount =
          attendances.where((a) => a.status == AttendanceStatus.late).length;
      final earlyCount =
          attendances.where((a) => a.status == AttendanceStatus.early).length;
      final noShowCount =
          attendances.where((a) => a.status == AttendanceStatus.noShow).length;

      return DailyAttendanceSummary(
        id: '${routeId}_${date.millisecondsSinceEpoch}',
        routeId: routeId,
        driverId: attendances.isNotEmpty ? attendances.first.driverId : '',
        date: date,
        totalStudents: attendances.length,
        presentCount: presentCount,
        absentCount: absentCount,
        lateCount: lateCount,
        earlyCount: earlyCount,
        noShowCount: noShowCount,
        attendances: attendances,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error getting daily attendance summary: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get daily attendance summary: $routeId, $date',
      );
      rethrow;
    }
  }

  /// Get attendance statistics for driver
  Future<Map<String, dynamic>> getDriverAttendanceStats(String driverId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = collection.where('driverId', isEqualTo: driverId);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      final attendances = querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final totalAttendances = attendances.length;
      final presentCount =
          attendances.where((a) => a.status == AttendanceStatus.present).length;
      final absentCount =
          attendances.where((a) => a.status == AttendanceStatus.absent).length;
      final lateCount =
          attendances.where((a) => a.status == AttendanceStatus.late).length;
      final onTimeCount = attendances.where((a) => a.isOnTime).length;

      return {
        'totalAttendances': totalAttendances,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
        'onTimeCount': onTimeCount,
        'attendanceRate':
            totalAttendances > 0 ? (presentCount / totalAttendances) * 100 : 0,
        'punctualityRate':
            presentCount > 0 ? (onTimeCount / presentCount) * 100 : 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting driver attendance stats: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get driver attendance stats: $driverId',
      );
      return {
        'totalAttendances': 0,
        'presentCount': 0,
        'absentCount': 0,
        'lateCount': 0,
        'onTimeCount': 0,
        'attendanceRate': 0,
        'punctualityRate': 0,
      };
    }
  }

  /// Get attendance statistics for child
  Future<Map<String, dynamic>> getChildAttendanceStats(String childId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final attendances = await getAttendanceByChild(childId,
          startDate: startDate, endDate: endDate);

      final totalAttendances = attendances.length;
      final presentCount =
          attendances.where((a) => a.status == AttendanceStatus.present).length;
      final absentCount =
          attendances.where((a) => a.status == AttendanceStatus.absent).length;
      final lateCount =
          attendances.where((a) => a.status == AttendanceStatus.late).length;
      final onTimeCount = attendances.where((a) => a.isOnTime).length;

      return {
        'totalAttendances': totalAttendances,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
        'onTimeCount': onTimeCount,
        'attendanceRate':
            totalAttendances > 0 ? (presentCount / totalAttendances) * 100 : 0,
        'punctualityRate':
            presentCount > 0 ? (onTimeCount / presentCount) * 100 : 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting child attendance stats: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get child attendance stats: $childId',
      );
      return {
        'totalAttendances': 0,
        'presentCount': 0,
        'absentCount': 0,
        'lateCount': 0,
        'onTimeCount': 0,
        'attendanceRate': 0,
        'punctualityRate': 0,
      };
    }
  }
}
