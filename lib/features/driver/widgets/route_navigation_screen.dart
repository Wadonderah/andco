import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class RouteNavigationScreen extends ConsumerStatefulWidget {
  final dynamic route;

  const RouteNavigationScreen({super.key, required this.route});

  @override
  ConsumerState<RouteNavigationScreen> createState() => _RouteNavigationScreenState();
}

class _RouteNavigationScreenState extends ConsumerState<RouteNavigationScreen> {
  bool _isLoading = false;
  bool _isNavigating = false;
  int _currentStopIndex = 0;
  double _currentSpeed = 0.0;
  String _currentLocation = 'Loading...';
  String _nextTurn = 'Continue straight';
  double _distanceToNextStop = 2.5;
  int _estimatedArrival = 8;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  void _initializeNavigation() {
    setState(() {
      _currentLocation = 'Starting navigation...';
      _isNavigating = true;
    });
    
    // TODO: Initialize GPS and navigation services
    _simulateNavigation();
  }

  void _simulateNavigation() {
    // Simulate real-time navigation updates
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentLocation = 'Main Street, approaching first stop';
          _currentSpeed = 35.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: Column(
            children: [
              // Navigation Header
              _buildNavigationHeader(),
              
              // Map Area (Placeholder)
              Expanded(
                flex: 3,
                child: _buildMapArea(),
              ),
              
              // Navigation Info
              _buildNavigationInfo(),
              
              // Current Stop Info
              _buildCurrentStopInfo(),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.driverColor,
      child: Row(
        children: [
          IconButton(
            onPressed: () => _exitNavigation(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.route.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Stop ${_currentStopIndex + 1} of ${widget.route.stops.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_currentSpeed.toInt()} km/h',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          // Map Placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'GPS Navigation Map',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Real-time navigation will be displayed here',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Controls Overlay
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _buildMapControl(Icons.my_location, 'Center'),
                const SizedBox(height: 8),
                _buildMapControl(Icons.zoom_in, 'Zoom In'),
                const SizedBox(height: 8),
                _buildMapControl(Icons.zoom_out, 'Zoom Out'),
              ],
            ),
          ),
          
          // Traffic Info Overlay
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.traffic, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Light Traffic',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl(IconData icon, String tooltip) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => _handleMapControl(tooltip),
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildNavigationInfo() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: Colors.white,
      child: Row(
        children: [
          // Next Turn
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.turn_right, color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nextTurn,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'in ${_distanceToNextStop.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // ETA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.driverColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'ETA',
                  style: TextStyle(
                    color: AppColors.driverColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_estimatedArrival} min',
                  style: TextStyle(
                    color: AppColors.driverColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStopInfo() {
    if (widget.route.stops.isEmpty) return const SizedBox.shrink();
    
    final currentStop = widget.route.stops[_currentStopIndex];
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    '${_currentStopIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      currentStop.address,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentStop.studentIds.length} students',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.paddingMedium),
          
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentStopIndex + 1) / widget.route.stops.length,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.driverColor),
          ),
          
          const SizedBox(height: AppConstants.paddingSmall),
          
          Text(
            'Stop ${_currentStopIndex + 1} of ${widget.route.stops.length}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: Colors.white,
      child: Row(
        children: [
          // Emergency SOS
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _triggerEmergencySOS(),
              icon: const Icon(Icons.emergency),
              label: const Text('SOS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(width: AppConstants.paddingMedium),
          
          // Arrive at Stop
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _arriveAtStop(),
              icon: const Icon(Icons.location_on),
              label: const Text('Arrive at Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(width: AppConstants.paddingMedium),
          
          // Voice Navigation Toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => _toggleVoiceNavigation(),
              icon: Icon(
                Icons.volume_up,
                color: AppColors.info,
              ),
              tooltip: 'Voice Navigation',
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _handleMapControl(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action - Feature coming soon')),
    );
  }

  void _exitNavigation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Navigation'),
        content: const Text('Are you sure you want to exit navigation? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.pop(context);
    }
  }

  void _triggerEmergencySOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Emergency SOS'),
          ],
        ),
        content: const Text('This will immediately alert school administrators and emergency contacts. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Send SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        // TODO: Implement SOS functionality
        await Future.delayed(const Duration(seconds: 2));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency SOS sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending SOS: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _arriveAtStop() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement stop arrival logic
      await Future.delayed(const Duration(seconds: 1));
      
      // Navigate to student manifest for this stop
      final result = await Navigator.pushNamed(
        context,
        '/student-manifest',
        arguments: {
          'route': widget.route,
          'stopIndex': _currentStopIndex,
        },
      );

      if (result == true) {
        // Move to next stop
        if (_currentStopIndex < widget.route.stops.length - 1) {
          setState(() {
            _currentStopIndex++;
            _distanceToNextStop = 1.8; // Simulate distance to next stop
            _estimatedArrival = 6; // Simulate new ETA
          });
        } else {
          // Route completed
          _completeRoute();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing stop arrival: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _completeRoute() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Route'),
        content: const Text('Congratulations! You have completed all stops on this route.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Finish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _toggleVoiceNavigation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice navigation toggled')),
    );
  }
}
