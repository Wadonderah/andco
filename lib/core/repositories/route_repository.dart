import 'dart:math' as math;

import '../../shared/models/route_model.dart';
import 'base_repository.dart';

/// Repository for managing route data
class RouteRepository extends BaseRepository<RouteModel> {
  @override
  String get collectionName => 'routes';

  @override
  RouteModel fromMap(Map<String, dynamic> map) => RouteModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(RouteModel model) => model.toMap();

  /// Get routes for a specific school
  Future<List<RouteModel>> getRoutesForSchool(String schoolId) async {
    return getWhere('schoolId', schoolId);
  }

  /// Get routes stream for a specific school
  Stream<List<RouteModel>> getRoutesStreamForSchool(String schoolId) {
    return getStreamWhere('schoolId', schoolId);
  }

  /// Get routes by type
  Future<List<RouteModel>> getRoutesByType(
      String schoolId, RouteType type) async {
    return getWhereMultiple({
      'schoolId': schoolId,
      'type': type.toString().split('.').last,
      'isActive': true,
    });
  }

  /// Get active routes for a school
  Future<List<RouteModel>> getActiveRoutes(String schoolId) async {
    return getWhereMultiple({
      'schoolId': schoolId,
      'isActive': true,
    });
  }

  /// Get routes assigned to a bus
  Future<List<RouteModel>> getRoutesForBus(String busId) async {
    return getWhere('busId', busId);
  }

  /// Get routes stream for a bus
  Stream<List<RouteModel>> getRoutesStreamForBus(String busId) {
    return getStreamWhere('busId', busId);
  }

