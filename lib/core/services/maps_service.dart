import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:http/http.dart' as http;

import 'firebase_service.dart';

/// Google Maps and location service
class MapsService {
  static MapsService? _instance;
  static MapsService get instance => _instance ??= MapsService._();

  MapsService._();

  // Google Maps API key (replace with your actual key)
  static const String _apiKey = 'your_google_maps_api_key_here';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Maps service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check location permissions
      await _checkLocationPermissions();

      _isInitialized = true;
      debugPrint('✅ Maps service initialized successfully');

      await FirebaseService.instance.logEvent('maps_service_initialized', {});
    } catch (e) {
      debugPrint('❌ Failed to initialize Maps service: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Maps service initialization failed');
      rethrow;
    }
  }

  /// Check and request location permissions
  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException('Location permissions are permanently denied');
    }
  }

  /// Get current location
  Future<Position> getCurrentLocation() async {
    try {
      await _checkLocationPermissions();

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await FirebaseService.instance.logEvent('location_obtained', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      });

      return position;
    } catch (e) {
      debugPrint('❌ Failed to get current location: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Get current location failed');
      rethrow;
    }
  }

  /// Get location stream for real-time tracking
  Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Geocode address to coordinates
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Geocoding failed: $e');
      await FirebaseService.instance
          .logError(e, StackTrace.current, reason: 'Geocoding failed');
      return null;
    }
  }

  /// Reverse geocode coordinates to address
  Future<String?> reverseGeocode(LatLng coordinates) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return _formatAddress(placemark);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Reverse geocoding failed: $e');
      await FirebaseService.instance
          .logError(e, StackTrace.current, reason: 'Reverse geocoding failed');
      return null;
    }
  }

  /// Get directions between two points
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    TravelMode travelMode = TravelMode.driving,
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) async {
    try {
      final url = _buildDirectionsUrl(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        travelMode: travelMode,
        avoidTolls: avoidTolls,
        avoidHighways: avoidHighways,
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return DirectionsResult.fromMap(data['routes'][0]);
        } else {
          throw MapsException('No routes found: ${data['status']}');
        }
      } else {
        throw MapsException('Directions API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Get directions failed: $e');
      await FirebaseService.instance
          .logError(e, StackTrace.current, reason: 'Get directions failed');
      return null;
    }
  }

  /// Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Calculate bearing between two points
  double calculateBearing(LatLng point1, LatLng point2) {
    return Geolocator.bearingBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Get nearby places
  Future<List<PlaceResult>> getNearbyPlaces({
    required LatLng location,
    required String type, // e.g., 'school', 'hospital', 'gas_station'
    int radius = 5000, // meters
  }) async {
    try {
      final url = '$_baseUrl/place/nearbysearch/json'
          '?location=${location.latitude},${location.longitude}'
          '&radius=$radius'
          '&type=$type'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return (data['results'] as List)
              .map((place) => PlaceResult.fromMap(place))
              .toList();
        } else {
          throw MapsException('Places API error: ${data['status']}');
        }
      } else {
        throw MapsException('Places API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Get nearby places failed: $e');
      await FirebaseService.instance
          .logError(e, StackTrace.current, reason: 'Get nearby places failed');
      return [];
    }
  }

  /// Get traffic information for a route
  Future<TrafficInfo?> getTrafficInfo({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url = '$_baseUrl/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&departure_time=now'
          '&traffic_model=best_guess'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          return TrafficInfo(
            duration: leg['duration']['text'],
            durationInTraffic:
                leg['duration_in_traffic']?['text'] ?? leg['duration']['text'],
            distance: leg['distance']['text'],
            trafficCondition: _getTrafficCondition(
              leg['duration']['value'],
              leg['duration_in_traffic']?['value'] ?? leg['duration']['value'],
            ),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get traffic info failed: $e');
      return null;
    }
  }

  /// Determine traffic condition based on duration comparison
  TrafficCondition _getTrafficCondition(
      int normalDuration, int trafficDuration) {
    final ratio = trafficDuration / normalDuration;

    if (ratio <= 1.1) return TrafficCondition.light;
    if (ratio <= 1.3) return TrafficCondition.moderate;
    if (ratio <= 1.5) return TrafficCondition.heavy;
    return TrafficCondition.severe;
  }

  /// Build directions URL
  String _buildDirectionsUrl({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    TravelMode travelMode = TravelMode.driving,
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) {
    var url = '$_baseUrl/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=${travelMode.name}'
        '&key=$_apiKey';

    if (waypoints != null && waypoints.isNotEmpty) {
      final waypointStr =
          waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');
      url += '&waypoints=$waypointStr';
    }

    if (avoidTolls) url += '&avoid=tolls';
    if (avoidHighways) url += '&avoid=highways';

    return url;
  }

  /// Format address from placemark
  String _formatAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.name != null) parts.add(placemark.name!);
    if (placemark.street != null) parts.add(placemark.street!);
    if (placemark.locality != null) parts.add(placemark.locality!);
    if (placemark.administrativeArea != null)
      parts.add(placemark.administrativeArea!);
    if (placemark.country != null) parts.add(placemark.country!);

    return parts.join(', ');
  }
}

