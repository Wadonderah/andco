import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/trip_repository.dart';
import '../services/firebase_service.dart';
import '../../shared/models/trip_model.dart';

/// Provider for trip repository
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

/// Provider for trips by driver
final tripsByDriverProvider = StreamProvider.family<List<TripModel>, String>((ref, driverId) {
  final repository = ref.read(tripRepositoryProvider);
  return repository.getTripsStreamForDriver(driverId);
});

/// Provider for active trips by driver
final activeTripsProvider = StreamProvider.family<List<TripModel>, String>((ref, driverId) {
  final repository = ref.read(tripRepositoryProvider);
  return repository.getActiveTripsStreamForDriver(driverId);
});

/// Provider for trips by bus
final tripsByBusProvider = StreamProvider.family<List<TripModel>, String>((ref, busId) {
  final repository = ref.read(tripRepositoryProvider);
  return repository.getTripsStreamForBus(busId);
});

/// Provider for trip by ID
final tripByIdProvider = StreamProvider.family<TripModel?, String>((ref, tripId) {
  final repository = ref.read(tripRepositoryProvider);
  return repository.getStreamById(tripId);
});

/// Provider for recent trips
final recentTripsProvider = FutureProvider.family<List<TripModel>, int>((ref, limit) async {
  final repository = ref.read(tripRepositoryProvider);
  return repository.getRecentTrips(limit: limit);
});

/// Trip controller for managing trip operations
class TripController extends StateNotifier<AsyncValue<TripModel?>> {
  TripController(this._repository) : super(const AsyncValue.data(null));

  final TripRepository _repository;

