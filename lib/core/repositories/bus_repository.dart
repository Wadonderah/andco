import '../../shared/models/bus_model.dart';
import 'base_repository.dart';

/// Repository for managing bus data
class BusRepository extends BaseRepository<BusModel> {
  @override
  String get collectionName => 'buses';

  @override
  BusModel fromMap(Map<String, dynamic> map) => BusModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(BusModel model) => model.toMap();

  /// Get buses for a specific school
  Future<List<BusModel>> getBusesForSchool(String schoolId) async {
    return getWhere('schoolId', schoolId);
  }

  /// Get buses stream for a specific school
  Stream<List<BusModel>> getBusesStreamForSchool(String schoolId) {
    return getStreamWhere('schoolId', schoolId);
  }

  /// Get buses by status
  Future<List<BusModel>> getBusesByStatus(String schoolId, BusStatus status) async {
    return getWhereMultiple({
      'schoolId': schoolId,
      'status': status.toString().split('.').last,
      'isActive': true,
    });
  }

  /// Get active buses for a school
  Future<List<BusModel>> getActiveBuses(String schoolId) async {
    return getWhereMultiple({
      'schoolId': schoolId,
      'isActive': true,
    });
  }

  /// Get buses assigned to a driver
  Future<List<BusModel>> getBusesForDriver(String driverId) async {
    return getWhere('driverId', driverId);
  }

  /// Get buses stream for a driver
  Stream<List<BusModel>> getBusesStreamForDriver(String driverId) {
    return getStreamWhere('driverId', driverId);
  }

  /// Get available buses (no driver assigned)
  Future<List<BusModel>> getAvailableBuses(String schoolId) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .where('driverId', isEqualTo: null)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allBuses = await getBusesForSchool(schoolId);
      return allBuses.where((bus) => !bus.hasDriver && bus.isActive).toList();
    }
  }

  /// Assign driver to bus
  Future<void> assignDriver(String busId, String driverId) async {
    await update(busId, {'driverId': driverId});
  }

  /// Remove driver from bus
  Future<void> removeDriver(String busId) async {
    await update(busId, {'driverId': null});
  }

  /// Update bus status
  Future<void> updateStatus(String busId, BusStatus status) async {
    await update(busId, {'status': status.toString().split('.').last});
  }

  /// Update bus location
  Future<void> updateLocation(String busId, double latitude, double longitude) async {
    await update(busId, {
      'currentLatitude': latitude,
      'currentLongitude': longitude,
      'lastLocationUpdate': DateTime.now(),
    });
  }

  /// Update maintenance dates
  Future<void> updateMaintenance(String busId, {
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
  }) async {
    final updateData = <String, dynamic>{};
    if (lastMaintenanceDate != null) {
      updateData['lastMaintenanceDate'] = lastMaintenanceDate;
    }
    if (nextMaintenanceDate != null) {
      updateData['nextMaintenanceDate'] = nextMaintenanceDate;
    }
    
    if (updateData.isNotEmpty) {
      await update(busId, updateData);
    }
  }

  /// Search buses by number or license plate
  Future<List<BusModel>> searchBuses(String schoolId, String query) async {
    try {
      // Search by bus number
      final busNumberResults = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .orderBy('busNumber')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();
      
      // Search by license plate
      final licensePlateResults = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .orderBy('licensePlate')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();
      
      final results = <BusModel>[];
      final seenIds = <String>{};
      
      for (final doc in [...busNumberResults.docs, ...licensePlateResults.docs]) {
        if (!seenIds.contains(doc.id)) {
          results.add(fromMap(doc.data() as Map<String, dynamic>));
          seenIds.add(doc.id);
        }
      }
      
      return results;
    } catch (e) {
      // Fallback to client-side filtering
      final allBuses = await getBusesForSchool(schoolId);
      return allBuses.where((bus) =>
          bus.busNumber.toLowerCase().contains(query.toLowerCase()) ||
          bus.licensePlate.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  /// Get buses needing maintenance
  Future<List<BusModel>> getBusesNeedingMaintenance(String schoolId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .where('nextMaintenanceDate', isLessThanOrEqualTo: now)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allBuses = await getBusesForSchool(schoolId);
      return allBuses.where((bus) => bus.needsMaintenance).toList();
    }
  }

  /// Get bus statistics for a school
  Future<Map<String, int>> getSchoolStatistics(String schoolId) async {
    final allBuses = await getBusesForSchool(schoolId);
    final activeBuses = allBuses.where((bus) => bus.isActive).toList();
    
    return {
      'total': activeBuses.length,
      'active': activeBuses.where((bus) => bus.status == BusStatus.active).length,
      'inTransit': activeBuses.where((bus) => bus.status == BusStatus.inTransit).length,
      'maintenance': activeBuses.where((bus) => bus.status == BusStatus.maintenance).length,
      'outOfService': activeBuses.where((bus) => bus.status == BusStatus.outOfService).length,
      'withDriver': activeBuses.where((bus) => bus.hasDriver).length,
      'withoutDriver': activeBuses.where((bus) => !bus.hasDriver).length,
      'needingMaintenance': activeBuses.where((bus) => bus.needsMaintenance).length,
    };
  }

  /// Get operational buses (active or in transit)
  Future<List<BusModel>> getOperationalBuses(String schoolId) async {
    final allBuses = await getBusesForSchool(schoolId);
    return allBuses.where((bus) => bus.isOperational && bus.isActive).toList();
  }

  /// Bulk update bus statuses
  Future<void> bulkUpdateStatus(List<String> busIds, BusStatus status) async {
    final updates = <String, Map<String, dynamic>>{};
    
    for (final busId in busIds) {
      updates[busId] = {'status': status.toString().split('.').last};
    }
    
    await batchUpdate(updates);
  }

  /// Get buses by capacity range
  Future<List<BusModel>> getBusesByCapacity(String schoolId, int minCapacity, int maxCapacity) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .where('capacity', isGreaterThanOrEqualTo: minCapacity)
          .where('capacity', isLessThanOrEqualTo: maxCapacity)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allBuses = await getBusesForSchool(schoolId);
      return allBuses.where((bus) => 
          bus.capacity >= minCapacity && 
          bus.capacity <= maxCapacity &&
          bus.isActive
      ).toList();
    }
  }

  /// Get buses by year range
  Future<List<BusModel>> getBusesByYear(String schoolId, int minYear, int maxYear) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .where('year', isGreaterThanOrEqualTo: minYear)
          .where('year', isLessThanOrEqualTo: maxYear)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allBuses = await getBusesForSchool(schoolId);
      return allBuses.where((bus) => 
          bus.year >= minYear && 
          bus.year <= maxYear &&
          bus.isActive
      ).toList();
    }
  }
}