/// Travel mode enum
enum TravelMode {
  driving,
  walking,
  bicycling,
  transit,
}

/// Directions result model
class DirectionsResult {
  final String polyline;
  final List<LatLng> points;
  final String distance;
  final String duration;
  final LatLngBounds bounds;

  DirectionsResult({
    required this.polyline,
    required this.points,
    required this.distance,
    required this.duration,
    required this.bounds,
  });

  factory DirectionsResult.fromMap(Map<String, dynamic> map) {
    final leg = map['legs'][0];
    final polylinePoints = decodePolyline(map['overview_polyline']['points']);

    return DirectionsResult(
      polyline: map['overview_polyline']['points'],
      points: polylinePoints
          .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
          .toList(),
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
      bounds: LatLngBounds(
        southwest: LatLng(
          map['bounds']['southwest']['lat'].toDouble(),
          map['bounds']['southwest']['lng'].toDouble(),
        ),
        northeast: LatLng(
          map['bounds']['northeast']['lat'].toDouble(),
          map['bounds']['northeast']['lng'].toDouble(),
        ),
      ),
    );
  }
}

/// Place result model
class PlaceResult {
  final String placeId;
  final String name;
  final LatLng location;
  final double? rating;
  final String? vicinity;
  final List<String> types;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.location,
    this.rating,
    this.vicinity,
    required this.types,
  });

  factory PlaceResult.fromMap(Map<String, dynamic> map) {
    return PlaceResult(
      placeId: map['place_id'],
      name: map['name'],
      location: LatLng(
        map['geometry']['location']['lat'].toDouble(),
        map['geometry']['location']['lng'].toDouble(),
      ),
      rating: map['rating']?.toDouble(),
      vicinity: map['vicinity'],
      types: List<String>.from(map['types']),
    );
  }
}

/// Traffic information model
class TrafficInfo {
  final String duration;
  final String durationInTraffic;
  final String distance;
  final TrafficCondition trafficCondition;

  TrafficInfo({
    required this.duration,
    required this.durationInTraffic,
    required this.distance,
    required this.trafficCondition,
  });
}

/// Traffic condition enum
enum TrafficCondition {
  light,
  moderate,
  heavy,
  severe,
}

extension TrafficConditionExtension on TrafficCondition {
  String get displayName {
    switch (this) {
      case TrafficCondition.light:
        return 'Light Traffic';
      case TrafficCondition.moderate:
        return 'Moderate Traffic';
      case TrafficCondition.heavy:
        return 'Heavy Traffic';
      case TrafficCondition.severe:
        return 'Severe Traffic';
    }
  }
}

/// Custom exceptions
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}

class MapsException implements Exception {
  final String message;
  MapsException(this.message);

  @override
  String toString() => 'MapsException: $message';
}
