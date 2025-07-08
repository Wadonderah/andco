import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: '1',
      type: PaymentType.card,
      name: 'Visa ending in 4242',
      details: '**** **** **** 4242',
      isDefault: true,
      expiryDate: '12/25',
    ),
    PaymentMethod(
      id: '2',
      type: PaymentType.mpesa,
      name: 'M-Pesa',
      details: '+254 712 345 678',
      isDefault: false,
      expiryDate: null,
    ),
  ];

  final List<PaymentHistory> _paymentHistory = [
    PaymentHistory(
      id: '1',
      amount: 125.00,
      date: DateTime.now().subtract(const Duration(days: 1)),
      description: 'Monthly Subscription - February 2024',
      status: PaymentStatus.completed,
      method: 'Visa *4242',
      transactionId: 'TXN_001234567',
    ),
    PaymentHistory(
      id: '2',
      amount: 25.00,
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Extra Trip - Emma Johnson',
      status: PaymentStatus.completed,
      method: 'M-Pesa',
      transactionId: 'MPX_987654321',
    ),
    PaymentHistory(
      id: '3',
      amount: 125.00,
      date: DateTime.now().subtract(const Duration(days: 32)),
      description: 'Monthly Subscription - January 2024',
      status: PaymentStatus.failed,
      method: 'Visa *4242',
      transactionId: 'TXN_001234566',
    ),
  ];

  final SubscriptionPlan _currentPlan = SubscriptionPlan(
    id: 'monthly_basic',
    name: 'Monthly Basic',
    price: 125.00,
    currency: 'USD',
    interval: 'month',
    features: [
      'Real-time GPS tracking',
      'Pickup & drop-off alerts',
      'In-app messaging',
      'Ride history',
      'Emergency SOS',
    ],
    nextBillingDate: DateTime.now().add(const Duration(days: 15)),
    isActive: true,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Billing'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Subscription'),
            Tab(text: 'Payment Methods'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubscriptionTab(),
          _buildPaymentMethodsTab(),
          _buildPaymentHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Plan Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text(
                        'Current Plan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  Text(
                    _currentPlan.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  Row(
                    children: [
                      Text(
                        '\$${_currentPlan.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '/${_currentPlan.interval}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  Text(
                    'Next billing: ${_formatDate(_currentPlan.nextBillingDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  // Features
                  Text(
                    'Included Features:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  ...(_currentPlan.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(feature),
                      ],
                    ),
                  )).toList()),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _managePlan,
                          child: const Text('Manage Plan'),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _upgradePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Upgrade'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Available Plans
          Text(
            'Available Plans',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          
          _buildPlanCard(
            'Basic Monthly',
            125.00,
            'month',
            ['Real-time tracking', 'Basic alerts', 'Ride history'],
            false,
          ),
          
          _buildPlanCard(
            'Premium Monthly',
            199.00,
            'month',
            ['Everything in Basic', 'Priority support', 'Advanced analytics', 'Multiple children'],
            false,
          ),
          
          _buildPlanCard(
            'Annual Basic',
            1250.00,
            'year',
            ['Same as Monthly Basic', '2 months free', 'Priority customer support'],
            true,
            discount: '17% OFF',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Payment Method Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addPaymentMethod,
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Payment Methods List
          Text(
            'Saved Payment Methods',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          
          ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Spent This Year',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${_calculateYearlyTotal().toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _downloadInvoices,
                    icon: const Icon(Icons.download),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Payment History List
          Text(
            'Payment History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          
          ..._paymentHistory.map((payment) => _buildPaymentHistoryCard(payment)).toList(),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, double price, String interval, List<String> features, bool isPopular, {String? discount}) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (discount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.paddingSmall),
                
                Row(
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '/$interval',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.paddingMedium),
                
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                )).toList(),
                
                const SizedBox(height: AppConstants.paddingMedium),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectPlan(name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? AppColors.primary : AppColors.secondary,
                    ),
                    child: Text(isPopular ? 'Choose Plan' : 'Select'),
                  ),
                ),
              ],
            ),
          ),
          
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(AppConstants.radiusMedium),
                    bottomLeft: Radius.circular(AppConstants.radiusMedium),
                  ),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final icon = method.type == PaymentType.card ? Icons.credit_card : Icons.phone_android;
    final color = method.type == PaymentType.card ? AppColors.primary : AppColors.success;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(child: Text(method.name)),
            if (method.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(method.details),
            if (method.expiryDate != null)
              Text('Expires: ${method.expiryDate}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handlePaymentMethodAction(action, method),
          itemBuilder: (context) => [
            if (!method.isDefault)
              const PopupMenuItem(
                value: 'default',
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
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard(PaymentHistory payment) {
    final statusColor = payment.status == PaymentStatus.completed 
        ? AppColors.success 
        : AppColors.error;
    final statusIcon = payment.status == PaymentStatus.completed 
        ? Icons.check_circle 
        : Icons.error;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(payment.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_formatDate(payment.date)} • ${payment.method}'),
            Text('Transaction ID: ${payment.transactionId}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${payment.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                payment.status.name.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showPaymentDetails(payment),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double _calculateYearlyTotal() {
    final now = DateTime.now();
    return _paymentHistory
        .where((payment) => 
            payment.date.year == now.year && 
            payment.status == PaymentStatus.completed)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  void _managePlan() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Manage Subscription',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ListTile(
              leading: const Icon(Icons.pause),
              title: const Text('Pause Subscription'),
              subtitle: const Text('Temporarily pause your subscription'),
              onTap: () {
                Navigator.pop(context);
                _pauseSubscription();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel Subscription'),
              subtitle: const Text('Cancel your subscription'),
              onTap: () {
                Navigator.pop(context);
                _cancelSubscription();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _upgradePlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan upgrade will be implemented')),
    );
  }

  void _selectPlan(String planName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected plan: $planName')),
    );
  }

  void _addPaymentMethod() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Payment Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Credit/Debit Card'),
              subtitle: const Text('Visa, Mastercard, American Express'),
              onTap: () {
                Navigator.pop(context);
                _addCreditCard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('M-Pesa'),
              subtitle: const Text('Mobile money payment'),
              onTap: () {
                Navigator.pop(context);
                _addMPesa();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handlePaymentMethodAction(String action, PaymentMethod method) {
    switch (action) {
      case 'default':
        _setDefaultPaymentMethod(method);
        break;
      case 'edit':
        _editPaymentMethod(method);
        break;
      case 'delete':
        _deletePaymentMethod(method);
        break;
    }
  }

  void _showPaymentDetails(PaymentHistory payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '\$${payment.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Date', _formatDate(payment.date)),
            _buildDetailRow('Method', payment.method),
            _buildDetailRow('Status', payment.status.name.toUpperCase()),
            _buildDetailRow('Transaction ID', payment.transactionId),
            _buildDetailRow('Description', payment.description),
          ],
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
              child: const Text('Download Receipt'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _downloadInvoices() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading invoices...')),
    );
  }

  void _pauseSubscription() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription paused')),
    );
  }

  void _cancelSubscription() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('Are you sure you want to cancel your subscription? You will lose access to all premium features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subscription cancelled')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  void _addCreditCard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credit card setup will be implemented')),
    );
  }

  void _addMPesa() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('M-Pesa setup will be implemented')),
    );
  }

  void _setDefaultPaymentMethod(PaymentMethod method) {
    setState(() {
      for (var pm in _paymentMethods) {
        pm.isDefault = pm.id == method.id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${method.name} set as default')),
    );
  }

  void _editPaymentMethod(PaymentMethod method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${method.name}')),
    );
  }

  void _deletePaymentMethod(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete ${method.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _paymentMethods.removeWhere((pm) => pm.id == method.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${method.name} deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _downloadReceipt(PaymentHistory payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading receipt for ${payment.transactionId}')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum PaymentType { card, mpesa }
enum PaymentStatus { completed, failed, pending }

class PaymentMethod {
  final String id;
  final PaymentType type;
  final String name;
  final String details;
  bool isDefault;
  final String? expiryDate;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.details,
    required this.isDefault,
    this.expiryDate,
  });
}

class PaymentHistory {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final PaymentStatus status;
  final String method;
  final String transactionId;

  PaymentHistory({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    required this.status,
    required this.method,
    required this.transactionId,
  });
}

class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String interval;
  final List<String> features;
  final DateTime nextBillingDate;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.interval,
    required this.features,
    required this.nextBillingDate,
    required this.isActive,
  });
}
