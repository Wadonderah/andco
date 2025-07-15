import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'base_ai_service.dart';

/// Smart Route Optimization Agent using Google Maps API and weather data
class RouteOptimizationService extends BaseAIService
    with RateLimitMixin, CacheMixin<RouteOptimizationResult> {
  static const String _googleMapsApiKey =
      'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with actual key
  static const String _weatherApiKey =
      'YOUR_OPENWEATHER_API_KEY'; // Replace with actual key

  AIServiceStatus _status = AIServiceStatus.uninitialized;
  bool _isEnabled = true;
  bool _isInitialized = false;
  RouteOptimizationConfig _config = const RouteOptimizationConfig();

  final Map<String, RouteOptimizationResult> _routeCache = {};
  final Map<String, WeatherData> _weatherCache = {};

  @override
  String get serviceName => 'Smart Route Optimization Agent';

  @override
  bool get isEnabled => _isEnabled;

  @override
  bool get isInitialized => _isInitialized;

  @override
  AIServiceStatus get status => _status;

  @override
  Future<void> initialize({Map<String, dynamic>? config}) async {
    try {
      _status = AIServiceStatus.initializing;

      if (config != null) {
        _config = RouteOptimizationConfig.fromJson(config);
      }

      // Set up rate limiting (Google Maps free tier: 2,500 requests/day)
      setRateLimitConfig(const RateLimitConfig(
        maxRequestsPerMinute: 4,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 2500,
      ));

      // Set up caching
      setCacheConfig(const CacheConfig(
        enabled: true,
        cacheDuration: Duration(minutes: 30),
        maxCacheSize: 50,
        persistCache: true,
      ));

      _isInitialized = true;
      _status = AIServiceStatus.ready;

      debugPrint('✅ Route Optimization Service initialized');
    } catch (e) {
      _status = AIServiceStatus.error;
      debugPrint('❌ Failed to initialize Route Optimization Service: $e');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    _routeCache.clear();
    _weatherCache.clear();
    clearCache();
    _isInitialized = false;
    _status = AIServiceStatus.uninitialized;
  }

  @override
  Future<void> enable() async {
    _isEnabled = true;
    if (_isInitialized) {
      _status = AIServiceStatus.ready;
    }
  }

  @override
  Future<void> disable() async {
    _isEnabled = false;
    _status = AIServiceStatus.disabled;
  }

  @override
  Future<AIServiceHealth> getHealthStatus() async {
    final isHealthy =
        _isEnabled && _isInitialized && _status != AIServiceStatus.error;

    return AIServiceHealth(
      serviceName: serviceName,
      status: _status,
      isHealthy: isHealthy,
      lastCheck: DateTime.now(),
      metrics: {
        'cachedRoutes': _routeCache.length,
        'cachedWeatherData': _weatherCache.length,
        'isEnabled': _isEnabled,
        'isInitialized': _isInitialized,
      },
    );
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return _config.toJson();
  }

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    _config = RouteOptimizationConfig.fromJson(config);
  }

  @override
  Future<void> reset() async {
    _routeCache.clear();
    _weatherCache.clear();
    clearCache();
    _status = AIServiceStatus.ready;
  }

  /// Optimize route for a list of student pickup/dropoff locations
  Future<AIServiceResult<RouteOptimizationResult>> optimizeRoute({
    required Position startLocation,
    required Position endLocation,
    required List<StudentLocation> studentLocations,
    RouteOptimizationOptions? options,
  }) async {
    try {
      if (!_isEnabled || !_isInitialized) {
        return AIServiceResult.failure('Service not available');
      }

      _status = AIServiceStatus.running;

      final cacheKey =
          _generateCacheKey(startLocation, endLocation, studentLocations);

      // Check cache first
      final cached = getCached(cacheKey);
      if (cached != null) {
        debugPrint('📦 Using cached route optimization result');
        return AIServiceResult.success(cached);
      }

      // Check rate limits
      if (!await checkRateLimit('route_optimization')) {
        return AIServiceResult.failure('Rate limit exceeded');
      }

      // Get weather data for route optimization
      final weatherData = await _getWeatherData(startLocation);

      // Calculate optimal route using multiple algorithms
      final optimizationResult = await _calculateOptimalRoute(
        startLocation: startLocation,
        endLocation: endLocation,
        studentLocations: studentLocations,
        weatherData: weatherData,
        options: options ?? const RouteOptimizationOptions(),
      );

      // Cache the result
      setCached(cacheKey, optimizationResult);

      _status = AIServiceStatus.ready;

      return AIServiceResult.success(optimizationResult, metadata: {
        'cached': false,
        'weatherConsidered': weatherData != null,
        'algorithmsUsed': optimizationResult.algorithmsUsed,
      });
    } catch (e) {
      _status = AIServiceStatus.error;
      debugPrint('❌ Route optimization failed: $e');
      return AIServiceResult.failure(e.toString());
    }
  }

  /// Get weather data for route planning
  Future<WeatherData?> _getWeatherData(Position location) async {
    try {
      final cacheKey = '${location.latitude}_${location.longitude}';

      // Check weather cache
      final cached = _weatherCache[cacheKey];
      if (cached != null &&
          DateTime.now().difference(cached.timestamp) <
              const Duration(hours: 1)) {
        return cached;
      }

      // Check rate limits for weather API
      if (!await checkRateLimit('weather_api')) {
        debugPrint('⚠️ Weather API rate limit exceeded');
        return null;
      }

      final url = 'https://api.openweathermap.org/data/2.5/weather'
          '?lat=${location.latitude}'
          '&lon=${location.longitude}'
          '&appid=$_weatherApiKey'
          '&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherData = WeatherData.fromJson(data);

        // Cache weather data
        _weatherCache[cacheKey] = weatherData;

        return weatherData;
      } else {
        debugPrint('⚠️ Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get weather data: $e');
      return null;
    }
  }

  /// Calculate optimal route using multiple algorithms
  Future<RouteOptimizationResult> _calculateOptimalRoute({
    required Position startLocation,
    required Position endLocation,
    required List<StudentLocation> studentLocations,
    WeatherData? weatherData,
    required RouteOptimizationOptions options,
  }) async {
    final algorithms = <String>[];

    // Algorithm 1: Nearest Neighbor (fast, good for small datasets)
    final nearestNeighborRoute = await _nearestNeighborAlgorithm(
        startLocation, endLocation, studentLocations);
    algorithms.add('Nearest Neighbor');

    // Algorithm 2: Genetic Algorithm (better optimization for larger datasets)
    RouteResult? geneticRoute;
    if (studentLocations.length > 5) {
      geneticRoute =
          await _geneticAlgorithm(startLocation, endLocation, studentLocations);
      algorithms.add('Genetic Algorithm');
    }

    // Algorithm 3: Weather-adjusted routing
    RouteResult? weatherAdjustedRoute;
    if (weatherData != null && _shouldAdjustForWeather(weatherData)) {
      weatherAdjustedRoute = await _weatherAdjustedRouting(
          startLocation, endLocation, studentLocations, weatherData);
      algorithms.add('Weather-Adjusted');
    }

    // Select best route
    final routes = [nearestNeighborRoute, geneticRoute, weatherAdjustedRoute]
        .where((route) => route != null)
        .cast<RouteResult>()
        .toList();

    final bestRoute = _selectBestRoute(routes, options);

    return RouteOptimizationResult(
      optimizedRoute: bestRoute,
      alternativeRoutes: routes.where((r) => r != bestRoute).toList(),
      optimizationMetrics: RouteOptimizationMetrics(
        totalDistance: bestRoute.totalDistance,
        estimatedDuration: bestRoute.estimatedDuration,
        fuelEfficiency: _calculateFuelEfficiency(bestRoute, weatherData),
        safetyScore: _calculateSafetyScore(bestRoute, weatherData),
        weatherImpact:
            weatherData != null ? _calculateWeatherImpact(weatherData) : 0.0,
      ),
      weatherData: weatherData,
      algorithmsUsed: algorithms,
      timestamp: DateTime.now(),
    );
  }

  /// Nearest Neighbor algorithm for route optimization
  Future<RouteResult> _nearestNeighborAlgorithm(
    Position start,
    Position end,
    List<StudentLocation> students,
  ) async {
    final route = <Position>[start];
    final remaining = List<StudentLocation>.from(students);
    Position current = start;
    double totalDistance = 0.0;

    while (remaining.isNotEmpty) {
      // Find nearest student location
      StudentLocation? nearest;
      double minDistance = double.infinity;

      for (final student in remaining) {
        final distance = Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          student.location.latitude,
          student.location.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = student;
        }
      }

      if (nearest != null) {
        route.add(nearest.location);
        totalDistance += minDistance;
        current = nearest.location;
        remaining.remove(nearest);
      }
    }

    // Add final destination
    route.add(end);
    totalDistance += Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      end.latitude,
      end.longitude,
    );

    return RouteResult(
      waypoints: route,
      totalDistance: totalDistance,
      estimatedDuration:
          Duration(minutes: (totalDistance / 500).round()), // Rough estimate
      algorithm: 'Nearest Neighbor',
    );
  }

  /// Simplified genetic algorithm for route optimization
  Future<RouteResult> _geneticAlgorithm(
    Position start,
    Position end,
    List<StudentLocation> students,
  ) async {
    // Simplified genetic algorithm implementation
    // In a real implementation, this would be more sophisticated

    const populationSize = 20;
    const generations = 50;
    final random = Random();

    // Generate initial population
    var population = <List<StudentLocation>>[];
    for (int i = 0; i < populationSize; i++) {
      final individual = List<StudentLocation>.from(students)..shuffle(random);
      population.add(individual);
    }

    // Evolution loop
    for (int gen = 0; gen < generations; gen++) {
      // Evaluate fitness (shorter distance = better fitness)
      final fitness = population.map((individual) {
        return 1.0 / (_calculateRouteDistance(start, end, individual) + 1);
      }).toList();

      // Selection and crossover (simplified)
      final newPopulation = <List<StudentLocation>>[];
      for (int i = 0; i < populationSize; i++) {
        final parent1 = _selectParent(population, fitness, random);
        final parent2 = _selectParent(population, fitness, random);
        final child = _crossover(parent1, parent2, random);
        _mutate(child, random);
        newPopulation.add(child);
      }

      population = newPopulation;
    }

    // Select best individual
    final bestIndividual = population.reduce((a, b) {
      return _calculateRouteDistance(start, end, a) <
              _calculateRouteDistance(start, end, b)
          ? a
          : b;
    });

    final route = [start, ...bestIndividual.map((s) => s.location), end];
    final totalDistance = _calculateRouteDistance(start, end, bestIndividual);

    return RouteResult(
      waypoints: route,
      totalDistance: totalDistance,
      estimatedDuration: Duration(minutes: (totalDistance / 500).round()),
      algorithm: 'Genetic Algorithm',
    );
  }

  /// Weather-adjusted routing
  Future<RouteResult> _weatherAdjustedRouting(
    Position start,
    Position end,
    List<StudentLocation> students,
    WeatherData weather,
  ) async {
    // Start with nearest neighbor and adjust for weather
    final baseRoute = await _nearestNeighborAlgorithm(start, end, students);

    // Apply weather adjustments
    final adjustmentFactor = _getWeatherAdjustmentFactor(weather);
    final adjustedDuration = Duration(
      milliseconds:
          (baseRoute.estimatedDuration.inMilliseconds * adjustmentFactor)
              .round(),
    );

    return RouteResult(
      waypoints: baseRoute.waypoints,
      totalDistance: baseRoute.totalDistance,
      estimatedDuration: adjustedDuration,
      algorithm: 'Weather-Adjusted',
      weatherAdjustments: {
        'factor': adjustmentFactor,
        'conditions': weather.condition,
        'visibility': weather.visibility,
        'windSpeed': weather.windSpeed,
      },
    );
  }

  // Helper methods for genetic algorithm
  List<StudentLocation> _selectParent(
    List<List<StudentLocation>> population,
    List<double> fitness,
    Random random,
  ) {
    final totalFitness = fitness.reduce((a, b) => a + b);
    final threshold = random.nextDouble() * totalFitness;
    double sum = 0.0;

    for (int i = 0; i < population.length; i++) {
      sum += fitness[i];
      if (sum >= threshold) {
        return population[i];
      }
    }

    return population.last;
  }

  List<StudentLocation> _crossover(
    List<StudentLocation> parent1,
    List<StudentLocation> parent2,
    Random random,
  ) {
    final crossoverPoint = random.nextInt(parent1.length);
    final child = <StudentLocation>[];

    // Add first part from parent1
    child.addAll(parent1.take(crossoverPoint));

    // Add remaining from parent2 (avoiding duplicates)
    for (final student in parent2) {
      if (!child.contains(student)) {
        child.add(student);
      }
    }

    return child;
  }

  void _mutate(List<StudentLocation> individual, Random random) {
    if (individual.length < 2) return;

    final i = random.nextInt(individual.length);
    final j = random.nextInt(individual.length);

    // Swap two random positions
    final temp = individual[i];
    individual[i] = individual[j];
    individual[j] = temp;
  }

  double _calculateRouteDistance(
    Position start,
    Position end,
    List<StudentLocation> students,
  ) {
    double distance = 0.0;
    Position current = start;

    for (final student in students) {
      distance += Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        student.location.latitude,
        student.location.longitude,
      );
      current = student.location;
    }

    distance += Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      end.latitude,
      end.longitude,
    );

    return distance;
  }

  // Helper methods
  String _generateCacheKey(
    Position start,
    Position end,
    List<StudentLocation> students,
  ) {
    final studentIds = students.map((s) => s.studentId).join(',');
    return '${start.latitude}_${start.longitude}_${end.latitude}_${end.longitude}_$studentIds';
  }

  bool _shouldAdjustForWeather(WeatherData weather) {
    return weather.condition.toLowerCase().contains('rain') ||
        weather.condition.toLowerCase().contains('snow') ||
        weather.condition.toLowerCase().contains('fog') ||
        weather.windSpeed > 10.0 ||
        weather.visibility < 5000;
  }

  double _getWeatherAdjustmentFactor(WeatherData weather) {
    double factor = 1.0;

    // Adjust for precipitation
    if (weather.condition.toLowerCase().contains('rain')) {
      factor *= 1.2;
    } else if (weather.condition.toLowerCase().contains('snow')) {
      factor *= 1.5;
    }

    // Adjust for wind
    if (weather.windSpeed > 15.0) {
      factor *= 1.1;
    }

    // Adjust for visibility
    if (weather.visibility < 1000) {
      factor *= 1.3;
    } else if (weather.visibility < 5000) {
      factor *= 1.1;
    }

    return factor;
  }

  RouteResult _selectBestRoute(
      List<RouteResult> routes, RouteOptimizationOptions options) {
    if (routes.isEmpty) throw Exception('No routes available');
    if (routes.length == 1) return routes.first;

    // Score routes based on options
    RouteResult? bestRoute;
    double bestScore = double.negativeInfinity;

    for (final route in routes) {
      double score = 0.0;

      // Distance weight
      score += (1.0 / (route.totalDistance + 1)) * options.distanceWeight;

      // Duration weight
      score +=
          (1.0 / (route.estimatedDuration.inMinutes + 1)) * options.timeWeight;

      // Safety weight (placeholder - would need actual safety scoring)
      score += 0.8 * options.safetyWeight;

      if (score > bestScore) {
        bestScore = score;
        bestRoute = route;
      }
    }

    return bestRoute!;
  }

  double _calculateFuelEfficiency(RouteResult route, WeatherData? weather) {
    // Simplified fuel efficiency calculation
    double efficiency =
        100.0 - (route.totalDistance / 1000) * 8; // Base efficiency

    if (weather != null) {
      efficiency *= _getWeatherAdjustmentFactor(weather);
    }

    return efficiency.clamp(0.0, 100.0);
  }

  double _calculateSafetyScore(RouteResult route, WeatherData? weather) {
    // Simplified safety score calculation
    double score = 85.0; // Base safety score

    if (weather != null) {
      if (weather.condition.toLowerCase().contains('rain')) score -= 10;
      if (weather.condition.toLowerCase().contains('snow')) score -= 20;
      if (weather.windSpeed > 15.0) score -= 5;
      if (weather.visibility < 1000) score -= 15;
    }

    return score.clamp(0.0, 100.0);
  }

  double _calculateWeatherImpact(WeatherData weather) {
    double impact = 0.0;

    if (weather.condition.toLowerCase().contains('rain')) impact += 0.2;
    if (weather.condition.toLowerCase().contains('snow')) impact += 0.5;
    if (weather.windSpeed > 15.0) impact += 0.1;
    if (weather.visibility < 1000) impact += 0.3;

    return impact.clamp(0.0, 1.0);
  }
}

