import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'firebase_service.dart';

/// M-Pesa Daraja API service for mobile money payments
class MPesaService {
  static MPesaService? _instance;
  static MPesaService get instance => _instance ??= MPesaService._();

  MPesaService._();

  // M-Pesa Daraja API configuration
  static const String _sandboxBaseUrl = 'https://sandbox.safaricom.co.ke';
  static const String _productionBaseUrl = 'https://api.safaricom.co.ke';

  // Sandbox credentials (replace with your actual credentials)
  static const String _sandboxConsumerKey = 'your_sandbox_consumer_key';
  static const String _sandboxConsumerSecret = 'your_sandbox_consumer_secret';
  static const String _sandboxPasskey =
      'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';

  // Production credentials (replace with your actual credentials)
  static const String _productionConsumerKey = 'your_production_consumer_key';
  static const String _productionConsumerSecret =
      'your_production_consumer_secret';
  static const String _productionPasskey = 'your_production_passkey';

  // Business short code
  static const String _sandboxShortCode = '174379';
  static const String _productionShortCode = 'your_production_shortcode';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Initialize M-Pesa service
  Future<void> initialize({bool isProduction = false}) async {
    if (_isInitialized) return;

    try {
      await _getAccessToken(isProduction: isProduction);
      _isInitialized = true;

      debugPrint('✅ M-Pesa service initialized successfully');
      await FirebaseService.instance.logEvent('mpesa_initialized', {
        'environment': isProduction ? 'production' : 'sandbox',
      });
    } catch (e) {
      debugPrint('❌ Failed to initialize M-Pesa service: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'M-Pesa initialization failed');
      rethrow;
    }
  }

  /// Get OAuth access token
  Future<void> _getAccessToken({bool isProduction = false}) async {
    // Check if token is still valid
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return;
    }

    final baseUrl = isProduction ? _productionBaseUrl : _sandboxBaseUrl;
    final consumerKey =
        isProduction ? _productionConsumerKey : _sandboxConsumerKey;
    final consumerSecret =
        isProduction ? _productionConsumerSecret : _sandboxConsumerSecret;

    final credentials =
        base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/oauth/v1/generate?grant_type=client_credentials'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];

        // Token expires in seconds, convert to DateTime
        final expiresIn = int.parse(data['expires_in']);
        _tokenExpiry =
            DateTime.now().add(Duration(seconds: expiresIn - 60)); // 60s buffer

        debugPrint('✅ M-Pesa access token obtained');
      } else {
        throw MPesaException('Failed to get access token: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Failed to get M-Pesa access token: $e');
      rethrow;
    }
  }

  /// Initiate STK Push payment
  Future<Map<String, dynamic>> stkPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
    String? callbackUrl,
    bool isProduction = false,
  }) async {
    await _ensureValidToken(isProduction: isProduction);

    final baseUrl = isProduction ? _productionBaseUrl : _sandboxBaseUrl;
    final shortCode = isProduction ? _productionShortCode : _sandboxShortCode;
    final passkey = isProduction ? _productionPasskey : _sandboxPasskey;

    // Format phone number (remove + and ensure it starts with 254)
    String formattedPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '254${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('254')) {
      formattedPhone = '254$formattedPhone';
    }

    // Generate timestamp
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^\d]'), '')
        .substring(0, 14);

    // Generate password
    final password = base64Encode(utf8.encode('$shortCode$passkey$timestamp'));

    final requestBody = {
      'BusinessShortCode': shortCode,
      'Password': password,
      'Timestamp': timestamp,
      'TransactionType': 'CustomerPayBillOnline',
      'Amount': amount.round(),
      'PartyA': formattedPhone,
      'PartyB': shortCode,
      'PhoneNumber': formattedPhone,
      'CallBackURL':
          callbackUrl ?? 'https://your-callback-url.com/mpesa/callback',
      'AccountReference': accountReference,
      'TransactionDesc': transactionDesc,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['ResponseCode'] == '0') {
        await FirebaseService.instance.logEvent('mpesa_stk_push_initiated', {
          'phone_number': formattedPhone,
          'amount': amount,
          'account_reference': accountReference,
        });

        debugPrint('✅ STK Push initiated successfully');
        return responseData;
      } else {
        throw MPesaException(responseData['errorMessage'] ?? 'STK Push failed');
      }
    } catch (e) {
      debugPrint('❌ STK Push failed: $e');
      await FirebaseService.instance
          .logError(e, StackTrace.current, reason: 'STK Push failed');
      rethrow;
    }
  }

  /// Query STK Push transaction status
  Future<Map<String, dynamic>> queryStkPushStatus({
    required String checkoutRequestId,
    bool isProduction = false,
  }) async {
    await _ensureValidToken(isProduction: isProduction);

    final baseUrl = isProduction ? _productionBaseUrl : _sandboxBaseUrl;
    final shortCode = isProduction ? _productionShortCode : _sandboxShortCode;
    final passkey = isProduction ? _productionPasskey : _sandboxPasskey;

    // Generate timestamp
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^\d]'), '')
        .substring(0, 14);

    // Generate password
    final password = base64Encode(utf8.encode('$shortCode$passkey$timestamp'));

    final requestBody = {
      'BusinessShortCode': shortCode,
      'Password': password,
      'Timestamp': timestamp,
      'CheckoutRequestID': checkoutRequestId,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        debugPrint('✅ STK Push status queried successfully');
        return responseData;
      } else {
        throw MPesaException(
            responseData['errorMessage'] ?? 'Status query failed');
      }
    } catch (e) {
      debugPrint('❌ STK Push status query failed: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'STK Push status query failed');
      rethrow;
    }
  }

  /// Register callback URLs
  Future<Map<String, dynamic>> registerUrls({
    required String confirmationUrl,
    required String validationUrl,
    bool isProduction = false,
  }) async {
    await _ensureValidToken(isProduction: isProduction);

    final baseUrl = isProduction ? _productionBaseUrl : _sandboxBaseUrl;
    final shortCode = isProduction ? _productionShortCode : _sandboxShortCode;

    final requestBody = {
      'ShortCode': shortCode,
      'ResponseType': 'Completed',
      'ConfirmationURL': confirmationUrl,
      'ValidationURL': validationUrl,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mpesa/c2b/v1/registerurl'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        debugPrint('✅ M-Pesa URLs registered successfully');
        return responseData;
      } else {
        throw MPesaException(
            responseData['errorMessage'] ?? 'URL registration failed');
      }
    } catch (e) {
      debugPrint('❌ M-Pesa URL registration failed: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'M-Pesa URL registration failed');
      rethrow;
    }
  }

  /// Ensure access token is valid
  Future<void> _ensureValidToken({bool isProduction = false}) async {
    if (_accessToken == null ||
        _tokenExpiry == null ||
        DateTime.now().isAfter(_tokenExpiry!)) {
      await _getAccessToken(isProduction: isProduction);
    }
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a valid Kenyan number
    return cleanPhone.length >= 9 &&
        (cleanPhone.startsWith('254') ||
            cleanPhone.startsWith('0') ||
            cleanPhone.length == 9);
  }

  /// Format phone number for display
  String formatPhoneNumber(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.startsWith('254')) {
      return '+${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    } else if (cleanPhone.startsWith('0')) {
      return '${cleanPhone.substring(0, 4)} ${cleanPhone.substring(4, 7)} ${cleanPhone.substring(7)}';
    }

    return phoneNumber;
  }

  /// Handle M-Pesa payment callback
  Future<void> handlePaymentCallback(Map<String, dynamic> callbackData) async {
    try {
      final resultCode = callbackData['Body']['stkCallback']['ResultCode'];
      final checkoutRequestId =
          callbackData['Body']['stkCallback']['CheckoutRequestID'];
      final merchantRequestId =
          callbackData['Body']['stkCallback']['MerchantRequestID'];

      if (resultCode == 0) {
        // Payment successful
        await _handleSuccessfulPayment(callbackData);
      } else {
        // Payment failed
        await _handleFailedPayment(callbackData);
      }

      debugPrint('✅ M-Pesa callback processed for: $checkoutRequestId');
    } catch (e) {
      debugPrint('❌ Error processing M-Pesa callback: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to process M-Pesa callback');
    }
  }

  /// Handle successful M-Pesa payment
  Future<void> _handleSuccessfulPayment(
      Map<String, dynamic> callbackData) async {
    try {
      final stkCallback = callbackData['Body']['stkCallback'];
      final checkoutRequestId = stkCallback['CheckoutRequestID'];
      final merchantRequestId = stkCallback['MerchantRequestID'];

      // Extract payment details from callback metadata
      final callbackMetadata = stkCallback['CallbackMetadata']['Item'] as List;
      final paymentDetails = <String, dynamic>{};

      for (final item in callbackMetadata) {
        final name = item['Name'];
        final value = item['Value'];
        paymentDetails[name] = value;
      }

      final amount = paymentDetails['Amount'];
      final mpesaReceiptNumber = paymentDetails['MpesaReceiptNumber'];
      final phoneNumber = paymentDetails['PhoneNumber'];

      // Update payment status in Firestore
      await FirebaseService.instance.firestore
          .collection('payments')
          .doc(checkoutRequestId)
          .update({
        'status': 'completed',
        'mpesaReceiptNumber': mpesaReceiptNumber,
        'phoneNumber': phoneNumber,
        'amount': amount,
        'completedAt': DateTime.now().toIso8601String(),
        'paymentMethod': 'mpesa',
        'merchantRequestId': merchantRequestId,
      });

      // Send confirmation notification
      await _sendMPesaPaymentConfirmation(
        phoneNumber.toString(),
        checkoutRequestId,
        amount,
        mpesaReceiptNumber,
      );

      debugPrint('✅ M-Pesa payment succeeded: $mpesaReceiptNumber');
    } catch (e) {
      debugPrint('❌ Error handling successful M-Pesa payment: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to handle successful M-Pesa payment');
    }
  }

  /// Handle failed M-Pesa payment
  Future<void> _handleFailedPayment(Map<String, dynamic> callbackData) async {
    try {
      final stkCallback = callbackData['Body']['stkCallback'];
      final checkoutRequestId = stkCallback['CheckoutRequestID'];
      final resultDesc = stkCallback['ResultDesc'];

      // Update payment status in Firestore
      await FirebaseService.instance.firestore
          .collection('payments')
          .doc(checkoutRequestId)
          .update({
        'status': 'failed',
        'failureReason': resultDesc,
        'failedAt': DateTime.now().toIso8601String(),
        'paymentMethod': 'mpesa',
      });

      debugPrint('❌ M-Pesa payment failed: $resultDesc');
    } catch (e) {
      debugPrint('❌ Error handling failed M-Pesa payment: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to handle failed M-Pesa payment');
    }
  }

  /// Send M-Pesa payment confirmation notification
  Future<void> _sendMPesaPaymentConfirmation(
    String phoneNumber,
    String checkoutRequestId,
    dynamic amount,
    String receiptNumber,
  ) async {
    try {
      // Create notification document in Firestore
      await FirebaseService.instance.firestore.collection('notifications').add({
        'phoneNumber': phoneNumber,
        'type': 'mpesa_payment_success',
        'title': 'M-Pesa Payment Successful',
        'message':
            'Your M-Pesa payment of KES ${amount.toString()} has been processed successfully. Receipt: $receiptNumber',
        'data': {
          'checkoutRequestId': checkoutRequestId,
          'amount': amount,
          'receiptNumber': receiptNumber,
          'phoneNumber': phoneNumber,
        },
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });

      debugPrint(
          '✅ M-Pesa payment confirmation notification sent for: $receiptNumber');
    } catch (e) {
      debugPrint('❌ Error sending M-Pesa payment confirmation: $e');
    }
  }

  /// Create payment record before initiating STK push
  Future<void> createPaymentRecord({
    required String checkoutRequestId,
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String description,
    String? userId,
  }) async {
    try {
      await FirebaseService.instance.firestore
          .collection('payments')
          .doc(checkoutRequestId)
          .set({
        'id': checkoutRequestId,
        'userId': userId,
        'phoneNumber': phoneNumber,
        'amount': amount,
        'currency': 'KES',
        'accountReference': accountReference,
        'description': description,
        'status': 'pending',
        'paymentMethod': 'mpesa',
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ M-Pesa payment record created: $checkoutRequestId');
    } catch (e) {
      debugPrint('❌ Error creating M-Pesa payment record: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to create M-Pesa payment record');
    }
  }
}

/// Custom exception for M-Pesa errors
class MPesaException implements Exception {
  final String message;
  final String? code;

  MPesaException(this.message, [this.code]);

  @override
  String toString() =>
      'MPesaException: $message${code != null ? ' (Code: $code)' : ''}';
}
