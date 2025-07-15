import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class CMSScreen extends StatefulWidget {
  const CMSScreen({super.key});

  @override
  State<CMSScreen> createState() => _CMSScreenState();
}

class _CMSScreenState extends State<CMSScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  final List<CMSContent> _content = [
    CMSContent(
      id: '1',
      title: 'How to Track Your Child\'s Bus',
      type: ContentType.faq,
      category: 'Bus Tracking',
      content:
          'To track your child\'s bus, open the app and navigate to the "Track Bus" section...',
      status: ContentStatus.published,
      language: 'English',
      author: 'Admin',
      createdDate: DateTime.now().subtract(const Duration(days: 5)),
      lastModified: DateTime.now().subtract(const Duration(days: 2)),
      views: 1250,
      version: 2,
    ),
    CMSContent(
      id: '2',
      title: 'Privacy Policy',
      type: ContentType.policy,
      category: 'Legal',
      content:
          'This Privacy Policy describes how we collect, use, and protect your information...',
      status: ContentStatus.published,
      language: 'English',
      author: 'Legal Team',
      createdDate: DateTime.now().subtract(const Duration(days: 30)),
      lastModified: DateTime.now().subtract(const Duration(days: 10)),
      views: 3450,
      version: 3,
    ),
    CMSContent(
      id: '3',
      title: 'Getting Started Guide',
      type: ContentType.helpDoc,
      category: 'Onboarding',
      content:
          'Welcome to the School Bus Tracking System! This guide will help you get started...',
      status: ContentStatus.draft,
      language: 'English',
      author: 'Support Team',
      createdDate: DateTime.now().subtract(const Duration(days: 1)),
      lastModified: DateTime.now().subtract(const Duration(hours: 2)),
      views: 0,
      version: 1,
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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Content Management System',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _createContent,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Content'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // CMS Stats
                Row(
                  children: [
                    _buildStatCard('Total Content', _content.length.toString(),
                        AppColors.indigo),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard('Published', _getPublishedCount().toString(),
                        AppColors.success),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard('Drafts', _getDraftCount().toString(),
                        AppColors.warning),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard('Total Views', _getTotalViews().toString(),
                        AppColors.info),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.indigo,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.indigo,
              isScrollable: true,
              tabs: const [
                Tab(text: 'All Content'),
                Tab(text: 'FAQs'),
                Tab(text: 'Help Docs'),
                Tab(text: 'Policies'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllContentTab(),
                _buildFAQsTab(),
                _buildHelpDocsTab(),
                _buildPoliciesTab(),
              ],
            ),
          ),
        ],
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

  Widget _buildAllContentTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Content',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: ListView.builder(
              itemCount: _content.length,
              itemBuilder: (context, index) {
                final content = _content[index];
                return _buildContentCard(content);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(CMSContent content) {
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
                    color: _getTypeColor(content.type).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    _getTypeIcon(content.type),
                    color: _getTypeColor(content.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${content.type.displayName} • ${content.category}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        'By ${content.author} • v${content.version} • ${content.views} views',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(content.status).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    content.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(content.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: Text(
                content.content.length > 150
                    ? '${content.content.substring(0, 150)}...'
                    : content.content,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                _buildContentMetric(
                    'Created', _formatDate(content.createdDate)),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildContentMetric(
                    'Modified', _formatDate(content.lastModified)),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildContentMetric('Language', content.language),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _editContent(content),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _viewVersionHistory(content),
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                ),
                if (content.status == ContentStatus.draft)
                  TextButton.icon(
                    onPressed: () => _publishContent(content),
                    icon: const Icon(Icons.publish),
                    label: const Text('Publish'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.success),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _deleteContent(content),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentMetric(String label, String value) {
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

  Widget _buildFAQsTab() {
    final faqs = _content.where((c) => c.type == ContentType.faq).toList();
    return _buildContentTypeTab('FAQs', faqs);
  }

  Widget _buildHelpDocsTab() {
    final helpDocs =
        _content.where((c) => c.type == ContentType.helpDoc).toList();
    return _buildContentTypeTab('Help Documentation', helpDocs);
  }

  Widget _buildPoliciesTab() {
    final policies =
        _content.where((c) => c.type == ContentType.policy).toList();
    return _buildContentTypeTab('Policies', policies);
  }

  Widget _buildContentTypeTab(String title, List<CMSContent> contentList) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: contentList.isEmpty
                ? _buildEmptyContentState(title)
                : ListView.builder(
                    itemCount: contentList.length,
                    itemBuilder: (context, index) {
                      final content = contentList[index];
                      return _buildContentCard(content);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  int _getPublishedCount() {
    return _content.where((c) => c.status == ContentStatus.published).length;
  }

  int _getDraftCount() {
    return _content.where((c) => c.status == ContentStatus.draft).length;
  }

  int _getTotalViews() {
    return _content.fold<int>(0, (sum, content) => sum + content.views);
  }

  Color _getTypeColor(ContentType type) {
    switch (type) {
      case ContentType.faq:
        return AppColors.info;
      case ContentType.helpDoc:
        return AppColors.success;
      case ContentType.policy:
        return AppColors.warning;
    }
  }

  IconData _getTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.faq:
        return Icons.help_outline;
      case ContentType.helpDoc:
        return Icons.description;
      case ContentType.policy:
        return Icons.policy;
    }
  }

  Color _getStatusColor(ContentStatus status) {
    switch (status) {
      case ContentStatus.published:
        return AppColors.success;
      case ContentStatus.draft:
        return AppColors.warning;
      case ContentStatus.archived:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyContentState(String contentType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getContentTypeIcon(contentType),
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No $contentType Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first ${contentType.toLowerCase()} to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createContent,
            icon: const Icon(Icons.add),
            label: Text('Create $contentType'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContentTypeIcon(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'faqs':
        return Icons.help_outline;
      case 'help docs':
        return Icons.description_outlined;
      case 'policies':
        return Icons.policy_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  // Action Methods
  void _createContent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Content'),
        content: const Text(
            'Content creation form with rich text editor would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _editContent(CMSContent content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${content.title}'),
        content: const Text(
            'Content editing form with rich text editor would be implemented here.'),
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

  void _viewVersionHistory(CMSContent content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Version History - ${content.title}'),
        content:
            const Text('Version history and comparison would be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _publishContent(CMSContent content) {
    setState(() {
      final index = _content.indexWhere((c) => c.id == content.id);
      if (index != -1) {
        _content[index] = content.copyWith(status: ContentStatus.published);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${content.title} has been published')),
    );
  }

  void _deleteContent(CMSContent content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete "${content.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _content.removeWhere((c) => c.id == content.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${content.title} has been deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Data Models
enum ContentType {
  faq('FAQ'),
  helpDoc('Help Document'),
  policy('Policy');

  const ContentType(this.displayName);
  final String displayName;
}

enum ContentStatus {
  published('Published'),
  draft('Draft'),
  archived('Archived');

  const ContentStatus(this.displayName);
  final String displayName;
}

class CMSContent {
  final String id;
  final String title;
  final ContentType type;
  final String category;
  final String content;
  final ContentStatus status;
  final String language;
  final String author;
  final DateTime createdDate;
  final DateTime lastModified;
  final int views;
  final int version;

  CMSContent({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.content,
    required this.status,
    required this.language,
    required this.author,
    required this.createdDate,
    required this.lastModified,
    required this.views,
    required this.version,
  });

  CMSContent copyWith({
    String? id,
    String? title,
    ContentType? type,
    String? category,
    String? content,
    ContentStatus? status,
    String? language,
    String? author,
    DateTime? createdDate,
    DateTime? lastModified,
    int? views,
    int? version,
  }) {
    return CMSContent(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      content: content ?? this.content,
      status: status ?? this.status,
      language: language ?? this.language,
      author: author ?? this.author,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      views: views ?? this.views,
      version: version ?? this.version,
    );
  }
}
