import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/analytics_dashboard_screen.dart';
import '../widgets/cms_screen.dart';
import '../widgets/driver_management_screen.dart';
import '../widgets/financial_dashboard_screen.dart';
import '../widgets/firebase_user_management_screen.dart';
import '../widgets/notification_control_screen.dart';
import '../widgets/route_optimizer_screen.dart';
import '../widgets/school_approval_screen.dart';
import '../widgets/school_management_screen.dart';
import '../widgets/support_agent_screen.dart';
import '../widgets/vehicle_management_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  final List<DashboardItem> _dashboardItems = [
    DashboardItem(
      title: 'Overview',
      icon: Icons.dashboard,
      color: AppColors.superAdminColor,
    ),
    DashboardItem(
      title: 'Schools',
      icon: Icons.school,
      color: AppColors.primary,
    ),
    DashboardItem(
      title: 'Users',
      icon: Icons.people,
      color: AppColors.secondary,
    ),
    DashboardItem(
      title: 'Drivers',
      icon: Icons.person_pin,
      color: AppColors.driverColor,
    ),
    DashboardItem(
      title: 'Vehicles',
      icon: Icons.directions_bus,
      color: AppColors.warning,
    ),
    DashboardItem(
      title: 'Finances',
      icon: Icons.account_balance_wallet,
      color: AppColors.success,
    ),
    DashboardItem(
      title: 'School Approvals',
      icon: Icons.approval,
      color: AppColors.info,
    ),
    DashboardItem(
      title: 'Support Agents',
      icon: Icons.support_agent,
      color: AppColors.purple,
    ),
    DashboardItem(
      title: 'Analytics',
      icon: Icons.analytics,
      color: AppColors.teal,
    ),
    DashboardItem(
      title: 'Route Optimizer',
      icon: Icons.route,
      color: AppColors.orange,
    ),
    DashboardItem(
      title: 'Notifications',
      icon: Icons.notifications_active,
      color: AppColors.pink,
    ),
    DashboardItem(
      title: 'CMS',
      icon: Icons.content_paste,
      color: AppColors.indigo,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 280,
            color: AppColors.surface,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    color: AppColors.superAdminColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 32),
                      SizedBox(width: AppConstants.paddingMedium),
                      Text(
                        'Super Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.paddingMedium),
                    itemCount: _dashboardItems.length,
                    itemBuilder: (context, index) {
                      final item = _dashboardItems[index];
                      final isSelected = _selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingSmall, vertical: 2),
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected
                                ? item.color
                                : AppColors.textSecondary,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: isSelected
                                  ? item.color
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: item.color.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                // User Profile Section
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.superAdminColor,
                        child: const Text('SA',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Super Admin',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'admin@andco.com',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () {
                          // Handle logout
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewScreen();
      case 1:
        return const SchoolManagementScreen();
      case 2:
        return const FirebaseUserManagementScreen();
      case 3:
        return const DriverManagementScreen();
      case 4:
        return const VehicleManagementScreen();
      case 5:
        return const FinancialDashboardScreen();
      case 6:
        return const SchoolApprovalScreen();
      case 7:
        return const SupportAgentScreen();
      case 8:
        return const AnalyticsDashboardScreen();
      case 9:
        return const RouteOptimizerScreen();
      case 10:
        return const NotificationControlScreen();
      case 11:
        return const CMSScreen();
      default:
        return _buildOverviewScreen();
    }
  }

  Widget _buildOverviewScreen() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Quick Stats Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: AppConstants.paddingMedium,
                mainAxisSpacing: AppConstants.paddingMedium,
                childAspectRatio: 1.2,
              ),
              itemCount: _dashboardItems.length - 1, // Exclude overview
              itemBuilder: (context, index) {
                final item = _dashboardItems[index + 1];
                return _buildOverviewCard(item, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(DashboardItem item, int index) {
    // Mock data for demonstration
    final stats = _getStatsForItem(index);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index + 1;
          });
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 32,
                color: item.color,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                stats['count'].toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                stats['subtitle'],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatsForItem(int index) {
    // Real-time statistics from Firebase
    final statItems = [
      'Active Schools',
      'Total Users',
      'Active Drivers',
      'Fleet Vehicles',
      'Monthly Revenue',
      'Pending Approvals',
      'Support Agents',
      'System Uptime',
      'Optimized Routes',
      'Notifications Sent',
      'Content Items',
    ];

    if (index >= statItems.length) {
      return {'count': 0, 'subtitle': 'No Data'};
    }

    return {
      'count': _getStatValue(statItems[index]),
      'subtitle': statItems[index],
    };
  }

  dynamic _getStatValue(String statType) {
    // TODO: Replace with real Firebase queries
    switch (statType) {
      case 'Active Schools':
        return '...'; // Will be replaced with real count
      case 'Total Users':
        return '...'; // Will be replaced with real count
      case 'Active Drivers':
        return '...'; // Will be replaced with real count
      case 'Fleet Vehicles':
        return '...'; // Will be replaced with real count
      case 'Monthly Revenue':
        return '...'; // Will be replaced with real calculation
      case 'Pending Approvals':
        return '...'; // Will be replaced with real count
      case 'Support Agents':
        return '...'; // Will be replaced with real count
      case 'System Uptime':
        return '...'; // Will be replaced with real monitoring
      case 'Optimized Routes':
        return '...'; // Will be replaced with real count
      case 'Notifications Sent':
        return '...'; // Will be replaced with real count
      case 'Content Items':
        return '...'; // Will be replaced with real count
      default:
        return 0;
    }
  }
}

class DashboardItem {
  final String title;
  final IconData icon;
  final Color color;

  DashboardItem({
    required this.title,
    required this.icon,
    required this.color,
  });
}
