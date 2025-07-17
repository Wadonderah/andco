import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/maps_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/models/child_model.dart';
import '../../../shared/models/route_model.dart';

class LiveTrackingMap extends ConsumerStatefulWidget {
  final String childId;
  final String busId;

  const LiveTrackingMap({
    super.key,
    required this.childId,
    required this.busId,
  });

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap> {
  GoogleMapController? _mapController;
  StreamSubscription<BusModel?>? _busLocationSubscription;
  StreamSubscription<Position>? _locationSubscription;

  BusModel? _currentBus;
  ChildModel? _currentChild;
  RouteModel? _currentRoute;
  Position? _userLocation;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _isTracking = true;
  bool _isLoading = true;
  String? _errorMessage;

  // Real-time tracking data
  double? _busSpeed;
  String? _estimatedArrival;
  int? _studentsOnBoard;

  // Enhanced tracking features
  Timer? _etaUpdateTimer;
  double? _distanceToPickup;
  double? _distanceToSchool;
  final bool _isChildPickedUp = false;
  final List<Position> _routePoints = [];
  String? _trafficCondition;
  DateTime? _lastLocationUpdate;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _busLocationSubscription?.cancel();
    _locationSubscription?.cancel();
    _etaUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get user's current location
      await _getUserLocation();

      // Load child and route data
      await _loadChildData();
      await _loadRouteData();

      setState(() {
        _isLoading = false;
      });

      await FirebaseService.instance.logEvent('parent_map_tracking_started', {
        'child_id': widget.childId,
        'bus_id': widget.busId,
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize tracking: ${e.toString()}';
      });

      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Parent map tracking initialization failed');
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final mapsService = MapsService.instance;
      _userLocation = await mapsService.getCurrentLocation();
    } catch (e) {
      debugPrint('Failed to get user location: $e');
      // Continue without user location
    }
  }

  Future<void> _loadChildData() async {
    try {
      final childRepo = ref.read(childRepositoryProvider);
      _currentChild = await childRepo.getById(widget.childId);
    } catch (e) {
      debugPrint('Failed to load child data: $e');
    }
  }

  Future<void> _loadRouteData() async {
    try {
      if (_currentBus?.metadata?['routeId'] != null) {
        final routeRepo = ref.read(routeRepositoryProvider);
        _currentRoute =
            await routeRepo.getById(_currentBus!.metadata!['routeId']);
      }
    } catch (e) {
      debugPrint('Failed to load route data: $e');
    }
  }

  void _updateMapWithBusLocation(BusModel bus) {
    if (!bus.hasLocation) return;

    final busPosition = LatLng(bus.currentLatitude!, bus.currentLongitude!);

    // Update bus marker
    _markers.removeWhere((marker) => marker.markerId.value == 'bus');
    _markers.add(
      Marker(
        markerId: const MarkerId('bus'),
        position: busPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: bus.busNumber,
          snippet:
              'Driver: ${_currentBus?.metadata?['driverName'] ?? 'Unknown'}',
        ),
      ),
    );

    // Add user location marker if available
    if (_userLocation != null) {
      _markers.removeWhere((marker) => marker.markerId.value == 'user');
      _markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(_userLocation!.latitude, _userLocation!.longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );
    }

    // Center map on bus location
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(busPosition),
      );
    }

    setState(() {});
  }

  void _calculateBusMetrics(BusModel bus) {
    // Calculate speed (mock for now, would need historical data)
    _busSpeed = 25.0; // km/h

    // Calculate ETA (mock for now, would need route data)
    _estimatedArrival = '8 minutes';

    // Get students on board (from bus metadata)
    _studentsOnBoard = bus.metadata?['studentsOnBoard'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time bus location updates
    if (_isTracking) {
      ref.listen<AsyncValue<BusModel?>>(
        busLocationStreamProvider(widget.busId),
        (previous, next) {
          next.when(
            data: (bus) {
              if (bus != null && mounted) {
                setState(() {
                  _currentBus = bus;
                });
                _updateMapWithBusLocation(bus);
                _calculateBusMetrics(bus);
              }
            },
            loading: () {
              // Handle loading state
            },
            error: (error, stackTrace) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Failed to track bus: ${error.toString()}';
                });
              }
            },
          );
        },
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Bus Tracking'),
          backgroundColor: AppColors.parentColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing tracking...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Bus Tracking'),
          backgroundColor: AppColors.parentColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeTracking,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleTracking,
            icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            onPressed: _refreshLocation,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Google Maps Widget
          Container(
            height: 300,
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              child: _currentBus?.hasLocation == true
                  ? GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentBus!.currentLatitude!,
                          _currentBus!.currentLongitude!,
                        ),
                        zoom: 15,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    )
                  : Container(
                      color: AppColors.surface,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            Text(
                              'Bus location unavailable',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            Text(
                              'Waiting for GPS signal...',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // Bus Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentBus?.busNumber ?? 'Unknown Bus',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Driver: ${_currentBus?.metadata?['driverName'] ?? 'Unknown'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: Text(
                        _currentBus?.status.toString() ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'ETA',
                        _estimatedArrival ?? 'Calculating...',
                        Icons.access_time,
                        AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Speed',
                        _busSpeed != null
                            ? '${_busSpeed!.toStringAsFixed(0)} km/h'
                            : 'Unknown',
                        Icons.speed,
                        AppColors.info,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Students',
                        '${_studentsOnBoard ?? 0}/${_currentBus?.capacity ?? 0}',
                        Icons.groups,
                        AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map Placeholder (In real implementation, this would be Google Maps)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(
                    color: AppColors.textHint.withValues(alpha: 0.3)),
              ),
              child: Stack(
                children: [
                  // Real-time GPS Map
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseService.instance.firestore
                        .collection('bus_locations')
                        .doc(widget.busId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          !snapshot.data!.exists) {
                        return _buildMapPlaceholder();
                      }

                      final busData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final latitude = busData['latitude'] as double?;
                      final longitude = busData['longitude'] as double?;
                      final lastUpdated = busData['lastUpdated'] as String?;
                      final speed = busData['speed'] as double?;
                      final heading = busData['heading'] as double?;

                      if (latitude == null || longitude == null) {
                        return _buildMapPlaceholder();
                      }

                      return _buildRealTimeMap(
                        latitude: latitude,
                        longitude: longitude,
                        lastUpdated: lastUpdated,
                        speed: speed,
                        heading: heading,
                      );
                    },
                  ),

                  // Mock bus location indicator
                  Positioned(
                    top: 100,
                    left: 150,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  // Mock route line
                  Positioned(
                    top: 120,
                    left: 50,
                    child: Container(
                      width: 200,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current Location Info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Text(
                      'Current Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  _currentBus?.hasLocation == true
                      ? 'Lat: ${_currentBus!.currentLatitude!.toStringAsFixed(4)}, Lng: ${_currentBus!.currentLongitude!.toStringAsFixed(4)}'
                      : 'Location unavailable',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Row(
                  children: [
                    const Icon(
                      Icons.flag,
                      color: AppColors.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Next Stop: ${_currentRoute?.stops.isNotEmpty == true ? _currentRoute!.stops.first.name : 'Unknown'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnBus,
        backgroundColor: AppColors.parentColor,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
    });

    if (_isTracking) {
      FirebaseService.instance.logEvent('parent_tracking_resumed', {
        'child_id': widget.childId,
        'bus_id': widget.busId,
      });
    } else {
      FirebaseService.instance.logEvent('parent_tracking_paused', {
        'child_id': widget.childId,
        'bus_id': widget.busId,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isTracking ? 'Tracking enabled' : 'Tracking paused'),
        backgroundColor: _isTracking ? AppColors.success : AppColors.warning,
      ),
    );
  }

  Future<void> _refreshLocation() async {
    try {
      // Refresh user location
      await _getUserLocation();

      // Force refresh bus location
      if (_currentBus != null) {
        _updateMapWithBusLocation(_currentBus!);
      }

      // Refresh route data
      await _loadRouteData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location refreshed'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      await FirebaseService.instance.logEvent('parent_location_refreshed', {
        'child_id': widget.childId,
        'bus_id': widget.busId,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh location: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Calculate real-time ETA based on current location, traffic, and route
  Future<void> _calculateETA() async {
    if (_currentBus?.hasLocation != true ||
        _currentChild?.hasPickupStop != true) {
      return;
    }

    try {
      // Get pickup stop location from route data
      final pickupStop = _currentRoute?.stops.firstWhere(
        (stop) => stop.id == _currentChild!.pickupStopId,
        orElse: () => throw Exception('Pickup stop not found'),
      );

      if (pickupStop == null) return;

      final busPosition = Position(
        latitude: _currentBus!.currentLatitude!,
        longitude: _currentBus!.currentLongitude!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      // Calculate distance to pickup location
      _distanceToPickup = Geolocator.distanceBetween(
        busPosition.latitude,
        busPosition.longitude,
        pickupStop.latitude,
        pickupStop.longitude,
      );

      // Calculate ETA based on current speed and traffic conditions
      final currentSpeed = _busSpeed ?? 30.0; // Default 30 km/h
      final trafficMultiplier = _getTrafficMultiplier();
      final adjustedSpeed = currentSpeed * trafficMultiplier;

      if (adjustedSpeed > 0) {
        final etaHours = (_distanceToPickup! / 1000) / adjustedSpeed;
        final etaMinutes = (etaHours * 60).round();

        setState(() {
          _estimatedArrival =
              etaMinutes > 0 ? '$etaMinutes min' : 'Arriving now';
        });

        // Send notification when bus is close (within 5 minutes)
        if (etaMinutes <= 5 && etaMinutes > 0) {
          _sendETANotification(etaMinutes);
        }
      }

      // Update last location update time
      _lastLocationUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error calculating ETA: $e');
    }
  }

  /// Get traffic condition multiplier (1.0 = normal, 0.5 = heavy traffic)
  double _getTrafficMultiplier() {
    switch (_trafficCondition) {
      case 'heavy':
        return 0.5;
      case 'moderate':
        return 0.7;
      case 'light':
        return 0.9;
      default:
        return 0.8; // Default moderate traffic
    }
  }

  /// Send ETA notification to parent
  Future<void> _sendETANotification(int etaMinutes) async {
    if (_currentChild == null) return;

    try {
      // This would integrate with the NotificationService
      debugPrint(
          'Sending ETA notification: Bus arriving in $etaMinutes minutes');

      // In a real implementation, you would call:
      // await NotificationService.instance.sendNotificationToUser(
      //   userId: _currentChild!.parentId,
      //   title: 'Bus Arriving Soon',
      //   message: 'Your child\'s bus will arrive in $etaMinutes minutes',
      //   type: 'eta',
      //   childName: _currentChild!.name,
      //   location: 'Pickup Location',
      // );
    } catch (e) {
      debugPrint('Error sending ETA notification: $e');
    }
  }

  /// Update route with optimized path
  Future<void> _updateOptimizedRoute() async {
    if (_currentBus?.hasLocation != true ||
        _currentChild?.hasPickupStop != true) {
      return;
    }

    try {
      // Get pickup stop location from route data
      final pickupStop = _currentRoute?.stops.firstWhere(
        (stop) => stop.id == _currentChild!.pickupStopId,
        orElse: () => throw Exception('Pickup stop not found'),
      );

      if (pickupStop == null) return;

      final busLocation = LatLng(
        _currentBus!.currentLatitude!,
        _currentBus!.currentLongitude!,
      );

      final childLocation = LatLng(
        pickupStop.latitude,
        pickupStop.longitude,
      );

      // Get directions from Maps Service
      final route = await MapsService.instance.getDirections(
        origin: busLocation,
        destination: childLocation,
        waypoints: [], // Add any waypoints if needed
      );

      if (route != null) {
        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('optimized_route'),
              points: route.points,
              color: AppColors.primary,
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error updating optimized route: $e');
    }
  }

  /// Send pickup notification to parent
  Future<void> _sendPickupNotification() async {
    if (_currentChild == null) return;

    try {
      // This would integrate with the NotificationService
      debugPrint('Sending pickup notification for ${_currentChild!.name}');

      // In a real implementation, you would call:
      // await NotificationService.instance.sendNotificationToUser(
      //   userId: _currentChild!.parentId,
      //   title: 'Child Picked Up',
      //   message: '${_currentChild!.name} has been picked up by the bus',
      //   type: 'pickup',
      //   childName: _currentChild!.name,
      //   location: 'Pickup Location',
      // );
    } catch (e) {
      debugPrint('Error sending pickup notification: $e');
    }
  }

  void _centerOnBus() {
    if (_currentBus?.hasLocation == true && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            _currentBus!.currentLatitude!,
            _currentBus!.currentLongitude!,
          ),
        ),
      );
    }
  }

  Widget _buildInfoItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Build map placeholder when no location data is available
  Widget _buildMapPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Live GPS Map',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Waiting for bus location data...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  /// Build real-time map with bus location
  Widget _buildRealTimeMap({
    required double latitude,
    required double longitude,
    String? lastUpdated,
    double? speed,
    double? heading,
  }) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _animateToLocation(LatLng(latitude, longitude));
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 15.0,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('bus_location'),
              position: LatLng(latitude, longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
              infoWindow: InfoWindow(
                title: 'School Bus',
                snippet: 'Last updated: ${_formatLastUpdated(lastUpdated)}',
              ),
              rotation: heading ?? 0.0,
            ),
          },
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),

        // Real-time info overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _isLocationRecent(lastUpdated)
                              ? AppColors.success
                              : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLocationRecent(lastUpdated)
                            ? 'Live Tracking'
                            : 'Last Known Location',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (speed != null) ...[
                    Text('Speed: ${speed.toStringAsFixed(1)} km/h'),
                    const SizedBox(height: 4),
                  ],
                  Text('Updated: ${_formatLastUpdated(lastUpdated)}'),
                ],
              ),
            ),
          ),
        ),

        // Center on bus button
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: () => _animateToLocation(LatLng(latitude, longitude)),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// Animate map camera to specific location
  void _animateToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 15.0,
        ),
      ),
    );
  }

  /// Check if location data is recent (within last 5 minutes)
  bool _isLocationRecent(String? lastUpdated) {
    if (lastUpdated == null) return false;

    try {
      final updateTime = DateTime.parse(lastUpdated);
      final now = DateTime.now();
      final difference = now.difference(updateTime);
      return difference.inMinutes <= 5;
    } catch (e) {
      return false;
    }
  }

  /// Format last updated time for display
  String _formatLastUpdated(String? lastUpdated) {
    if (lastUpdated == null) return 'Unknown';

    try {
      final updateTime = DateTime.parse(lastUpdated);
      final now = DateTime.now();
      final difference = now.difference(updateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
