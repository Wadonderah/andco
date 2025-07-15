import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class FinancialOversightScreen extends ConsumerStatefulWidget {
  const FinancialOversightScreen({super.key});

  @override
  ConsumerState<FinancialOversightScreen> createState() =>
      _FinancialOversightScreenState();
}

class _FinancialOversightScreenState
    extends ConsumerState<FinancialOversightScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedTimeRange = 'This Month';
  String _selectedPaymentMethod = 'All Methods';

  final List<String> _timeRangeOptions = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year'
  ];
  final List<String> _paymentMethodOptions = [
    'All Methods',
    'Stripe',
    'M-Pesa',
    'Bank Transfer',
    'Cash'
  ];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Oversight'),
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
            Tab(icon: Icon(Icons.payment), text: 'Transactions'),
            Tab(icon: Icon(Icons.report_problem), text: 'Disputes'),
            Tab(icon: Icon(Icons.analytics), text: 'Reports'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _exportFinancialReport(),
            icon: const Icon(Icons.file_download),
          ),
          IconButton(
            onPressed: () => _refreshData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Filters Section
            _buildFiltersSection(),

            // Financial Overview
            _buildFinancialOverview(),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildTransactionsTab(),
                  _buildDisputesTab(),
                  _buildReportsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              'Time Range',
              _selectedTimeRange,
              _timeRangeOptions,
              (value) => setState(() => _selectedTimeRange = value),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: _buildFilterDropdown(
              'Payment Method',
              _selectedPaymentMethod,
              _paymentMethodOptions,
              (value) => setState(() => _selectedPaymentMethod = value),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          ElevatedButton.icon(
            onPressed: () => _applyFilters(),
            icon: const Icon(Icons.filter_list),
            label: const Text('Apply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.superAdminColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options,
      Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (newValue) => onChanged(newValue!),
    );
  }

  Widget _buildFinancialOverview() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.superAdminColor.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildFinancialCard('Total Revenue', '\$127,456',
                      '+15.2%', Icons.trending_up, AppColors.success)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildFinancialCard('Monthly Growth', '\$23,890',
                      '+8.7%', Icons.show_chart, AppColors.info)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildFinancialCard('Pending Payments', '\$4,567',
                      '-2.1%', Icons.pending, AppColors.warning)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildFinancialCard('Disputes', '\$892', '-12.3%',
                      Icons.report_problem, AppColors.error)),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: [
              Expanded(
                  child: _buildFinancialCard('Stripe Revenue', '\$89,234',
                      '+18.5%', Icons.credit_card, AppColors.purple)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildFinancialCard('M-Pesa Revenue', '\$38,222',
                      '+12.1%', Icons.phone_android, AppColors.teal)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildFinancialCard('Transaction Fee', '\$2,156',
                      '+5.3%', Icons.account_balance, AppColors.orange)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildFinancialCard('Net Profit', '\$95,300', '+16.8%',
                      Icons.savings, AppColors.pink)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(
      String title, String amount, String change, IconData icon, Color color) {
    final isPositive = change.startsWith('+');
    final changeColor = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
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
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Revenue Chart Placeholder
          Container(
            height: 300,
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  'Revenue Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildRevenueMetric('This Month', '\$45.2K', '+12%',
                                AppColors.success),
                            _buildRevenueMetric(
                                'Last Month', '\$40.3K', '+8%', AppColors.info),
                            _buildRevenueMetric(
                                'Growth Rate', '12%', '+2%', AppColors.warning),
                          ],
                        ),
                        const SizedBox(height: AppConstants.paddingLarge),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMedium),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Text(
                                'Revenue trends chart\nwould be displayed here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Recent Transactions
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.paddingMedium),
          _buildTransactionManagementInterface(),
        ],
      ),
    );
  }

  Widget _buildDisputesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Disputes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildPaymentDisputesInterface(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Reports',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Report Types Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppConstants.paddingMedium,
            mainAxisSpacing: AppConstants.paddingMedium,
            childAspectRatio: 1.2,
            children: [
              _buildReportCard(
                  'Monthly Revenue',
                  'Generate monthly revenue reports',
                  Icons.calendar_month,
                  AppColors.success),
              _buildReportCard('Payment Analytics', 'Analyze payment patterns',
                  Icons.analytics, AppColors.info),
              _buildReportCard(
                  'School Performance',
                  'School-wise financial data',
                  Icons.school,
                  AppColors.warning),
              _buildReportCard(
                  'Transaction History',
                  'Detailed transaction logs',
                  Icons.receipt_long,
                  AppColors.purple),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Recent Reports
          Text(
            'Recent Reports',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          _buildRecentReportsList(),
        ],
      ),
    );
  }

  Widget _buildReportCard(
      String title, String description, IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: () => _generateReport(title),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReportsList() {
    final recentReports = [
      {
        'name': 'Monthly Revenue - December 2024',
        'date': '2 days ago',
        'type': 'Revenue'
      },
      {
        'name': 'Payment Analytics - Q4 2024',
        'date': '1 week ago',
        'type': 'Analytics'
      },
      {
        'name': 'School Performance - November',
        'date': '2 weeks ago',
        'type': 'Performance'
      },
    ];

    return Column(
      children: recentReports
          .map((report) => Card(
                margin:
                    const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.info.withValues(alpha: 0.1),
                    child: Icon(Icons.description, color: AppColors.info),
                  ),
                  title: Text(report['name']!),
                  subtitle:
                      Text('Generated ${report['date']} • ${report['type']}'),
                  trailing: IconButton(
                    onPressed: () => _downloadReport(report['name']!),
                    icon: const Icon(Icons.download),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRevenueMetric(
      String label, String value, String change, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          change,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  void _generateReport(String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $reportType report...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _downloadReport(String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $reportName...'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildRecentTransactions() {
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
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Transaction Items
          _buildTransactionItem(
            'Maplewood Elementary',
            'Monthly subscription payment',
            '\$2,450.00',
            'Stripe',
            '2 hours ago',
            AppColors.success,
          ),
          _buildTransactionItem(
            'Oakridge High School',
            'Bus route optimization fee',
            '\$890.00',
            'M-Pesa',
            '4 hours ago',
            AppColors.success,
          ),
          _buildTransactionItem(
            'Pine Valley Academy',
            'Premium features upgrade',
            '\$1,200.00',
            'Stripe',
            '6 hours ago',
            AppColors.success,
          ),
          _buildTransactionItem(
            'Hillside Primary',
            'Refund processed',
            '-\$450.00',
            'Bank Transfer',
            '1 day ago',
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String school, String description, String amount,
      String method, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              method == 'Stripe'
                  ? Icons.credit_card
                  : method == 'M-Pesa'
                      ? Icons.phone_android
                      : method == 'Bank Transfer'
                          ? Icons.account_balance
                          : Icons.payment,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  method,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
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
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action methods
  Widget _buildTransactionManagementInterface() {
    return Column(
      children: [
        // Search and Filter Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: AppConstants.paddingMedium),
            ElevatedButton.icon(
              onPressed: _showTransactionFilters,
              icon: Icon(Icons.filter_list),
              label: Text('Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.superAdminColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.paddingMedium),

        // Transaction List
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.superAdminColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppConstants.radiusMedium)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: _viewAllTransactions,
                      child: Text('View All'),
                    ),
                  ],
                ),
              ),

              // Transaction Items
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  return _buildTransactionListItem(index);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionListItem(int index) {
    final transactions = [
      {
        'school': 'Maplewood Elementary',
        'amount': '\$2,450.00',
        'method': 'Stripe',
        'status': 'Completed',
        'time': '2 hours ago',
        'type': 'Subscription',
      },
      {
        'school': 'Oakridge High School',
        'amount': '\$890.00',
        'method': 'M-Pesa',
        'status': 'Completed',
        'time': '4 hours ago',
        'type': 'Route Fee',
      },
      {
        'school': 'Sunset Academy',
        'amount': '\$1,200.00',
        'method': 'Bank Transfer',
        'status': 'Pending',
        'time': '6 hours ago',
        'type': 'Monthly Fee',
      },
      {
        'school': 'Pine Valley School',
        'amount': '\$675.00',
        'method': 'Stripe',
        'status': 'Failed',
        'time': '8 hours ago',
        'type': 'Late Fee',
      },
      {
        'school': 'Riverside Elementary',
        'amount': '\$3,100.00',
        'method': 'M-Pesa',
        'status': 'Completed',
        'time': '1 day ago',
        'type': 'Annual Fee',
      },
    ];

    final transaction = transactions[index];
    final statusColor = _getStatusColor(transaction['status']!);

    return ListTile(
      contentPadding: EdgeInsets.all(AppConstants.paddingMedium),
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(
          _getPaymentMethodIcon(transaction['method']!),
          color: statusColor,
        ),
      ),
      title: Text(
        transaction['school']!,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${transaction['type']} • ${transaction['time']}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            transaction['amount']!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              transaction['status']!,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      onTap: () => _viewTransactionDetails(transaction),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'Pending':
        return AppColors.warning;
      case 'Failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Stripe':
        return Icons.credit_card;
      case 'M-Pesa':
        return Icons.phone_android;
      case 'Bank Transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  void _showTransactionFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Status'),
              items: ['All', 'Completed', 'Pending', 'Failed']
                  .map((status) =>
                      DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {},
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Payment Method'),
              items: ['All', 'Stripe', 'M-Pesa', 'Bank Transfer']
                  .map((method) =>
                      DropdownMenuItem(value: method, child: Text(method)))
                  .toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _viewAllTransactions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening detailed transaction view...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _viewTransactionDetails(Map<String, String> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('School', transaction['school']!),
            _buildDetailRow('Amount', transaction['amount']!),
            _buildDetailRow('Method', transaction['method']!),
            _buildDetailRow('Status', transaction['status']!),
            _buildDetailRow('Type', transaction['type']!),
            _buildDetailRow('Time', transaction['time']!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (transaction['status'] == 'Failed')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _retryTransaction(transaction);
              },
              child: Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _retryTransaction(Map<String, String> transaction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Retrying transaction for ${transaction['school']}...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _exportFinancialReport() {
    showDialog(
      context: context,
      builder: (context) => _buildExportDialog(),
    );
  }

  Widget _buildExportDialog() {
    String selectedFormat = 'PDF';
    String selectedPeriod = 'This Month';

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Export Financial Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select export format:'),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedFormat,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['PDF', 'Excel', 'CSV'].map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Text(format),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedFormat = value!);
              },
            ),
            SizedBox(height: 16),
            Text('Select time period:'),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedPeriod,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['Today', 'This Week', 'This Month', 'This Year', 'Custom']
                  .map((period) =>
                      DropdownMenuItem(value: period, child: Text(period)))
                  .toList(),
              onChanged: (value) {
                setState(() => selectedPeriod = value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performExport(selectedFormat, selectedPeriod);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.superAdminColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  void _performExport(String format, String period) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Financial report exported as $format for $period'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPaymentDisputesInterface() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusMedium)),
            ),
            child: Row(
              children: [
                Icon(Icons.report_problem, color: AppColors.error),
                SizedBox(width: AppConstants.paddingSmall),
                Text(
                  'Payment Disputes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '3 Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dispute Items
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildDisputeListItem(index);
            },
          ),

          // View All Button
          Container(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _viewAllDisputes,
                child: Text('View All Disputes'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeListItem(int index) {
    final disputes = [
      {
        'id': 'DSP-001',
        'school': 'Maplewood Elementary',
        'amount': '\$2,450.00',
        'reason': 'Unauthorized charge',
        'status': 'Under Review',
        'date': '2 days ago',
        'priority': 'High',
      },
      {
        'id': 'DSP-002',
        'school': 'Pine Valley School',
        'amount': '\$675.00',
        'reason': 'Service not provided',
        'status': 'Investigating',
        'date': '5 days ago',
        'priority': 'Medium',
      },
      {
        'id': 'DSP-003',
        'school': 'Sunset Academy',
        'amount': '\$1,200.00',
        'reason': 'Billing error',
        'status': 'Pending Response',
        'date': '1 week ago',
        'priority': 'Low',
      },
    ];

    final dispute = disputes[index];
    final priorityColor = _getPriorityColor(dispute['priority']!);
    final statusColor = _getDisputeStatusColor(dispute['status']!);

    return ListTile(
      contentPadding: EdgeInsets.all(AppConstants.paddingMedium),
      leading: CircleAvatar(
        backgroundColor: priorityColor.withValues(alpha: 0.1),
        child: Icon(
          Icons.warning,
          color: priorityColor,
        ),
      ),
      title: Row(
        children: [
          Text(
            dispute['id']!,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dispute['priority']!,
              style: TextStyle(
                color: priorityColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${dispute['school']} • ${dispute['date']}'),
          SizedBox(height: 4),
          Text(
            dispute['reason']!,
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
            dispute['amount']!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dispute['status']!,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      onTap: () => _viewDisputeDetails(dispute),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getDisputeStatusColor(String status) {
    switch (status) {
      case 'Under Review':
        return AppColors.warning;
      case 'Investigating':
        return AppColors.info;
      case 'Pending Response':
        return AppColors.textSecondary;
      case 'Resolved':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  void _viewAllDisputes() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening detailed disputes view...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _viewDisputeDetails(Map<String, String> dispute) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dispute ${dispute['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('School', dispute['school']!),
              _buildDetailRow('Amount', dispute['amount']!),
              _buildDetailRow('Reason', dispute['reason']!),
              _buildDetailRow('Status', dispute['status']!),
              _buildDetailRow('Priority', dispute['priority']!),
              _buildDetailRow('Date', dispute['date']!),
              SizedBox(height: 16),
              Text(
                'Actions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _escalateDispute(dispute);
                      },
                      child: Text('Escalate'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _resolveDispute(dispute);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Resolve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _escalateDispute(Map<String, String> dispute) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Dispute ${dispute['id']} escalated to senior management'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _resolveDispute(Map<String, String> dispute) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dispute ${dispute['id']} marked as resolved'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _refreshData() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Financial data refreshed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  void _applyFilters() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Filters applied: $_selectedTimeRange, $_selectedPaymentMethod'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    });
  }
}