/// Configuration for Route Optimization Service
class RouteOptimizationConfig extends AIServiceConfig {
  final bool useWeatherData;
  final bool useTrafficData;
  final int maxStudentsPerRoute;
  final double maxRouteDistance;
  final Duration maxRouteDuration;

  const RouteOptimizationConfig({
    super.enabled = true,
    this.useWeatherData = true,
    this.useTrafficData = true,
    this.maxStudentsPerRoute = 50,
    this.maxRouteDistance = 100000, // 100km in meters
    this.maxRouteDuration = const Duration(hours: 2),
    super.rateLimitConfig,
    super.cacheConfig,
    super.customConfig = const {},
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'useWeatherData': useWeatherData,
      'useTrafficData': useTrafficData,
      'maxStudentsPerRoute': maxStudentsPerRoute,
      'maxRouteDistance': maxRouteDistance,
      'maxRouteDurationMs': maxRouteDuration.inMilliseconds,
      'rateLimitConfig': rateLimitConfig?.toJson(),
      'cacheConfig': cacheConfig?.toJson(),
      'customConfig': customConfig,
    };
  }

  factory RouteOptimizationConfig.fromJson(Map<String, dynamic> json) {
    return RouteOptimizationConfig(
      enabled: json['enabled'] ?? true,
      useWeatherData: json['useWeatherData'] ?? true,
      useTrafficData: json['useTrafficData'] ?? true,
      maxStudentsPerRoute: json['maxStudentsPerRoute'] ?? 50,
      maxRouteDistance: json['maxRouteDistance']?.toDouble() ?? 100000.0,
      maxRouteDuration:
          Duration(milliseconds: json['maxRouteDurationMs'] ?? 7200000),
      rateLimitConfig: json['rateLimitConfig'] != null
          ? RateLimitConfig.fromJson(json['rateLimitConfig'])
          : null,
      cacheConfig: json['cacheConfig'] != null
          ? CacheConfig.fromJson(json['cacheConfig'])
          : null,
      customConfig: Map<String, dynamic>.from(json['customConfig'] ?? {}),
    );
  }
}

