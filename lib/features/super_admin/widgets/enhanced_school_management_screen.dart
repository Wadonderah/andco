import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/approval_workflow_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/school_model.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedSchoolManagementScreen extends ConsumerStatefulWidget {
  const EnhancedSchoolManagementScreen({super.key});

  @override
  ConsumerState<EnhancedSchoolManagementScreen> createState() =>
      _EnhancedSchoolManagementScreenState();
}

class _EnhancedSchoolManagementScreenState
    extends ConsumerState<EnhancedSchoolManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Management'),
        backgroundColor: AppColors.superAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle), text: 'Active'),
            Tab(icon: Icon(Icons.cancel), text: 'Rejected'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPendingSchoolsTab(),
            _buildActiveSchoolsTab(),
            _buildRejectedSchoolsTab(),
            _buildAnalyticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSchoolsTab() {
    final pendingSchoolsAsync = ref.watch(pendingSchoolsStreamProvider);

    return pendingSchoolsAsync.when(
      data: (schools) => _buildSchoolsList(schools, isPending: true),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error loading pending schools: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(pendingSchoolsStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSchoolsTab() {
    final activeSchoolsAsync = ref.watch(activeSchoolsStreamProvider);

    return activeSchoolsAsync.when(
      data: (schools) => _buildSchoolsList(schools, isPending: false),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error loading active schools: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(activeSchoolsStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedSchoolsTab() {
    final allSchoolsAsync = ref.watch(allSchoolsStreamProvider);

    return allSchoolsAsync.when(
      data: (schools) {
        final rejectedSchools = schools.where((s) => s.isRejected).toList();
        return _buildSchoolsList(rejectedSchools, isPending: false);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error loading rejected schools: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(allSchoolsStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolsList(List<SchoolModel> schools,
      {required bool isPending}) {
    final filteredSchools = schools.where((school) {
      if (_searchQuery.isEmpty) return true;
      return school.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          school.contactEmail
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.surface,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search schools...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Schools List
        Expanded(
          child: filteredSchools.isEmpty
              ? _buildEmptyState(isPending)
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: filteredSchools.length,
                  itemBuilder: (context, index) {
                    return _buildSchoolCard(filteredSchools[index], isPending);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isPending) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending ? Icons.pending_actions : Icons.school,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isPending ? 'No Pending Schools' : 'No Schools Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'New school approval requests will appear here'
                : 'Schools matching your search will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolCard(SchoolModel school, bool isPending) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        school.contactEmail,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(school.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    school.statusDisplayName,
                    style: TextStyle(
                      color: _getStatusColor(school.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Details
            _buildDetailRow('Principal', school.principalName),
            _buildDetailRow('Phone', school.contactPhone),
            _buildDetailRow('Address', school.address),
            _buildDetailRow('Type', school.typeDisplayName),
            _buildDetailRow(
                'Subscription', school.subscriptionPlan.toUpperCase()),
            _buildDetailRow(
                'Created', DateFormat('MMM dd, yyyy').format(school.createdAt)),

            if (school.rejectionReason != null)
              _buildDetailRow('Rejection Reason', school.rejectionReason!,
                  isError: true),

            const SizedBox(height: AppConstants.paddingMedium),

            // Actions
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveSchool(school),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectSchool(school),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewSchoolDetails(school),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  if (school.isActive)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _suspendSchool(school),
                        icon: const Icon(Icons.pause),
                        label: const Text('Suspend'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (school.isSuspended)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _reactivateSchool(school),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Reactivate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? AppColors.error : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'School Management Analytics',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.superAdminColor,
                ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Key Metrics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: AppConstants.paddingMedium,
            mainAxisSpacing: AppConstants.paddingMedium,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Active Schools',
                '156',
                Icons.school,
                AppColors.success,
                '+12%',
              ),
              _buildMetricCard(
                'Total Students',
                '8,432',
                Icons.people,
                AppColors.primary,
                '+5%',
              ),
              _buildMetricCard(
                'Active Drivers',
                '324',
                Icons.directions_bus,
                AppColors.driverColor,
                '+8%',
              ),
              _buildMetricCard(
                'Monthly Revenue',
                '\$45,230',
                Icons.attach_money,
                AppColors.warning,
                '+15%',
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Performance Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Performance indicators
                  _buildPerformanceIndicator(
                      'On-time Performance', 0.94, AppColors.success),
                  const SizedBox(height: AppConstants.paddingSmall),
                  _buildPerformanceIndicator(
                      'Parent Satisfaction', 0.87, AppColors.primary),
                  const SizedBox(height: AppConstants.paddingSmall),
                  _buildPerformanceIndicator(
                      'Driver Efficiency', 0.91, AppColors.driverColor),
                  const SizedBox(height: AppConstants.paddingSmall),
                  _buildPerformanceIndicator(
                      'System Uptime', 0.99, AppColors.success),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Recent Issues
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Issues',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to full issues list
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  ...List.generate(
                      4,
                      (index) => _buildIssueItem(
                            'Issue ${index + 1}',
                            'Description of the issue that needs attention',
                            index == 0
                                ? 'High'
                                : index == 1
                                    ? 'Medium'
                                    : 'Low',
                            '${index + 1}h ago',
                          )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String change) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24, color: color),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    color: change.startsWith('+')
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${(value * 100).toInt()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildIssueItem(
      String title, String description, String priority, String time) {
    Color priorityColor = priority == 'High'
        ? AppColors.error
        : priority == 'Medium'
            ? AppColors.warning
            : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  description,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 10,
                    color: priorityColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SchoolStatus status) {
    switch (status) {
      case SchoolStatus.pending:
        return AppColors.warning;
      case SchoolStatus.active:
        return AppColors.success;
      case SchoolStatus.rejected:
        return AppColors.error;
      case SchoolStatus.suspended:
        return AppColors.warning;
      case SchoolStatus.inactive:
        return AppColors.textSecondary;
    }
  }

  // Action methods
  Future<void> _approveSchool(SchoolModel school) async {
    final authState = ref.read(authControllerProvider);
    final user = authState.value;

    if (user == null) return;

    final confirmed = await _showConfirmationDialog(
      'Approve School',
      'Are you sure you want to approve ${school.name}?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final approvalService = ref.read(approvalWorkflowServiceProvider);
      final result = await approvalService.approveSchool(
        schoolId: school.id,
        approvedBy: user.uid,
        notes: 'Approved by Super Admin',
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${school.name} approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve school: ${result.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving school: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectSchool(SchoolModel school) async {
    final authState = ref.read(authControllerProvider);
    final user = authState.value;

    if (user == null) return;

    final reason = await _showRejectDialog(school.name);
    if (reason == null) return;

    setState(() => _isLoading = true);

    try {
      final approvalService = ref.read(approvalWorkflowServiceProvider);
      final result = await approvalService.rejectSchool(
        schoolId: school.id,
        rejectedBy: user.uid,
        reason: reason,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${school.name} rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject school: ${result.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting school: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _showRejectDialog(String schoolName) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $schoolName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    controller.dispose();
    return result?.isNotEmpty == true ? result : null;
  }

  void _viewSchoolDetails(SchoolModel school) {
    // TODO: Implement school details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${school.name}')),
    );
  }

  void _suspendSchool(SchoolModel school) {
    // TODO: Implement school suspension
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Suspend ${school.name}')),
    );
  }

  void _reactivateSchool(SchoolModel school) {
    // TODO: Implement school reactivation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reactivate ${school.name}')),
    );
  }
}
