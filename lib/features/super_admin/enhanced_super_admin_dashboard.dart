import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/loading_overlay.dart';
import 'widgets/financial_oversight_screen.dart';
import 'widgets/platform_analytics_screen.dart';
import 'widgets/school_approval_screen.dart';
import 'widgets/super_admin_settings_screen.dart';
import 'widgets/support_management_screen.dart';
import 'widgets/system_monitoring_screen.dart';
import 'widgets/user_moderation_screen.dart';

class EnhancedSuperAdminDashboard extends ConsumerStatefulWidget {
  const EnhancedSuperAdminDashboard({super.key});

  @override
  ConsumerState<EnhancedSuperAdminDashboard> createState() =>
      _EnhancedSuperAdminDashboardState();
}

class _EnhancedSuperAdminDashboardState
    extends ConsumerState<EnhancedSuperAdminDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;
  int _selectedIndex = 0;

  final List<DashboardTab> _tabs = [
    DashboardTab(
      title: 'Overview',
      icon: Icons.dashboard,
      widget: const SuperAdminOverviewTab(),
    ),
    DashboardTab(
      title: 'Schools',
      icon: Icons.school,
      widget: const SchoolApprovalScreen(),
    ),
    DashboardTab(
      title: 'Users',
      icon: Icons.people,
      widget: const UserModerationScreen(),
    ),
    DashboardTab(
      title: 'Analytics',
      icon: Icons.analytics,
      widget: const PlatformAnalyticsScreen(),
    ),
    DashboardTab(
      title: 'Financial',
      icon: Icons.attach_money,
      widget: const FinancialOversightScreen(),
    ),
    DashboardTab(
      title: 'Support',
      icon: Icons.support_agent,
      widget: const SupportManagementScreen(),
    ),
    DashboardTab(
      title: 'Monitoring',
      icon: Icons.monitor,
      widget: const SystemMonitoringScreen(),
    ),
    DashboardTab(
      title: 'Settings',
      icon: Icons.settings,
      widget: const SuperAdminSettingsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Super Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Platform Controller',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.superAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showSystemAlerts(),
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showQuickActions(),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: authState.when(
          data: (user) => user != null
              ? _buildSuperAdminContent(user)
              : _buildUnauthorizedAccess(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSuperAdminContent(user) {
    // Verify Super Admin access
    if (user.email != 'admin@andco.com' || user.role != 'super_admin') {
      return _buildUnauthorizedAccess();
    }

    return Column(
      children: [
        // System Status Bar
        _buildSystemStatusBar(),

        // Main Content
        Expanded(
          child: _tabs[_selectedIndex].widget,
        ),
      ],
    );
  }

  Widget _buildSystemStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.superAdminColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          _buildStatusIndicator('System', 'Online', AppColors.success),
          const SizedBox(width: 16),
          _buildStatusIndicator('Database', 'Healthy', AppColors.success),
          const SizedBox(width: 16),
          _buildStatusIndicator('API', 'Operational', AppColors.success),
          const Spacer(),
          Text(
            'Last Updated: ${DateTime.now().toString().substring(11, 16)}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String status, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $status',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.superAdminColor,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: Colors.white,
      elevation: 8,
      items: _tabs.take(4).map((tab) {
        return BottomNavigationBarItem(
          icon: Icon(tab.icon),
          label: tab.title,
        );
      }).toList()
        ..add(
          BottomNavigationBarItem(
            icon: PopupMenuButton<int>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              itemBuilder: (context) => _tabs.skip(4).map((tab) {
                final index = _tabs.indexOf(tab);
                return PopupMenuItem<int>(
                  value: index,
                  child: Row(
                    children: [
                      Icon(tab.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(tab.title),
                    ],
                  ),
                );
              }).toList(),
            ),
            label: 'More',
          ),
        ),
    );
  }

  Widget _buildUnauthorizedAccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Unauthorized Access',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Super Admin access is restricted to authorized personnel only.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showSystemAlerts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('System alerts functionality coming soon')),
    );
  }

  void _showQuickActions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick actions functionality coming soon')),
    );
  }
}

class DashboardTab {
  final String title;
  final IconData icon;
  final Widget widget;

  DashboardTab({
    required this.title,
    required this.icon,
    required this.widget,
  });
}

class SuperAdminOverviewTab extends StatelessWidget {
  const SuperAdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildExecutiveDashboard(),
        ],
      ),
    );
  }

  Widget _buildExecutiveDashboard() {
    return Column(
      children: [
        // Key Metrics Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                '\$125.4K',
                Icons.attach_money,
                AppColors.success,
                '+12.5%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Active Users',
                '2,847',
                Icons.people,
                AppColors.info,
                '+8.2%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Schools',
                '156',
                Icons.school,
                AppColors.superAdminColor,
                '+5.1%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Fleet Size',
                '298',
                Icons.directions_bus,
                AppColors.warning,
                '+2.3%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Quick Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildActionChip('Approve Schools', Icons.approval, () {}),
                    _buildActionChip('View Reports', Icons.analytics, () {}),
                    _buildActionChip(
                        'System Health', Icons.health_and_safety, () {}),
                    _buildActionChip(
                        'User Support', Icons.support_agent, () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String change) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
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

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.superAdminColor.withOpacity(0.1),
    );
  }
}
