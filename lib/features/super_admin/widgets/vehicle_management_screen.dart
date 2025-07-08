import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  VehicleStatus _selectedStatus = VehicleStatus.all;
  MaintenanceStatus _selectedMaintenance = MaintenanceStatus.all;

  final List<Vehicle> _vehicles = [
    Vehicle(
      id: '1',
      busNumber: 'BUS001',
      make: 'Blue Bird',
      model: 'Vision',
      year: 2022,
      plateNumber: 'SCH-001',
      capacity: 45,
      status: VehicleStatus.active,
      maintenanceStatus: MaintenanceStatus.upToDate,
      schoolId: '1',
      schoolName: 'Greenwood Elementary',
      assignedDriverId: '1',
      assignedDriverName: 'Michael Johnson',
      assignedRoute: 'Route A - North District',
      purchaseDate: DateTime(2022, 1, 15),
      lastMaintenance: DateTime.now().subtract(const Duration(days: 30)),
      nextMaintenance: DateTime.now().add(const Duration(days: 60)),
      mileage: 45000,
      fuelType: 'Diesel',
      insuranceExpiry: DateTime(2025, 8, 30),
      inspectionExpiry: DateTime(2024, 12, 15),
      gpsEnabled: true,
      safetyFeatures: [
        'Emergency Exit',
        'First Aid Kit',
        'Fire Extinguisher',
        'GPS Tracking'
      ],
      maintenanceHistory: [
        MaintenanceRecord(
          id: '1',
          date: DateTime.now().subtract(const Duration(days: 30)),
          type: 'Regular Service',
          description: 'Oil change, brake inspection, tire rotation',
          cost: 450.00,
          mechanic: 'Auto Service Center',
        ),
      ],
    ),
    Vehicle(
      id: '2',
      busNumber: 'BUS002',
      make: 'Thomas Built',
      model: 'Saf-T-Liner',
      year: 2021,
      plateNumber: 'SCH-002',
      capacity: 40,
      status: VehicleStatus.active,
      maintenanceStatus: MaintenanceStatus.upToDate,
      schoolId: '2',
      schoolName: 'Riverside High School',
      assignedDriverId: '2',
      assignedDriverName: 'Sarah Williams',
      assignedRoute: 'Route B - South District',
      purchaseDate: DateTime(2021, 6, 20),
      lastMaintenance: DateTime.now().subtract(const Duration(days: 15)),
      nextMaintenance: DateTime.now().add(const Duration(days: 75)),
      mileage: 62000,
      fuelType: 'Diesel',
      insuranceExpiry: DateTime(2025, 10, 20),
      inspectionExpiry: DateTime(2024, 11, 30),
      gpsEnabled: true,
      safetyFeatures: [
        'Emergency Exit',
        'First Aid Kit',
        'Fire Extinguisher',
        'GPS Tracking',
        'Security Cameras'
      ],
      maintenanceHistory: [
        MaintenanceRecord(
          id: '2',
          date: DateTime.now().subtract(const Duration(days: 15)),
          type: 'Brake Service',
          description: 'Brake pad replacement, brake fluid change',
          cost: 320.00,
          mechanic: 'City Auto Repair',
        ),
      ],
    ),
    Vehicle(
      id: '3',
      busNumber: 'BUS003',
      make: 'IC Bus',
      model: 'CE Series',
      year: 2020,
      plateNumber: 'SCH-003',
      capacity: 35,
      status: VehicleStatus.maintenance,
      maintenanceStatus: MaintenanceStatus.overdue,
      schoolId: '1',
      schoolName: 'Greenwood Elementary',
      assignedDriverId: null,
      assignedDriverName: null,
      assignedRoute: null,
      purchaseDate: DateTime(2020, 3, 10),
      lastMaintenance: DateTime.now().subtract(const Duration(days: 120)),
      nextMaintenance: DateTime.now().subtract(const Duration(days: 30)),
      mileage: 78000,
      fuelType: 'Diesel',
      insuranceExpiry: DateTime(2024, 12, 31),
      inspectionExpiry: DateTime(2024, 9, 15),
      gpsEnabled: false,
      safetyFeatures: ['Emergency Exit', 'First Aid Kit'],
      maintenanceHistory: [
        MaintenanceRecord(
          id: '3',
          date: DateTime.now().subtract(const Duration(days: 120)),
          type: 'Engine Service',
          description: 'Engine oil change, air filter replacement',
          cost: 280.00,
          mechanic: 'Fleet Maintenance Co.',
        ),
      ],
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
                      'Vehicle Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showAddVehicleDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Vehicle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
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
                              'Search vehicles by bus number, plate, or school...',
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
                      child: DropdownButtonFormField<VehicleStatus>(
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
                        items: VehicleStatus.values.map((status) {
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
                      child: DropdownButtonFormField<MaintenanceStatus>(
                        value: _selectedMaintenance,
                        decoration: InputDecoration(
                          labelText: 'Maintenance',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        items: MaintenanceStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMaintenance = value!;
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
                    _buildStatCard('Total Vehicles',
                        _vehicles.length.toString(), AppColors.warning),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Active',
                        _getVehicleCount(VehicleStatus.active).toString(),
                        AppColors.success),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Maintenance',
                        _getVehicleCount(VehicleStatus.maintenance).toString(),
                        AppColors.orange),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard('Total Capacity',
                        _getTotalCapacity().toString(), AppColors.info),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Avg Mileage',
                        '${_getAverageMileage().toStringAsFixed(0)}K',
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
              labelColor: AppColors.warning,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.warning,
              isScrollable: true,
              tabs: const [
                Tab(text: 'All Vehicles'),
                Tab(text: 'Maintenance'),
                Tab(text: 'Assignments'),
                Tab(text: 'Compliance'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVehiclesList(),
                _buildMaintenanceTab(),
                _buildAssignmentsTab(),
                _buildComplianceTab(),
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

  Widget _buildVehiclesList() {
    final filteredVehicles = _getFilteredVehicles();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = filteredVehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
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
                    color:
                        _getStatusColor(vehicle.status).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: _getStatusColor(vehicle.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.busNumber} - ${vehicle.year} ${vehicle.make} ${vehicle.model}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Plate: ${vehicle.plateNumber} • Capacity: ${vehicle.capacity}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${vehicle.schoolName} • ${vehicle.mileage.toStringAsFixed(0)} miles',
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
                        _getStatusColor(vehicle.status).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    vehicle.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(vehicle.status),
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
                    color: _getMaintenanceColor(vehicle.maintenanceStatus)
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    vehicle.maintenanceStatus.displayName,
                    style: TextStyle(
                      color: _getMaintenanceColor(vehicle.maintenanceStatus),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Vehicle Details
            Row(
              children: [
                _buildVehicleDetail(Icons.local_gas_station, vehicle.fuelType),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildVehicleDetail(Icons.build,
                    'Next: ${_formatDate(vehicle.nextMaintenance)}'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildVehicleDetail(Icons.security,
                    'Insurance: ${_formatDate(vehicle.insuranceExpiry)}'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildVehicleDetail(Icons.gps_fixed,
                    vehicle.gpsEnabled ? 'GPS Enabled' : 'GPS Disabled'),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Assignment Info
            if (vehicle.assignedDriverName != null &&
                vehicle.assignedRoute != null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Text(
                      'Driver: ${vehicle.assignedDriverName} • Route: ${vehicle.assignedRoute}',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.success),
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
                  onPressed: () => _viewVehicleDetails(vehicle),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
                TextButton.icon(
                  onPressed: () => _editVehicle(vehicle),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _scheduleMaintenance(vehicle),
                  icon: const Icon(Icons.build),
                  label: const Text('Maintenance'),
                ),
                const Spacer(),
                if (vehicle.status == VehicleStatus.active)
                  TextButton.icon(
                    onPressed: () => _takeOffline(vehicle),
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('Take Offline'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning),
                  )
                else if (vehicle.status == VehicleStatus.offline)
                  TextButton.icon(
                    onPressed: () => _bringOnline(vehicle),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Bring Online'),
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

  Widget _buildVehicleDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMaintenanceTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Maintenance Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return _buildMaintenanceCard(vehicle);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(Vehicle vehicle) {
    final isOverdue = vehicle.nextMaintenance.isBefore(DateTime.now());
    final daysDiff = vehicle.nextMaintenance.difference(DateTime.now()).inDays;

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
                    color: _getMaintenanceColor(vehicle.maintenanceStatus)
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    Icons.build,
                    color: _getMaintenanceColor(vehicle.maintenanceStatus),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.busNumber,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMaintenanceColor(vehicle.maintenanceStatus)
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    vehicle.maintenanceStatus.displayName,
                    style: TextStyle(
                      color: _getMaintenanceColor(vehicle.maintenanceStatus),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last Maintenance:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(_formatDate(vehicle.lastMaintenance)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Next Maintenance:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        _formatDate(vehicle.nextMaintenance),
                        style: TextStyle(
                          color: isOverdue
                              ? AppColors.error
                              : daysDiff < 30
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mileage:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${vehicle.mileage.toStringAsFixed(0)} miles'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _scheduleMaintenance(vehicle),
                  icon: const Icon(Icons.schedule),
                  label: const Text('Schedule'),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                ElevatedButton.icon(
                  onPressed: () => _viewMaintenanceHistory(vehicle),
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColors.info),
                ),
              ],
            ),
          ],
        ),
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
            'Vehicle Assignments',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return _buildAssignmentCard(vehicle);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Vehicle vehicle) {
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
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: const Icon(Icons.directions_bus,
                      color: AppColors.warning),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.busNumber,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        vehicle.schoolName,
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
                        _getStatusColor(vehicle.status).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    vehicle.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(vehicle.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            if (vehicle.assignedDriverName != null &&
                vehicle.assignedRoute != null) ...[
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
                        const Icon(Icons.assignment, color: AppColors.success),
                        const SizedBox(width: AppConstants.paddingSmall),
                        const Text(
                          'Current Assignment',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text('Driver: ${vehicle.assignedDriverName}'),
                    Text('Route: ${vehicle.assignedRoute}'),
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
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.warning),
                    SizedBox(width: AppConstants.paddingSmall),
                    Text(
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
                  onPressed: () => _assignDriverRoute(vehicle),
                  icon: const Icon(Icons.assignment),
                  label: const Text('Assign Driver/Route'),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                if (vehicle.assignedDriverName != null)
                  OutlinedButton.icon(
                    onPressed: () => _unassignVehicle(vehicle),
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

  Widget _buildComplianceTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Compliance Status',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return _buildComplianceCard(vehicle);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCard(Vehicle vehicle) {
    final insuranceExpired = vehicle.insuranceExpiry.isBefore(DateTime.now());
    final inspectionExpired = vehicle.inspectionExpiry.isBefore(DateTime.now());
    final insuranceDays =
        vehicle.insuranceExpiry.difference(DateTime.now()).inDays;
    final inspectionDays =
        vehicle.inspectionExpiry.difference(DateTime.now()).inDays;

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
                    color: (insuranceExpired || inspectionExpired)
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    Icons.verified_user,
                    color: (insuranceExpired || inspectionExpired)
                        ? AppColors.error
                        : AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.busNumber,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (insuranceExpired || inspectionExpired)
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    (insuranceExpired || inspectionExpired)
                        ? 'Non-Compliant'
                        : 'Compliant',
                    style: TextStyle(
                      color: (insuranceExpired || inspectionExpired)
                          ? AppColors.error
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Insurance Expiry:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        _formatDate(vehicle.insuranceExpiry),
                        style: TextStyle(
                          color: insuranceExpired
                              ? AppColors.error
                              : insuranceDays < 30
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                      ),
                      if (!insuranceExpired && insuranceDays < 30)
                        Text(
                          'Expires in $insuranceDays days',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.warning),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Inspection Expiry:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        _formatDate(vehicle.inspectionExpiry),
                        style: TextStyle(
                          color: inspectionExpired
                              ? AppColors.error
                              : inspectionDays < 30
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                      ),
                      if (!inspectionExpired && inspectionDays < 30)
                        Text(
                          'Expires in $inspectionDays days',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.warning),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Safety Features:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${vehicle.safetyFeatures.length} features'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _renewInsurance(vehicle),
                  icon: const Icon(Icons.security),
                  label: const Text('Renew Insurance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        insuranceExpired ? AppColors.error : AppColors.info,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                ElevatedButton.icon(
                  onPressed: () => _scheduleInspection(vehicle),
                  icon: const Icon(Icons.verified),
                  label: const Text('Schedule Inspection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        inspectionExpired ? AppColors.error : AppColors.warning,
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
  List<Vehicle> _getFilteredVehicles() {
    return _vehicles.where((vehicle) {
      final matchesSearch = _searchQuery.isEmpty ||
          vehicle.busNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          vehicle.plateNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          vehicle.schoolName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == VehicleStatus.all ||
          vehicle.status == _selectedStatus;
      final matchesMaintenance =
          _selectedMaintenance == MaintenanceStatus.all ||
              vehicle.maintenanceStatus == _selectedMaintenance;

      return matchesSearch && matchesStatus && matchesMaintenance;
    }).toList();
  }

  int _getVehicleCount(VehicleStatus status) {
    return _vehicles.where((vehicle) => vehicle.status == status).length;
  }

  int _getTotalCapacity() {
    return _vehicles.fold<int>(0, (sum, vehicle) => sum + vehicle.capacity);
  }

  double _getAverageMileage() {
    if (_vehicles.isEmpty) return 0.0;
    return _vehicles.fold<double>(0, (sum, vehicle) => sum + vehicle.mileage) /
        _vehicles.length /
        1000;
  }

  Color _getStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return AppColors.success;
      case VehicleStatus.maintenance:
        return AppColors.orange;
      case VehicleStatus.offline:
        return AppColors.warning;
      case VehicleStatus.retired:
        return AppColors.error;
      case VehicleStatus.all:
        return AppColors.warning;
    }
  }

  Color _getMaintenanceColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.upToDate:
        return AppColors.success;
      case MaintenanceStatus.due:
        return AppColors.warning;
      case MaintenanceStatus.overdue:
        return AppColors.error;
      case MaintenanceStatus.all:
        return AppColors.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action Methods
  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: const Text(
            'Add new vehicle functionality would be implemented here.'),
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

  void _viewVehicleDetails(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vehicle.busNumber),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Make/Model: ${vehicle.year} ${vehicle.make} ${vehicle.model}'),
            Text('Plate Number: ${vehicle.plateNumber}'),
            Text('Capacity: ${vehicle.capacity} passengers'),
            Text('School: ${vehicle.schoolName}'),
            Text('Status: ${vehicle.status.displayName}'),
            Text('Mileage: ${vehicle.mileage.toStringAsFixed(0)} miles'),
            Text('Fuel Type: ${vehicle.fuelType}'),
            Text('GPS: ${vehicle.gpsEnabled ? 'Enabled' : 'Disabled'}'),
            if (vehicle.assignedDriverName != null)
              Text('Driver: ${vehicle.assignedDriverName}'),
            if (vehicle.assignedRoute != null)
              Text('Route: ${vehicle.assignedRoute}'),
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

  void _editVehicle(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${vehicle.busNumber}'),
        content: const Text('Edit vehicle form would be implemented here.'),
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

  void _scheduleMaintenance(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule Maintenance - ${vehicle.busNumber}'),
        content: const Text(
            'Maintenance scheduling interface would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _viewMaintenanceHistory(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Maintenance History - ${vehicle.busNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Maintenance:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppConstants.paddingSmall),
            ...vehicle.maintenanceHistory.map((record) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_formatDate(record.date)} - ${record.type}'),
                      Text(record.description,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text('Cost: \$${record.cost.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12)),
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

  void _assignDriverRoute(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Driver/Route - ${vehicle.busNumber}'),
        content: const Text(
            'Driver and route assignment interface would be implemented here.'),
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

  void _unassignVehicle(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Vehicle'),
        content: Text(
            'Are you sure you want to unassign ${vehicle.busNumber} from its current driver and route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
                if (index != -1) {
                  _vehicles[index] = vehicle.copyWith(
                    assignedDriverId: null,
                    assignedDriverName: null,
                    assignedRoute: null,
                  );
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${vehicle.busNumber} has been unassigned')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
  }

  void _takeOffline(Vehicle vehicle) {
    setState(() {
      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = vehicle.copyWith(status: VehicleStatus.offline);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${vehicle.busNumber} has been taken offline')),
    );
  }

  void _bringOnline(Vehicle vehicle) {
    setState(() {
      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = vehicle.copyWith(status: VehicleStatus.active);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${vehicle.busNumber} has been brought online')),
    );
  }

  void _renewInsurance(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Renew Insurance - ${vehicle.busNumber}'),
        content: const Text(
            'Insurance renewal interface would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Renew'),
          ),
        ],
      ),
    );
  }

  void _scheduleInspection(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule Inspection - ${vehicle.busNumber}'),
        content: const Text(
            'Inspection scheduling interface would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schedule'),
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
enum VehicleStatus {
  all('All'),
  active('Active'),
  maintenance('Maintenance'),
  offline('Offline'),
  retired('Retired');

  const VehicleStatus(this.displayName);
  final String displayName;
}

enum MaintenanceStatus {
  all('All'),
  upToDate('Up to Date'),
  due('Due'),
  overdue('Overdue');

  const MaintenanceStatus(this.displayName);
  final String displayName;
}

class Vehicle {
  final String id;
  final String busNumber;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final int capacity;
  final VehicleStatus status;
  final MaintenanceStatus maintenanceStatus;
  final String schoolId;
  final String schoolName;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedRoute;
  final DateTime purchaseDate;
  final DateTime lastMaintenance;
  final DateTime nextMaintenance;
  final double mileage;
  final String fuelType;
  final DateTime insuranceExpiry;
  final DateTime inspectionExpiry;
  final bool gpsEnabled;
  final List<String> safetyFeatures;
  final List<MaintenanceRecord> maintenanceHistory;

  Vehicle({
    required this.id,
    required this.busNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.capacity,
    required this.status,
    required this.maintenanceStatus,
    required this.schoolId,
    required this.schoolName,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedRoute,
    required this.purchaseDate,
    required this.lastMaintenance,
    required this.nextMaintenance,
    required this.mileage,
    required this.fuelType,
    required this.insuranceExpiry,
    required this.inspectionExpiry,
    required this.gpsEnabled,
    required this.safetyFeatures,
    required this.maintenanceHistory,
  });

  Vehicle copyWith({
    String? id,
    String? busNumber,
    String? make,
    String? model,
    int? year,
    String? plateNumber,
    int? capacity,
    VehicleStatus? status,
    MaintenanceStatus? maintenanceStatus,
    String? schoolId,
    String? schoolName,
    String? assignedDriverId,
    String? assignedDriverName,
    String? assignedRoute,
    DateTime? purchaseDate,
    DateTime? lastMaintenance,
    DateTime? nextMaintenance,
    double? mileage,
    String? fuelType,
    DateTime? insuranceExpiry,
    DateTime? inspectionExpiry,
    bool? gpsEnabled,
    List<String>? safetyFeatures,
    List<MaintenanceRecord>? maintenanceHistory,
  }) {
    return Vehicle(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      maintenanceStatus: maintenanceStatus ?? this.maintenanceStatus,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedRoute: assignedRoute ?? this.assignedRoute,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      nextMaintenance: nextMaintenance ?? this.nextMaintenance,
      mileage: mileage ?? this.mileage,
      fuelType: fuelType ?? this.fuelType,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      inspectionExpiry: inspectionExpiry ?? this.inspectionExpiry,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      safetyFeatures: safetyFeatures ?? this.safetyFeatures,
      maintenanceHistory: maintenanceHistory ?? this.maintenanceHistory,
    );
  }
}

class MaintenanceRecord {
  final String id;
  final DateTime date;
  final String type;
  final String description;
  final double cost;
  final String mechanic;

  MaintenanceRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    required this.cost,
    required this.mechanic,
  });
}
