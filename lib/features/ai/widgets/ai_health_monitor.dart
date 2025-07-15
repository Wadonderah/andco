import 'package:flutter/material.dart';

import '../../../core/services/ai/base_ai_service.dart';
import '../../../core/theme/app_colors.dart';

class AIHealthMonitor extends StatelessWidget {
  final Map<String, AIServiceHealth> healthData;

  const AIHealthMonitor({
    super.key,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
    final healthyServices = healthData.values.where((h) => h.isHealthy).length;
    final totalServices = healthData.length;
    final healthPercentage = totalServices > 0 ? (healthyServices / totalServices) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: _getHealthColor(healthPercentage),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Health',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$healthyServices of $totalServices services healthy',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getHealthColor(healthPercentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getHealthColor(healthPercentage).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${healthPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getHealthColor(healthPercentage),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHealthBar(healthPercentage),
            const SizedBox(height: 16),
            _buildStatusBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBar(double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Overall Health'),
            Text('${percentage.toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(_getHealthColor(percentage)),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown() {
    final statusCounts = <AIServiceStatus, int>{};
    
    for (final health in healthData.values) {
      statusCounts[health.status] = (statusCounts[health.status] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Breakdown',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statusCounts.entries.map((entry) {
            return _buildStatusChip(entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusChip(AIServiceStatus status, int count) {
    Color color;
    IconData icon;

    switch (status) {
      case AIServiceStatus.ready:
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case AIServiceStatus.running:
        color = AppColors.info;
        icon = Icons.play_circle;
        break;
      case AIServiceStatus.error:
        color = AppColors.error;
        icon = Icons.error;
        break;
      case AIServiceStatus.disabled:
        color = AppColors.textSecondary;
        icon = Icons.pause_circle;
        break;
      case AIServiceStatus.initializing:
        color = AppColors.warning;
        icon = Icons.hourglass_empty;
        break;
      case AIServiceStatus.uninitialized:
        color = AppColors.textSecondary;
        icon = Icons.help;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '${status.name} ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(double percentage) {
    if (percentage >= 90) return AppColors.success;
    if (percentage >= 70) return AppColors.warning;
    return AppColors.error;
  }
}
