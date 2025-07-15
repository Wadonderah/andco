import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

import '../providers/auth_provider.dart';
import 'firebase_service.dart';

/// Enhanced authentication service with biometric, 2FA, and security features
class EnhancedAuthService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _twoFactorEnabledKey = 'two_factor_enabled';
  static const String _lastLoginKey = 'last_login';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  static const String _passwordHistoryKey = 'password_history';
  
  static const int maxFailedAttempts = 5;
  static const int lockoutDurationMinutes = 30;
  static const int passwordHistoryLimit = 5;

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometricAuth() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Enable biometric authentication for secure login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricEnabledKey, true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error enabling biometric auth: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometricAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
      return false;
    }
  }

  /// Generate 2FA secret key
  String generate2FASecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(20, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Generate 2FA QR code data
  String generate2FAQRCode(String email, String secret) {
    final issuer = 'AndCo School Transport';
    final accountName = email;
    return 'otpauth://totp/$issuer:$accountName?secret=$secret&issuer=$issuer';
  }

  /// Enable 2FA
  Future<bool> enable2FA(String secret, String verificationCode) async {
    try {
      // Verify the code first
      final isValid = verify2FACode(secret, verificationCode);
      if (!isValid) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_twoFactorEnabledKey, true);
      await prefs.setString('2fa_secret', secret);
      
      return true;
    } catch (e) {
      debugPrint('Error enabling 2FA: $e');
      return false;
    }
  }

  /// Disable 2FA
  Future<void> disable2FA() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_twoFactorEnabledKey, false);
    await prefs.remove('2fa_secret');
  }

  /// Check if 2FA is enabled
  Future<bool> is2FAEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_twoFactorEnabledKey) ?? false;
  }

  /// Verify 2FA code
  bool verify2FACode(String secret, String code) {
    try {
      // Simple TOTP implementation (in production, use a proper library)
      final timeStep = (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ 30;
      final expectedCode = _generateTOTP(secret, timeStep);
      return code == expectedCode;
    } catch (e) {
      debugPrint('Error verifying 2FA code: $e');
      return false;
    }
  }

  /// Generate TOTP code (simplified implementation)
  String _generateTOTP(String secret, int timeStep) {
    // This is a simplified implementation
    // In production, use a proper TOTP library
    final hash = sha256.convert(utf8.encode('$secret$timeStep'));
    final code = hash.toString().substring(0, 6);
    return code.padLeft(6, '0');
  }

  /// Check password strength
  PasswordStrength checkPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Validate password against history
  Future<bool> isPasswordInHistory(String userId, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('${_passwordHistoryKey}_$userId');
      if (historyJson == null) return false;

      final history = List<String>.from(json.decode(historyJson));
      final hashedPassword = sha256.convert(utf8.encode(newPassword)).toString();
      
      return history.contains(hashedPassword);
    } catch (e) {
      debugPrint('Error checking password history: $e');
      return false;
    }
  }

  /// Add password to history
  Future<void> addPasswordToHistory(String userId, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = '${_passwordHistoryKey}_$userId';
      final historyJson = prefs.getString(historyKey);
      
      List<String> history = [];
      if (historyJson != null) {
        history = List<String>.from(json.decode(historyJson));
      }
      
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      history.insert(0, hashedPassword);
      
      // Keep only the last N passwords
      if (history.length > passwordHistoryLimit) {
        history = history.take(passwordHistoryLimit).toList();
      }
      
      await prefs.setString(historyKey, json.encode(history));
    } catch (e) {
      debugPrint('Error adding password to history: $e');
    }
  }

  /// Record failed login attempt
  Future<void> recordFailedAttempt(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptsKey = '${_failedAttemptsKey}_$userId';
      final attempts = prefs.getInt(attemptsKey) ?? 0;
      
      await prefs.setInt(attemptsKey, attempts + 1);
      
      if (attempts + 1 >= maxFailedAttempts) {
        final lockoutTime = DateTime.now().add(const Duration(minutes: lockoutDurationMinutes));
        await prefs.setString('${_lockoutTimeKey}_$userId', lockoutTime.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error recording failed attempt: $e');
    }
  }

  /// Clear failed attempts
  Future<void> clearFailedAttempts(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_failedAttemptsKey}_$userId');
      await prefs.remove('${_lockoutTimeKey}_$userId');
    } catch (e) {
      debugPrint('Error clearing failed attempts: $e');
    }
  }

  /// Check if account is locked
  Future<bool> isAccountLocked(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutTimeStr = prefs.getString('${_lockoutTimeKey}_$userId');
      
      if (lockoutTimeStr == null) return false;
      
      final lockoutTime = DateTime.parse(lockoutTimeStr);
      return DateTime.now().isBefore(lockoutTime);
    } catch (e) {
      debugPrint('Error checking account lock: $e');
      return false;
    }
  }

  /// Get remaining lockout time
  Future<Duration?> getRemainingLockoutTime(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutTimeStr = prefs.getString('${_lockoutTimeKey}_$userId');
      
      if (lockoutTimeStr == null) return null;
      
      final lockoutTime = DateTime.parse(lockoutTimeStr);
      final now = DateTime.now();
      
      if (now.isBefore(lockoutTime)) {
        return lockoutTime.difference(now);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting remaining lockout time: $e');
      return null;
    }
  }

  /// Record successful login
  Future<void> recordSuccessfulLogin(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_lastLoginKey}_$userId', DateTime.now().toIso8601String());
      await clearFailedAttempts(userId);
    } catch (e) {
      debugPrint('Error recording successful login: $e');
    }
  }

  /// Get last login time
  Future<DateTime?> getLastLoginTime(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginStr = prefs.getString('${_lastLoginKey}_$userId');
      
      if (lastLoginStr == null) return null;
      return DateTime.parse(lastLoginStr);
    } catch (e) {
      debugPrint('Error getting last login time: $e');
      return null;
    }
  }
}

/// Password strength enum
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Enhanced auth service provider
final enhancedAuthServiceProvider = Provider<EnhancedAuthService>((ref) {
  return EnhancedAuthService();
});
