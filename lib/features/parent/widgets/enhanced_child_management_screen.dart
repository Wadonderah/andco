import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/child_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'enhanced_add_child_screen.dart';

class EnhancedChildManagementScreen extends ConsumerStatefulWidget {
  const EnhancedChildManagementScreen({super.key});

  @override
  ConsumerState<EnhancedChildManagementScreen> createState() =>
      _EnhancedChildManagementScreenState();
}

class _EnhancedChildManagementScreenState
    extends ConsumerState<EnhancedChildManagementScreen> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addChild,
            icon: const Icon(Icons.add),
            tooltip: 'Add Child',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: authState.when(
          data: (user) =>
              user != null ? _buildChildrenList(user.uid) : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addChild,
        backgroundColor: AppColors.parentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildChildrenList(String parentId) {
    final childrenAsync = ref.watch(childrenByParentStreamProvider(parentId));

    return childrenAsync.when(
      data: (children) =>
          children.isEmpty ? _buildEmptyState() : _buildChildrenGrid(children),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error loading children: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(childrenByParentStreamProvider(parentId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.child_care,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            'No Children Added',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Add your children to start tracking their school transportation',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton.icon(
            onPressed: _addChild,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Child'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.parentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenGrid(List<ChildModel> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Section
          _buildSummarySection(children),

          const SizedBox(height: AppConstants.paddingLarge),

          // Children Grid
          Text(
            'Your Children',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.paddingMedium,
              mainAxisSpacing: AppConstants.paddingMedium,
              childAspectRatio: 0.8,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) {
              return _buildChildCard(children[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(List<ChildModel> children) {
    final activeChildren = children.where((c) => c.isActive).length;
    final totalRoutes = children.where((c) => c.routeId != null).length;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.parentColor,
            AppColors.parentColor.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Row(
        children: [
          Expanded(
            child:
                _buildSummaryItem('Total Children', children.length.toString()),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildSummaryItem('Active', activeChildren.toString()),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildSummaryItem('On Routes', totalRoutes.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChildCard(ChildModel child) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: InkWell(
        onTap: () => _viewChildDetails(child),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child Avatar and Status
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.parentColor.withOpacity(0.1),
                    backgroundImage: child.photoUrl != null
                        ? NetworkImage(child.photoUrl!)
                        : null,
                    child: child.photoUrl == null
                        ? Icon(
                            child.gender == 'Male' ? Icons.boy : Icons.girl,
                            color: AppColors.parentColor,
                            size: 30,
                          )
                        : null,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: child.isActive
                          ? AppColors.success
                          : AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      child.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Child Name
              Text(
                child.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // School and Grade
              Text(
                '${child.grade} • ${child.className}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Route Info
              if (child.routeId != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_bus,
                          size: 12, color: AppColors.info),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Route ${child.routeId}',
                          style: TextStyle(
                            color: AppColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 12, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'No Route',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _editChild(child),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.parentColor),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          color: AppColors.parentColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _trackChild(child),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.parentColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Track',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            'Please log in to manage your children',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _addChild() async {
    final result = await Navigator.push<ChildModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedAddChildScreen(),
      ),
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _editChild(ChildModel child) async {
    final result = await Navigator.push<ChildModel>(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedAddChildScreen(child: child),
      ),
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _viewChildDetails(ChildModel child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChildDetailsSheet(child),
    );
  }

  Widget _buildChildDetailsSheet(ChildModel child) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.parentColor.withOpacity(0.1),
                  backgroundImage: child.photoUrl != null
                      ? NetworkImage(child.photoUrl!)
                      : null,
                  child: child.photoUrl == null
                      ? Icon(
                          child.gender == 'Male' ? Icons.boy : Icons.girl,
                          color: AppColors.parentColor,
                          size: 35,
                        )
                      : null,
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${child.grade} • ${child.className}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Basic Information', [
                    _buildDetailItem('Gender', child.gender ?? 'Not specified'),
                    _buildDetailItem(
                        'Date of Birth',
                        child.dateOfBirth != null
                            ? DateFormat('MMM dd, yyyy')
                                .format(child.dateOfBirth)
                            : 'Not provided'),
                    _buildDetailItem('Age', '${child.age} years old'),
                  ]),
                  const SizedBox(height: AppConstants.paddingLarge),
                  _buildDetailSection('School Information', [
                    _buildDetailItem('Class', child.className),
                    _buildDetailItem('Grade', child.grade),
                    _buildDetailItem(
                        'Student ID', child.studentId ?? 'Not provided'),
                  ]),
                  const SizedBox(height: AppConstants.paddingLarge),
                  _buildDetailSection('Transportation', [
                    _buildDetailItem('Route', child.routeId ?? 'Not assigned'),
                    _buildDetailItem('Bus', child.busId ?? 'Not assigned'),
                    _buildDetailItem(
                        'Status', child.isActive ? 'Active' : 'Inactive'),
                  ]),
                  if (child.medicalInfo?.isNotEmpty == true) ...[
                    const SizedBox(height: AppConstants.paddingLarge),
                    _buildDetailSection('Medical Information', [
                      _buildDetailItem('Notes', child.medicalInfo!),
                    ]),
                  ],
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editChild(child);
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _trackChild(child);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.parentColor,
                    ),
                    child: const Text('Track',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        ...items,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _trackChild(ChildModel child) {
    // TODO: Implement child tracking
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tracking ${child.name}')),
    );
  }
}
