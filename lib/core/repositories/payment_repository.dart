import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/payment_model.dart';
import 'base_repository.dart';

/// Repository for managing payment data
class PaymentRepository extends BaseRepository<PaymentModel> {
  @override
  String get collectionName => 'payments';

  @override
  PaymentModel fromMap(Map<String, dynamic> map) => PaymentModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(PaymentModel model) => model.toMap();

  /// Get payments for a specific user
  Future<List<PaymentModel>> getPaymentsForUser(String userId) async {
    return getWhere('userId', userId);
  }

  /// Get payments stream for a specific user
  Stream<List<PaymentModel>> getPaymentsStreamForUser(String userId) {
    return getStreamWhere('userId', userId);
  }

  /// Get payments for a specific school
  Future<List<PaymentModel>> getPaymentsForSchool(String schoolId) async {
    return getWhere('schoolId', schoolId);
  }

  /// Get payments stream for a specific school
  Stream<List<PaymentModel>> getPaymentsStreamForSchool(String schoolId) {
    return getStreamWhere('schoolId', schoolId);
  }

  /// Get payments by status
  Future<List<PaymentModel>> getPaymentsByStatus(PaymentStatus status) async {
    return getWhere('status', status.toString().split('.').last);
  }

  /// Get payments stream by status
  Stream<List<PaymentModel>> getPaymentsStreamByStatus(PaymentStatus status) {
    return getStreamWhere('status', status.toString().split('.').last);
  }

  /// Get payments by method
  Future<List<PaymentModel>> getPaymentsByMethod(PaymentMethod method) async {
    return getWhere('paymentMethod', method.toString().split('.').last);
  }

  /// Get payments stream by method
  Stream<List<PaymentModel>> getPaymentsStreamByMethod(PaymentMethod method) {
    return getStreamWhere('paymentMethod', method.toString().split('.').last);
  }

  /// Get pending payments
  Future<List<PaymentModel>> getPendingPayments() async {
    return getPaymentsByStatus(PaymentStatus.pending);
  }

  /// Get pending payments stream
  Stream<List<PaymentModel>> getPendingPaymentsStream() {
    return getPaymentsStreamByStatus(PaymentStatus.pending);
  }

  /// Get completed payments
  Future<List<PaymentModel>> getCompletedPayments() async {
    return getPaymentsByStatus(PaymentStatus.completed);
  }

  /// Get completed payments stream
  Stream<List<PaymentModel>> getCompletedPaymentsStream() {
    return getPaymentsStreamByStatus(PaymentStatus.completed);
  }

  /// Get failed payments
  Future<List<PaymentModel>> getFailedPayments() async {
    return getPaymentsByStatus(PaymentStatus.failed);
  }

  /// Get failed payments stream
  Stream<List<PaymentModel>> getFailedPaymentsStream() {
    return getPaymentsStreamByStatus(PaymentStatus.failed);
  }

  /// Get payments within date range
  Future<List<PaymentModel>> getPaymentsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await collection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering
      final allPayments = await getAll();
      return allPayments
          .where((payment) =>
              payment.createdAt.isAfter(startDate) &&
              payment.createdAt.isBefore(endDate))
          .toList();
    }
  }

  /// Get user payments within date range
  Future<List<PaymentModel>> getUserPaymentsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await collection
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback approach
      final userPayments = await getPaymentsForUser(userId);
      return userPayments
          .where((payment) =>
              payment.createdAt.isAfter(startDate) &&
              payment.createdAt.isBefore(endDate))
          .toList();
    }
  }

  /// Get school payments within date range
  Future<List<PaymentModel>> getSchoolPaymentsInDateRange(
    String schoolId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback approach
      final schoolPayments = await getPaymentsForSchool(schoolId);
      return schoolPayments
          .where((payment) =>
              payment.createdAt.isAfter(startDate) &&
              payment.createdAt.isBefore(endDate))
          .toList();
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? failureReason,
    String? receiptNumber,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.toString().split('.').last,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    switch (status) {
      case PaymentStatus.completed:
        updateData['completedAt'] = DateTime.now().toIso8601String();
        if (receiptNumber != null) {
          updateData['mpesaReceiptNumber'] = receiptNumber;
        }
        break;
      case PaymentStatus.failed:
        updateData['failedAt'] = DateTime.now().toIso8601String();
        if (failureReason != null) {
          updateData['failureReason'] = failureReason;
        }
        break;
      case PaymentStatus.cancelled:
        updateData['cancelledAt'] = DateTime.now().toIso8601String();
        break;
      default:
        break;
    }

    await updateById(paymentId, updateData);
  }

  /// Process payment (placeholder for actual payment processing)
  Future<PaymentModel> processPayment(PaymentModel payment) async {
    // This would typically integrate with actual payment processors
    // For now, we'll just create the payment record
    final paymentId = await create(payment);
    final createdPayment = await getById(paymentId);
    return createdPayment!;
  }

  /// Get payment status stream for a specific payment
  Stream<PaymentModel?> getPaymentStatusStream(String paymentId) {
    return collection.doc(paymentId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Get payment statistics for a school
  Future<Map<String, dynamic>> getSchoolPaymentStatistics(String schoolId) async {
    final payments = await getPaymentsForSchool(schoolId);
    
    final totalAmount = payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final completedPayments = payments.where((p) => p.status == PaymentStatus.completed);
    final completedAmount = completedPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
    
    return {
      'totalPayments': payments.length,
      'completedPayments': completedPayments.length,
      'pendingPayments': payments.where((p) => p.status == PaymentStatus.pending).length,
      'failedPayments': payments.where((p) => p.status == PaymentStatus.failed).length,
      'totalAmount': totalAmount,
      'completedAmount': completedAmount,
      'pendingAmount': payments
          .where((p) => p.status == PaymentStatus.pending)
          .fold<double>(0, (sum, payment) => sum + payment.amount),
    };
  }

  /// Get user payment statistics
  Future<Map<String, dynamic>> getUserPaymentStatistics(String userId) async {
    final payments = await getPaymentsForUser(userId);
    
    final totalAmount = payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final completedPayments = payments.where((p) => p.status == PaymentStatus.completed);
    final completedAmount = completedPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
    
    return {
      'totalPayments': payments.length,
      'completedPayments': completedPayments.length,
      'pendingPayments': payments.where((p) => p.status == PaymentStatus.pending).length,
      'failedPayments': payments.where((p) => p.status == PaymentStatus.failed).length,
      'totalAmount': totalAmount,
      'completedAmount': completedAmount,
      'pendingAmount': payments
          .where((p) => p.status == PaymentStatus.pending)
          .fold<double>(0, (sum, payment) => sum + payment.amount),
    };
  }

  /// Search payments by description
  Future<List<PaymentModel>> searchPaymentsByDescription(String query) async {
    final allPayments = await getAll();
    return allPayments
        .where((payment) => 
            payment.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Get recent payments (last 30 days)
  Future<List<PaymentModel>> getRecentPayments({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final endDate = DateTime.now();
    return getPaymentsInDateRange(startDate, endDate);
  }

  /// Get monthly payment summary
  Future<Map<String, double>> getMonthlyPaymentSummary(String schoolId, int year) async {
    final summary = <String, double>{};
    
    for (int month = 1; month <= 12; month++) {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
      
      final payments = await getSchoolPaymentsInDateRange(schoolId, startDate, endDate);
      final completedPayments = payments.where((p) => p.status == PaymentStatus.completed);
      final monthlyTotal = completedPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
      
      summary['${year}-${month.toString().padLeft(2, '0')}'] = monthlyTotal;
    }
    
    return summary;
  }
}
