import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final StudentFilter _currentFilter = StudentFilter.all;
  String _selectedGrade = 'All Grades';
  String _selectedClass = 'All Classes';

  final List<String> _grades = [
    'All Grades',
    'Pre-K',
    'K',
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th'
  ];
  final List<String> _classes = ['All Classes', 'A', 'B', 'C', 'D'];

  final List<AdminStudent> _students = [
    AdminStudent(
      id: '1',
      name: 'Emma Johnson',
      grade: '3rd',
      className: 'A',
      studentId: 'STU001',
      photoUrl: 'assets/images/student1.jpg',
      parentName: 'Sarah Johnson',
      parentPhone: '+1 234 567 8900',
      parentEmail: 'sarah.johnson@email.com',
      emergencyContact: 'John Johnson - +1 234 567 8901',
      address: '123 Maple Street, Springfield',
      medicalNotes: 'Allergic to peanuts',
      busRoute: 'Route A',
      busNumber: 'Bus 101',
      pickupTime: '7:45 AM',
      dropoffTime: '3:15 PM',
      status: StudentStatus.active,
      enrollmentDate: DateTime(2023, 8, 15),
      dateOfBirth: DateTime(2015, 3, 12),
      bloodType: 'O+',
      hasSpecialNeeds: false,
      specialNeeds: [],
    ),
    AdminStudent(
      id: '2',
      name: 'Alex Chen',
      grade: '2nd',
      className: 'B',
      studentId: 'STU002',
      photoUrl: 'assets/images/student2.jpg',
      parentName: 'Lisa Chen',
      parentPhone: '+1 234 567 8902',
      parentEmail: 'lisa.chen@email.com',
      emergencyContact: 'David Chen - +1 234 567 8903',
      address: '456 Oak Avenue, Springfield',
      medicalNotes: 'Inhaler for asthma',
      busRoute: 'Route B',
      busNumber: 'Bus 102',
      pickupTime: '7:50 AM',
      dropoffTime: '3:15 PM',
      status: StudentStatus.active,
      enrollmentDate: DateTime(2023, 8, 20),
      dateOfBirth: DateTime(2016, 7, 8),
      bloodType: 'A+',
      hasSpecialNeeds: true,
      specialNeeds: ['Asthma'],
    ),
    AdminStudent(
      id: '3',
      name: 'Marcus Williams',
      grade: '4th',
      className: 'A',
      studentId: 'STU003',
      photoUrl: 'assets/images/student3.jpg',
      parentName: 'Angela Williams',
      parentPhone: '+1 234 567 8904',
      parentEmail: 'angela.williams@email.com',
      emergencyContact: 'Robert Williams - +1 234 567 8905',
      address: '789 Pine Road, Springfield',
      medicalNotes: 'None',
      busRoute: 'Route A',
      busNumber: 'Bus 101',
      pickupTime: '7:55 AM',
      dropoffTime: '3:15 PM',
      status: StudentStatus.active,
      enrollmentDate: DateTime(2023, 8, 10),
      dateOfBirth: DateTime(2014, 11, 22),
      bloodType: 'B+',
      hasSpecialNeeds: false,
      specialNeeds: [],
    ),
    AdminStudent(
      id: '4',
      name: 'Sofia Rodriguez',
      grade: '1st',
      className: 'C',
      studentId: 'STU004',
      photoUrl: 'assets/images/student4.jpg',
      parentName: 'Maria Rodriguez',
      parentPhone: '+1 234 567 8906',
      parentEmail: 'maria.rodriguez@email.com',
      emergencyContact: 'Carlos Rodriguez - +1 234 567 8907',
      address: '321 Cedar Lane, Springfield',
      medicalNotes: 'Lactose intolerant',
      busRoute: 'Route C',
      busNumber: 'Bus 103',
      pickupTime: '8:00 AM',
      dropoffTime: '3:15 PM',
      status: StudentStatus.inactive,
      enrollmentDate: DateTime(2023, 9, 1),
      dateOfBirth: DateTime(2017, 1, 15),
      bloodType: 'AB+',
      hasSpecialNeeds: true,
      specialNeeds: ['Dietary restrictions'],
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
        title: const Text('Student Management'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Students'),
            Tab(text: 'Enrollment'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _addNewStudent,
            icon: const Icon(Icons.person_add),
          ),
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _exportStudentData,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentListTab(),
          _buildEnrollmentTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildStudentListTab() {
    final filteredStudents = _getFilteredStudents();

    return Column(
      children: [
        // Search and Filters
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.surfaceVariant,
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search students by name, ID, or parent...',
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

              // Filter Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGrade,
                      decoration: const InputDecoration(
                        labelText: 'Grade',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _grades
                          .map((grade) => DropdownMenuItem(
                                value: grade,
                                child: Text(grade),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGrade = value!),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _classes
                          .map((className) => DropdownMenuItem(
                                value: className,
                                child: Text(className),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedClass = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Summary Stats
              Row(
                children: [
                  Expanded(
                      child: _buildSummaryCard('Total',
                          _students.length.toString(), AppColors.info)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildSummaryCard(
                          'Active',
                          _getStudentCount(StudentStatus.active).toString(),
                          AppColors.success)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildSummaryCard(
                          'Inactive',
                          _getStudentCount(StudentStatus.inactive).toString(),
                          AppColors.warning)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildSummaryCard(
                          'Special Needs',
                          _students
                              .where((s) => s.hasSpecialNeeds)
                              .length
                              .toString(),
                          AppColors.secondary)),
                ],
              ),
            ],
          ),
        ),

        // Student List
        Expanded(
          child: filteredStudents.isEmpty
              ? _buildEmptyStudentsState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return _buildStudentCard(student);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Student Enrollment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Manage new student enrollments and transfers',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Student Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            'View enrollment trends and student statistics',
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

  Widget _buildStudentCard(AdminStudent student) {
    final statusColor = student.status == StudentStatus.active
        ? AppColors.success
        : AppColors.warning;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                // Student Photo
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.schoolAdminColor.withOpacity(0.1),
                  child: student.photoUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.asset(
                            student.photoUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                                student.name[0],
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        )
                      : Text(
                          student.name[0],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.schoolAdminColor,
                          ),
                        ),
                ),

                const SizedBox(width: AppConstants.paddingMedium),

                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.name,
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
                              student.status == StudentStatus.active
                                  ? 'Active'
                                  : 'Inactive',
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
                        'ID: ${student.studentId} • Grade ${student.grade}${student.className}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Parent: ${student.parentName}',
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
                  onSelected: (value) => _handleStudentAction(value, student),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'view', child: Text('View Details')),
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit Profile')),
                    const PopupMenuItem(
                        value: 'assign_bus', child: Text('Assign Bus')),
                    const PopupMenuItem(
                        value: 'contact_parent', child: Text('Contact Parent')),
                    const PopupMenuItem(
                        value: 'deactivate', child: Text('Deactivate')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Quick Info Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickInfo(
                    'Bus Route',
                    student.busRoute,
                    Icons.directions_bus,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _buildQuickInfo(
                    'Pickup Time',
                    student.pickupTime,
                    Icons.schedule,
                    AppColors.warning,
                  ),
                ),
              ],
            ),

            if (student.hasSpecialNeeds) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Special Needs: ${student.specialNeeds.join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
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

  Widget _buildQuickInfo(
      String label, String value, IconData icon, Color color) {
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<AdminStudent> _getFilteredStudents() {
    return _students.where((student) {
      final matchesSearch = _searchQuery.isEmpty ||
          student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.studentId
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          student.parentName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesGrade =
          _selectedGrade == 'All Grades' || student.grade == _selectedGrade;
      final matchesClass = _selectedClass == 'All Classes' ||
          student.className == _selectedClass;

      return matchesSearch && matchesGrade && matchesClass;
    }).toList();
  }

  int _getStudentCount(StudentStatus status) {
    return _students.where((student) => student.status == status).length;
  }

  void _handleStudentAction(String action, AdminStudent student) {
    switch (action) {
      case 'view':
        _viewStudentDetails(student);
        break;
      case 'edit':
        _editStudentProfile(student);
        break;
      case 'assign_bus':
        _assignBusToStudent(student);
        break;
      case 'contact_parent':
        _contactParent(student);
        break;
      case 'deactivate':
        _deactivateStudent(student);
        break;
    }
  }

  void _viewStudentDetails(AdminStudent student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${student.name} - Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Student ID', student.studentId),
              _buildDetailRow('Grade', '${student.grade}${student.className}'),
              _buildDetailRow('Parent', student.parentName),
              _buildDetailRow('Phone', student.parentPhone),
              _buildDetailRow('Email', student.parentEmail),
              _buildDetailRow('Address', student.address),
              _buildDetailRow('Bus Route', student.busRoute),
              _buildDetailRow('Bus Number', student.busNumber),
              _buildDetailRow('Medical Notes', student.medicalNotes),
              if (student.hasSpecialNeeds)
                _buildDetailRow(
                    'Special Needs', student.specialNeeds.join(', ')),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  Widget _buildEmptyStudentsState() {
    final isSearching = _searchQuery.isNotEmpty;
    final hasGradeFilter = _selectedGrade != 'All Grades';
    final hasClassFilter = _selectedClass != 'All Classes';
    final hasFilters = isSearching || hasGradeFilter || hasClassFilter;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.school_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No Students Found' : 'No Students Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your search terms or filters'
                : 'Students will appear here once they are enrolled',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedGrade = 'All Grades';
                  _selectedClass = 'All Classes';
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.schoolAdminColor,
                foregroundColor: Colors.white,
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addNewStudent,
              icon: const Icon(Icons.add),
              label: const Text('Add Student'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.schoolAdminColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editStudentProfile(AdminStudent student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit profile for ${student.name}')),
    );
  }

  void _assignBusToStudent(AdminStudent student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assign bus to ${student.name}')),
    );
  }

  void _contactParent(AdminStudent student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contacting ${student.parentName}...')),
    );
  }

  void _deactivateStudent(AdminStudent student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Student'),
        content: Text('Are you sure you want to deactivate ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final index = _students.indexWhere((s) => s.id == student.id);
                if (index != -1) {
                  _students[index] =
                      student.copyWith(status: StudentStatus.inactive);
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${student.name} deactivated')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _addNewStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Add New Student'),
            backgroundColor: AppColors.schoolAdminColor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Grade',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Parent Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Student added successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.schoolAdminColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Add Student'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.grade),
              title: const Text('Filter by Grade'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Grade filter applied'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text('Filter by Class'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Class filter applied'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_bus),
              title: const Text('Filter by Bus Route'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Route filter applied'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear All Filters'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All filters cleared'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportStudentData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting student data...')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum StudentStatus { active, inactive, transferred, graduated }

enum StudentFilter { all, active, inactive, specialNeeds, noBus }

class AdminStudent {
  final String id;
  final String name;
  final String grade;
  final String className;
  final String studentId;
  final String photoUrl;
  final String parentName;
  final String parentPhone;
  final String parentEmail;
  final String emergencyContact;
  final String address;
  final String medicalNotes;
  final String busRoute;
  final String busNumber;
  final String pickupTime;
  final String dropoffTime;
  final StudentStatus status;
  final DateTime enrollmentDate;
  final DateTime dateOfBirth;
  final String bloodType;
  final bool hasSpecialNeeds;
  final List<String> specialNeeds;

  AdminStudent({
    required this.id,
    required this.name,
    required this.grade,
    required this.className,
    required this.studentId,
    required this.photoUrl,
    required this.parentName,
    required this.parentPhone,
    required this.parentEmail,
    required this.emergencyContact,
    required this.address,
    required this.medicalNotes,
    required this.busRoute,
    required this.busNumber,
    required this.pickupTime,
    required this.dropoffTime,
    required this.status,
    required this.enrollmentDate,
    required this.dateOfBirth,
    required this.bloodType,
    required this.hasSpecialNeeds,
    required this.specialNeeds,
  });

  AdminStudent copyWith({
    String? id,
    String? name,
    String? grade,
    String? className,
    String? studentId,
    String? photoUrl,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? emergencyContact,
    String? address,
    String? medicalNotes,
    String? busRoute,
    String? busNumber,
    String? pickupTime,
    String? dropoffTime,
    StudentStatus? status,
    DateTime? enrollmentDate,
    DateTime? dateOfBirth,
    String? bloodType,
    bool? hasSpecialNeeds,
    List<String>? specialNeeds,
  }) {
    return AdminStudent(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      className: className ?? this.className,
      studentId: studentId ?? this.studentId,
      photoUrl: photoUrl ?? this.photoUrl,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      address: address ?? this.address,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      busRoute: busRoute ?? this.busRoute,
      busNumber: busNumber ?? this.busNumber,
      pickupTime: pickupTime ?? this.pickupTime,
      dropoffTime: dropoffTime ?? this.dropoffTime,
      status: status ?? this.status,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      hasSpecialNeeds: hasSpecialNeeds ?? this.hasSpecialNeeds,
      specialNeeds: specialNeeds ?? this.specialNeeds,
    );
  }
}
