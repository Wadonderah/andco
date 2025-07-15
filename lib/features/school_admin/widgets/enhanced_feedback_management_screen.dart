import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedFeedbackManagementScreen extends ConsumerStatefulWidget {
  const EnhancedFeedbackManagementScreen({super.key});

  @override
  ConsumerState<EnhancedFeedbackManagementScreen> createState() =>
      _EnhancedFeedbackManagementScreenState();
}

class _EnhancedFeedbackManagementScreenState
    extends ConsumerState<EnhancedFeedbackManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _selectedPriority = 'All';

  final List<String> _categoryOptions = [
    'All',
    'Driver',
    'Route',
    'Safety',
    'Service',
    'Other'
  ];
  final List<String> _statusOptions = [
    'All',
    'New',
    'In Progress',
    'Resolved',
    'Closed'
  ];
  final List<String> _priorityOptions = [
    'All',
    'Low',
    'Medium',
    'High',
    'Urgent'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Feedback Management'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.feedback), text: 'All Feedback'),
            Tab(icon: Icon(Icons.new_releases), text: 'New'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
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
              user != null ? _buildFeedbackContent(user) : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildFeedbackContent(user) {
    final schoolId = user.schoolId ?? '';

    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    return Column(
      children: [
        // Search and Filter Section
        _buildSearchAndFilters(),

        // Feedback Statistics
        _buildFeedbackStatistics(schoolId),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllFeedbackTab(schoolId),
              _buildNewFeedbackTab(schoolId),
              _buildAnalyticsTab(schoolId),
              _buildSettingsTab(schoolId),
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
              hintText: 'Search feedback by content, parent, or category...',
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
                    'Category', _selectedCategory, _categoryOptions, (value) {
                  setState(() => _selectedCategory = value);
                }),
                const SizedBox(width: AppConstants.paddingSmall),
                _buildFilterChip('Status', _selectedStatus, _statusOptions,
                    (value) {
                  setState(() => _selectedStatus = value);
                }),
                const SizedBox(width: AppConstants.paddingSmall),
                _buildFilterChip(
                    'Priority', _selectedPriority, _priorityOptions, (value) {
                  setState(() => _selectedPriority = value);
                }),
                const SizedBox(width: AppConstants.paddingSmall),
                ActionChip(
                  label: const Text('Clear Filters'),
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _selectedStatus = 'All';
                      _selectedPriority = 'All';
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

  Widget _buildFeedbackStatistics(String schoolId) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.secondary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
              child: _buildStatItem('Total Feedback', '127', Icons.feedback)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('New', '23', Icons.new_releases)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('In Progress', '15', Icons.pending)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Avg Rating', '4.2', Icons.star)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.secondary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.secondary,
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

  Widget _buildAllFeedbackTab(String schoolId) {
    final feedback = _getMockFeedback();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: feedback.length,
      itemBuilder: (context, index) {
        return _buildFeedbackCard(feedback[index]);
      },
    );
  }

  Widget _buildNewFeedbackTab(String schoolId) {
    final newFeedback =
        _getMockFeedback().where((f) => f['status'] == 'New').toList();

    if (newFeedback.isEmpty) {
      return _buildEmptyState(
          'No new feedback', 'All feedback has been reviewed');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: newFeedback.length,
      itemBuilder: (context, index) {
        return _buildFeedbackCard(newFeedback[index]);
      },
    );
  }

  Widget _buildAnalyticsTab(String schoolId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback Analytics',
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
                  'Satisfaction Rate',
                  '87%',
                  Icons.sentiment_satisfied,
                  AppColors.success,
                  'Overall satisfaction',
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildAnalyticsCard(
                  'Response Time',
                  '4.2 hrs',
                  Icons.timer,
                  AppColors.info,
                  'Average response time',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Chart Placeholder
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
                  'Feedback Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'Feedback trends will be displayed here',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Generating feedback trends...'),
                                backgroundColor: AppColors.info,
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Generate Trends'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.schoolAdminColor,
                            foregroundColor: Colors.white,
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

  Widget _buildSettingsTab(String schoolId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Settings Options
          _buildSettingsSection('Notifications', [
            _buildSettingsTile(
                'Email Notifications', 'Receive feedback via email', true),
            _buildSettingsTile(
                'Push Notifications', 'Get instant feedback alerts', true),
            _buildSettingsTile(
                'SMS Notifications', 'Receive urgent feedback via SMS', false),
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          _buildSettingsSection('Auto-Response', [
            _buildSettingsTile('Auto-Acknowledge',
                'Automatically acknowledge new feedback', true),
            _buildSettingsTile('Response Templates',
                'Use predefined response templates', true),
            _buildSettingsTile('Priority Assignment',
                'Auto-assign priority based on keywords', false),
          ]),

          const SizedBox(height: AppConstants.paddingLarge),

          _buildSettingsSection('Collection', [
            _buildActionTile('Feedback Forms',
                'Manage feedback collection forms', Icons.assignment),
            _buildActionTile('Survey Templates',
                'Create and manage survey templates', Icons.quiz),
            _buildActionTile('Rating Categories', 'Configure rating categories',
                Icons.category),
          ]),
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

  Widget _buildSettingsSection(String title, List<Widget> children) {
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
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, bool value) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (newValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$title ${newValue ? 'enabled' : 'disabled'}')),
        );
      },
      activeColor: AppColors.schoolAdminColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.schoolAdminColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        _handleActionTap(title);
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final priorityColor = _getPriorityColor(feedback['priority']);
    final statusColor = _getStatusColor(feedback['status']);

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
                  radius: 20,
                  backgroundColor: priorityColor.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: priorityColor, size: 20),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback['parentName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feedback['category'],
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        feedback['priority'],
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
                        feedback['status'],
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
              feedback['message'],
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                if (feedback['rating'] != null) ...[
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < feedback['rating']
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.warning,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.access_time,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  feedback['submittedAt'],
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _viewFeedbackDetails(feedback),
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
          Icon(Icons.feedback_outlined,
              size: 64, color: AppColors.textSecondary),
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

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Please log in to access feedback management',
            style: Theme.of(context).textTheme.titleLarge,
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return AppColors.info;
      case 'Medium':
        return AppColors.warning;
      case 'High':
        return AppColors.error;
      case 'Urgent':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return AppColors.info;
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
              leading: const Icon(Icons.star),
              title: const Text('Filter by Rating'),
              onTap: () => _filterByRating(),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Filter by Parent'),
              onTap: () => _filterByParent(),
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
            content: Text('Feedback data refreshed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  void _viewFeedbackDetails(Map<String, dynamic> feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Feedback from ${feedback['parentName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${feedback['category']}'),
            Text('Priority: ${feedback['priority']}'),
            Text('Status: ${feedback['status']}'),
            if (feedback['rating'] != null)
              Text('Rating: ${feedback['rating']}/5'),
            Text('Submitted: ${feedback['submittedAt']}'),
            const SizedBox(height: 8),
            Text('Message:'),
            Text(feedback['message']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (feedback['status'] != 'Resolved' &&
              feedback['status'] != 'Closed')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _respondToFeedback(feedback);
              },
              child: const Text('Respond'),
            ),
        ],
      ),
    );
  }

  void _respondToFeedback(Map<String, dynamic> feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Responding to: ${feedback['subject']}'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Your Response',
                hintText: 'Type your response here...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Store response
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
              setState(() {
                feedback['status'] = 'Responded';
                feedback['responseDate'] = DateTime.now().toIso8601String();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Response sent successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Send Response'),
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

    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Filtering feedback from ${picked.start.day}/${picked.start.month} to ${picked.end.day}/${picked.end.month}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  DateTimeRange? _selectedDateRange;

  void _filterByRating() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rating filter coming soon')),
    );
  }

  void _filterByParent() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parent filter coming soon')),
    );
  }

  // Mock data method
  List<Map<String, dynamic>> _getMockFeedback() {
    return [
      {
        'id': '1',
        'parentName': 'Sarah Johnson',
        'category': 'Driver',
        'priority': 'Medium',
        'status': 'New',
        'rating': 4,
        'message':
            'The driver was very friendly and helpful with my child today. Great service!',
        'submittedAt': '2 hours ago',
      },
      {
        'id': '2',
        'parentName': 'Michael Chen',
        'category': 'Route',
        'priority': 'High',
        'status': 'In Progress',
        'rating': 2,
        'message':
            'The bus was 15 minutes late this morning. This has happened multiple times this week.',
        'submittedAt': '1 day ago',
      },
      {
        'id': '3',
        'parentName': 'Maria Rodriguez',
        'category': 'Safety',
        'priority': 'Urgent',
        'status': 'New',
        'rating': 1,
        'message':
            'I noticed the bus driver was using their phone while driving. This is very concerning for safety.',
        'submittedAt': '3 hours ago',
      },
      {
        'id': '4',
        'parentName': 'David Wilson',
        'category': 'Service',
        'priority': 'Low',
        'status': 'Resolved',
        'rating': 5,
        'message':
            'Thank you for the excellent service. My child loves taking the school bus.',
        'submittedAt': '2 days ago',
      },
      {
        'id': '5',
        'parentName': 'Lisa Davis',
        'category': 'Other',
        'priority': 'Medium',
        'status': 'Closed',
        'rating': 3,
        'message':
            'Could you please provide more information about the bus schedule changes?',
        'submittedAt': '1 week ago',
      },
    ];
  }

  void _handleActionTap(String title) {
    switch (title) {
      case 'Export Feedback Data':
        _exportFeedbackData();
        break;
      case 'Generate Report':
        _generateFeedbackReport();
        break;
      case 'Send Bulk Response':
        _sendBulkResponse();
        break;
      case 'Archive Old Feedback':
        _archiveOldFeedback();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature is being implemented')),
        );
    }
  }

  void _exportFeedbackData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting feedback data...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _generateFeedbackReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating feedback report...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _sendBulkResponse() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing bulk response...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _archiveOldFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Archiving old feedback...'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}
