import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  late Box _dataBox;
  late Box _syncQueueBox;
  late SharedPreferences _prefs;

  bool _isOnline = true;
  bool _isInitialized = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  final StreamController<SyncStatus> _syncController =
      StreamController<SyncStatus>.broadcast();

  // Getters
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;
  Stream<bool> get connectivityStream => _connectivityController.stream;
  Stream<SyncStatus> get syncStream => _syncController.stream;

  // Initialize offline service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters for custom objects
      _registerHiveAdapters();

      // Open boxes
      _dataBox = await Hive.openBox('offline_data');
      _syncQueueBox = await Hive.openBox('sync_queue');

      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Check initial connectivity
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);

      // Listen to connectivity changes
      _connectivitySubscription =
          connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

      // Start periodic sync
      _startPeriodicSync();

      _isInitialized = true;
      debugPrint('OfflineService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize OfflineService: $e');
      rethrow;
    }
  }

  void _registerHiveAdapters() {
    // Register custom type adapters here
    // Example: Hive.registerAdapter(UserAdapter());
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    _connectivityController.add(_isOnline);

    if (!wasOnline && _isOnline) {
      // Connection restored, trigger sync
      _triggerSync();
    }

    debugPrint('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline) {
        _triggerSync();
      }
    });
  }

  // Data Storage Methods
  Future<void> storeData(String key, dynamic data,
      {bool requiresSync = false}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final offlineData = OfflineData(
        key: key,
        data: data,
        timestamp: timestamp,
        requiresSync: requiresSync,
        synced: false,
      );

      await _dataBox.put(key, offlineData.toJson());

      if (requiresSync) {
        await _addToSyncQueue(key, SyncOperation.update, data);
      }

      debugPrint('Data stored offline: $key');
    } catch (e) {
      debugPrint('Failed to store data offline: $e');
      rethrow;
    }
  }

  T? getData<T>(String key, {T? defaultValue}) {
    try {
      final jsonData = _dataBox.get(key);
      if (jsonData == null) return defaultValue;

      final offlineData = OfflineData.fromJson(jsonData);
      return offlineData.data as T?;
    } catch (e) {
      debugPrint('Failed to get data offline: $e');
      return defaultValue;
    }
  }

  Future<void> deleteData(String key, {bool requiresSync = false}) async {
    try {
      await _dataBox.delete(key);

      if (requiresSync) {
        await _addToSyncQueue(key, SyncOperation.delete, null);
      }

      debugPrint('Data deleted offline: $key');
    } catch (e) {
      debugPrint('Failed to delete data offline: $e');
      rethrow;
    }
  }

  List<String> getAllKeys({String? prefix}) {
    try {
      final keys = _dataBox.keys.cast<String>().toList();
      if (prefix != null) {
        return keys.where((key) => key.startsWith(prefix)).toList();
      }
      return keys;
    } catch (e) {
      debugPrint('Failed to get all keys: $e');
      return [];
    }
  }

  // Sync Queue Management
  Future<void> _addToSyncQueue(
      String key, SyncOperation operation, dynamic data) async {
    try {
      final syncItem = SyncQueueItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        key: key,
        operation: operation,
        data: data,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        retryCount: 0,
      );

      await _syncQueueBox.put(syncItem.id, syncItem.toJson());
      debugPrint('Added to sync queue: ${operation.name} - $key');
    } catch (e) {
      debugPrint('Failed to add to sync queue: $e');
    }
  }

  Future<void> _triggerSync() async {
    if (!_isOnline) return;

    _syncController.add(SyncStatus.syncing);

    try {
      final syncItems = _syncQueueBox.values
          .map((json) => SyncQueueItem.fromJson(json))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      int successCount = 0;
      int failureCount = 0;

      for (final item in syncItems) {
        try {
          final success = await _syncItem(item);
          if (success) {
            await _syncQueueBox.delete(item.id);
            successCount++;
          } else {
            // Increment retry count
            item.retryCount++;
            if (item.retryCount >= 3) {
              // Max retries reached, remove from queue
              await _syncQueueBox.delete(item.id);
              failureCount++;
            } else {
              await _syncQueueBox.put(item.id, item.toJson());
            }
          }
        } catch (e) {
          debugPrint('Failed to sync item ${item.id}: $e');
          failureCount++;
        }
      }

      _syncController.add(SyncStatus.completed);
      debugPrint(
          'Sync completed: $successCount success, $failureCount failures');
    } catch (e) {
      _syncController.add(SyncStatus.failed);
      debugPrint('Sync failed: $e');
    }
  }

  Future<bool> _syncItem(SyncQueueItem item) async {
    try {
      // This would integrate with your actual API service
      // For now, we'll simulate the sync operation
      await Future.delayed(const Duration(milliseconds: 500));

      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          // Simulate API call to create/update data
          debugPrint('Syncing ${item.operation.name}: ${item.key}');
          break;
        case SyncOperation.delete:
          // Simulate API call to delete data
          debugPrint('Syncing delete: ${item.key}');
          break;
      }

      // Mark local data as synced
      final localData = _dataBox.get(item.key);
      if (localData != null) {
        final offlineData = OfflineData.fromJson(localData);
        offlineData.synced = true;
        await _dataBox.put(item.key, offlineData.toJson());
      }

      return true;
    } catch (e) {
      debugPrint('Failed to sync item: $e');
      return false;
    }
  }

  // Cache Management
  Future<void> clearCache() async {
    try {
      await _dataBox.clear();
      await _syncQueueBox.clear();
      debugPrint('Cache cleared');
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  Future<void> clearSyncedData() async {
    try {
      final keysToDelete = <String>[];

      for (final key in _dataBox.keys) {
        final jsonData = _dataBox.get(key);
        if (jsonData != null) {
          final offlineData = OfflineData.fromJson(jsonData);
          if (offlineData.synced) {
            keysToDelete.add(key as String);
          }
        }
      }

      for (final key in keysToDelete) {
        await _dataBox.delete(key);
      }

      debugPrint('Cleared ${keysToDelete.length} synced items');
    } catch (e) {
      debugPrint('Failed to clear synced data: $e');
    }
  }

  // Statistics
  OfflineStats getStats() {
    try {
      final totalItems = _dataBox.length;
      final syncQueueItems = _syncQueueBox.length;

      int syncedItems = 0;
      int unsyncedItems = 0;

      for (final value in _dataBox.values) {
        final offlineData = OfflineData.fromJson(value);
        if (offlineData.synced) {
          syncedItems++;
        } else {
          unsyncedItems++;
        }
      }

      return OfflineStats(
        totalItems: totalItems,
        syncedItems: syncedItems,
        unsyncedItems: unsyncedItems,
        pendingSyncItems: syncQueueItems,
        isOnline: _isOnline,
      );
    } catch (e) {
      debugPrint('Failed to get stats: $e');
      return OfflineStats(
        totalItems: 0,
        syncedItems: 0,
        unsyncedItems: 0,
        pendingSyncItems: 0,
        isOnline: _isOnline,
      );
    }
  }

  // Cleanup
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    await _connectivityController.close();
    await _syncController.close();
    await _dataBox.close();
    await _syncQueueBox.close();
  }
}

