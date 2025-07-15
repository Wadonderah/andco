import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class SystemMonitoringScreen extends ConsumerStatefulWidget {
  const SystemMonitoringScreen({super.key});

  @override
  ConsumerState<SystemMonitoringScreen> createState() =>
      _SystemMonitoringScreenState();
}

class _SystemMonitoringScreenState extends ConsumerState<SystemMonitoringScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

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
        title: const Text('System Monitoring'),
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
            Tab(icon: Icon(Icons.monitor), text: 'System Health'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.warning), text: 'Alerts'),
            Tab(icon: Icon(Icons.history), text: 'Activity Log'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _refreshMonitoring(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // System Status Overview
            _buildSystemStatusOverview(),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSystemHealthTab(),
                  _buildSecurityTab(),
                  _buildAlertsTab(),
                  _buildActivityLogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusOverview() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.superAdminColor.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatusCard(
                      'API Server', 'Online', AppColors.success, Icons.cloud)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildStatusCard(
                      'Database', 'Healthy', AppColors.success, Icons.storage)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildStatusCard('Firebase', 'Connected',
                      AppColors.success, Icons.cloud_done)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildStatusCard(
                      'CDN', 'Active', AppColors.success, Icons.speed)),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: [
              Expanded(
                  child: _buildStatusCard(
                      'CPU Usage', '45%', AppColors.info, Icons.memory)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildStatusCard('Memory', '67%', AppColors.warning,
                      Icons.developer_board)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildStatusCard(
                      'Disk Space', '23%', AppColors.success, Icons.storage)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildStatusCard('Network', '12ms', AppColors.success,
                      Icons.network_check)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      String title, String value, Color color, IconData icon) {
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
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Health Monitoring',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Performance Metrics
          _buildPerformanceMetrics(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Service Status
          _buildServiceStatus(),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Monitoring',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Security Metrics
          _buildSecurityMetrics(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Recent Security Events
          _buildRecentSecurityEvents(),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Alerts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Active Alerts
          _buildActiveAlerts(),
        ],
      ),
    );
  }

  Widget _buildActivityLogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Activity Log',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Activity Log
          _buildActivityLog(),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
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
            'Performance Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Performance Metrics Chart
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'System Performance',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        'Last 24 hours',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                            child:
                                _buildMetricBar('CPU', 0.65, AppColors.info)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildMetricBar(
                                'Memory', 0.78, AppColors.warning)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildMetricBar(
                                'Storage', 0.45, AppColors.success)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildMetricBar(
                                'Network', 0.82, AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatus() {
    final services = [
      {'name': 'Authentication Service', 'status': 'Online', 'uptime': '99.9%'},
      {'name': 'Notification Service', 'status': 'Online', 'uptime': '99.8%'},
      {'name': 'Payment Processing', 'status': 'Online', 'uptime': '99.7%'},
      {'name': 'File Storage', 'status': 'Online', 'uptime': '99.9%'},
      {'name': 'Real-time Tracking', 'status': 'Degraded', 'uptime': '98.5%'},
    ];

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
            'Service Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...services.map((service) => _buildServiceItem(service)),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final statusColor =
        service['status'] == 'Online' ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Text(
              service['name'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            service['status'],
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Text(
            service['uptime'],
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMetrics() {
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
            'Security Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: [
              Expanded(
                  child: _buildSecurityMetricCard(
                      'Failed Logins', '23', AppColors.warning)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildSecurityMetricCard(
                      'Blocked IPs', '5', AppColors.error)),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                  child: _buildSecurityMetricCard(
                      'Active Sessions', '1,247', AppColors.info)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSecurityEvents() {
    final events = [
      {
        'type': 'Failed Login',
        'user': 'unknown@email.com',
        'time': '2 minutes ago',
        'severity': 'Medium'
      },
      {
        'type': 'IP Blocked',
        'user': '192.168.1.100',
        'time': '15 minutes ago',
        'severity': 'High'
      },
      {
        'type': 'Password Reset',
        'user': 'user@school.edu',
        'time': '1 hour ago',
        'severity': 'Low'
      },
      {
        'type': 'Suspicious Activity',
        'user': 'admin@test.com',
        'time': '2 hours ago',
        'severity': 'High'
      },
    ];

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
            'Recent Security Events',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...events.map((event) => _buildSecurityEventItem(event)),
        ],
      ),
    );
  }

  Widget _buildSecurityEventItem(Map<String, dynamic> event) {
    final severityColor = _getSeverityColor(event['severity']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.security, color: severityColor, size: 16),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['type'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  event['user'],
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event['severity'],
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                event['time'],
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

  Widget _buildActiveAlerts() {
    final alerts = [
      {
        'title': 'High Memory Usage',
        'description': 'Server memory usage above 80%',
        'severity': 'High',
        'time': '5 minutes ago'
      },
      {
        'title': 'Database Connection Pool',
        'description': 'Connection pool nearing capacity',
        'severity': 'Medium',
        'time': '15 minutes ago'
      },
      {
        'title': 'SSL Certificate Expiry',
        'description': 'Certificate expires in 30 days',
        'severity': 'Low',
        'time': '1 hour ago'
      },
    ];

    return Column(
      children: alerts.map((alert) => _buildAlertCard(alert)).toList(),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severityColor = _getSeverityColor(alert['severity']);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning, color: severityColor, size: 20),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert['description'],
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert['severity'],
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['time'],
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog() {
    final activities = [
      {
        'action': 'User Login',
        'user': 'admin@andco.com',
        'time': '2 minutes ago',
        'ip': '192.168.1.1'
      },
      {
        'action': 'Database Backup',
        'user': 'System',
        'time': '1 hour ago',
        'ip': 'Internal'
      },
      {
        'action': 'Security Scan',
        'user': 'System',
        'time': '2 hours ago',
        'ip': 'Internal'
      },
      {
        'action': 'User Registration',
        'user': 'new.user@school.edu',
        'time': '3 hours ago',
        'ip': '203.0.113.1'
      },
    ];

    return Column(
      children:
          activities.map((activity) => _buildActivityItem(activity)).toList(),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, color: AppColors.info, size: 20),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['action'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User: ${activity['user']} • IP: ${activity['ip']}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
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
      ),
    );
  }

  Widget _buildMetricBar(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: 20,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(value * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Low':
        return AppColors.info;
      case 'Medium':
        return AppColors.warning;
      case 'High':
        return AppColors.error;
      case 'Critical':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  // Action methods
  void _refreshMonitoring() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('System monitoring data refreshed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }
}
