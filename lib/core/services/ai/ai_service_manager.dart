import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'base_ai_service.dart';
import 'route_optimization_service.dart';
import 'safety_monitoring_service.dart';
import 'chatbot_service.dart';
import 'incident_response_service.dart';
import 'notification_intelligence_service.dart';
import 'budget_optimization_service.dart';

/// Central manager for all AI services in the AndCo School Transport app
class AIServiceManager {
  static final AIServiceManager _instance = AIServiceManager._internal();
  static AIServiceManager get instance => _instance;
  AIServiceManager._internal();

  final Map<String, BaseAIService> _services = {};
  bool _isInitialized = false;
  
  /// Get all registered AI services
  Map<String, BaseAIService> get services => Map.unmodifiable(_services);
  
  /// Check if the manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize all AI services
  Future<void> initialize({bool isProduction = false}) async {
    if (_isInitialized) return;

    try {
      debugPrint('🤖 Initializing AI Service Manager...');

      // Register all AI services
      await _registerServices();

      // Load configurations
      await _loadConfigurations();

      // Initialize enabled services
      await _initializeEnabledServices(isProduction: isProduction);

      _isInitialized = true;
      debugPrint('✅ AI Service Manager initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize AI Service Manager: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Register all AI services
  Future<void> _registerServices() async {
    // Register Smart Route Optimization Agent
    _services['route_optimization'] = RouteOptimizationService();
    
    // Register Predictive Safety Agent
    _services['safety_monitoring'] = SafetyMonitoringService();
    
    // Register Customer Support Chatbot
    _services['chatbot'] = ChatbotService();
    
    // Register Incident Response Agent
    _services['incident_response'] = IncidentResponseService();
    
    // Register Smart Notification Agent
    _services['notification_intelligence'] = NotificationIntelligenceService();
    
    // Register Budget Optimization Agent
    _services['budget_optimization'] = BudgetOptimizationService();

    debugPrint('📝 Registered ${_services.length} AI services');
  }

  /// Load service configurations from storage
  Future<void> _loadConfigurations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final entry in _services.entries) {
        final serviceName = entry.key;
        final service = entry.value;
        
        final configJson = prefs.getString('ai_config_$serviceName');
        if (configJson != null) {
          final config = json.decode(configJson) as Map<String, dynamic>;
          await service.updateConfiguration(config);
        }
      }
      
      debugPrint('⚙️ Loaded AI service configurations');
    } catch (e) {
      debugPrint('⚠️ Failed to load AI configurations: $e');
    }
  }

  /// Initialize enabled services
  Future<void> _initializeEnabledServices({bool isProduction = false}) async {
    final initializationResults = <String, bool>{};
    
    for (final entry in _services.entries) {
      final serviceName = entry.key;
      final service = entry.value;
      
      try {
        if (service.isEnabled) {
          await service.initialize(config: {
            'isProduction': isProduction,
            'serviceName': serviceName,
          });
          initializationResults[serviceName] = true;
          debugPrint('✅ Initialized AI service: $serviceName');
        } else {
          debugPrint('⏭️ Skipped disabled AI service: $serviceName');
          initializationResults[serviceName] = false;
        }
      } catch (e) {
        debugPrint('❌ Failed to initialize AI service $serviceName: $e');
        initializationResults[serviceName] = false;
      }
    }
    
    final successCount = initializationResults.values.where((success) => success).length;
    debugPrint('🎯 Initialized $successCount/${_services.length} AI services');
  }

  /// Get a specific AI service
  T? getService<T extends BaseAIService>(String serviceName) {
    return _services[serviceName] as T?;
  }

  /// Enable a specific AI service
  Future<void> enableService(String serviceName) async {
    final service = _services[serviceName];
    if (service == null) {
      throw AIServiceException('Service not found: $serviceName');
    }

    try {
      await service.enable();
      await _saveServiceConfiguration(serviceName, service.getConfiguration());
      debugPrint('✅ Enabled AI service: $serviceName');
    } catch (e) {
      debugPrint('❌ Failed to enable AI service $serviceName: $e');
      rethrow;
    }
  }

  /// Disable a specific AI service
  Future<void> disableService(String serviceName) async {
    final service = _services[serviceName];
    if (service == null) {
      throw AIServiceException('Service not found: $serviceName');
    }

    try {
      await service.disable();
      await _saveServiceConfiguration(serviceName, service.getConfiguration());
      debugPrint('🔇 Disabled AI service: $serviceName');
    } catch (e) {
      debugPrint('❌ Failed to disable AI service $serviceName: $e');
      rethrow;
    }
  }

