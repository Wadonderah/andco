import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedSafetyChecksScreen extends ConsumerStatefulWidget {
  const EnhancedSafetyChecksScreen({super.key});

  @override
  ConsumerState<EnhancedSafetyChecksScreen> createState() =>
      _EnhancedSafetyChecksScreenState();
}

class _EnhancedSafetyChecksScreenState
    extends ConsumerState<EnhancedSafetyChecksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final Map<String, bool> _checkItems = {};
  final Map<String, String> _checkNotes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeCheckItems();
  }

  void _initializeCheckItems() {
    final items = _getDefaultSafetyItems();
    for (final item in items) {
      _checkItems[item['id']] = false;
      _checkNotes[item['id']] = '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Checks'),
        backgroundColor: AppColors.driverColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Today'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.info), text: 'Guidelines'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: authState.when(
          data: (user) =>
              user != null ? _buildSafetyChecks(user) : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildSafetyChecks(user) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTodaysChecks(),
        _buildCheckHistory(),
        _buildGuidelines(),
      ],
    );
  }

  Widget _buildTodaysChecks() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildTodaysHeader(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Safety Check Items
          _buildSafetyCheckItems(),

          const SizedBox(height: AppConstants.paddingLarge),

          // Complete Button
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildTodaysHeader() {
    final completedItems =
        _checkItems.values.where((checked) => checked).length;
    final totalItems = _checkItems.length;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.driverColor,
            AppColors.driverColor.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Pre-Trip Safety Check',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM dd, yyyy').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            '$completedItems of $totalItems items completed',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCheckItems() {
    final items = _getDefaultSafetyItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Check Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        ...items.map((item) => _buildCheckItem(item)),
      ],
    );
  }

  Widget _buildCheckItem(Map<String, dynamic> item) {
    final itemId = item['id'];
    final isChecked = _checkItems[itemId] ?? false;
    final isCritical = item['isCritical'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isChecked,
                  onChanged: (value) =>
                      _toggleCheckItem(itemId, value ?? false),
                  activeColor: AppColors.success,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration:
                                  isChecked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (isCritical) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'CRITICAL',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['description'],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showItemDetails(item),
                  icon: const Icon(Icons.info_outline),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.info.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            if (isChecked) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any observations or notes...',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
                onChanged: (value) => _checkNotes[itemId] = value,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    final completedItems =
        _checkItems.values.where((checked) => checked).length;
    final totalItems = _checkItems.length;
    final isComplete = completedItems == totalItems;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isComplete ? _completeSafetyCheck : null,
        icon: const Icon(Icons.check_circle),
        label: Text(
            isComplete ? 'Complete Safety Check' : 'Complete All Items First'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isComplete ? AppColors.success : AppColors.textSecondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCheckHistory() {
    // Mock history data
    final history = _getMockHistory();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: history.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(history[index]);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> check) {
    final status = check['status'];
    final statusColor = status == 'Passed'
        ? AppColors.success
        : status == 'Failed'
            ? AppColors.error
            : AppColors.warning;

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
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status == 'Passed'
                        ? Icons.check_circle
                        : status == 'Failed'
                            ? Icons.cancel
                            : Icons.warning,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        check['type'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy - HH:mm')
                            .format(check['date']),
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
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (check['notes']?.isNotEmpty == true) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: Text(
                  check['notes'],
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelines() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Check Guidelines',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildGuidelineSection(
            'Pre-Trip Inspection',
            'Perform this check before starting your route each day.',
            [
              'Check all lights and signals',
              'Inspect tires for proper pressure and wear',
              'Test brakes and steering',
              'Verify emergency equipment is present',
              'Ensure all mirrors are clean and properly adjusted',
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          _buildGuidelineSection(
            'Critical Items',
            'These items must pass for the vehicle to be safe for operation.',
            [
              'Brakes must function properly',
              'All lights must work',
              'Tires must have adequate tread and pressure',
              'Emergency exits must be clear and functional',
              'Fire extinguisher must be present and charged',
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          _buildGuidelineSection(
            'What to Do If Items Fail',
            'If any critical items fail inspection:',
            [
              'Do not operate the vehicle',
              'Report the issue immediately to your supervisor',
              'Document the problem with photos if possible',
              'Wait for maintenance approval before proceeding',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineSection(
      String title, String description, List<String> items) {
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
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: AppColors.driverColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
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
            'Please log in to access safety checks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  // Action methods
  void _toggleCheckItem(String itemId, bool checked) {
    setState(() {
      _checkItems[itemId] = checked;
    });
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['description']),
            if (item['isCritical']) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a critical safety item. The vehicle cannot be operated if this check fails.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  void _completeSafetyCheck() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Implement actual safety check completion
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safety check completed successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing safety check: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Mock data
  List<Map<String, dynamic>> _getDefaultSafetyItems() {
    return [
      {
        'id': 'tires',
        'name': 'Tires',
        'description': 'Check tire condition, pressure, and tread depth',
        'isCritical': true,
      },
      {
        'id': 'brakes',
        'name': 'Brakes',
        'description': 'Test brake functionality and responsiveness',
        'isCritical': true,
      },
      {
        'id': 'lights',
        'name': 'Lights & Signals',
        'description':
            'Check headlights, taillights, turn signals, and hazard lights',
        'isCritical': true,
      },
      {
        'id': 'mirrors',
        'name': 'Mirrors',
        'description': 'Adjust and clean all mirrors for optimal visibility',
        'isCritical': false,
      },
      {
        'id': 'seatbelts',
        'name': 'Seatbelts',
        'description': 'Check all seatbelts for proper function and wear',
        'isCritical': true,
      },
      {
        'id': 'emergency_exits',
        'name': 'Emergency Exits',
        'description': 'Ensure emergency exits are clear and functional',
        'isCritical': true,
      },
      {
        'id': 'first_aid',
        'name': 'First Aid Kit',
        'description': 'Verify first aid kit is present and properly stocked',
        'isCritical': false,
      },
      {
        'id': 'fire_extinguisher',
        'name': 'Fire Extinguisher',
        'description':
            'Check fire extinguisher is present and properly charged',
        'isCritical': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getMockHistory() {
    return [
      {
        'type': 'Pre-Trip Safety Check',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'status': 'Passed',
        'notes': 'All systems checked and operational',
      },
      {
        'type': 'Pre-Trip Safety Check',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'Failed',
        'notes': 'Left headlight bulb needs replacement',
      },
      {
        'type': 'Pre-Trip Safety Check',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'status': 'Passed',
        'notes': '',
      },
    ];
  }
}
