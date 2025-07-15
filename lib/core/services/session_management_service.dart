import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/user_model.dart';

/// Comprehensive session management service with security features
class SessionManagementService {
  static const String _sessionTokenKey = 'session_token';
  static const String _sessionExpiryKey = 'session_expiry';
  static const String _deviceFingerprintKey = 'device_fingerprint';
  static const String _sessionHistoryKey = 'session_history';
  static const String _lastActivityKey = 'last_activity';
  static const String _autoLockTimeKey = 'auto_lock_time';

  static const int defaultSessionDurationMinutes = 480; // 8 hours
  static const int maxInactivityMinutes = 30;
  static const int maxSessionHistoryEntries = 10;

  Timer? _inactivityTimer;
  Timer? _sessionExpiryTimer;
  VoidCallback? _onSessionExpired;
  VoidCallback? _onInactivityTimeout;

  /// Initialize session management
  Future<void> initialize({
    VoidCallback? onSessionExpired,
    VoidCallback? onInactivityTimeout,
  }) async {
    _onSessionExpired = onSessionExpired;
    _onInactivityTimeout = onInactivityTimeout;

    await _startSessionMonitoring();
  }

  /// Create a new session
  Future<SessionInfo> createSession(
    UserModel user, {
    int? durationMinutes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final sessionToken = _generateSessionToken();
      final deviceFingerprint = await _generateDeviceFingerprint();
      final expiryTime = DateTime.now().add(
        Duration(minutes: durationMinutes ?? defaultSessionDurationMinutes),
      );

      final sessionInfo = SessionInfo(
        token: sessionToken,
        userId: user.uid,
        deviceFingerprint: deviceFingerprint,
        createdAt: DateTime.now(),
        expiresAt: expiryTime,
        lastActivity: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _saveSession(sessionInfo);
      await _addToSessionHistory(sessionInfo);
      await _startSessionTimers(sessionInfo);

      return sessionInfo;
    } catch (e) {
      debugPrint('Error creating session: $e');
      rethrow;
    }
  }

  /// Validate current session
  Future<SessionValidationResult> validateSession() async {
    try {
      final sessionInfo = await getCurrentSession();
      if (sessionInfo == null) {
        return SessionValidationResult(
          isValid: false,
          reason: SessionInvalidReason.noSession,
        );
      }

      // Check if session is expired
      if (DateTime.now().isAfter(sessionInfo.expiresAt)) {
        await invalidateSession();
        return SessionValidationResult(
          isValid: false,
          reason: SessionInvalidReason.expired,
        );
      }

      // Check device fingerprint
      final currentFingerprint = await _generateDeviceFingerprint();
      if (currentFingerprint != sessionInfo.deviceFingerprint) {
        await invalidateSession();
        return SessionValidationResult(
          isValid: false,
          reason: SessionInvalidReason.deviceMismatch,
        );
      }

      // Check inactivity timeout
      final inactivityDuration =
          DateTime.now().difference(sessionInfo.lastActivity);
      if (inactivityDuration.inMinutes > maxInactivityMinutes) {
        await invalidateSession();
        return SessionValidationResult(
          isValid: false,
          reason: SessionInvalidReason.inactivityTimeout,
        );
      }

      // Update last activity
      await updateLastActivity();

      return SessionValidationResult(
        isValid: true,
        sessionInfo: sessionInfo,
      );
    } catch (e) {
      debugPrint('Error validating session: $e');
      return SessionValidationResult(
        isValid: false,
        reason: SessionInvalidReason.error,
      );
    }
  }

  /// Get current session info
  Future<SessionInfo?> getCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_sessionTokenKey);

      if (sessionData == null) return null;

