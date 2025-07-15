import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user_model.dart';
import '../providers/firebase_providers.dart';
import '../repositories/child_repository.dart';
import 'enhanced_auth_service.dart';
import 'secure_storage_service.dart';
import 'session_management_service.dart';

/// Comprehensive authentication validation service
class AuthValidationService {
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 30;
  static const int passwordMinLength = 8;
  static const int passwordMaxAge = 90; // days
  static const int sessionTimeoutMinutes = 30;

  final EnhancedAuthService _enhancedAuthService;
  final SessionManagementService _sessionService;
  final SecureStorageService _secureStorage;
  final ChildRepository _childRepository;

  AuthValidationService({
    required EnhancedAuthService enhancedAuthService,
    required SessionManagementService sessionService,
    required SecureStorageService secureStorage,
    required ChildRepository childRepository,
  })  : _enhancedAuthService = enhancedAuthService,
        _sessionService = sessionService,
        _secureStorage = secureStorage,
        _childRepository = childRepository;

  /// Validate user credentials with comprehensive security checks
  Future<AuthValidationResult> validateCredentials({
    required String email,
    required String password,
    String? twoFactorCode,
    bool requireBiometric = false,
  }) async {
    try {
      // Step 1: Basic input validation
      final inputValidation = _validateInput(email, password);
      if (!inputValidation.isValid) {
        return inputValidation;
      }

      // Step 2: Check account lockout
      final isLocked = await _enhancedAuthService.isAccountLocked(email);
      if (isLocked) {
        final remainingTime =
            await _enhancedAuthService.getRemainingLockoutTime(email);
        return AuthValidationResult(
          isValid: false,
          errorCode: AuthErrorCode.accountLocked,
          message:
              'Account is locked. Try again in ${remainingTime?.inMinutes ?? 0} minutes.',
        );
      }

      // Step 3: Validate password strength
      final passwordStrength =
          _enhancedAuthService.checkPasswordStrength(password);
      if (passwordStrength == PasswordStrength.weak) {
        return AuthValidationResult(
          isValid: false,
          errorCode: AuthErrorCode.weakPassword,
          message: 'Password does not meet security requirements.',
        );
      }

      // Step 4: Check password history (for password changes)
      final isInHistory =
          await _enhancedAuthService.isPasswordInHistory(email, password);
      if (isInHistory) {
        return AuthValidationResult(
          isValid: false,
          errorCode: AuthErrorCode.passwordReused,
          message:
              'This password was used recently. Please choose a different password.',
        );
      }

      // Step 5: Validate 2FA if enabled
      final is2FAEnabled = await _enhancedAuthService.is2FAEnabled();
      if (is2FAEnabled) {
        if (twoFactorCode == null || twoFactorCode.isEmpty) {
          return AuthValidationResult(
            isValid: false,
            errorCode: AuthErrorCode.twoFactorRequired,
            message: 'Two-factor authentication code is required.',
          );
        }

        final secret = await _secureStorage.retrieve2FASecret(email);
        if (secret == null ||
            !_enhancedAuthService.verify2FACode(secret, twoFactorCode)) {
          await _enhancedAuthService.recordFailedAttempt(email);
          return AuthValidationResult(
            isValid: false,
            errorCode: AuthErrorCode.invalidTwoFactor,
            message: 'Invalid two-factor authentication code.',
          );
        }
      }

      // Step 6: Validate biometric if required
      if (requireBiometric) {
        final biometricResult =
            await _enhancedAuthService.authenticateWithBiometrics();
        if (!biometricResult) {
          return AuthValidationResult(
            isValid: false,
            errorCode: AuthErrorCode.biometricFailed,
            message: 'Biometric authentication failed.',
          );
        }
      }

      // Step 7: Record successful authentication
      await _enhancedAuthService.recordSuccessfulLogin(email);

      return AuthValidationResult(
        isValid: true,
        message: 'Authentication successful.',
      );
    } catch (e) {
      debugPrint('Error validating credentials: $e');
      return AuthValidationResult(
        isValid: false,
        errorCode: AuthErrorCode.systemError,
        message: 'System error occurred during authentication.',
      );
    }
  }

  /// Validate session and refresh if needed
  Future<SessionValidationResult> validateAndRefreshSession() async {
    try {
      final validation = await _sessionService.validateSession();

      if (!validation.isValid) {
        return validation;
      }

      // Check if session needs refresh (within 1 hour of expiry)
      final sessionInfo = validation.sessionInfo!;
      final timeUntilExpiry = sessionInfo.expiresAt.difference(DateTime.now());

      if (timeUntilExpiry.inHours <= 1) {
        final extended =
            await _sessionService.extendSession(additionalMinutes: 60);
        if (!extended) {
          return SessionValidationResult(
            isValid: false,
            reason: SessionInvalidReason.error,
          );
        }
      }

      return validation;
    } catch (e) {
      debugPrint('Error validating session: $e');
      return SessionValidationResult(
        isValid: false,
        reason: SessionInvalidReason.error,
      );
    }
  }

