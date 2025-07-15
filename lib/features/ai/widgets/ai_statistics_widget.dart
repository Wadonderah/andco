import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AIStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const AIStatisticsWidget({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final totalServices = statistics['totalServices'] ?? 0;
    final enabledServices = statistics['enabledServices'] ?? 0;
    final initializedServices = statistics['initializedServices'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Services Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Services',
                    totalServices.toString(),
                    Icons.smart_toy,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Enabled',
                    enabledServices.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Initialized',
                    initializedServices.toString(),
                    Icons.settings,
                    AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildServicesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    final services = statistics['services'] as Map<String, dynamic>? ?? {};
    
    if (services.isEmpty) {
      return const Center(
        child: Text('No services available'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...services.entries.map((entry) {
          final serviceName = entry.key;
          final serviceData = entry.value as Map<String, dynamic>;
          
          return _buildServiceRow(serviceName, serviceData);
        }),
      ],
    );
  }

  Widget _buildServiceRow(String serviceName, Map<String, dynamic> serviceData) {
    final status = serviceData['status'] ?? 'unknown';
    final enabled = serviceData['enabled'] ?? false;
    final initialized = serviceData['initialized'] ?? false;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'ready':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'running':
        statusColor = AppColors.info;
        statusIcon = Icons.play_circle;
        break;
      case 'error':
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        break;
      case 'disabled':
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.pause_circle;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatServiceName(serviceName),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          _buildStatusBadge('E', enabled, AppColors.success),
          const SizedBox(width: 4),
          _buildStatusBadge('I', initialized, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, bool isActive, Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isActive ? color : AppColors.border,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _formatServiceName(String serviceName) {
    // Convert snake_case to Title Case
    return serviceName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
