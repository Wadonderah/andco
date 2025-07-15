import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedBusRouteManagementScreen extends ConsumerStatefulWidget {
  const EnhancedBusRouteManagementScreen({super.key});

  @override
  ConsumerState<EnhancedBusRouteManagementScreen> createState() =>
      _EnhancedBusRouteManagementScreenState();
}

class _EnhancedBusRouteManagementScreenState
    extends ConsumerState<EnhancedBusRouteManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final List<String> _statusOptions = [
    'All',
    'Active',
    'Inactive',
    'Maintenance'
  ];

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
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus & Route Management'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.route), text: 'Routes'),
            Tab(icon: Icon(Icons.directions_bus), text: 'Buses'),
            Tab(icon: Icon(Icons.person_pin), text: 'Drivers'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
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
          data: (user) => user != null
              ? _buildManagementContent(user)
              : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.schoolAdminColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildManagementContent(user) {
    final schoolId = user.schoolId ?? '';

    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildRoutesTab(schoolId),
        _buildBusesTab(schoolId),
        _buildDriversTab(schoolId),
        _buildAnalyticsTab(schoolId),
      ],
    );
  }

  Widget _buildRoutesTab(String schoolId) {
    return Column(
      children: [
        // Search and Filter Section
        _buildSearchAndFilters(),

        // Route Statistics
        _buildRouteStatistics(schoolId),

        // Routes List
        Expanded(
          child: _buildRoutesList(schoolId),
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
              hintText: 'Search routes, buses, or drivers...',
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

  Widget _buildRouteStatistics(String schoolId) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.schoolAdminColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('Total Routes', '8', Icons.route)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
              child: _buildStatItem('Active Buses', '6', Icons.directions_bus)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
              child: _buildStatItem('Available Drivers', '12', Icons.person)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Capacity', '320', Icons.groups)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.schoolAdminColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.schoolAdminColor,
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

  Widget _buildRoutesList(String schoolId) {
    final routes = _getMockRoutes();
    final filteredRoutes = _filterRoutes(routes);

    if (filteredRoutes.isEmpty) {
      return _buildEmptyState(
          'No routes found', 'Try adjusting your search or filters');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: filteredRoutes.length,
      itemBuilder: (context, index) {
        return _buildRouteCard(filteredRoutes[index]);
      },
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final isActive = route['status'] == 'Active';

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
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.route,
                    color: isActive ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route['stops']} stops • ${route['students']} students',
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
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    route['status'],
                    style: TextStyle(
                      color: isActive ? AppColors.success : AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleRouteAction(value, route),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'view', child: Text('View Details')),
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit Route')),
                    const PopupMenuItem(
                        value: 'assign', child: Text('Assign Driver')),
                    const PopupMenuItem(
                        value: 'optimize', child: Text('Optimize Route')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Delete Route')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Route Details
            Row(
              children: [
                Expanded(
                  child: _buildRouteDetail(
                      'Driver', route['driver'] ?? 'Unassigned', Icons.person),
                ),
                Expanded(
                  child: _buildRouteDetail('Bus', route['bus'] ?? 'Unassigned',
                      Icons.directions_bus),
                ),
                Expanded(
                  child: _buildRouteDetail(
                      'Duration', route['duration'], Icons.timer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusesTab(String schoolId) {
    return Column(
      children: [
        _buildSearchAndFilters(),
        _buildBusStatistics(schoolId),
        Expanded(child: _buildBusesList(schoolId)),
      ],
    );
  }

  Widget _buildBusStatistics(String schoolId) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.info.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
              child: _buildStatItem('Total Buses', '8', Icons.directions_bus)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Active', '6', Icons.check_circle)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Maintenance', '2', Icons.build)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
              child: _buildStatItem(
                  'Capacity', '320', Icons.airline_seat_recline_normal)),
        ],
      ),
    );
  }

  Widget _buildBusesList(String schoolId) {
    final buses = _getMockBuses();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: buses.length,
      itemBuilder: (context, index) {
        return _buildBusCard(buses[index]);
      },
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus) {
    final statusColor = bus['status'] == 'Active'
        ? AppColors.success
        : bus['status'] == 'Maintenance'
            ? AppColors.warning
            : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_bus, color: statusColor, size: 24),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus['number'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bus['model']} • Capacity: ${bus['capacity']}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        bus['driver'] ?? 'Unassigned',
                        style: TextStyle(
                          color: bus['driver'] != null
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bus['status'],
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            PopupMenuButton<String>(
              onSelected: (value) => _handleBusAction(value, bus),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Details')),
                const PopupMenuItem(value: 'edit', child: Text('Edit Bus')),
                const PopupMenuItem(
                    value: 'assign', child: Text('Assign Driver')),
                const PopupMenuItem(
                    value: 'maintenance', child: Text('Schedule Maintenance')),
                const PopupMenuItem(value: 'delete', child: Text('Remove Bus')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriversTab(String schoolId) {
    return Column(
      children: [
        _buildSearchAndFilters(),
        _buildDriverStatistics(schoolId),
        Expanded(child: _buildDriversList(schoolId)),
      ],
    );
  }

  Widget _buildDriverStatistics(String schoolId) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.secondary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('Total Drivers', '12', Icons.person)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Active', '10', Icons.check_circle)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Pending', '2', Icons.pending)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
              child: _buildStatItem('Available', '8', Icons.person_outline)),
        ],
      ),
    );
  }

  Widget _buildDriversList(String schoolId) {
    final drivers = _getMockDrivers();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        return _buildDriverCard(drivers[index]);
      },
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final statusColor = driver['status'] == 'Active'
        ? AppColors.success
        : driver['status'] == 'Pending'
            ? AppColors.warning
            : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
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
                  Row(
                    children: [
                      Icon(Icons.directions_bus,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        driver['assignedBus'] ?? 'Unassigned',
                        style: TextStyle(
                          color: driver['assignedBus'] != null
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(width: AppConstants.paddingSmall),
            PopupMenuButton<String>(
              onSelected: (value) => _handleDriverAction(value, driver),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Profile')),
                const PopupMenuItem(value: 'edit', child: Text('Edit Driver')),
                const PopupMenuItem(value: 'assign', child: Text('Assign Bus')),
                const PopupMenuItem(
                    value: 'approve', child: Text('Approve Driver')),
                const PopupMenuItem(
                    value: 'suspend', child: Text('Suspend Driver')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(String schoolId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Analytics',
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
                  'Route Efficiency',
                  '92%',
                  Icons.trending_up,
                  AppColors.success,
                  '+5% from last month',
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildAnalyticsCard(
                  'Fuel Consumption',
                  '8.2L/100km',
                  Icons.local_gas_station,
                  AppColors.info,
                  '-2% from last month',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'On-Time Performance',
                  '96%',
                  Icons.schedule,
                  AppColors.success,
                  '+3% from last month',
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildAnalyticsCard(
                  'Maintenance Cost',
                  '\$2,450',
                  Icons.build,
                  AppColors.warning,
                  '+12% from last month',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Route Performance Chart Placeholder
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
                  'Route Performance Trends',
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
                        Icon(Icons.bar_chart,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'Interactive charts coming soon',
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
      String title, String value, IconData icon, Color color, String trend) {
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
                  fontSize: 18,
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
            trend,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary),
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

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Please log in to access bus and route management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  // Filter methods
  List<Map<String, dynamic>> _filterRoutes(List<Map<String, dynamic>> routes) {
    return routes.where((route) {
      final matchesSearch = _searchQuery.isEmpty ||
          route['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (route['driver'] ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _selectedStatus == 'All' || route['status'] == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // Action methods
  void _handleRouteAction(String action, Map<String, dynamic> route) {
    switch (action) {
      case 'view':
        _viewRouteDetails(route);
        break;
      case 'edit':
        _editRoute(route);
        break;
      case 'assign':
        _assignDriverToRoute(route);
        break;
      case 'optimize':
        _optimizeRoute(route);
        break;
      case 'delete':
        _deleteRoute(route);
        break;
    }
  }

  void _handleBusAction(String action, Map<String, dynamic> bus) {
    switch (action) {
      case 'view':
        _viewBusDetails(bus);
        break;
      case 'edit':
        _editBus(bus);
        break;
      case 'assign':
        _assignDriverToBus(bus);
        break;
      case 'maintenance':
        _scheduleMaintenance(bus);
        break;
      case 'delete':
        _deleteBus(bus);
        break;
    }
  }

  void _handleDriverAction(String action, Map<String, dynamic> driver) {
    switch (action) {
      case 'view':
        _viewDriverProfile(driver);
        break;
      case 'edit':
        _editDriver(driver);
        break;
      case 'assign':
        _assignBusToDriver(driver);
        break;
      case 'approve':
        _approveDriver(driver);
        break;
      case 'suspend':
        _suspendDriver(driver);
        break;
    }
  }

  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export Data'),
              onTap: () => _exportData(),
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Optimize All Routes'),
              onTap: () => _optimizeAllRoutes(),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Bulk Driver Assignment'),
              onTap: () => _bulkDriverAssignment(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Add Route'),
              onTap: () {
                Navigator.pop(context);
                _addRoute();
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_bus),
              title: const Text('Add Bus'),
              onTap: () {
                Navigator.pop(context);
                _addBus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Add Driver'),
              onTap: () {
                Navigator.pop(context);
                _addDriver();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Individual action methods
  void _viewRouteDetails(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(route['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${route['status']}'),
            Text('Stops: ${route['stops']}'),
            Text('Students: ${route['students']}'),
            Text('Driver: ${route['driver'] ?? 'Unassigned'}'),
            Text('Bus: ${route['bus'] ?? 'Unassigned'}'),
            Text('Duration: ${route['duration']}'),
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

  void _editRoute(Map<String, dynamic> route) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route editing functionality coming soon')),
    );
  }

  void _assignDriverToRoute(Map<String, dynamic> route) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Driver assignment functionality coming soon')),
    );
  }

  void _optimizeRoute(Map<String, dynamic> route) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Route optimization functionality coming soon')),
    );
  }

  void _deleteRoute(Map<String, dynamic> route) async {
    final confirmed = await _showConfirmDialog(
      'Delete Route',
      'Are you sure you want to delete ${route['name']}?',
    );

    if (confirmed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _viewBusDetails(Map<String, dynamic> bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bus['number']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model: ${bus['model']}'),
            Text('Capacity: ${bus['capacity']}'),
            Text('Status: ${bus['status']}'),
            Text('Driver: ${bus['driver'] ?? 'Unassigned'}'),
            Text('License Plate: ${bus['licensePlate']}'),
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

  void _editBus(Map<String, dynamic> bus) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bus editing functionality coming soon')),
    );
  }

  void _assignDriverToBus(Map<String, dynamic> bus) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Driver assignment functionality coming soon')),
    );
  }

  void _scheduleMaintenance(Map<String, dynamic> bus) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Maintenance scheduling functionality coming soon')),
    );
  }

  void _deleteBus(Map<String, dynamic> bus) async {
    final confirmed = await _showConfirmDialog(
      'Delete Bus',
      'Are you sure you want to delete ${bus['number']}?',
    );

    if (confirmed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bus deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _viewDriverProfile(Map<String, dynamic> driver) {
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
            Text('Status: ${driver['status']}'),
            Text('Phone: ${driver['phone']}'),
            Text('Assigned Bus: ${driver['assignedBus'] ?? 'Unassigned'}'),
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

  void _editDriver(Map<String, dynamic> driver) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Driver editing functionality coming soon')),
    );
  }

  void _assignBusToDriver(Map<String, dynamic> driver) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bus assignment functionality coming soon')),
    );
  }

  void _approveDriver(Map<String, dynamic> driver) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Driver approved successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _suspendDriver(Map<String, dynamic> driver) async {
    final confirmed = await _showConfirmDialog(
      'Suspend Driver',
      'Are you sure you want to suspend ${driver['name']}?',
    );

    if (confirmed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver suspended successfully'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  // Bulk operations
  void _exportData() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export functionality coming soon')),
    );
  }

  void _optimizeAllRoutes() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Route optimization functionality coming soon')),
    );
  }

  void _bulkDriverAssignment() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Bulk assignment functionality coming soon')),
    );
  }

  void _addRoute() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add route functionality coming soon')),
    );
  }

  void _addBus() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add bus functionality coming soon')),
    );
  }

  void _addDriver() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add driver functionality coming soon')),
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
  List<Map<String, dynamic>> _getMockRoutes() {
    return [
      {
        'id': '1',
        'name': 'Route A - North District',
        'status': 'Active',
        'stops': 12,
        'students': 35,
        'driver': 'John Smith',
        'bus': 'Bus 001',
        'duration': '45 min',
      },
      {
        'id': '2',
        'name': 'Route B - South District',
        'status': 'Active',
        'stops': 8,
        'students': 28,
        'driver': 'Mary Johnson',
        'bus': 'Bus 002',
        'duration': '35 min',
      },
      {
        'id': '3',
        'name': 'Route C - East District',
        'status': 'Inactive',
        'stops': 15,
        'students': 42,
        'driver': null,
        'bus': null,
        'duration': '55 min',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockBuses() {
    return [
      {
        'id': '1',
        'number': 'Bus 001',
        'model': 'Blue Bird Vision',
        'capacity': 40,
        'status': 'Active',
        'driver': 'John Smith',
        'licensePlate': 'SCH-001',
      },
      {
        'id': '2',
        'number': 'Bus 002',
        'model': 'Thomas Built C2',
        'capacity': 35,
        'status': 'Active',
        'driver': 'Mary Johnson',
        'licensePlate': 'SCH-002',
      },
      {
        'id': '3',
        'number': 'Bus 003',
        'model': 'IC Bus CE',
        'capacity': 45,
        'status': 'Maintenance',
        'driver': null,
        'licensePlate': 'SCH-003',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockDrivers() {
    return [
      {
        'id': '1',
        'name': 'John Smith',
        'license': 'CDL-12345',
        'expiry': '2025-06-15',
        'status': 'Active',
        'phone': '+1-555-0101',
        'assignedBus': 'Bus 001',
        'photoUrl': null,
      },
      {
        'id': '2',
        'name': 'Mary Johnson',
        'license': 'CDL-67890',
        'expiry': '2025-08-22',
        'status': 'Active',
        'phone': '+1-555-0102',
        'assignedBus': 'Bus 002',
        'photoUrl': null,
      },
      {
        'id': '3',
        'name': 'Robert Wilson',
        'license': 'CDL-11111',
        'expiry': '2024-12-10',
        'status': 'Pending',
        'phone': '+1-555-0103',
        'assignedBus': null,
        'photoUrl': null,
      },
    ];
  }
}
