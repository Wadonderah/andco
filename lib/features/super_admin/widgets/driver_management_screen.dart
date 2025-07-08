import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DriverStatus _selectedStatus = DriverStatus.all;
  DriverVerificationStatus _selectedVerification = DriverVerificationStatus.all;

  final List<Driver> _drivers = [
    Driver(
      id: '1',
      name: 'Michael Johnson',
      email: 'michael.johnson@driver.com',
      phone: '+1 555-0201',
      licenseNumber: 'DL123456789',
      licenseExpiry: DateTime(2025, 12, 31),
      experience: 5,
      status: DriverStatus.active,
      verificationStatus: DriverVerificationStatus.verified,
      schoolId: '1',
      schoolName: 'Greenwood Elementary',
      assignedBusId: 'BUS001',
      assignedRoute: 'Route A - North District',
      joinDate: DateTime(2022, 3, 15),
      lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
      performanceRating: 4.8,
      totalTrips: 1250,
      safetyScore: 95,
      onTimePercentage: 98.5,
      documents: [
        'License',
        'Background Check',
        'Medical Certificate',
        'Training Certificate'
      ],
      emergencyContact: '+1 555-0299',
      address: '123 Driver Lane, Springfield',
      profilePicture: null,
    ),
    Driver(
      id: '2',
      name: 'Sarah Williams',
      email: 'sarah.williams@driver.com',
      phone: '+1 555-0202',
      licenseNumber: 'DL987654321',
      licenseExpiry: DateTime(2026, 6, 15),
      experience: 8,
      status: DriverStatus.active,
      verificationStatus: DriverVerificationStatus.verified,
      schoolId: '2',
      schoolName: 'Riverside High School',
      assignedBusId: 'BUS002',
      assignedRoute: 'Route B - South District',
      joinDate: DateTime(2021, 8, 20),
      lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
      performanceRating: 4.9,
      totalTrips: 2100,
      safetyScore: 98,
      onTimePercentage: 99.2,
      documents: [
        'License',
        'Background Check',
        'Medical Certificate',
        'Training Certificate',
        'Advanced Safety Course'
      ],
      emergencyContact: '+1 555-0298',
      address: '456 Oak Street, Riverside',
      profilePicture: null,
    ),
    Driver(
      id: '3',
      name: 'Robert Davis',
      email: 'robert.davis@driver.com',
      phone: '+1 555-0203',
      licenseNumber: 'DL456789123',
      licenseExpiry: DateTime(2024, 11, 30),
      experience: 3,
      status: DriverStatus.suspended,
      verificationStatus: DriverVerificationStatus.pending,
      schoolId: '1',
      schoolName: 'Greenwood Elementary',
      assignedBusId: null,
      assignedRoute: null,
      joinDate: DateTime(2023, 1, 10),
      lastActivity: DateTime.now().subtract(const Duration(days: 5)),
      performanceRating: 3.2,
      totalTrips: 450,
      safetyScore: 78,
      onTimePercentage: 85.3,
      documents: ['License', 'Background Check'],
      emergencyContact: '+1 555-0297',
      address: '789 Pine Avenue, Springfield',
      profilePicture: null,
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
                      'Driver Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showAddDriverDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.driverColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // Search and Filter Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search drivers by name, license, or school...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: DropdownButtonFormField<DriverStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status Filter',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        items: DriverStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: DropdownButtonFormField<DriverVerificationStatus>(
                        value: _selectedVerification,
                        decoration: InputDecoration(
                          labelText: 'Verification',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        items: DriverVerificationStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVerification = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Stats Row
                Row(
                  children: [
                    _buildStatCard('Total Drivers', _drivers.length.toString(),
                        AppColors.driverColor),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Active',
                        _getDriverCount(DriverStatus.active).toString(),
                        AppColors.success),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Verified',
                        _getVerificationCount(DriverVerificationStatus.verified)
                            .toString(),
                        AppColors.info),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Avg Rating',
                        _getAverageRating().toStringAsFixed(1),
                        AppColors.warning),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Safety Score',
                        '${_getAverageSafetyScore().toStringAsFixed(0)}%',
                        AppColors.purple),
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
              labelColor: AppColors.driverColor,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.driverColor,
              isScrollable: true,
              tabs: const [
                Tab(text: 'All Drivers'),
                Tab(text: 'Performance'),
                Tab(text: 'Verification'),
                Tab(text: 'Assignments'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDriversList(),
                _buildPerformanceTab(),
                _buildVerificationTab(),
                _buildAssignmentsTab(),
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

  Widget _buildDriversList() {
    final filteredDrivers = _getFilteredDrivers();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: filteredDrivers.length,
      itemBuilder: (context, index) {
        final driver = filteredDrivers[index];
        return _buildDriverCard(driver);
      },
    );
  }

  Widget _buildDriverCard(Driver driver) {
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
                  backgroundColor: _getStatusColor(driver.status),
                  child: Text(
                    driver.name[0],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'License: ${driver.licenseNumber}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${driver.schoolName} • ${driver.experience} years exp.',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(driver.status).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    driver.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(driver.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getVerificationColor(driver.verificationStatus)
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    driver.verificationStatus.displayName,
                    style: TextStyle(
                      color: _getVerificationColor(driver.verificationStatus),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Performance Metrics
            Row(
              children: [
                _buildMetric(
                    Icons.star, '${driver.performanceRating}', 'Rating'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildMetric(
                    Icons.security, '${driver.safetyScore}%', 'Safety'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildMetric(
                    Icons.schedule,
                    '${driver.onTimePercentage.toStringAsFixed(1)}%',
                    'On-Time'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildMetric(
                    Icons.directions_bus, '${driver.totalTrips}', 'Trips'),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Assignment Info
            if (driver.assignedBusId != null &&
                driver.assignedRoute != null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bus,
                        color: AppColors.info, size: 16),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Text(
                      'Assigned: ${driver.assignedBusId} - ${driver.assignedRoute}',
                      style:
                          const TextStyle(fontSize: 14, color: AppColors.info),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            // Action Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewDriverDetails(driver),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
                TextButton.icon(
                  onPressed: () => _editDriver(driver),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _manageAssignments(driver),
                  icon: const Icon(Icons.assignment),
                  label: const Text('Assignments'),
                ),
                const Spacer(),
                if (driver.status == DriverStatus.active)
                  TextButton.icon(
                    onPressed: () => _suspendDriver(driver),
                    icon: const Icon(Icons.block),
                    label: const Text('Suspend'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning),
                  )
                else if (driver.status == DriverStatus.suspended)
                  TextButton.icon(
                    onPressed: () => _activateDriver(driver),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Activate'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.success),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Performance Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Performance Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                    'Average Rating',
                    _getAverageRating().toStringAsFixed(1),
                    Icons.star,
                    AppColors.warning),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildPerformanceCard(
                    'Safety Score',
                    '${_getAverageSafetyScore().toStringAsFixed(0)}%',
                    Icons.security,
                    AppColors.success),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildPerformanceCard(
                    'On-Time Rate',
                    '${_getAverageOnTimeRate().toStringAsFixed(1)}%',
                    Icons.schedule,
                    AppColors.info),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildPerformanceCard(
                    'Total Trips',
                    _getTotalTrips().toString(),
                    Icons.directions_bus,
                    AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Individual Driver Performance
          Expanded(
            child: ListView.builder(
              itemCount: _drivers.length,
              itemBuilder: (context, index) {
                final driver = _drivers[index];
                return _buildPerformanceDriverCard(driver);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDriverCard(Driver driver) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getStatusColor(driver.status),
              child: Text(driver.name[0],
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    driver.schoolName,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _buildPerformanceMetric('Rating',
                driver.performanceRating.toString(), AppColors.warning),
            const SizedBox(width: AppConstants.paddingMedium),
            _buildPerformanceMetric(
                'Safety', '${driver.safetyScore}%', AppColors.success),
            const SizedBox(width: AppConstants.paddingMedium),
            _buildPerformanceMetric(
                'On-Time',
                '${driver.onTimePercentage.toStringAsFixed(1)}%',
                AppColors.info),
            const SizedBox(width: AppConstants.paddingMedium),
            _buildPerformanceMetric(
                'Trips', driver.totalTrips.toString(), AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
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
    );
  }

  Widget _buildVerificationTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Verification Status',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: ListView.builder(
              itemCount: _drivers.length,
              itemBuilder: (context, index) {
                final driver = _drivers[index];
                return _buildVerificationCard(driver);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(Driver driver) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getVerificationColor(driver.verificationStatus),
          child:
              Text(driver.name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(driver.name),
        subtitle: Text(
            '${driver.verificationStatus.displayName} • License expires: ${_formatDate(driver.licenseExpiry)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Documents:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: driver.documents.map((document) {
                    return Chip(
                      label: Text(document),
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Row(
                  children: [
                    if (driver.verificationStatus ==
                        DriverVerificationStatus.pending)
                      ElevatedButton.icon(
                        onPressed: () => _verifyDriver(driver),
                        icon: const Icon(Icons.verified),
                        label: const Text('Verify'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success),
                      ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    ElevatedButton.icon(
                      onPressed: () => _viewDocuments(driver),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('View Documents'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Assignments',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: ListView.builder(
              itemCount: _drivers.length,
              itemBuilder: (context, index) {
                final driver = _drivers[index];
                return _buildAssignmentCard(driver);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Driver driver) {
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
                  backgroundColor: _getStatusColor(driver.status),
                  child: Text(driver.name[0],
                      style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        driver.schoolName,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(driver.status).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    driver.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(driver.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            if (driver.assignedBusId != null &&
                driver.assignedRoute != null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus,
                            color: AppColors.success),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Text(
                          'Current Assignment',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text('Bus: ${driver.assignedBusId}'),
                    Text('Route: ${driver.assignedRoute}'),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.warning),
                    const SizedBox(width: AppConstants.paddingSmall),
                    const Text(
                      'No Current Assignment',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _assignBusRoute(driver),
                  icon: const Icon(Icons.assignment),
                  label: const Text('Assign Bus/Route'),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                if (driver.assignedBusId != null)
                  OutlinedButton.icon(
                    onPressed: () => _unassignDriver(driver),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Unassign'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  List<Driver> _getFilteredDrivers() {
    return _drivers.where((driver) {
      final matchesSearch = _searchQuery.isEmpty ||
          driver.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          driver.licenseNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          driver.schoolName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == DriverStatus.all ||
          driver.status == _selectedStatus;
      final matchesVerification =
          _selectedVerification == DriverVerificationStatus.all ||
              driver.verificationStatus == _selectedVerification;

      return matchesSearch && matchesStatus && matchesVerification;
    }).toList();
  }

  int _getDriverCount(DriverStatus status) {
    return _drivers.where((driver) => driver.status == status).length;
  }

  int _getVerificationCount(DriverVerificationStatus status) {
    return _drivers
        .where((driver) => driver.verificationStatus == status)
        .length;
  }

  double _getAverageRating() {
    if (_drivers.isEmpty) return 0.0;
    return _drivers.fold<double>(
            0, (sum, driver) => sum + driver.performanceRating) /
        _drivers.length;
  }

  double _getAverageSafetyScore() {
    if (_drivers.isEmpty) return 0.0;
    return _drivers.fold<double>(0, (sum, driver) => sum + driver.safetyScore) /
        _drivers.length;
  }

  double _getAverageOnTimeRate() {
    if (_drivers.isEmpty) return 0.0;
    return _drivers.fold<double>(
            0, (sum, driver) => sum + driver.onTimePercentage) /
        _drivers.length;
  }

  int _getTotalTrips() {
    return _drivers.fold<int>(0, (sum, driver) => sum + driver.totalTrips);
  }

  Color _getStatusColor(DriverStatus status) {
    switch (status) {
      case DriverStatus.active:
        return AppColors.success;
      case DriverStatus.suspended:
        return AppColors.warning;
      case DriverStatus.inactive:
        return AppColors.error;
      case DriverStatus.all:
        return AppColors.driverColor;
    }
  }

  Color _getVerificationColor(DriverVerificationStatus status) {
    switch (status) {
      case DriverVerificationStatus.verified:
        return AppColors.success;
      case DriverVerificationStatus.pending:
        return AppColors.warning;
      case DriverVerificationStatus.rejected:
        return AppColors.error;
      case DriverVerificationStatus.all:
        return AppColors.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action Methods
  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Driver'),
        content: const Text(
            'Add new driver functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _viewDriverDetails(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${driver.email}'),
            Text('Phone: ${driver.phone}'),
            Text('License: ${driver.licenseNumber}'),
            Text('Experience: ${driver.experience} years'),
            Text('School: ${driver.schoolName}'),
            Text('Status: ${driver.status.displayName}'),
            Text('Verification: ${driver.verificationStatus.displayName}'),
            Text('Rating: ${driver.performanceRating}'),
            Text('Safety Score: ${driver.safetyScore}%'),
            Text(
                'On-Time Rate: ${driver.onTimePercentage.toStringAsFixed(1)}%'),
            if (driver.assignedBusId != null)
              Text('Assigned Bus: ${driver.assignedBusId}'),
            if (driver.assignedRoute != null)
              Text('Assigned Route: ${driver.assignedRoute}'),
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

  void _editDriver(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${driver.name}'),
        content: const Text('Edit driver form would be implemented here.'),
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

  void _manageAssignments(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Assignments - ${driver.name}'),
        content: const Text(
            'Assignment management interface would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _suspendDriver(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Driver'),
        content: Text('Are you sure you want to suspend ${driver.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index = _drivers.indexWhere((d) => d.id == driver.id);
                if (index != -1) {
                  _drivers[index] =
                      driver.copyWith(status: DriverStatus.suspended);
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${driver.name} has been suspended')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _activateDriver(Driver driver) {
    setState(() {
      final index = _drivers.indexWhere((d) => d.id == driver.id);
      if (index != -1) {
        _drivers[index] = driver.copyWith(status: DriverStatus.active);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${driver.name} has been activated')),
    );
  }

  void _verifyDriver(Driver driver) {
    setState(() {
      final index = _drivers.indexWhere((d) => d.id == driver.id);
      if (index != -1) {
        _drivers[index] = driver.copyWith(
            verificationStatus: DriverVerificationStatus.verified);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${driver.name} has been verified')),
    );
  }

  void _viewDocuments(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Documents - ${driver.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submitted Documents:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppConstants.paddingSmall),
            ...driver.documents.map((doc) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Text(doc),
                    ],
                  ),
                )),
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

  void _assignBusRoute(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Bus/Route - ${driver.name}'),
        content: const Text(
            'Bus and route assignment interface would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _unassignDriver(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Driver'),
        content: Text(
            'Are you sure you want to unassign ${driver.name} from their current bus and route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index = _drivers.indexWhere((d) => d.id == driver.id);
                if (index != -1) {
                  _drivers[index] = driver.copyWith(
                    assignedBusId: null,
                    assignedRoute: null,
                  );
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${driver.name} has been unassigned')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Data Models
enum DriverStatus {
  all('All'),
  active('Active'),
  suspended('Suspended'),
  inactive('Inactive');

  const DriverStatus(this.displayName);
  final String displayName;
}

enum DriverVerificationStatus {
  all('All'),
  verified('Verified'),
  pending('Pending'),
  rejected('Rejected');

  const DriverVerificationStatus(this.displayName);
  final String displayName;
}

class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final int experience;
  final DriverStatus status;
  final DriverVerificationStatus verificationStatus;
  final String schoolId;
  final String schoolName;
  final String? assignedBusId;
  final String? assignedRoute;
  final DateTime joinDate;
  final DateTime lastActivity;
  final double performanceRating;
  final int totalTrips;
  final int safetyScore;
  final double onTimePercentage;
  final List<String> documents;
  final String emergencyContact;
  final String address;
  final String? profilePicture;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.experience,
    required this.status,
    required this.verificationStatus,
    required this.schoolId,
    required this.schoolName,
    this.assignedBusId,
    this.assignedRoute,
    required this.joinDate,
    required this.lastActivity,
    required this.performanceRating,
    required this.totalTrips,
    required this.safetyScore,
    required this.onTimePercentage,
    required this.documents,
    required this.emergencyContact,
    required this.address,
    this.profilePicture,
  });

  Driver copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? licenseNumber,
    DateTime? licenseExpiry,
    int? experience,
    DriverStatus? status,
    DriverVerificationStatus? verificationStatus,
    String? schoolId,
    String? schoolName,
    String? assignedBusId,
    String? assignedRoute,
    DateTime? joinDate,
    DateTime? lastActivity,
    double? performanceRating,
    int? totalTrips,
    int? safetyScore,
    double? onTimePercentage,
    List<String>? documents,
    String? emergencyContact,
    String? address,
    String? profilePicture,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      experience: experience ?? this.experience,
      status: status ?? this.status,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      assignedBusId: assignedBusId ?? this.assignedBusId,
      assignedRoute: assignedRoute ?? this.assignedRoute,
      joinDate: joinDate ?? this.joinDate,
      lastActivity: lastActivity ?? this.lastActivity,
      performanceRating: performanceRating ?? this.performanceRating,
      totalTrips: totalTrips ?? this.totalTrips,
      safetyScore: safetyScore ?? this.safetyScore,
      onTimePercentage: onTimePercentage ?? this.onTimePercentage,
      documents: documents ?? this.documents,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}
