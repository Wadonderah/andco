import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedDriverApprovalScreen extends ConsumerStatefulWidget {
  const EnhancedDriverApprovalScreen({super.key});

  @override
  ConsumerState<EnhancedDriverApprovalScreen> createState() =>
      _EnhancedDriverApprovalScreenState();
}

class _EnhancedDriverApprovalScreenState
    extends ConsumerState<EnhancedDriverApprovalScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Under Review',
    'Approved',
    'Rejected'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Driver & Vehicle Approval'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: 'Driver Approval'),
            Tab(icon: Icon(Icons.directions_bus), text: 'Vehicle Approval'),
            Tab(icon: Icon(Icons.analytics), text: 'Approval Analytics'),
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
        child: authState.when(
          data: (user) =>
              user != null ? _buildApprovalContent(user) : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildApprovalContent(user) {
    final schoolId = user.schoolId ?? '';

    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    return Column(
      children: [
        // Search and Filter Section
        _buildSearchAndFilters(),

        // Approval Statistics
        _buildApprovalStatistics(schoolId),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDriverApprovalTab(schoolId),
              _buildVehicleApprovalTab(schoolId),
              _buildAnalyticsTab(schoolId),
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
              hintText: 'Search drivers, vehicles, or applications...',
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
                _buildFilterChip('Status', _selectedStatus, _statusOptions,
                    (value) {
                  setState(() => _selectedStatus = value);
                }),
                const SizedBox(width: AppConstants.paddingSmall),
                ActionChip(
                  label: const Text('Clear Filters'),
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'All';
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

  Widget _buildApprovalStatistics(String schoolId) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.info.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
              child: _buildStatItem('Pending Approvals', '8', Icons.pending)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
              child: _buildStatItem('Under Review', '3', Icons.rate_review)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
              child: _buildStatItem('Approved Today', '5', Icons.check_circle)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
              child:
                  _buildStatItem('Avg Review Time', '2.5 days', Icons.timer)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.info, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.info,
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

  Widget _buildDriverApprovalTab(String schoolId) {
    final drivers = _getMockDriverApplications();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        return _buildDriverApplicationCard(drivers[index]);
      },
    );
  }

  Widget _buildVehicleApprovalTab(String schoolId) {
    final vehicles = _getMockVehicleApplications();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        return _buildVehicleApplicationCard(vehicles[index]);
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
            'Approval Analytics',
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
                  'Approval Rate',
                  '87%',
                  Icons.check_circle,
                  AppColors.success,
                  'Applications approved',
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildAnalyticsCard(
                  'Avg Review Time',
                  '2.5 days',
                  Icons.timer,
                  AppColors.info,
                  'Time to approval',
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
                  'Approval Trends',
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
                          'Approval trend charts coming soon',
                          style: TextStyle(color: AppColors.textSecondary),
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

  Widget _buildDriverApplicationCard(Map<String, dynamic> driver) {
    final statusColor = _getStatusColor(driver['status']);

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
                  radius: 25,
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  backgroundImage: driver['photoUrl'] != null
                      ? NetworkImage(driver['photoUrl'])
                      : null,
                  child: driver['photoUrl'] == null
                      ? Icon(Icons.person, color: statusColor, size: 30)
                      : null,
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'License: ${driver['license']} • Exp: ${driver['expiry']}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied: ${driver['appliedDate']}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    driver['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Action Buttons
            if (driver['status'] == 'Pending' ||
                driver['status'] == 'Under Review')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewDriverDetails(driver),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Review'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveDriver(driver),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectDriver(driver),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewDriverDetails(driver),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleApplicationCard(Map<String, dynamic> vehicle) {
    final statusColor = _getStatusColor(vehicle['status']);

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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.directions_bus, color: statusColor, size: 24),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['model'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'License: ${vehicle['licensePlate']} • Year: ${vehicle['year']}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capacity: ${vehicle['capacity']} • Applied: ${vehicle['appliedDate']}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicle['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Action Buttons
            if (vehicle['status'] == 'Pending' ||
                vehicle['status'] == 'Under Review')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewVehicleDetails(vehicle),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Review'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveVehicle(vehicle),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectVehicle(vehicle),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewVehicleDetails(vehicle),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Please log in to access driver and vehicle approval',
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.warning;
      case 'Under Review':
        return AppColors.info;
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

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
              leading: const Icon(Icons.check_circle),
              title: const Text('Bulk Approve'),
              onTap: () => _bulkApprove(),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Bulk Reject'),
              onTap: () => _bulkReject(),
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export Applications'),
              onTap: () => _exportApplications(),
            ),
          ],
        ),
      ),
    );
  }

  void _viewDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('License: ${driver['license']}'),
            Text('Expiry: ${driver['expiry']}'),
            Text('Phone: ${driver['phone']}'),
            Text('Experience: ${driver['experience']}'),
            Text('Applied: ${driver['appliedDate']}'),
            Text('Status: ${driver['status']}'),
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

  void _approveDriver(Map<String, dynamic> driver) async {
    final confirmed = await _showConfirmDialog(
      'Approve Driver',
      'Are you sure you want to approve ${driver['name']}?',
    );

    if (confirmed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${driver['name']} approved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _rejectDriver(Map<String, dynamic> driver) async {
    final confirmed = await _showConfirmDialog(
      'Reject Driver',
      'Are you sure you want to reject ${driver['name']}?',
    );

    if (confirmed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${driver['name']} rejected'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _viewVehicleDetails(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vehicle['model']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('License Plate: ${vehicle['licensePlate']}'),
            Text('Year: ${vehicle['year']}'),
            Text('Capacity: ${vehicle['capacity']}'),
            Text('Owner: ${vehicle['owner']}'),
            Text('Applied: ${vehicle['appliedDate']}'),
            Text('Status: ${vehicle['status']}'),
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

  void _approveVehicle(Map<String, dynamic> vehicle) async {
    final confirmed = await _showConfirmDialog(
      'Approve Vehicle',
      'Are you sure you want to approve ${vehicle['model']}?',
    );

    if (confirmed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${vehicle['model']} approved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _rejectVehicle(Map<String, dynamic> vehicle) async {
    final confirmed = await _showConfirmDialog(
      'Reject Vehicle',
      'Are you sure you want to reject ${vehicle['model']}?',
    );

    if (confirmed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${vehicle['model']} rejected'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _bulkApprove() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk approve functionality coming soon')),
    );
  }

  void _bulkReject() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk reject functionality coming soon')),
    );
  }

  void _exportApplications() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Export applications functionality coming soon')),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.schoolAdminColor),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Mock data methods
  List<Map<String, dynamic>> _getMockDriverApplications() {
    return [
      {
        'id': '1',
        'name': 'Michael Thompson',
        'license': 'CDL-98765',
        'expiry': '2025-12-15',
        'phone': '+1-555-0201',
        'experience': '5 years',
        'appliedDate': '2 days ago',
        'status': 'Pending',
        'photoUrl': null,
      },
      {
        'id': '2',
        'name': 'Sarah Williams',
        'license': 'CDL-54321',
        'expiry': '2026-03-20',
        'phone': '+1-555-0202',
        'experience': '8 years',
        'appliedDate': '1 week ago',
        'status': 'Under Review',
        'photoUrl': null,
      },
      {
        'id': '3',
        'name': 'David Brown',
        'license': 'CDL-11223',
        'expiry': '2025-09-10',
        'phone': '+1-555-0203',
        'experience': '3 years',
        'appliedDate': '3 days ago',
        'status': 'Approved',
        'photoUrl': null,
      },
    ];
  }

  List<Map<String, dynamic>> _getMockVehicleApplications() {
    return [
      {
        'id': '1',
        'model': 'Blue Bird Vision 2022',
        'licensePlate': 'SCH-101',
        'year': '2022',
        'capacity': '40 students',
        'owner': 'ABC Transport Co.',
        'appliedDate': '1 week ago',
        'status': 'Pending',
      },
      {
        'id': '2',
        'model': 'Thomas Built C2 2021',
        'licensePlate': 'SCH-102',
        'year': '2021',
        'capacity': '35 students',
        'owner': 'XYZ Bus Services',
        'appliedDate': '3 days ago',
        'status': 'Under Review',
      },
      {
        'id': '3',
        'model': 'IC Bus CE 2023',
        'licensePlate': 'SCH-103',
        'year': '2023',
        'capacity': '45 students',
        'owner': 'City School District',
        'appliedDate': '2 weeks ago',
        'status': 'Approved',
      },
    ];
  }
}
