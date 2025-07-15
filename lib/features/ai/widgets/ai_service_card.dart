import 'package:flutter/material.dart';

import '../../../core/services/ai/base_ai_service.dart';
import '../../../core/theme/app_colors.dart';

class AIServiceCard extends StatelessWidget {
  final String serviceName;
  final BaseAIService service;
  final Function(bool) onToggle;
  final VoidCallback onConfigure;

  const AIServiceCard({
    super.key,
    required this.serviceName,
    required this.service,
    required this.onToggle,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: service.isEnabled,
                  onChanged: onToggle,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Status',
                    service.status.name,
                    _getStatusColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    'Initialized',
                    service.isInitialized ? 'Yes' : 'No',
                    service.isInitialized ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onConfigure,
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showServiceDetails(context),
                    icon: const Icon(Icons.info),
                    label: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (service.status) {
      case AIServiceStatus.ready:
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case AIServiceStatus.running:
        icon = Icons.play_circle;
        color = AppColors.info;
        break;
      case AIServiceStatus.error:
        icon = Icons.error;
        color = AppColors.error;
        break;
      case AIServiceStatus.disabled:
        icon = Icons.pause_circle;
        color = AppColors.textSecondary;
        break;
      case AIServiceStatus.initializing:
        icon = Icons.hourglass_empty;
        color = AppColors.warning;
        break;
      default:
        icon = Icons.help;
        color = AppColors.textSecondary;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription() {
    switch (service.status) {
      case AIServiceStatus.ready:
        return 'Ready to process requests';
      case AIServiceStatus.running:
        return 'Currently processing';
      case AIServiceStatus.error:
        return 'Service encountered an error';
      case AIServiceStatus.disabled:
        return 'Service is disabled';
      case AIServiceStatus.initializing:
        return 'Initializing service...';
      case AIServiceStatus.uninitialized:
        return 'Service not initialized';
    }
  }

  Color _getStatusColor() {
    switch (service.status) {
      case AIServiceStatus.ready:
        return AppColors.success;
      case AIServiceStatus.running:
        return AppColors.info;
      case AIServiceStatus.error:
        return AppColors.error;
      case AIServiceStatus.disabled:
        return AppColors.textSecondary;
      case AIServiceStatus.initializing:
        return AppColors.warning;
      case AIServiceStatus.uninitialized:
        return AppColors.textSecondary;
    }
  }

  void _showServiceDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service.serviceName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Service Name', service.serviceName),
              _buildDetailRow('Status', service.status.name),
              _buildDetailRow('Enabled', service.isEnabled ? 'Yes' : 'No'),
              _buildDetailRow('Initialized', service.isInitialized ? 'Yes' : 'No'),
              const SizedBox(height: 16),
              Text(
                'Configuration',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...service.getConfiguration().entries.map(
                (entry) => _buildDetailRow(entry.key, entry.value.toString()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfigure();
            },
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
