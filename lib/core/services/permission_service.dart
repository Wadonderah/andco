import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_service.dart';

/// Service for managing app permissions
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  static PermissionService get instance => _instance;
  PermissionService._internal();

  /// Check and request location permission
  Future<PermissionResult> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await FirebaseService.instance.logEvent('location_service_disabled', {
          'timestamp': DateTime.now().toIso8601String(),
        });
        return PermissionResult(
          isGranted: false,
          isDenied: true,
          isPermanentlyDenied: false,
          message: 'Location services are disabled. Please enable location services in your device settings.',
        );
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
      }

      final result = _mapLocationPermissionToResult(permission);
      
      // Log permission result
      await FirebaseService.instance.logEvent('location_permission_requested', {
        'result': result.isGranted ? 'granted' : 'denied',
        'permanently_denied': result.isPermanentlyDenied,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Location permission request failed');
      
      return PermissionResult(
        isGranted: false,
        isDenied: true,
        isPermanentlyDenied: false,
        message: 'Failed to request location permission: $e',
      );
    }
  }

  /// Check and request notification permission
  Future<PermissionResult> requestNotificationPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                       settings.authorizationStatus == AuthorizationStatus.provisional;

      final result = PermissionResult(
        isGranted: isGranted,
        isDenied: !isGranted,
        isPermanentlyDenied: settings.authorizationStatus == AuthorizationStatus.denied,
        message: isGranted 
            ? 'Notification permission granted'
            : 'Notification permission denied. You can enable it later in app settings.',
      );

      // Log permission result
      await FirebaseService.instance.logEvent('notification_permission_requested', {
        'result': isGranted ? 'granted' : 'denied',
        'authorization_status': settings.authorizationStatus.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Notification permission request failed');
      
      return PermissionResult(
        isGranted: false,
        isDenied: true,
        isPermanentlyDenied: false,
        message: 'Failed to request notification permission: $e',
      );
    }
  }

  /// Check and request camera permission (for QR code scanning, profile photos)
  Future<PermissionResult> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      final result = _mapPermissionStatusToResult(status, 'camera');
      
      // Log permission result
      await FirebaseService.instance.logEvent('camera_permission_requested', {
        'result': result.isGranted ? 'granted' : 'denied',
        'permanently_denied': result.isPermanentlyDenied,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Camera permission request failed');
      
      return PermissionResult(
        isGranted: false,
        isDenied: true,
        isPermanentlyDenied: false,
        message: 'Failed to request camera permission: $e',
      );
    }
  }

  /// Check and request microphone permission (for voice features)
  Future<PermissionResult> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      final result = _mapPermissionStatusToResult(status, 'microphone');
      
      // Log permission result
      await FirebaseService.instance.logEvent('microphone_permission_requested', {
        'result': result.isGranted ? 'granted' : 'denied',
        'permanently_denied': result.isPermanentlyDenied,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result;
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Microphone permission request failed');
      
      return PermissionResult(
        isGranted: false,
        isDenied: true,
        isPermanentlyDenied: false,
        message: 'Failed to request microphone permission: $e',
      );
    }
  }

  /// Check and request storage permission (for file uploads/downloads)
  Future<PermissionResult> requestStoragePermission() async {
    try {
      final status = await Permission.storage.request();
      final result = _mapPermissionStatusToResult(status, 'storage');
      
      // Log permission result
      await FirebaseService.instance.logEvent('storage_permission_requested', {
        'result': result.isGranted ? 'granted' : 'denied',
        'permanently_denied': result.isPermanentlyDenied,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result;
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Storage permission request failed');
      
      return PermissionResult(
        isGranted: false,
        isDenied: true,
        isPermanentlyDenied: false,
        message: 'Failed to request storage permission: $e',
      );
    }
  }

  /// Request all essential permissions
  Future<Map<String, PermissionResult>> requestEssentialPermissions() async {
    final results = <String, PermissionResult>{};
    
    try {
      // Request location permission (essential for tracking)
      results['location'] = await requestLocationPermission();
      
      // Request notification permission (essential for alerts)
      results['notification'] = await requestNotificationPermission();
      
      // Log overall permission request
      await FirebaseService.instance.logEvent('essential_permissions_requested', {
        'location_granted': results['location']?.isGranted ?? false,
        'notification_granted': results['notification']?.isGranted ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return results;
    } catch (e) {
      debugPrint('Error requesting essential permissions: $e');
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Essential permissions request failed');
      
      return results;
    }
  }

  /// Check if all essential permissions are granted
  Future<bool> areEssentialPermissionsGranted() async {
    try {
      // Check location permission
      final locationPermission = await Geolocator.checkPermission();
      final isLocationGranted = locationPermission == LocationPermission.always ||
                               locationPermission == LocationPermission.whileInUse;
      
      // Check notification permission
      final messaging = FirebaseMessaging.instance;
      final notificationSettings = await messaging.getNotificationSettings();
      final isNotificationGranted = notificationSettings.authorizationStatus == AuthorizationStatus.authorized ||
                                   notificationSettings.authorizationStatus == AuthorizationStatus.provisional;
      
      return isLocationGranted && isNotificationGranted;
    } catch (e) {
      debugPrint('Error checking essential permissions: $e');
      return false;
    }
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    try {
      final opened = await openAppSettings();
      
      await FirebaseService.instance.logEvent('app_settings_opened', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return opened;
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  /// Map LocationPermission to PermissionResult
  PermissionResult _mapLocationPermissionToResult(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return PermissionResult(
          isGranted: true,
          isDenied: false,
          isPermanentlyDenied: false,
          message: 'Location permission granted',
        );
      case LocationPermission.denied:
        return PermissionResult(
          isGranted: false,
          isDenied: true,
          isPermanentlyDenied: false,
          message: 'Location permission denied. You can grant it later in app settings.',
        );
      case LocationPermission.deniedForever:
        return PermissionResult(
          isGranted: false,
          isDenied: true,
          isPermanentlyDenied: true,
          message: 'Location permission permanently denied. Please enable it in device settings.',
        );
      case LocationPermission.unableToDetermine:
        return PermissionResult(
          isGranted: false,
          isDenied: true,
          isPermanentlyDenied: false,
          message: 'Unable to determine location permission status.',
        );
    }
  }

  /// Map PermissionStatus to PermissionResult
  PermissionResult _mapPermissionStatusToResult(PermissionStatus status, String permissionType) {
    switch (status) {
      case PermissionStatus.granted:
        return PermissionResult(
          isGranted: true,
          isDenied: false,
          isPermanentlyDenied: false,
          message: '$permissionType permission granted',
        );
      case PermissionStatus.denied:
        return PermissionResult(
          isGranted: false,
          isDenied: true,
          isPermanentlyDenied: false,
          message: '$permissionType permission denied. You can grant it later in app settings.',
        );
      case PermissionStatus.permanentlyDenied:
        return PermissionResult(
          isGranted: false,
          isDenied: true,
          isPermanentlyDenied: true,
          message: '$permissionType permission permanently denied. Please enable it in device settings.',
        );
      case PermissionStatus.restricted:
        return PermissionResult(
          isGranted: false,
          isDenied: true,
          isPermanentlyDenied: true,
          message: '$permissionType permission is restricted on this device.',
        );
      case PermissionStatus.limited:
        return PermissionResult(
          isGranted: true,
          isDenied: false,
          isPermanentlyDenied: false,
          message: '$permissionType permission granted with limitations',
        );
      case PermissionStatus.provisional:
        return PermissionResult(
          isGranted: true,
          isDenied: false,
          isPermanentlyDenied: false,
          message: '$permissionType permission granted provisionally',
        );
    }
  }
}

/// Permission result model
class PermissionResult {
  final bool isGranted;
  final bool isDenied;
  final bool isPermanentlyDenied;
  final String message;

  const PermissionResult({
    required this.isGranted,
    required this.isDenied,
    required this.isPermanentlyDenied,
    required this.message,
  });

  @override
  String toString() {
    return 'PermissionResult(isGranted: $isGranted, isDenied: $isDenied, isPermanentlyDenied: $isPermanentlyDenied, message: $message)';
  }
}
