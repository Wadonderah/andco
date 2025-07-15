/// Subscription plan model
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String interval; // 'month', 'year', etc.
  final List<String> features;
  final bool isPopular;
  final String? stripePriceId;
  final int? trialDays;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.interval,
    required this.features,
    this.isPopular = false,
    this.stripePriceId,
    this.trialDays,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      interval: map['interval'] ?? 'month',
      features: List<String>.from(map['features'] ?? []),
      isPopular: map['isPopular'] ?? false,
      stripePriceId: map['stripePriceId'],
      trialDays: map['trialDays'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'interval': interval,
      'features': features,
      'isPopular': isPopular,
      'stripePriceId': stripePriceId,
      'trialDays': trialDays,
    };
  }

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedInterval => interval == 'month' ? 'Monthly' : 'Yearly';
}

/// Payment method model
class PaymentMethodModel {
  final String id;
  final String type; // 'card', 'mobile_money', etc.
  final String last4;
  final String brand;
  final int expMonth;
  final int expYear;
  final bool isDefault;
  final DateTime createdAt;

  const PaymentMethodModel({
    required this.id,
    required this.type,
    required this.last4,
    required this.brand,
    required this.expMonth,
    required this.expYear,
    this.isDefault = false,
    required this.createdAt,
  });

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      last4: map['last4'] ?? '',
      brand: map['brand'] ?? '',
      expMonth: map['expMonth'] ?? 0,
      expYear: map['expYear'] ?? 0,
      isDefault: map['isDefault'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'last4': last4,
      'brand': brand,
      'expMonth': expMonth,
      'expYear': expYear,
      'isDefault': isDefault,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  String get displayName => '•••• •••• •••• $last4';
  String get expiryDate =>
      '${expMonth.toString().padLeft(2, '0')}/${expYear.toString().substring(2)}';
}

/// Transaction model
class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'payment', 'refund', 'subscription'
  final double amount;
  final String currency;
  final TransactionStatus status;
  final String? description;
  final String? paymentMethodId;
  final String? subscriptionId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    this.description,
    this.paymentMethodId,
    this.subscriptionId,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      status: TransactionStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      description: map['description'],
      paymentMethodId: map['paymentMethodId'],
      subscriptionId: map['subscriptionId'],
      metadata: map['metadata'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'description': description,
      'paymentMethodId': paymentMethodId,
      'subscriptionId': subscriptionId,
      'metadata': metadata,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
}

/// Transaction status enum
enum TransactionStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.succeeded:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }
}

/// Billing address model
class BillingAddress {
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  const BillingAddress({
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  factory BillingAddress.fromMap(Map<String, dynamic> map) {
    return BillingAddress(
      line1: map['line1'] ?? '',
      line2: map['line2'],
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }
}

/// M-Pesa payment request model
class MPesaPaymentRequest {
  final String phoneNumber;
  final double amount;
  final String accountReference;
  final String transactionDesc;
  final String? callbackUrl;

  const MPesaPaymentRequest({
    required this.phoneNumber,
    required this.amount,
    required this.accountReference,
    required this.transactionDesc,
    this.callbackUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'amount': amount,
      'accountReference': accountReference,
      'transactionDesc': transactionDesc,
      'callbackUrl': callbackUrl,
    };
  }
}

/// M-Pesa payment response model
class MPesaPaymentResponse {
  final String merchantRequestId;
  final String checkoutRequestId;
  final String responseCode;
  final String responseDescription;
  final String? customerMessage;

  const MPesaPaymentResponse({
    required this.merchantRequestId,
    required this.checkoutRequestId,
    required this.responseCode,
    required this.responseDescription,
    this.customerMessage,
  });

  factory MPesaPaymentResponse.fromMap(Map<String, dynamic> map) {
    return MPesaPaymentResponse(
      merchantRequestId: map['MerchantRequestID'] ?? '',
      checkoutRequestId: map['CheckoutRequestID'] ?? '',
      responseCode: map['ResponseCode'] ?? '',
      responseDescription: map['ResponseDescription'] ?? '',
      customerMessage: map['CustomerMessage'],
    );
  }

  bool get isSuccess => responseCode == '0';
}
