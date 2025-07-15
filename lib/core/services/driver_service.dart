import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive driver service for managing routes, students, and tracking
class DriverService {
  static DriverService? _instance;
  static DriverService get instance => _instance ??= DriverService._();
  
  DriverService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  StreamSubscription<Position>? _locationSubscription;
  Timer? _routeUpdateTimer;
  bool _isOnDuty = false;
  String? _currentRouteId;

  /// Initialize driver service
  Future<void> initialize() async {
    try {
      await _requestLocationPermissions();
      debugPrint('✅ Driver service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize driver service: $e');
      rethrow;
    }
  }

  /// Request location permissions
  Future<void> _requestLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
  }

  /// Start duty and begin location tracking
  Future<void> startDuty(String routeId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Driver not authenticated');

    try {
      _currentRouteId = routeId;
      _isOnDuty = true;

      // Update driver status in Firestore
      await _firestore.collection('drivers').doc(user.uid).update({
        'isOnDuty': true,
        'currentRouteId': routeId,
        'dutyStartTime': FieldValue.serverTimestamp(),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      // Start location tracking
      await _startLocationTracking();
      
      // Start route updates
      _startRouteUpdates();

      debugPrint('✅ Driver duty started for route: $routeId');
    } catch (e) {
      debugPrint('❌ Failed to start duty: $e');
      rethrow;
    }
  }

  /// End duty and stop tracking
  Future<void> endDuty() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Driver not authenticated');

    try {
      _isOnDuty = false;
      _currentRouteId = null;

      // Stop location tracking
      await _locationSubscription?.cancel();
      _routeUpdateTimer?.cancel();

      // Update driver status in Firestore
      await _firestore.collection('drivers').doc(user.uid).update({
        'isOnDuty': false,
        'currentRouteId': null,
        'dutyEndTime': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Driver duty ended');
    } catch (e) {
      debugPrint('❌ Failed to end duty: $e');
      rethrow;
    }
  }

  /// Start real-time location tracking
  Future<void> _startLocationTracking() async {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _updateDriverLocation(position);
      },
      onError: (error) {
        debugPrint('❌ Location tracking error: $error');
      },
    );
  }

  /// Update driver location in Firestore
  Future<void> _updateDriverLocation(Position position) async {
    final user = _auth.currentUser;
    if (user == null || !_isOnDuty) return;

    try {
      await _firestore.collection('drivers').doc(user.uid).update({
        'currentLatitude': position.latitude,
        'currentLongitude': position.longitude,
        'currentSpeed': position.speed,
        'currentHeading': position.heading,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'locationAccuracy': position.accuracy,
      });

      // Update bus location if assigned
      if (_currentRouteId != null) {
        final driverDoc = await _firestore.collection('drivers').doc(user.uid).get();
        final busId = driverDoc.data()?['assignedBusId'];
        
        if (busId != null) {
          await _firestore.collection('buses').doc(busId).update({
            'currentLatitude': position.latitude,
            'currentLongitude': position.longitude,
            'currentSpeed': position.speed,
            'lastLocationUpdate': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to update location: $e');
    }
  }

  /// Start periodic route updates
  void _startRouteUpdates() {
    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateRouteProgress();
    });
  }

  /// Update route progress and ETA calculations
  Future<void> _updateRouteProgress() async {
    if (!_isOnDuty || _currentRouteId == null) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final position = await Geolocator.getCurrentPosition();
      
      // Get current route data
      final routeDoc = await _firestore.collection('routes').doc(_currentRouteId).get();
      if (!routeDoc.exists) return;

      final routeData = routeDoc.data()!;
      final stops = List<Map<String, dynamic>>.from(routeData['stops'] ?? []);

      // Calculate progress and ETAs
      final progress = await _calculateRouteProgress(position, stops);
      
      // Update route progress in Firestore
      await _firestore.collection('routes').doc(_currentRouteId).update({
        'currentProgress': progress,
        'lastProgressUpdate': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      debugPrint('❌ Failed to update route progress: $e');
    }
  }

  /// Calculate route progress based on current location
  Future<Map<String, dynamic>> _calculateRouteProgress(
    Position currentPosition, 
    List<Map<String, dynamic>> stops,
  ) async {
    try {
      double totalDistance = 0;
      double completedDistance = 0;
      int nextStopIndex = 0;
      
      for (int i = 0; i < stops.length - 1; i++) {
        final stop = stops[i];
        final nextStop = stops[i + 1];
        
        final stopDistance = Geolocator.distanceBetween(
          stop['latitude'],
          stop['longitude'],
          nextStop['latitude'],
          nextStop['longitude'],
        );
        
        totalDistance += stopDistance;
        
        // Check if we've passed this stop
        final distanceToStop = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          stop['latitude'],
          stop['longitude'],
        );
        
        if (distanceToStop < 100) { // Within 100 meters of stop
          completedDistance += stopDistance;
          nextStopIndex = i + 1;
        }
      }
      
      final progressPercentage = totalDistance > 0 ? (completedDistance / totalDistance) * 100 : 0;
      
      return {
        'progressPercentage': progressPercentage,
        'nextStopIndex': nextStopIndex,
        'totalDistance': totalDistance,
        'completedDistance': completedDistance,
        'estimatedTimeRemaining': _calculateETA(currentPosition, stops, nextStopIndex),
      };
    } catch (e) {
      debugPrint('❌ Error calculating route progress: $e');
      return {
        'progressPercentage': 0.0,
        'nextStopIndex': 0,
        'totalDistance': 0.0,
        'completedDistance': 0.0,
        'estimatedTimeRemaining': 0,
      };
    }
  }

  /// Calculate ETA to complete remaining route
  int _calculateETA(Position currentPosition, List<Map<String, dynamic>> stops, int nextStopIndex) {
    try {
      if (nextStopIndex >= stops.length) return 0;
      
      double remainingDistance = 0;
      
      // Distance to next stop
      if (nextStopIndex < stops.length) {
        final nextStop = stops[nextStopIndex];
        remainingDistance += Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          nextStop['latitude'],
          nextStop['longitude'],
        );
      }
      
      // Distance between remaining stops
      for (int i = nextStopIndex; i < stops.length - 1; i++) {
        final stop = stops[i];
        final nextStop = stops[i + 1];
        
        remainingDistance += Geolocator.distanceBetween(
          stop['latitude'],
          stop['longitude'],
          nextStop['latitude'],
          nextStop['longitude'],
        );
      }
      
      // Assume average speed of 30 km/h in city traffic
      const averageSpeed = 30.0; // km/h
      final etaHours = (remainingDistance / 1000) / averageSpeed;
      return (etaHours * 60).round(); // Convert to minutes
      
    } catch (e) {
      debugPrint('❌ Error calculating ETA: $e');
      return 0;
    }
  }

  /// Get driver's assigned route
  Stream<Map<String, dynamic>?> getAssignedRouteStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('drivers')
        .doc(user.uid)
        .snapshots()
        .asyncMap((driverDoc) async {
      if (!driverDoc.exists) return null;
      
      final driverData = driverDoc.data()!;
      final routeId = driverData['assignedRouteId'] as String?;
      
      if (routeId == null) return null;
      
      final routeDoc = await _firestore.collection('routes').doc(routeId).get();
      if (!routeDoc.exists) return null;
      
      return {
        'id': routeId,
        ...routeDoc.data()!,
      };
    });
  }

  /// Get students for current route
  Stream<List<Map<String, dynamic>>> getRouteStudentsStream(String routeId) {
    return _firestore
        .collection('children')
        .where('routeId', isEqualTo: routeId)
        .where('isActive', isEqualTo: true)
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

  /// Mark student as picked up
  Future<void> markStudentPickedUp(String studentId, String stopId) async {
    try {
      await _firestore.collection('student_checkins').add({
        'studentId': studentId,
        'stopId': stopId,
        'driverId': _auth.currentUser?.uid,
        'routeId': _currentRouteId,
        'type': 'pickup',
        'timestamp': FieldValue.serverTimestamp(),
        'location': await _getCurrentLocation(),
      });

      // Update student status
      await _firestore.collection('children').doc(studentId).update({
        'lastPickupTime': FieldValue.serverTimestamp(),
        'isOnBus': true,
      });

      debugPrint('✅ Student $studentId marked as picked up');
    } catch (e) {
      debugPrint('❌ Failed to mark student as picked up: $e');
      rethrow;
    }
  }

  /// Mark student as dropped off
  Future<void> markStudentDroppedOff(String studentId, String stopId) async {
    try {
      await _firestore.collection('student_checkins').add({
        'studentId': studentId,
        'stopId': stopId,
        'driverId': _auth.currentUser?.uid,
        'routeId': _currentRouteId,
        'type': 'dropoff',
        'timestamp': FieldValue.serverTimestamp(),
        'location': await _getCurrentLocation(),
      });

      // Update student status
      await _firestore.collection('children').doc(studentId).update({
        'lastDropoffTime': FieldValue.serverTimestamp(),
        'isOnBus': false,
      });

      debugPrint('✅ Student $studentId marked as dropped off');
    } catch (e) {
      debugPrint('❌ Failed to mark student as dropped off: $e');
      rethrow;
    }
  }

  /// Get current location
  Future<Map<String, double>> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  /// Dispose resources
  void dispose() {
    _locationSubscription?.cancel();
    _routeUpdateTimer?.cancel();
  }
}