  /// Get health status of all services
  Future<Map<String, AIServiceHealth>> getHealthStatus() async {
    final healthStatus = <String, AIServiceHealth>{};
    
    for (final entry in _services.entries) {
      final serviceName = entry.key;
      final service = entry.value;
      
      try {
        healthStatus[serviceName] = await service.getHealthStatus();
      } catch (e) {
        healthStatus[serviceName] = AIServiceHealth(
          serviceName: serviceName,
          status: AIServiceStatus.error,
          isHealthy: false,
          errorMessage: e.toString(),
          lastCheck: DateTime.now(),
        );
      }
    }
    
    return healthStatus;
  }

  /// Update configuration for a specific service
  Future<void> updateServiceConfiguration(
    String serviceName,
    Map<String, dynamic> config,
  ) async {
    final service = _services[serviceName];
    if (service == null) {
      throw AIServiceException('Service not found: $serviceName');
    }

    try {
      await service.updateConfiguration(config);
      await _saveServiceConfiguration(serviceName, config);
      debugPrint('⚙️ Updated configuration for AI service: $serviceName');
    } catch (e) {
      debugPrint('❌ Failed to update configuration for $serviceName: $e');
      rethrow;
    }
  }

  /// Save service configuration to storage
  Future<void> _saveServiceConfiguration(
    String serviceName,
    Map<String, dynamic> config,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_config_$serviceName', json.encode(config));
    } catch (e) {
      debugPrint('⚠️ Failed to save configuration for $serviceName: $e');
    }
  }

  /// Reset all AI services
  Future<void> resetAllServices() async {
    for (final entry in _services.entries) {
      final serviceName = entry.key;
      final service = entry.value;
      
      try {
        await service.reset();
        debugPrint('🔄 Reset AI service: $serviceName');
      } catch (e) {
        debugPrint('❌ Failed to reset AI service $serviceName: $e');
      }
    }
  }

  /// Dispose all AI services
  Future<void> dispose() async {
    for (final entry in _services.entries) {
      final serviceName = entry.key;
      final service = entry.value;
      
      try {
        await service.dispose();
        debugPrint('🗑️ Disposed AI service: $serviceName');
      } catch (e) {
        debugPrint('❌ Failed to dispose AI service $serviceName: $e');
      }
    }
    
    _services.clear();
    _isInitialized = false;
    debugPrint('🧹 AI Service Manager disposed');
  }

  /// Get service statistics
  Map<String, dynamic> getServiceStatistics() {
    final stats = <String, dynamic>{};
    
    for (final entry in _services.entries) {
      final serviceName = entry.key;
      final service = entry.value;
      
      stats[serviceName] = {
        'status': service.status.name,
        'enabled': service.isEnabled,
        'initialized': service.isInitialized,
        'configuration': service.getConfiguration(),
      };
    }
    
    return {
      'totalServices': _services.length,
      'enabledServices': _services.values.where((s) => s.isEnabled).length,
      'initializedServices': _services.values.where((s) => s.isInitialized).length,
      'services': stats,
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }

  /// Check if a specific service is available and healthy
  Future<bool> isServiceHealthy(String serviceName) async {
    final service = _services[serviceName];
    if (service == null) return false;

    try {
      final health = await service.getHealthStatus();
      return health.isHealthy;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available service names
  List<String> getAvailableServices() {
    return _services.keys.toList();
  }

  /// Get list of enabled service names
  List<String> getEnabledServices() {
    return _services.entries
        .where((entry) => entry.value.isEnabled)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Provider for AI Service Manager
final aiServiceManagerProvider = Provider<AIServiceManager>((ref) {
  return AIServiceManager.instance;
});

/// Provider for AI services health status
final aiServicesHealthProvider = FutureProvider<Map<String, AIServiceHealth>>((ref) async {
  final manager = ref.read(aiServiceManagerProvider);
  return await manager.getHealthStatus();
});

/// Provider for AI service statistics
final aiServiceStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final manager = ref.read(aiServiceManagerProvider);
  return manager.getServiceStatistics();
});

/// Provider for specific AI service
final aiServiceProvider = Provider.family<BaseAIService?, String>((ref, serviceName) {
  final manager = ref.read(aiServiceManagerProvider);
  return manager.getService(serviceName);
});
