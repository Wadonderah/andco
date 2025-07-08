import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final BusFilter _currentFilter = BusFilter.all;

  final List<SchoolBus> _buses = [
    SchoolBus(
      id: '1',
      busNumber: 'Bus 101',
      plateNumber: 'ABC-123',
      capacity: 45,
      currentOccupancy: 38,
      driverName: 'John Smith',
      driverPhone: '+1 234 567 8900',
      route: 'Route A',
      status: BusStatus.active,
      lastMaintenance: DateTime(2024, 1, 15),
      nextMaintenance: DateTime(2024, 4, 15),
      fuelLevel: 85,
      gpsLocation: '40.7128, -74.0060',
      assignedStudents: 38,
      specialFeatures: ['Wheelchair Accessible', 'Air Conditioning'],
    ),
    SchoolBus(
      id: '2',
      busNumber: 'Bus 102',
      plateNumber: 'DEF-456',
      capacity: 40,
      currentOccupancy: 35,
      driverName: 'Maria Garcia',
      driverPhone: '+1 234 567 8901',
      route: 'Route B',
      status: BusStatus.active,
      lastMaintenance: DateTime(2024, 1, 20),
      nextMaintenance: DateTime(2024, 4, 20),
      fuelLevel: 72,
      gpsLocation: '40.7589, -73.9851',
      assignedStudents: 35,
      specialFeatures: ['Security Cameras', 'GPS Tracking'],
    ),
    SchoolBus(
      id: '3',
      busNumber: 'Bus 103',
      plateNumber: 'GHI-789',
      capacity: 50,
      currentOccupancy: 42,
      driverName: 'Robert Johnson',
      driverPhone: '+1 234 567 8902',
      route: 'Route C',
      status: BusStatus.maintenance,
      lastMaintenance: DateTime(2024, 2, 1),
      nextMaintenance: DateTime(2024, 5, 1),
      fuelLevel: 45,
      gpsLocation: '40.6892, -74.0445',
      assignedStudents: 42,
      specialFeatures: ['First Aid Kit', 'Emergency Radio'],
    ),
  ];

  final List<BusRoute> _routes = [
    BusRoute(
      id: '1',
      name: 'Route A',
      description: 'North District Route',
      totalStops: 12,
      estimatedTime: 45,
      assignedBus: 'Bus 101',
      status: RouteStatus.active,
      stops: [
        BusStop(
            id: '1',
            name: 'Maple Street',
            address: '123 Maple St',
            time: '7:45 AM',
            studentsCount: 8),
        BusStop(
            id: '2',
            name: 'Oak Avenue',
            address: '456 Oak Ave',
            time: '7:52 AM',
            studentsCount: 12),
        BusStop(
            id: '3',
            name: 'Pine Road',
            address: '789 Pine Rd',
            time: '8:00 AM',
            studentsCount: 10),
      ],
    ),
    BusRoute(
      id: '2',
      name: 'Route B',
      description: 'South District Route',
      totalStops: 10,
      estimatedTime: 40,
      assignedBus: 'Bus 102',
      status: RouteStatus.active,
      stops: [
        BusStop(
            id: '4',
            name: 'Cedar Lane',
            address: '321 Cedar Ln',
            time: '7:50 AM',
            studentsCount: 15),
        BusStop(
            id: '5',
            name: 'Elm Street',
            address: '654 Elm St',
            time: '7:58 AM',
            studentsCount: 20),
      ],
    ),
    BusRoute(
      id: '3',
      name: 'Route C',
      description: 'East District Route',
      totalStops: 15,
      estimatedTime: 55,
      assignedBus: 'Bus 103',
      status: RouteStatus.suspended,
      stops: [
        BusStop(
            id: '6',
            name: 'Birch Avenue',
            address: '987 Birch Ave',
            time: '8:00 AM',
            studentsCount: 25),
        BusStop(
            id: '7',
            name: 'Willow Drive',
            address: '147 Willow Dr',
            time: '8:10 AM',
            studentsCount: 17),
      ],
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
        title: const Text('Bus & Route Management'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Fleet Overview'),
            Tab(text: 'Routes'),
            Tab(text: 'Assignments'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _addNewBus,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _exportBusData,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFleetOverviewTab(),
          _buildRoutesTab(),
          _buildAssignmentsTab(),
        ],
      ),
    );
  }

  Widget _buildFleetOverviewTab() {
    final filteredBuses = _getFilteredBuses();

    return Column(
      children: [
        // Summary Cards
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.surfaceVariant,
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search buses by number, driver, or route...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Fleet Summary
              Row(
                children: [
                  Expanded(
                      child: _buildSummaryCard('Total Buses',
                          _buses.length.toString(), AppColors.info)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildSummaryCard(
                          'Active',
                          _getBusCount(BusStatus.active).toString(),
                          AppColors.success)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildSummaryCard(
                          'Maintenance',
                          _getBusCount(BusStatus.maintenance).toString(),
                          AppColors.warning)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildSummaryCard('Capacity',
                          '${_getTotalCapacity()}', AppColors.secondary)),
                ],
              ),
            ],
          ),
        ),

        // Bus List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium),
            itemCount: filteredBuses.length,
            itemBuilder: (context, index) {
              final bus = filteredBuses[index];
              return _buildBusCard(bus);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoutesTab() {
    return Column(
      children: [
        // Route Summary
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.surfaceVariant,
          child: Row(
            children: [
              Expanded(
                  child: _buildSummaryCard('Total Routes',
                      _routes.length.toString(), AppColors.info)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildSummaryCard(
                      'Active',
                      _getRouteCount(RouteStatus.active).toString(),
                      AppColors.success)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildSummaryCard(
                      'Suspended',
                      _getRouteCount(RouteStatus.suspended).toString(),
                      AppColors.error)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildSummaryCard('Total Stops',
                      _getTotalStops().toString(), AppColors.secondary)),
            ],
          ),
        ),

        // Routes List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium),
            itemCount: _routes.length,
            itemBuilder: (context, index) {
              final route = _routes[index];
              return _buildRouteCard(route);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Student-Bus Assignments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Manage student assignments to buses and routes',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(SchoolBus bus) {
    final statusColor = _getBusStatusColor(bus.status);
    final occupancyPercentage =
        (bus.currentOccupancy / bus.capacity * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                // Bus Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: statusColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: AppConstants.paddingMedium),

                // Bus Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bus.busNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSmall),
                            ),
                            child: Text(
                              bus.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plate: ${bus.plateNumber} • Route: ${bus.route}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Driver: ${bus.driverName}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleBusAction(value, bus),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'view', child: Text('View Details')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit Bus')),
                    const PopupMenuItem(
                        value: 'assign_route', child: Text('Assign Route')),
                    const PopupMenuItem(
                        value: 'maintenance',
                        child: Text('Schedule Maintenance')),
                    const PopupMenuItem(
                        value: 'track', child: Text('Track Location')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Capacity and Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildBusStatCard(
                    'Capacity',
                    '${bus.currentOccupancy}/${bus.capacity}',
                    '$occupancyPercentage%',
                    Icons.people,
                    occupancyPercentage > 90 ? AppColors.error : AppColors.info,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _buildBusStatCard(
                    'Fuel Level',
                    '${bus.fuelLevel}%',
                    bus.fuelLevel < 25 ? 'Low' : 'Good',
                    Icons.local_gas_station,
                    bus.fuelLevel < 25 ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),

            if (bus.specialFeatures.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Features: ${bus.specialFeatures.join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
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
      ),
    );
  }

  Widget _buildBusStatCard(
      String label, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BusRoute route) {
    final statusColor = _getRouteStatusColor(route.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    Icons.route,
                    color: statusColor,
                    size: 24,
                  ),
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
                              route.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSmall),
                            ),
                            child: Text(
                              route.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        route.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Bus: ${route.assignedBus} • ${route.totalStops} stops • ${route.estimatedTime} min',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleRouteAction(value, route),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'view', child: Text('View Stops')),
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit Route')),
                    const PopupMenuItem(
                        value: 'assign_bus', child: Text('Assign Bus')),
                    const PopupMenuItem(
                        value: 'optimize', child: Text('Optimize Route')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Route Stats
            Row(
              children: [
                Expanded(
                  child: _buildRouteStatCard(
                    'Total Stops',
                    route.totalStops.toString(),
                    Icons.location_on,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _buildRouteStatCard(
                    'Est. Time',
                    '${route.estimatedTime} min',
                    Icons.schedule,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _buildRouteStatCard(
                    'Students',
                    route.stops
                        .fold(0, (sum, stop) => sum + stop.studentsCount)
                        .toString(),
                    Icons.people,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<SchoolBus> _getFilteredBuses() {
    return _buses.where((bus) {
      final matchesSearch = _searchQuery.isEmpty ||
          bus.busNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bus.driverName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bus.route.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesSearch;
    }).toList();
  }

  int _getBusCount(BusStatus status) {
    return _buses.where((bus) => bus.status == status).length;
  }

  int _getRouteCount(RouteStatus status) {
    return _routes.where((route) => route.status == status).length;
  }

  int _getTotalCapacity() {
    return _buses.fold(0, (sum, bus) => sum + bus.capacity);
  }

  int _getTotalStops() {
    return _routes.fold(0, (sum, route) => sum + route.totalStops);
  }

  Color _getBusStatusColor(BusStatus status) {
    switch (status) {
      case BusStatus.active:
        return AppColors.success;
      case BusStatus.maintenance:
        return AppColors.warning;
      case BusStatus.inactive:
        return AppColors.error;
    }
  }

  Color _getRouteStatusColor(RouteStatus status) {
    switch (status) {
      case RouteStatus.active:
        return AppColors.success;
      case RouteStatus.suspended:
        return AppColors.error;
      case RouteStatus.planning:
        return AppColors.warning;
    }
  }

  void _handleBusAction(String action, SchoolBus bus) {
    switch (action) {
      case 'view':
        _viewBusDetails(bus);
        break;
      case 'edit':
        _editBus(bus);
        break;
      case 'assign_route':
        _assignRoute(bus);
        break;
      case 'maintenance':
        _scheduleMaintenance(bus);
        break;
      case 'track':
        _trackBus(bus);
        break;
    }
  }

  void _handleRouteAction(String action, BusRoute route) {
    switch (action) {
      case 'view':
        _viewRouteStops(route);
        break;
      case 'edit':
        _editRoute(route);
        break;
      case 'assign_bus':
        _assignBusToRoute(route);
        break;
      case 'optimize':
        _optimizeRoute(route);
        break;
    }
  }

  void _viewBusDetails(SchoolBus bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${bus.busNumber} - Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Bus Number', bus.busNumber),
              _buildDetailRow('Plate Number', bus.plateNumber),
              _buildDetailRow('Capacity', '${bus.capacity} students'),
              _buildDetailRow(
                  'Current Occupancy', '${bus.currentOccupancy} students'),
              _buildDetailRow('Driver', bus.driverName),
              _buildDetailRow('Driver Phone', bus.driverPhone),
              _buildDetailRow('Route', bus.route),
              _buildDetailRow('Status', bus.status.name),
              _buildDetailRow('Fuel Level', '${bus.fuelLevel}%'),
              _buildDetailRow('GPS Location', bus.gpsLocation),
              if (bus.specialFeatures.isNotEmpty)
                _buildDetailRow(
                    'Special Features', bus.specialFeatures.join(', ')),
            ],
          ),
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

  void _viewRouteStops(BusRoute route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${route.name} - Stops'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: route.stops.length,
            itemBuilder: (context, index) {
              final stop = route.stops[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.info,
                  child: Text('${index + 1}'),
                ),
                title: Text(stop.name),
                subtitle: Text('${stop.address} • ${stop.time}'),
                trailing: Text('${stop.studentsCount} students'),
              );
            },
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editBus(SchoolBus bus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${bus.busNumber}')),
    );
  }

  void _assignRoute(SchoolBus bus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assign route to ${bus.busNumber}')),
    );
  }

  void _scheduleMaintenance(SchoolBus bus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule maintenance for ${bus.busNumber}')),
    );
  }

  void _trackBus(SchoolBus bus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tracking ${bus.busNumber}...')),
    );
  }

  void _editRoute(BusRoute route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${route.name}')),
    );
  }

  void _assignBusToRoute(BusRoute route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assign bus to ${route.name}')),
    );
  }

  void _optimizeRoute(BusRoute route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Optimizing ${route.name}...')),
    );
  }

  void _addNewBus() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Add new bus functionality will be implemented')),
    );
  }

  void _showFilterOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options will be implemented')),
    );
  }

  void _exportBusData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting bus data...')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum BusStatus { active, maintenance, inactive }

enum RouteStatus { active, suspended, planning }

enum BusFilter { all, active, maintenance, inactive }

class SchoolBus {
  final String id;
  final String busNumber;
  final String plateNumber;
  final int capacity;
  final int currentOccupancy;
  final String driverName;
  final String driverPhone;
  final String route;
  final BusStatus status;
  final DateTime lastMaintenance;
  final DateTime nextMaintenance;
  final int fuelLevel;
  final String gpsLocation;
  final int assignedStudents;
  final List<String> specialFeatures;

  SchoolBus({
    required this.id,
    required this.busNumber,
    required this.plateNumber,
    required this.capacity,
    required this.currentOccupancy,
    required this.driverName,
    required this.driverPhone,
    required this.route,
    required this.status,
    required this.lastMaintenance,
    required this.nextMaintenance,
    required this.fuelLevel,
    required this.gpsLocation,
    required this.assignedStudents,
    required this.specialFeatures,
  });
}

class BusRoute {
  final String id;
  final String name;
  final String description;
  final int totalStops;
  final int estimatedTime;
  final String assignedBus;
  final RouteStatus status;
  final List<BusStop> stops;

  BusRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.totalStops,
    required this.estimatedTime,
    required this.assignedBus,
    required this.status,
    required this.stops,
  });
}

class BusStop {
  final String id;
  final String name;
  final String address;
  final String time;
  final int studentsCount;

  BusStop({
    required this.id,
    required this.name,
    required this.address,
    required this.time,
    required this.studentsCount,
  });
}
