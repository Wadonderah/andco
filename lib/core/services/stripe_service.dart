import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'firebase_service.dart';

/// Stripe payment service for handling payments and subscriptions
class StripeService {
  static StripeService? _instance;
  static StripeService get instance => _instance ??= StripeService._();

  StripeService._();

  // Stripe configuration
  static const String _publishableKeyTest = 'pk_test_your_publishable_key_here';
  static const String _secretKeyTest = 'sk_test_your_secret_key_here';
  static const String _publishableKeyLive = 'pk_live_your_publishable_key_here';
  static const String _secretKeyLive = 'sk_live_your_secret_key_here';
  static const String _baseUrl = 'https://api.stripe.com/v1';
  static const String _webhookEndpoint =
      'https://your-backend.com/stripe/webhook';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Stripe with appropriate keys based on environment
  Future<void> initialize({bool isProduction = false}) async {
    if (_isInitialized) return;

    try {
      final publishableKey =
          isProduction ? _publishableKeyLive : _publishableKeyTest;
      Stripe.publishableKey = publishableKey;

      // Configure Stripe settings
      await Stripe.instance.applySettings();

      _isInitialized = true;
      debugPrint('✅ Stripe initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Stripe: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Stripe initialization failed');
      rethrow;
    }
  }

  /// Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required int amount, // Amount in cents
    required String currency,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: {
          'Authorization':
              'Bearer ${kDebugMode ? _secretKeyTest : _secretKeyLive}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount.toString(),
          'currency': currency,
          'automatic_payment_methods[enabled]': 'true',
          if (customerId != null) 'customer': customerId,
          if (metadata != null)
            ...metadata.map(
                (key, value) => MapEntry('metadata[$key]', value.toString())),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await FirebaseService.instance.logEvent('payment_intent_created', {
          'amount': amount,
          'currency': currency,
          'customer_id': customerId ?? '',
        });
        return data;
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to create payment intent');
      rethrow;
    }
  }

  /// Process payment
  Future<PaymentIntent> processPayment({
    required String paymentIntentClientSecret,
    BillingDetails? billingDetails,
  }) async {
    try {
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntentClientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );

      await FirebaseService.instance.logEvent('payment_processed', {
        'payment_intent_id': paymentIntent.id,
        'status': paymentIntent.status.name,
      });

      return paymentIntent;
    } catch (e) {
      await FirebaseService.instance
          .logError(e, StackTrace.current, reason: 'Payment processing failed');
      rethrow;
    }
  }

  /// Create customer
  Future<Map<String, dynamic>> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customers'),
        headers: {
          'Authorization':
              'Bearer ${kDebugMode ? _secretKeyTest : _secretKeyLive}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (metadata != null)
            ...metadata.map(
                (key, value) => MapEntry('metadata[$key]', value.toString())),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await FirebaseService.instance.logEvent('customer_created', {
          'customer_id': data['id'],
          'email': email,
        });
        return data;
      } else {
        throw Exception('Failed to create customer: ${response.body}');
      }
    } catch (e) {
      await FirebaseService.instance
          .logError(e, StackTrace.current, reason: 'Failed to create customer');
      rethrow;
    }
  }

  /// Create subscription
  Future<Map<String, dynamic>> createSubscription({
    required String customerId,
    required String priceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions'),
        headers: {
          'Authorization':
              'Bearer ${kDebugMode ? _secretKeyTest : _secretKeyLive}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
          'items[0][price]': priceId,
          'payment_behavior': 'default_incomplete',
          'payment_settings[save_default_payment_method]': 'on_subscription',
          'expand[0]': 'latest_invoice.payment_intent',
          if (metadata != null)
            ...metadata.map(
                (key, value) => MapEntry('metadata[$key]', value.toString())),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await FirebaseService.instance.logEvent('subscription_created', {
          'subscription_id': data['id'],
          'customer_id': customerId,
          'price_id': priceId,
        });
        return data;
      } else {
        throw Exception('Failed to create subscription: ${response.body}');
      }
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to create subscription');
      rethrow;
    }
  }

  /// Cancel subscription
  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Authorization':
              'Bearer ${kDebugMode ? _secretKeyTest : _secretKeyLive}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await FirebaseService.instance.logEvent('subscription_cancelled', {
          'subscription_id': subscriptionId,
        });
        return data;
      } else {
        throw Exception('Failed to cancel subscription: ${response.body}');
      }
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to cancel subscription');
      rethrow;
    }
  }

  /// Get customer subscriptions
  Future<List<Map<String, dynamic>>> getCustomerSubscriptions(
      String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions?customer=$customerId'),
        headers: {
          'Authorization':
              'Bearer ${kDebugMode ? _secretKeyTest : _secretKeyLive}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to get subscriptions: ${response.body}');
      }
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to get customer subscriptions');
      rethrow;
    }
  }

  /// Handle webhook events
  Future<void> handleWebhook(String payload, String signature) async {
    try {
      // Verify webhook signature (implement based on your webhook endpoint secret)
      // final event = Webhook.constructEvent(payload, signature, webhookSecret);

      final event = json.decode(payload);
      final eventType = event['type'] as String;

      switch (eventType) {
        case 'payment_intent.succeeded':
          await _handlePaymentSucceeded(event['data']['object']);
          break;
        case 'payment_intent.payment_failed':
          await _handlePaymentFailed(event['data']['object']);
          break;
        case 'customer.subscription.created':
          await _handleSubscriptionCreated(event['data']['object']);
          break;
        case 'customer.subscription.updated':
          await _handleSubscriptionUpdated(event['data']['object']);
          break;
        case 'customer.subscription.deleted':
          await _handleSubscriptionDeleted(event['data']['object']);
          break;
        default:
          debugPrint('Unhandled webhook event: $eventType');
      }

      await FirebaseService.instance.logEvent('webhook_processed', {
        'event_type': eventType,
      });
    } catch (e) {
      await FirebaseService.instance
          .logError(e, StackTrace.current, reason: 'Webhook processing failed');
      rethrow;
    }
  }

  /// Handle successful payment
  Future<void> _handlePaymentSucceeded(
      Map<String, dynamic> paymentIntent) async {
    try {
      final paymentId = paymentIntent['id'];
      final amount = paymentIntent['amount'];
      final currency = paymentIntent['currency'];
      final customerId = paymentIntent['customer'];

      // Update payment status in Firestore
      await FirebaseService.instance.firestore
          .collection('payments')
          .doc(paymentId)
          .update({
        'status': 'completed',
        'stripePaymentIntentId': paymentId,
        'amount': amount / 100, // Convert from cents
        'currency': currency.toUpperCase(),
        'completedAt': DateTime.now().toIso8601String(),
        'paymentMethod': 'stripe',
      });

      // Send confirmation notifications
      if (customerId != null) {
        await _sendPaymentConfirmation(customerId, paymentId, amount, currency);
      }

      debugPrint('✅ Payment succeeded and recorded: $paymentId');
    } catch (e) {
      debugPrint('❌ Error handling payment success: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to handle successful payment');
    }
  }

  /// Handle failed payment
  Future<void> _handlePaymentFailed(Map<String, dynamic> paymentIntent) async {
    // Update payment status in Firestore
    // Send failure notifications
    debugPrint('Payment failed: ${paymentIntent['id']}');
  }

  /// Handle subscription created
  Future<void> _handleSubscriptionCreated(
      Map<String, dynamic> subscription) async {
    // Update subscription status in Firestore
    debugPrint('Subscription created: ${subscription['id']}');
  }

  /// Handle subscription updated
  Future<void> _handleSubscriptionUpdated(
      Map<String, dynamic> subscription) async {
    // Update subscription status in Firestore
    debugPrint('Subscription updated: ${subscription['id']}');
  }

  /// Handle subscription deleted
  Future<void> _handleSubscriptionDeleted(
      Map<String, dynamic> subscription) async {
    try {
      final subscriptionId = subscription['id'];
      final customerId = subscription['customer'];

      // Update subscription status in Firestore
      await FirebaseService.instance.firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .update({
        'status': 'canceled',
        'canceledAt': DateTime.now().toIso8601String(),
      });

      // Send cancellation notification
      if (customerId != null) {
        await _sendSubscriptionCancellationNotification(
            customerId, subscriptionId);
      }

      debugPrint('✅ Subscription deleted and recorded: $subscriptionId');
    } catch (e) {
      debugPrint('❌ Error handling subscription deletion: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to handle subscription deletion');
    }
  }

  /// Send payment confirmation notification
  Future<void> _sendPaymentConfirmation(
    String customerId,
    String paymentId,
    int amount,
    String currency,
  ) async {
    try {
      // Create notification document in Firestore
      await FirebaseService.instance.firestore.collection('notifications').add({
        'userId': customerId,
        'type': 'payment_success',
        'title': 'Payment Successful',
        'message':
            'Your payment of ${currency.toUpperCase()} ${(amount / 100).toStringAsFixed(2)} has been processed successfully.',
        'data': {
          'paymentId': paymentId,
          'amount': amount / 100,
          'currency': currency.toUpperCase(),
        },
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });

      debugPrint('✅ Payment confirmation notification sent for: $paymentId');
    } catch (e) {
      debugPrint('❌ Error sending payment confirmation: $e');
    }
  }

  /// Send subscription cancellation notification
  Future<void> _sendSubscriptionCancellationNotification(
    String customerId,
    String subscriptionId,
  ) async {
    try {
      // Create notification document in Firestore
      await FirebaseService.instance.firestore.collection('notifications').add({
        'userId': customerId,
        'type': 'subscription_canceled',
        'title': 'Subscription Canceled',
        'message': 'Your subscription has been canceled successfully.',
        'data': {
          'subscriptionId': subscriptionId,
        },
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });

      debugPrint(
          '✅ Subscription cancellation notification sent for: $subscriptionId');
    } catch (e) {
      debugPrint('❌ Error sending subscription cancellation notification: $e');
    }
  }
}
