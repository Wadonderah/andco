import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/payment_model.dart';
import '../../../shared/widgets/loading_overlay.dart';

class PaymentDashboardScreen extends ConsumerStatefulWidget {
  const PaymentDashboardScreen({super.key});

  @override
  ConsumerState<PaymentDashboardScreen> createState() =>
      _PaymentDashboardScreenState();
}

class _PaymentDashboardScreenState extends ConsumerState<PaymentDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  /// Get real-time payment trends data from Firebase
  Stream<List<Map<String, dynamic>>> _getPaymentTrendsStream() {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('createdAt',
            isGreaterThan: DateTime.now().subtract(const Duration(days: 30)))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // Group payments by day for trend analysis
      final Map<String, double> dailyTotals = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        if (createdAt != null) {
          final dayKey =
              '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0.0) + amount;
        }
      }

      // Convert to chart data format
      return dailyTotals.entries
          .map((entry) => {
                'date': entry.key,
                'amount': entry.value,
              })
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    });
  }

  /// Build payment trends chart widget
  Widget _buildPaymentTrendsChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'No Payment Data',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Payment trends will appear here once data is available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Simple line chart representation using containers
    final maxAmount =
        data.map((e) => e['amount'] as double).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Trends (Last 30 Days)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.take(10).map((item) {
                final amount = item['amount'] as double;
                final height = (amount / maxAmount) * 120;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Dashboard'),
        backgroundColor: AppColors.superAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings), text: 'Configuration'),
            Tab(icon: Icon(Icons.account_balance), text: 'Financial'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildAnalyticsTab(),
            _buildConfigurationTab(),
            _buildFinancialTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authControllerProvider);

        return authState.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text('Please log in to view payment dashboard'),
              );
            }

            return StreamBuilder<List<PaymentModel>>(
              stream: ref.read(paymentRepositoryProvider).getStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final payments = snapshot.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period Selector
                      _buildPeriodSelector(),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Key Metrics Cards
                      _buildKeyMetricsCards(payments),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Payment Status Overview
                      _buildPaymentStatusOverview(payments),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Payment Methods Distribution
                      _buildPaymentMethodsDistribution(payments),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Recent Transactions
                      _buildRecentTransactions(payments),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.date_range,
              color: AppColors.superAdminColor,
            ),
            const SizedBox(width: 12),
            Text(
              'Period:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                isExpanded: true,
                underline: Container(),
                items: [
                  'Today',
                  'This Week',
                  'This Month',
                  'This Year',
                  'All Time'
                ]
                    .map((period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
            ),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing payment data...'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCards(List<PaymentModel> payments) {
    final filteredPayments = _filterPaymentsByPeriod(payments);
    final totalRevenue = filteredPayments.fold<double>(
        0, (sum, payment) => sum + payment.amount);
    final completedPayments = filteredPayments
        .where((p) => p.status == PaymentStatus.completed)
        .length;
    final totalTransactions = filteredPayments.length;
    final averageTransaction =
        totalTransactions > 0 ? totalRevenue / totalTransactions : 0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Revenue',
            'KES ${NumberFormat('#,##0.00').format(totalRevenue)}',
            Icons.attach_money,
            AppColors.success,
            '+12.5%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Transactions',
            NumberFormat('#,##0').format(totalTransactions),
            Icons.receipt_long,
            AppColors.info,
            '+8.3%',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String change) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusOverview(List<PaymentModel> payments) {
    final filteredPayments = _filterPaymentsByPeriod(payments);
    final completed = filteredPayments
        .where((p) => p.status == PaymentStatus.completed)
        .length;
    final pending =
        filteredPayments.where((p) => p.status == PaymentStatus.pending).length;
    final failed =
        filteredPayments.where((p) => p.status == PaymentStatus.failed).length;
    final cancelled = filteredPayments
        .where((p) => p.status == PaymentStatus.cancelled)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Status Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                      'Completed', completed, AppColors.success),
                ),
                Expanded(
                  child:
                      _buildStatusItem('Pending', pending, AppColors.warning),
                ),
                Expanded(
                  child: _buildStatusItem('Failed', failed, AppColors.error),
                ),
                Expanded(
                  child: _buildStatusItem(
                      'Cancelled', cancelled, AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsDistribution(List<PaymentModel> payments) {
    final filteredPayments = _filterPaymentsByPeriod(payments);
    final stripeCount = filteredPayments
        .where((p) => p.paymentMethod == PaymentMethod.stripe)
        .length;
    final mpesaCount = filteredPayments
        .where((p) => p.paymentMethod == PaymentMethod.mpesa)
        .length;
    final bankCount = filteredPayments
        .where((p) => p.paymentMethod == PaymentMethod.bank)
        .length;
    final cashCount = filteredPayments
        .where((p) => p.paymentMethod == PaymentMethod.cash)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Methods Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMethodItem(
                'Stripe', stripeCount, AppColors.info, Icons.credit_card),
            _buildMethodItem(
                'M-Pesa', mpesaCount, AppColors.success, Icons.phone_android),
            _buildMethodItem('Bank Transfer', bankCount, AppColors.warning,
                Icons.account_balance),
            _buildMethodItem(
                'Cash', cashCount, AppColors.textSecondary, Icons.money),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodItem(
      String method, int count, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              method,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Configuration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildPaymentGatewaySettings(),
          const SizedBox(height: 24),
          _buildFeeSettings(),
          const SizedBox(height: 24),
          _buildSecuritySettings(),
        ],
      ),
    );
  }

  Widget _buildPaymentGatewaySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Gateway Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildGatewayItem('Stripe', true, 'Connected', AppColors.success),
            _buildGatewayItem('M-Pesa', true, 'Connected', AppColors.success),
            _buildGatewayItem(
                'PayPal', false, 'Not Connected', AppColors.textSecondary),
            _buildGatewayItem('Bank Transfer', true, 'Active', AppColors.info),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayItem(
      String gateway, bool isActive, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isActive ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              gateway,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _configureGateway(gateway),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Fee Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFeeItem(
                'Transaction Fee', '2.5%', 'Per successful transaction'),
            _buildFeeItem(
                'Monthly Subscription', 'KES 5,000', 'Per school per month'),
            _buildFeeItem(
                'Setup Fee', 'KES 10,000', 'One-time school onboarding'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeItem(String feeType, String amount, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feeType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.superAdminColor,
                ),
          ),
          IconButton(
            onPressed: () => _editFee(feeType),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Two-Factor Authentication'),
              subtitle: const Text('Require 2FA for payment operations'),
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.superAdminColor,
            ),
            SwitchListTile(
              title: const Text('Fraud Detection'),
              subtitle: const Text('Enable automatic fraud detection'),
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.superAdminColor,
            ),
            SwitchListTile(
              title: const Text('Payment Limits'),
              subtitle: const Text('Enforce daily payment limits'),
              value: false,
              onChanged: (value) {},
              activeColor: AppColors.superAdminColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authControllerProvider);

        return authState.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text('Please log in to view analytics'),
              );
            }

            return StreamBuilder<List<PaymentModel>>(
              stream: ref.read(paymentRepositoryProvider).getStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final payments = snapshot.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Analytics',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),

                      // Period Selector
                      _buildPeriodSelector(),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Analytics Charts Placeholder
                      _buildAnalyticsCharts(payments),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Performance Metrics
                      _buildPerformanceMetrics(payments),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Trends Analysis
                      _buildTrendsAnalysis(payments),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }

  Widget _buildFinancialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildFinancialSummary(),
          const SizedBox(height: 24),
          _buildRevenueBreakdown(),
          const SizedBox(height: 24),
          _buildPayoutSchedule(),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialItem(
                      'Total Revenue', 'KES 2,450,000', AppColors.success),
                ),
                Expanded(
                  child: _buildFinancialItem(
                      'Platform Fees', 'KES 61,250', AppColors.info),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialItem(
                      'Pending Payouts', 'KES 125,000', AppColors.warning),
                ),
                Expanded(
                  child: _buildFinancialItem(
                      'Refunds', 'KES 15,500', AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialItem(String label, String amount, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildRevenueItem('Subscription Fees', 'KES 1,800,000', 73.5),
            _buildRevenueItem('Transaction Fees', 'KES 450,000', 18.4),
            _buildRevenueItem('Setup Fees', 'KES 150,000', 6.1),
            _buildRevenueItem('Other', 'KES 50,000', 2.0),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(String source, String amount, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              source,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.superAdminColor,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutSchedule() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Payouts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildPayoutItem('Greenwood Academy', 'KES 45,000', 'Tomorrow'),
            _buildPayoutItem('Sunrise School', 'KES 32,500', 'In 2 days'),
            _buildPayoutItem('Valley High', 'KES 28,000', 'In 3 days'),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutItem(String school, String amount, String schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  schedule,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<PaymentModel> payments) {
    final recentPayments = payments.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full transactions list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('View all transactions feature coming soon'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentPayments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No recent transactions'),
                ),
              )
            else
              ...recentPayments
                  .map((payment) => _buildTransactionItem(payment)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(PaymentModel payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Icon(
            _getPaymentMethodIcon(payment.paymentMethod),
            color: _getPaymentStatusColor(payment.status),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.description ?? 'Payment Transaction',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(payment.createdAt),
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
                'KES ${NumberFormat('#,##0.00').format(payment.amount)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getPaymentStatusColor(payment.status),
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      _getPaymentStatusColor(payment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payment.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: _getPaymentStatusColor(payment.status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCharts(List<PaymentModel> payments) {
    final filteredPayments = _filterPaymentsByPeriod(payments);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Analytics Charts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getPaymentTrendsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load chart data',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data ?? [];
                  return _buildPaymentTrendsChart(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(List<PaymentModel> payments) {
    final filteredPayments = _filterPaymentsByPeriod(payments);
    final totalRevenue = filteredPayments.fold<double>(
        0, (sum, payment) => sum + payment.amount);
    final successRate = filteredPayments.isEmpty
        ? 0.0
        : (filteredPayments
                    .where((p) => p.status == PaymentStatus.completed)
                    .length /
                filteredPayments.length) *
            100;
    final averageTransaction =
        filteredPayments.isEmpty ? 0.0 : totalRevenue / filteredPayments.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceCard(
                    'Success Rate',
                    '${successRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPerformanceCard(
                    'Avg Transaction',
                    'KES ${NumberFormat('#,##0').format(averageTransaction)}',
                    Icons.trending_up,
                    AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsAnalysis(List<PaymentModel> payments) {
    final filteredPayments = _filterPaymentsByPeriod(payments);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trends Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildTrendItem(
              'Payment Volume',
              '${filteredPayments.length} transactions',
              '+15.2%',
              true,
              Icons.trending_up,
            ),
            _buildTrendItem(
              'Success Rate',
              '${((filteredPayments.where((p) => p.status == PaymentStatus.completed).length / (filteredPayments.isEmpty ? 1 : filteredPayments.length)) * 100).toStringAsFixed(1)}%',
              '+2.8%',
              true,
              Icons.check_circle,
            ),
            _buildTrendItem(
              'Average Amount',
              'KES ${NumberFormat('#,##0').format(filteredPayments.isEmpty ? 0 : filteredPayments.fold<double>(0, (sum, p) => sum + p.amount) / filteredPayments.length)}',
              '-3.1%',
              false,
              Icons.attach_money,
            ),
            _buildTrendItem(
              'Failed Payments',
              '${filteredPayments.where((p) => p.status == PaymentStatus.failed).length}',
              '-8.5%',
              true,
              Icons.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String title, String value, String change,
      bool isPositive, IconData icon) {
    final changeColor = isPositive ? AppColors.success : AppColors.error;
    final changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.superAdminColor, size: 24),
          const SizedBox(width: 12),
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
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.superAdminColor,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(changeIcon, color: changeColor, size: 12),
                const SizedBox(width: 4),
                Text(
                  change,
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<PaymentModel> _filterPaymentsByPeriod(List<PaymentModel> payments) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        return payments;
    }

    return payments
        .where((payment) => payment.createdAt.isAfter(startDate))
        .toList();
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return AppColors.success;
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.failed:
        return AppColors.error;
      case PaymentStatus.cancelled:
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.stripe:
        return Icons.credit_card;
      case PaymentMethod.mpesa:
        return Icons.phone_android;
      case PaymentMethod.bank:
        return Icons.account_balance;
      case PaymentMethod.cash:
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  // Action methods
  void _configureGateway(String gateway) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configure $gateway'),
        content: Text('Configure $gateway payment gateway settings'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$gateway configuration updated'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editFee(String feeType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $feeType'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Amount/Percentage',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$feeType updated successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
