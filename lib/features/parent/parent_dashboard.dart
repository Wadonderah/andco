import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/andco_logo.dart';
import 'widgets/add_child_screen.dart';
import 'widgets/chat_screen.dart';
import 'widgets/driver_info_screen.dart';
import 'widgets/emergency_sos_screen.dart';
import 'widgets/live_tracking_map.dart';
import 'widgets/notifications_screen.dart';
import 'widgets/payment_screen.dart';
import 'widgets/ride_history_screen.dart';
import 'widgets/settings_screen.dart';

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
    const ParentChildrenTab(),
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care_outlined),
            activeIcon: Icon(Icons.child_care),
            label: 'Children',
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

class ParentHomeTab extends StatelessWidget {
  const ParentHomeTab({super.key});

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
                          'Good Morning!',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        Text(
                          'Sarah Johnson',
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
                        icon: const Icon(Icons.notifications_outlined),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceVariant,
                        ),
                      ),
                      // Notification badge
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      AppColors.secondary,
                      () {},
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'SOS Alert',
                      Icons.emergency,
                      AppColors.error,
                      () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Children Status
              Text(
                'Children Status',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              _buildChildStatusCard(
                context,
                'Emma Johnson',
                'Grade 5A',
                'On Bus - ETA 8:15 AM',
                Icons.directions_bus,
                AppColors.success,
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              _buildChildStatusCard(
                context,
                'Alex Johnson',
                'Grade 3B',
                'At School',
                Icons.school,
                AppColors.info,
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Recent Activity
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              _buildActivityCard(
                context,
                'Emma picked up',
                '7:45 AM - Maple Street',
                Icons.check_circle,
                AppColors.success,
              ),

              _buildActivityCard(
                context,
                'Alex dropped off',
                '8:10 AM - Lincoln Elementary',
                Icons.school,
                AppColors.info,
              ),

              _buildActivityCard(
                context,
                'Payment processed',
                'Monthly subscription - \$120',
                Icons.payment,
                AppColors.primary,
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: AppConstants.iconMedium,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.parentColor.withOpacity(0.1),
              child: Text(
                name[0],
                style: TextStyle(
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                color: statusColor.withOpacity(0.1),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildActivityCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
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
          'Just now',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}

class ParentTrackingTab extends StatelessWidget {
  const ParentTrackingTab({super.key});

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
              Text(
                'Live Bus Tracking',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                'Track your children\'s buses in real-time',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Active Buses
              Text(
                'Active Buses',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              _buildBusTrackingCard(
                context,
                'BUS-001',
                'Emma Johnson',
                'On Route - ETA 8 min',
                'Lincoln Elementary',
                AppColors.success,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LiveTrackingMap(
                        childId: 'emma_001',
                        busId: 'bus_001',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              _buildBusTrackingCard(
                context,
                'BUS-003',
                'Alex Johnson',
                'At School',
                'Lincoln Elementary',
                AppColors.info,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LiveTrackingMap(
                        childId: 'alex_002',
                        busId: 'bus_003',
                      ),
                    ),
                  );
                },
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
                      'Emergency\nSOS',
                      Icons.emergency,
                      AppColors.error,
                      () {
                        _showSOSDialog(context);
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'Call\nDriver',
                      Icons.phone,
                      AppColors.primary,
                      () {
                        _callDriver(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusTrackingCard(
    BuildContext context,
    String busNumber,
    String childName,
    String status,
    String destination,
    Color statusColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
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
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          busNumber,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          childName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Destination: $destination',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: AppConstants.iconMedium,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content:
            const Text('Are you sure you want to send an emergency alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent!'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  void _callDriver(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling driver...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class ParentChildrenTab extends StatefulWidget {
  const ParentChildrenTab({super.key});

  @override
  State<ParentChildrenTab> createState() => _ParentChildrenTabState();
}

class _ParentChildrenTabState extends State<ParentChildrenTab> {
  final List<Child> _children = [
    Child(
      id: '1',
      name: 'Emma Johnson',
      gender: 'Female',
      grade: '5A',
      school: 'Lincoln Elementary',
      emergencyContact: '+1 234 567 8900',
      bloodType: 'O+',
      hasAllergies: true,
      hasSpecialNeeds: false,
      medicalNotes: 'Allergic to peanuts',
      profileImagePath: '',
    ),
    Child(
      id: '2',
      name: 'Alex Johnson',
      gender: 'Male',
      grade: '3B',
      school: 'Lincoln Elementary',
      emergencyContact: '+1 234 567 8900',
      bloodType: 'A+',
      hasAllergies: false,
      hasSpecialNeeds: false,
      medicalNotes: '',
      profileImagePath: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Children',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${_children.length} children registered',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addChild,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Child'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.parentColor,
                    ),
                  ),
                ],
              ),
            ),

            // Children List
            Expanded(
              child: _children.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium),
                      itemCount: _children.length,
                      itemBuilder: (context, index) {
                        final child = _children[index];
                        return _buildChildCard(child);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.parentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.child_care_outlined,
              size: 64,
              color: AppColors.parentColor,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            'No Children Added',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Add your children\'s profiles to start tracking their school transport',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton.icon(
            onPressed: _addChild,
            icon: const Icon(Icons.add),
            label: const Text('Add First Child'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.parentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(Child child) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            Row(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.parentColor.withOpacity(0.1),
                  backgroundImage: child.profileImagePath.isNotEmpty
                      ? AssetImage(child.profileImagePath)
                      : null,
                  child: child.profileImagePath.isEmpty
                      ? Text(
                          child.name[0],
                          style: TextStyle(
                            color: AppColors.parentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppConstants.paddingMedium),

                // Child Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${child.grade} • ${child.school}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (child.hasAllergies)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Allergies',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (child.hasSpecialNeeds)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Special Needs',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  onSelected: (action) => _handleChildAction(action, child),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'track',
                      child: Row(
                        children: [
                          Icon(Icons.location_on),
                          SizedBox(width: 8),
                          Text('Track Bus'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'medical',
                      child: Row(
                        children: [
                          Icon(Icons.medical_information),
                          SizedBox(width: 8),
                          Text('Medical Info'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Quick Info Row
            Row(
              children: [
                _buildQuickInfo('Blood Type', child.bloodType, Icons.bloodtype),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildQuickInfo('Gender', child.gender, Icons.wc),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildQuickInfo(
                    'Emergency', child.emergencyContact, Icons.phone),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addChild() async {
    final result = await Navigator.of(context).push<Child>(
      MaterialPageRoute(
        builder: (context) => const AddChildScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _children.add(result);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _handleChildAction(String action, Child child) {
    switch (action) {
      case 'edit':
        _editChild(child);
        break;
      case 'track':
        _trackChild(child);
        break;
      case 'medical':
        _showMedicalInfo(child);
        break;
      case 'delete':
        _deleteChild(child);
        break;
    }
  }

  void _editChild(Child child) async {
    final result = await Navigator.of(context).push<Child>(
      MaterialPageRoute(
        builder: (context) => AddChildScreen(child: child),
      ),
    );

    if (result != null) {
      setState(() {
        final index = _children.indexWhere((c) => c.id == child.id);
        if (index != -1) {
          _children[index] = result;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _trackChild(Child child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LiveTrackingMap(
          childId: child.id,
          busId: 'bus_001',
        ),
      ),
    );
  }

  void _showMedicalInfo(Child child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${child.name} - Medical Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMedicalInfoRow('Blood Type', child.bloodType),
            _buildMedicalInfoRow(
                'Allergies', child.hasAllergies ? 'Yes' : 'No'),
            _buildMedicalInfoRow(
                'Special Needs', child.hasSpecialNeeds ? 'Yes' : 'No'),
            if (child.medicalNotes.isNotEmpty)
              _buildMedicalInfoRow('Notes', child.medicalNotes),
            _buildMedicalInfoRow('Emergency Contact', child.emergencyContact),
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

  Widget _buildMedicalInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _deleteChild(Child child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Child'),
        content: Text(
            'Are you sure you want to remove ${child.name} from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _children.removeWhere((c) => c.id == child.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${child.name} removed'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ParentProfileTab extends StatelessWidget {
  const ParentProfileTab({super.key});

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
              // Profile Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.parentColor.withOpacity(0.1),
                        child: const Text(
                          'SJ',
                          style: TextStyle(
                            color: AppColors.parentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sarah Johnson',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'sarah.johnson@email.com',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            Text(
                              '+1 234 567 8900',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.parentColor.withOpacity(0.1),
                          foregroundColor: AppColors.parentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Features Section
              Text(
                'Features & Services',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              _buildFeatureCard(
                context,
                'Driver & Vehicle Info',
                'View driver profiles and vehicle details',
                Icons.info_outline,
                AppColors.driverColor,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DriverInfoScreen(
                        driverId: 'driver_001',
                        busId: 'bus_001',
                      ),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                context,
                'Messages',
                'Chat with drivers and school staff',
                Icons.chat_bubble_outline,
                AppColors.info,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatListScreen(),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                context,
                'Ride History',
                'View detailed ride and attendance logs',
                Icons.history,
                AppColors.secondary,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RideHistoryScreen(),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                context,
                'Payments & Billing',
                'Manage subscriptions and payment methods',
                Icons.payment,
                AppColors.success,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PaymentScreen(),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                context,
                'Emergency SOS',
                'Quick access to emergency services',
                Icons.emergency,
                AppColors.error,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EmergencySOSScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Settings Section
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              _buildSettingsTile(
                context,
                'App Settings',
                'Theme, notifications, and preferences',
                Icons.settings,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),

              _buildSettingsTile(
                context,
                'Privacy & Security',
                'Account security and privacy settings',
                Icons.security,
                () {},
              ),

              _buildSettingsTile(
                context,
                'Help & Support',
                'Get help and contact support',
                Icons.help_outline,
                () {},
              ),

              _buildSettingsTile(
                context,
                'About',
                'App version and legal information',
                Icons.info_outline,
                () {},
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
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
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