// Data Models
class OfflineData {
  final String key;
  final dynamic data;
  final int timestamp;
  final bool requiresSync;
  bool synced;

  OfflineData({
    required this.key,
    required this.data,
    required this.timestamp,
    required this.requiresSync,
    required this.synced,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'data': data,
        'timestamp': timestamp,
        'requiresSync': requiresSync,
        'synced': synced,
      };

  factory OfflineData.fromJson(Map<String, dynamic> json) => OfflineData(
        key: json['key'],
        data: json['data'],
        timestamp: json['timestamp'],
        requiresSync: json['requiresSync'],
        synced: json['synced'],
      );
}

class SyncQueueItem {
  final String id;
  final String key;
  final SyncOperation operation;
  final dynamic data;
  final int timestamp;
  int retryCount;

  SyncQueueItem({
    required this.id,
    required this.key,
    required this.operation,
    required this.data,
    required this.timestamp,
    required this.retryCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'operation': operation.name,
        'data': data,
        'timestamp': timestamp,
        'retryCount': retryCount,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: json['id'],
        key: json['key'],
        operation:
            SyncOperation.values.firstWhere((e) => e.name == json['operation']),
        data: json['data'],
        timestamp: json['timestamp'],
        retryCount: json['retryCount'],
      );
}

class OfflineStats {
  final int totalItems;
  final int syncedItems;
  final int unsyncedItems;
  final int pendingSyncItems;
  final bool isOnline;

  OfflineStats({
    required this.totalItems,
    required this.syncedItems,
    required this.unsyncedItems,
    required this.pendingSyncItems,
    required this.isOnline,
  });
}

enum SyncOperation { create, update, delete }

enum SyncStatus { syncing, completed, failed }
