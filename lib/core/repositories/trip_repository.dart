import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/trip_model.dart';
import 'base_repository.dart';

/// Repository for managing trip data
class TripRepository extends BaseRepository<TripModel> {
  @override
  String get collectionName => 'trips';

  @override
  TripModel fromMap(Map<String, dynamic> map) => TripModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(TripModel model) => model.toMap();

  /// Get trips for a specific driver
  Future<List<TripModel>> getTripsForDriver(String driverId) async {
    return getWhere('driverId', driverId);
  }

  /// Get trips stream for a specific driver
  Stream<List<TripModel>> getTripsStreamForDriver(String driverId) {
    return getStreamWhere('driverId', driverId);
  }

  /// Get active trips for a driver
  Future<List<TripModel>> getActiveTripsForDriver(String driverId) async {
    return getWhereMultiple({
      'driverId': driverId,
      'status': 'active',
    });
  }

  /// Get active trips stream for a driver
  Stream<List<TripModel>> getActiveTripsStreamForDriver(String driverId) {
    try {
      return collection
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      // Fallback to client-side filtering
      return getTripsStreamForDriver(driverId)
          .map((trips) => trips.where((trip) => trip.isActive).toList());
    }
  }

  /// Get trips for a specific bus
  Future<List<TripModel>> getTripsForBus(String busId) async {
    return getWhere('busId', busId);
  }

  /// Get trips stream for a specific bus
  Stream<List<TripModel>> getTripsStreamForBus(String busId) {
    return getStreamWhere('busId', busId);
  }

  /// Get trips for a specific route
  Future<List<TripModel>> getTripsForRoute(String routeId) async {
    return getWhere('routeId', routeId);
  }

