import '../../shared/models/child_model.dart';
import 'base_repository.dart';

/// Repository for managing children data
class ChildRepository extends BaseRepository<ChildModel> {
  @override
  String get collectionName => 'children';

  @override
  ChildModel fromMap(Map<String, dynamic> map) => ChildModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(ChildModel model) => model.toMap();

  /// Get children for a specific parent
  Future<List<ChildModel>> getChildrenForParent(String parentId) async {
    return getWhere('parentId', parentId);
  }

  /// Get children stream for a specific parent
  Stream<List<ChildModel>> getChildrenStreamForParent(String parentId) {
    return getStreamWhere('parentId', parentId);
  }

  /// Get children for a specific school
  Future<List<ChildModel>> getChildrenForSchool(String schoolId) async {
    return getWhere('schoolId', schoolId);
  }

  /// Get children stream for a specific school
  Stream<List<ChildModel>> getChildrenStreamForSchool(String schoolId) {
    return getStreamWhere('schoolId', schoolId);
  }

  /// Get children for a specific bus
  Future<List<ChildModel>> getChildrenForBus(String busId) async {
    return getWhere('busId', busId);
  }

  /// Get children stream for a specific bus
  Stream<List<ChildModel>> getChildrenStreamForBus(String busId) {
    return getStreamWhere('busId', busId);
  }

  /// Get children for a specific route
  Future<List<ChildModel>> getChildrenForRoute(String routeId) async {
    return getWhere('routeId', routeId);
  }

  /// Get children stream for a specific route
  Stream<List<ChildModel>> getChildrenStreamForRoute(String routeId) {
    return getStreamWhere('routeId', routeId);
  }

  /// Get children by grade
  Future<List<ChildModel>> getChildrenByGrade(String schoolId, String grade) async {
    return getWhereMultiple({
      'schoolId': schoolId,
      'grade': grade,
      'isActive': true,
    });
  }

  /// Get children by class
  Future<List<ChildModel>> getChildrenByClass(String schoolId, String className) async {
    return getWhereMultiple({
      'schoolId': schoolId,
      'className': className,
      'isActive': true,
    });
  }

  /// Assign child to bus and route
  Future<void> assignTransport(String childId, String busId, String routeId, 
      {String? pickupStopId, String? dropoffStopId}) async {
    await update(childId, {
      'busId': busId,
      'routeId': routeId,
      'pickupStopId': pickupStopId,
      'dropoffStopId': dropoffStopId,
    });
  }

  /// Remove child from transport
  Future<void> removeTransport(String childId) async {
    await update(childId, {
      'busId': null,
      'routeId': null,
      'pickupStopId': null,
      'dropoffStopId': null,
    });
  }

  /// Update child's pickup/dropoff stops
  Future<void> updateStops(String childId, {String? pickupStopId, String? dropoffStopId}) async {
    final updateData = <String, dynamic>{};
    if (pickupStopId != null) updateData['pickupStopId'] = pickupStopId;
    if (dropoffStopId != null) updateData['dropoffStopId'] = dropoffStopId;
    
    if (updateData.isNotEmpty) {
      await update(childId, updateData);
    }
  }

  /// Search children by name
  Future<List<ChildModel>> searchByName(String schoolId, String query) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
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
      final allChildren = await getChildrenForSchool(schoolId);
      return allChildren
          .where((child) => child.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Get children with transport assigned
  Future<List<ChildModel>> getChildrenWithTransport(String schoolId) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .where('busId', isNotEqualTo: null)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allChildren = await getChildrenForSchool(schoolId);
      return allChildren.where((child) => child.hasTransportAssigned).toList();
    }
  }

  /// Get children without transport assigned
  Future<List<ChildModel>> getChildrenWithoutTransport(String schoolId) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .where('busId', isEqualTo: null)
          .get();
      
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allChildren = await getChildrenForSchool(schoolId);
      return allChildren.where((child) => !child.hasTransportAssigned).toList();
    }
  }

  /// Get children statistics for a school
  Future<Map<String, int>> getSchoolStatistics(String schoolId) async {
    final allChildren = await getChildrenForSchool(schoolId);
    final activeChildren = allChildren.where((child) => child.isActive).toList();
    
    return {
      'total': activeChildren.length,
      'withTransport': activeChildren.where((child) => child.hasTransportAssigned).length,
      'withoutTransport': activeChildren.where((child) => !child.hasTransportAssigned).length,
      'withEmergencyContact': activeChildren.where((child) => child.hasEmergencyContact).length,
    };
  }

  /// Bulk assign children to transport
  Future<void> bulkAssignTransport(List<String> childIds, String busId, String routeId) async {
    final updates = <String, Map<String, dynamic>>{};
    
    for (final childId in childIds) {
      updates[childId] = {
        'busId': busId,
        'routeId': routeId,
      };
    }
    
    await batchUpdate(updates);
  }

  /// Bulk remove children from transport
  Future<void> bulkRemoveTransport(List<String> childIds) async {
    final updates = <String, Map<String, dynamic>>{};
    
    for (final childId in childIds) {
      updates[childId] = {
        'busId': null,
        'routeId': null,
        'pickupStopId': null,
        'dropoffStopId': null,
      };
    }
    
    await batchUpdate(updates);
  }
}
