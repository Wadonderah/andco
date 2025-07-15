import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/driver_service.dart';
import '../../../core/theme/app_colors.dart';

class SmartRoutesScreen extends ConsumerStatefulWidget {
  const SmartRoutesScreen({super.key});

  @override
  ConsumerState<SmartRoutesScreen> createState() => _SmartRoutesScreenState();
}

class _SmartRoutesScreenState extends ConsumerState<SmartRoutesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Real route data will be loaded from Firebase
  List<RouteOption> _routeOptions = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _currentRoute;

  // Real traffic alerts will be loaded from Firebase
  final List<TrafficAlert> _trafficAlerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRouteData();
  }

  /// Load real route data from Firebase
  Future<void> _loadRouteData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get driver's assigned route from DriverService
      final routeStream = DriverService.instance.getAssignedRouteStream();

      routeStream.listen((route) {
        if (route != null) {
          setState(() {
            _currentRoute = route;
            _isLoading = false;
          });
          _generateRouteOptions(route);
        } else {
          setState(() {
            _error = 'No route assigned';
            _isLoading = false;
          });
        }
      }, onError: (error) {
        setState(() {
          _error = 'Failed to load route: $error';
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load route data: $e';
        _isLoading = false;
      });
    }
  }

  /// Generate route options based on current route data
  void _generateRouteOptions(Map<String, dynamic> route) {
    // In a real implementation, this would use Google Maps API
    // to generate multiple route options with real traffic data
    setState(() {
      _routeOptions = [
        RouteOption(
          id: 'optimal',
          name: 'Optimal Route',
          distance: '${(route['totalDistance'] ?? 0).toStringAsFixed(1)} km',
          duration: '${route['estimatedDuration'] ?? 25} min',
          trafficLevel: TrafficLevel.light,
          fuelCost:
              '\$${((route['totalDistance'] ?? 0) * 0.68).toStringAsFixed(2)}',
          isRecommended: true,
          waypoints: _extractWaypoints(route),
        ),
        // Additional route options would be generated here
      ];
    });
  }

  /// Extract waypoints from route data
  List<String> _extractWaypoints(Map<String, dynamic> route) {
    final stops = route['stops'] as List<dynamic>? ?? [];
    return stops
        .map((stop) => stop['name'] as String? ?? 'Unknown Stop')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Routes'),
        backgroundColor: AppColors.driverColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Route Options'),
            Tab(text: 'Live Traffic'),
            Tab(text: 'Navigation'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refreshRoutes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRouteOptionsTab(),
          _buildLiveTrafficTab(),
          _buildNavigationTab(),
        ],
      ),
    );
  }

  Widget _buildRouteOptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Route Status
          Card(
            color: AppColors.driverColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  Icon(
                    Icons.route,
                    color: AppColors.driverColor,
                    size: 32,
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Morning Route - Active',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.driverColor,
                                  ),
                        ),
                        Text(
                          '10 students • 6 stops • ETA: 8:15 AM',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _startNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.driverColor,
                    ),
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Route Options
          Text(
            'Route Options',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          ..._routeOptions.map((route) => _buildRouteOptionCard(route)),
        ],
      ),
    );
  }

  Widget _buildRouteOptionCard(RouteOption route) {
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
                  child: Text(
                    route.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (route.isRecommended)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Route Stats
            Row(
              children: [
                _buildStatChip(
                    Icons.straighten, route.distance, AppColors.info),
                const SizedBox(width: AppConstants.paddingSmall),
                _buildStatChip(
                    Icons.access_time, route.duration, AppColors.warning),
                const SizedBox(width: AppConstants.paddingSmall),
                _buildStatChip(
                    Icons.local_gas_station, route.fuelCost, AppColors.success),
                const SizedBox(width: AppConstants.paddingSmall),
                _buildTrafficChip(route.trafficLevel),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Waypoints
            Text(
              'Route Stops:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),

            ...route.waypoints.asMap().entries.map((entry) {
              final index = entry.key;
              final waypoint = entry.value;
              final isLast = index == route.waypoints.length - 1;

              return Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: index == 0 || isLast
                              ? AppColors.driverColor
                              : AppColors.info,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 20,
                          color: AppColors.surfaceVariant,
                        ),
                    ],
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        waypoint,
                        style: TextStyle(
                          fontSize: 12,
                          color: index == 0 || isLast
                              ? AppColors.driverColor
                              : AppColors.textPrimary,
                          fontWeight: index == 0 || isLast
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: AppConstants.paddingMedium),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _previewRoute(route),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectRoute(route),
                    icon: const Icon(Icons.navigation),
                    label: const Text('Select'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: route.isRecommended
                          ? AppColors.driverColor
                          : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficChip(TrafficLevel level) {
    Color color;
    String text;
    IconData icon;

    switch (level) {
      case TrafficLevel.light:
        color = AppColors.success;
        text = 'Light';
        icon = Icons.traffic;
        break;
      case TrafficLevel.moderate:
        color = AppColors.warning;
        text = 'Moderate';
        icon = Icons.traffic;
        break;
      case TrafficLevel.heavy:
        color = AppColors.error;
        text = 'Heavy';
        icon = Icons.traffic;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTrafficTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Traffic Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.traffic,
                        color: AppColors.warning,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text(
                        'Traffic Overview',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Spacer(),
                      Text(
                        'Updated 2 min ago',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTrafficStat('Current Route',
                            'Light Traffic', AppColors.success),
                      ),
                      Expanded(
                        child: _buildTrafficStat(
                            'Average Delay', '3 minutes', AppColors.warning),
                      ),
                      Expanded(
                        child: _buildTrafficStat(
                            'Incidents', '2 active', AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Traffic Alerts
          Text(
            'Traffic Alerts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          ..._trafficAlerts.map((alert) => _buildTrafficAlertCard(alert)),

          const SizedBox(height: AppConstants.paddingLarge),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _refreshTraffic,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Traffic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.driverColor,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reportIncident,
                  icon: const Icon(Icons.report),
                  label: const Text('Report Incident'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrafficAlertCard(TrafficAlert alert) {
    Color alertColor;
    IconData alertIcon;

    switch (alert.severity) {
      case AlertSeverity.low:
        alertColor = AppColors.info;
        alertIcon = Icons.info_outline;
        break;
      case AlertSeverity.medium:
        alertColor = AppColors.warning;
        alertIcon = Icons.warning_amber;
        break;
      case AlertSeverity.high:
        alertColor = AppColors.error;
        alertIcon = Icons.error_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(alertIcon, color: alertColor, size: 20),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Text(
                    alert.location,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: alertColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    alert.severity.name.toUpperCase(),
                    style: TextStyle(
                      color: alertColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              alert.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Delay: ${alert.estimatedDelay}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Icon(Icons.alt_route, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    alert.alternativeRoute,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.navigation,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Navigation Ready',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Select a route to start turn-by-turn navigation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton.icon(
            onPressed: _startNavigation,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Navigation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.driverColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshRoutes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing routes with latest traffic data...'),
        backgroundColor: AppColors.driverColor,
      ),
    );
  }

  void _previewRoute(RouteOption route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Previewing ${route.name}')),
    );
  }

  void _selectRoute(RouteOption route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${route.name} selected'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _startNavigation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting navigation...'),
        backgroundColor: AppColors.driverColor,
      ),
    );
  }

  void _refreshTraffic() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing traffic data...')),
    );
  }

  void _reportIncident() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Report incident feature will be implemented')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum TrafficLevel { light, moderate, heavy }

enum TrafficAlertType { accident, construction, weather, event }

enum AlertSeverity { low, medium, high }

class RouteOption {
  final String id;
  final String name;
  final String distance;
  final String duration;
  final TrafficLevel trafficLevel;
  final String fuelCost;
  final bool isRecommended;
  final List<String> waypoints;

  RouteOption({
    required this.id,
    required this.name,
    required this.distance,
    required this.duration,
    required this.trafficLevel,
    required this.fuelCost,
    required this.isRecommended,
    required this.waypoints,
  });
}

class TrafficAlert {
  final String id;
  final String location;
  final TrafficAlertType type;
  final AlertSeverity severity;
  final String description;
  final String estimatedDelay;
  final String alternativeRoute;

  TrafficAlert({
    required this.id,
    required this.location,
    required this.type,
    required this.severity,
    required this.description,
    required this.estimatedDelay,
    required this.alternativeRoute,
  });
}