  /// Get trips by date range
  Future<List<TripModel>> getTripsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await collection
          .where('startTime', isGreaterThanOrEqualTo: startDate)
          .where('startTime', isLessThanOrEqualTo: endDate)
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to getting all trips and filtering client-side
      final allTrips = await getAll();
      return allTrips
          .where((trip) =>
              trip.startTime.isAfter(startDate) &&
              trip.startTime.isBefore(endDate))
          .toList();
    }
  }

  /// Get trips by status
  Future<List<TripModel>> getTripsByStatus(TripStatus status) async {
    return getWhere('status', status.toString().split('.').last);
  }

  /// Get trips by type
  Future<List<TripModel>> getTripsByType(TripType type) async {
    return getWhere('type', type.toString().split('.').last);
  }

  /// Start a new trip
  Future<String> startTrip(TripModel trip) async {
    // Verify no active trip exists for this bus
    final activeTrips = await getWhereMultiple({
      'busId': trip.busId,
      'status': 'active',
    });

    if (activeTrips.isNotEmpty) {
      throw Exception('There is already an active trip for this bus');
    }

    return await create(trip);
  }

  /// Update trip location
  Future<void> updateTripLocation(String tripId, LocationData location) async {
    await update(tripId, {
      'currentLocation': location.toMap(),
      'locationHistory': FieldValue.arrayUnion([location.toMap()]),
    });
  }

  /// Add child to checked-in list
  Future<void> checkInChild(String tripId, String childId) async {
    await update(tripId, {
      'checkedInChildren': FieldValue.arrayUnion([childId]),
    });
  }

  /// Remove child from checked-in list
  Future<void> checkOutChild(String tripId, String childId) async {
    await update(tripId, {
      'checkedInChildren': FieldValue.arrayRemove([childId]),
    });
  }

  /// Complete a trip
  Future<void> completeTrip(String tripId) async {
    await update(tripId, {
      'status': 'completed',
      'endTime': DateTime.now(),
    });
  }

  /// Cancel a trip
  Future<void> cancelTrip(String tripId, String reason) async {
    await update(tripId, {
      'status': 'cancelled',
      'endTime': DateTime.now(),
      'metadata.cancellationReason': reason,
    });
  }

  /// Pause a trip
  Future<void> pauseTrip(String tripId, String reason) async {
    await update(tripId, {
      'status': 'paused',
      'metadata.pauseReason': reason,
      'metadata.pausedAt': DateTime.now(),
    });
  }

  /// Resume a paused trip
  Future<void> resumeTrip(String tripId) async {
    await update(tripId, {
      'status': 'active',
      'metadata.resumedAt': DateTime.now(),
    });
  }

  /// Get trip statistics for a driver
  Future<Map<String, dynamic>> getDriverStatistics(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<TripModel> trips;

    if (startDate != null && endDate != null) {
      trips = await getTripsByDateRange(startDate, endDate);
      trips = trips.where((trip) => trip.driverId == driverId).toList();
    } else {
      trips = await getTripsForDriver(driverId);
    }

    final completedTrips = trips.where((trip) => trip.isCompleted).toList();
    final cancelledTrips = trips.where((trip) => trip.isCancelled).toList();

    final totalChildren =
        trips.fold<int>(0, (sum, trip) => sum + trip.totalChildren);
    final totalCheckedIn =
        trips.fold<int>(0, (sum, trip) => sum + trip.checkedInCount);

    final totalDuration = completedTrips.fold<Duration>(
      Duration.zero,
      (sum, trip) => sum + (trip.duration ?? Duration.zero),
    );

    return {
      'totalTrips': trips.length,
      'completedTrips': completedTrips.length,
      'cancelledTrips': cancelledTrips.length,
      'totalChildren': totalChildren,
      'totalCheckedIn': totalCheckedIn,
      'averageCompletionRate':
          totalChildren > 0 ? (totalCheckedIn / totalChildren) * 100 : 0,
      'totalDuration': totalDuration.inMinutes,
      'averageTripDuration': completedTrips.isNotEmpty
          ? totalDuration.inMinutes / completedTrips.length
          : 0,
    };
  }

  /// Get active trips for a school
  /// Since trips don't have schoolId directly, we need to query through buses
  Future<List<TripModel>> getActiveTripsForSchool(String schoolId) async {
    // Get all active trips and filter by school through bus relationship
    final activeTrips = await getWhereMultiple({
      'status': 'active',
    });

    // This is a simplified approach - in production you might want to
    // use a compound query or maintain schoolId in trips
    return activeTrips;
  }

  /// Get active trips stream for a school
  /// Since trips don't have schoolId directly, we need to query through buses
  Stream<List<TripModel>> getActiveTripsStreamForSchool(String schoolId) {
    try {
      // For now, get all active trips and let the UI filter by school
      // In production, you might want to maintain schoolId in trips or use joins
      return collection
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      // Fallback to getting all trips and filtering client-side
      return getStream().map((trips) => trips
          .where((trip) => trip.status.toString().split('.').last == 'active')
          .toList());
    }
  }

  /// Get trip statistics for a school
  Future<Map<String, dynamic>> getSchoolStatistics(
    String schoolId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // This would require a compound query or client-side filtering
    // For now, we'll get all trips and filter client-side
    List<TripModel> allTrips;

    if (startDate != null && endDate != null) {
      allTrips = await getTripsByDateRange(startDate, endDate);
    } else {
      allTrips = await getAll();
    }

    // Filter by school (would need to join with bus/route data)
    // For now, this is a placeholder implementation
    final trips = allTrips; // TODO: Filter by school

    final completedTrips = trips.where((trip) => trip.isCompleted).toList();
    final activeTrips = trips.where((trip) => trip.isActive).toList();
    final cancelledTrips = trips.where((trip) => trip.isCancelled).toList();

    final pickupTrips =
        trips.where((trip) => trip.type == TripType.pickup).length;
    final dropoffTrips =
        trips.where((trip) => trip.type == TripType.dropoff).length;

    return {
      'totalTrips': trips.length,
      'activeTrips': activeTrips.length,
      'completedTrips': completedTrips.length,
      'cancelledTrips': cancelledTrips.length,
      'pickupTrips': pickupTrips,
      'dropoffTrips': dropoffTrips,
    };
  }

  /// Get recent trips
  Future<List<TripModel>> getRecentTrips({int limit = 10}) async {
    try {
      final querySnapshot = await collection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to getting all and sorting client-side
      final allTrips = await getAll();
      allTrips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allTrips.take(limit).toList();
    }
  }

  /// Search trips by bus number or route name
  Future<List<TripModel>> searchTrips(String query) async {
    try {
      // Search by bus number
      final busNumberResults = await collection
          .orderBy('busNumber')
          .startAt([query]).endAt(['$query\uf8ff']).get();

      // Search by route name
      final routeNameResults = await collection
          .orderBy('routeName')
          .startAt([query]).endAt(['$query\uf8ff']).get();

      final results = <TripModel>[];
      final seenIds = <String>{};

      for (final doc in [...busNumberResults.docs, ...routeNameResults.docs]) {
        if (!seenIds.contains(doc.id)) {
          results.add(fromMap(doc.data() as Map<String, dynamic>));
          seenIds.add(doc.id);
        }
      }

      return results;
    } catch (e) {
      // Fallback to client-side filtering
      final allTrips = await getAll();
      return allTrips
          .where((trip) =>
              trip.busNumber.toLowerCase().contains(query.toLowerCase()) ||
              trip.routeName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
