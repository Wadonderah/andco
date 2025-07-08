import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class StudentManifestScreen extends StatefulWidget {
  const StudentManifestScreen({super.key});

  @override
  State<StudentManifestScreen> createState() => _StudentManifestScreenState();
}

class _StudentManifestScreenState extends State<StudentManifestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  StudentFilter _currentFilter = StudentFilter.all;
  
  final List<Student> _students = [
    Student(
      id: '1',
      name: 'Emma Johnson',
      grade: '3rd Grade',
      photoUrl: 'assets/images/student1.jpg',
      pickupLocation: '123 Maple Street',
      dropoffLocation: 'Lincoln Elementary School',
      pickupTime: '7:45 AM',
      dropoffTime: '3:15 PM',
      parentName: 'Sarah Johnson',
      parentPhone: '+1 234 567 8900',
      emergencyContact: 'John Johnson - +1 234 567 8901',
      medicalNotes: 'Allergic to peanuts',
      status: StudentStatus.notPickedUp,
      busStop: 'Stop A1',
      seatNumber: '12',
      specialNeeds: [],
    ),
    Student(
      id: '2',
      name: 'Alex Chen',
      grade: '2nd Grade',
      photoUrl: 'assets/images/student2.jpg',
      pickupLocation: '456 Oak Avenue',
      dropoffLocation: 'Lincoln Elementary School',
      pickupTime: '7:50 AM',
      dropoffTime: '3:15 PM',
      parentName: 'Lisa Chen',
      parentPhone: '+1 234 567 8902',
      emergencyContact: 'David Chen - +1 234 567 8903',
      medicalNotes: 'Inhaler for asthma',
      status: StudentStatus.onBus,
      busStop: 'Stop A2',
      seatNumber: '8',
      specialNeeds: ['Asthma'],
    ),
    Student(
      id: '3',
      name: 'Marcus Williams',
      grade: '4th Grade',
      photoUrl: 'assets/images/student3.jpg',
      pickupLocation: '789 Pine Road',
      dropoffLocation: 'Lincoln Elementary School',
      pickupTime: '7:55 AM',
      dropoffTime: '3:15 PM',
      parentName: 'Angela Williams',
      parentPhone: '+1 234 567 8904',
      emergencyContact: 'Robert Williams - +1 234 567 8905',
      medicalNotes: 'None',
      status: StudentStatus.droppedOff,
      busStop: 'Stop A3',
      seatNumber: '15',
      specialNeeds: [],
    ),
    Student(
      id: '4',
      name: 'Sofia Rodriguez',
      grade: '1st Grade',
      photoUrl: 'assets/images/student4.jpg',
      pickupLocation: '321 Cedar Lane',
      dropoffLocation: 'Lincoln Elementary School',
      pickupTime: '8:00 AM',
      dropoffTime: '3:15 PM',
      parentName: 'Maria Rodriguez',
      parentPhone: '+1 234 567 8906',
      emergencyContact: 'Carlos Rodriguez - +1 234 567 8907',
      medicalNotes: 'Lactose intolerant',
      status: StudentStatus.absent,
      busStop: 'Stop A4',
      seatNumber: '5',
      specialNeeds: ['Dietary restrictions'],
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
        title: const Text('Student Manifest'),
        backgroundColor: AppColors.driverColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Student List'),
            Tab(text: 'Route Map'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _exportManifest,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentListTab(),
          _buildRouteMapTab(),
        ],
      ),
    );
  }

  Widget _buildStudentListTab() {
    final filteredStudents = _getFilteredStudents();
    
    return Column(
      children: [
        // Search and Summary
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.surfaceVariant,
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Summary Stats
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Total', _students.length.toString(), AppColors.info)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(child: _buildSummaryCard('On Bus', _getStudentCount(StudentStatus.onBus).toString(), AppColors.success)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(child: _buildSummaryCard('Pending', _getStudentCount(StudentStatus.notPickedUp).toString(), AppColors.warning)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(child: _buildSummaryCard('Absent', _getStudentCount(StudentStatus.absent).toString(), AppColors.error)),
                ],
              ),
            ],
          ),
        ),

        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium, vertical: AppConstants.paddingSmall),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: StudentFilter.values.map((filter) => 
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getFilterLabel(filter)),
                    selected: _currentFilter == filter,
                    onSelected: (selected) => setState(() => _currentFilter = filter),
                    selectedColor: AppColors.driverColor.withOpacity(0.2),
                    checkmarkColor: AppColors.driverColor,
                  ),
                ),
              ).toList(),
            ),
          ),
        ),

        // Student List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
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

  Widget _buildStudentCard(Student student) {
    final statusColor = _getStatusColor(student.status);
    
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
                  backgroundColor: AppColors.driverColor.withOpacity(0.1),
                  child: student.photoUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.asset(
                            student.photoUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                Text(student.name[0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        )
                      : Text(
                          student.name[0],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.driverColor,
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              student.status.name.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${student.grade} • Seat ${student.seatNumber} • ${student.busStop}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (student.specialNeeds.isNotEmpty)
                        Text(
                          'Special needs: ${student.specialNeeds.join(', ')}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _showStudentDetails(student),
                      icon: const Icon(Icons.info_outline),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.info.withOpacity(0.1),
                        foregroundColor: AppColors.info,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _callParent(student),
                      icon: const Icon(Icons.phone),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.success.withOpacity(0.1),
                        foregroundColor: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Location Info
            Row(
              children: [
                Expanded(
                  child: _buildLocationInfo(
                    'Pickup',
                    student.pickupLocation,
                    student.pickupTime,
                    Icons.home,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _buildLocationInfo(
                    'Drop-off',
                    student.dropoffLocation,
                    student.dropoffTime,
                    Icons.school,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            
            if (student.status == StudentStatus.notPickedUp) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markAsPickedUp(student),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark as Picked Up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(String label, String location, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            location,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMapTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Route Map',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Interactive map showing all pickup/drop-off locations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton.icon(
            onPressed: _openRouteMap,
            icon: const Icon(Icons.map),
            label: const Text('Open Map View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.driverColor,
            ),
          ),
        ],
      ),
    );
  }

  List<Student> _getFilteredStudents() {
    var filtered = _students.where((student) {
      final matchesSearch = _searchQuery.isEmpty ||
          student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.grade.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _currentFilter == StudentFilter.all ||
          (_currentFilter == StudentFilter.onBus && student.status == StudentStatus.onBus) ||
          (_currentFilter == StudentFilter.pending && student.status == StudentStatus.notPickedUp) ||
          (_currentFilter == StudentFilter.absent && student.status == StudentStatus.absent) ||
          (_currentFilter == StudentFilter.droppedOff && student.status == StudentStatus.droppedOff) ||
          (_currentFilter == StudentFilter.specialNeeds && student.specialNeeds.isNotEmpty);
      
      return matchesSearch && matchesFilter;
    }).toList();
    
    // Sort by status priority
    filtered.sort((a, b) {
      const statusPriority = {
        StudentStatus.notPickedUp: 0,
        StudentStatus.onBus: 1,
        StudentStatus.droppedOff: 2,
        StudentStatus.absent: 3,
      };
      return statusPriority[a.status]!.compareTo(statusPriority[b.status]!);
    });
    
    return filtered;
  }

  int _getStudentCount(StudentStatus status) {
    return _students.where((student) => student.status == status).length;
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.notPickedUp:
        return AppColors.warning;
      case StudentStatus.onBus:
        return AppColors.success;
      case StudentStatus.droppedOff:
        return AppColors.info;
      case StudentStatus.absent:
        return AppColors.error;
    }
  }

  String _getFilterLabel(StudentFilter filter) {
    switch (filter) {
      case StudentFilter.all:
        return 'All';
      case StudentFilter.onBus:
        return 'On Bus';
      case StudentFilter.pending:
        return 'Pending';
      case StudentFilter.absent:
        return 'Absent';
      case StudentFilter.droppedOff:
        return 'Dropped Off';
      case StudentFilter.specialNeeds:
        return 'Special Needs';
    }
  }

  void _showStudentDetails(Student student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.driverColor.withOpacity(0.1),
                      child: Text(
                        student.name[0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.driverColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            student.grade,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Details
                _buildDetailRow('Parent', student.parentName),
                _buildDetailRow('Phone', student.parentPhone),
                _buildDetailRow('Emergency Contact', student.emergencyContact),
                _buildDetailRow('Medical Notes', student.medicalNotes),
                _buildDetailRow('Bus Stop', student.busStop),
                _buildDetailRow('Seat Number', student.seatNumber),
                
                if (student.specialNeeds.isNotEmpty)
                  _buildDetailRow('Special Needs', student.specialNeeds.join(', ')),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callParent(student),
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Parent'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.driverColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _markAsPickedUp(Student student) {
    setState(() {
      final index = _students.indexWhere((s) => s.id == student.id);
      if (index != -1) {
        _students[index] = student.copyWith(status: StudentStatus.onBus);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${student.name} marked as picked up'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _callParent(Student student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${student.parentName}...')),
    );
  }

  void _showFilterOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options will be implemented')),
    );
  }

  void _exportManifest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting manifest...')),
    );
  }

  void _openRouteMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening route map...')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum StudentStatus { notPickedUp, onBus, droppedOff, absent }
enum StudentFilter { all, onBus, pending, absent, droppedOff, specialNeeds }

class Student {
  final String id;
  final String name;
  final String grade;
  final String photoUrl;
  final String pickupLocation;
  final String dropoffLocation;
  final String pickupTime;
  final String dropoffTime;
  final String parentName;
  final String parentPhone;
  final String emergencyContact;
  final String medicalNotes;
  final StudentStatus status;
  final String busStop;
  final String seatNumber;
  final List<String> specialNeeds;

  Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.photoUrl,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupTime,
    required this.dropoffTime,
    required this.parentName,
    required this.parentPhone,
    required this.emergencyContact,
    required this.medicalNotes,
    required this.status,
    required this.busStop,
    required this.seatNumber,
    required this.specialNeeds,
  });

  Student copyWith({
    String? id,
    String? name,
    String? grade,
    String? photoUrl,
    String? pickupLocation,
    String? dropoffLocation,
    String? pickupTime,
    String? dropoffTime,
    String? parentName,
    String? parentPhone,
    String? emergencyContact,
    String? medicalNotes,
    StudentStatus? status,
    String? busStop,
    String? seatNumber,
    List<String>? specialNeeds,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      photoUrl: photoUrl ?? this.photoUrl,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupTime: pickupTime ?? this.pickupTime,
      dropoffTime: dropoffTime ?? this.dropoffTime,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      status: status ?? this.status,
      busStop: busStop ?? this.busStop,
      seatNumber: seatNumber ?? this.seatNumber,
      specialNeeds: specialNeeds ?? this.specialNeeds,
    );
  }
}
