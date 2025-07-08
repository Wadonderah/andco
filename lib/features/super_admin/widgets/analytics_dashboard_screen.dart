import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
                const Text(
                  'Analytics & Usage Heatmaps',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                // Analytics Summary Cards
                Row(
                  children: [
                    _buildAnalyticsCard('Total Users', '2,847', AppColors.teal, Icons.people),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildAnalyticsCard('Daily Active', '1,234', AppColors.success, Icons.trending_up),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildAnalyticsCard('Session Duration', '24m', AppColors.info, Icons.access_time),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildAnalyticsCard('Bounce Rate', '12.5%', AppColors.warning, Icons.exit_to_app),
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
              labelColor: AppColors.teal,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.teal,
              isScrollable: true,
              tabs: const [
                Tab(text: 'User Analytics'),
                Tab(text: 'Usage Heatmaps'),
                Tab(text: 'Performance Metrics'),
                Tab(text: 'Custom Reports'),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserAnalyticsTab(),
                _buildUsageHeatmapsTab(),
                _buildPerformanceMetricsTab(),
                _buildCustomReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, Color color, IconData icon) {
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

  Widget _buildUserAnalyticsTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Analytics Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // User Growth Chart
          Card(
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                children: [
                  const Text(
                    'User Growth Over Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: const Center(
                        child: Text(
                          'User Growth Chart\n(Chart implementation would go here)',
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
          
          // User Behavior Metrics
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
                          'User Engagement',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildMetricRow('Daily Active Users', '1,234'),
                        _buildMetricRow('Weekly Active Users', '5,678'),
                        _buildMetricRow('Monthly Active Users', '15,432'),
                        _buildMetricRow('Average Session Duration', '24 minutes'),
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
                          'User Retention',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildMetricRow('Day 1 Retention', '85%'),
                        _buildMetricRow('Day 7 Retention', '72%'),
                        _buildMetricRow('Day 30 Retention', '58%'),
                        _buildMetricRow('Churn Rate', '12.5%'),
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

  Widget _buildUsageHeatmapsTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usage Heatmaps',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Heatmap Visualization
          Card(
            child: Container(
              height: 400,
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                children: [
                  const Text(
                    'Feature Usage Heatmap',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: const Center(
                        child: Text(
                          'Interactive Heatmap\n(Heatmap visualization would go here)',
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
          
          // Feature Usage Stats
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
                          'Most Used Features',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildFeatureUsage('Bus Tracking', 95),
                        _buildFeatureUsage('Notifications', 87),
                        _buildFeatureUsage('Route Planning', 76),
                        _buildFeatureUsage('Student Management', 68),
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
                          'Peak Usage Times',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildTimeUsage('7:00 AM - 9:00 AM', 'Morning Rush'),
                        _buildTimeUsage('3:00 PM - 5:00 PM', 'Afternoon Rush'),
                        _buildTimeUsage('6:00 PM - 8:00 PM', 'Evening Check'),
                        _buildTimeUsage('Weekend', 'Low Activity'),
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

  Widget _buildPerformanceMetricsTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: const Center(
        child: Text(
          'Performance Metrics\n(Implementation would go here)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildCustomReportsTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: const Center(
        child: Text(
          'Custom Reports\n(Implementation would go here)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
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

  Widget _buildFeatureUsage(String feature, int percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(feature, style: const TextStyle(fontSize: 14)),
              Text('$percentage%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUsage(String time, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
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
}
