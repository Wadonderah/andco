import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/driver_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedStudentManifestScreen extends ConsumerStatefulWidget {
  final dynamic route;
  final int? stopIndex;

  const EnhancedStudentManifestScreen({super.key, this.route, this.stopIndex});

  @override
  ConsumerState<EnhancedStudentManifestScreen> createState() =>
      _EnhancedStudentManifestScreenState();
}

class _EnhancedStudentManifestScreenState
    extends ConsumerState<EnhancedStudentManifestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final Map<String, bool> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Student Manifest'),
        backgroundColor: AppColors.driverColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.upload), text: 'Pickup'),
            Tab(icon: Icon(Icons.download), text: 'Drop-off'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: authState.when(
          data: (user) =>
              user != null ? _buildStudentManifest(user) : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildStudentManifest(user) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPickupTab(user.schoolId ?? ''),
        _buildDropoffTab(user.schoolId ?? ''),
      ],
    );
  }

  Widget _buildPickupTab(String schoolId) {
    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getRouteStudentsStream(schoolId, isPickup: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final students = snapshot.data ?? [];
        return _buildStudentList(students, isPickup: true);
      },
    );
  }

  Widget _buildDropoffTab(String schoolId) {
    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getRouteStudentsStream(schoolId, isPickup: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final students = snapshot.data ?? [];
        return _buildStudentList(students, isPickup: false);
      },
    );
  }

  Widget _buildStudentList(List<Map<String, dynamic>> students,
      {required bool isPickup}) {
    if (students.isEmpty) {
      return _buildNoStudents(isPickup);
    }

    return Column(
      children: [
        // Summary Header
        _buildSummaryHeader(students, isPickup),

        // Student List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return _buildStudentCard(students[index], isPickup);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(
      List<Map<String, dynamic>> students, bool isPickup) {
    final totalStudents = students.length;
    final checkedIn = _attendanceStatus.values.where((status) => status).length;
    final remaining = totalStudents - checkedIn;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      color: AppColors.driverColor.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total',
              totalStudents.toString(),
              Icons.groups,
              AppColors.info,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _buildSummaryItem(
              isPickup ? 'Picked Up' : 'Dropped Off',
              checkedIn.toString(),
              Icons.check_circle,
              AppColors.success,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _buildSummaryItem(
              'Remaining',
              remaining.toString(),
              Icons.pending,
              AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
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
        ),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, bool isPickup) {
    final studentId = student['id'];
    final isCheckedIn = _attendanceStatus[studentId] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            // Student Photo
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.driverColor.withOpacity(0.1),
              backgroundImage: student['photoUrl'] != null
                  ? NetworkImage(student['photoUrl'])
                  : null,
              child: student['photoUrl'] == null
                  ? Icon(
                      student['gender'] == 'Male' ? Icons.boy : Icons.girl,
                      color: AppColors.driverColor,
                      size: 35,
                    )
                  : null,
            ),

            const SizedBox(width: AppConstants.paddingMedium),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${student['grade']} • ${student['class']}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.home,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          student['address'],
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Attendance Action
            if (isCheckedIn) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
            ] else ...[
              GestureDetector(
                onTap: () => _showAttendanceDialog(student, isPickup),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.driverColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPickup ? 'Pick Up' : 'Drop Off',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildNoStudents(bool isPickup) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPickup ? Icons.upload : Icons.download,
            color: AppColors.info,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isPickup ? 'No Students to Pick Up' : 'No Students to Drop Off',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isPickup
                ? 'All students have been picked up or no students are scheduled for pickup.'
                : 'All students have been dropped off or no students are scheduled for drop-off.',
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
            'Please log in to access student manifest',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  // Action methods
  void _showAttendanceDialog(Map<String, dynamic> student, bool isPickup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPickup ? 'Confirm Pickup' : 'Confirm Drop-off'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.driverColor.withOpacity(0.1),
              backgroundImage: student['photoUrl'] != null
                  ? NetworkImage(student['photoUrl'])
                  : null,
              child: student['photoUrl'] == null
                  ? Icon(
                      student['gender'] == 'Male' ? Icons.boy : Icons.girl,
                      color: AppColors.driverColor,
                      size: 40,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              student['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${student['grade']} • ${student['class']}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPickup
                  ? 'Confirm that this student has been picked up?'
                  : 'Confirm that this student has been dropped off?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _confirmAttendance(student['id'], isPickup),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              'Confirm',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAttendance(String studentId, bool isPickup) async {
    Navigator.pop(context); // Close dialog

    setState(() => _isLoading = true);

    try {
      // Use DriverService to mark student attendance with real Firebase integration
      if (isPickup) {
        await DriverService.instance.markStudentPickedUp(
          studentId,
          'current_stop_id', // This would be determined by current location
        );
      } else {
        await DriverService.instance.markStudentDroppedOff(
          studentId,
          'current_stop_id', // This would be determined by current location
        );
      }

      setState(() {
        _attendanceStatus[studentId] = true;
      });

      // Show success feedback with haptic feedback
      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isPickup ? Icons.upload : Icons.download,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                isPickup
                    ? 'Student picked up successfully'
                    : 'Student dropped off successfully',
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      // Show error feedback with haptic feedback
      HapticFeedback.heavyImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error marking attendance: $e'),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _confirmAttendance(studentId, isPickup),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Stream<List<Map<String, dynamic>>> _getRouteStudentsStream(String schoolId,
      {required bool isPickup}) {
    if (schoolId.isEmpty) {
      return Stream.value([]);
    }

    // Get students assigned to routes for this school
    return FirebaseFirestore.instance
        .collection('children')
        .where('schoolId', isEqualTo: schoolId)
        .where('routeId', isNotEqualTo: null)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Student',
          'grade': data['grade'] ?? '',
          'class': data['class'] ?? '',
          'gender': data['gender'] ?? '',
          'address': data['address'] ?? '',
          'photoUrl': data['photoUrl'],
          'routeId': data['routeId'],
          'parentName': data['parentName'] ?? '',
        };
      }).toList();
    });
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading students',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.error,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
