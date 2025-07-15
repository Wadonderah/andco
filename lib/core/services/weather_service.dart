import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'firebase_service.dart';

/// Weather service using OpenWeather API
class WeatherService {
  static WeatherService? _instance;
  static WeatherService get instance => _instance ??= WeatherService._();

  WeatherService._();

  // OpenWeather API configuration
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = 'your_openweather_api_key_here';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize weather service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Test API key with a simple request
      await _testApiKey();
      
      _isInitialized = true;
      debugPrint('✅ Weather service initialized successfully');
      
      await FirebaseService.instance.logEvent('weather_service_initialized', {});
    } catch (e) {
      debugPrint('❌ Failed to initialize weather service: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Weather service initialization failed');
      rethrow;
    }
  }

  /// Test API key validity
  Future<void> _testApiKey() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/weather?q=London&appid=$_apiKey'),
    );

    if (response.statusCode == 401) {
      throw WeatherException('Invalid API key');
    } else if (response.statusCode != 200) {
      throw WeatherException('API test failed: ${response.statusCode}');
    }
  }

  /// Get current weather by coordinates
  Future<WeatherData?> getCurrentWeather({
    required double latitude,
    required double longitude,
    String units = 'metric',
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=$units',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherData.fromMap(data);
        
        await FirebaseService.instance.logEvent('weather_fetched', {
          'latitude': latitude,
          'longitude': longitude,
          'temperature': weather.temperature,
          'condition': weather.condition,
        });
        
        return weather;
      } else {
        throw WeatherException('Failed to fetch weather: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to get current weather: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Get current weather failed');
      return null;
    }
  }

  /// Get current weather by city name
  Future<WeatherData?> getCurrentWeatherByCity({
    required String cityName,
    String units = 'metric',
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=$units',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherData.fromMap(data);
        
        await FirebaseService.instance.logEvent('weather_fetched_city', {
          'city': cityName,
          'temperature': weather.temperature,
          'condition': weather.condition,
        });
        
        return weather;
      } else {
        throw WeatherException('Failed to fetch weather for $cityName: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to get weather for city: $e');
      return null;
    }
  }

  /// Get weather forecast
  Future<List<WeatherForecast>?> getWeatherForecast({
    required double latitude,
    required double longitude,
    String units = 'metric',
    int days = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=$units&cnt=${days * 8}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final forecasts = (data['list'] as List)
            .map((item) => WeatherForecast.fromMap(item))
            .toList();
        
        await FirebaseService.instance.logEvent('weather_forecast_fetched', {
          'latitude': latitude,
          'longitude': longitude,
          'forecast_count': forecasts.length,
        });
        
        return forecasts;
      } else {
        throw WeatherException('Failed to fetch forecast: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to get weather forecast: $e');
      return null;
    }
  }

  /// Get weather alerts
  Future<List<WeatherAlert>?> getWeatherAlerts({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/onecall?lat=$latitude&lon=$longitude&appid=$_apiKey&exclude=minutely,hourly,daily',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['alerts'] != null) {
          final alerts = (data['alerts'] as List)
              .map((item) => WeatherAlert.fromMap(item))
              .toList();
          
          await FirebaseService.instance.logEvent('weather_alerts_fetched', {
            'latitude': latitude,
            'longitude': longitude,
            'alert_count': alerts.length,
          });
          
          return alerts;
        }
        
        return [];
      } else {
        throw WeatherException('Failed to fetch weather alerts: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to get weather alerts: $e');
      return null;
    }
  }

  /// Check if weather is safe for school transport
  Future<WeatherSafetyAssessment> assessWeatherSafety({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final weather = await getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );

      if (weather == null) {
        return WeatherSafetyAssessment(
          isSafe: false,
          riskLevel: WeatherRiskLevel.unknown,
          warnings: ['Unable to fetch weather data'],
          recommendations: ['Check weather manually before departure'],
        );
      }

      final alerts = await getWeatherAlerts(
        latitude: latitude,
        longitude: longitude,
      );

      return _evaluateWeatherSafety(weather, alerts ?? []);
    } catch (e) {
      debugPrint('❌ Weather safety assessment failed: $e');
      return WeatherSafetyAssessment(
        isSafe: false,
        riskLevel: WeatherRiskLevel.unknown,
        warnings: ['Weather assessment failed'],
        recommendations: ['Check weather manually'],
      );
    }
  }

  /// Evaluate weather safety
  WeatherSafetyAssessment _evaluateWeatherSafety(
    WeatherData weather,
    List<WeatherAlert> alerts,
  ) {
    final warnings = <String>[];
    final recommendations = <String>[];
    WeatherRiskLevel riskLevel = WeatherRiskLevel.low;

    // Check temperature extremes
    if (weather.temperature < -10) {
      warnings.add('Extremely cold temperature (${weather.temperature.toInt()}°C)');
      recommendations.add('Ensure vehicles are properly heated');
      riskLevel = WeatherRiskLevel.high;
    } else if (weather.temperature > 40) {
      warnings.add('Extremely hot temperature (${weather.temperature.toInt()}°C)');
      recommendations.add('Ensure adequate air conditioning');
      riskLevel = WeatherRiskLevel.high;
    }

    // Check wind speed
    if (weather.windSpeed > 15) {
      warnings.add('High wind speed (${weather.windSpeed.toInt()} m/s)');
      recommendations.add('Drive carefully, especially on open roads');
      if (riskLevel == WeatherRiskLevel.low) riskLevel = WeatherRiskLevel.medium;
    }

    // Check visibility
    if (weather.visibility < 1000) {
      warnings.add('Poor visibility (${weather.visibility}m)');
      recommendations.add('Use headlights and drive slowly');
      riskLevel = WeatherRiskLevel.high;
    }

    // Check precipitation
    if (weather.condition.toLowerCase().contains('rain')) {
      if (weather.condition.toLowerCase().contains('heavy')) {
        warnings.add('Heavy rain conditions');
        recommendations.add('Allow extra travel time and drive carefully');
        riskLevel = WeatherRiskLevel.high;
      } else {
        warnings.add('Rainy conditions');
        recommendations.add('Drive carefully on wet roads');
        if (riskLevel == WeatherRiskLevel.low) riskLevel = WeatherRiskLevel.medium;
      }
    }

    if (weather.condition.toLowerCase().contains('snow')) {
      warnings.add('Snow conditions');
      recommendations.add('Ensure vehicles have winter equipment');
      riskLevel = WeatherRiskLevel.high;
    }

    if (weather.condition.toLowerCase().contains('fog')) {
      warnings.add('Foggy conditions');
      recommendations.add('Use fog lights and reduce speed');
      riskLevel = WeatherRiskLevel.high;
    }

    // Check weather alerts
    for (final alert in alerts) {
      warnings.add('Weather Alert: ${alert.event}');
      recommendations.add('Follow official weather warnings');
      if (alert.severity == 'severe' || alert.severity == 'extreme') {
        riskLevel = WeatherRiskLevel.high;
      } else if (riskLevel == WeatherRiskLevel.low) {
        riskLevel = WeatherRiskLevel.medium;
      }
    }

    final isSafe = riskLevel != WeatherRiskLevel.high && alerts.isEmpty;

    return WeatherSafetyAssessment(
      isSafe: isSafe,
      riskLevel: riskLevel,
      warnings: warnings,
      recommendations: recommendations,
    );
  }

  /// Get weather icon URL
  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}