/// Student location data
class StudentLocation {
  final String studentId;
  final Position location;
  final String address;
  final bool isPickup;
  final DateTime? scheduledTime;

  const StudentLocation({
    required this.studentId,
    required this.location,
    required this.address,
    this.isPickup = true,
    this.scheduledTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'address': address,
      'isPickup': isPickup,
      'scheduledTime': scheduledTime?.toIso8601String(),
    };
  }

  factory StudentLocation.fromJson(Map<String, dynamic> json) {
    return StudentLocation(
      studentId: json['studentId'] ?? '',
      location: Position(
        latitude: json['latitude']?.toDouble() ?? 0.0,
        longitude: json['longitude']?.toDouble() ?? 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      ),
      address: json['address'] ?? '',
      isPickup: json['isPickup'] ?? true,
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : null,
    );
  }
}

/// Weather data for route optimization
class WeatherData {
  final String condition;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final double windDirection;
  final double visibility;
  final double precipitation;
  final DateTime timestamp;

  const WeatherData({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.visibility,
    required this.precipitation,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'visibility': visibility,
      'precipitation': precipitation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      condition: json['weather']?[0]?['description'] ?? 'clear',
      temperature: json['main']?['temp']?.toDouble() ?? 20.0,
      humidity: json['main']?['humidity']?.toDouble() ?? 50.0,
      windSpeed: json['wind']?['speed']?.toDouble() ?? 0.0,
      windDirection: json['wind']?['deg']?.toDouble() ?? 0.0,
      visibility: json['visibility']?.toDouble() ?? 10000.0,
      precipitation: json['rain']?['1h']?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    );
  }
}

