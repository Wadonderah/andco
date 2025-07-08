import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  final List<RideRecord> _rideHistory = [
    RideRecord(
      id: '1',
      childName: 'Emma Johnson',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      pickupTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      dropoffTime: DateTime.now().subtract(const Duration(hours: 2)),
      pickupLocation: 'Maple Street, Home',
      dropoffLocation: 'Lincoln Elementary School',
      driverName: 'Mike Wilson',
      busNumber: 'BUS-001',
      status: RideStatus.completed,
      distance: '5.2 km',
      duration: '25 minutes',
      fare: 12.50,
    ),
    RideRecord(
      id: '2',
      childName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(days: 1)),
      pickupTime: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      dropoffTime: DateTime.now().subtract(const Duration(days: 1, hours: 7, minutes: 30)),
      pickupLocation: 'Oak Avenue Stop',
      dropoffLocation: 'Lincoln Elementary School',
      driverName: 'Sarah Davis',
      busNumber: 'BUS-003',
      status: RideStatus.completed,
      distance: '4.8 km',
      duration: '22 minutes',
      fare: 12.50,
    ),
    RideRecord(
      id: '3',
      childName: 'Emma Johnson',
      date: DateTime.now().subtract(const Duration(days: 2)),
      pickupTime: DateTime.now().subtract(const Duration(days: 2, hours: 8)),
      dropoffTime: null,
      pickupLocation: 'Maple Street, Home',
      dropoffLocation: 'Lincoln Elementary School',
      driverName: 'Mike Wilson',
      busNumber: 'BUS-001',
      status: RideStatus.cancelled,
      distance: '5.2 km',
      duration: null,
      fare: 0.0,
      notes: 'Child was sick - cancelled by parent',
    ),
  ];

  final List<AttendanceRecord> _attendanceHistory = [
    AttendanceRecord(
      id: '1',
      childName: 'Emma Johnson',
      date: DateTime.now(),
      morningPickup: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      morningDropoff: DateTime.now().subtract(const Duration(hours: 2)),
      afternoonPickup: null,
      afternoonDropoff: null,
      status: AttendanceStatus.present,
      notes: 'On time pickup and dropoff',
    ),
    AttendanceRecord(
      id: '2',
      childName: 'Alex Johnson',
      date: DateTime.now(),
      morningPickup: DateTime.now().subtract(const Duration(hours: 2, minutes: 35)),
      morningDropoff: DateTime.now().subtract(const Duration(hours: 2, minutes: 5)),
      afternoonPickup: null,
      afternoonDropoff: null,
      status: AttendanceStatus.present,
      notes: 'Slightly late pickup due to traffic',
    ),
    AttendanceRecord(
      id: '3',
      childName: 'Emma Johnson',
      date: DateTime.now().subtract(const Duration(days: 1)),
      morningPickup: null,
      morningDropoff: null,
      afternoonPickup: null,
      afternoonDropoff: null,
      status: AttendanceStatus.absent,
      notes: 'Sick day - parent notification sent',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History & Attendance'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Ride History'),
            Tab(text: 'Attendance'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _exportData,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRideHistoryTab(),
          _buildAttendanceTab(),
        ],
      ),
    );
  }

  Widget _buildRideHistoryTab() {
    return Column(
      children: [
        // Summary Cards
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Rides',
                  _rideHistory.where((r) => r.status == RideStatus.completed).length.toString(),
                  Icons.directions_bus,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildSummaryCard(
                  'This Month',
                  '\$${_calculateMonthlyFare().toStringAsFixed(2)}',
                  Icons.attach_money,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ),

        // Ride History List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            itemCount: _rideHistory.length,
            itemBuilder: (context, index) {
              final ride = _rideHistory[index];
              return _buildRideHistoryCard(ride);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    return Column(
      children: [
        // Attendance Summary
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Present Days',
                  _attendanceHistory.where((a) => a.status == AttendanceStatus.present).length.toString(),
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildSummaryCard(
                  'Attendance Rate',
                  '${(_calculateAttendanceRate() * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppColors.info,
                ),
              ),
            ],
          ),
        ),

        // Attendance List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            itemCount: _attendanceHistory.length,
            itemBuilder: (context, index) {
              final attendance = _attendanceHistory[index];
              return _buildAttendanceCard(attendance);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideHistoryCard(RideRecord ride) {
    final statusColor = _getRideStatusColor(ride.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.parentColor.withOpacity(0.1),
                  child: Text(
                    ride.childName[0],
                    style: const TextStyle(
                      color: AppColors.parentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.childName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(ride.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    ride.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Route Information
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationRow(
                        'Pickup',
                        ride.pickupLocation,
                        ride.pickupTime != null ? _formatTime(ride.pickupTime!) : 'N/A',
                        Icons.radio_button_checked,
                        AppColors.success,
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      _buildLocationRow(
                        'Drop-off',
                        ride.dropoffLocation,
                        ride.dropoffTime != null ? _formatTime(ride.dropoffTime!) : 'N/A',
                        Icons.location_on,
                        AppColors.error,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Trip Details
            Row(
              children: [
                _buildDetailChip('Driver', ride.driverName, Icons.person),
                const SizedBox(width: AppConstants.paddingSmall),
                _buildDetailChip('Bus', ride.busNumber, Icons.directions_bus),
                const SizedBox(width: AppConstants.paddingSmall),
                _buildDetailChip('Distance', ride.distance, Icons.straighten),
              ],
            ),
            
            if (ride.duration != null) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                children: [
                  _buildDetailChip('Duration', ride.duration!, Icons.access_time),
                  const SizedBox(width: AppConstants.paddingSmall),
                  _buildDetailChip('Fare', '\$${ride.fare.toStringAsFixed(2)}', Icons.attach_money),
                ],
              ),
            ],
            
            if (ride.notes != null) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride.notes!,
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
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

  Widget _buildAttendanceCard(AttendanceRecord attendance) {
    final statusColor = _getAttendanceStatusColor(attendance.status);
    
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
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(
                    attendance.status == AttendanceStatus.present 
                        ? Icons.check 
                        : Icons.close,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance.childName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(attendance.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    attendance.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            if (attendance.status == AttendanceStatus.present) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Morning Trip
              if (attendance.morningPickup != null && attendance.morningDropoff != null) ...[
                _buildTripRow(
                  'Morning Trip',
                  _formatTime(attendance.morningPickup!),
                  _formatTime(attendance.morningDropoff!),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
              ],
              
              // Afternoon Trip
              if (attendance.afternoonPickup != null && attendance.afternoonDropoff != null) ...[
                _buildTripRow(
                  'Afternoon Trip',
                  _formatTime(attendance.afternoonPickup!),
                  _formatTime(attendance.afternoonDropoff!),
                ),
              ],
            ],
            
            if (attendance.notes.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Text(
                  attendance.notes,
                  style: const TextStyle(
                    color: AppColors.info,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String location, String time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripRow(String label, String pickupTime, String dropoffTime) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$pickupTime → $dropoffTime',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getRideStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return AppColors.success;
      case RideStatus.cancelled:
        return AppColors.error;
      case RideStatus.inProgress:
        return AppColors.warning;
    }
  }

  Color _getAttendanceStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late:
        return AppColors.warning;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  double _calculateMonthlyFare() {
    final now = DateTime.now();
    return _rideHistory
        .where((ride) => 
            ride.date.month == now.month && 
            ride.date.year == now.year &&
            ride.status == RideStatus.completed)
        .fold(0.0, (sum, ride) => sum + ride.fare);
  }

  double _calculateAttendanceRate() {
    if (_attendanceHistory.isEmpty) return 0.0;
    final presentDays = _attendanceHistory
        .where((attendance) => attendance.status == AttendanceStatus.present)
        .length;
    return presentDays / _attendanceHistory.length;
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date Range'),
              subtitle: const Text('Filter by specific date range'),
              onTap: () {
                Navigator.pop(context);
                _selectDateRange();
              },
            ),
            ListTile(
              leading: const Icon(Icons.child_care),
              title: const Text('Child'),
              subtitle: const Text('Filter by specific child'),
              onTap: () {
                Navigator.pop(context);
                _selectChild();
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Status'),
              subtitle: const Text('Filter by ride/attendance status'),
              onTap: () {
                Navigator.pop(context);
                _selectStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose export format for your ride history and attendance data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToPDF();
            },
            child: const Text('PDF'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToCSV();
            },
            child: const Text('CSV'),
          ),
        ],
      ),
    );
  }

  void _selectDateRange() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Date range selection will be implemented')),
    );
  }

  void _selectChild() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Child filter will be implemented')),
    );
  }

  void _selectStatus() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status filter will be implemented')),
    );
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting to PDF...'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _exportToCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting to CSV...'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum RideStatus { completed, cancelled, inProgress }
enum AttendanceStatus { present, absent, late }

class RideRecord {
  final String id;
  final String childName;
  final DateTime date;
  final DateTime? pickupTime;
  final DateTime? dropoffTime;
  final String pickupLocation;
  final String dropoffLocation;
  final String driverName;
  final String busNumber;
  final RideStatus status;
  final String distance;
  final String? duration;
  final double fare;
  final String? notes;

  RideRecord({
    required this.id,
    required this.childName,
    required this.date,
    this.pickupTime,
    this.dropoffTime,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.driverName,
    required this.busNumber,
    required this.status,
    required this.distance,
    this.duration,
    required this.fare,
    this.notes,
  });
}

class AttendanceRecord {
  final String id;
  final String childName;
  final DateTime date;
  final DateTime? morningPickup;
  final DateTime? morningDropoff;
  final DateTime? afternoonPickup;
  final DateTime? afternoonDropoff;
  final AttendanceStatus status;
  final String notes;

  AttendanceRecord({
    required this.id,
    required this.childName,
    required this.date,
    this.morningPickup,
    this.morningDropoff,
    this.afternoonPickup,
    this.afternoonDropoff,
    required this.status,
    required this.notes,
  });
}