/// Weather data model
class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double pressure;
  final double windSpeed;
  final int windDirection;
  final int visibility;
  final String condition;
  final String description;
  final String iconCode;
  final String cityName;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.visibility,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.cityName,
    required this.timestamp,
  });

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      temperature: (map['main']['temp'] ?? 0).toDouble(),
      feelsLike: (map['main']['feels_like'] ?? 0).toDouble(),
      humidity: map['main']['humidity'] ?? 0,
      pressure: (map['main']['pressure'] ?? 0).toDouble(),
      windSpeed: (map['wind']?['speed'] ?? 0).toDouble(),
      windDirection: map['wind']?['deg'] ?? 0,
      visibility: map['visibility'] ?? 10000,
      condition: map['weather'][0]['main'] ?? '',
      description: map['weather'][0]['description'] ?? '',
      iconCode: map['weather'][0]['icon'] ?? '',
      cityName: map['name'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch((map['dt'] ?? 0) * 1000),
    );
  }
}

/// Weather forecast model
class WeatherForecast {
  final DateTime dateTime;
  final double temperature;
  final String condition;
  final String description;
  final String iconCode;
  final double windSpeed;
  final int humidity;

  WeatherForecast({
    required this.dateTime,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.windSpeed,
    required this.humidity,
  });

  factory WeatherForecast.fromMap(Map<String, dynamic> map) {
    return WeatherForecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch((map['dt'] ?? 0) * 1000),
      temperature: (map['main']['temp'] ?? 0).toDouble(),
      condition: map['weather'][0]['main'] ?? '',
      description: map['weather'][0]['description'] ?? '',
      iconCode: map['weather'][0]['icon'] ?? '',
      windSpeed: (map['wind']?['speed'] ?? 0).toDouble(),
      humidity: map['main']['humidity'] ?? 0,
    );
  }
}

/// Weather alert model
class WeatherAlert {
  final String senderName;
  final String event;
  final DateTime start;
  final DateTime end;
  final String description;
  final String severity;

  WeatherAlert({
    required this.senderName,
    required this.event,
    required this.start,
    required this.end,
    required this.description,
    required this.severity,
  });

  factory WeatherAlert.fromMap(Map<String, dynamic> map) {
    return WeatherAlert(
      senderName: map['sender_name'] ?? '',
      event: map['event'] ?? '',
      start: DateTime.fromMillisecondsSinceEpoch((map['start'] ?? 0) * 1000),
      end: DateTime.fromMillisecondsSinceEpoch((map['end'] ?? 0) * 1000),
      description: map['description'] ?? '',
      severity: map['tags']?[0] ?? 'minor',
    );
  }
}

/// Weather safety assessment model
class WeatherSafetyAssessment {
  final bool isSafe;
  final WeatherRiskLevel riskLevel;
  final List<String> warnings;
  final List<String> recommendations;

  WeatherSafetyAssessment({
    required this.isSafe,
    required this.riskLevel,
    required this.warnings,
    required this.recommendations,
  });
}

/// Weather risk level enum
enum WeatherRiskLevel {
  low,
  medium,
  high,
  unknown,
}

extension WeatherRiskLevelExtension on WeatherRiskLevel {
  String get displayName {
    switch (this) {
      case WeatherRiskLevel.low:
        return 'Low Risk';
      case WeatherRiskLevel.medium:
        return 'Medium Risk';
      case WeatherRiskLevel.high:
        return 'High Risk';
      case WeatherRiskLevel.unknown:
        return 'Unknown';
    }
  }
}

/// Weather exception
class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);
  
  @override
  String toString() => 'WeatherException: $message';
}
