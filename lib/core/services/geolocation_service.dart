import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'firebase_service.dart';

/// IP Geolocation service for security and regional features
class GeolocationService {
  static GeolocationService? _instance;
  static GeolocationService get instance =>
      _instance ??= GeolocationService._();

  GeolocationService._();

  // Multiple IP geolocation providers for redundancy
  static const String _ipApiUrl = 'http://ip-api.com/json';
  static const String _ipInfoUrl = 'https://ipinfo.io';
  static const String _ipInfoToken = 'your_ipinfo_token_here';
  static const String _ipGeolocationUrl = 'https://api.ipgeolocation.io/ipgeo';
  static const String _ipGeolocationApiKey = 'your_ipgeolocation_api_key_here';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize geolocation service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Test service availability
      await _testServices();

      _isInitialized = true;
      debugPrint('✅ Geolocation service initialized successfully');

      await FirebaseService.instance
          .logEvent('geolocation_service_initialized', {});
    } catch (e) {
      debugPrint('❌ Failed to initialize geolocation service: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Geolocation service initialization failed');
      rethrow;
    }
  }

  /// Test geolocation services
  Future<void> _testServices() async {
    try {
      await _getLocationFromIpApi();
      debugPrint('✅ IP-API service is working');
    } catch (e) {
      debugPrint('⚠️ IP-API service test failed: $e');
    }
  }

  /// Get current location based on IP address
  Future<IpLocationData?> getCurrentIpLocation() async {
    if (!_isInitialized) {
      throw GeolocationException('Geolocation service not initialized');
    }

    // Try multiple providers for redundancy
    final providers = [
      _getLocationFromIpApi,
      _getLocationFromIpInfo,
      _getLocationFromIpGeolocation,
    ];

    for (final provider in providers) {
      try {
        final location = await provider();
        if (location != null) {
          await FirebaseService.instance.logEvent('ip_location_obtained', {
            'country': location.country,
            'city': location.city,
            'provider': location.provider,
          });

          return location;
        }
      } catch (e) {
        debugPrint('Provider failed: $e');
        continue;
      }
    }

    debugPrint('❌ All IP geolocation providers failed');
    return null;
  }

  /// Get location for specific IP address
  Future<IpLocationData?> getLocationForIp(String ipAddress) async {
    if (!_isInitialized) {
      throw GeolocationException('Geolocation service not initialized');
    }

    try {
      final response = await http.get(
        Uri.parse('$_ipApiUrl/$ipAddress'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final location = IpLocationData.fromIpApiMap(data);

          await FirebaseService.instance
              .logEvent('specific_ip_location_obtained', {
            'ip': ipAddress,
            'country': location.country,
            'city': location.city,
          });

          return location;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Failed to get location for IP $ipAddress: $e');
      return null;
    }
  }

  /// Get location from IP-API
  Future<IpLocationData?> _getLocationFromIpApi() async {
    try {
      final response = await http.get(
        Uri.parse(_ipApiUrl),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return IpLocationData.fromIpApiMap(data);
        }
      }

      return null;
    } catch (e) {
      throw GeolocationException('IP-API request failed: $e');
    }
  }

  /// Get location from IPInfo
  Future<IpLocationData?> _getLocationFromIpInfo() async {
    try {
      final url = _ipInfoToken.isNotEmpty
          ? '$_ipInfoUrl?token=$_ipInfoToken'
          : _ipInfoUrl;

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IpLocationData.fromIpInfoMap(data);
      }

      return null;
    } catch (e) {
      throw GeolocationException('IPInfo request failed: $e');
    }
  }

  /// Get location from IPGeolocation
  Future<IpLocationData?> _getLocationFromIpGeolocation() async {
    try {
      final response = await http.get(
        Uri.parse('$_ipGeolocationUrl?apiKey=$_ipGeolocationApiKey'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IpLocationData.fromIpGeolocationMap(data);
      }

      return null;
    } catch (e) {
      throw GeolocationException('IPGeolocation request failed: $e');
    }
  }

  /// Check if user is in allowed region
  Future<RegionCheckResult> checkUserRegion({
    List<String> allowedCountries = const ['KE', 'UG', 'TZ'], // East Africa
    List<String> blockedCountries = const [],
  }) async {
    try {
      final location = await getCurrentIpLocation();

      if (location == null) {
        return RegionCheckResult(
          isAllowed: false,
          reason: 'Unable to determine location',
          location: null,
        );
      }

      // Check if country is blocked
      if (blockedCountries.contains(location.countryCode)) {
        await FirebaseService.instance.logEvent('region_blocked', {
          'country': location.country,
          'country_code': location.countryCode,
          'ip': location.ip,
        });

        return RegionCheckResult(
          isAllowed: false,
          reason: 'Access not available in ${location.country}',
          location: location,
        );
      }

      // Check if country is allowed
      if (allowedCountries.isNotEmpty &&
          !allowedCountries.contains(location.countryCode)) {
        await FirebaseService.instance.logEvent('region_not_allowed', {
          'country': location.country,
          'country_code': location.countryCode,
          'ip': location.ip,
        });

        return RegionCheckResult(
          isAllowed: false,
          reason: 'Service not available in ${location.country}',
          location: location,
        );
      }

      await FirebaseService.instance.logEvent('region_allowed', {
        'country': location.country,
        'country_code': location.countryCode,
        'ip': location.ip,
      });

      return RegionCheckResult(
        isAllowed: true,
        reason: 'Access granted',
        location: location,
      );
    } catch (e) {
      debugPrint('❌ Region check failed: $e');

      return RegionCheckResult(
        isAllowed: false,
        reason: 'Region verification failed',
        location: null,
      );
    }
  }

  /// Detect suspicious login activity
  Future<SecurityAssessment> assessLoginSecurity({
    required String userId,
    String? lastKnownCountry,
    String? lastKnownCity,
  }) async {
    try {
      final currentLocation = await getCurrentIpLocation();

      if (currentLocation == null) {
        return SecurityAssessment(
          riskLevel: SecurityRiskLevel.medium,
          warnings: ['Unable to verify location'],
          recommendations: ['Manual verification recommended'],
          location: null,
        );
      }

      final warnings = <String>[];
      final recommendations = <String>[];
      SecurityRiskLevel riskLevel = SecurityRiskLevel.low;

      // Check for country change
      if (lastKnownCountry != null &&
          lastKnownCountry != currentLocation.country) {
        warnings
            .add('Login from different country: ${currentLocation.country}');
        recommendations.add('Verify this login attempt');
        riskLevel = SecurityRiskLevel.high;
      }

      // Check for city change (if same country)
      if (lastKnownCountry == currentLocation.country &&
          lastKnownCity != null &&
          lastKnownCity != currentLocation.city) {
        warnings.add('Login from different city: ${currentLocation.city}');
        recommendations.add('Confirm location change');
        if (riskLevel == SecurityRiskLevel.low) {
          riskLevel = SecurityRiskLevel.medium;
        }
      }

      // Check for VPN/Proxy usage
      if (currentLocation.isProxy || currentLocation.isVpn) {
        warnings.add('VPN or proxy detected');
        recommendations.add('Additional verification required');
        riskLevel = SecurityRiskLevel.high;
      }

      // Check timezone consistency
      if (currentLocation.timezone != null) {
        final expectedHour = DateTime.now()
            .toUtc()
            .add(Duration(seconds: currentLocation.timezoneOffset ?? 0))
            .hour;

        // This is a simplified check - in production, you'd want more sophisticated analysis
        if (expectedHour < 6 || expectedHour > 22) {
          warnings.add('Login at unusual hour for location');
          if (riskLevel == SecurityRiskLevel.low) {
            riskLevel = SecurityRiskLevel.medium;
          }
        }
      }

      await FirebaseService.instance.logEvent('login_security_assessed', {
        'user_id': userId,
        'risk_level': riskLevel.name,
        'country': currentLocation.country,
        'city': currentLocation.city,
        'warning_count': warnings.length,
      });

      return SecurityAssessment(
        riskLevel: riskLevel,
        warnings: warnings,
        recommendations: recommendations,
        location: currentLocation,
      );
    } catch (e) {
      debugPrint('❌ Security assessment failed: $e');

      return SecurityAssessment(
        riskLevel: SecurityRiskLevel.high,
        warnings: ['Security assessment failed'],
        recommendations: ['Manual verification required'],
        location: null,
      );
    }
  }

  /// Get regional settings based on location
  Future<RegionalSettings> getRegionalSettings() async {
    try {
      final location = await getCurrentIpLocation();

      if (location == null) {
        return RegionalSettings.defaultSettings();
      }

      return RegionalSettings.fromLocation(location);
    } catch (e) {
      debugPrint('❌ Failed to get regional settings: $e');
      return RegionalSettings.defaultSettings();
    }
  }
}

