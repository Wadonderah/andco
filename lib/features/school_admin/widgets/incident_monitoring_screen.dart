import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class IncidentMonitoringScreen extends StatefulWidget {
  const IncidentMonitoringScreen({super.key});

  @override
  State<IncidentMonitoringScreen> createState() =>
      _IncidentMonitoringScreenState();
}

class _IncidentMonitoringScreenState extends State<IncidentMonitoringScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final IncidentFilter _currentFilter = IncidentFilter.all;

  final List<Incident> _incidents = [
    Incident(
      id: '1',
      title: 'Student Injury on Bus 101',
      description:
          'Minor injury during emergency braking. Student treated by school nurse.',
      type: IncidentType.medical,
      severity: IncidentSeverity.medium,
      status: IncidentStatus.resolved,
      reportedBy: 'John Smith (Driver)',
      reportedDate: DateTime.now().subtract(const Duration(hours: 2)),
      busNumber: 'Bus 101',
      route: 'Route A',
      studentsInvolved: ['Emma Johnson'],
      actionsTaken: [
        'First aid administered',
        'Parent contacted',
        'Incident report filed'
      ],
      followUpRequired: false,
    ),
    Incident(
      id: '2',
      title: 'Mechanical Failure - Bus 102',
      description:
          'Engine overheating detected during morning route. Bus safely stopped.',
      type: IncidentType.mechanical,
      severity: IncidentSeverity.high,
      status: IncidentStatus.investigating,
      reportedBy: 'Maria Garcia (Driver)',
      reportedDate: DateTime.now().subtract(const Duration(hours: 6)),
      busNumber: 'Bus 102',
      route: 'Route B',
      studentsInvolved: [],
      actionsTaken: [
        'Emergency stop',
        'Students transferred to backup bus',
        'Maintenance called'
      ],
      followUpRequired: true,
    ),
    Incident(
      id: '3',
      title: 'Behavioral Issue - Route C',
      description:
          'Student disruption requiring intervention during transport.',
      type: IncidentType.behavioral,
      severity: IncidentSeverity.low,
      status: IncidentStatus.pending,
      reportedBy: 'Robert Johnson (Driver)',
      reportedDate: DateTime.now().subtract(const Duration(days: 1)),
      busNumber: 'Bus 103',
      route: 'Route C',
      studentsInvolved: ['Marcus Williams'],
      actionsTaken: ['Verbal warning given', 'Seat reassignment'],
      followUpRequired: true,
    ),
    Incident(
      id: '4',
      title: 'Emergency SOS Activation',
      description:
          'Driver activated emergency SOS due to suspicious activity near bus stop.',
      type: IncidentType.security,
      severity: IncidentSeverity.high,
      status: IncidentStatus.resolved,
      reportedBy: 'System Alert',
      reportedDate: DateTime.now().subtract(const Duration(days: 2)),
      busNumber: 'Bus 101',
      route: 'Route A',
      studentsInvolved: [],
      actionsTaken: [
        'Police contacted',
        'Route temporarily modified',
        'Security review completed'
      ],
      followUpRequired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Monitoring'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _createIncidentReport,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _exportIncidentData,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildHistoryTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    final activeIncidents = _incidents
        .where((incident) => incident.status != IncidentStatus.resolved)
        .toList();

    return Column(
      children: [
        // Summary Section
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.surfaceVariant,
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search incidents...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Summary Stats
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard('Total',
                          _incidents.length.toString(), AppColors.info)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildStatCard('Active',
                          activeIncidents.length.toString(), AppColors.error)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildStatCard(
                          'High Priority',
                          _getIncidentCount(IncidentSeverity.high).toString(),
                          AppColors.warning)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildStatCard(
                          'This Week', '8', AppColors.secondary)),
                ],
              ),
            ],
          ),
        ),

        // Active Incidents List
        Expanded(
          child: activeIncidents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.success,
                      ),
                      SizedBox(height: AppConstants.paddingMedium),
                      Text(
                        'No Active Incidents',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        'All incidents have been resolved',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium),
                  itemCount: activeIncidents.length,
                  itemBuilder: (context, index) {
                    final incident = activeIncidents[index];
                    return _buildIncidentCard(incident);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final resolvedIncidents = _incidents
        .where((incident) => incident.status == IncidentStatus.resolved)
        .toList();

    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      itemCount: resolvedIncidents.length,
      itemBuilder: (context, index) {
        final incident = resolvedIncidents[index];
        return _buildIncidentCard(incident);
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Incident Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Trends and patterns in incident data',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    final severityColor = _getSeverityColor(incident.severity);
    final statusColor = _getStatusColor(incident.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    _getIncidentTypeIcon(incident.type),
                    color: severityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${incident.busNumber} • ${incident.route}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: Text(
                        incident.severity.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: severityColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: Text(
                        incident.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Description
            Text(
              incident.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Details Row
            Row(
              children: [
                Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  incident.reportedBy,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(incident.reportedDate),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            if (incident.studentsInvolved.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Students: ${incident.studentsInvolved.join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppConstants.paddingMedium),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewIncidentDetails(incident),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                if (incident.status != IncidentStatus.resolved)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateIncidentStatus(incident),
                      icon: const Icon(Icons.update),
                      label: const Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
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

  // Helper Methods
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return AppColors.success;
      case IncidentSeverity.medium:
        return AppColors.warning;
      case IncidentSeverity.high:
        return AppColors.error;
    }
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.pending:
        return AppColors.warning;
      case IncidentStatus.investigating:
        return AppColors.info;
      case IncidentStatus.resolved:
        return AppColors.success;
    }
  }

  IconData _getIncidentTypeIcon(IncidentType type) {
    switch (type) {
      case IncidentType.medical:
        return Icons.medical_services;
      case IncidentType.mechanical:
        return Icons.build;
      case IncidentType.behavioral:
        return Icons.person_off;
      case IncidentType.security:
        return Icons.security;
      case IncidentType.weather:
        return Icons.cloud;
      case IncidentType.other:
        return Icons.warning;
    }
  }

  int _getIncidentCount(IncidentSeverity severity) {
    return _incidents.where((incident) => incident.severity == severity).length;
  }

  void _viewIncidentDetails(Incident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(incident.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${incident.description}'),
              const SizedBox(height: 8),
              Text('Type: ${incident.type.name}'),
              Text('Severity: ${incident.severity.name}'),
              Text('Status: ${incident.status.name}'),
              Text('Reported by: ${incident.reportedBy}'),
              Text('Date: ${_formatDateTime(incident.reportedDate)}'),
              if (incident.studentsInvolved.isNotEmpty)
                Text('Students: ${incident.studentsInvolved.join(', ')}'),
              const SizedBox(height: 8),
              const Text('Actions Taken:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...incident.actionsTaken.map((action) => Text('• $action')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateIncidentStatus(Incident incident) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Update status for ${incident.title}')),
    );
  }

  void _createIncidentReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Create incident report functionality will be implemented')),
    );
  }

  void _showFilterOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options will be implemented')),
    );
  }

  void _exportIncidentData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting incident data...')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum IncidentType { medical, mechanical, behavioral, security, weather, other }

enum IncidentSeverity { low, medium, high }

enum IncidentStatus { pending, investigating, resolved }

enum IncidentFilter { all, pending, investigating, resolved, highPriority }

class Incident {
  final String id;
  final String title;
  final String description;
  final IncidentType type;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String reportedBy;
  final DateTime reportedDate;
  final String busNumber;
  final String route;
  final List<String> studentsInvolved;
  final List<String> actionsTaken;
  final bool followUpRequired;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.status,
    required this.reportedBy,
    required this.reportedDate,
    required this.busNumber,
    required this.route,
    required this.studentsInvolved,
    required this.actionsTaken,
    required this.followUpRequired,
  });
}
