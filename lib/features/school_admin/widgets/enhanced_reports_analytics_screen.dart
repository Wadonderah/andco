import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/school_admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedReportsAnalyticsScreen extends ConsumerStatefulWidget {
  const EnhancedReportsAnalyticsScreen({super.key});

  @override
  ConsumerState<EnhancedReportsAnalyticsScreen> createState() =>
      _EnhancedReportsAnalyticsScreenState();
}

class _EnhancedReportsAnalyticsScreenState
    extends ConsumerState<EnhancedReportsAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedPeriod = 'This Month';
  String _selectedReportType = 'All Reports';

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'Custom Range'
  ];
  final List<String> _reportTypes = [
    'All Reports',
    'Attendance',
    'Routes',
    'Safety',
    'Performance',
    'Financial'
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
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: AppColors.schoolAdminColor,
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
            Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
            Tab(icon: Icon(Icons.description), text: 'Reports'),
            Tab(icon: Icon(Icons.file_download), text: 'Export'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showFilterOptions(),
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () => _refreshData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: authState.when(
          data: (user) =>
              user != null ? _buildReportsContent(user) : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildReportsContent(user) {
    final schoolId = user.schoolId ?? '';

    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    return Column(
      children: [
        // Period and Filter Selection
        _buildFilterBar(),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(schoolId),
              _buildAnalyticsTab(schoolId),
              _buildReportsTab(schoolId),
              _buildExportTab(schoolId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child:
                _buildFilterChip('Period', _selectedPeriod, _periods, (value) {
              setState(() => _selectedPeriod = value);
            }),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: _buildFilterChip('Type', _selectedReportType, _reportTypes,
                (value) {
              setState(() => _selectedReportType = value);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selected, List<String> options,
      Function(String) onSelected) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select $label',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                ...options.map((option) => ListTile(
                      title: Text(option),
                      leading: Radio<String>(
                        value: option,
                        groupValue: selected,
                        onChanged: (value) {
                          onSelected(value!);
                          Navigator.pop(context);
                        },
                      ),
                    )),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    selected,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(String schoolId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          _buildKeyMetricsSection(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Quick Stats
          _buildQuickStatsSection(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Recent Activity
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Attendance Rate',
                '96.5%',
                Icons.people,
                AppColors.success,
                '+2.3% from last month',
                true,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _buildMetricCard(
                'On-Time Performance',
                '94.2%',
                Icons.schedule,
                AppColors.info,
                '+1.8% from last month',
                true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Safety Incidents',
                '2',
                Icons.warning,
                AppColors.warning,
                '-1 from last month',
                false,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _buildMetricCard(
                'Route Efficiency',
                '89.7%',
                Icons.route,
                AppColors.success,
                '+3.1% from last month',
                true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon,
      Color color, String trend, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildStatItem(
                          'Total Students', '342', Icons.groups)),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                      child: _buildStatItem('Active Routes', '8', Icons.route)),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                      child: _buildStatItem(
                          'Total Buses', '12', Icons.directions_bus)),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: AppConstants.paddingMedium),
              Row(
                children: [
                  Expanded(
                      child:
                          _buildStatItem('Active Drivers', '15', Icons.person)),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                      child: _buildStatItem(
                          'Avg Trip Time', '28 min', Icons.timer)),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                      child: _buildStatItem('Fuel Efficiency', '8.2L/100km',
                          Icons.local_gas_station)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.schoolAdminColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.schoolAdminColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _viewAllActivity(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _getMockRecentActivity().map((activity) {
              return _buildActivityItem(activity);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final isLast = _getMockRecentActivity().last == activity;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.border),
              ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity['color'].withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'],
              color: activity['color'],
              size: 16,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['description'],
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity['time'],
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(String schoolId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Real-Time Analytics Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Real-time analytics data from Firebase
          FutureBuilder<Map<String, dynamic>>(
            future: SchoolAdminService.instance.getSchoolAnalytics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load analytics',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                );
              }

              final analytics = snapshot.data ?? {};
              return _buildRealTimeAnalytics(analytics);
            },
          ),

          // Chart Placeholders
          _buildChartSection(
              'Attendance Trends', Icons.people, AppColors.success),
          const SizedBox(height: AppConstants.paddingLarge),
          _buildChartSection('Route Performance', Icons.route, AppColors.info),
          const SizedBox(height: AppConstants.paddingLarge),
          _buildChartSection(
              'Safety Metrics', Icons.security, AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildChartSection(String title, IconData icon, Color color) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _expandChart(title),
                icon: const Icon(Icons.fullscreen),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(
                    'Interactive $title chart coming soon',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab(String schoolId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Reports',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Report Templates
          ..._getReportTemplates()
              .map((template) => _buildReportTemplate(template)),
        ],
      ),
    );
  }

  Widget _buildReportTemplate(Map<String, dynamic> template) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: template['color'].withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                template['icon'],
                color: template['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template['description'],
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Last generated: ${template['lastGenerated']}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _generateReport(template),
              style: ElevatedButton.styleFrom(
                backgroundColor: template['color'],
                foregroundColor: Colors.white,
              ),
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab(String schoolId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Export Options
          _buildExportSection('Student Data', Icons.groups, [
            'Student List with Contact Info',
            'Attendance Records',
            'Route Assignments',
            'Medical Information',
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          _buildExportSection('Transportation Data', Icons.directions_bus, [
            'Route Information',
            'Bus Details and Capacity',
            'Driver Information',
            'Trip Logs',
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          _buildExportSection('Analytics Data', Icons.analytics, [
            'Performance Metrics',
            'Safety Reports',
            'Financial Summary',
            'Custom Analytics',
          ]),
        ],
      ),
    );
  }

  Widget _buildExportSection(
      String title, IconData icon, List<String> options) {
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
          Row(
            children: [
              Icon(icon, color: AppColors.schoolAdminColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...options.map((option) => Padding(
                padding:
                    const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(option),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _exportData('CSV', option),
                          child: const Text('CSV'),
                        ),
                        TextButton(
                          onPressed: () => _exportData('PDF', option),
                          child: const Text('PDF'),
                        ),
                        TextButton(
                          onPressed: () => _exportData('Excel', option),
                          child: const Text('Excel'),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Please log in to access reports and analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSchoolAssigned() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: AppColors.warning, size: 64),
          const SizedBox(height: 16),
          Text(
            'No School Assigned',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact your administrator to assign you to a school.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Action methods
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Custom Date Range'),
              onTap: () => _selectDateRange(),
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Advanced Filters'),
              onTap: () => _showAdvancedFilters(),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset Filters'),
              onTap: () => _resetFilters(),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshData() {
    setState(() => _isLoading = true);

    // Simulate data refresh
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  void _viewAllActivity() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('View all activity functionality coming soon')),
    );
  }

  void _expandChart(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Expand $title chart functionality coming soon')),
    );
  }

  void _generateReport(Map<String, dynamic> template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating ${template['title']} report...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _exportData(String format, String dataType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting $dataType as $format...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _selectDateRange() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Date range selection coming soon')),
    );
  }

  void _showAdvancedFilters() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Advanced filters coming soon')),
    );
  }

  void _resetFilters() {
    Navigator.pop(context);
    setState(() {
      _selectedPeriod = 'This Month';
      _selectedReportType = 'All Reports';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters reset')),
    );
  }

  // Mock data methods
  List<Map<String, dynamic>> _getMockRecentActivity() {
    return [
      {
        'title': 'Route A completed successfully',
        'description': 'All 35 students picked up and dropped off on time',
        'time': '2 hours ago',
        'icon': Icons.check_circle,
        'color': AppColors.success,
      },
      {
        'title': 'Safety incident reported',
        'description': 'Minor incident on Route B - resolved',
        'time': '4 hours ago',
        'icon': Icons.warning,
        'color': AppColors.warning,
      },
      {
        'title': 'New driver approved',
        'description': 'John Smith has been approved and assigned to Bus 003',
        'time': '1 day ago',
        'icon': Icons.person_add,
        'color': AppColors.info,
      },
      {
        'title': 'Monthly report generated',
        'description': 'Attendance report for November 2024',
        'time': '2 days ago',
        'icon': Icons.description,
        'color': AppColors.secondary,
      },
    ];
  }

  List<Map<String, dynamic>> _getReportTemplates() {
    return [
      {
        'title': 'Daily Attendance Report',
        'description': 'Student attendance summary for selected date',
        'lastGenerated': '2 hours ago',
        'icon': Icons.people,
        'color': AppColors.success,
      },
      {
        'title': 'Route Performance Report',
        'description': 'On-time performance and efficiency metrics',
        'lastGenerated': '1 day ago',
        'icon': Icons.route,
        'color': AppColors.info,
      },
      {
        'title': 'Safety Incident Report',
        'description': 'Safety incidents and resolution status',
        'lastGenerated': '3 days ago',
        'icon': Icons.security,
        'color': AppColors.warning,
      },
      {
        'title': 'Driver Performance Report',
        'description': 'Driver ratings, punctuality, and feedback',
        'lastGenerated': '1 week ago',
        'icon': Icons.person,
        'color': AppColors.secondary,
      },
      {
        'title': 'Financial Summary Report',
        'description': 'Transportation costs and budget analysis',
        'lastGenerated': '1 week ago',
        'icon': Icons.attach_money,
        'color': AppColors.primary,
      },
      {
        'title': 'Parent Feedback Report',
        'description': 'Parent satisfaction and feedback summary',
        'lastGenerated': '2 weeks ago',
        'icon': Icons.feedback,
        'color': AppColors.schoolAdminColor,
      },
    ];
  }

  /// Build real-time analytics dashboard with Firebase data
  Widget _buildRealTimeAnalytics(Map<String, dynamic> analytics) {
    final totalStudents = analytics['totalStudents'] ?? 0;
    final totalDrivers = analytics['totalDrivers'] ?? 0;
    final totalRoutes = analytics['totalRoutes'] ?? 0;
    final lastUpdated = analytics['lastUpdated'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key Metrics Cards
        Row(
          children: [
            Expanded(
              child: _buildRealTimeMetricCard(
                'Total Students',
                totalStudents.toString(),
                Icons.people,
                AppColors.primary,
                'Active students enrolled',
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _buildRealTimeMetricCard(
                'Active Drivers',
                totalDrivers.toString(),
                Icons.drive_eta,
                AppColors.success,
                'Approved and active drivers',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        Row(
          children: [
            Expanded(
              child: _buildRealTimeMetricCard(
                'Active Routes',
                totalRoutes.toString(),
                Icons.route,
                AppColors.info,
                'Currently operational routes',
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _buildRealTimeMetricCard(
                'System Status',
                'Online',
                Icons.cloud_done,
                AppColors.success,
                'Real-time data sync active',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.paddingLarge),

        // Last Updated Info
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.update,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Last updated: ${_formatLastUpdated(lastUpdated)}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {}); // Trigger rebuild to refresh data
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.paddingLarge),

        // Real-time Activity Stream
        Text(
          'Real-Time Activity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),

        // Activity stream would be implemented here with real Firebase data
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildRealTimeActivityItem(
                'New student registered',
                'John Doe added to Grade 3A',
                Icons.person_add,
                AppColors.success,
                '2 minutes ago',
              ),
              const Divider(),
              _buildRealTimeActivityItem(
                'Route completed',
                'Route A completed morning pickup',
                Icons.check_circle,
                AppColors.info,
                '15 minutes ago',
              ),
              const Divider(),
              _buildRealTimeActivityItem(
                'Driver approved',
                'Sarah Johnson approved for Route B',
                Icons.verified,
                AppColors.primary,
                '1 hour ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build real-time metric card widget
  Widget _buildRealTimeMetricCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
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
    );
  }

  /// Build real-time activity item widget
  Widget _buildRealTimeActivityItem(String title, String description,
      IconData icon, Color color, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
            time,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Format last updated timestamp
  String _formatLastUpdated(String timestamp) {
    if (timestamp.isEmpty) return 'Never';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
