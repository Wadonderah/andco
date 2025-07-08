import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'payment_model.g.dart';

@HiveType(typeId: 15)
class PaymentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String schoolId;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String currency;

  @HiveField(5)
  final PaymentStatus status;

  @HiveField(6)
  final PaymentMethod paymentMethod;

  @HiveField(7)
  final String? stripePaymentIntentId;

  @HiveField(8)
  final String? mpesaReceiptNumber;

  @HiveField(9)
  final String? phoneNumber;

  @HiveField(10)
  final String? checkoutRequestId;

  @HiveField(11)
  final String description;

  @HiveField(12)
  final DateTime? completedAt;

  @HiveField(13)
  final DateTime? failedAt;

  @HiveField(14)
  final DateTime? cancelledAt;

  @HiveField(15)
  final String? failureReason;

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime updatedAt;

  @HiveField(18)
  final Map<String, dynamic>? metadata;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.schoolId,
    required this.amount,
    required this.currency,
    this.status = PaymentStatus.pending,
    required this.paymentMethod,
    this.stripePaymentIntentId,
    this.mpesaReceiptNumber,
    this.phoneNumber,
    this.checkoutRequestId,
    required this.description,
    this.completedAt,
    this.failedAt,
    this.cancelledAt,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${map['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${map['paymentMethod']}',
        orElse: () => PaymentMethod.stripe,
      ),
      stripePaymentIntentId: map['stripePaymentIntentId'],
      mpesaReceiptNumber: map['mpesaReceiptNumber'],
      phoneNumber: map['phoneNumber'],
      checkoutRequestId: map['checkoutRequestId'],
      description: map['description'] ?? '',
      completedAt: map['completedAt'] is Timestamp 
          ? (map['completedAt'] as Timestamp).toDate()
          : map['completedAt'] != null 
              ? DateTime.parse(map['completedAt'])
              : null,
      failedAt: map['failedAt'] is Timestamp 
          ? (map['failedAt'] as Timestamp).toDate()
          : map['failedAt'] != null 
              ? DateTime.parse(map['failedAt'])
              : null,
      cancelledAt: map['cancelledAt'] is Timestamp 
          ? (map['cancelledAt'] as Timestamp).toDate()
          : map['cancelledAt'] != null 
              ? DateTime.parse(map['cancelledAt'])
              : null,
      failureReason: map['failureReason'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt']),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'schoolId': schoolId,
      'amount': amount,
      'currency': currency,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'stripePaymentIntentId': stripePaymentIntentId,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'phoneNumber': phoneNumber,
      'checkoutRequestId': checkoutRequestId,
      'description': description,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'failureReason': failureReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? schoolId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    String? stripePaymentIntentId,
    String? mpesaReceiptNumber,
    String? phoneNumber,
    String? checkoutRequestId,
    String? description,
    DateTime? completedAt,
    DateTime? failedAt,
    DateTime? cancelledAt,
    String? failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      checkoutRequestId: checkoutRequestId ?? this.checkoutRequestId,
      description: description ?? this.description,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isPending => status == PaymentStatus.pending;
  bool get isCompleted => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isRefunded => status == PaymentStatus.refunded;

  bool get isStripePayment => paymentMethod == PaymentMethod.stripe;
  bool get isMpesaPayment => paymentMethod == PaymentMethod.mpesa;

  String get formattedAmount => '${currency.toUpperCase()} ${amount.toStringAsFixed(2)}';

  String get statusDisplayName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case PaymentMethod.stripe:
        return 'Credit/Debit Card';
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }

  Duration? get processingTime {
    if (completedAt != null) {
      return completedAt!.difference(createdAt);
    } else if (failedAt != null) {
      return failedAt!.difference(createdAt);
    }
    return null;
  }
}

@HiveType(typeId: 16)
enum PaymentStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  completed,

  @HiveField(2)
  failed,

  @HiveField(3)
  cancelled,

  @HiveField(4)
  refunded,
}

@HiveType(typeId: 17)
enum PaymentMethod {
  @HiveField(0)
  stripe,

  @HiveField(1)
  mpesa,

  @HiveField(2)
  bank,

  @HiveField(3)
  cash,
}
