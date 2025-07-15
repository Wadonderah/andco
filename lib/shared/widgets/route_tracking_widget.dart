import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/maps_service.dart';
import '../../core/theme/app_colors.dart';

/// Widget for real-time route tracking
class RouteTrackingWidget extends ConsumerStatefulWidget {
  final LatLng destination;
  final List<LatLng>? waypoints;
  final VoidCallback? onArrived;
  final Function(Position)? onLocationUpdate;
  final bool showTrafficInfo;

  const RouteTrackingWidget({
    super.key,
    required this.destination,
    this.waypoints,
    this.onArrived,
    this.onLocationUpdate,
    this.showTrafficInfo = true,
  });

  @override
  ConsumerState<RouteTrackingWidget> createState() => _RouteTrackingWidgetState();
}

class _RouteTrackingWidgetState extends ConsumerState<RouteTrackingWidget> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  
  Position? _currentPosition;
  DirectionsResult? _directions;
  TrafficInfo? _trafficInfo;
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  bool _isLoading = true;
  String? _errorMessage;
  
  static const double _arrivalThreshold = 50.0; // meters

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : widget.destination,
                zoom: 15,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Error message
            if (_errorMessage != null)
              Positioned(
                top: AppConstants.paddingMedium,
                left: AppConstants.paddingMedium,
                right: AppConstants.paddingMedium,
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Route info panel
            if (_directions != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildRouteInfoPanel(),
              ),

            // My location button
            Positioned(
              bottom: widget.showTrafficInfo && _trafficInfo != null ? 120 : 80,
              right: AppConstants.paddingMedium,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _centerOnCurrentLocation,
                child: const Icon(Icons.my_location, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusMedium),
          topRight: Radius.circular(AppConstants.radiusMedium),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Route summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.access_time,
                label: 'Duration',
                value: _directions!.duration,
              ),
              _buildInfoItem(
                icon: Icons.straighten,
                label: 'Distance',
                value: _directions!.distance,
              ),
              if (_currentPosition != null)
                _buildInfoItem(
                  icon: Icons.speed,
                  label: 'Speed',
                  value: '${(_currentPosition!.speed * 3.6).toStringAsFixed(0)} km/h',
                ),
            ],
          ),

          // Traffic info
          if (widget.showTrafficInfo && _trafficInfo != null) ...[
            const SizedBox(height: AppConstants.paddingSmall),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              decoration: BoxDecoration(
                color: _getTrafficColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(color: _getTrafficColor().withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_getTrafficIcon(), color: _getTrafficColor(), size: 20),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      '${_trafficInfo!.trafficCondition.displayName} - ${_trafficInfo!.durationInTraffic}',
                      style: TextStyle(
                        color: _getTrafficColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _initializeTracking() async {
    try {
      // Get current location
      _currentPosition = await MapsService.instance.getCurrentLocation();
      
      // Start location tracking
      _locationSubscription = MapsService.instance.getLocationStream().listen(
        _onLocationUpdate,
        onError: (error) {
          setState(() {
            _errorMessage = 'Location tracking error: $error';
          });
        },
      );

      // Get initial directions
      await _updateDirections();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize tracking: $e';
      });
    }
  }

  void _onLocationUpdate(Position position) {
    setState(() {
      _currentPosition = position;
    });

    widget.onLocationUpdate?.call(position);

    // Check if arrived at destination
    final distanceToDestination = MapsService.instance.calculateDistance(
      LatLng(position.latitude, position.longitude),
      widget.destination,
    );

    if (distanceToDestination <= _arrivalThreshold) {
      widget.onArrived?.call();
    }

    // Update directions periodically
    _updateDirections();
  }

  Future<void> _updateDirections() async {
    if (_currentPosition == null) return;

    try {
      final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      final directions = await MapsService.instance.getDirections(
        origin: origin,
        destination: widget.destination,
        waypoints: widget.waypoints,
      );

      if (directions != null) {
        setState(() {
          _directions = directions;
        });

        _updateMapElements();

        // Get traffic info if enabled
        if (widget.showTrafficInfo) {
          final trafficInfo = await MapsService.instance.getTrafficInfo(
            origin: origin,
            destination: widget.destination,
          );
          
          if (trafficInfo != null) {
            setState(() {
              _trafficInfo = trafficInfo;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to update directions: $e');
    }
  }

  void _updateMapElements() {
    if (_directions == null || _currentPosition == null) return;

    // Update markers
    _markers.clear();
    
    // Current location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Current Location'),
      ),
    );

    // Destination marker
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    );

    // Waypoint markers
    if (widget.waypoints != null) {
      for (int i = 0; i < widget.waypoints!.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('waypoint_$i'),
            position: widget.waypoints![i],
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
            infoWindow: InfoWindow(title: 'Waypoint ${i + 1}'),
          ),
        );
      }
    }

    // Update polyline
    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: _directions!.points,
        color: AppColors.primary,
        width: 5,
        patterns: [],
      ),
    );

    // Update camera to show route
    _fitCameraToBounds();
  }

  void _fitCameraToBounds() {
    if (_mapController == null || _directions == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(_directions!.bounds, 100),
    );
  }

  void _centerOnCurrentLocation() {
    if (_mapController == null || _currentPosition == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Color _getTrafficColor() {
    if (_trafficInfo == null) return AppColors.success;
    
    switch (_trafficInfo!.trafficCondition) {
      case TrafficCondition.light:
        return AppColors.success;
      case TrafficCondition.moderate:
        return AppColors.warning;
      case TrafficCondition.heavy:
        return Colors.orange;
      case TrafficCondition.severe:
        return AppColors.error;
    }
  }

  IconData _getTrafficIcon() {
    if (_trafficInfo == null) return Icons.traffic;
    
    switch (_trafficInfo!.trafficCondition) {
      case TrafficCondition.light:
        return Icons.traffic;
      case TrafficCondition.moderate:
        return Icons.warning;
      case TrafficCondition.heavy:
        return Icons.error_outline;
      case TrafficCondition.severe:
        return Icons.error;
    }
  }
}
