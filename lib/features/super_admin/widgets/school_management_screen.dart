import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class SchoolManagementScreen extends StatefulWidget {
  const SchoolManagementScreen({super.key});

  @override
  State<SchoolManagementScreen> createState() => _SchoolManagementScreenState();
}

class _SchoolManagementScreenState extends State<SchoolManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SchoolStatus _selectedStatus = SchoolStatus.all;

  final List<School> _schools = [
    School(
      id: '1',
      name: 'Greenwood Elementary',
      address: '123 Oak Street, Springfield',
      contactEmail: 'admin@greenwood.edu',
      contactPhone: '+1 555-0101',
      principalName: 'Dr. Sarah Johnson',
      studentCount: 450,
      busCount: 8,
      driverCount: 12,
      status: SchoolStatus.active,
      subscriptionPlan: 'Premium',
      monthlyRevenue: 2500.00,
      joinDate: DateTime(2023, 1, 15),
      lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
      coordinates: {'lat': 39.7817, 'lng': -89.6501},
      documents: ['License', 'Insurance', 'Accreditation'],
    ),
    School(
      id: '2',
      name: 'Riverside High School',
      address: '456 River Road, Riverside',
      contactEmail: 'contact@riverside.edu',
      contactPhone: '+1 555-0102',
      principalName: 'Mr. Michael Chen',
      studentCount: 1200,
      busCount: 15,
      driverCount: 20,
      status: SchoolStatus.active,
      subscriptionPlan: 'Enterprise',
      monthlyRevenue: 5000.00,
      joinDate: DateTime(2022, 8, 20),
      lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
      coordinates: {'lat': 39.7901, 'lng': -89.6440},
      documents: ['License', 'Insurance', 'Accreditation', 'Safety Certificate'],
    ),
    School(
      id: '3',
      name: 'Sunset Academy',
      address: '789 Sunset Blvd, Westside',
      contactEmail: 'info@sunset.edu',
      contactPhone: '+1 555-0103',
      principalName: 'Ms. Emily Rodriguez',
      studentCount: 300,
      busCount: 5,
      driverCount: 8,
      status: SchoolStatus.suspended,
      subscriptionPlan: 'Basic',
      monthlyRevenue: 1200.00,
      joinDate: DateTime(2023, 5, 10),
      lastActivity: DateTime.now().subtract(const Duration(days: 7)),
      coordinates: {'lat': 39.7750, 'lng': -89.6650},
      documents: ['License', 'Insurance'],
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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'School Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showAddSchoolDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add School'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                // Search and Filter Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search schools...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: DropdownButtonFormField<SchoolStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status Filter',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        items: SchoolStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.paddingMedium),
                
                // Stats Row
                Row(
                  children: [
                    _buildStatCard('Total Schools', _schools.length.toString(), AppColors.primary),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard('Active', _getSchoolCount(SchoolStatus.active).toString(), AppColors.success),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard('Pending', _getSchoolCount(SchoolStatus.pending).toString(), AppColors.warning),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard('Suspended', _getSchoolCount(SchoolStatus.suspended).toString(), AppColors.error),
                  ],
                ),
              ],
            ),
          ),
          
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'All Schools'),
                Tab(text: 'Performance'),
                Tab(text: 'Financial'),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSchoolsList(),
                _buildPerformanceTab(),
                _buildFinancialTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
        ),
      ),
    );
  }

  Widget _buildSchoolsList() {
    final filteredSchools = _getFilteredSchools();
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: filteredSchools.length,
      itemBuilder: (context, index) {
        final school = filteredSchools[index];
        return _buildSchoolCard(school);
      },
    );
  }

  Widget _buildSchoolCard(School school) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(school.status),
                  child: Text(
                    school.name[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        school.address,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        'Principal: ${school.principalName}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(school.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    school.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(school.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            
            // School Stats
            Row(
              children: [
                _buildSchoolStat(Icons.people, '${school.studentCount} Students'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildSchoolStat(Icons.directions_bus, '${school.busCount} Buses'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildSchoolStat(Icons.person, '${school.driverCount} Drivers'),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildSchoolStat(Icons.attach_money, '\$${school.monthlyRevenue.toStringAsFixed(0)}/mo'),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Action Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewSchoolDetails(school),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
                TextButton.icon(
                  onPressed: () => _editSchool(school),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _manageSchoolUsers(school),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Manage Users'),
                ),
                const Spacer(),
                if (school.status == SchoolStatus.active)
                  TextButton.icon(
                    onPressed: () => _suspendSchool(school),
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('Suspend'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.warning),
                  )
                else if (school.status == SchoolStatus.suspended)
                  TextButton.icon(
                    onPressed: () => _activateSchool(school),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Activate'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.success),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'School Performance Metrics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.paddingMedium,
              mainAxisSpacing: AppConstants.paddingMedium,
              children: _schools.map((school) => _buildPerformanceCard(school)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(School school) {
    final efficiency = (school.studentCount / school.busCount).round();
    final utilization = (school.driverCount / school.busCount * 100).round();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              school.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            
            _buildMetricRow('Students per Bus', '$efficiency'),
            _buildMetricRow('Driver Utilization', '$utilization%'),
            _buildMetricRow('Revenue per Student', '\$${(school.monthlyRevenue / school.studentCount).toStringAsFixed(2)}'),
            _buildMetricRow('Last Activity', _formatLastActivity(school.lastActivity)),
            
            const Spacer(),
            LinearProgressIndicator(
              value: utilization / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                utilization > 80 ? AppColors.success : 
                utilization > 60 ? AppColors.warning : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    final totalRevenue = _schools.fold<double>(0, (sum, school) => sum + school.monthlyRevenue);
    final averageRevenue = totalRevenue / _schools.length;
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Financial Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Total Monthly Revenue: \$${totalRevenue.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Revenue Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildRevenueCard('Total Revenue', '\$${totalRevenue.toStringAsFixed(2)}', AppColors.success),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildRevenueCard('Average Revenue', '\$${averageRevenue.toStringAsFixed(2)}', AppColors.info),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildRevenueCard('Active Schools', '${_getSchoolCount(SchoolStatus.active)}', AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // School Revenue List
          Expanded(
            child: ListView.builder(
              itemCount: _schools.length,
              itemBuilder: (context, index) {
                final school = _schools[index];
                return _buildRevenueListItem(school);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String title, String value, Color color) {
    return Container(
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueListItem(School school) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(school.status),
          child: Text(school.name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(school.name),
        subtitle: Text('${school.subscriptionPlan} Plan • ${school.studentCount} students'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${school.monthlyRevenue.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
            Text(
              'per month',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  List<School> _getFilteredSchools() {
    return _schools.where((school) {
      final matchesSearch = _searchQuery.isEmpty ||
          school.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          school.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          school.principalName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _selectedStatus == SchoolStatus.all || school.status == _selectedStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  int _getSchoolCount(SchoolStatus status) {
    return _schools.where((school) => school.status == status).length;
  }

  Color _getStatusColor(SchoolStatus status) {
    switch (status) {
      case SchoolStatus.active:
        return AppColors.success;
      case SchoolStatus.pending:
        return AppColors.warning;
      case SchoolStatus.suspended:
        return AppColors.error;
      case SchoolStatus.all:
        return AppColors.primary;
    }
  }

  String _formatLastActivity(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Action Methods
  void _showAddSchoolDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New School'),
        content: const Text('Add new school functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _viewSchoolDetails(School school) {
    // Navigate to detailed school view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(school.name),
        content: Text('Detailed view for ${school.name} would be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editSchool(School school) {
    // Navigate to edit school form
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${school.name}'),
        content: Text('Edit form for ${school.name} would be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _manageSchoolUsers(School school) {
    // Navigate to user management for this school
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Users - ${school.name}'),
        content: Text('User management for ${school.name} would be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _suspendSchool(School school) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend School'),
        content: Text('Are you sure you want to suspend ${school.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index = _schools.indexWhere((s) => s.id == school.id);
                if (index != -1) {
                  _schools[index] = school.copyWith(status: SchoolStatus.suspended);
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${school.name} has been suspended')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _activateSchool(School school) {
    setState(() {
      final index = _schools.indexWhere((s) => s.id == school.id);
      if (index != -1) {
        _schools[index] = school.copyWith(status: SchoolStatus.active);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${school.name} has been activated')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Data Models
enum SchoolStatus {
  all('All'),
  active('Active'),
  pending('Pending'),
  suspended('Suspended');

  const SchoolStatus(this.displayName);
  final String displayName;
}

class School {
  final String id;
  final String name;
  final String address;
  final String contactEmail;
  final String contactPhone;
  final String principalName;
  final int studentCount;
  final int busCount;
  final int driverCount;
  final SchoolStatus status;
  final String subscriptionPlan;
  final double monthlyRevenue;
  final DateTime joinDate;
  final DateTime lastActivity;
  final Map<String, double> coordinates;
  final List<String> documents;

  School({
    required this.id,
    required this.name,
    required this.address,
    required this.contactEmail,
    required this.contactPhone,
    required this.principalName,
    required this.studentCount,
    required this.busCount,
    required this.driverCount,
    required this.status,
    required this.subscriptionPlan,
    required this.monthlyRevenue,
    required this.joinDate,
    required this.lastActivity,
    required this.coordinates,
    required this.documents,
  });

  School copyWith({
    String? id,
    String? name,
    String? address,
    String? contactEmail,
    String? contactPhone,
    String? principalName,
    int? studentCount,
    int? busCount,
    int? driverCount,
    SchoolStatus? status,
    String? subscriptionPlan,
    double? monthlyRevenue,
    DateTime? joinDate,
    DateTime? lastActivity,
    Map<String, double>? coordinates,
    List<String>? documents,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      principalName: principalName ?? this.principalName,
      studentCount: studentCount ?? this.studentCount,
      busCount: busCount ?? this.busCount,
      driverCount: driverCount ?? this.driverCount,
      status: status ?? this.status,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      joinDate: joinDate ?? this.joinDate,
      lastActivity: lastActivity ?? this.lastActivity,
      coordinates: coordinates ?? this.coordinates,
      documents: documents ?? this.documents,
    );
  }
}
