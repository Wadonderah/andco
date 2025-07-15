import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'firebase_service.dart';

/// SMS service supporting both Twilio and Africa's Talking
class SmsService {
  static SmsService? _instance;
  static SmsService get instance => _instance ??= SmsService._();

  SmsService._();

  // Twilio configuration
  static const String _twilioAccountSid = 'your_twilio_account_sid';
  static const String _twilioAuthToken = 'your_twilio_auth_token';
  static const String _twilioPhoneNumber = 'your_twilio_phone_number';
  static const String _twilioBaseUrl = 'https://api.twilio.com/2010-04-01';

  // Africa's Talking configuration
  static const String _atApiKey = 'your_africas_talking_api_key';
  static const String _atUsername = 'your_africas_talking_username';
  static const String _atSenderId = 'your_sender_id';
  static const String _atBaseUrl = 'https://api.africastalking.com/version1';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SmsProvider _primaryProvider = SmsProvider.twilio;
  SmsProvider _fallbackProvider = SmsProvider.africasTalking;

  /// Initialize SMS service
  Future<void> initialize({
    SmsProvider primaryProvider = SmsProvider.twilio,
    SmsProvider fallbackProvider = SmsProvider.africasTalking,
  }) async {
    if (_isInitialized) return;

    try {
      _primaryProvider = primaryProvider;
      _fallbackProvider = fallbackProvider;

      // Test both providers
      await _testProviders();
      
      _isInitialized = true;
      debugPrint('✅ SMS service initialized successfully');
      
      await FirebaseService.instance.logEvent('sms_service_initialized', {
        'primary_provider': primaryProvider.name,
        'fallback_provider': fallbackProvider.name,
      });
    } catch (e) {
      debugPrint('❌ Failed to initialize SMS service: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'SMS service initialization failed');
      rethrow;
    }
  }

  /// Test SMS providers
  Future<void> _testProviders() async {
    // Test primary provider
    try {
      await _testProvider(_primaryProvider);
      debugPrint('✅ Primary SMS provider (${_primaryProvider.name}) is working');
    } catch (e) {
      debugPrint('⚠️ Primary SMS provider (${_primaryProvider.name}) test failed: $e');
    }

    // Test fallback provider
    try {
      await _testProvider(_fallbackProvider);
      debugPrint('✅ Fallback SMS provider (${_fallbackProvider.name}) is working');
    } catch (e) {
      debugPrint('⚠️ Fallback SMS provider (${_fallbackProvider.name}) test failed: $e');
    }
  }

  /// Test individual provider
  Future<void> _testProvider(SmsProvider provider) async {
    switch (provider) {
      case SmsProvider.twilio:
        await _testTwilio();
        break;
      case SmsProvider.africasTalking:
        await _testAfricasTalking();
        break;
    }
  }

  /// Test Twilio configuration
  Future<void> _testTwilio() async {
    final credentials = base64Encode(utf8.encode('$_twilioAccountSid:$_twilioAuthToken'));
    
    final response = await http.get(
      Uri.parse('$_twilioBaseUrl/Accounts/$_twilioAccountSid.json'),
      headers: {
        'Authorization': 'Basic $credentials',
      },
    );

    if (response.statusCode != 200) {
      throw SmsException('Twilio test failed: ${response.body}');
    }
  }

  /// Test Africa's Talking configuration
  Future<void> _testAfricasTalking() async {
    final response = await http.get(
      Uri.parse('$_atBaseUrl/user?username=$_atUsername'),
      headers: {
        'apiKey': _atApiKey,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    if (response.statusCode != 200) {
      throw SmsException('Africa\'s Talking test failed: ${response.body}');
    }
  }

  /// Send SMS message
  Future<SmsResult> sendSms({
    required String to,
    required String message,
    SmsProvider? provider,
    bool useFailover = true,
  }) async {
    if (!_isInitialized) {
      throw SmsException('SMS service not initialized');
    }

    final targetProvider = provider ?? _primaryProvider;
    
    try {
      final result = await _sendSmsWithProvider(targetProvider, to, message);
      
      await FirebaseService.instance.logEvent('sms_sent', {
        'provider': targetProvider.name,
        'to': to,
        'success': result.success,
      });
      
      return result;
    } catch (e) {
      debugPrint('❌ SMS failed with ${targetProvider.name}: $e');
      
      // Try fallback provider if enabled and different from primary
      if (useFailover && targetProvider != _fallbackProvider) {
        debugPrint('🔄 Trying fallback provider: ${_fallbackProvider.name}');
        
        try {
          final fallbackResult = await _sendSmsWithProvider(_fallbackProvider, to, message);
          
          await FirebaseService.instance.logEvent('sms_sent_fallback', {
            'primary_provider': targetProvider.name,
            'fallback_provider': _fallbackProvider.name,
            'to': to,
            'success': fallbackResult.success,
          });
          
          return fallbackResult;
        } catch (fallbackError) {
          debugPrint('❌ Fallback SMS also failed: $fallbackError');
          
          await FirebaseService.instance.logError(fallbackError, StackTrace.current,
              reason: 'SMS fallback failed');
          
          return SmsResult(
            success: false,
            messageId: null,
            error: 'Both primary and fallback SMS providers failed',
            provider: _fallbackProvider,
          );
        }
      }
      
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'SMS sending failed');
      
      return SmsResult(
        success: false,
        messageId: null,
        error: e.toString(),
        provider: targetProvider,
      );
    }
  }

  /// Send SMS with specific provider
  Future<SmsResult> _sendSmsWithProvider(SmsProvider provider, String to, String message) async {
    switch (provider) {
      case SmsProvider.twilio:
        return await _sendTwilioSms(to, message);
      case SmsProvider.africasTalking:
        return await _sendAfricasTalkingSms(to, message);
    }
  }

  /// Send SMS via Twilio
  Future<SmsResult> _sendTwilioSms(String to, String message) async {
    final credentials = base64Encode(utf8.encode('$_twilioAccountSid:$_twilioAuthToken'));
    
    final response = await http.post(
      Uri.parse('$_twilioBaseUrl/Accounts/$_twilioAccountSid/Messages.json'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'From': _twilioPhoneNumber,
        'To': _formatPhoneNumber(to),
        'Body': message,
      },
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 201) {
      return SmsResult(
        success: true,
        messageId: responseData['sid'],
        error: null,
        provider: SmsProvider.twilio,
      );
    } else {
      throw SmsException('Twilio SMS failed: ${responseData['message']}');
    }
  }

  /// Send SMS via Africa's Talking
  Future<SmsResult> _sendAfricasTalkingSms(String to, String message) async {
    final response = await http.post(
      Uri.parse('$_atBaseUrl/messaging'),
      headers: {
        'apiKey': _atApiKey,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': _atUsername,
        'to': _formatPhoneNumberForAT(to),
        'message': message,
        'from': _atSenderId,
      },
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 201) {
      final smsMessageData = responseData['SMSMessageData'];
      final recipients = smsMessageData['Recipients'] as List;
      
      if (recipients.isNotEmpty && recipients[0]['status'] == 'Success') {
        return SmsResult(
          success: true,
          messageId: recipients[0]['messageId'],
          error: null,
          provider: SmsProvider.africasTalking,
        );
      } else {
        throw SmsException('Africa\'s Talking SMS failed: ${recipients[0]['status']}');
      }
    } else {
      throw SmsException('Africa\'s Talking SMS failed: ${response.body}');
    }
  }

  /// Send bulk SMS
  Future<List<SmsResult>> sendBulkSms({
    required List<String> recipients,
    required String message,
    SmsProvider? provider,
    bool useFailover = true,
  }) async {
    final results = <SmsResult>[];
    
    for (final recipient in recipients) {
      final result = await sendSms(
        to: recipient,
        message: message,
        provider: provider,
        useFailover: useFailover,
      );
      results.add(result);
      
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    await FirebaseService.instance.logEvent('bulk_sms_sent', {
      'recipient_count': recipients.length,
      'success_count': results.where((r) => r.success).length,
      'provider': (provider ?? _primaryProvider).name,
    });
    
    return results;
  }

  /// Send emergency SMS
  Future<SmsResult> sendEmergencySms({
    required String to,
    required String emergencyType,
    required String location,
    String? additionalInfo,
  }) async {
    final message = _buildEmergencyMessage(emergencyType, location, additionalInfo);
    
    // Use both providers for emergency messages
    final primaryResult = await sendSms(
      to: to,
      message: message,
      provider: _primaryProvider,
      useFailover: false,
    );
    
    // Also try fallback provider for redundancy
    if (_primaryProvider != _fallbackProvider) {
      await sendSms(
        to: to,
        message: message,
        provider: _fallbackProvider,
        useFailover: false,
      );
    }
    
    await FirebaseService.instance.logEvent('emergency_sms_sent', {
      'emergency_type': emergencyType,
      'to': to,
      'success': primaryResult.success,
    });
    
    return primaryResult;
  }

  /// Build emergency message
  String _buildEmergencyMessage(String emergencyType, String location, String? additionalInfo) {
    var message = 'EMERGENCY ALERT: $emergencyType at $location';
    
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      message += '. $additionalInfo';
    }
    
    message += '. Please respond immediately.';
    
    return message;
  }

  /// Format phone number for Twilio (international format)
  String _formatPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.startsWith('0')) {
      cleaned = '254${cleaned.substring(1)}'; // Kenya country code
    }
    
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    
    return cleaned;
  }

  /// Format phone number for Africa's Talking
  String _formatPhoneNumberForAT(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.startsWith('0')) {
      cleaned = '+254${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+254')) {
      cleaned = '+254$cleaned';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    
    return cleaned;
  }

  /// Validate phone number
  bool isValidPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length >= 9 && cleaned.length <= 15;
  }
}

/// SMS provider enum
enum SmsProvider {
  twilio,
  africasTalking,
}

extension SmsProviderExtension on SmsProvider {
  String get name {
    switch (this) {
      case SmsProvider.twilio:
        return 'Twilio';
      case SmsProvider.africasTalking:
        return 'Africa\'s Talking';
    }
  }
}

/// SMS result model
class SmsResult {
  final bool success;
  final String? messageId;
  final String? error;
  final SmsProvider provider;

  SmsResult({
    required this.success,
    required this.messageId,
    required this.error,
    required this.provider,
  });
}

/// SMS exception
class SmsException implements Exception {
  final String message;
  SmsException(this.message);
  
  @override
  String toString() => 'SmsException: $message';
}
