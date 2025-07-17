import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/andco_logo.dart';
import 'widgets/emergency_sos_screen.dart';
import 'widgets/enhanced_child_management_screen.dart';
import 'widgets/enhanced_payment_screen.dart';
import 'widgets/enhanced_settings_screen.dart';
import 'widgets/live_tracking_map.dart';
import 'widgets/notifications_screen.dart';
import 'widgets/support_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ParentHomeTab(),
    const ParentTrackingTab(),
    const EnhancedChildManagementScreen(),
    const ParentProfileTab(),
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
        selectedItemColor: AppColors.parentColor,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care),
            label: 'Children',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ParentHomeTab extends ConsumerStatefulWidget {
  const ParentHomeTab({super.key});

  @override
  ConsumerState<ParentHomeTab> createState() => _ParentHomeTabState();
}

class _ParentHomeTabState extends ConsumerState<ParentHomeTab> {
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
              // Header with logo and notifications
              Row(
                children: [
                  const AndcoLogo(size: 40),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Track your children\'s safe journey',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'Track Bus',
                      Icons.location_on,
                      AppColors.primary,
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LiveTrackingMap(
                            childId: 'default',
                            busId: 'default',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'Emergency',
                      Icons.emergency,
                      AppColors.error,
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EmergencySOSScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'Payments',
                      Icons.payment,
                      AppColors.success,
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EnhancedPaymentScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'Support',
                      Icons.support_agent,
                      AppColors.info,
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ParentSupportScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Children Status - Real Firebase Data
              Text(
                'Children Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              // Real-time children status from Firebase
              _buildChildrenStatusSection(),

              const SizedBox(height: AppConstants.paddingLarge),

              // Recent Activity - Real Firebase Data
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              _buildRecentActivitySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenStatusSection() {
    final user = FirebaseService.instance.auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view children status'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getChildrenStatusStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final children = snapshot.data ?? [];

        if (children.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                children: [
                  Icon(
                    Icons.child_care_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'No children added yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Add your children to start tracking their journey',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: children
              .map((child) => _buildChildStatusCard(
                    context,
                    child['name'] ?? 'Unknown',
                    child['grade'] ?? 'Unknown Grade',
                    child['status'] ?? 'Unknown Status',
                    _getStatusIcon(child['status']),
                    _getStatusColor(child['status']),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildChildStatusCard(
    BuildContext context,
    String name,
    String grade,
    String status,
    IconData icon,
    Color statusColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.parentColor.withValues(alpha: 0.1),
              child: Text(
                name[0],
                style: const TextStyle(
                  color: AppColors.parentColor,
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
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    grade,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final user = FirebaseService.instance.auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view recent activity'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getRecentActivityStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'No recent activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Activity will appear here once your children start using the transport service',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: activities
              .take(5)
              .map((activity) => _buildActivityCard(
                    context,
                    activity['title'] ?? 'Unknown Activity',
                    activity['description'] ?? 'No description',
                    _getActivityIcon(activity['type']),
                    _getActivityColor(activity['type']),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
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
        subtitle: Text(description),
        trailing: Text(
          _formatTime(DateTime.now()),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }

  // Helper methods for real Firebase data
  Stream<List<Map<String, dynamic>>> _getChildrenStatusStream(String parentId) {
    return FirebaseService.instance.firestore
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  Stream<List<Map<String, dynamic>>> _getRecentActivityStream(String parentId) {
    return FirebaseService.instance.firestore
        .collection('activities')
        .where('parentId', isEqualTo: parentId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'on_bus':
        return Icons.directions_bus;
      case 'at_school':
        return Icons.school;
      case 'at_home':
        return Icons.home;
      case 'picked_up':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'on_bus':
        return AppColors.warning;
      case 'at_school':
        return AppColors.info;
      case 'at_home':
        return AppColors.success;
      case 'picked_up':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pickup':
        return Icons.directions_bus;
      case 'dropoff':
        return Icons.school;
      case 'payment':
        return Icons.payment;
      case 'notification':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'pickup':
        return AppColors.primary;
      case 'dropoff':
        return AppColors.success;
      case 'payment':
        return AppColors.warning;
      case 'notification':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class ParentTrackingTab extends StatelessWidget {
  const ParentTrackingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const LiveTrackingMap(
      childId: 'default',
      busId: 'default',
    );
  }
}

// Use the enhanced child management screen with real Firebase data
class ParentChildrenTab extends StatelessWidget {
  const ParentChildrenTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnhancedChildManagementScreen();
  }
}

class ParentProfileTab extends StatelessWidget {
  const ParentProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnhancedSettingsScreen();
  }
}
