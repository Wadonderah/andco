import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/user_model.dart';
import '../../shared/models/child_model.dart';
import '../../shared/models/bus_model.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/trip_model.dart';
import '../../shared/models/checkin_model.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/models/notification_model.dart';

/// Service for managing Hive local storage
class HiveService {
  static final HiveService _instance = HiveService._internal();
  static HiveService get instance => _instance;
  HiveService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Box names
  static const String _usersBox = 'users';
  static const String _childrenBox = 'children';
  static const String _busesBox = 'buses';
  static const String _routesBox = 'routes';
  static const String _tripsBox = 'trips';
  static const String _checkinsBox = 'checkins';
  static const String _paymentsBox = 'payments';
  static const String _notificationsBox = 'notifications';
  static const String _settingsBox = 'settings';
  static const String _cacheBox = 'cache';

  /// Initialize Hive and open all required boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters for custom objects
      _registerAdapters();

      // Open all boxes
      await _openBoxes();

      _isInitialized = true;
      debugPrint('✅ Hive service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Hive service: $e');
      rethrow;
    }
  }

  /// Register Hive adapters for custom objects
  void _registerAdapters() {
    try {
      // Register adapters only if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ChildModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(BusModelAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(RouteModelAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(TripModelAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(CheckinModelAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(PaymentModelAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(NotificationModelAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(UserRoleAdapter());
      }
    } catch (e) {
      debugPrint('Warning: Some Hive adapters may already be registered: $e');
    }
  }

  /// Open all required Hive boxes
  Future<void> _openBoxes() async {
    try {
      await Future.wait([
        Hive.openBox<UserModel>(_usersBox),
        Hive.openBox<ChildModel>(_childrenBox),
        Hive.openBox<BusModel>(_busesBox),
        Hive.openBox<RouteModel>(_routesBox),
        Hive.openBox<TripModel>(_tripsBox),
        Hive.openBox<CheckinModel>(_checkinsBox),
        Hive.openBox<PaymentModel>(_paymentsBox),
        Hive.openBox<NotificationModel>(_notificationsBox),
        Hive.openBox(_settingsBox),
        Hive.openBox(_cacheBox),
      ]);
    } catch (e) {
      debugPrint('Error opening Hive boxes: $e');
      // Try to open boxes individually if batch opening fails
      await _openBoxesIndividually();
    }
  }

  /// Open Hive boxes individually as fallback
  Future<void> _openBoxesIndividually() async {
    final boxConfigs = [
      {'name': _usersBox, 'type': UserModel},
      {'name': _childrenBox, 'type': ChildModel},
      {'name': _busesBox, 'type': BusModel},
      {'name': _routesBox, 'type': RouteModel},
      {'name': _tripsBox, 'type': TripModel},
      {'name': _checkinsBox, 'type': CheckinModel},
      {'name': _paymentsBox, 'type': PaymentModel},
      {'name': _notificationsBox, 'type': NotificationModel},
      {'name': _settingsBox, 'type': null},
      {'name': _cacheBox, 'type': null},
    ];

    for (final config in boxConfigs) {
      try {
        if (config['type'] != null) {
          await Hive.openBox(config['name'] as String);
        } else {
          await Hive.openBox(config['name'] as String);
        }
      } catch (e) {
        debugPrint('Failed to open box ${config['name']}: $e');
        // Continue with other boxes even if one fails
      }
    }
  }

  /// Get a specific box
  Box<T> getBox<T>(String boxName) {
    if (!_isInitialized) {
      throw Exception('HiveService not initialized. Call initialize() first.');
    }
    return Hive.box<T>(boxName);
  }

  /// Get users box
  Box<UserModel> get usersBox => getBox<UserModel>(_usersBox);

  /// Get children box
  Box<ChildModel> get childrenBox => getBox<ChildModel>(_childrenBox);

  /// Get buses box
  Box<BusModel> get busesBox => getBox<BusModel>(_busesBox);

  /// Get routes box
  Box<RouteModel> get routesBox => getBox<RouteModel>(_routesBox);

  /// Get trips box
  Box<TripModel> get tripsBox => getBox<TripModel>(_tripsBox);

  /// Get checkins box
  Box<CheckinModel> get checkinsBox => getBox<CheckinModel>(_checkinsBox);

  /// Get payments box
  Box<PaymentModel> get paymentsBox => getBox<PaymentModel>(_paymentsBox);

  /// Get notifications box
  Box<NotificationModel> get notificationsBox => getBox<NotificationModel>(_notificationsBox);

  /// Get settings box
  Box get settingsBox => getBox(_settingsBox);

  /// Get cache box
  Box get cacheBox => getBox(_cacheBox);

  /// Store data in cache
  Future<void> cacheData(String key, dynamic data) async {
    try {
      await cacheBox.put(key, {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Failed to cache data: $e');
    }
  }

  /// Get cached data
  T? getCachedData<T>(String key, {Duration? maxAge}) {
    try {
      final cached = cacheBox.get(key);
      if (cached == null) return null;

      final timestamp = cached['timestamp'] as int?;
      final data = cached['data'];

      if (maxAge != null && timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age > maxAge.inMilliseconds) {
          // Data is too old, remove it
          cacheBox.delete(key);
          return null;
        }
      }

      return data as T?;
    } catch (e) {
      debugPrint('Failed to get cached data: $e');
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await cacheBox.clear();
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Store user setting
  Future<void> setSetting(String key, dynamic value) async {
    try {
      await settingsBox.put(key, value);
    } catch (e) {
      debugPrint('Failed to store setting: $e');
    }
  }

  /// Get user setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      return settingsBox.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      debugPrint('Failed to get setting: $e');
      return defaultValue;
    }
  }

  /// Close all boxes and cleanup
  Future<void> dispose() async {
    try {
      await Hive.close();
      _isInitialized = false;
      debugPrint('✅ Hive service disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose Hive service: $e');
    }
  }

  /// Delete all data (for testing or reset)
  Future<void> deleteAllData() async {
    try {
      await Future.wait([
        usersBox.clear(),
        childrenBox.clear(),
        busesBox.clear(),
        routesBox.clear(),
        tripsBox.clear(),
        checkinsBox.clear(),
        paymentsBox.clear(),
        notificationsBox.clear(),
        settingsBox.clear(),
        cacheBox.clear(),
      ]);
      debugPrint('✅ All Hive data deleted');
    } catch (e) {
      debugPrint('❌ Failed to delete Hive data: $e');
    }
  }
}