  /// Start a new trip
  Future<String?> startTrip(TripModel trip) async {
    state = const AsyncValue.loading();
    
    try {
      final tripId = await _repository.startTrip(trip);
      
      await FirebaseService.instance.logEvent('trip_started', {
        'trip_id': tripId,
        'bus_id': trip.busId,
        'route_id': trip.routeId,
        'driver_id': trip.driverId,
        'type': trip.type.toString(),
      });
      
      final createdTrip = await _repository.getById(tripId);
      state = AsyncValue.data(createdTrip);
      return tripId;
    } catch (e, stackTrace) {
      await FirebaseService.instance.logError(e, stackTrace, reason: 'Failed to start trip');
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Update trip location
  Future<void> updateLocation(String tripId, LocationData location) async {
    try {
      await _repository.updateTripLocation(tripId, location);
      
      await FirebaseService.instance.logEvent('trip_location_updated', {
        'trip_id': tripId,
        'latitude': location.latitude,
        'longitude': location.longitude,
      });
    } catch (e, stackTrace) {
      await FirebaseService.instance.logError(e, stackTrace, reason: 'Failed to update trip location');
      rethrow;
    }
  }

  /// Check in a child
  Future<void> checkInChild(String tripId, String childId) async {
    try {
      await _repository.checkInChild(tripId, childId);
      
      await FirebaseService.instance.logEvent('child_checked_in', {
        'trip_id': tripId,
        'child_id': childId,
      });
    } catch (e, stackTrace) {
      await FirebaseService.instance.logError(e, stackTrace, reason: 'Failed to check in child');
      rethrow;
    }
  }

  /// Check out a child
  Future<void> checkOutChild(String tripId, String childId) async {
    try {
      await _repository.checkOutChild(tripId, childId);
      
      await FirebaseService.instance.logEvent('child_checked_out', {
        'trip_id': tripId,
        'child_id': childId,
      });
    } catch (e, stackTrace) {
      await FirebaseService.instance.logError(e, stackTrace, reason: 'Failed to check out child');
      rethrow;
    }
  }

  /// Complete a trip
  Future<void> completeTrip(String tripId) async {
    try {
      await _repository.completeTrip(tripId);
      
      await FirebaseService.instance.logEvent('trip_completed', {
        'trip_id': tripId,
      });
      
      // Update state to reflect completion
      final completedTrip = await _repository.getById(tripId);
      state = AsyncValue.data(completedTrip);
    } catch (e, stackTrace) {
      await FirebaseService.instance.logError(e, stackTrace, reason: 'Failed to complete trip');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Cancel a trip
  Future<void> cancelTrip(String tripId, String reason) async {
    try {
      await _repository.cancelTrip(tripId, reason);
      
      await FirebaseService.instance.logEvent('trip_cancelled', {
        'trip_id': tripId,
        'reason': reason,
      });
      
      // Update state to reflect cancellation
      final cancelledTrip = await _repository.getById(tripId);
      state = AsyncValue.data(cancelledTrip);
    } catch (e, stackTrace) {
      await FirebaseService.instance.logError(e, stackTrace, reason: 'Failed to cancel trip');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Pause a trip
  Future<void> pauseTrip(String tripId, String reason) async {
    try {
      await _repository.pauseTrip(tripId, reason);
      
      await FirebaseService.instance.logEvent('trip_paused', {
        'trip_id': tripId,
        'reason': reason,
      });
      
      // Update state to reflect pause
      final pausedTrip = await _repository.getById(tripId);
      state = AsyncValue.data(pausedTrip);
    } catch (e, stackTrace) {
      await FirebaseService.instance.logError(e, stackTrace, reason: 'Failed to pause trip');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Resume a paused trip
  Future<void> resumeTrip(String tripId) async {
    try {
      await _repository.resumeTrip(tripId);
      
      await FirebaseService.instance.logEvent('trip_resumed', {
        'trip_id': tripId,
      });
      
      // Update state to reflect resume
      final resumedTrip = await _repository.getById(tripId);
      state = AsyncValue.data(resumedTrip);
    } catch (e, stackTrace) {
      await FirebaseService.instance.logError(e, stackTrace, reason: 'Failed to resume trip');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Get trip statistics for a driver
  Future<Map<String, dynamic>> getDriverStatistics(String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _repository.getDriverStatistics(
        driverId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e, stackTrace) {
      await FirebaseService.instance.logError(e, stackTrace, reason: 'Failed to get driver statistics');
      rethrow;
    }
  }

  /// Search trips
  Future<List<TripModel>> searchTrips(String query) async {
    try {
      return await _repository.searchTrips(query);
    } catch (e, stackTrace) {
      await FirebaseService.instance.logError(e, stackTrace, reason: 'Failed to search trips');
      rethrow;
    }
  }
}

/// Provider for trip controller
final tripControllerProvider = StateNotifierProvider<TripController, AsyncValue<TripModel?>>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  return TripController(repository);
});

/// Provider for driver statistics
final driverStatisticsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final controller = ref.read(tripControllerProvider.notifier);
  return controller.getDriverStatistics(
    params['driverId'] as String,
    startDate: params['startDate'] as DateTime?,
    endDate: params['endDate'] as DateTime?,
  );
});

/// Provider for trip search
final tripSearchProvider = FutureProvider.family<List<TripModel>, String>((ref, query) async {
  final controller = ref.read(tripControllerProvider.notifier);
  return controller.searchTrips(query);
});

/// Provider for trips by date range
final tripsByDateRangeProvider = FutureProvider.family<List<TripModel>, Map<String, DateTime>>((ref, dateRange) async {
  final repository = ref.read(tripRepositoryProvider);
  return repository.getTripsByDateRange(dateRange['startDate']!, dateRange['endDate']!);
});

/// Provider for trips by status
final tripsByStatusProvider = FutureProvider.family<List<TripModel>, TripStatus>((ref, status) async {
  final repository = ref.read(tripRepositoryProvider);
  return repository.getTripsByStatus(status);
});

/// Provider for trips by type
final tripsByTypeProvider = FutureProvider.family<List<TripModel>, TripType>((ref, type) async {
  final repository = ref.read(tripRepositoryProvider);
  return repository.getTripsByType(type);
});