/// Route optimization options
class RouteOptimizationOptions {
  final double distanceWeight;
  final double timeWeight;
  final double safetyWeight;
  final double fuelWeight;
  final bool avoidTolls;
  final bool avoidHighways;

  const RouteOptimizationOptions({
    this.distanceWeight = 0.3,
    this.timeWeight = 0.4,
    this.safetyWeight = 0.2,
    this.fuelWeight = 0.1,
    this.avoidTolls = false,
    this.avoidHighways = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'distanceWeight': distanceWeight,
      'timeWeight': timeWeight,
      'safetyWeight': safetyWeight,
      'fuelWeight': fuelWeight,
      'avoidTolls': avoidTolls,
      'avoidHighways': avoidHighways,
    };
  }

  factory RouteOptimizationOptions.fromJson(Map<String, dynamic> json) {
    return RouteOptimizationOptions(
      distanceWeight: json['distanceWeight']?.toDouble() ?? 0.3,
      timeWeight: json['timeWeight']?.toDouble() ?? 0.4,
      safetyWeight: json['safetyWeight']?.toDouble() ?? 0.2,
      fuelWeight: json['fuelWeight']?.toDouble() ?? 0.1,
      avoidTolls: json['avoidTolls'] ?? false,
      avoidHighways: json['avoidHighways'] ?? false,
    );
  }
}

