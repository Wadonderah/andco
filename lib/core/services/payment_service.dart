import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Comprehensive payment service supporting Stripe and M-Pesa
class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  
  PaymentService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Payment configuration - these should be set from environment variables
  static const String _stripePublishableKey = 'pk_test_your_stripe_key_here';
  static const String _mpesaConsumerKey = 'your_mpesa_consumer_key_here';
  static const String _mpesaConsumerSecret = 'your_mpesa_consumer_secret_here';
  static const String _mpesaShortcode = '174379'; // Test shortcode
  static const String _mpesaPasskey = 'your_mpesa_passkey_here';

  /// Initialize payment service
  Future<void> initialize() async {
    try {
      debugPrint('✅ Payment service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize payment service: $e');
      rethrow;
    }
  }

  /// Process Stripe payment
  Future<PaymentResult> processStripePayment({
    required double amount,
    required String currency,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return PaymentResult(
        success: false,
        error: 'User not authenticated',
      );
    }

    try {
      // Create payment record in Firestore
      final paymentRef = await _firestore.collection('payments').add({
        'userId': user.uid,
        'amount': amount,
        'currency': currency,
        'description': description,
        'paymentMethod': 'stripe',
        'status': 'pending',
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // In a real implementation, you would integrate with Stripe SDK
      // For now, we'll simulate the payment process
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful payment (90% success rate)
      final isSuccess = DateTime.now().millisecond % 10 != 0;

      if (isSuccess) {
        // Update payment status
        await paymentRef.update({
          'status': 'completed',
          'transactionId': 'stripe_${DateTime.now().millisecondsSinceEpoch}',
          'completedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Stripe payment completed successfully');
        return PaymentResult(
          success: true,
          transactionId: 'stripe_${DateTime.now().millisecondsSinceEpoch}',
          paymentId: paymentRef.id,
        );
      } else {
        // Update payment status to failed
        await paymentRef.update({
          'status': 'failed',
          'error': 'Payment declined by bank',
          'failedAt': FieldValue.serverTimestamp(),
        });

        return PaymentResult(
          success: false,
          error: 'Payment declined by bank',
          paymentId: paymentRef.id,
        );
      }
    } catch (e) {
      debugPrint('❌ Stripe payment failed: $e');
      return PaymentResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Process M-Pesa payment
  Future<PaymentResult> processMpesaPayment({
    required double amount,
    required String phoneNumber,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return PaymentResult(
        success: false,
        error: 'User not authenticated',
      );
    }

    try {
      // Create payment record in Firestore
      final paymentRef = await _firestore.collection('payments').add({
        'userId': user.uid,
        'amount': amount,
        'currency': 'KES',
        'description': description,
        'paymentMethod': 'mpesa',
        'phoneNumber': phoneNumber,
        'status': 'pending',
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // In a real implementation, you would integrate with M-Pesa Daraja API
      // For now, we'll simulate the payment process
      await Future.delayed(const Duration(seconds: 3));

      // Simulate successful payment (85% success rate)
      final isSuccess = DateTime.now().millisecond % 10 < 8;

      if (isSuccess) {
        // Update payment status
        await paymentRef.update({
          'status': 'completed',
          'transactionId': 'mpesa_${DateTime.now().millisecondsSinceEpoch}',
          'mpesaReceiptNumber': 'QHX${DateTime.now().millisecondsSinceEpoch}',
          'completedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ M-Pesa payment completed successfully');
        return PaymentResult(
          success: true,
          transactionId: 'mpesa_${DateTime.now().millisecondsSinceEpoch}',
          paymentId: paymentRef.id,
        );
      } else {
        // Update payment status to failed
        await paymentRef.update({
          'status': 'failed',
          'error': 'Insufficient funds or transaction cancelled',
          'failedAt': FieldValue.serverTimestamp(),
        });

        return PaymentResult(
          success: false,
          error: 'Insufficient funds or transaction cancelled',
          paymentId: paymentRef.id,
        );
      }
    } catch (e) {
      debugPrint('❌ M-Pesa payment failed: $e');
      return PaymentResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get payment history for current user
  Stream<List<PaymentRecord>> getPaymentHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PaymentRecord(
          id: doc.id,
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          currency: data['currency'] ?? 'USD',
          description: data['description'] ?? '',
          paymentMethod: data['paymentMethod'] ?? 'stripe',
          status: data['status'] ?? 'pending',
          transactionId: data['transactionId'],
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          completedAt: data['completedAt'] != null 
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
          error: data['error'],
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
      }).toList();
    });
  }

  /// Get payment statistics for current user
  Future<PaymentStats> getPaymentStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      return PaymentStats(
        totalPaid: 0.0,
        totalPending: 0.0,
        totalFailed: 0.0,
        paymentCount: 0,
        successRate: 0.0,
      );
    }

    try {
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .get();

      double totalPaid = 0.0;
      double totalPending = 0.0;
      double totalFailed = 0.0;
      int successCount = 0;
      int totalCount = paymentsSnapshot.docs.length;

      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final status = data['status'] ?? 'pending';

        switch (status) {
          case 'completed':
            totalPaid += amount;
            successCount++;
            break;
          case 'pending':
            totalPending += amount;
            break;
          case 'failed':
            totalFailed += amount;
            break;
        }
      }

      final successRate = totalCount > 0 ? (successCount / totalCount) * 100 : 0.0;

      return PaymentStats(
        totalPaid: totalPaid,
        totalPending: totalPending,
        totalFailed: totalFailed,
        paymentCount: totalCount,
        successRate: successRate,
      );
    } catch (e) {
      debugPrint('❌ Failed to get payment stats: $e');
      return PaymentStats(
        totalPaid: 0.0,
        totalPending: 0.0,
        totalFailed: 0.0,
        paymentCount: 0,
        successRate: 0.0,
      );
    }
  }

  /// Retry failed payment
  Future<PaymentResult> retryPayment(String paymentId) async {
    try {
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      if (!paymentDoc.exists) {
        return PaymentResult(
          success: false,
          error: 'Payment not found',
        );
      }

      final data = paymentDoc.data()!;
      final paymentMethod = data['paymentMethod'] ?? 'stripe';

      if (paymentMethod == 'stripe') {
        return await processStripePayment(
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          currency: data['currency'] ?? 'USD',
          description: data['description'] ?? '',
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
      } else if (paymentMethod == 'mpesa') {
        return await processMpesaPayment(
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          phoneNumber: data['phoneNumber'] ?? '',
          description: data['description'] ?? '',
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
      } else {
        return PaymentResult(
          success: false,
          error: 'Unsupported payment method',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to retry payment: $e');
      return PaymentResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? paymentId;
  final String? error;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.paymentId,
    this.error,
  });
}

/// Payment record model
class PaymentRecord {
  final String id;
  final double amount;
  final String currency;
  final String description;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? error;
  final Map<String, dynamic> metadata;

  PaymentRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.description,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    required this.createdAt,
    this.completedAt,
    this.error,
    required this.metadata,
  });
}

/// Payment statistics model
class PaymentStats {
  final double totalPaid;
  final double totalPending;
  final double totalFailed;
  final int paymentCount;
  final double successRate;

  PaymentStats({
    required this.totalPaid,
    required this.totalPending,
    required this.totalFailed,
    required this.paymentCount,
    required this.successRate,
  });
}
