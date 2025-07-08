import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class AttendanceTrackingScreen extends StatefulWidget {
  const AttendanceTrackingScreen({super.key});

  @override
  State<AttendanceTrackingScreen> createState() => _AttendanceTrackingScreenState();
}

class _AttendanceTrackingScreenState extends State<AttendanceTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  final List<AttendanceRecord> _todayAttendance = [
    AttendanceRecord(
      studentId: '1',
      studentName: 'Emma Johnson',
      grade: '3rd Grade',
      seatNumber: '12',
      morningPickup: AttendanceStatus.present,
      morningPickupTime: DateTime.now().subtract(const Duration(hours: 2)),
      afternoonDropoff: AttendanceStatus.pending,
      afternoonDropoffTime: null,
      parentNotified: true,
      notes: 'On time pickup',
      photoUrl: 'assets/images/student1.jpg',
    ),
    AttendanceRecord(
      studentId: '2',
      studentName: 'Alex Chen',
      grade: '2nd Grade',
      seatNumber: '8',
      morningPickup: AttendanceStatus.present,
      morningPickupTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      afternoonDropoff: AttendanceStatus.pending,
      afternoonDropoffTime: null,
      parentNotified: true,
      notes: 'Brought inhaler',
      photoUrl: 'assets/images/student2.jpg',
    ),
    AttendanceRecord(
      studentId: '3',
      studentName: 'Marcus Williams',
      grade: '4th Grade',
      seatNumber: '15',
      morningPickup: AttendanceStatus.absent,
      morningPickupTime: null,
      afternoonDropoff: AttendanceStatus.notApplicable,
      afternoonDropoffTime: null,
      parentNotified: true,
      notes: 'Parent called - sick',
      photoUrl: 'assets/images/student3.jpg',
    ),
    AttendanceRecord(
      studentId: '4',
      studentName: 'Sofia Rodriguez',
      grade: '1st Grade',
      seatNumber: '5',
      morningPickup: AttendanceStatus.late,
      morningPickupTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      afternoonDropoff: AttendanceStatus.pending,
      afternoonDropoffTime: null,
      parentNotified: true,
      notes: 'Picked up 10 minutes late',
      photoUrl: 'assets/images/student4.jpg',
    ),
  ];

  final List<AttendanceReport> _weeklyReports = [
    AttendanceReport(
      date: DateTime.now(),
      totalStudents: 25,
      presentMorning: 23,
      presentAfternoon: 22,
      absentCount: 2,
      lateCount: 1,
      completionRate: 0.92,
    ),
    AttendanceReport(
      date: DateTime.now().subtract(const Duration(days: 1)),
      totalStudents: 25,
      presentMorning: 25,
      presentAfternoon: 24,
      absentCount: 0,
      lateCount: 0,
      completionRate: 0.96,
    ),
    AttendanceReport(
      date: DateTime.now().subtract(const Duration(days: 2)),
      totalStudents: 25,
      presentMorning: 22,
      presentAfternoon: 21,
      absentCount: 3,
      lateCount: 2,
      completionRate: 0.84,
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
        title: const Text('Attendance Tracking'),
        backgroundColor: AppColors.driverColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Reports'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _syncAttendance,
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            onPressed: _exportAttendance,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildReportsTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _quickAttendanceUpdate,
        backgroundColor: AppColors.driverColor,
        icon: const Icon(Icons.edit),
        label: const Text('Quick Update'),
      ),
    );
  }

  Widget _buildTodayTab() {
    final presentCount = _todayAttendance.where((a) => a.morningPickup == AttendanceStatus.present).length;
    final absentCount = _todayAttendance.where((a) => a.morningPickup == AttendanceStatus.absent).length;
    final lateCount = _todayAttendance.where((a) => a.morningPickup == AttendanceStatus.late).length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.today,
                        color: AppColors.driverColor,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text(
                        'Today\'s Attendance',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  Row(
                    children: [
                      Expanded(child: _buildAttendanceStat('Present', presentCount, AppColors.success)),
                      Expanded(child: _buildAttendanceStat('Absent', absentCount, AppColors.error)),
                      Expanded(child: _buildAttendanceStat('Late', lateCount, AppColors.warning)),
                      Expanded(child: _buildAttendanceStat('Total', _todayAttendance.length, AppColors.info)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Route Status
          Row(
            children: [
              Expanded(
                child: _buildRouteStatusCard(
                  'Morning Route',
                  'Completed',
                  '${presentCount + lateCount}/${_todayAttendance.length} picked up',
                  AppColors.success,
                  Icons.wb_sunny,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildRouteStatusCard(
                  'Afternoon Route',
                  'Pending',
                  'Starts at 3:15 PM',
                  AppColors.warning,
                  Icons.wb_twilight,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Student Attendance List
          Text(
            'Student Attendance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          ..._todayAttendance.map((record) => _buildAttendanceCard(record)).toList(),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
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

  Widget _buildRouteStatusCard(String title, String status, String subtitle, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    final morningColor = _getStatusColor(record.morningPickup);
    final afternoonColor = _getStatusColor(record.afternoonDropoff);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.driverColor.withOpacity(0.1),
                  child: Text(
                    record.studentName[0],
                    style: const TextStyle(
                      color: AppColors.driverColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.studentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${record.grade} • Seat ${record.seatNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (record.parentNotified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'NOTIFIED',
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Attendance Status
            Row(
              children: [
                Expanded(
                  child: _buildStatusChip(
                    'Morning',
                    record.morningPickup,
                    record.morningPickupTime,
                    morningColor,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _buildStatusChip(
                    'Afternoon',
                    record.afternoonDropoff,
                    record.afternoonDropoffTime,
                    afternoonColor,
                  ),
                ),
              ],
            ),

            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.note,
                      color: AppColors.info,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.notes,
                        style: const TextStyle(
                          color: AppColors.info,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppConstants.paddingMedium),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editAttendance(record),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.driverColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _notifyParent(record),
                    icon: const Icon(Icons.notifications),
                    label: const Text('Notify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
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

  Widget _buildStatusChip(String label, AttendanceStatus status, DateTime? time, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getStatusText(status),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (time != null)
            Text(
              _formatTime(time),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  Row(
                    children: [
                      Expanded(child: _buildWeeklyStat('Average Attendance', '94%', AppColors.success)),
                      Expanded(child: _buildWeeklyStat('Total Absences', '5', AppColors.error)),
                      Expanded(child: _buildWeeklyStat('Late Pickups', '3', AppColors.warning)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Daily Reports
          Text(
            'Daily Reports',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          ..._weeklyReports.map((report) => _buildDailyReportCard(report)).toList(),
        ],
      ),
    );
  }

  Widget _buildWeeklyStat(String label, String value, Color color) {
    return Column(
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
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDailyReportCard(AttendanceReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(report.date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCompletionColor(report.completionRate).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    '${(report.completionRate * 100).round()}%',
                    style: TextStyle(
                      color: _getCompletionColor(report.completionRate),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            Row(
              children: [
                Expanded(child: _buildReportStat('Present AM', report.presentMorning.toString())),
                Expanded(child: _buildReportStat('Present PM', report.presentAfternoon.toString())),
                Expanded(child: _buildReportStat('Absent', report.absentCount.toString())),
                Expanded(child: _buildReportStat('Late', report.lateCount.toString())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildAnalyticsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Analytics Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Detailed attendance analytics and trends',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton.icon(
            onPressed: _viewAnalytics,
            icon: const Icon(Icons.bar_chart),
            label: const Text('View Analytics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.driverColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.pending:
        return AppColors.info;
      case AttendanceStatus.notApplicable:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.pending:
        return 'Pending';
      case AttendanceStatus.notApplicable:
        return 'N/A';
    }
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 0.9) return AppColors.success;
    if (rate >= 0.8) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _editAttendance(AttendanceRecord record) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing attendance for ${record.studentName}')),
    );
  }

  void _notifyParent(AttendanceRecord record) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifying parent of ${record.studentName}'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _syncAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing attendance data...'),
        backgroundColor: AppColors.driverColor,
      ),
    );
  }

  void _exportAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting attendance report...')),
    );
  }

  void _quickAttendanceUpdate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick attendance update will be implemented')),
    );
  }

  void _viewAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics dashboard will be implemented')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum AttendanceStatus { present, absent, late, pending, notApplicable }

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final String grade;
  final String seatNumber;
  final AttendanceStatus morningPickup;
  final DateTime? morningPickupTime;
  final AttendanceStatus afternoonDropoff;
  final DateTime? afternoonDropoffTime;
  final bool parentNotified;
  final String notes;
  final String photoUrl;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.seatNumber,
    required this.morningPickup,
    this.morningPickupTime,
    required this.afternoonDropoff,
    this.afternoonDropoffTime,
    required this.parentNotified,
    required this.notes,
    required this.photoUrl,
  });
}

class AttendanceReport {
  final DateTime date;
  final int totalStudents;
  final int presentMorning;
  final int presentAfternoon;
  final int absentCount;
  final int lateCount;
  final double completionRate;

  AttendanceReport({
    required this.date,
    required this.totalStudents,
    required this.presentMorning,
    required this.presentAfternoon,
    required this.absentCount,
    required this.lateCount,
    required this.completionRate,
  });
}