/// IP location data model
class IpLocationData {
  final String ip;
  final String country;
  final String countryCode;
  final String region;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final int? timezoneOffset;
  final String? isp;
  final String? organization;
  final bool isProxy;
  final bool isVpn;
  final String provider;

  IpLocationData({
    required this.ip,
    required this.country,
    required this.countryCode,
    required this.region,
    required this.city,
    this.latitude,
    this.longitude,
    this.timezone,
    this.timezoneOffset,
    this.isp,
    this.organization,
    this.isProxy = false,
    this.isVpn = false,
    required this.provider,
  });

  factory IpLocationData.fromIpApiMap(Map<String, dynamic> map) {
    return IpLocationData(
      ip: map['query'] ?? '',
      country: map['country'] ?? '',
      countryCode: map['countryCode'] ?? '',
      region: map['regionName'] ?? '',
      city: map['city'] ?? '',
      latitude: map['lat']?.toDouble(),
      longitude: map['lon']?.toDouble(),
      timezone: map['timezone'],
      isp: map['isp'],
      organization: map['org'],
      isProxy: map['proxy'] ?? false,
      isVpn: false, // IP-API doesn't provide VPN detection
      provider: 'IP-API',
    );
  }

  factory IpLocationData.fromIpInfoMap(Map<String, dynamic> map) {
    final loc = map['loc']?.split(',');

    return IpLocationData(
      ip: map['ip'] ?? '',
      country: map['country'] ?? '',
      countryCode: map['country'] ?? '',
      region: map['region'] ?? '',
      city: map['city'] ?? '',
      latitude: loc != null && loc.length > 0 ? double.tryParse(loc[0]) : null,
      longitude: loc != null && loc.length > 1 ? double.tryParse(loc[1]) : null,
      timezone: map['timezone'],
      isp: map['org'],
      organization: map['org'],
      provider: 'IPInfo',
    );
  }

