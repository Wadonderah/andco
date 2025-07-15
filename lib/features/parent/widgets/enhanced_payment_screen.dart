import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/payment_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/payment_summary_card.dart';

class EnhancedPaymentScreen extends ConsumerStatefulWidget {
  const EnhancedPaymentScreen({super.key});

  @override
  ConsumerState<EnhancedPaymentScreen> createState() =>
      _EnhancedPaymentScreenState();
}

class _EnhancedPaymentScreenState extends ConsumerState<EnhancedPaymentScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Billing'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.payment), text: 'Pay Now'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.credit_card), text: 'Methods'),
            Tab(icon: Icon(Icons.notifications), text: 'Reminders'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPayNowTab(),
            _buildPaymentHistoryTab(),
            _buildPaymentMethodsTab(),
            _buildRemindersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPayNowTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outstanding Balance Card
          _buildOutstandingBalanceCard(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Quick Payment Options
          Text(
            'Quick Payment',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          _buildQuickPaymentOptions(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Custom Amount Payment
          Text(
            'Custom Payment',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          _buildCustomPaymentForm(),
        ],
      ),
    );
  }

  Widget _buildOutstandingBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.parentColor,
            AppColors.parentColor.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.parentColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Outstanding Balance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white.withOpacity(0.8),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            '\$245.00',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Due: March 15, 2024',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _payFullBalance(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.parentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
              ),
              child: const Text(
                'Pay Full Balance',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPaymentOptions() {
    final quickAmounts = [50.0, 100.0, 150.0, 200.0];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppConstants.paddingMedium,
        mainAxisSpacing: AppConstants.paddingMedium,
        childAspectRatio: 2.5,
      ),
      itemCount: quickAmounts.length,
      itemBuilder: (context, index) {
        final amount = quickAmounts[index];
        return _buildQuickPaymentCard(amount);
      },
    );
  }

  Widget _buildQuickPaymentCard(double amount) {
    return InkWell(
      onTap: () => _initiatePayment(amount),
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\$${amount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.parentColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quick Pay',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Amount',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (\$)',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                borderSide: const BorderSide(color: AppColors.parentColor),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              prefixIcon: const Icon(Icons.description),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                borderSide: const BorderSide(color: AppColors.parentColor),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPaymentMethodSelection(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.parentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
              ),
              child: const Text(
                'Proceed to Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTab() {
    final paymentRepository = ref.watch(paymentRepositoryProvider);
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Center(
              child: Text('Please log in to view payment history'));
        }

        return StreamBuilder<List<PaymentModel>>(
          stream: paymentRepository.getPaymentsStreamForUser(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final payments = snapshot.data ?? [];

            if (payments.isEmpty) {
              return _buildEmptyPaymentHistory();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                return PaymentSummaryCard(
                  payment: payments[index],
                  showActions: true,
                  onActionSelected: (action) =>
                      _handlePaymentAction(action, payments[index]),
                  onTap: () => _showPaymentDetails(payments[index]),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildEmptyPaymentHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'No Payment History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Your payment transactions will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard(PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(payment.status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(payment.status),
            color: _getStatusColor(payment.status),
          ),
        ),
        title: Text(
          payment.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(payment.createdAt)),
            Text(
              _getPaymentMethodText(payment.paymentMethod),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(payment.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(payment.status),
                style: TextStyle(
                  color: _getStatusColor(payment.status),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showPaymentDetails(payment),
      ),
    );
  }

  // Helper methods for payment status
  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return AppColors.success;
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.failed:
        return AppColors.error;
      case PaymentStatus.cancelled:
        return AppColors.textSecondary;
      case PaymentStatus.refunded:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.access_time;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.refunded:
        return Icons.refresh;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.stripe:
        return 'Credit Card';
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }

  // Placeholder methods for payment functionality
  void _payFullBalance() {
    _initiatePayment(245.00);
  }

  void _initiatePayment(double amount) async {
    if (amount <= 0) {
      _showErrorMessage('Please enter a valid amount');
      return;
    }

    setState(() {
      _selectedAmount = amount;
    });

    _showPaymentMethodSelection();
  }

  double _selectedAmount = 0.0;

  void _showPaymentMethodSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentMethodSelectionSheet(),
    );
  }

  Widget _buildPaymentMethodSelectionSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          Text(
            'Select Payment Method',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Credit/Debit Card
          _buildPaymentMethodOption(
            icon: Icons.credit_card,
            title: 'Credit/Debit Card',
            subtitle: 'Pay with Visa, Mastercard, or other cards',
            onTap: () {
              Navigator.pop(context);
              _processStripePayment();
            },
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // M-Pesa
          _buildPaymentMethodOption(
            icon: Icons.phone_android,
            title: 'M-Pesa',
            subtitle: 'Pay with your M-Pesa mobile money',
            onTap: () {
              Navigator.pop(context);
              _processMPesaPayment();
            },
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          border:
              Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.parentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: Icon(icon, color: AppColors.parentColor),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _processStripePayment() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current user
      final authState = ref.read(authControllerProvider);
      final user = authState.value;

      if (user == null) {
        Navigator.pop(context);
        _showErrorMessage('Please log in to make a payment');
        return;
      }

      // Create payment record in Firebase
      final payment = PaymentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        schoolId: user.schoolId ?? '',
        amount: _selectedAmount,
        currency: 'USD',
        paymentMethod: PaymentMethod.stripe,
        description: 'School transport payment',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: PaymentStatus.completed,
        completedAt: DateTime.now(),
        stripePaymentIntentId: 'pi_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Save payment to repository
      final paymentRepository = ref.read(paymentRepositoryProvider);
      await paymentRepository.create(payment);

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close payment method selection

      _showSuccessMessage('Payment processed successfully via Stripe!');

      // Send notification
      await NotificationService.instance.sendPaymentSuccessWithReceipt(
        userId: user.uid,
        paymentMethod: 'Stripe',
        amount: _selectedAmount,
        currency: 'USD',
        transactionId: payment.stripePaymentIntentId ?? '',
        email: user.email,
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorMessage('Payment failed: ${e.toString()}');
    }
  }

  void _processMPesaPayment() async {
    try {
      // Show M-Pesa phone number input dialog
      final phoneNumber = await _showMPesaPhoneDialog();
      if (phoneNumber == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current user
      final authState = ref.read(authControllerProvider);
      final user = authState.value;

      if (user == null) {
        Navigator.pop(context);
        _showErrorMessage('Please log in to make a payment');
        return;
      }

      // Create payment record in Firebase
      final payment = PaymentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        schoolId: user.schoolId ?? '',
        amount: _selectedAmount,
        currency: 'KES',
        paymentMethod: PaymentMethod.mpesa,
        description: 'School transport payment',
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: PaymentStatus.pending,
        checkoutRequestId: 'ws_CO_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Save payment to repository
      final paymentRepository = ref.read(paymentRepositoryProvider);
      await paymentRepository.create(payment);

      // Simulate STK push processing
      await Future.delayed(const Duration(seconds: 2));

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close payment method selection

      _showSuccessMessage(
          'M-Pesa payment request sent to $phoneNumber. Please complete on your phone.');

      // Simulate successful payment after delay
      Future.delayed(const Duration(seconds: 5), () async {
        final updatedPayment = payment.copyWith(
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
          mpesaReceiptNumber: 'QGR${DateTime.now().millisecondsSinceEpoch}',
        );

        await paymentRepository.update(
            updatedPayment.id, updatedPayment.toMap());

        if (mounted) {
          _showSuccessMessage('M-Pesa payment completed successfully!');
        }
      });
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorMessage('M-Pesa payment failed: ${e.toString()}');
    }
  }

  Future<String?> _showMPesaPhoneDialog() async {
    final phoneController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('M-Pesa Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your M-Pesa phone number:'),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '254712345678',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(context, phone);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.parentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPaymentDetails(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Payment ID', payment.id),
              _buildDetailRow('Amount',
                  '${payment.currency} ${payment.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Status',
                  payment.status.toString().split('.').last.toUpperCase()),
              _buildDetailRow(
                  'Method',
                  payment.paymentMethod
                      .toString()
                      .split('.')
                      .last
                      .toUpperCase()),
              _buildDetailRow('Description', payment.description),
              _buildDetailRow('Date',
                  DateFormat('MMM dd, yyyy HH:mm').format(payment.createdAt)),
              if (payment.stripePaymentIntentId != null)
                _buildDetailRow(
                    'Transaction ID', payment.stripePaymentIntentId!),
              if (payment.mpesaReceiptNumber != null)
                _buildDetailRow('M-Pesa Receipt', payment.mpesaReceiptNumber!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (payment.status == PaymentStatus.completed)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _downloadReceipt(payment);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.parentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Download Receipt'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _handlePaymentAction(String action, PaymentModel payment) {
    switch (action) {
      case 'view_details':
        _showPaymentDetails(payment);
        break;
      case 'download_receipt':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading receipt for ${payment.id}')),
        );
        break;
      case 'refund':
        _requestRefund(payment);
        break;
      case 'retry':
        _retryPayment(payment);
        break;
      case 'copy_id':
        // TODO: Implement copy to clipboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction ID copied to clipboard')),
        );
        break;
    }
  }

  void _requestRefund(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Refund'),
        content: Text(
            'Are you sure you want to request a refund for \$${payment.amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refund request submitted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Request Refund',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _retryPayment(PaymentModel payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Retry payment for ${payment.id}')),
    );
  }

  Widget _buildPaymentMethodsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Methods',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: _addPaymentMethod,
                icon: const Icon(Icons.add),
                label: const Text('Add Method'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.parentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Credit Cards Section
          _buildPaymentMethodSection(
            'Credit & Debit Cards',
            Icons.credit_card,
            [
              _buildCreditCardItem(
                'Visa ending in 4242',
                '**** **** **** 4242',
                'Expires 12/25',
                true,
              ),
              _buildCreditCardItem(
                'Mastercard ending in 8888',
                '**** **** **** 8888',
                'Expires 08/26',
                false,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Mobile Money Section
          _buildPaymentMethodSection(
            'Mobile Money',
            Icons.phone_android,
            [
              _buildMobileMoneyItem(
                'M-Pesa',
                '+254 712 345 678',
                false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(
      String title, IconData icon, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        ...items,
      ],
    );
  }

  Widget _buildCreditCardItem(
      String name, String number, String expiry, bool isDefault) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDefault ? AppColors.parentColor : AppColors.border,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.parentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.credit_card,
              color: AppColors.parentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.parentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  number,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  expiry,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handlePaymentMethodAction(value, name),
            itemBuilder: (context) => [
              if (!isDefault)
                const PopupMenuItem(
                  value: 'set_default',
                  child: Text('Set as Default'),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMoneyItem(String name, String number, bool isDefault) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDefault ? AppColors.parentColor : AppColors.border,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.phone_android,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.parentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  number,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handlePaymentMethodAction(value, name),
            itemBuilder: (context) => [
              if (!isDefault)
                const PopupMenuItem(
                  value: 'set_default',
                  child: Text('Set as Default'),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Reminders',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Upcoming Payments
          _buildReminderSection(
            'Upcoming Payments',
            Icons.schedule,
            [
              _buildReminderCard(
                'Monthly Subscription',
                '\$125.00',
                'Due in 3 days',
                'March 15, 2024',
                AppColors.warning,
                Icons.schedule,
              ),
              _buildReminderCard(
                'Extra Trip Fee',
                '\$25.00',
                'Due in 1 week',
                'March 22, 2024',
                AppColors.info,
                Icons.directions_bus,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Overdue Payments
          _buildReminderSection(
            'Overdue Payments',
            Icons.warning,
            [
              _buildReminderCard(
                'Late Fee',
                '\$15.00',
                'Overdue by 2 days',
                'March 10, 2024',
                AppColors.error,
                Icons.warning,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Reminder Settings
          _buildReminderSettings(),
        ],
      ),
    );
  }

  Widget _buildReminderSection(
      String title, IconData icon, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'No ${title.toLowerCase()}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ...items,
      ],
    );
  }

  Widget _buildReminderCard(
    String title,
    String amount,
    String status,
    String dueDate,
    Color statusColor,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  dueDate,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSettings() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminder Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          SwitchListTile(
            title: const Text('Email Reminders'),
            subtitle: const Text('Receive payment reminders via email'),
            value: true,
            onChanged: (value) {},
            activeColor: AppColors.parentColor,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('SMS Reminders'),
            subtitle: const Text('Receive payment reminders via SMS'),
            value: false,
            onChanged: (value) {},
            activeColor: AppColors.parentColor,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive payment reminders in the app'),
            value: true,
            onChanged: (value) {},
            activeColor: AppColors.parentColor,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ListTile(
            title: const Text('Reminder Frequency'),
            subtitle: const Text('3 days before due date'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // Action handlers
  void _addPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddPaymentMethodSheet(),
    );
  }

  Widget _buildAddPaymentMethodSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Payment Method',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.parentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.credit_card,
                      color: AppColors.parentColor,
                    ),
                  ),
                  title: const Text('Credit or Debit Card'),
                  subtitle: const Text('Visa, Mastercard, American Express'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _addCreditCard();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      color: Colors.green,
                    ),
                  ),
                  title: const Text('M-Pesa'),
                  subtitle: const Text('Mobile money payment'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _addMpesa();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePaymentMethodAction(String action, String methodName) {
    switch (action) {
      case 'set_default':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$methodName set as default')),
        );
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit $methodName')),
        );
        break;
      case 'delete':
        _confirmDeletePaymentMethod(methodName);
        break;
    }
  }

  void _confirmDeletePaymentMethod(String methodName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete $methodName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$methodName deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addCreditCard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Credit Card - Coming Soon')),
    );
  }

  void _downloadReceipt(PaymentModel payment) {
    // Simulate receipt download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Receipt for payment ${payment.id} downloaded'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addMpesa() {
    showDialog(
      context: context,
      builder: (context) => _buildAddMPesaDialog(),
    );
  }

  Widget _buildAddMPesaDialog() {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();

    return AlertDialog(
      title: const Text('Add M-Pesa Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'Enter account name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone Number',
                hintText: '254712345678',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This phone number will be used for M-Pesa payments',
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            final phone = phoneController.text.trim();

            if (name.isNotEmpty && phone.isNotEmpty) {
              Navigator.pop(context);
              _showSuccessMessage('M-Pesa account "$name" added successfully');
            } else {
              _showErrorMessage('Please fill in all fields');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.parentColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Account'),
        ),
      ],
    );
  }
}
