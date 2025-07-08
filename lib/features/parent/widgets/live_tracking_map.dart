import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class LiveTrackingMap extends StatefulWidget {
  final String childId;
  final String busId;
  
  const LiveTrackingMap({
    super.key,
    required this.childId,
    required this.busId,
  });

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  // Mock data for demonstration
  final Map<String, dynamic> _busData = {
    'busNumber': 'BUS-001',
    'driverName': 'Mike Wilson',
    'currentLocation': 'Main Street & Oak Avenue',
    'eta': '8 minutes',
    'speed': '25 km/h',
    'nextStop': 'Lincoln Elementary School',
    'studentsOnBoard': 12,
    'capacity': 30,
    'status': 'On Route',
  };

  bool _isTracking = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleTracking,
            icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            onPressed: _refreshLocation,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bus Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _busData['busNumber'],
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Driver: ${_busData['driverName']}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: Text(
                        _busData['status'],
                        style: const TextStyle(
                          color: Colors.white,
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
                      child: _buildInfoItem(
                        'ETA',
                        _busData['eta'],
                        Icons.access_time,
                        AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Speed',
                        _busData['speed'],
                        Icons.speed,
                        AppColors.info,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Students',
                        '${_busData['studentsOnBoard']}/${_busData['capacity']}',
                        Icons.groups,
                        AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map Placeholder (In real implementation, this would be Google Maps)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: AppColors.textHint.withOpacity(0.3)),
              ),
              child: Stack(
                children: [
                  // Map placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        Text(
                          'Live GPS Map',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          'Real-time bus location tracking',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Mock bus location indicator
                  Positioned(
                    top: 100,
                    left: 150,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  // Mock route line
                  Positioned(
                    top: 120,
                    left: 50,
                    child: Container(
                      width: 200,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current Location Info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Text(
                      'Current Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  _busData['currentLocation'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Row(
                  children: [
                    const Icon(
                      Icons.flag,
                      color: AppColors.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Next Stop: ${_busData['nextStop']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnBus,
        backgroundColor: AppColors.parentColor,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isTracking ? 'Tracking resumed' : 'Tracking paused'),
        backgroundColor: _isTracking ? AppColors.success : AppColors.warning,
      ),
    );
  }

  void _refreshLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location updated'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _centerOnBus() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centered on bus location'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
