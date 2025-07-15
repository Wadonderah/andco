import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base class for all AI services in the AndCo School Transport app
/// Provides common functionality and patterns for AI agent implementation
abstract class BaseAIService {
  /// Service name for identification and logging
  String get serviceName;
  
  /// Whether the service is currently enabled
  bool get isEnabled;
  
  /// Whether the service is currently initialized
  bool get isInitialized;
  
  /// Current service status
  AIServiceStatus get status;
  
  /// Initialize the AI service with configuration
  Future<void> initialize({Map<String, dynamic>? config});
  
  /// Dispose of resources and cleanup
  Future<void> dispose();
  
  /// Enable the service
  Future<void> enable();
  
  /// Disable the service
  Future<void> disable();
  
  /// Get service health status
  Future<AIServiceHealth> getHealthStatus();
  
  /// Get service configuration
  Map<String, dynamic> getConfiguration();
  
  /// Update service configuration
  Future<void> updateConfiguration(Map<String, dynamic> config);
  
  /// Reset service to default state
  Future<void> reset();
}

/// AI Service status enumeration
enum AIServiceStatus {
  uninitialized,
  initializing,
  ready,
  running,
  error,
  disabled,
}

/// AI Service health information
class AIServiceHealth {
  final String serviceName;
  final AIServiceStatus status;
  final bool isHealthy;
  final String? errorMessage;
  final DateTime lastCheck;
  final Map<String, dynamic> metrics;

  const AIServiceHealth({
    required this.serviceName,
    required this.status,
    required this.isHealthy,
    this.errorMessage,
    required this.lastCheck,
    this.metrics = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceName': serviceName,
      'status': status.name,
      'isHealthy': isHealthy,
      'errorMessage': errorMessage,
      'lastCheck': lastCheck.toIso8601String(),
      'metrics': metrics,
    };
  }

  factory AIServiceHealth.fromJson(Map<String, dynamic> json) {
    return AIServiceHealth(
      serviceName: json['serviceName'] ?? '',
      status: AIServiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AIServiceStatus.uninitialized,
      ),
      isHealthy: json['isHealthy'] ?? false,
      errorMessage: json['errorMessage'],
      lastCheck: DateTime.parse(json['lastCheck']),
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
    );
  }
}

/// Base AI configuration class
abstract class AIServiceConfig {
  /// Whether the service is enabled
  final bool enabled;
  
  /// API endpoint URL (if applicable)
  final String? apiEndpoint;
  
  /// API key (if applicable)
  final String? apiKey;
  
  /// Rate limiting configuration
  final RateLimitConfig? rateLimitConfig;
  
  /// Caching configuration
  final CacheConfig? cacheConfig;
  
  /// Custom configuration parameters
  final Map<String, dynamic> customConfig;

  const AIServiceConfig({
    this.enabled = true,
    this.apiEndpoint,
    this.apiKey,
    this.rateLimitConfig,
    this.cacheConfig,
    this.customConfig = const {},
  });

  Map<String, dynamic> toJson();
  
  /// Create configuration from JSON
  static AIServiceConfig fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('Subclasses must implement fromJson');
  }
}

/// Rate limiting configuration
class RateLimitConfig {
  final int maxRequestsPerMinute;
  final int maxRequestsPerHour;
  final int maxRequestsPerDay;
  final Duration cooldownPeriod;

  const RateLimitConfig({
    this.maxRequestsPerMinute = 60,
    this.maxRequestsPerHour = 1000,
    this.maxRequestsPerDay = 10000,
    this.cooldownPeriod = const Duration(seconds: 1),
  });

  Map<String, dynamic> toJson() {
    return {
      'maxRequestsPerMinute': maxRequestsPerMinute,
      'maxRequestsPerHour': maxRequestsPerHour,
      'maxRequestsPerDay': maxRequestsPerDay,
      'cooldownPeriodMs': cooldownPeriod.inMilliseconds,
    };
  }

  factory RateLimitConfig.fromJson(Map<String, dynamic> json) {
    return RateLimitConfig(
      maxRequestsPerMinute: json['maxRequestsPerMinute'] ?? 60,
      maxRequestsPerHour: json['maxRequestsPerHour'] ?? 1000,
      maxRequestsPerDay: json['maxRequestsPerDay'] ?? 10000,
      cooldownPeriod: Duration(milliseconds: json['cooldownPeriodMs'] ?? 1000),
    );
  }
}

