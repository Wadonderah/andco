import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/jira_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/responsive_auth_button.dart';

/// Parent support screen with Jira integration
class ParentSupportScreen extends ConsumerStatefulWidget {
  const ParentSupportScreen({super.key});

  @override
  ConsumerState<ParentSupportScreen> createState() =>
      _ParentSupportScreenState();
}

class _ParentSupportScreenState extends ConsumerState<ParentSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();

  // Form state
  String _selectedCategory = 'General';
  String _selectedPriority = 'Medium';
  bool _isSubmitting = false;
  bool _isLoading = false;

  // Data
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic>? _selectedTicket;

  final List<String> _categories = [
    'General',
    'Technical',
    'Billing',
    'Feature Request',
    'Bug Report',
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseService.instance.auth.currentUser;
      if (user != null) {
        final tickets = await JiraService.instance.getParentTickets(
          parentId: user.uid,
        );
        setState(() => _tickets = tickets);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load support tickets: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTicket() async {
    if (_subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseService.instance.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final result = await JiraService.instance.submitSupportTicket(
        parentId: user.uid,
        parentName: user.displayName ?? 'Unknown',
        parentEmail: user.email ?? 'unknown@email.com',
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        additionalData: {
          'app_version': '1.0.0',
          'platform': 'mobile',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (result['success'] == true) {
        _showSuccessSnackBar('Support ticket created: ${result['issueKey']}');
        _clearForm();
        _loadTickets();
        _tabController.animateTo(1); // Switch to tickets tab
      } else {
        throw Exception(result['message'] ?? 'Failed to create ticket');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to submit ticket: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _addComment(String issueKey) async {
    if (_commentController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a comment');
      return;
    }

    try {
      final user = FirebaseService.instance.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final success = await JiraService.instance.addTicketComment(
        issueKey: issueKey,
        parentId: user.uid,
        comment: _commentController.text.trim(),
      );

      if (success) {
        _showSuccessSnackBar('Comment added successfully');
        _commentController.clear();
        _loadTickets();
      } else {
        throw Exception('Failed to add comment');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add comment: $e');
    }
  }

  void _clearForm() {
    _subjectController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = 'General';
      _selectedPriority = 'Medium';
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'New Ticket', icon: Icon(Icons.add_circle_outline)),
            Tab(text: 'My Tickets', icon: Icon(Icons.support_agent)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewTicketTab(),
          _buildMyTicketsTab(),
        ],
      ),
    );
  }

  Widget _buildNewTicketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submit a Support Request',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Category Selection
          const Text(
            'Category *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value!);
            },
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Priority Selection
          const Text(
            'Priority *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          DropdownButtonFormField<String>(
            value: _selectedPriority,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _priorities.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Row(
                  children: [
                    Icon(
                      _getPriorityIcon(priority),
                      color: _getPriorityColor(priority),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(priority),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedPriority = value!);
            },
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Subject Field
          CustomTextField(
            controller: _subjectController,
            label: 'Subject *',
            hint: 'Brief description of your issue',
            maxLength: 100,
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Description Field
          CustomTextField(
            controller: _descriptionController,
            label: 'Description *',
            hint: 'Please provide detailed information about your issue',
            maxLines: 6,
            maxLength: 1000,
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Submit Button
          ResponsiveAuthButton(
            text: 'Submit Ticket',
            onPressed: _isSubmitting ? null : _submitTicket,
            isLoading: _isSubmitting,
            customColor: AppColors.primary,
            type: AuthButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No support tickets yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submit your first support request using the form',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          return _buildTicketCard(ticket);
        },
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['currentStatus'] ?? ticket['status'] ?? 'Unknown';
    final priority = ticket['priority'] ?? 'Medium';

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 2,
      child: InkWell(
        onTap: () => _showTicketDetails(ticket),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket['subject'] ?? 'No Subject',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(status).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket['issueKey'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    _getPriorityIcon(priority),
                    size: 16,
                    color: _getPriorityColor(priority),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    priority,
                    style: TextStyle(
                      fontSize: 14,
                      color: _getPriorityColor(priority),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                'Category: ${ticket['category'] ?? 'General'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (ticket['createdAt'] != null) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  'Created: ${_formatDate(ticket['createdAt'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _buildTicketDetailsContent(ticket, scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDetailsContent(
      Map<String, dynamic> ticket, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticket['subject'] ?? 'No Subject',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Ticket Info
          _buildInfoRow('Ticket ID', ticket['issueKey'] ?? 'Unknown'),
          _buildInfoRow('Status',
              ticket['currentStatus'] ?? ticket['status'] ?? 'Unknown'),
          _buildInfoRow('Priority', ticket['priority'] ?? 'Medium'),
          _buildInfoRow('Category', ticket['category'] ?? 'General'),
          if (ticket['assignee'] != null)
            _buildInfoRow('Assigned to', ticket['assignee']),

          const SizedBox(height: AppConstants.paddingMedium),
          const Divider(),
          const SizedBox(height: AppConstants.paddingMedium),

          // Comments Section
          const Text(
            'Comments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          if (ticket['comments'] != null &&
              (ticket['comments'] as List).isNotEmpty) ...[
            ...(ticket['comments'] as List)
                .map((comment) => _buildCommentCard(comment)),
          ] else ...[
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],

          const SizedBox(height: AppConstants.paddingMedium),

          // Add Comment Section
          const Text(
            'Add Comment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          CustomTextField(
            controller: _commentController,
            label: 'Comment',
            hint: 'Type your comment here...',
            maxLines: 3,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          SizedBox(
            width: double.infinity,
            child: ResponsiveAuthButton(
              text: 'Add Comment',
              onPressed: () => _addComment(ticket['issueKey']),
              customColor: AppColors.primary,
              type: AuthButtonType.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  comment['author'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(comment['created']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              comment['body'] ?? 'No content',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.low_priority;
      default:
        return Icons.help;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'medium':
        return Colors.blue[700]!;
      case 'low':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'to do':
        return Colors.blue[700]!;
      case 'in progress':
        return Colors.orange[700]!;
      case 'done':
      case 'resolved':
      case 'closed':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.grey[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _formatDate(dynamic dateTime) {
    try {
      if (dateTime is String) {
        final date = DateTime.parse(dateTime);
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      return 'Unknown';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
