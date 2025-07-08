import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class SafetyChecksScreen extends StatefulWidget {
  const SafetyChecksScreen({super.key});

  @override
  State<SafetyChecksScreen> createState() => _SafetyChecksScreenState();
}

class _SafetyChecksScreenState extends State<SafetyChecksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  final List<SafetyCheckItem> _preTripChecks = [
    SafetyCheckItem(
      id: 'exterior_inspection',
      category: 'Exterior',
      title: 'Vehicle Exterior Inspection',
      description: 'Check for damage, tire condition, lights',
      isRequired: true,
      status: CheckStatus.pending,
      requiresPhoto: true,
    ),
    SafetyCheckItem(
      id: 'interior_inspection',
      category: 'Interior',
      title: 'Interior Cleanliness & Safety',
      description: 'Seats, aisles, emergency exits clear',
      isRequired: true,
      status: CheckStatus.pending,
      requiresPhoto: false,
    ),
    SafetyCheckItem(
      id: 'emergency_equipment',
      category: 'Safety',
      title: 'Emergency Equipment Check',
      description: 'First aid kit, fire extinguisher, emergency exits',
      isRequired: true,
      status: CheckStatus.pending,
      requiresPhoto: false,
    ),
    SafetyCheckItem(
      id: 'engine_fluids',
      category: 'Engine',
      title: 'Engine & Fluid Levels',
      description: 'Oil, coolant, brake fluid levels',
      isRequired: true,
      status: CheckStatus.pending,
      requiresPhoto: false,
    ),
    SafetyCheckItem(
      id: 'lights_signals',
      category: 'Electrical',
      title: 'Lights & Signals',
      description: 'Headlights, taillights, turn signals, hazards',
      isRequired: true,
      status: CheckStatus.pending,
      requiresPhoto: false,
    ),
    SafetyCheckItem(
      id: 'mirrors_visibility',
      category: 'Visibility',
      title: 'Mirrors & Visibility',
      description: 'All mirrors clean and properly adjusted',
      isRequired: true,
      status: CheckStatus.pending,
      requiresPhoto: false,
    ),
  ];

  final List<SafetyCheckItem> _postTripChecks = [
    SafetyCheckItem(
      id: 'student_sweep',
      category: 'Safety',
      title: 'Student Sweep Check',
      description: 'Walk through entire bus to ensure no students remain',
      isRequired: true,
      status: CheckStatus.pending,
      requiresPhoto: true,
    ),
    SafetyCheckItem(
      id: 'lost_items',
      category: 'Interior',
      title: 'Lost Items Check',
      description: 'Check for and collect any lost student items',
      isRequired: true,
      status: CheckStatus.pending,
      requiresPhoto: false,
    ),
    SafetyCheckItem(
      id: 'damage_report',
      category: 'Maintenance',
      title: 'Damage Assessment',
      description: 'Report any new damage or maintenance issues',
      isRequired: false,
      status: CheckStatus.pending,
      requiresPhoto: true,
    ),
    SafetyCheckItem(
      id: 'fuel_level',
      category: 'Maintenance',
      title: 'Fuel Level Check',
      description: 'Record current fuel level',
      isRequired: true,
      status: CheckStatus.pending,
      requiresPhoto: false,
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
        title: const Text('Safety Checks'),
        backgroundColor: AppColors.driverColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pre-Trip'),
            Tab(text: 'Post-Trip'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showChecklistSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPreTripTab(),
          _buildPostTripTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildPreTripTab() {
    final completedChecks = _preTripChecks.where((check) => check.status == CheckStatus.completed).length;
    final totalChecks = _preTripChecks.length;
    final progress = totalChecks > 0 ? completedChecks / totalChecks : 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Card
          Card(
            color: AppColors.driverColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        color: AppColors.driverColor,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text(
                        'Pre-Trip Inspection',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completedChecks/$totalChecks',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.driverColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? AppColors.success : AppColors.driverColor,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  Text(
                    progress == 1.0 
                        ? 'All checks completed! Ready to start route.'
                        : 'Complete all required checks before starting route.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: progress == 1.0 ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Checklist Items
          Text(
            'Safety Checklist',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          ..._preTripChecks.map((check) => _buildCheckItem(check, true)).toList(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Action Buttons
          if (progress == 1.0) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitPreTripChecks,
                icon: const Icon(Icons.check_circle),
                label: const Text('Submit Pre-Trip Inspection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetChecks,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _autoCompleteChecks,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Quick Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostTripTab() {
    final completedChecks = _postTripChecks.where((check) => check.status == CheckStatus.completed).length;
    final totalChecks = _postTripChecks.length;
    final progress = totalChecks > 0 ? completedChecks / totalChecks : 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Card
          Card(
            color: AppColors.info.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fact_check,
                        color: AppColors.info,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text(
                        'Post-Trip Inspection',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completedChecks/$totalChecks',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? AppColors.success : AppColors.info,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  Text(
                    progress == 1.0 
                        ? 'All checks completed! Route officially ended.'
                        : 'Complete all required checks to end route.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: progress == 1.0 ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Checklist Items
          Text(
            'Post-Trip Checklist',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          ..._postTripChecks.map((check) => _buildCheckItem(check, false)).toList(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Action Buttons
          if (progress == 1.0) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitPostTripChecks,
                icon: const Icon(Icons.check_circle),
                label: const Text('Submit Post-Trip Inspection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckItem(SafetyCheckItem check, bool isPreTrip) {
    final isCompleted = check.status == CheckStatus.completed;
    final color = isCompleted ? AppColors.success : AppColors.textSecondary;
    
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
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? AppColors.success : AppColors.textSecondary,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              check.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (check.isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'REQUIRED',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        check.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Category and Photo requirement
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    check.category,
                    style: const TextStyle(
                      color: AppColors.info,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (check.requiresPhoto) ...[
                  const SizedBox(width: AppConstants.paddingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: AppColors.warning,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'PHOTO REQUIRED',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Action Buttons
            if (!isCompleted) ...[
              Row(
                children: [
                  if (check.requiresPhoto) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _takePhoto(check),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _completeCheck(check),
                      icon: const Icon(Icons.check),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Completed at ${_formatTime(DateTime.now())}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _undoCheck(check),
                    child: const Text('Undo'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Safety Check History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'View previous safety inspection records',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton.icon(
            onPressed: _viewHistory,
            icon: const Icon(Icons.list),
            label: const Text('View History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.driverColor,
            ),
          ),
        ],
      ),
    );
  }

  void _completeCheck(SafetyCheckItem check) {
    setState(() {
      check.status = CheckStatus.completed;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${check.title} completed'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _undoCheck(SafetyCheckItem check) {
    setState(() {
      check.status = CheckStatus.pending;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${check.title} marked as pending')),
    );
  }

  void _takePhoto(SafetyCheckItem check) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Taking photo for ${check.title}')),
    );
  }

  void _resetChecks() {
    setState(() {
      for (var check in _preTripChecks) {
        check.status = CheckStatus.pending;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pre-trip checks reset')),
    );
  }

  void _autoCompleteChecks() {
    setState(() {
      for (var check in _preTripChecks) {
        check.status = CheckStatus.completed;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All pre-trip checks completed'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _submitPreTripChecks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pre-trip inspection submitted successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _submitPostTripChecks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post-trip inspection submitted successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showChecklistSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checklist settings will be implemented')),
    );
  }

  void _viewHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Safety check history will be implemented')),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum CheckStatus { pending, completed, failed }

class SafetyCheckItem {
  final String id;
  final String category;
  final String title;
  final String description;
  final bool isRequired;
  CheckStatus status;
  final bool requiresPhoto;

  SafetyCheckItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.isRequired,
    required this.status,
    required this.requiresPhoto,
  });
}
