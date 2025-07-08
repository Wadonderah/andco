import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final FeedbackFilter _currentFilter = FeedbackFilter.all;

  final List<FeedbackItem> _feedbackItems = [
    FeedbackItem(
      id: '1',
      title: 'Bus Driver Very Professional',
      message:
          'I wanted to commend John Smith for his excellent driving and patience with the children. He always ensures safety first.',
      type: FeedbackType.compliment,
      category: FeedbackCategory.driver,
      priority: FeedbackPriority.low,
      status: FeedbackStatus.acknowledged,
      submittedBy: 'Sarah Johnson (Parent)',
      submittedDate: DateTime.now().subtract(const Duration(hours: 3)),
      relatedBus: 'Bus 101',
      relatedRoute: 'Route A',
      adminResponse:
          'Thank you for the positive feedback. We have shared this with John and his supervisor.',
      responseDate: DateTime.now().subtract(const Duration(hours: 1)),
      tags: ['Driver Performance', 'Safety', 'Professionalism'],
    ),
    FeedbackItem(
      id: '2',
      title: 'Bus Consistently Late',
      message:
          'The bus has been arriving 10-15 minutes late for the past week. This is causing my child to be late for school.',
      type: FeedbackType.complaint,
      category: FeedbackCategory.schedule,
      priority: FeedbackPriority.high,
      status: FeedbackStatus.investigating,
      submittedBy: 'Michael Chen (Parent)',
      submittedDate: DateTime.now().subtract(const Duration(days: 1)),
      relatedBus: 'Bus 102',
      relatedRoute: 'Route B',
      adminResponse: null,
      responseDate: null,
      tags: ['Punctuality', 'Schedule', 'Route B'],
    ),
    FeedbackItem(
      id: '3',
      title: 'Suggestion for Route Optimization',
      message:
          'I noticed the bus takes a longer route through downtown. A more direct path via Oak Street might save 10 minutes.',
      type: FeedbackType.suggestion,
      category: FeedbackCategory.route,
      priority: FeedbackPriority.medium,
      status: FeedbackStatus.pending,
      submittedBy: 'Lisa Rodriguez (Parent)',
      submittedDate: DateTime.now().subtract(const Duration(days: 2)),
      relatedBus: 'Bus 103',
      relatedRoute: 'Route C',
      adminResponse: null,
      responseDate: null,
      tags: ['Route Optimization', 'Efficiency', 'Time Saving'],
    ),
    FeedbackItem(
      id: '4',
      title: 'Bus Cleanliness Issue',
      message:
          'The bus interior needs better cleaning. There were food crumbs and sticky surfaces yesterday.',
      type: FeedbackType.complaint,
      category: FeedbackCategory.maintenance,
      priority: FeedbackPriority.medium,
      status: FeedbackStatus.resolved,
      submittedBy: 'David Williams (Parent)',
      submittedDate: DateTime.now().subtract(const Duration(days: 3)),
      relatedBus: 'Bus 101',
      relatedRoute: 'Route A',
      adminResponse:
          'We have addressed this with our cleaning crew and implemented daily deep cleaning protocols.',
      responseDate: DateTime.now().subtract(const Duration(days: 1)),
      tags: ['Cleanliness', 'Maintenance', 'Health'],
    ),
    FeedbackItem(
      id: '5',
      title: 'Excellent Communication',
      message:
          'The school transportation office has been very responsive to our questions and concerns. Great job!',
      type: FeedbackType.compliment,
      category: FeedbackCategory.communication,
      priority: FeedbackPriority.low,
      status: FeedbackStatus.acknowledged,
      submittedBy: 'Jennifer Brown (Parent)',
      submittedDate: DateTime.now().subtract(const Duration(days: 4)),
      relatedBus: null,
      relatedRoute: null,
      adminResponse:
          'Thank you for your kind words. We strive to maintain open communication with all families.',
      responseDate: DateTime.now().subtract(const Duration(days: 3)),
      tags: ['Communication', 'Customer Service', 'Appreciation'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Complaints'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Feedback'),
            Tab(text: 'Pending'),
            Tab(text: 'Complaints'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _exportFeedbackData,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllFeedbackTab(),
          _buildPendingTab(),
          _buildComplaintsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildAllFeedbackTab() {
    final filteredFeedback = _getFilteredFeedback();

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
                  hintText:
                      'Search feedback by title, message, or submitter...',
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
                          _feedbackItems.length.toString(), AppColors.info)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildStatCard(
                          'Pending',
                          _getFeedbackCount(FeedbackStatus.pending).toString(),
                          AppColors.warning)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildStatCard(
                          'Complaints',
                          _getFeedbackTypeCount(FeedbackType.complaint)
                              .toString(),
                          AppColors.error)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildStatCard(
                          'This Week', '12', AppColors.secondary)),
                ],
              ),
            ],
          ),
        ),

        // Feedback List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium),
            itemCount: filteredFeedback.length,
            itemBuilder: (context, index) {
              final feedback = filteredFeedback[index];
              return _buildFeedbackCard(feedback);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTab() {
    final pendingFeedback = _feedbackItems
        .where((feedback) => feedback.status == FeedbackStatus.pending)
        .toList();

    return pendingFeedback.isEmpty
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
                  'No Pending Feedback',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppConstants.paddingSmall),
                Text(
                  'All feedback has been addressed',
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
            itemCount: pendingFeedback.length,
            itemBuilder: (context, index) {
              final feedback = pendingFeedback[index];
              return _buildFeedbackCard(feedback);
            },
          );
  }

  Widget _buildComplaintsTab() {
    final complaints = _feedbackItems
        .where((feedback) => feedback.type == FeedbackType.complaint)
        .toList();

    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        return _buildFeedbackCard(complaint);
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
            'Feedback Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Trends and insights from feedback data',
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

  Widget _buildFeedbackCard(FeedbackItem feedback) {
    final typeColor = _getFeedbackTypeColor(feedback.type);
    final statusColor = _getFeedbackStatusColor(feedback.status);
    final priorityColor = _getFeedbackPriorityColor(feedback.priority);

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
                    color: typeColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    _getFeedbackTypeIcon(feedback.type),
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${feedback.submittedBy}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (feedback.relatedBus != null)
                        Text(
                          '${feedback.relatedBus} • ${feedback.relatedRoute}',
                          style: const TextStyle(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: Text(
                        feedback.priority.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
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
                        feedback.status.name.toUpperCase(),
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

            // Message
            Text(
              feedback.message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Tags
            if (feedback.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: feedback.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            // Admin Response
            if (feedback.adminResponse != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            size: 16, color: AppColors.success),
                        SizedBox(width: 8),
                        Text(
                          'Admin Response',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feedback.adminResponse!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (feedback.responseDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Responded: ${_formatDateTime(feedback.responseDate!)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewFeedbackDetails(feedback),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                if (feedback.status == FeedbackStatus.pending)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respondToFeedback(feedback),
                      icon: const Icon(Icons.reply),
                      label: const Text('Respond'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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

  List<FeedbackItem> _getFilteredFeedback() {
    return _feedbackItems.where((feedback) {
      final matchesSearch = _searchQuery.isEmpty ||
          feedback.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          feedback.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          feedback.submittedBy
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      return matchesSearch;
    }).toList();
  }

  int _getFeedbackCount(FeedbackStatus status) {
    return _feedbackItems.where((feedback) => feedback.status == status).length;
  }

  int _getFeedbackTypeCount(FeedbackType type) {
    return _feedbackItems.where((feedback) => feedback.type == type).length;
  }

  Color _getFeedbackTypeColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.complaint:
        return AppColors.error;
      case FeedbackType.compliment:
        return AppColors.success;
      case FeedbackType.suggestion:
        return AppColors.info;
      case FeedbackType.inquiry:
        return AppColors.warning;
    }
  }

  Color _getFeedbackStatusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return AppColors.warning;
      case FeedbackStatus.investigating:
        return AppColors.info;
      case FeedbackStatus.acknowledged:
        return AppColors.secondary;
      case FeedbackStatus.resolved:
        return AppColors.success;
    }
  }

  Color _getFeedbackPriorityColor(FeedbackPriority priority) {
    switch (priority) {
      case FeedbackPriority.low:
        return AppColors.success;
      case FeedbackPriority.medium:
        return AppColors.warning;
      case FeedbackPriority.high:
        return AppColors.error;
    }
  }

  IconData _getFeedbackTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.complaint:
        return Icons.report_problem;
      case FeedbackType.compliment:
        return Icons.thumb_up;
      case FeedbackType.suggestion:
        return Icons.lightbulb;
      case FeedbackType.inquiry:
        return Icons.help;
    }
  }

  void _viewFeedbackDetails(FeedbackItem feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feedback.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('From: ${feedback.submittedBy}'),
              Text('Type: ${feedback.type.name}'),
              Text('Category: ${feedback.category.name}'),
              Text('Priority: ${feedback.priority.name}'),
              Text('Status: ${feedback.status.name}'),
              const SizedBox(height: 8),
              const Text('Message:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(feedback.message),
              if (feedback.adminResponse != null) ...[
                const SizedBox(height: 8),
                const Text('Admin Response:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(feedback.adminResponse!),
              ],
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

  void _respondToFeedback(FeedbackItem feedback) {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Respond to: ${feedback.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${feedback.submittedBy}'),
            const SizedBox(height: 8),
            Text('Message: ${feedback.message}'),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Your Response',
                border: OutlineInputBorder(),
                hintText: 'Type your response here...',
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
              if (responseController.text.isNotEmpty) {
                setState(() {
                  final index =
                      _feedbackItems.indexWhere((f) => f.id == feedback.id);
                  if (index != -1) {
                    _feedbackItems[index] = feedback.copyWith(
                      adminResponse: responseController.text,
                      responseDate: DateTime.now(),
                      status: FeedbackStatus.acknowledged,
                    );
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Response sent successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Send Response'),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options will be implemented')),
    );
  }

  void _exportFeedbackData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting feedback data...')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum FeedbackType { complaint, compliment, suggestion, inquiry }

enum FeedbackCategory {
  driver,
  schedule,
  route,
  maintenance,
  communication,
  safety,
  other
}

enum FeedbackPriority { low, medium, high }

enum FeedbackStatus { pending, investigating, acknowledged, resolved }

enum FeedbackFilter { all, pending, complaints, compliments, highPriority }

class FeedbackItem {
  final String id;
  final String title;
  final String message;
  final FeedbackType type;
  final FeedbackCategory category;
  final FeedbackPriority priority;
  final FeedbackStatus status;
  final String submittedBy;
  final DateTime submittedDate;
  final String? relatedBus;
  final String? relatedRoute;
  final String? adminResponse;
  final DateTime? responseDate;
  final List<String> tags;

  FeedbackItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.priority,
    required this.status,
    required this.submittedBy,
    required this.submittedDate,
    this.relatedBus,
    this.relatedRoute,
    this.adminResponse,
    this.responseDate,
    required this.tags,
  });

  FeedbackItem copyWith({
    String? id,
    String? title,
    String? message,
    FeedbackType? type,
    FeedbackCategory? category,
    FeedbackPriority? priority,
    FeedbackStatus? status,
    String? submittedBy,
    DateTime? submittedDate,
    String? relatedBus,
    String? relatedRoute,
    String? adminResponse,
    DateTime? responseDate,
    List<String>? tags,
  }) {
    return FeedbackItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedDate: submittedDate ?? this.submittedDate,
      relatedBus: relatedBus ?? this.relatedBus,
      relatedRoute: relatedRoute ?? this.relatedRoute,
      adminResponse: adminResponse ?? this.adminResponse,
      responseDate: responseDate ?? this.responseDate,
      tags: tags ?? this.tags,
    );
  }
}