/// Cache configuration
class CacheConfig {
  final bool enabled;
  final Duration cacheDuration;
  final int maxCacheSize;
  final bool persistCache;

  const CacheConfig({
    this.enabled = true,
    this.cacheDuration = const Duration(hours: 1),
    this.maxCacheSize = 100,
    this.persistCache = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'cacheDurationMs': cacheDuration.inMilliseconds,
      'maxCacheSize': maxCacheSize,
      'persistCache': persistCache,
    };
  }

  factory CacheConfig.fromJson(Map<String, dynamic> json) {
    return CacheConfig(
      enabled: json['enabled'] ?? true,
      cacheDuration: Duration(milliseconds: json['cacheDurationMs'] ?? 3600000),
      maxCacheSize: json['maxCacheSize'] ?? 100,
      persistCache: json['persistCache'] ?? false,
    );
  }
}

/// AI Service result wrapper
class AIServiceResult<T> {
  final T? data;
  final bool success;
  final String? error;
  final Map<String, dynamic> metadata;

  const AIServiceResult({
    this.data,
    required this.success,
    this.error,
    this.metadata = const {},
  });

  factory AIServiceResult.success(T data, {Map<String, dynamic>? metadata}) {
    return AIServiceResult(
      data: data,
      success: true,
      metadata: metadata ?? {},
    );
  }

  factory AIServiceResult.failure(String error, {Map<String, dynamic>? metadata}) {
    return AIServiceResult(
      success: false,
      error: error,
      metadata: metadata ?? {},
    );
  }

  bool get isSuccess => success;
  bool get isFailure => !success;
}

/// AI Service exception
class AIServiceException implements Exception {
  final String message;
  final String? serviceName;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AIServiceException(
    this.message, {
    this.serviceName,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AIServiceException${serviceName != null ? ' ($serviceName)' : ''}: $message';
  }
}

/// Mixin for rate limiting functionality
mixin RateLimitMixin {
  final Map<String, List<DateTime>> _requestHistory = {};
  RateLimitConfig? _rateLimitConfig;

  void setRateLimitConfig(RateLimitConfig config) {
    _rateLimitConfig = config;
  }

  Future<bool> checkRateLimit(String endpoint) async {
    if (_rateLimitConfig == null) return true;

    final now = DateTime.now();
    final history = _requestHistory[endpoint] ?? [];

    // Clean old requests
    history.removeWhere((time) => now.difference(time) > const Duration(days: 1));

    // Check limits
    final minuteAgo = now.subtract(const Duration(minutes: 1));
    final hourAgo = now.subtract(const Duration(hours: 1));
    final dayAgo = now.subtract(const Duration(days: 1));

    final requestsLastMinute = history.where((time) => time.isAfter(minuteAgo)).length;
    final requestsLastHour = history.where((time) => time.isAfter(hourAgo)).length;
    final requestsLastDay = history.where((time) => time.isAfter(dayAgo)).length;

    if (requestsLastMinute >= _rateLimitConfig!.maxRequestsPerMinute ||
        requestsLastHour >= _rateLimitConfig!.maxRequestsPerHour ||
        requestsLastDay >= _rateLimitConfig!.maxRequestsPerDay) {
      return false;
    }

    // Add current request
    history.add(now);
    _requestHistory[endpoint] = history;

    return true;
  }

  void clearRateLimit(String endpoint) {
    _requestHistory.remove(endpoint);
  }
}

/// Mixin for caching functionality
mixin CacheMixin<T> {
  final Map<String, CacheEntry<T>> _cache = {};
  CacheConfig? _cacheConfig;

  void setCacheConfig(CacheConfig config) {
    _cacheConfig = config;
  }

  T? getCached(String key) {
    if (_cacheConfig?.enabled != true) return null;

    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return entry.data;
  }

  void setCached(String key, T data) {
    if (_cacheConfig?.enabled != true) return;

    final expiresAt = DateTime.now().add(_cacheConfig!.cacheDuration);
    _cache[key] = CacheEntry(data: data, expiresAt: expiresAt);

    // Clean cache if it exceeds max size
    if (_cache.length > _cacheConfig!.maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }

  void clearCache() {
    _cache.clear();
  }
}

/// Cache entry wrapper
class CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  const CacheEntry({
    required this.data,
    required this.expiresAt,
  });
}