  /// Validate password change request
  Future<PasswordChangeValidationResult> validatePasswordChange({
    required String userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // Step 1: Validate new password matches confirmation
      if (newPassword != confirmPassword) {
        return PasswordChangeValidationResult(
          isValid: false,
          errorCode: PasswordChangeErrorCode.passwordMismatch,
          message: 'New password and confirmation do not match.',
        );
      }

      // Step 2: Validate new password strength
      final passwordStrength =
          _enhancedAuthService.checkPasswordStrength(newPassword);
      if (passwordStrength == PasswordStrength.weak) {
        return PasswordChangeValidationResult(
          isValid: false,
          errorCode: PasswordChangeErrorCode.weakPassword,
          message: 'New password does not meet security requirements.',
        );
      }

      // Step 3: Check password history
      final isInHistory =
          await _enhancedAuthService.isPasswordInHistory(userId, newPassword);
      if (isInHistory) {
        return PasswordChangeValidationResult(
          isValid: false,
          errorCode: PasswordChangeErrorCode.passwordReused,
          message:
              'This password was used recently. Please choose a different password.',
        );
      }

      // Step 4: Validate current password (this would typically involve Firebase Auth)
      // For now, we'll assume it's valid if provided
      if (currentPassword.isEmpty) {
        return PasswordChangeValidationResult(
          isValid: false,
          errorCode: PasswordChangeErrorCode.currentPasswordRequired,
          message: 'Current password is required.',
        );
      }

      return PasswordChangeValidationResult(
        isValid: true,
        message: 'Password change validation successful.',
      );
    } catch (e) {
      debugPrint('Error validating password change: $e');
      return PasswordChangeValidationResult(
        isValid: false,
        errorCode: PasswordChangeErrorCode.systemError,
        message: 'System error occurred during password validation.',
      );
    }
  }

  /// Validate user permissions for specific actions
  Future<PermissionValidationResult> validatePermissions({
    required UserModel user,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Define role-based permissions
      final permissions = _getRolePermissions(user.role);

      if (!permissions.contains(action)) {
        return PermissionValidationResult(
          isValid: false,
          errorCode: PermissionErrorCode.insufficientPermissions,
          message: 'You do not have permission to perform this action.',
        );
      }

      // Additional context-based validation
      if (context != null) {
        final contextValidation =
            await _validateActionContext(user, action, context);
        if (!contextValidation.isValid) {
          return contextValidation;
        }
      }

      return PermissionValidationResult(
        isValid: true,
        message: 'Permission validation successful.',
      );
    } catch (e) {
      debugPrint('Error validating permissions: $e');
      return PermissionValidationResult(
        isValid: false,
        errorCode: PermissionErrorCode.systemError,
        message: 'System error occurred during permission validation.',
      );
    }
  }

  /// Validate device security
  Future<DeviceSecurityValidationResult> validateDeviceSecurity() async {
    try {
      final results = <String, bool>{};

      // Check if device has screen lock
      results['screenLock'] = await _checkScreenLock();

      // Check if device is rooted/jailbroken
      results['deviceIntegrity'] = await _checkDeviceIntegrity();

      // Check if app is running in debug mode
      results['debugMode'] = !_isReleaseMode();

      // Check if device has biometric capabilities
      results['biometricCapable'] =
          await _enhancedAuthService.isBiometricAvailable();

      final securityScore = _calculateSecurityScore(results);

      return DeviceSecurityValidationResult(
        isSecure: securityScore >= 0.7, // 70% threshold
        securityScore: securityScore,
        checks: results,
        recommendations: _getSecurityRecommendations(results),
      );
    } catch (e) {
      debugPrint('Error validating device security: $e');
      return DeviceSecurityValidationResult(
        isSecure: false,
        securityScore: 0.0,
        checks: {},
        recommendations: ['Unable to validate device security'],
      );
    }
  }

  // Private helper methods

