import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_service_manager.dart';
import '../../../core/services/ai/base_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/ai_health_monitor.dart';
import '../widgets/ai_service_card.dart';
import '../widgets/ai_statistics_widget.dart';

class AIDashboardScreen extends ConsumerStatefulWidget {
  const AIDashboardScreen({super.key});

  @override
  ConsumerState<AIDashboardScreen> createState() => _AIDashboardScreenState();
}

class _AIDashboardScreenState extends ConsumerState<AIDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiManager = ref.watch(aiServiceManagerProvider);
    final healthStatus = ref.watch(aiServicesHealthProvider);
    final statistics = ref.watch(aiServiceStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Agents Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(aiServicesHealthProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showAISettings(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Services', icon: Icon(Icons.smart_toy)),
            Tab(text: 'Health', icon: Icon(Icons.health_and_safety)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServicesTab(aiManager),
          _buildHealthTab(healthStatus),
          _buildAnalyticsTab(statistics),
        ],
      ),
    );
  }

  Widget _buildServicesTab(AIServiceManager aiManager) {
    final services = aiManager.services;

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(aiServicesHealthProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickActions(),
          const SizedBox(height: 16),
          Text(
            'AI Services (${services.length})',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...services.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AIServiceCard(
                serviceName: entry.key,
                service: entry.value,
                onToggle: (enabled) => _toggleService(entry.key, enabled),
                onConfigure: () => _configureService(entry.key, entry.value),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHealthTab(
      AsyncValue<Map<String, AIServiceHealth>> healthStatus) {
    return healthStatus.when(
      data: (health) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AIHealthMonitor(healthData: health),
          const SizedBox(height: 16),
          ...health.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: entry.value.isHealthy
                      ? AppColors.success
                      : AppColors.error,
                  child: Icon(
                    entry.value.isHealthy ? Icons.check : Icons.error,
                    color: Colors.white,
                  ),
                ),
                title: Text(entry.value.serviceName),
                subtitle: Text(
                  'Status: ${entry.value.status.name}\n'
                  'Last Check: ${_formatTime(entry.value.lastCheck)}',
                ),
                trailing: entry.value.isHealthy
                    ? null
                    : Icon(Icons.warning, color: AppColors.warning),
                onTap: () => _showHealthDetails(entry.value),
              ),
            );
          }),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load health status'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.refresh(aiServicesHealthProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(Map<String, dynamic> statistics) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AIStatisticsWidget(statistics: statistics),
        const SizedBox(height: 16),
        _buildUsageChart(),
        const SizedBox(height: 16),
        _buildPerformanceMetrics(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _enableAllServices,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Enable All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _disableAllServices,
                    icon: const Icon(Icons.stop),
                    label: const Text('Disable All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetAllServices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Usage (Last 7 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: const Center(
                child: Text('Usage chart would be implemented here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                      'Response Time', '250ms', AppColors.info),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                      'Success Rate', '98.5%', AppColors.success),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      _buildMetricCard('Error Rate', '1.5%', AppColors.warning),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleService(String serviceName, bool enabled) async {
    final aiManager = ref.read(aiServiceManagerProvider);

    try {
      if (enabled) {
        await aiManager.enableService(serviceName);
      } else {
        await aiManager.disableService(serviceName);
      }

      // Refresh health status
      ref.refresh(aiServicesHealthProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${enabled ? 'Enabled' : 'Disabled'} $serviceName'),
          backgroundColor: enabled ? AppColors.success : AppColors.warning,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to ${enabled ? 'enable' : 'disable'} $serviceName: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _configureService(String serviceName, BaseAIService service) {
    // Navigate to service configuration screen
    Navigator.of(context).pushNamed(
      '/ai/configure',
      arguments: {'serviceName': serviceName, 'service': service},
    );
  }

  void _enableAllServices() async {
    final aiManager = ref.read(aiServiceManagerProvider);
    final services = aiManager.getAvailableServices();

    for (final serviceName in services) {
      try {
        await aiManager.enableService(serviceName);
      } catch (e) {
        debugPrint('Failed to enable $serviceName: $e');
      }
    }

    ref.refresh(aiServicesHealthProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enabled all AI services'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _disableAllServices() async {
    final aiManager = ref.read(aiServiceManagerProvider);
    final services = aiManager.getAvailableServices();

    for (final serviceName in services) {
      try {
        await aiManager.disableService(serviceName);
      } catch (e) {
        debugPrint('Failed to disable $serviceName: $e');
      }
    }

    ref.refresh(aiServicesHealthProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disabled all AI services'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _resetAllServices() async {
    final aiManager = ref.read(aiServiceManagerProvider);

    try {
      await aiManager.resetAllServices();
      ref.refresh(aiServicesHealthProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset all AI services'),
          backgroundColor: AppColors.info,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset services: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAISettings(BuildContext context) {
    Navigator.of(context).pushNamed('/ai/settings');
  }

  void _showHealthDetails(AIServiceHealth health) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(health.serviceName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${health.status.name}'),
            Text('Healthy: ${health.isHealthy ? 'Yes' : 'No'}'),
            Text('Last Check: ${_formatTime(health.lastCheck)}'),
            if (health.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text('Error: ${health.errorMessage}'),
            ],
            if (health.metrics.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Metrics:'),
              ...health.metrics.entries.map(
                (e) => Text('  ${e.key}: ${e.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