  /// Get available routes (no bus assigned)
  Future<List<RouteModel>> getAvailableRoutes(String schoolId) async {
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
      final allRoutes = await getRoutesForSchool(schoolId);
      return allRoutes
          .where((route) => !route.hasBusAssigned && route.isActive)
          .toList();
    }
  }

  /// Assign bus to route
  Future<void> assignBus(String routeId, String busId) async {
    await update(routeId, {'busId': busId});
  }

  /// Remove bus from route
  Future<void> removeBus(String routeId) async {
    await update(routeId, {'busId': null});
  }

  /// Update route stops
  Future<void> updateStops(String routeId, List<RouteStop> stops) async {
    await update(routeId, {
      'stops': stops.map((stop) => stop.toMap()).toList(),
    });
  }

  /// Add stop to route
  Future<void> addStop(String routeId, RouteStop stop) async {
    final route = await getById(routeId);
    if (route != null) {
      final updatedStops = [...route.stops, stop];
      await updateStops(routeId, updatedStops);
    }
  }

  /// Remove stop from route
  Future<void> removeStop(String routeId, String stopId) async {
    final route = await getById(routeId);
    if (route != null) {
      final updatedStops =
          route.stops.where((stop) => stop.id != stopId).toList();
      await updateStops(routeId, updatedStops);
    }
  }

  /// Update stop order
  Future<void> updateStopOrder(String routeId, List<String> stopIds) async {
    final route = await getById(routeId);
    if (route != null) {
      final stopsMap = {for (var stop in route.stops) stop.id: stop};
      final reorderedStops = <RouteStop>[];

      for (int i = 0; i < stopIds.length; i++) {
        final stop = stopsMap[stopIds[i]];
        if (stop != null) {
          // Update the order
          final updatedStop = RouteStop(
            id: stop.id,
            name: stop.name,
            latitude: stop.latitude,
            longitude: stop.longitude,
            address: stop.address,
            order: i + 1,
            scheduledTime: stop.scheduledTime,
            estimatedWaitTime: stop.estimatedWaitTime,
            childrenIds: stop.childrenIds,
            isActive: stop.isActive,
            metadata: stop.metadata,
          );
          reorderedStops.add(updatedStop);
        }
      }

      await updateStops(routeId, reorderedStops);
    }
  }

  /// Search routes by name
  Future<List<RouteModel>> searchByName(String schoolId, String query) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .startAt([query]).endAt(['$query\uf8ff']).get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allRoutes = await getRoutesForSchool(schoolId);
      return allRoutes
          .where(
              (route) => route.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Get routes active today
  Future<List<RouteModel>> getRoutesActiveToday(String schoolId) async {
    final allRoutes = await getActiveRoutes(schoolId);
    return allRoutes.where((route) => route.isActiveToday).toList();
  }

  /// Get routes by time range
  Future<List<RouteModel>> getRoutesByTimeRange(
      String schoolId, DateTime startTime, DateTime endTime) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .where('startTime', isGreaterThanOrEqualTo: startTime)
          .where('startTime', isLessThanOrEqualTo: endTime)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allRoutes = await getActiveRoutes(schoolId);
      return allRoutes
          .where((route) =>
              route.startTime.isAfter(startTime) &&
              route.startTime.isBefore(endTime))
          .toList();
    }
  }

  /// Get route statistics for a school
  Future<Map<String, dynamic>> getSchoolStatistics(String schoolId) async {
    final allRoutes = await getRoutesForSchool(schoolId);
    final activeRoutes = allRoutes.where((route) => route.isActive).toList();

    final pickupRoutes =
        activeRoutes.where((route) => route.type == RouteType.pickup).length;
    final dropoffRoutes =
        activeRoutes.where((route) => route.type == RouteType.dropoff).length;
    final roundTripRoutes =
        activeRoutes.where((route) => route.type == RouteType.roundTrip).length;

    final totalStops =
        activeRoutes.fold<int>(0, (sum, route) => sum + route.stopCount);
    final averageStops =
        activeRoutes.isNotEmpty ? totalStops / activeRoutes.length : 0.0;

    final totalDistance =
        activeRoutes.fold<double>(0, (sum, route) => sum + route.distance);
    final averageDistance =
        activeRoutes.isNotEmpty ? totalDistance / activeRoutes.length : 0.0;

    return {
      'total': activeRoutes.length,
      'pickup': pickupRoutes,
      'dropoff': dropoffRoutes,
      'roundTrip': roundTripRoutes,
      'withBus': activeRoutes.where((route) => route.hasBusAssigned).length,
      'withoutBus': activeRoutes.where((route) => !route.hasBusAssigned).length,
      'activeToday': activeRoutes.where((route) => route.isActiveToday).length,
      'totalStops': totalStops,
      'averageStops': averageStops,
      'totalDistance': totalDistance,
      'averageDistance': averageDistance,
    };
  }

  /// Optimize route stops order (simple distance-based optimization)
  Future<void> optimizeStopsOrder(String routeId) async {
    final route = await getById(routeId);
    if (route == null || route.stops.length < 2) return;

    // Simple nearest neighbor optimization
    final stops = List<RouteStop>.from(route.stops);
    final optimizedStops = <RouteStop>[];

    // Start with the first stop
    optimizedStops.add(stops.removeAt(0));

    while (stops.isNotEmpty) {
      final currentStop = optimizedStops.last;
      int nearestIndex = 0;
      double nearestDistance = double.infinity;

      for (int i = 0; i < stops.length; i++) {
        final distance = _calculateDistance(
          currentStop.latitude,
          currentStop.longitude,
          stops[i].latitude,
          stops[i].longitude,
        );

        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestIndex = i;
        }
      }

      optimizedStops.add(stops.removeAt(nearestIndex));
    }

    // Update order numbers
    for (int i = 0; i < optimizedStops.length; i++) {
      final stop = optimizedStops[i];
      optimizedStops[i] = RouteStop(
        id: stop.id,
        name: stop.name,
        latitude: stop.latitude,
        longitude: stop.longitude,
        address: stop.address,
        order: i + 1,
        scheduledTime: stop.scheduledTime,
        estimatedWaitTime: stop.estimatedWaitTime,
        childrenIds: stop.childrenIds,
        isActive: stop.isActive,
        metadata: stop.metadata,
      );
    }

    await updateStops(routeId, optimizedStops);
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Bulk assign buses to routes
  Future<void> bulkAssignBuses(Map<String, String> routeBusAssignments) async {
    final updates = <String, Map<String, dynamic>>{};

    routeBusAssignments.forEach((routeId, busId) {
      updates[routeId] = {'busId': busId};
    });

    await batchUpdate(updates);
  }
}
