import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class RouteOptimizerScreen extends StatefulWidget {
  const RouteOptimizerScreen({super.key});

  @override
  State<RouteOptimizerScreen> createState() => _RouteOptimizerScreenState();
}

class _RouteOptimizerScreenState extends State<RouteOptimizerScreen> {
  final List<OptimizedRoute> _routes = [
    OptimizedRoute(
      id: '1',
      name: 'Route A - North District',
      schoolName: 'Greenwood Elementary',
      currentEfficiency: 85,
      optimizedEfficiency: 92,
      estimatedSavings: 15.5,
      studentCount: 45,
      stops: 12,
      distance: 18.5,
      duration: 35,
      status: OptimizationStatus.optimized,
      lastOptimized: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    OptimizedRoute(
      id: '2',
      name: 'Route B - South District',
      schoolName: 'Riverside High School',
      currentEfficiency: 78,
      optimizedEfficiency: 88,
      estimatedSavings: 22.3,
      studentCount: 52,
      stops: 15,
      distance: 24.2,
      duration: 42,
      status: OptimizationStatus.pending,
      lastOptimized: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'AI-Based Route Optimizer',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _runOptimization,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Run Optimization'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Optimization Summary
            Row(
              children: [
                _buildSummaryCard('Total Routes', _routes.length.toString(), AppColors.orange),
                const SizedBox(width: AppConstants.paddingMedium),
                _buildSummaryCard('Avg Efficiency', '${_getAverageEfficiency().toStringAsFixed(1)}%', AppColors.success),
                const SizedBox(width: AppConstants.paddingMedium),
                _buildSummaryCard('Potential Savings', '\$${_getTotalSavings().toStringAsFixed(0)}', AppColors.info),
                const SizedBox(width: AppConstants.paddingMedium),
                _buildSummaryCard('Optimized Today', _getOptimizedTodayCount().toString(), AppColors.purple),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Routes List
            const Text(
              'Route Optimization Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Expanded(
              child: ListView.builder(
                itemCount: _routes.length,
                itemBuilder: (context, index) {
                  final route = _routes[index];
                  return _buildRouteCard(route);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
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

  Widget _buildRouteCard(OptimizedRoute route) {
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
                    color: _getStatusColor(route.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    Icons.route,
                    color: _getStatusColor(route.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        route.schoolName,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${route.studentCount} students • ${route.stops} stops • ${route.distance}km',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(route.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    route.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(route.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Efficiency Comparison
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Efficiency', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${route.currentEfficiency}%', style: const TextStyle(fontSize: 18, color: AppColors.warning)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AppColors.textSecondary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Optimized Efficiency', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${route.optimizedEfficiency}%', style: const TextStyle(fontSize: 18, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Savings and Metrics
            Row(
              children: [
                _buildMetric('Potential Savings', '\$${route.estimatedSavings.toStringAsFixed(1)}'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildMetric('Duration', '${route.duration} min'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildMetric('Last Optimized', _formatLastOptimized(route.lastOptimized)),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Action Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewRouteDetails(route),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
                TextButton.icon(
                  onPressed: () => _viewOptimizationSuggestions(route),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Suggestions'),
                ),
                const Spacer(),
                if (route.status == OptimizationStatus.pending)
                  ElevatedButton.icon(
                    onPressed: () => _applyOptimization(route),
                    icon: const Icon(Icons.check),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _reoptimizeRoute(route),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Re-optimize'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // Helper Methods
  double _getAverageEfficiency() {
    if (_routes.isEmpty) return 0.0;
    return _routes.fold<double>(0, (sum, route) => sum + route.optimizedEfficiency) / _routes.length;
  }

  double _getTotalSavings() {
    return _routes.fold<double>(0, (sum, route) => sum + route.estimatedSavings);
  }

  int _getOptimizedTodayCount() {
    final today = DateTime.now();
    return _routes.where((route) => 
      route.lastOptimized.day == today.day &&
      route.lastOptimized.month == today.month &&
      route.lastOptimized.year == today.year
    ).length;
  }

  Color _getStatusColor(OptimizationStatus status) {
    switch (status) {
      case OptimizationStatus.optimized:
        return AppColors.success;
      case OptimizationStatus.pending:
        return AppColors.warning;
      case OptimizationStatus.failed:
        return AppColors.error;
    }
  }

  String _formatLastOptimized(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Action Methods
  void _runOptimization() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Route Optimization'),
        content: const Text('This will analyze all routes and provide optimization suggestions. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Route optimization started...')),
              );
            },
            child: const Text('Run'),
          ),
        ],
      ),
    );
  }

  void _viewRouteDetails(OptimizedRoute route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(route.name),
        content: Text('Detailed route information for ${route.name} would be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewOptimizationSuggestions(OptimizedRoute route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Optimization Suggestions - ${route.name}'),
        content: const Text('AI-generated optimization suggestions would be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _applyOptimization(OptimizedRoute route) {
    setState(() {
      final index = _routes.indexWhere((r) => r.id == route.id);
      if (index != -1) {
        _routes[index] = route.copyWith(
          status: OptimizationStatus.optimized,
          lastOptimized: DateTime.now(),
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Optimization applied to ${route.name}')),
    );
  }

  void _reoptimizeRoute(OptimizedRoute route) {
    setState(() {
      final index = _routes.indexWhere((r) => r.id == route.id);
      if (index != -1) {
        _routes[index] = route.copyWith(
          status: OptimizationStatus.pending,
          lastOptimized: DateTime.now(),
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Re-optimization started for ${route.name}')),
    );
  }
}

// Data Models
enum OptimizationStatus {
  optimized('Optimized'),
  pending('Pending'),
  failed('Failed');

  const OptimizationStatus(this.displayName);
  final String displayName;
}

class OptimizedRoute {
  final String id;
  final String name;
  final String schoolName;
  final int currentEfficiency;
  final int optimizedEfficiency;
  final double estimatedSavings;
  final int studentCount;
  final int stops;
  final double distance;
  final int duration;
  final OptimizationStatus status;
  final DateTime lastOptimized;

  OptimizedRoute({
    required this.id,
    required this.name,
    required this.schoolName,
    required this.currentEfficiency,
    required this.optimizedEfficiency,
    required this.estimatedSavings,
    required this.studentCount,
    required this.stops,
    required this.distance,
    required this.duration,
    required this.status,
    required this.lastOptimized,
  });

  OptimizedRoute copyWith({
    String? id,
    String? name,
    String? schoolName,
    int? currentEfficiency,
    int? optimizedEfficiency,
    double? estimatedSavings,
    int? studentCount,
    int? stops,
    double? distance,
    int? duration,
    OptimizationStatus? status,
    DateTime? lastOptimized,
  }) {
    return OptimizedRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolName: schoolName ?? this.schoolName,
      currentEfficiency: currentEfficiency ?? this.currentEfficiency,
      optimizedEfficiency: optimizedEfficiency ?? this.optimizedEfficiency,
      estimatedSavings: estimatedSavings ?? this.estimatedSavings,
      studentCount: studentCount ?? this.studentCount,
      stops: stops ?? this.stops,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      lastOptimized: lastOptimized ?? this.lastOptimized,
    );
  }
}