  factory IpLocationData.fromIpGeolocationMap(Map<String, dynamic> map) {
    return IpLocationData(
      ip: map['ip'] ?? '',
      country: map['country_name'] ?? '',
      countryCode: map['country_code2'] ?? '',
      region: map['state_prov'] ?? '',
      city: map['city'] ?? '',
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      timezone: map['time_zone']?['name'],
      timezoneOffset: map['time_zone']?['offset'],
      isp: map['isp'],
      organization: map['organization'],
      isProxy: map['threat']?['is_proxy'] ?? false,
      isVpn: map['threat']?['is_anonymous'] ?? false,
      provider: 'IPGeolocation',
    );
  }
}

/// Region check result model
class RegionCheckResult {
  final bool isAllowed;
  final String reason;
  final IpLocationData? location;

  RegionCheckResult({
    required this.isAllowed,
    required this.reason,
    required this.location,
  });
}

/// Security assessment model
class SecurityAssessment {
  final SecurityRiskLevel riskLevel;
  final List<String> warnings;
  final List<String> recommendations;
  final IpLocationData? location;

  SecurityAssessment({
    required this.riskLevel,
    required this.warnings,
    required this.recommendations,
    required this.location,
  });
}

/// Security risk level enum
enum SecurityRiskLevel {
  low,
  medium,
  high,
}

/// Regional settings model
class RegionalSettings {
  final String currency;
  final String language;
  final String dateFormat;
  final String timeFormat;
  final List<String> paymentMethods;

  RegionalSettings({
    required this.currency,
    required this.language,
    required this.dateFormat,
    required this.timeFormat,
    required this.paymentMethods,
  });

  factory RegionalSettings.fromLocation(IpLocationData location) {
    switch (location.countryCode) {
      case 'KE':
        return RegionalSettings(
          currency: 'KES',
          language: 'en',
          dateFormat: 'dd/MM/yyyy',
          timeFormat: '24h',
          paymentMethods: ['mpesa', 'card', 'bank_transfer'],
        );
      case 'UG':
        return RegionalSettings(
          currency: 'UGX',
          language: 'en',
          dateFormat: 'dd/MM/yyyy',
          timeFormat: '24h',
          paymentMethods: ['mobile_money', 'card', 'bank_transfer'],
        );
      case 'TZ':
        return RegionalSettings(
          currency: 'TZS',
          language: 'sw',
          dateFormat: 'dd/MM/yyyy',
          timeFormat: '24h',
          paymentMethods: ['mobile_money', 'card', 'bank_transfer'],
        );
      default:
        return RegionalSettings.defaultSettings();
    }
  }

  factory RegionalSettings.defaultSettings() {
    return RegionalSettings(
      currency: 'USD',
      language: 'en',
      dateFormat: 'MM/dd/yyyy',
      timeFormat: '12h',
      paymentMethods: ['card', 'bank_transfer'],
    );
  }
}

/// Geolocation exception
class GeolocationException implements Exception {
  final String message;
  GeolocationException(this.message);

  @override
  String toString() => 'GeolocationException: $message';
}