/// Route optimization result
class RouteOptimizationResult {
  final RouteResult optimizedRoute;
  final List<RouteResult> alternativeRoutes;
  final RouteOptimizationMetrics optimizationMetrics;
  final WeatherData? weatherData;
  final List<String> algorithmsUsed;
  final DateTime timestamp;

  const RouteOptimizationResult({
    required this.optimizedRoute,
    required this.alternativeRoutes,
    required this.optimizationMetrics,
    this.weatherData,
    required this.algorithmsUsed,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'optimizedRoute': optimizedRoute.toJson(),
      'alternativeRoutes': alternativeRoutes.map((r) => r.toJson()).toList(),
      'optimizationMetrics': optimizationMetrics.toJson(),
      'weatherData': weatherData?.toJson(),
      'algorithmsUsed': algorithmsUsed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Individual route result
class RouteResult {
  final List<Position> waypoints;
  final double totalDistance;
  final Duration estimatedDuration;
  final String algorithm;
  final Map<String, dynamic>? weatherAdjustments;

  const RouteResult({
    required this.waypoints,
    required this.totalDistance,
    required this.estimatedDuration,
    required this.algorithm,
    this.weatherAdjustments,
  });

  Map<String, dynamic> toJson() {
    return {
      'waypoints': waypoints
          .map((p) => {
                'latitude': p.latitude,
                'longitude': p.longitude,
              })
          .toList(),
      'totalDistance': totalDistance,
      'estimatedDurationMs': estimatedDuration.inMilliseconds,
      'algorithm': algorithm,
      'weatherAdjustments': weatherAdjustments,
    };
  }
}

/// Route optimization metrics
class RouteOptimizationMetrics {
  final double totalDistance;
  final Duration estimatedDuration;
  final double fuelEfficiency;
  final double safetyScore;
  final double weatherImpact;

  const RouteOptimizationMetrics({
    required this.totalDistance,
    required this.estimatedDuration,
    required this.fuelEfficiency,
    required this.safetyScore,
    required this.weatherImpact,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalDistance': totalDistance,
      'estimatedDurationMs': estimatedDuration.inMilliseconds,
      'fuelEfficiency': fuelEfficiency,
      'safetyScore': safetyScore,
      'weatherImpact': weatherImpact,
    };
  }
}