      final sessionMap = json.decode(sessionData) as Map<String, dynamic>;
      return SessionInfo.fromMap(sessionMap);
    } catch (e) {
      debugPrint('Error getting current session: $e');
      return null;
    }
  }

  /// Update last activity timestamp
  Future<void> updateLastActivity() async {
    try {
      final sessionInfo = await getCurrentSession();
      if (sessionInfo == null) return;

      final updatedSession = sessionInfo.copyWith(
        lastActivity: DateTime.now(),
      );

      await _saveSession(updatedSession);
      _resetInactivityTimer();
    } catch (e) {
      debugPrint('Error updating last activity: $e');
    }
  }

  /// Extend session duration
  Future<bool> extendSession({int? additionalMinutes}) async {
    try {
      final sessionInfo = await getCurrentSession();
      if (sessionInfo == null) return false;

      final extension = Duration(minutes: additionalMinutes ?? 60);
      final newExpiryTime = sessionInfo.expiresAt.add(extension);

      final updatedSession = sessionInfo.copyWith(
        expiresAt: newExpiryTime,
        lastActivity: DateTime.now(),
      );

      await _saveSession(updatedSession);
      await _startSessionTimers(updatedSession);

      return true;
    } catch (e) {
      debugPrint('Error extending session: $e');
      return false;
    }
  }

  /// Invalidate current session
  Future<void> invalidateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionTokenKey);
      await prefs.remove(_sessionExpiryKey);
      await prefs.remove(_lastActivityKey);

      _cancelTimers();
    } catch (e) {
      debugPrint('Error invalidating session: $e');
    }
  }

  /// Get session history
  Future<List<SessionHistoryEntry>> getSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_sessionHistoryKey);

      if (historyJson == null) return [];

      final historyList = json.decode(historyJson) as List;
      return historyList
          .map((entry) =>
              SessionHistoryEntry.fromMap(entry as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting session history: $e');
      return [];
    }
  }

  /// Set auto-lock time
  Future<void> setAutoLockTime(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_autoLockTimeKey, minutes);
    } catch (e) {
      debugPrint('Error setting auto-lock time: $e');
    }
  }

  /// Get auto-lock time
  Future<int> getAutoLockTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_autoLockTimeKey) ?? maxInactivityMinutes;
    } catch (e) {
      debugPrint('Error getting auto-lock time: $e');
      return maxInactivityMinutes;
    }
  }

  /// Check if session should auto-lock
  Future<bool> shouldAutoLock() async {
    try {
      final sessionInfo = await getCurrentSession();
      if (sessionInfo == null) return false;

      final autoLockTime = await getAutoLockTime();
      final inactivityDuration =
          DateTime.now().difference(sessionInfo.lastActivity);

      return inactivityDuration.inMinutes >= autoLockTime;
    } catch (e) {
      debugPrint('Error checking auto-lock: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _cancelTimers();
  }

  // Private methods

  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final data = '$timestamp$random';
    return sha256.convert(utf8.encode(data)).toString();
  }

  Future<String> _generateDeviceFingerprint() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceId = '';
      String model = '';
      String os = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        model = androidInfo.model;
        os = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
        model = iosInfo.model;
        os = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }

      final fingerprintData = '$deviceId$model$os${packageInfo.version}';
      return sha256.convert(utf8.encode(fingerprintData)).toString();
    } catch (e) {
      debugPrint('Error generating device fingerprint: $e');
      return 'unknown_device';
    }
  }

  Future<void> _saveSession(SessionInfo sessionInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, json.encode(sessionInfo.toMap()));
    await prefs.setString(
        _sessionExpiryKey, sessionInfo.expiresAt.toIso8601String());
    await prefs.setString(
        _lastActivityKey, sessionInfo.lastActivity.toIso8601String());
  }

  Future<void> _addToSessionHistory(SessionInfo sessionInfo) async {
    try {
      final history = await getSessionHistory();

      final newEntry = SessionHistoryEntry(
        sessionToken: sessionInfo.token,
        userId: sessionInfo.userId,
        deviceFingerprint: sessionInfo.deviceFingerprint,
        startTime: sessionInfo.createdAt,
        endTime: null,
        metadata: sessionInfo.metadata,
      );

      history.insert(0, newEntry);

      // Keep only the last N entries
      final limitedHistory = history.take(maxSessionHistoryEntries).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sessionHistoryKey,
        json.encode(limitedHistory.map((e) => e.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('Error adding to session history: $e');
    }
  }

  Future<void> _startSessionMonitoring() async {
    final validation = await validateSession();
    if (validation.isValid && validation.sessionInfo != null) {
      await _startSessionTimers(validation.sessionInfo!);
    }
  }

  Future<void> _startSessionTimers(SessionInfo sessionInfo) async {
    _cancelTimers();

    // Session expiry timer
    final timeUntilExpiry = sessionInfo.expiresAt.difference(DateTime.now());
    if (timeUntilExpiry.isNegative) {
      _onSessionExpired?.call();
      return;
    }

    _sessionExpiryTimer = Timer(timeUntilExpiry, () {
      _onSessionExpired?.call();
    });

    // Inactivity timer
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(minutes: maxInactivityMinutes), () {
      _onInactivityTimeout?.call();
    });
  }

  void _cancelTimers() {
    _sessionExpiryTimer?.cancel();
    _inactivityTimer?.cancel();
  }
}

/// Session information model
class SessionInfo {
  final String token;
  final String userId;
  final String deviceFingerprint;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime lastActivity;
  final Map<String, dynamic> metadata;

  SessionInfo({
    required this.token,
    required this.userId,
    required this.deviceFingerprint,
    required this.createdAt,
    required this.expiresAt,
    required this.lastActivity,
    required this.metadata,
  });

  SessionInfo copyWith({
    String? token,
    String? userId,
    String? deviceFingerprint,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? lastActivity,
    Map<String, dynamic>? metadata,
  }) {
    return SessionInfo(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActivity: lastActivity ?? this.lastActivity,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'userId': userId,
      'deviceFingerprint': deviceFingerprint,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory SessionInfo.fromMap(Map<String, dynamic> map) {
    return SessionInfo(
      token: map['token'] ?? '',
      userId: map['userId'] ?? '',
      deviceFingerprint: map['deviceFingerprint'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt: DateTime.parse(map['expiresAt']),
      lastActivity: DateTime.parse(map['lastActivity']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// Session validation result
class SessionValidationResult {
  final bool isValid;
  final SessionInvalidReason? reason;
  final SessionInfo? sessionInfo;

  SessionValidationResult({
    required this.isValid,
    this.reason,
    this.sessionInfo,
  });
}

/// Session invalid reasons
enum SessionInvalidReason {
  noSession,
  expired,
  deviceMismatch,
  inactivityTimeout,
  error,
}

/// Session history entry
class SessionHistoryEntry {
  final String sessionToken;
  final String userId;
  final String deviceFingerprint;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> metadata;

  SessionHistoryEntry({
    required this.sessionToken,
    required this.userId,
    required this.deviceFingerprint,
    required this.startTime,
    this.endTime,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionToken': sessionToken,
      'userId': userId,
      'deviceFingerprint': deviceFingerprint,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory SessionHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SessionHistoryEntry(
      sessionToken: map['sessionToken'] ?? '',
      userId: map['userId'] ?? '',
      deviceFingerprint: map['deviceFingerprint'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// Session management service provider
final sessionManagementServiceProvider =
    Provider<SessionManagementService>((ref) {
  return SessionManagementService();
});
