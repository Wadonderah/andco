import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedIncidentMonitoringScreen extends ConsumerStatefulWidget {
  const EnhancedIncidentMonitoringScreen({super.key});

  @override
  ConsumerState<EnhancedIncidentMonitoringScreen> createState() =>
      _EnhancedIncidentMonitoringScreenState();
}

class _EnhancedIncidentMonitoringScreenState
    extends ConsumerState<EnhancedIncidentMonitoringScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSeverity = 'All';
  String _selectedStatus = 'All';

  final List<String> _severityOptions = [
    'All',
    'Low',
    'Medium',
    'High',
    'Critical'
  ];
  final List<String> _statusOptions = [
    'All',
    'Open',
    'In Progress',
    'Resolved',
    'Closed'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Monitoring'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.warning), text: 'Active'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
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
              user != null ? _buildIncidentContent(user) : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _reportNewIncident(),
        backgroundColor: AppColors.error,
        child: const Icon(Icons.add_alert, color: Colors.white),
      ),
    );
  }

  Widget _buildIncidentContent(user) {
    final schoolId = user.schoolId ?? '';

    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    return Column(
      children: [
        // Search and Filter Section
        _buildSearchAndFilters(),

        // Incident Statistics
        _buildIncidentStatistics(schoolId),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActiveIncidentsTab(schoolId),
              _buildHistoryTab(schoolId),
              _buildAnalyticsTab(schoolId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.surface,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  'Search incidents by description, route, or reporter...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                    'Severity', _selectedSeverity, _severityOptions, (value) {
                  setState(() => _selectedSeverity = value);
                }),
                const SizedBox(width: AppConstants.paddingSmall),
                _buildFilterChip('Status', _selectedStatus, _statusOptions,
                    (value) {
                  setState(() => _selectedStatus = value);
                }),
                const SizedBox(width: AppConstants.paddingSmall),
                ActionChip(
                  label: const Text('Clear Filters'),
                  onPressed: () {
                    setState(() {
                      _selectedSeverity = 'All';
                      _selectedStatus = 'All';
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selected, List<String> options,
      Function(String) onSelected) {
    return FilterChip(
      label: Text('$label: $selected'),
      selected: selected != 'All',
      onSelected: (isSelected) {
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
      selectedColor: AppColors.schoolAdminColor.withValues(alpha: 0.2),
      checkmarkColor: AppColors.schoolAdminColor,
    );
  }

  Widget _buildIncidentStatistics(String schoolId) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
              child: _buildStatItem('Total Incidents', '23', Icons.warning)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Open', '5', Icons.error)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('In Progress', '3', Icons.pending)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Resolved', '15', Icons.check_circle)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.error, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.error,
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

  Widget _buildActiveIncidentsTab(String schoolId) {
    final incidents = _getMockIncidents()
        .where((incident) =>
            incident['status'] == 'Open' || incident['status'] == 'In Progress')
        .toList();

    return _buildIncidentsList(incidents, isActive: true);
  }

  Widget _buildHistoryTab(String schoolId) {
    final incidents = _getMockIncidents()
        .where((incident) =>
            incident['status'] == 'Resolved' || incident['status'] == 'Closed')
        .toList();

    return _buildIncidentsList(incidents, isActive: false);
  }

  Widget _buildAnalyticsTab(String schoolId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incident Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Analytics Cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Response Time',
                  '12 min',
                  Icons.timer,
                  AppColors.info,
                  'Average response time',
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildAnalyticsCard(
                  'Resolution Rate',
                  '87%',
                  Icons.check_circle,
                  AppColors.success,
                  'Incidents resolved',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Trend Chart Placeholder
          Container(
            height: 200,
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  'Incident Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            _buildTrendIndicator('This Week', '3',
                                AppColors.success, Icons.trending_down),
                            _buildTrendIndicator('Last Week', '7',
                                AppColors.warning, Icons.trending_up),
                            _buildTrendIndicator('This Month', '15',
                                AppColors.info, Icons.trending_flat),
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
                                'Incident trends chart\nwould be displayed here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color, String subtitle) {
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
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsList(List<Map<String, dynamic>> incidents,
      {required bool isActive}) {
    if (incidents.isEmpty) {
      return _buildEmptyState(
        isActive ? 'No active incidents' : 'No incident history',
        isActive
            ? 'All incidents have been resolved'
            : 'No resolved incidents found',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: incidents.length,
      itemBuilder: (context, index) {
        return _buildIncidentCard(incidents[index]);
      },
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final severityColor = _getSeverityColor(incident['severity']);
    final statusColor = _getStatusColor(incident['status']);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getSeverityIcon(incident['severity']),
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
                        incident['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        incident['description'],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        incident['severity'],
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        incident['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  incident['location'],
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  incident['reportedAt'],
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _viewIncidentDetails(incident),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary),
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

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Please log in to access incident monitoring',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  // Helper methods for colors and icons
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return AppColors.error;
      case 'In Progress':
        return AppColors.warning;
      case 'Resolved':
        return AppColors.success;
      case 'Closed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'Low':
        return Icons.info;
      case 'Medium':
        return Icons.warning;
      case 'High':
        return Icons.error;
      case 'Critical':
        return Icons.dangerous;
      default:
        return Icons.help;
    }
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
              title: const Text('Filter by Date Range'),
              onTap: () => _filterByDateRange(),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Filter by Location'),
              onTap: () => _filterByLocation(),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Filter by Reporter'),
              onTap: () => _filterByReporter(),
            ),
          ],
        ),
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
            content: Text('Incident data refreshed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  void _reportNewIncident() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report New Incident'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Incident Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Incident reported successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _viewIncidentDetails(Map<String, dynamic> incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(incident['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Severity: ${incident['severity']}'),
            Text('Status: ${incident['status']}'),
            Text('Location: ${incident['location']}'),
            Text('Reported: ${incident['reportedAt']}'),
            Text('Reporter: ${incident['reporter']}'),
            const SizedBox(height: 8),
            Text('Description:'),
            Text(incident['description']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (incident['status'] != 'Resolved' &&
              incident['status'] != 'Closed')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateIncidentStatus(incident);
              },
              child: const Text('Update Status'),
            ),
        ],
      ),
    );
  }

  void _updateIncidentStatus(Map<String, dynamic> incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Incident Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update status for: ${incident['title']}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: incident['status'],
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ['Open', 'In Progress', 'Resolved', 'Closed']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    incident['status'] = value;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Incident status updated to ${incident['status']}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _filterByDateRange() async {
    Navigator.pop(context);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Filtering incidents from ${picked.start.day}/${picked.start.month} to ${picked.end.day}/${picked.end.month}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  DateTimeRange? _selectedDateRange;

  void _filterByLocation() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location filter coming soon')),
    );
  }

  void _filterByReporter() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporter filter coming soon')),
    );
  }

  // Mock data method
  List<Map<String, dynamic>> _getMockIncidents() {
    return [
      {
        'id': '1',
        'title': 'Student fell on bus',
        'description':
            'Student slipped while boarding the bus during morning pickup',
        'severity': 'Medium',
        'status': 'In Progress',
        'location': 'Route A - Oak Street Stop',
        'reportedAt': '2 hours ago',
        'reporter': 'Driver John Smith',
      },
      {
        'id': '2',
        'title': 'Bus breakdown',
        'description':
            'Engine overheating on Route B, students transferred to backup bus',
        'severity': 'High',
        'status': 'Resolved',
        'location': 'Route B - Main Avenue',
        'reportedAt': '1 day ago',
        'reporter': 'Driver Mary Johnson',
      },
      {
        'id': '3',
        'title': 'Unauthorized person near bus',
        'description':
            'Suspicious individual approached bus during student pickup',
        'severity': 'High',
        'status': 'Open',
        'location': 'Route C - School Entrance',
        'reportedAt': '3 hours ago',
        'reporter': 'Security Guard',
      },
      {
        'id': '4',
        'title': 'Student medical emergency',
        'description':
            'Student experienced allergic reaction, emergency services called',
        'severity': 'Critical',
        'status': 'Resolved',
        'location': 'Route A - Elm Street',
        'reportedAt': '2 days ago',
        'reporter': 'Driver Robert Wilson',
      },
      {
        'id': '5',
        'title': 'Minor traffic accident',
        'description':
            'Bus involved in minor fender bender, no injuries reported',
        'severity': 'Medium',
        'status': 'Closed',
        'location': 'Route D - Highway 101',
        'reportedAt': '1 week ago',
        'reporter': 'Driver Lisa Davis',
      },
    ];
  }
}
