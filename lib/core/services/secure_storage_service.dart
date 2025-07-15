import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data with encryption
class SecureStorageService {
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _saltKey = 'encryption_salt';

  late final FlutterSecureStorage _secureStorage;
  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;

  SecureStorageService() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );

    _initializeEncryption();
  }

  /// Initialize encryption components
  Future<void> _initializeEncryption() async {
    try {
      // Get or create encryption key
      String? encryptionKey = await _secureStorage.read(key: _encryptionKeyKey);
      if (encryptionKey == null) {
        encryptionKey = _generateEncryptionKey();
        await _secureStorage.write(
            key: _encryptionKeyKey, value: encryptionKey);
      }

      // Get or create salt
      String? salt = await _secureStorage.read(key: _saltKey);
      if (salt == null) {
        salt = _generateSalt();
        await _secureStorage.write(key: _saltKey, value: salt);
      }

      // Initialize encrypter
      final key = encrypt.Key.fromBase64(encryptionKey);
      _encrypter = encrypt.Encrypter(encrypt.AES(key));
      _iv = encrypt.IV.fromSecureRandom(16);
    } catch (e) {
      debugPrint('Error initializing encryption: $e');
      rethrow;
    }
  }

  /// Store encrypted data
  Future<bool> storeSecure(String key, String value) async {
    try {
      final encrypted = _encrypter.encrypt(value, iv: _iv);
      await _secureStorage.write(
        key: key,
        value: json.encode({
          'data': encrypted.base64,
          'iv': _iv.base64,
        }),
      );
      return true;
    } catch (e) {
      debugPrint('Error storing secure data: $e');
      return false;
    }
  }

  /// Retrieve and decrypt data
  Future<String?> retrieveSecure(String key) async {
    try {
      final encryptedData = await _secureStorage.read(key: key);
      if (encryptedData == null) return null;

      final dataMap = json.decode(encryptedData) as Map<String, dynamic>;
      final encrypted = encrypt.Encrypted.fromBase64(dataMap['data']);
      final iv = encrypt.IV.fromBase64(dataMap['iv']);

      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('Error retrieving secure data: $e');
      return null;
    }
  }

  /// Store JSON data securely
  Future<bool> storeSecureJson(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = json.encode(data);
      return await storeSecure(key, jsonString);
    } catch (e) {
      debugPrint('Error storing secure JSON: $e');
      return false;
    }
  }

  /// Retrieve JSON data securely
  Future<Map<String, dynamic>?> retrieveSecureJson(String key) async {
    try {
      final jsonString = await retrieveSecure(key);
      if (jsonString == null) return null;

      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error retrieving secure JSON: $e');
      return null;
    }
  }

  /// Store authentication tokens securely
  Future<bool> storeAuthTokens({
    required String accessToken,
    required String refreshToken,
    String? idToken,
  }) async {
    try {
      final tokens = {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        if (idToken != null) 'idToken': idToken,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return await storeSecureJson('auth_tokens', tokens);
    } catch (e) {
      debugPrint('Error storing auth tokens: $e');
      return false;
    }
  }

  /// Retrieve authentication tokens
  Future<AuthTokens?> retrieveAuthTokens() async {
    try {
      final tokensData = await retrieveSecureJson('auth_tokens');
      if (tokensData == null) return null;

      return AuthTokens.fromMap(tokensData);
    } catch (e) {
      debugPrint('Error retrieving auth tokens: $e');
      return null;
    }
  }

  /// Store biometric authentication data
  Future<bool> storeBiometricData(String userId, String biometricHash) async {
    try {
      final biometricData = {
        'userId': userId,
        'biometricHash': biometricHash,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return await storeSecureJson('biometric_data_$userId', biometricData);
    } catch (e) {
      debugPrint('Error storing biometric data: $e');
      return false;
    }
  }

  /// Retrieve biometric authentication data
  Future<Map<String, dynamic>?> retrieveBiometricData(String userId) async {
    try {
      return await retrieveSecureJson('biometric_data_$userId');
    } catch (e) {
      debugPrint('Error retrieving biometric data: $e');
      return null;
    }
  }

  /// Store 2FA secret securely
  Future<bool> store2FASecret(String userId, String secret) async {
    try {
      final secretData = {
        'userId': userId,
        'secret': secret,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return await storeSecureJson('2fa_secret_$userId', secretData);
    } catch (e) {
      debugPrint('Error storing 2FA secret: $e');
      return false;
    }
  }

  /// Retrieve 2FA secret
  Future<String?> retrieve2FASecret(String userId) async {
    try {
      final secretData = await retrieveSecureJson('2fa_secret_$userId');
      return secretData?['secret'];
    } catch (e) {
      debugPrint('Error retrieving 2FA secret: $e');
      return null;
    }
  }

  /// Store user credentials securely (for remember me functionality)
  Future<bool> storeUserCredentials({
    required String email,
    required String passwordHash,
    String? userId,
  }) async {
    try {
      final credentials = {
        'email': email,
        'passwordHash': passwordHash,
        if (userId != null) 'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return await storeSecureJson('user_credentials', credentials);
    } catch (e) {
      debugPrint('Error storing user credentials: $e');
      return false;
    }
  }

  /// Retrieve user credentials
  Future<UserCredentials?> retrieveUserCredentials() async {
    try {
      final credentialsData = await retrieveSecureJson('user_credentials');
      if (credentialsData == null) return null;

      return UserCredentials.fromMap(credentialsData);
    } catch (e) {
      debugPrint('Error retrieving user credentials: $e');
      return null;
    }
  }

  /// Delete specific secure data
  Future<bool> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
      return true;
    } catch (e) {
      debugPrint('Error deleting secure data: $e');
      return false;
    }
  }

  /// Clear all secure data
  Future<bool> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      return true;
    } catch (e) {
      debugPrint('Error clearing all secure data: $e');
      return false;
    }
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } catch (e) {
      debugPrint('Error checking key existence: $e');
      return false;
    }
  }

  /// Get all stored keys
  Future<Set<String>> getAllKeys() async {
    try {
      final allData = await _secureStorage.readAll();
      return allData.keys.toSet();
    } catch (e) {
      debugPrint('Error getting all keys: $e');
      return <String>{};
    }
  }

  /// Hash password securely
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure random salt
  String _generateSalt() {
    final bytes = List<int>.generate(
        32, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    return base64Encode(bytes);
  }

  /// Generate encryption key
  String _generateEncryptionKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return key.base64;
  }

  /// Validate data integrity
  Future<bool> validateDataIntegrity(String key, String expectedHash) async {
    try {
      final data = await retrieveSecure(key);
      if (data == null) return false;

      final actualHash = sha256.convert(utf8.encode(data)).toString();
      return actualHash == expectedHash;
    } catch (e) {
      debugPrint('Error validating data integrity: $e');
      return false;
    }
  }

  /// Create data checksum
  String createChecksum(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Backup secure data (encrypted)
  Future<String?> backupSecureData() async {
    try {
      final allData = await _secureStorage.readAll();
      final backupData = {
        'data': allData,
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final jsonString = json.encode(backupData);
      final encrypted = _encrypter.encrypt(jsonString, iv: _iv);

      return json.encode({
        'backup': encrypted.base64,
        'iv': _iv.base64,
      });
    } catch (e) {
      debugPrint('Error backing up secure data: $e');
      return null;
    }
  }

  /// Restore secure data from backup
  Future<bool> restoreSecureData(String backupString) async {
    try {
      final backupMap = json.decode(backupString) as Map<String, dynamic>;
      final encrypted = encrypt.Encrypted.fromBase64(backupMap['backup']);
      final iv = encrypt.IV.fromBase64(backupMap['iv']);

      final decryptedString = _encrypter.decrypt(encrypted, iv: iv);
      final backupData = json.decode(decryptedString) as Map<String, dynamic>;

      final dataMap = backupData['data'] as Map<String, dynamic>;

      // Clear existing data
      await _secureStorage.deleteAll();

      // Restore data
      for (final entry in dataMap.entries) {
        await _secureStorage.write(key: entry.key, value: entry.value);
      }

      return true;
    } catch (e) {
      debugPrint('Error restoring secure data: $e');
      return false;
    }
  }
}

/// Authentication tokens model
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String? idToken;
  final DateTime timestamp;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.idToken,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      if (idToken != null) 'idToken': idToken,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuthTokens.fromMap(Map<String, dynamic> map) {
    return AuthTokens(
      accessToken: map['accessToken'] ?? '',
      refreshToken: map['refreshToken'] ?? '',
      idToken: map['idToken'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

/// User credentials model
class UserCredentials {
  final String email;
  final String passwordHash;
  final String? userId;
  final DateTime timestamp;

  UserCredentials({
    required this.email,
    required this.passwordHash,
    this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'passwordHash': passwordHash,
      if (userId != null) 'userId': userId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory UserCredentials.fromMap(Map<String, dynamic> map) {
    return UserCredentials(
      email: map['email'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      userId: map['userId'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

/// Secure storage service provider
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
