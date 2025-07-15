import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/route_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'route_navigation_screen.dart';

class EnhancedRouteManagementScreen extends ConsumerStatefulWidget {
  const EnhancedRouteManagementScreen({super.key});

  @override
  ConsumerState<EnhancedRouteManagementScreen> createState() =>
      _EnhancedRouteManagementScreenState();
}

class _EnhancedRouteManagementScreenState
    extends ConsumerState<EnhancedRouteManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Route Management'),
        backgroundColor: AppColors.driverColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.schedule), text: 'Scheduled'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: authState.when(
          data: (user) =>
              user != null ? _buildRouteManagement(user) : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildRouteManagement(user) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTodaysRoutes(user.schoolId ?? ''),
        _buildScheduledRoutes(user.schoolId ?? ''),
        _buildRouteHistory(user.schoolId ?? ''),
      ],
    );
  }

  Widget _buildTodaysRoutes(String schoolId) {
    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    final routesAsync = ref.watch(routesBySchoolStreamProvider(schoolId));

    return routesAsync.when(
      data: (routes) {
        // Filter routes for today
        final today = DateTime.now();
        final todaysRoutes = routes.where((route) {
          final routeDate = route.startTime;
          return routeDate.year == today.year &&
              routeDate.month == today.month &&
              routeDate.day == today.day;
        }).toList();

        return todaysRoutes.isEmpty
            ? _buildNoRoutesToday()
            : _buildRoutesList(todaysRoutes, isToday: true);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error loading routes: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(routesBySchoolStreamProvider(schoolId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledRoutes(String schoolId) {
    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    final routesAsync = ref.watch(routesBySchoolStreamProvider(schoolId));

    return routesAsync.when(
      data: (routes) {
        // Filter future routes
        final now = DateTime.now();
        final futureRoutes = routes.where((route) {
          return route.startTime.isAfter(now);
        }).toList();

        return futureRoutes.isEmpty
            ? _buildNoScheduledRoutes()
            : _buildRoutesList(futureRoutes, isToday: false);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading scheduled routes: $error')),
    );
  }

  Widget _buildRouteHistory(String schoolId) {
    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    final routesAsync = ref.watch(routesBySchoolStreamProvider(schoolId));

    return routesAsync.when(
      data: (routes) {
        // Filter inactive routes (representing completed/historical routes)
        final completedRoutes = routes.where((route) {
          return !route.isActive;
        }).toList();

        return completedRoutes.isEmpty
            ? _buildNoHistory()
            : _buildRoutesList(completedRoutes, isHistory: true);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading route history: $error')),
    );
  }

  Widget _buildRoutesList(List<dynamic> routes,
      {bool isToday = false, bool isHistory = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        return _buildRouteCard(routes[index],
            isToday: isToday, isHistory: isHistory);
      },
    );
  }

  Widget _buildRouteCard(dynamic route,
      {bool isToday = false, bool isHistory = false}) {
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
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.driverColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.route, color: AppColors.driverColor, size: 20),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        route.description,
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
                    color: _getRouteStatusColor(route).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRouteStatusText(route),
                    style: TextStyle(
                      color: _getRouteStatusColor(route),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Route Details
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('HH:mm').format(route.startTime)} - ${DateFormat('HH:mm').format(route.endTime)}',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${route.stops.length} stops',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.straighten,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${route.estimatedDistance.toStringAsFixed(1)} km',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Progress Bar (for today's routes)
            if (isToday) ...[
              LinearProgressIndicator(
                value: _getRouteProgress(route),
                backgroundColor: AppColors.border,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.driverColor),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                '${(_getRouteProgress(route) * 100).toInt()}% Complete',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            // Action Buttons
            Row(
              children: [
                if (isToday && !_isRouteCompleted(route)) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startRoute(route),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Route'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewRouteDetails(route),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.driverColor),
                    ),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateRoute(route),
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.driverColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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

  Widget _buildNoRoutesToday() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.today, color: AppColors.info, size: 64),
          const SizedBox(height: 16),
          Text(
            'No Routes Today',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no routes scheduled for today. Enjoy your day off!',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoScheduledRoutes() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, color: AppColors.info, size: 64),
          const SizedBox(height: 16),
          Text(
            'No Scheduled Routes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No upcoming routes are scheduled. Check back later.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: AppColors.info, size: 64),
          const SizedBox(height: 16),
          Text(
            'No Route History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed routes will appear here.',
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
            'Please log in to access route management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getRouteStatusColor(RouteModel route) {
    if (!route.isActive) {
      return AppColors.success; // Inactive routes are considered completed
    }
    if (route.hasBusAssigned) {
      return AppColors.warning; // Active with bus assigned
    }
    return AppColors.info; // Active but no bus assigned
  }

  String _getRouteStatusText(RouteModel route) {
    if (!route.isActive) return 'Completed';
    if (route.hasBusAssigned) return 'In Progress';
    return 'Scheduled';
  }

  double _getRouteProgress(dynamic route) {
    // Calculate progress based on completed stops
    if (route.stops.isEmpty) return 0.0;
    final completedStops =
        route.stops.where((stop) => stop.isCompleted ?? false).length;
    return completedStops / route.stops.length;
  }

  bool _isRouteCompleted(RouteModel route) {
    return !route.isActive; // Inactive routes are considered completed
  }

  // Action methods
  void _startRoute(dynamic route) async {
    final confirmed = await _showConfirmDialog(
      'Start Route',
      'Are you sure you want to start ${route.name}?',
    );

    if (confirmed) {
      setState(() => _isLoading = true);

      try {
        // TODO: Implement route start logic
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${route.name} started successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting route: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _viewRouteDetails(dynamic route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRouteDetailsSheet(route),
    );
  }

  Widget _buildRouteDetailsSheet(dynamic route) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                Expanded(
                  child: Text(
                    route.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Route details content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildDetailItem('Description', route.description),
                  _buildDetailItem('Start Time',
                      DateFormat('HH:mm').format(route.startTime)),
                  _buildDetailItem(
                      'End Time', DateFormat('HH:mm').format(route.endTime)),
                  _buildDetailItem('Distance',
                      '${route.estimatedDistance.toStringAsFixed(1)} km'),
                  _buildDetailItem(
                      'Duration', '${route.estimatedDuration.toInt()} minutes'),
                  _buildDetailItem('Stops', '${route.stops.length}'),
                  const SizedBox(height: AppConstants.paddingLarge),
                  Text(
                    'Route Stops',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  ...route.stops.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stop = entry.value;
                    return _buildStopItem(index + 1, stop);
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildStopItem(int number, dynamic stop) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.driverColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  stop.address,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (stop.isCompleted ?? false)
            Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  void _navigateRoute(dynamic route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteNavigationScreen(route: route),
      ),
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
                backgroundColor: AppColors.driverColor),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
