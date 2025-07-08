import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/andco_logo.dart';
import 'widgets/bus_management_screen.dart';
import 'widgets/driver_approval_screen.dart';
import 'widgets/feedback_management_screen.dart';
import 'widgets/incident_monitoring_screen.dart';
import 'widgets/reports_screen.dart';
import 'widgets/student_management_screen.dart';

class SchoolAdminDashboard extends StatefulWidget {
  const SchoolAdminDashboard({super.key});

  @override
  State<SchoolAdminDashboard> createState() => _SchoolAdminDashboardState();
}

class _SchoolAdminDashboardState extends State<SchoolAdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SchoolAdminHomeTab(),
    const SchoolAdminStudentsTab(),
    const SchoolAdminBusesTab(),
    const SchoolAdminReportsTab(),
    const SchoolAdminProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppColors.schoolAdminColor,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_outlined),
            activeIcon: Icon(Icons.directions_bus),
            label: 'Buses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class SchoolAdminHomeTab extends StatelessWidget {
  const SchoolAdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const AndcoLogo(size: 40, showShadow: false),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lincoln Elementary',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        Text(
                          'Admin Dashboard',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      context,
                      '342',
                      'Total Students',
                      Icons.school,
                      AppColors.info,
                      '+12 this month',
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: _buildOverviewCard(
                      context,
                      '8',
                      'Active Buses',
                      Icons.directions_bus,
                      AppColors.warning,
                      '2 on route',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      context,
                      '12',
                      'Drivers',
                      Icons.person,
                      AppColors.secondary,
                      'All active',
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: _buildOverviewCard(
                      context,
                      '98.5%',
                      'Attendance',
                      Icons.check_circle,
                      AppColors.success,
                      'This week',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.paddingMedium,
                mainAxisSpacing: AppConstants.paddingMedium,
                childAspectRatio: 1.5,
                children: [
                  _buildActionCard(
                    context,
                    'Add Student',
                    Icons.person_add,
                    AppColors.primary,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Assign Route',
                    Icons.route,
                    AppColors.secondary,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BusManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    'View Reports',
                    Icons.analytics,
                    AppColors.info,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Emergency Alert',
                    Icons.emergency,
                    AppColors.error,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const IncidentMonitoringScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Manage Drivers',
                    Icons.person_pin,
                    AppColors.warning,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriverApprovalScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    'View Feedback',
                    Icons.feedback,
                    AppColors.secondary,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const FeedbackManagementScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Recent Activities
              Text(
                'Recent Activities',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              _buildActivityCard(
                context,
                'New student enrolled',
                'Emma Thompson - Grade 4A',
                Icons.person_add,
                AppColors.success,
                '2 hours ago',
              ),

              _buildActivityCard(
                context,
                'Route updated',
                'Route 3 - Added new stop',
                Icons.route,
                AppColors.info,
                '4 hours ago',
              ),

              _buildActivityCard(
                context,
                'Driver approved',
                'John Smith - License verified',
                Icons.verified_user,
                AppColors.primary,
                '1 day ago',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    String value,
    String title,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppConstants.iconMedium,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}

class SchoolAdminStudentsTab extends StatelessWidget {
  const SchoolAdminStudentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentManagementScreen();
  }
}

class SchoolAdminBusesTab extends StatelessWidget {
  const SchoolAdminBusesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const BusManagementScreen();
  }
}

class SchoolAdminReportsTab extends StatelessWidget {
  const SchoolAdminReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportsScreen();
  }
}

class SchoolAdminProfileTab extends StatelessWidget {
  const SchoolAdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Admin Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Manage your admin profile and settings',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
