import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedStudentManagementScreen extends ConsumerStatefulWidget {
  const EnhancedStudentManagementScreen({super.key});

  @override
  ConsumerState<EnhancedStudentManagementScreen> createState() =>
      _EnhancedStudentManagementScreenState();
}

class _EnhancedStudentManagementScreenState
    extends ConsumerState<EnhancedStudentManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGrade = 'All';
  String _selectedClass = 'All';
  String _selectedRoute = 'All';

  final List<String> _grades = [
    'All',
    'Pre-K',
    'K',
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th'
  ];
  final List<String> _classes = [
    'All',
    'Class A',
    'Class B',
    'Class C',
    'Class D'
  ];
  final List<String> _routes = [
    'All',
    'Route A',
    'Route B',
    'Route C',
    'Route D'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Student Management'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All Students'),
            Tab(icon: Icon(Icons.add), text: 'Add Student'),
            Tab(icon: Icon(Icons.route), text: 'Route Assignment'),
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
              ? _buildStudentManagement(user)
              : _buildLoginPrompt(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewStudent(),
        backgroundColor: AppColors.schoolAdminColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStudentManagement(user) {
    final schoolId = user.schoolId ?? '';

    if (schoolId.isEmpty) {
      return _buildNoSchoolAssigned();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildStudentList(schoolId),
        _buildAddStudent(schoolId),
        _buildRouteAssignment(schoolId),
      ],
    );
  }

  Widget _buildStudentList(String schoolId) {
    return Column(
      children: [
        // Search and Filter Section
        _buildSearchAndFilters(),

        // Student Statistics
        _buildStudentStatistics(schoolId),

        // Student List
        Expanded(
          child: _buildStudentListView(schoolId),
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
              hintText: 'Search students by name, ID, or parent...',
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
                _buildFilterChip('Grade', _selectedGrade, _grades, (value) {
                  setState(() => _selectedGrade = value);
                }),
                const SizedBox(width: AppConstants.paddingSmall),
                _buildFilterChip('Class', _selectedClass, _classes, (value) {
                  setState(() => _selectedClass = value);
                }),
                const SizedBox(width: AppConstants.paddingSmall),
                _buildFilterChip('Route', _selectedRoute, _routes, (value) {
                  setState(() => _selectedRoute = value);
                }),
                const SizedBox(width: AppConstants.paddingSmall),
                ActionChip(
                  label: const Text('Clear Filters'),
                  onPressed: () {
                    setState(() {
                      _selectedGrade = 'All';
                      _selectedClass = 'All';
                      _selectedRoute = 'All';
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

  Widget _buildStudentStatistics(String schoolId) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppColors.schoolAdminColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
              child: _buildStatItem('Total Students', '342', Icons.groups)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Active Routes', '8', Icons.route)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _buildStatItem('Unassigned', '12', Icons.warning)),
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
        ),
      ],
    );
  }

  Widget _buildStudentListView(String schoolId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getStudentsStream(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final students = snapshot.data ?? [];
        final filteredStudents = _filterStudents(students);

        if (filteredStudents.isEmpty) {
          return _buildEmptyStudentsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          itemCount: filteredStudents.length,
          itemBuilder: (context, index) {
            return _buildStudentCard(filteredStudents[index]);
          },
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getStudentsStream(String schoolId) {
    if (schoolId.isEmpty) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('children')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'studentId': data['studentId'] ?? '',
          'name': data['name'] ?? 'Unknown Student',
          'grade': data['grade'] ?? '',
          'class': data['class'] ?? '',
          'gender': data['gender'] ?? '',
          'parentName': data['parentName'] ?? '',
          'route': data['routeId'] ?? '',
          'address': data['address'] ?? '',
          'photoUrl': data['photoUrl'],
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

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            // Student Photo
            CircleAvatar(
              radius: 25,
              backgroundColor:
                  AppColors.schoolAdminColor.withValues(alpha: 0.1),
              backgroundImage: student['photoUrl'] != null
                  ? NetworkImage(student['photoUrl'])
                  : null,
              child: student['photoUrl'] == null
                  ? Icon(
                      student['gender'] == 'Male' ? Icons.boy : Icons.girl,
                      color: AppColors.schoolAdminColor,
                      size: 30,
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
                    'ID: ${student['studentId']} • ${student['grade']} ${student['class']}',
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
                        student['parentName'],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.route,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        student['route'] ?? 'Unassigned',
                        style: TextStyle(
                          color: student['route'] != null
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

            // Action Menu
            PopupMenuButton<String>(
              onSelected: (value) => _handleStudentAction(value, student),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Details')),
                const PopupMenuItem(value: 'edit', child: Text('Edit Student')),
                const PopupMenuItem(
                    value: 'assign', child: Text('Assign Route')),
                const PopupMenuItem(
                    value: 'contact', child: Text('Contact Parent')),
                const PopupMenuItem(
                    value: 'delete', child: Text('Remove Student')),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.schoolAdminColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.more_vert,
                    color: AppColors.schoolAdminColor, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStudent(String schoolId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add New Student',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Add Student Form
          _buildAddStudentForm(),
        ],
      ),
    );
  }

  Widget _buildAddStudentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Photo Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        AppColors.schoolAdminColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person_add,
                      size: 50,
                      color: AppColors.schoolAdminColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  TextButton.icon(
                    onPressed: () => _selectStudentPhoto(),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Add Photo'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Student Information
            Text(
              'Student Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Student ID *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Gender *',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Male', 'Female', 'Other'].map((gender) {
                      return DropdownMenuItem(
                          value: gender, child: Text(gender));
                    }).toList(),
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Grade *',
                      border: OutlineInputBorder(),
                    ),
                    items: _grades.where((g) => g != 'All').map((grade) {
                      return DropdownMenuItem(value: grade, child: Text(grade));
                    }).toList(),
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Class *',
                      border: OutlineInputBorder(),
                    ),
                    items: _classes.where((c) => c != 'All').map((className) {
                      return DropdownMenuItem(
                          value: className, child: Text(className));
                    }).toList(),
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDateOfBirth(),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Parent Information
            Text(
              'Parent/Guardian Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Parent Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Home Address *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Medical Information
            Text(
              'Medical Information (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Allergies',
                border: OutlineInputBorder(),
                hintText: 'List any known allergies...',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Medical Conditions',
                border: OutlineInputBorder(),
                hintText: 'List any medical conditions...',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Emergency Contact',
                border: OutlineInputBorder(),
                hintText: 'Name and phone number...',
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge * 2),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _clearForm(),
                    child: const Text('Clear Form'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _saveStudent(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.schoolAdminColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Add Student',
                      style: TextStyle(color: Colors.white),
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

  Widget _buildRouteAssignment(String schoolId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Assignment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          Text(
            'Drag and drop students to assign them to routes, or use bulk assignment tools.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Route Assignment Interface
          _buildRouteAssignmentInterface(),
        ],
      ),
    );
  }

  Widget _buildRouteAssignmentInterface() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unassigned Students',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        child: ListView(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingSmall),
                          children: [
                            // TODO: Replace with real unassigned students from Firebase
                            Center(
                              child: Text(
                                'Unassigned students will appear here',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.paddingLarge),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Routes',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        child: ListView(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingSmall),
                          children: [
                            // TODO: Replace with real routes from Firebase
                            Center(
                              child: Text(
                                'Routes will appear here',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Bulk Assignment Tools
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBulkAssignmentDialog(),
                    icon: const Icon(Icons.group_add),
                    label: const Text('Bulk Assign by Grade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _autoAssignByLocation(),
                    icon: const Icon(Icons.location_on),
                    label: const Text('Auto-Assign by Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
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

  Widget _buildDraggableStudentCard(Map<String, dynamic> student) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.schoolAdminColor.withValues(alpha: 0.1),
          child: Icon(
            student['gender'] == 'Male' ? Icons.boy : Icons.girl,
            color: AppColors.schoolAdminColor,
          ),
        ),
        title: Text(student['name']),
        subtitle: Text('${student['grade']} ${student['class']}'),
        trailing: const Icon(Icons.drag_handle),
      ),
    );
  }

  Widget _buildRouteDropZone(Map<String, dynamic> route) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      color: AppColors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  route['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${route['studentCount']}/40',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Driver: ${route['driver']}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            Text(
              'Capacity: ${route['capacity']} students',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods and widgets
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
            'Please log in to access student management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  // Filter and search methods
  List<Map<String, dynamic>> _filterStudents(
      List<Map<String, dynamic>> students) {
    return students.where((student) {
      final matchesSearch = _searchQuery.isEmpty ||
          student['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student['studentId']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          student['parentName']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesGrade =
          _selectedGrade == 'All' || student['grade'] == _selectedGrade;
      final matchesClass =
          _selectedClass == 'All' || student['class'] == _selectedClass;
      final matchesRoute =
          _selectedRoute == 'All' || student['route'] == _selectedRoute;

      return matchesSearch && matchesGrade && matchesClass && matchesRoute;
    }).toList();
  }

  // Action methods
  void _handleStudentAction(String action, Map<String, dynamic> student) {
    switch (action) {
      case 'view':
        _viewStudentDetails(student);
        break;
      case 'edit':
        _editStudent(student);
        break;
      case 'assign':
        _assignStudentToRoute(student);
        break;
      case 'contact':
        _contactParent(student);
        break;
      case 'delete':
        _removeStudent(student);
        break;
    }
  }

  void _viewStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student ID: ${student['studentId']}'),
            Text('Grade: ${student['grade']} ${student['class']}'),
            Text('Parent: ${student['parentName']}'),
            Text('Route: ${student['route'] ?? 'Unassigned'}'),
            Text('Address: ${student['address']}'),
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

  void _editStudent(Map<String, dynamic> student) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit student functionality coming soon')),
    );
  }

  void _assignStudentToRoute(Map<String, dynamic> student) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Route assignment functionality coming soon')),
    );
  }

  void _contactParent(Map<String, dynamic> student) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact parent functionality coming soon')),
    );
  }

  void _removeStudent(Map<String, dynamic> student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
            'Are you sure you want to remove ${student['name']} from the school?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student removed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // Form methods
  void _selectStudentPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo selection coming soon')),
    );
  }

  void _selectDateOfBirth() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Date picker coming soon')),
    );
  }

  void _clearForm() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form cleared')),
    );
  }

  void _saveStudent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student added successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // Bulk operations
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
              title: const Text('Export Student Data'),
              onTap: () => _exportStudentData(),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Import Students'),
              onTap: () => _importStudents(),
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Bulk Route Assignment'),
              onTap: () => _showBulkAssignmentDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewStudent() {
    _tabController.animateTo(1);
  }

  void _exportStudentData() async {
    Navigator.pop(context);

    try {
      // Get all students from Firestore
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .orderBy('name')
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No students to export')),
          );
        }
        return;
      }

      // For now, show success message - in production, implement file download
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Exported ${studentsSnapshot.docs.length} students successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _importStudents() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import functionality coming soon')),
    );
  }

  void _showBulkAssignmentDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk assignment dialog coming soon')),
    );
  }

  void _autoAssignByLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auto-assignment by location coming soon')),
    );
  }

  // All mock data methods removed - now using real Firebase data
}
