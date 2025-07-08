import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class SupportAgentScreen extends StatefulWidget {
  const SupportAgentScreen({super.key});

  @override
  State<SupportAgentScreen> createState() => _SupportAgentScreenState();
}

class _SupportAgentScreenState extends State<SupportAgentScreen> {
  final List<SupportAgent> _agents = [
    SupportAgent(
      id: '1',
      name: 'Alice Johnson',
      email: 'alice@support.com',
      phone: '+1 555-0401',
      status: AgentStatus.active,
      specialization: 'Technical Support',
      assignedTickets: 15,
      resolvedTickets: 142,
      averageRating: 4.8,
      workload: 75,
      joinDate: DateTime(2023, 1, 15),
      lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    SupportAgent(
      id: '2',
      name: 'Bob Smith',
      email: 'bob@support.com',
      phone: '+1 555-0402',
      status: AgentStatus.active,
      specialization: 'Billing Support',
      assignedTickets: 8,
      resolvedTickets: 98,
      averageRating: 4.6,
      workload: 45,
      joinDate: DateTime(2023, 3, 20),
      lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Support Agent Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addAgent,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Agent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Stats Row
            Row(
              children: [
                _buildStatCard('Total Agents', _agents.length.toString(), AppColors.purple),
                const SizedBox(width: AppConstants.paddingMedium),
                _buildStatCard('Active', _getActiveAgentCount().toString(), AppColors.success),
                const SizedBox(width: AppConstants.paddingMedium),
                _buildStatCard('Avg Rating', _getAverageRating().toStringAsFixed(1), AppColors.warning),
                const SizedBox(width: AppConstants.paddingMedium),
                _buildStatCard('Total Tickets', _getTotalAssignedTickets().toString(), AppColors.info),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Agents List
            Expanded(
              child: ListView.builder(
                itemCount: _agents.length,
                itemBuilder: (context, index) {
                  final agent = _agents[index];
                  return _buildAgentCard(agent);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentCard(SupportAgent agent) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(agent.status),
                  child: Text(
                    agent.name[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        agent.specialization,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${agent.assignedTickets} assigned • ${agent.resolvedTickets} resolved',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(agent.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    agent.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(agent.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Performance Metrics
            Row(
              children: [
                _buildMetric('Rating', '${agent.averageRating}⭐'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildMetric('Workload', '${agent.workload}%'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildMetric('Last Active', _formatLastActivity(agent.lastActivity)),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Action Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewAgentDetails(agent),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
                TextButton.icon(
                  onPressed: () => _assignTickets(agent),
                  icon: const Icon(Icons.assignment),
                  label: const Text('Assign Tickets'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _editAgent(agent),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // Helper Methods
  int _getActiveAgentCount() {
    return _agents.where((agent) => agent.status == AgentStatus.active).length;
  }

  double _getAverageRating() {
    if (_agents.isEmpty) return 0.0;
    return _agents.fold<double>(0, (sum, agent) => sum + agent.averageRating) / _agents.length;
  }

  int _getTotalAssignedTickets() {
    return _agents.fold<int>(0, (sum, agent) => sum + agent.assignedTickets);
  }

  Color _getStatusColor(AgentStatus status) {
    switch (status) {
      case AgentStatus.active:
        return AppColors.success;
      case AgentStatus.busy:
        return AppColors.warning;
      case AgentStatus.offline:
        return AppColors.error;
    }
  }

  String _formatLastActivity(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Action Methods
  void _addAgent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Support Agent'),
        content: const Text('Add agent functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _viewAgentDetails(SupportAgent agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(agent.name),
        content: Text('Agent details for ${agent.name} would be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _assignTickets(SupportAgent agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Tickets - ${agent.name}'),
        content: const Text('Ticket assignment interface would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _editAgent(SupportAgent agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${agent.name}'),
        content: const Text('Edit agent form would be implemented here.'),
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
}

// Data Models
enum AgentStatus {
  active('Active'),
  busy('Busy'),
  offline('Offline');

  const AgentStatus(this.displayName);
  final String displayName;
}

class SupportAgent {
  final String id;
  final String name;
  final String email;
  final String phone;
  final AgentStatus status;
  final String specialization;
  final int assignedTickets;
  final int resolvedTickets;
  final double averageRating;
  final int workload;
  final DateTime joinDate;
  final DateTime lastActivity;

  SupportAgent({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.specialization,
    required this.assignedTickets,
    required this.resolvedTickets,
    required this.averageRating,
    required this.workload,
    required this.joinDate,
    required this.lastActivity,
  });
}