  AuthValidationResult _validateInput(String email, String password) {
    if (email.isEmpty) {
      return AuthValidationResult(
        isValid: false,
        errorCode: AuthErrorCode.invalidEmail,
        message: 'Email is required.',
      );
    }

    if (!_isValidEmail(email)) {
      return AuthValidationResult(
        isValid: false,
        errorCode: AuthErrorCode.invalidEmail,
        message: 'Please enter a valid email address.',
      );
    }

    if (password.isEmpty) {
      return AuthValidationResult(
        isValid: false,
        errorCode: AuthErrorCode.invalidPassword,
        message: 'Password is required.',
      );
    }

    if (password.length < passwordMinLength) {
      return AuthValidationResult(
        isValid: false,
        errorCode: AuthErrorCode.invalidPassword,
        message:
            'Password must be at least $passwordMinLength characters long.',
      );
    }

    return AuthValidationResult(
      isValid: true,
      message: 'Input validation successful.',
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  Set<String> _getRolePermissions(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return {
          'view_children',
          'view_trips',
          'make_payments',
          'view_notifications',
          'update_profile',
        };
      case UserRole.driver:
        return {
          'view_routes',
          'update_trip_status',
          'view_students',
          'emergency_contact',
          'view_schedule',
        };
      case UserRole.schoolAdmin:
        return {
          'manage_students',
          'manage_routes',
          'view_reports',
          'manage_drivers',
          'view_payments',
          'send_notifications',
        };
      case UserRole.superAdmin:
        return {
          'manage_schools',
          'manage_users',
          'view_analytics',
          'system_settings',
          'financial_reports',
          'user_moderation',
        };
    }
  }

  Future<PermissionValidationResult> _validateActionContext(
    UserModel user,
    String action,
    Map<String, dynamic> context,
  ) async {
    // Context-specific validation logic
    // For example, ensure a parent can only view their own children
    if (action == 'view_children' && user.role == UserRole.parent) {
      final childId = context['childId'] as String?;
      if (childId != null) {
        // Check if the child belongs to this parent by querying the child repository
        try {
          final child = await _childRepository.getById(childId);
          if (child == null || child.parentId != user.uid) {
            return PermissionValidationResult(
              isValid: false,
              errorCode: PermissionErrorCode.accessDenied,
              message: 'You can only access your own children\'s information.',
            );
          }
        } catch (e) {
          return PermissionValidationResult(
            isValid: false,
            errorCode: PermissionErrorCode.systemError,
            message: 'Unable to validate child access permissions.',
          );
        }
      }
    }

    return PermissionValidationResult(
      isValid: true,
      message: 'Context validation successful.',
    );
  }

  Future<bool> _checkScreenLock() async {
    // This would typically use platform-specific code
    // For now, return true as a placeholder
    return true;
  }

  Future<bool> _checkDeviceIntegrity() async {
    // This would check for root/jailbreak
    // For now, return true as a placeholder
    return true;
  }

  bool _isReleaseMode() {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return !inDebugMode;
  }

  double _calculateSecurityScore(Map<String, bool> checks) {
    if (checks.isEmpty) return 0.0;

    final passedChecks = checks.values.where((passed) => passed).length;
    return passedChecks / checks.length;
  }

  List<String> _getSecurityRecommendations(Map<String, bool> checks) {
    final recommendations = <String>[];

    if (checks['screenLock'] == false) {
      recommendations.add('Enable screen lock on your device');
    }

    if (checks['deviceIntegrity'] == false) {
      recommendations.add('Use a non-rooted/non-jailbroken device');
    }

    if (checks['biometricCapable'] == false) {
      recommendations
          .add('Consider using a device with biometric capabilities');
    }

    return recommendations;
  }
}

/// Authentication validation result
class AuthValidationResult {
  final bool isValid;
  final AuthErrorCode? errorCode;
  final String message;

  AuthValidationResult({
    required this.isValid,
    this.errorCode,
    required this.message,
  });
}

/// Password change validation result
class PasswordChangeValidationResult {
  final bool isValid;
  final PasswordChangeErrorCode? errorCode;
  final String message;

  PasswordChangeValidationResult({
    required this.isValid,
    this.errorCode,
    required this.message,
  });
}

/// Permission validation result
class PermissionValidationResult {
  final bool isValid;
  final PermissionErrorCode? errorCode;
  final String message;

  PermissionValidationResult({
    required this.isValid,
    this.errorCode,
    required this.message,
  });
}

/// Device security validation result
class DeviceSecurityValidationResult {
  final bool isSecure;
  final double securityScore;
  final Map<String, bool> checks;
  final List<String> recommendations;

  DeviceSecurityValidationResult({
    required this.isSecure,
    required this.securityScore,
    required this.checks,
    required this.recommendations,
  });
}

/// Authentication error codes
enum AuthErrorCode {
  invalidEmail,
  invalidPassword,
  accountLocked,
  weakPassword,
  passwordReused,
  twoFactorRequired,
  invalidTwoFactor,
  biometricFailed,
  systemError,
}

/// Password change error codes
enum PasswordChangeErrorCode {
  passwordMismatch,
  weakPassword,
  passwordReused,
  currentPasswordRequired,
  systemError,
}

/// Permission error codes
enum PermissionErrorCode {
  insufficientPermissions,
  accessDenied,
  systemError,
}

/// Auth validation service provider
final authValidationServiceProvider = Provider<AuthValidationService>((ref) {
  return AuthValidationService(
    enhancedAuthService: ref.read(enhancedAuthServiceProvider),
    sessionService: ref.read(sessionManagementServiceProvider),
    secureStorage: ref.read(secureStorageServiceProvider),
    childRepository: ref.read(childRepositoryProvider),
  );
});
