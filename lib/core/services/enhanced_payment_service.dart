import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import '../../shared/models/payment_model.dart';
import '../repositories/payment_repository.dart';
import 'firebase_service.dart';
import 'mpesa_service.dart';
import 'notification_service.dart';
import 'stripe_service.dart';

/// Enhanced payment service that orchestrates all payment operations
class EnhancedPaymentService {
  static EnhancedPaymentService? _instance;
  static EnhancedPaymentService get instance =>
      _instance ??= EnhancedPaymentService._();

  EnhancedPaymentService._();

  final PaymentRepository _paymentRepository = PaymentRepository();
  final StripeService _stripeService = StripeService.instance;
  final MPesaService _mpesaService = MPesaService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  /// Process payment with automatic method detection and error handling
  Future<PaymentResult> processPayment({
    required PaymentRequest request,
  }) async {
    try {
      // Create initial payment record
      final payment = PaymentModel(
        id: '',
        userId: request.userId,
        schoolId: request.schoolId,
        amount: request.amount,
        currency: request.currency,
        description: request.description,
        paymentMethod: request.paymentMethod,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final paymentId = await _paymentRepository.create(payment);
      final createdPayment = payment.copyWith(id: paymentId);

      // Process payment based on method
      PaymentResult result;
      switch (request.paymentMethod) {
        case PaymentMethod.stripe:
          result = await _processStripePayment(createdPayment, request);
          break;
        case PaymentMethod.mpesa:
          result = await _processMpesaPayment(createdPayment, request);
          break;
        case PaymentMethod.bank:
          result = await _processBankPayment(createdPayment, request);
          break;
        case PaymentMethod.cash:
          result = await _processCashPayment(createdPayment, request);
          break;
      }

      // Update payment status
      await _updatePaymentStatus(paymentId, result);

      // Send notifications
      await _sendPaymentNotifications(createdPayment, result);

      // Log analytics
      await _logPaymentAnalytics(createdPayment, result);

      return result;
    } catch (e) {
      debugPrint('❌ Payment processing failed: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Payment processing failed',
      );
      return PaymentResult(
        success: false,
        paymentId: '',
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Process Stripe payment
  Future<PaymentResult> _processStripePayment(
    PaymentModel payment,
    PaymentRequest request,
  ) async {
    try {
      // Create payment intent
      final paymentIntent = await _stripeService.createPaymentIntent(
        amount: (payment.amount * 100).round(), // Convert to cents
        currency: payment.currency,
        customerId: request.customerId,
        metadata: {
          'payment_id': payment.id,
          'user_id': payment.userId,
          'school_id': payment.schoolId,
          'description': payment.description,
        },
      );

      // Process payment
      final result = await _stripeService.processPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        billingDetails: request.billingDetails,
      );

      return PaymentResult(
        success: result.status == stripe.PaymentIntentsStatus.Succeeded,
        paymentId: payment.id,
        transactionId: result.id,
        paymentMethod: PaymentMethod.stripe,
        amount: payment.amount,
        currency: payment.currency,
        status: _mapStripeStatus(result.status),
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        paymentId: payment.id,
        errorMessage: _getErrorMessage(e),
        paymentMethod: PaymentMethod.stripe,
      );
    }
  }

  /// Process M-Pesa payment
  Future<PaymentResult> _processMpesaPayment(
    PaymentModel payment,
    PaymentRequest request,
  ) async {
    try {
      if (request.phoneNumber == null) {
        throw Exception('Phone number is required for M-Pesa payments');
      }

      // Initiate STK Push
      final response = await _mpesaService.stkPush(
        phoneNumber: request.phoneNumber!,
        amount: payment.amount,
        accountReference: payment.id,
        transactionDesc: payment.description,
      );

      if (response['ResponseCode'] == '0') {
        return PaymentResult(
          success: true,
          paymentId: payment.id,
          transactionId: response['CheckoutRequestID'],
          paymentMethod: PaymentMethod.mpesa,
          amount: payment.amount,
          currency: payment.currency,
          status: PaymentStatus.pending,
          mpesaCheckoutRequestId: response['CheckoutRequestID'],
        );
      } else {
        return PaymentResult(
          success: false,
          paymentId: payment.id,
          errorMessage: response['CustomerMessage'] ?? 'M-Pesa payment failed',
          paymentMethod: PaymentMethod.mpesa,
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        paymentId: payment.id,
        errorMessage: _getErrorMessage(e),
        paymentMethod: PaymentMethod.mpesa,
      );
    }
  }

  /// Update payment status in database
  Future<void> _updatePaymentStatus(
      String paymentId, PaymentResult result) async {
    try {
      final updates = <String, dynamic>{
        'status': result.status?.name ?? PaymentStatus.failed.name,
        'updatedAt': DateTime.now(),
      };

      if (result.transactionId != null) {
        if (result.paymentMethod == PaymentMethod.stripe) {
          updates['stripePaymentIntentId'] = result.transactionId;
        } else if (result.paymentMethod == PaymentMethod.mpesa) {
          updates['mpesaCheckoutRequestId'] = result.transactionId;
        } else if (result.paymentMethod == PaymentMethod.bank) {
          updates['bankTransactionId'] = result.transactionId;
        } else if (result.paymentMethod == PaymentMethod.cash) {
          updates['cashTransactionId'] = result.transactionId;
        }
      }

      if (result.errorMessage != null) {
        updates['failureReason'] = result.errorMessage;
      }

      await _paymentRepository.update(paymentId, updates);
    } catch (e) {
      debugPrint('❌ Failed to update payment status: $e');
    }
  }

  /// Send payment notifications
  Future<void> _sendPaymentNotifications(
    PaymentModel payment,
    PaymentResult result,
  ) async {
    try {
      String title;
      String body;

      if (result.success) {
        title = 'Payment Successful';
        body =
            'Your payment of \$${payment.amount.toStringAsFixed(2)} has been processed successfully.';
      } else {
        title = 'Payment Failed';
        body =
            'Your payment of \$${payment.amount.toStringAsFixed(2)} could not be processed. ${result.errorMessage ?? ''}';
      }

      await _notificationService.sendPaymentNotification(
        userId: payment.userId,
        status: result.success ? 'success' : 'failed',
        amount: payment.amount,
        currency: payment.currency,
        transactionId: result.transactionId,
      );
    } catch (e) {
      debugPrint('❌ Failed to send payment notifications: $e');
    }
  }

  /// Log payment analytics
  Future<void> _logPaymentAnalytics(
    PaymentModel payment,
    PaymentResult result,
  ) async {
    try {
      await FirebaseService.instance.logEvent('payment_processed', {
        'payment_id': payment.id,
        'user_id': payment.userId,
        'school_id': payment.schoolId,
        'amount': payment.amount,
        'currency': payment.currency,
        'payment_method': payment.paymentMethod.name,
        'success': result.success,
        'status': result.status?.name ?? 'unknown',
        if (result.errorMessage != null) 'error_message': result.errorMessage!,
      });
    } catch (e) {
      debugPrint('❌ Failed to log payment analytics: $e');
    }
  }

  /// Get payment history for user
  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    return await _paymentRepository.getPaymentsForUser(userId);
  }

  /// Get payment history stream for user
  Stream<List<PaymentModel>> getPaymentHistoryStream(String userId) {
    return _paymentRepository.getPaymentsStreamForUser(userId);
  }

  /// Get payment by ID
  Future<PaymentModel?> getPayment(String paymentId) async {
    return await _paymentRepository.getById(paymentId);
  }

  /// Get payment status stream
  Stream<PaymentModel?> getPaymentStatusStream(String paymentId) {
    return _paymentRepository.getPaymentStatusStream(paymentId);
  }

  /// Refund payment
  Future<PaymentResult> refundPayment(String paymentId,
      {double? amount}) async {
    try {
      final payment = await _paymentRepository.getById(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      if (payment.status != PaymentStatus.completed) {
        throw Exception('Only completed payments can be refunded');
      }

      // Process refund based on payment method
      PaymentResult result;
      switch (payment.paymentMethod) {
        case PaymentMethod.stripe:
          result = await _processStripeRefund(payment, amount);
          break;
        case PaymentMethod.mpesa:
          result = await _processMpesaRefund(payment, amount);
          break;
        case PaymentMethod.bank:
          result = await _processBankRefund(payment, amount);
          break;
        case PaymentMethod.cash:
          result = await _processCashRefund(payment, amount);
          break;
      }

      // Update payment status
      if (result.success) {
        await _paymentRepository.update(paymentId, {
          'status': PaymentStatus.cancelled.name,
          'updatedAt': DateTime.now(),
        });
      }

      return result;
    } catch (e) {
      return PaymentResult(
        success: false,
        paymentId: paymentId,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Process Stripe refund
  Future<PaymentResult> _processStripeRefund(
      PaymentModel payment, double? amount) async {
    // TODO: Implement Stripe refund logic
    return PaymentResult(
      success: false,
      paymentId: payment.id,
      errorMessage: 'Stripe refunds not yet implemented',
    );
  }

  /// Process M-Pesa refund
  Future<PaymentResult> _processMpesaRefund(
      PaymentModel payment, double? amount) async {
    // TODO: Implement M-Pesa refund logic
    return PaymentResult(
      success: false,
      paymentId: payment.id,
      errorMessage: 'M-Pesa refunds not yet implemented',
    );
  }

  /// Process bank payment
  Future<PaymentResult> _processBankPayment(
    PaymentModel payment,
    PaymentRequest request,
  ) async {
    try {
      // TODO: Implement bank transfer payment logic
      // This would typically involve generating payment instructions
      // or integrating with banking APIs

      return PaymentResult(
        success: true,
        paymentId: payment.id,
        transactionId: 'BANK_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: PaymentMethod.bank,
        amount: payment.amount,
        currency: payment.currency,
        status: PaymentStatus
            .pending, // Bank transfers usually require manual verification
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        paymentId: payment.id,
        errorMessage: _getErrorMessage(e),
        paymentMethod: PaymentMethod.bank,
      );
    }
  }

  /// Process cash payment
  Future<PaymentResult> _processCashPayment(
    PaymentModel payment,
    PaymentRequest request,
  ) async {
    try {
      // TODO: Implement cash payment logic
      // This would typically involve marking payment as pending
      // until cash is physically received and verified

      return PaymentResult(
        success: true,
        paymentId: payment.id,
        transactionId: 'CASH_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: PaymentMethod.cash,
        amount: payment.amount,
        currency: payment.currency,
        status:
            PaymentStatus.pending, // Cash payments require manual verification
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        paymentId: payment.id,
        errorMessage: _getErrorMessage(e),
        paymentMethod: PaymentMethod.cash,
      );
    }
  }

  /// Process bank refund
  Future<PaymentResult> _processBankRefund(
      PaymentModel payment, double? amount) async {
    // TODO: Implement bank transfer refund logic
    return PaymentResult(
      success: false,
      paymentId: payment.id,
      errorMessage: 'Bank transfer refunds not yet implemented',
    );
  }

  /// Process cash refund
  Future<PaymentResult> _processCashRefund(
      PaymentModel payment, double? amount) async {
    // TODO: Implement cash refund logic
    return PaymentResult(
      success: false,
      paymentId: payment.id,
      errorMessage: 'Cash refunds not yet implemented',
    );
  }

  /// Map Stripe status to PaymentStatus
  PaymentStatus _mapStripeStatus(stripe.PaymentIntentsStatus status) {
    switch (status) {
      case stripe.PaymentIntentsStatus.Succeeded:
        return PaymentStatus.completed;
      case stripe.PaymentIntentsStatus.Processing:
        return PaymentStatus.pending;
      case stripe.PaymentIntentsStatus.RequiresPaymentMethod:
      case stripe.PaymentIntentsStatus.RequiresConfirmation:
      case stripe.PaymentIntentsStatus.RequiresAction:
        return PaymentStatus.pending;
      case stripe.PaymentIntentsStatus.Canceled:
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.failed;
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }
}

/// Payment request model
class PaymentRequest {
  final String userId;
  final String schoolId;
  final double amount;
  final String currency;
  final String description;
  final PaymentMethod paymentMethod;
  final String? customerId;
  final String? phoneNumber;
  final dynamic billingDetails;

  PaymentRequest({
    required this.userId,
    required this.schoolId,
    required this.amount,
    required this.currency,
    required this.description,
    required this.paymentMethod,
    this.customerId,
    this.phoneNumber,
    this.billingDetails,
  });
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String paymentId;
  final String? transactionId;
  final PaymentMethod? paymentMethod;
  final double? amount;
  final String? currency;
  final PaymentStatus? status;
  final String? errorMessage;
  final String? mpesaCheckoutRequestId;

  PaymentResult({
    required this.success,
    required this.paymentId,
    this.transactionId,
    this.paymentMethod,
    this.amount,
    this.currency,
    this.status,
    this.errorMessage,
    this.mpesaCheckoutRequestId,
  });
}

/// Provider for enhanced payment service
final enhancedPaymentServiceProvider = Provider<EnhancedPaymentService>((ref) {
  return EnhancedPaymentService.instance;
});
