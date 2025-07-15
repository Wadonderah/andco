import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class NotificationControlScreen extends StatefulWidget {
  const NotificationControlScreen({super.key});

  @override
  State<NotificationControlScreen> createState() =>
      _NotificationControlScreenState();
}

class _NotificationControlScreenState extends State<NotificationControlScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Real notification templates will be loaded from Firebase
  List<NotificationTemplate> _templates = [];

  // Real notification campaigns will be loaded from Firebase
  List<NotificationCampaign> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotificationData();
  }

  Future<void> _loadNotificationData() async {
    try {
      // Load notification templates from Firebase
      final templatesSnapshot = await FirebaseFirestore.instance
          .collection('notification_templates')
          .get();

      setState(() {
        _templates = templatesSnapshot.docs.map((doc) {
          final data = doc.data();
          return NotificationTemplate(
            id: doc.id,
            name: data['name'] ?? 'Unnamed Template',
            type: _parseNotificationType(data['type']),
            category: data['category'] ?? 'General',
            title: data['title'] ?? '',
            message: data['message'] ?? '',
            isActive: data['isActive'] ?? false,
            recipientCount: data['recipientCount'] ?? 0,
            lastSent: data['lastSent'] != null
                ? (data['lastSent'] as Timestamp).toDate()
                : DateTime.now(),
          );
        }).toList();
      });

      // Load notification campaigns from Firebase
      final campaignsSnapshot = await FirebaseFirestore.instance
          .collection('notification_campaigns')
          .get();

      setState(() {
        _campaigns = campaignsSnapshot.docs.map((doc) {
          final data = doc.data();
          return NotificationCampaign(
            id: doc.id,
            name: data['name'] ?? 'Unnamed Campaign',
            status: _parseCampaignStatus(data['status']),
            scheduledDate: data['scheduledDate'] != null
                ? (data['scheduledDate'] as Timestamp).toDate()
                : DateTime.now(),
            targetAudience: data['targetAudience'] ?? 'All Users',
            estimatedReach: data['estimatedReach'] ?? 0,
            template: data['template'] ?? '',
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Failed to load notification data: $e');
      // Keep empty lists if loading fails
    }
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'push':
        return NotificationType.push;
      case 'sms':
        return NotificationType.sms;
      case 'both':
        return NotificationType.both;
      default:
        return NotificationType.push;
    }
  }

  CampaignStatus _parseCampaignStatus(String? status) {
    switch (status) {
      case 'draft':
        return CampaignStatus.draft;
      case 'scheduled':
        return CampaignStatus.scheduled;
      case 'sent':
        return CampaignStatus.sent;
      case 'cancelled':
        return CampaignStatus.cancelled;
      default:
        return CampaignStatus.draft;
    }
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
                      'Push/SMS Alert Controls',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _createNotification,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pink,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // Notification Stats
                Row(
                  children: [
                    _buildStatCard('Total Templates',
                        _templates.length.toString(), AppColors.pink),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Active Templates',
                        _getActiveTemplateCount().toString(),
                        AppColors.success),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard('Sent Today',
                        _getSentTodayCount().toString(), AppColors.info),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard('Total Recipients',
                        _getTotalRecipients().toString(), AppColors.warning),
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
              labelColor: AppColors.pink,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.pink,
              tabs: const [
                Tab(text: 'Templates'),
                Tab(text: 'Campaigns'),
                Tab(text: 'Analytics'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTemplatesTab(),
                _buildCampaignsTab(),
                _buildAnalyticsTab(),
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

  Widget _buildTemplatesTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Templates',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return _buildTemplateCard(template);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(NotificationTemplate template) {
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
                    color: _getTypeColor(template.type).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    _getTypeIcon(template.type),
                    color: _getTypeColor(template.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        template.category,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: template.isActive,
                  onChanged: (value) => _toggleTemplate(template),
                  activeColor: AppColors.success,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    template.message,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                _buildTemplateMetric(
                    'Recipients', template.recipientCount.toString()),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildTemplateMetric('Type', template.type.displayName),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildTemplateMetric(
                    'Last Sent', _formatLastSent(template.lastSent)),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _editTemplate(template),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _sendNow(template),
                  icon: const Icon(Icons.send),
                  label: const Text('Send Now'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _deleteTemplate(template),
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

  Widget _buildTemplateMetric(String label, String value) {
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

  Widget _buildCampaignsTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Notification Campaigns',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _createCampaign,
                icon: const Icon(Icons.campaign),
                label: const Text('Create Campaign'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: ListView.builder(
              itemCount: _campaigns.length,
              itemBuilder: (context, index) {
                final campaign = _campaigns[index];
                return _buildCampaignCard(campaign);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(NotificationCampaign campaign) {
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
                    color: _getCampaignStatusColor(campaign.status)
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    Icons.campaign,
                    color: _getCampaignStatusColor(campaign.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${campaign.targetAudience} • ${campaign.estimatedReach} recipients',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCampaignStatusColor(campaign.status)
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    campaign.status.displayName,
                    style: TextStyle(
                      color: _getCampaignStatusColor(campaign.status),
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
                campaign.template,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                _buildCampaignMetric(
                    'Scheduled', _formatScheduledDate(campaign.scheduledDate)),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildCampaignMetric(
                    'Reach', campaign.estimatedReach.toString()),
                const Spacer(),
                if (campaign.status == CampaignStatus.scheduled) ...[
                  TextButton.icon(
                    onPressed: () => _editCampaign(campaign),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _sendCampaign(campaign),
                    icon: const Icon(Icons.send),
                    label: const Text('Send Now'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignMetric(String label, String value) {
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

  Widget _buildAnalyticsTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: const Center(
        child: Text(
          'Notification Analytics\n(Implementation would go here)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  // Helper Methods
  int _getActiveTemplateCount() {
    return _templates.where((template) => template.isActive).length;
  }

  int _getSentTodayCount() {
    final today = DateTime.now();
    return _templates
        .where((template) =>
            template.lastSent.day == today.day &&
            template.lastSent.month == today.month &&
            template.lastSent.year == today.year)
        .length;
  }

  int _getTotalRecipients() {
    return _templates.fold<int>(
        0, (sum, template) => sum + template.recipientCount);
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.push:
        return AppColors.info;
      case NotificationType.sms:
        return AppColors.warning;
      case NotificationType.both:
        return AppColors.purple;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.push:
        return Icons.notifications;
      case NotificationType.sms:
        return Icons.sms;
      case NotificationType.both:
        return Icons.notifications_active;
    }
  }

  Color _getCampaignStatusColor(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.draft:
        return AppColors.textSecondary;
      case CampaignStatus.scheduled:
        return AppColors.warning;
      case CampaignStatus.sent:
        return AppColors.success;
      case CampaignStatus.cancelled:
        return AppColors.error;
      case CampaignStatus.failed:
        return AppColors.error;
    }
  }

  String _formatLastSent(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatScheduledDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Action Methods
  void _createNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Notification Template'),
        content: const Text(
            'Notification template creation form would be implemented here.'),
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

  void _toggleTemplate(NotificationTemplate template) {
    setState(() {
      final index = _templates.indexWhere((t) => t.id == template.id);
      if (index != -1) {
        _templates[index] = template.copyWith(isActive: !template.isActive);
      }
    });
  }

  void _editTemplate(NotificationTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${template.name}'),
        content: const Text('Template editing form would be implemented here.'),
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

  void _sendNow(NotificationTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: Text(
            'Send "${template.name}" to ${template.recipientCount} recipients now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${template.name} sent successfully')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(NotificationTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _templates.removeWhere((t) => t.id == template.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${template.name} deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createCampaign() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Campaign'),
        content:
            const Text('Campaign creation form would be implemented here.'),
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

  void _editCampaign(NotificationCampaign campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${campaign.name}'),
        content: const Text('Campaign editing form would be implemented here.'),
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

  void _sendCampaign(NotificationCampaign campaign) {
    setState(() {
      final index = _campaigns.indexWhere((c) => c.id == campaign.id);
      if (index != -1) {
        _campaigns[index] = campaign.copyWith(status: CampaignStatus.sent);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${campaign.name} sent successfully')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Data Models
enum NotificationType {
  push('Push'),
  sms('SMS'),
  both('Push + SMS');

  const NotificationType(this.displayName);
  final String displayName;
}

enum CampaignStatus {
  draft('Draft'),
  scheduled('Scheduled'),
  sent('Sent'),
  cancelled('Cancelled'),
  failed('Failed');

  const CampaignStatus(this.displayName);
  final String displayName;
}

class NotificationTemplate {
  final String id;
  final String name;
  final NotificationType type;
  final String category;
  final String title;
  final String message;
  final bool isActive;
  final int recipientCount;
  final DateTime lastSent;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    required this.isActive,
    required this.recipientCount,
    required this.lastSent,
  });

  NotificationTemplate copyWith({
    String? id,
    String? name,
    NotificationType? type,
    String? category,
    String? title,
    String? message,
    bool? isActive,
    int? recipientCount,
    DateTime? lastSent,
  }) {
    return NotificationTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      isActive: isActive ?? this.isActive,
      recipientCount: recipientCount ?? this.recipientCount,
      lastSent: lastSent ?? this.lastSent,
    );
  }
}

class NotificationCampaign {
  final String id;
  final String name;
  final CampaignStatus status;
  final DateTime scheduledDate;
  final String targetAudience;
  final int estimatedReach;
  final String template;

  NotificationCampaign({
    required this.id,
    required this.name,
    required this.status,
    required this.scheduledDate,
    required this.targetAudience,
    required this.estimatedReach,
    required this.template,
  });

  NotificationCampaign copyWith({
    String? id,
    String? name,
    CampaignStatus? status,
    DateTime? scheduledDate,
    String? targetAudience,
    int? estimatedReach,
    String? template,
  }) {
    return NotificationCampaign(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      targetAudience: targetAudience ?? this.targetAudience,
      estimatedReach: estimatedReach ?? this.estimatedReach,
      template: template ?? this.template,
    );
  }
}
