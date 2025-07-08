import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  PaymentProvider _selectedProvider = PaymentProvider.all;
  TransactionStatus _selectedStatus = TransactionStatus.all;
  DateRange _selectedDateRange = DateRange.thisMonth;

  final List<Transaction> _transactions = [
    Transaction(
      id: 'txn_001',
      schoolId: '1',
      schoolName: 'Greenwood Elementary',
      amount: 2500.00,
      currency: 'USD',
      provider: PaymentProvider.stripe,
      status: TransactionStatus.completed,
      type: TransactionType.subscription,
      description: 'Monthly Premium Subscription',
      date: DateTime.now().subtract(const Duration(days: 1)),
      stripePaymentId: 'pi_1234567890',
      mpesaReceiptNumber: null,
    ),
    Transaction(
      id: 'txn_002',
      schoolId: '2',
      schoolName: 'Riverside High School',
      amount: 5000.00,
      currency: 'USD',
      provider: PaymentProvider.stripe,
      status: TransactionStatus.completed,
      type: TransactionType.subscription,
      description: 'Monthly Enterprise Subscription',
      date: DateTime.now().subtract(const Duration(days: 2)),
      stripePaymentId: 'pi_0987654321',
      mpesaReceiptNumber: null,
    ),
    Transaction(
      id: 'txn_003',
      schoolId: '3',
      schoolName: 'Sunset Academy',
      amount: 1200.00,
      currency: 'KES',
      provider: PaymentProvider.mpesa,
      status: TransactionStatus.completed,
      type: TransactionType.subscription,
      description: 'Monthly Basic Subscription',
      date: DateTime.now().subtract(const Duration(days: 3)),
      stripePaymentId: null,
      mpesaReceiptNumber: 'QHX12345678',
    ),
    Transaction(
      id: 'txn_004',
      schoolId: '1',
      schoolName: 'Greenwood Elementary',
      amount: 150.00,
      currency: 'USD',
      provider: PaymentProvider.stripe,
      status: TransactionStatus.failed,
      type: TransactionType.addon,
      description: 'Additional GPS Tracking Feature',
      date: DateTime.now().subtract(const Duration(days: 4)),
      stripePaymentId: 'pi_failed123',
      mpesaReceiptNumber: null,
    ),
  ];

  final List<RevenueData> _revenueData = [
    RevenueData(month: 'Jan', stripe: 45000, mpesa: 12000),
    RevenueData(month: 'Feb', stripe: 48000, mpesa: 15000),
    RevenueData(month: 'Mar', stripe: 52000, mpesa: 18000),
    RevenueData(month: 'Apr', stripe: 55000, mpesa: 20000),
    RevenueData(month: 'May', stripe: 58000, mpesa: 22000),
    RevenueData(month: 'Jun', stripe: 62000, mpesa: 25000),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Financial Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _exportFinancialReport,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PaymentProvider>(
                        value: _selectedProvider,
                        decoration: InputDecoration(
                          labelText: 'Payment Provider',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        items: PaymentProvider.values.map((provider) {
                          return DropdownMenuItem(
                            value: provider,
                            child: Text(provider.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProvider = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: DropdownButtonFormField<TransactionStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status Filter',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        items: TransactionStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: DropdownButtonFormField<DateRange>(
                        value: _selectedDateRange,
                        decoration: InputDecoration(
                          labelText: 'Date Range',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        items: DateRange.values.map((range) {
                          return DropdownMenuItem(
                            value: range,
                            child: Text(range.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDateRange = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Financial Summary Cards
                Row(
                  children: [
                    _buildSummaryCard(
                        'Total Revenue',
                        '\$${_getTotalRevenue().toStringAsFixed(2)}',
                        AppColors.success,
                        Icons.attach_money),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildSummaryCard(
                        'Stripe Revenue',
                        '\$${_getStripeRevenue().toStringAsFixed(2)}',
                        AppColors.info,
                        Icons.credit_card),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildSummaryCard(
                        'M-Pesa Revenue',
                        'KES ${_getMpesaRevenue().toStringAsFixed(2)}',
                        AppColors.warning,
                        Icons.phone_android),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildSummaryCard(
                        'Failed Transactions',
                        _getFailedTransactionCount().toString(),
                        AppColors.error,
                        Icons.error_outline),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.success,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.success,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Transactions'),
                Tab(text: 'Revenue Analytics'),
                Tab(text: 'Payment Management'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTransactionsTab(),
                _buildRevenueAnalyticsTab(),
                _buildPaymentManagementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Revenue Breakdown
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revenue Breakdown',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildRevenueBreakdownItem('Stripe Payments',
                            _getStripeRevenue(), AppColors.info),
                        _buildRevenueBreakdownItem('M-Pesa Payments',
                            _getMpesaRevenue(), AppColors.warning),
                        const Divider(),
                        _buildRevenueBreakdownItem('Total Revenue',
                            _getTotalRevenue(), AppColors.success),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transaction Stats',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildStatItem('Total Transactions',
                            _transactions.length.toString()),
                        _buildStatItem(
                            'Successful',
                            _getTransactionCount(TransactionStatus.completed)
                                .toString()),
                        _buildStatItem(
                            'Failed',
                            _getTransactionCount(TransactionStatus.failed)
                                .toString()),
                        _buildStatItem(
                            'Pending',
                            _getTransactionCount(TransactionStatus.pending)
                                .toString()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Recent Transactions
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.take(5).length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return _buildTransactionCard(transaction);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownItem(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    final filteredTransactions = _getFilteredTransactions();

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'All Transactions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${filteredTransactions.length} transactions',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                return _buildTransactionCard(transaction);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getProviderColor(transaction.provider)
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    _getProviderIcon(transaction.provider),
                    color: _getProviderColor(transaction.provider),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.schoolName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        transaction.description,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        _formatDate(transaction.date),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status)
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: Text(
                        transaction.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(transaction.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewTransactionDetails(transaction),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
                if (transaction.status == TransactionStatus.failed)
                  TextButton.icon(
                    onPressed: () => _retryTransaction(transaction),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _refundTransaction(transaction),
                  icon: const Icon(Icons.undo),
                  label: const Text('Refund'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueAnalyticsTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Revenue Chart Placeholder
          Card(
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                children: [
                  const Text(
                    'Monthly Revenue Trend',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: const Center(
                        child: Text(
                          'Revenue Chart\n(Chart implementation would go here)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Revenue by Provider
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stripe Analytics',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildAnalyticsItem('Total Revenue',
                            '\$${_getStripeRevenue().toStringAsFixed(2)}'),
                        _buildAnalyticsItem('Transactions',
                            _getStripeTransactionCount().toString()),
                        _buildAnalyticsItem('Success Rate',
                            '${_getStripeSuccessRate().toStringAsFixed(1)}%'),
                        _buildAnalyticsItem('Avg Transaction',
                            '\$${_getStripeAverageTransaction().toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'M-Pesa Analytics',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildAnalyticsItem('Total Revenue',
                            'KES ${_getMpesaRevenue().toStringAsFixed(2)}'),
                        _buildAnalyticsItem('Transactions',
                            _getMpesaTransactionCount().toString()),
                        _buildAnalyticsItem('Success Rate',
                            '${_getMpesaSuccessRate().toStringAsFixed(1)}%'),
                        _buildAnalyticsItem('Avg Transaction',
                            'KES ${_getMpesaAverageTransaction().toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentManagementTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Payment Provider Settings
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.credit_card,
                                color: AppColors.info),
                            const SizedBox(width: AppConstants.paddingSmall),
                            const Text(
                              'Stripe Configuration',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildConfigItem('Status', 'Active', AppColors.success),
                        _buildConfigItem(
                            'API Version', '2023-10-16', AppColors.textPrimary),
                        _buildConfigItem(
                            'Webhook Status', 'Connected', AppColors.success),
                        const SizedBox(height: AppConstants.paddingMedium),
                        ElevatedButton.icon(
                          onPressed: _configureStripe,
                          icon: const Icon(Icons.settings),
                          label: const Text('Configure'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.info),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone_android,
                                color: AppColors.warning),
                            const SizedBox(width: AppConstants.paddingSmall),
                            const Text(
                              'M-Pesa Configuration',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildConfigItem('Status', 'Active', AppColors.success),
                        _buildConfigItem(
                            'Shortcode', '174379', AppColors.textPrimary),
                        _buildConfigItem(
                            'Callback URL', 'Configured', AppColors.success),
                        const SizedBox(height: AppConstants.paddingMedium),
                        ElevatedButton.icon(
                          onPressed: _configureMpesa,
                          icon: const Icon(Icons.settings),
                          label: const Text('Configure'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Failed Transactions
          const Text(
            'Failed Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Expanded(
            child: ListView.builder(
              itemCount: _getFailedTransactions().length,
              itemBuilder: (context, index) {
                final transaction = _getFailedTransactions()[index];
                return _buildFailedTransactionCard(transaction);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedTransactionCard(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(Icons.error, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.schoolName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${transaction.currency} ${transaction.amount.toStringAsFixed(2)} - ${transaction.description}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    _formatDate(transaction.date),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _retryTransaction(transaction),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  List<Transaction> _getFilteredTransactions() {
    return _transactions.where((transaction) {
      final matchesProvider = _selectedProvider == PaymentProvider.all ||
          transaction.provider == _selectedProvider;
      final matchesStatus = _selectedStatus == TransactionStatus.all ||
          transaction.status == _selectedStatus;

      // Date range filtering would be implemented here
      return matchesProvider && matchesStatus;
    }).toList();
  }

  List<Transaction> _getFailedTransactions() {
    return _transactions
        .where((t) => t.status == TransactionStatus.failed)
        .toList();
  }

  double _getTotalRevenue() {
    return _transactions
        .where((t) => t.status == TransactionStatus.completed)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  double _getStripeRevenue() {
    return _transactions
        .where((t) =>
            t.provider == PaymentProvider.stripe &&
            t.status == TransactionStatus.completed)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  double _getMpesaRevenue() {
    return _transactions
        .where((t) =>
            t.provider == PaymentProvider.mpesa &&
            t.status == TransactionStatus.completed)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  int _getFailedTransactionCount() {
    return _transactions
        .where((t) => t.status == TransactionStatus.failed)
        .length;
  }

  int _getTransactionCount(TransactionStatus status) {
    return _transactions.where((t) => t.status == status).length;
  }

  int _getStripeTransactionCount() {
    return _transactions
        .where((t) => t.provider == PaymentProvider.stripe)
        .length;
  }

  int _getMpesaTransactionCount() {
    return _transactions
        .where((t) => t.provider == PaymentProvider.mpesa)
        .length;
  }

  double _getStripeSuccessRate() {
    final stripeTransactions =
        _transactions.where((t) => t.provider == PaymentProvider.stripe);
    if (stripeTransactions.isEmpty) return 0.0;
    final successful = stripeTransactions
        .where((t) => t.status == TransactionStatus.completed)
        .length;
    return (successful / stripeTransactions.length) * 100;
  }

  double _getMpesaSuccessRate() {
    final mpesaTransactions =
        _transactions.where((t) => t.provider == PaymentProvider.mpesa);
    if (mpesaTransactions.isEmpty) return 0.0;
    final successful = mpesaTransactions
        .where((t) => t.status == TransactionStatus.completed)
        .length;
    return (successful / mpesaTransactions.length) * 100;
  }

  double _getStripeAverageTransaction() {
    final stripeTransactions = _transactions.where((t) =>
        t.provider == PaymentProvider.stripe &&
        t.status == TransactionStatus.completed);
    if (stripeTransactions.isEmpty) return 0.0;
    return stripeTransactions.fold<double>(0, (sum, t) => sum + t.amount) /
        stripeTransactions.length;
  }

  double _getMpesaAverageTransaction() {
    final mpesaTransactions = _transactions.where((t) =>
        t.provider == PaymentProvider.mpesa &&
        t.status == TransactionStatus.completed);
    if (mpesaTransactions.isEmpty) return 0.0;
    return mpesaTransactions.fold<double>(0, (sum, t) => sum + t.amount) /
        mpesaTransactions.length;
  }

  Color _getProviderColor(PaymentProvider provider) {
    switch (provider) {
      case PaymentProvider.stripe:
        return AppColors.info;
      case PaymentProvider.mpesa:
        return AppColors.warning;
      case PaymentProvider.all:
        return AppColors.primary;
    }
  }

  IconData _getProviderIcon(PaymentProvider provider) {
    switch (provider) {
      case PaymentProvider.stripe:
        return Icons.credit_card;
      case PaymentProvider.mpesa:
        return Icons.phone_android;
      case PaymentProvider.all:
        return Icons.payment;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.pending:
        return AppColors.warning;
      case TransactionStatus.failed:
        return AppColors.error;
      case TransactionStatus.all:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action Methods
  void _exportFinancialReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Financial Report'),
        content: const Text(
            'Financial report export functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _viewTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${transaction.id}'),
            Text('School: ${transaction.schoolName}'),
            Text(
                'Amount: ${transaction.currency} ${transaction.amount.toStringAsFixed(2)}'),
            Text('Provider: ${transaction.provider.displayName}'),
            Text('Status: ${transaction.status.displayName}'),
            Text('Type: ${transaction.type.displayName}'),
            Text('Description: ${transaction.description}'),
            Text('Date: ${_formatDate(transaction.date)}'),
            if (transaction.stripePaymentId != null)
              Text('Stripe ID: ${transaction.stripePaymentId}'),
            if (transaction.mpesaReceiptNumber != null)
              Text('M-Pesa Receipt: ${transaction.mpesaReceiptNumber}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _retryTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Transaction'),
        content: Text(
            'Are you sure you want to retry the transaction for ${transaction.schoolName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Retry logic would be implemented here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction retry initiated')),
              );
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _refundTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund Transaction'),
        content: Text(
            'Are you sure you want to refund ${transaction.currency} ${transaction.amount.toStringAsFixed(2)} to ${transaction.schoolName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Refund logic would be implemented here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refund initiated')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Refund'),
          ),
        ],
      ),
    );
  }

  void _configureStripe() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Stripe'),
        content: const Text(
            'Stripe configuration interface would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _configureMpesa() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure M-Pesa'),
        content: const Text(
            'M-Pesa configuration interface would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Data Models
enum PaymentProvider {
  all('All'),
  stripe('Stripe'),
  mpesa('M-Pesa');

  const PaymentProvider(this.displayName);
  final String displayName;
}

enum TransactionStatus {
  all('All'),
  completed('Completed'),
  pending('Pending'),
  failed('Failed');

  const TransactionStatus(this.displayName);
  final String displayName;
}

enum TransactionType {
  subscription('Subscription'),
  addon('Add-on'),
  refund('Refund');

  const TransactionType(this.displayName);
  final String displayName;
}

enum DateRange {
  thisMonth('This Month'),
  lastMonth('Last Month'),
  last3Months('Last 3 Months'),
  last6Months('Last 6 Months'),
  thisYear('This Year');

  const DateRange(this.displayName);
  final String displayName;
}

class Transaction {
  final String id;
  final String schoolId;
  final String schoolName;
  final double amount;
  final String currency;
  final PaymentProvider provider;
  final TransactionStatus status;
  final TransactionType type;
  final String description;
  final DateTime date;
  final String? stripePaymentId;
  final String? mpesaReceiptNumber;

  Transaction({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.status,
    required this.type,
    required this.description,
    required this.date,
    this.stripePaymentId,
    this.mpesaReceiptNumber,
  });
}

class RevenueData {
  final String month;
  final double stripe;
  final double mpesa;

  RevenueData({
    required this.month,
    required this.stripe,
    required this.mpesa,
  });
}
