import '../../shared/models/checkin_model.dart';
import 'base_repository.dart';

/// Repository for managing check-in data
class CheckinRepository extends BaseRepository<CheckinModel> {
  @override
  String get collectionName => 'checkins';

  @override
  CheckinModel fromMap(Map<String, dynamic> map) => CheckinModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(CheckinModel model) => model.toMap();

  /// Get check-ins for a specific trip
  Future<List<CheckinModel>> getCheckinsForTrip(String tripId) async {
    return getWhere('tripId', tripId);
  }

  /// Get check-ins stream for a specific trip
  Stream<List<CheckinModel>> getCheckinsStreamForTrip(String tripId) {
    return getStreamWhere('tripId', tripId);
  }

  /// Get check-ins for a specific child
  Future<List<CheckinModel>> getCheckinsForChild(String childId) async {
    return getWhere('childId', childId);
  }

  /// Get check-ins stream for a specific child
  Stream<List<CheckinModel>> getCheckinsStreamForChild(String childId) {
    return getStreamWhere('childId', childId);
  }

  /// Get check-ins for a specific driver
  Future<List<CheckinModel>> getCheckinsForDriver(String driverId) async {
    return getWhere('driverId', driverId);
  }

  /// Get check-ins by date range
  Future<List<CheckinModel>> getCheckinsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await collection
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to getting all check-ins and filtering client-side
      final allCheckins = await getAll();
      return allCheckins.where((checkin) =>
          checkin.timestamp.isAfter(startDate) && 
          checkin.timestamp.isBefore(endDate)
      ).toList();
    }
  }

  /// Get check-ins by method
  Future<List<CheckinModel>> getCheckinsByMethod(CheckinMethod method) async {
    return getWhere('method', method.toString().split('.').last);
  }

  /// Get check-ins by status
  Future<List<CheckinModel>> getCheckinsByStatus(CheckinStatus status) async {
    return getWhere('status', status.toString().split('.').last);
  }

  /// Get today's check-ins for a child
  Future<List<CheckinModel>> getTodayCheckinsForChild(String childId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final querySnapshot = await collection
          .where('childId', isEqualTo: childId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final childCheckins = await getCheckinsForChild(childId);
      return childCheckins.where((checkin) =>
          checkin.timestamp.isAfter(startOfDay) && 
          checkin.timestamp.isBefore(endOfDay)
      ).toList();
    }
  }

  /// Get latest check-in for a child
  Future<CheckinModel?> getLatestCheckinForChild(String childId) async {
    try {
      final querySnapshot = await collection
          .where('childId', isEqualTo: childId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // Fallback to getting all and sorting client-side
      final childCheckins = await getCheckinsForChild(childId);
      if (childCheckins.isNotEmpty) {
        childCheckins.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return childCheckins.first;
      }
      return null;
    }
  }

  /// Create check-in with validation
  Future<String> createCheckin(CheckinModel checkin) async {
    // Validate that child hasn't already been checked in for this trip
    final existingCheckins = await getWhereMultiple({
      'tripId': checkin.tripId,
      'childId': checkin.childId,
    });

    if (existingCheckins.isNotEmpty) {
      throw Exception('Child has already been checked in for this trip');
    }

    return await create(checkin);
  }

  /// Update check-in status
  Future<void> updateCheckinStatus(String checkinId, CheckinStatus status) async {
    await update(checkinId, {
      'status': status.toString().split('.').last,
    });
  }

  /// Add notes to check-in
  Future<void> addNotes(String checkinId, String notes) async {
    await update(checkinId, {'notes': notes});
  }

  /// Get check-in statistics for a child
  Future<Map<String, dynamic>> getChildStatistics(String childId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<CheckinModel> checkins;
    
    if (startDate != null && endDate != null) {
      checkins = await getCheckinsByDateRange(startDate, endDate);
      checkins = checkins.where((checkin) => checkin.childId == childId).toList();
    } else {
      checkins = await getCheckinsForChild(childId);
    }

    final confirmedCheckins = checkins.where((checkin) => checkin.isConfirmed).toList();
    final pendingCheckins = checkins.where((checkin) => checkin.isPending).toList();
    final cancelledCheckins = checkins.where((checkin) => checkin.isCancelled).toList();

    final methodCounts = <String, int>{};
    for (final checkin in checkins) {
      final method = checkin.method.toString().split('.').last;
      methodCounts[method] = (methodCounts[method] ?? 0) + 1;
    }

    return {
      'totalCheckins': checkins.length,
      'confirmedCheckins': confirmedCheckins.length,
      'pendingCheckins': pendingCheckins.length,
      'cancelledCheckins': cancelledCheckins.length,
      'methodCounts': methodCounts,
      'attendanceRate': checkins.isNotEmpty 
          ? (confirmedCheckins.length / checkins.length) * 100 
          : 0,
    };
  }

  /// Get check-in statistics for a driver
  Future<Map<String, dynamic>> getDriverStatistics(String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<CheckinModel> checkins;
    
    if (startDate != null && endDate != null) {
      checkins = await getCheckinsByDateRange(startDate, endDate);
      checkins = checkins.where((checkin) => checkin.driverId == driverId).toList();
    } else {
      checkins = await getCheckinsForDriver(driverId);
    }

    final confirmedCheckins = checkins.where((checkin) => checkin.isConfirmed).toList();
    final withPhotos = checkins.where((checkin) => checkin.hasPhoto).toList();
    final withLocation = checkins.where((checkin) => checkin.hasLocation).toList();

    final methodCounts = <String, int>{};
    for (final checkin in checkins) {
      final method = checkin.method.toString().split('.').last;
      methodCounts[method] = (methodCounts[method] ?? 0) + 1;
    }

    return {
      'totalCheckins': checkins.length,
      'confirmedCheckins': confirmedCheckins.length,
      'checkinsWithPhotos': withPhotos.length,
      'checkinsWithLocation': withLocation.length,
      'methodCounts': methodCounts,
      'confirmationRate': checkins.isNotEmpty 
          ? (confirmedCheckins.length / checkins.length) * 100 
          : 0,
    };
  }

  /// Get attendance report for a date range
  Future<Map<String, dynamic>> getAttendanceReport(DateTime startDate, DateTime endDate) async {
    final checkins = await getCheckinsByDateRange(startDate, endDate);
    
    final dailyAttendance = <String, int>{};
    final childAttendance = <String, int>{};
    final busAttendance = <String, int>{};

    for (final checkin in checkins) {
      if (checkin.isConfirmed) {
        // Daily attendance
        final dateKey = '${checkin.timestamp.year}-${checkin.timestamp.month.toString().padLeft(2, '0')}-${checkin.timestamp.day.toString().padLeft(2, '0')}';
        dailyAttendance[dateKey] = (dailyAttendance[dateKey] ?? 0) + 1;

        // Child attendance
        childAttendance[checkin.childId] = (childAttendance[checkin.childId] ?? 0) + 1;

        // Bus attendance
        busAttendance[checkin.busId] = (busAttendance[checkin.busId] ?? 0) + 1;
      }
    }

    return {
      'totalCheckins': checkins.length,
      'confirmedCheckins': checkins.where((c) => c.isConfirmed).length,
      'dailyAttendance': dailyAttendance,
      'childAttendance': childAttendance,
      'busAttendance': busAttendance,
      'averageDailyAttendance': dailyAttendance.values.isNotEmpty 
          ? dailyAttendance.values.reduce((a, b) => a + b) / dailyAttendance.length 
          : 0,
    };
  }

  /// Get recent check-ins
  Future<List<CheckinModel>> getRecentCheckins({int limit = 20}) async {
    try {
      final querySnapshot = await collection
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to getting all and sorting client-side
      final allCheckins = await getAll();
      allCheckins.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allCheckins.take(limit).toList();
    }
  }

  /// Search check-ins by child name
  Future<List<CheckinModel>> searchCheckinsByChildName(String query) async {
    try {
      final querySnapshot = await collection
          .orderBy('childName')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allCheckins = await getAll();
      return allCheckins.where((checkin) =>
          checkin.childName.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  /// Bulk update check-in statuses
  Future<void> bulkUpdateStatus(List<String> checkinIds, CheckinStatus status) async {
    final updates = <String, Map<String, dynamic>>{};
    
    for (final checkinId in checkinIds) {
      updates[checkinId] = {'status': status.toString().split('.').last};
    }
    
    await batchUpdate(updates);
  }
}
