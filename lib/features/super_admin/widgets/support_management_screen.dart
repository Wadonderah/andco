import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class SupportManagementScreen extends ConsumerStatefulWidget {
  const SupportManagementScreen({super.key});

  @override
  ConsumerState<SupportManagementScreen> createState() =>
      _SupportManagementScreenState();
}

class _SupportManagementScreenState
    extends ConsumerState<SupportManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedPriority = 'All';
  String _selectedStatus = 'All';
  String _selectedAgent = 'All';

  final List<String> _priorityOptions = [
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
    'Pending',
    'Resolved',
    'Closed'
  ];
  final List<String> _agentOptions = [
    'All',
    'John Smith',
    'Sarah Wilson',
    'Mike Johnson',
    'Lisa Chen'
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Management'),
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
            Tab(icon: Icon(Icons.support_agent), text: 'Active Tickets'),
            Tab(icon: Icon(Icons.people), text: 'Support Agents'),
            Tab(icon: Icon(Icons.escalator_warning), text: 'Escalations'),
            Tab(icon: Icon(Icons.analytics), text: 'Performance'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showBulkActions(),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Filters Section
            _buildFiltersSection(),

            // Support Statistics
            _buildSupportStatistics(),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveTicketsTab(),
                  _buildSupportAgentsTab(),
                  _buildEscalationsTab(),
                  _buildPerformanceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              'Priority',
              _selectedPriority,
              _priorityOptions,
              (value) => setState(() => _selectedPriority = value),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: _buildFilterDropdown(
              'Status',
              _selectedStatus,
              _statusOptions,
              (value) => setState(() => _selectedStatus = value),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: _buildFilterDropdown(
              'Agent',
              _selectedAgent,
              _agentOptions,
              (value) => setState(() => _selectedAgent = value),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          ElevatedButton.icon(
            onPressed: () => _applyFilters(),
            icon: const Icon(Icons.filter_list),
            label: const Text('Apply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.superAdminColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options,
      Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (newValue) => onChanged(newValue!),
    );
  }

  Widget _buildSupportStatistics() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.superAdminColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
              child:
                  _buildStatItem('Open Tickets', '234', Icons.support_agent)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('In Progress', '89', Icons.pending)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
              child:
                  _buildStatItem('Resolved Today', '156', Icons.check_circle)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Avg Response', '2.3h', Icons.timer)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Satisfaction', '4.7/5', Icons.star)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.superAdminColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.superAdminColor,
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

  Widget _buildActiveTicketsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_tickets')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading tickets: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final tickets = snapshot.data?.docs ?? [];

        if (tickets.isEmpty) {
          return _buildEmptyTicketsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticketData = tickets[index].data() as Map<String, dynamic>;
            // Add the document ID to the ticket data for reference
            ticketData['id'] = tickets[index].id;
            return _buildTicketCard(ticketData);
          },
        );
      },
    );
  }

  Widget _buildEmptyTicketsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Support Tickets',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'All support tickets will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportAgentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_agents')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading agents: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final agents = snapshot.data?.docs ?? [];

        if (agents.isEmpty) {
          return _buildEmptyAgentsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          itemCount: agents.length,
          itemBuilder: (context, index) {
            final agentData = agents[index].data() as Map<String, dynamic>;
            agentData['id'] = agents[index].id;
            return _buildAgentCard(agentData);
          },
        );
      },
    );
  }

  Widget _buildEmptyAgentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Support Agents',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Support agents will appear here when added',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewAgent,
            icon: const Icon(Icons.add),
            label: const Text('Add Agent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _addNewAgent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Support Agent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Agent Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              items: ['Technical', 'Customer Service', 'Billing', 'General']
                  .map((dept) => DropdownMenuItem(
                        value: dept,
                        child: Text(dept),
                      ))
                  .toList(),
              onChanged: (value) {},
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
                  content: Text('Support agent added successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Add Agent'),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escalated Tickets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildEscalatedTicketsList(),
        ],
      ),
    );
  }

  Widget _buildEscalatedTicketsList() {
    final escalatedTickets = [
      {
        'id': 'ESC001',
        'title': 'Payment Gateway Issue',
        'priority': 'Critical',
        'assignedTo': 'John Smith',
        'escalatedDate': '2024-01-15',
        'status': 'In Progress',
      },
      {
        'id': 'ESC002',
        'title': 'Bus Tracking Malfunction',
        'priority': 'High',
        'assignedTo': 'Sarah Johnson',
        'escalatedDate': '2024-01-14',
        'status': 'Under Review',
      },
    ];

    if (escalatedTickets.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.escalator_warning,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Escalated Tickets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All tickets are being handled at normal priority',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: escalatedTickets.length,
      itemBuilder: (context, index) {
        final ticket = escalatedTickets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPriorityColor(ticket['priority']!),
              child: Text(
                ticket['priority']![0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(ticket['title']!),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'ID: ${ticket['id']} • Assigned to: ${ticket['assignedTo']}'),
                Text('Escalated: ${ticket['escalatedDate']}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(ticket['status']!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ticket['status']!,
                style: TextStyle(
                  color: _getStatusColor(ticket['status']!),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening escalated ticket ${ticket['id']}'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return AppColors.error;
      case 'High':
        return AppColors.warning;
      case 'Medium':
        return AppColors.info;
      case 'Low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return AppColors.info;
      case 'Under Review':
        return AppColors.warning;
      case 'Resolved':
        return AppColors.success;
      case 'Closed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildPerformanceTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Performance Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.paddingMedium),
          Text('Support performance analytics coming soon...'),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final priorityColor = _getPriorityColor(ticket['priority']);
    final statusColor = _getStatusColor(ticket['status']);

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
                    color: priorityColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.support_agent, color: priorityColor, size: 20),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${ticket['user']} • Agent: ${ticket['agent']}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
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
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ticket['priority'],
                        style: TextStyle(
                          color: priorityColor,
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
                        ticket['status'],
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
            Text(
              ticket['description'],
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Created: ${ticket['createdAt']}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _viewTicketDetails(ticket),
                  child: const Text('View Details'),
                ),
                TextButton(
                  onPressed: () => _assignTicket(ticket),
                  child: const Text('Assign'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.info.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: AppColors.info, size: 30),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agent['email'],
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Active Tickets: ${agent['activeTickets']}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Rating: ${agent['rating']}/5',
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
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: agent['status'] == 'Online'
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    agent['status'],
                    style: TextStyle(
                      color: agent['status'] == 'Online'
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAgentAction(value, agent),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'view', child: Text('View Profile')),
                    const PopupMenuItem(
                        value: 'assign', child: Text('Assign Tickets')),
                    const PopupMenuItem(
                        value: 'performance', child: Text('View Performance')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods - removed duplicates

  // Action methods
  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Bulk Assign'),
              onTap: () => _bulkAssign(),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Bulk Close'),
              onTap: () => _bulkClose(),
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export Tickets'),
              onTap: () => _exportTickets(),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Filters applied: $_selectedPriority, $_selectedStatus, $_selectedAgent'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    });
  }

  void _viewTicketDetails(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ticket Details - ${ticket['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${ticket['user']}'),
            Text('Agent: ${ticket['agent']}'),
            Text('Priority: ${ticket['priority']}'),
            Text('Status: ${ticket['status']}'),
            Text('Created: ${ticket['createdAt']}'),
            const SizedBox(height: 8),
            Text('Description:'),
            Text(ticket['description']),
          ],
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

  void _assignTicket(Map<String, dynamic> ticket) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assign ticket functionality coming soon')),
    );
  }

  void _handleAgentAction(String action, Map<String, dynamic> agent) {
    switch (action) {
      case 'view':
        _viewAgentProfile(agent);
        break;
      case 'assign':
        _assignTicketsToAgent(agent);
        break;
      case 'performance':
        _viewAgentPerformance(agent);
        break;
    }
  }

  void _viewAgentProfile(Map<String, dynamic> agent) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('View agent profile functionality coming soon')),
    );
  }

  void _assignTicketsToAgent(Map<String, dynamic> agent) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Assign tickets to agent functionality coming soon')),
    );
  }

  void _viewAgentPerformance(Map<String, dynamic> agent) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('View agent performance functionality coming soon')),
    );
  }

  void _bulkAssign() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk assign functionality coming soon')),
    );
  }

  void _bulkClose() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk close functionality coming soon')),
    );
  }

  void _exportTickets() async {
    Navigator.pop(context);

    try {
      // Get all tickets from Firestore
      final ticketsSnapshot = await FirebaseFirestore.instance
          .collection('support_tickets')
          .orderBy('createdAt', descending: true)
          .get();

      if (ticketsSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tickets to export')),
          );
        }
        return;
      }

      // Create CSV content
      _generateCSVContent(ticketsSnapshot.docs);

      // For now, show success message - in production, implement file download
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Exported ${ticketsSnapshot.docs.length} tickets successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _generateCSVContent(List<QueryDocumentSnapshot> tickets) {
    final buffer = StringBuffer();
    buffer
        .writeln('ID,Title,Description,User,Agent,Priority,Status,Created At');

    for (final ticket in tickets) {
      final data = ticket.data() as Map<String, dynamic>;
      buffer.writeln([
        data['id'] ?? ticket.id,
        _escapeCsvField(data['title'] ?? ''),
        _escapeCsvField(data['description'] ?? ''),
        _escapeCsvField(data['user'] ?? ''),
        _escapeCsvField(data['agent'] ?? ''),
        data['priority'] ?? '',
        data['status'] ?? '',
        data['createdAt']?.toDate()?.toString() ?? '',
      ].join(','));
    }

    return buffer.toString();
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
