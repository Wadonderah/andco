import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/firebase_providers.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/models/user_model.dart';

/// Example dashboard showing how to use all Firebase features
class FirebaseDashboardExample extends ConsumerWidget {
  const FirebaseDashboardExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: currentUser.when(
        data: (UserModel? user) {
          if (user != null) {
            return _buildDashboard(context, ref, user);
          } else {
            return _buildLoginPrompt(context);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Please log in to view dashboard',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfo(user),
          const SizedBox(height: 24),
          if (user.role == UserRole.parent) ...[
            _buildChildrenSection(ref, user.uid),
            const SizedBox(height: 24),
          ],
          if (user.role == UserRole.schoolAdmin ||
              user.role == UserRole.superAdmin) ...[
            _buildSchoolBusesSection(ref, user.schoolId ?? ''),
            const SizedBox(height: 24),
            _buildSchoolRoutesSection(ref, user.schoolId ?? ''),
            const SizedBox(height: 24),
          ],
          _buildNotificationsSection(ref, user.uid),
          const SizedBox(height: 24),
          _buildFirebaseActionsSection(ref, user),
        ],
      ),
    );
  }

  Widget _buildUserInfo(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user.name}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Role: ${user.role.toString().split('.').last}'),
            Text('Email: ${user.email}'),
            if (user.phoneNumber != null) Text('Phone: ${user.phoneNumber}'),
            if (user.schoolId != null) Text('School ID: ${user.schoolId}'),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenSection(WidgetRef ref, String parentId) {
    final children = ref.watch(userChildrenStreamProvider(parentId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Children',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            children.when(
              data: (childrenList) => childrenList.isEmpty
                  ? const Text('No children registered')
                  : Column(
                      children: childrenList
                          .map((child) => ListTile(
                                leading: CircleAvatar(
                                  child: Text(child.name[0]),
                                ),
                                title: Text(child.name),
                                subtitle: Text(
                                    'Grade: ${child.grade} | Class: ${child.className}'),
                                trailing: child.hasTransportAssigned
                                    ? const Icon(Icons.directions_bus,
                                        color: Colors.green)
                                    : const Icon(Icons.warning,
                                        color: Colors.orange),
                              ))
                          .toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading children: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolBusesSection(WidgetRef ref, String schoolId) {
    final buses = ref.watch(schoolBusesStreamProvider(schoolId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'School Buses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            buses.when(
              data: (busList) => busList.isEmpty
                  ? const Text('No buses registered')
                  : Column(
                      children: busList
                          .take(3)
                          .map((bus) => ListTile(
                                leading: Icon(
                                  Icons.directions_bus,
                                  color: bus.isOperational
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                title: Text('Bus ${bus.licensePlate}'),
                                subtitle: Text(
                                    '${bus.model} | Capacity: ${bus.capacity}'),
                                trailing:
                                    Text(bus.status.toString().split('.').last),
                              ))
                          .toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading buses: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolRoutesSection(WidgetRef ref, String schoolId) {
    final routes = ref.watch(schoolRoutesStreamProvider(schoolId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'School Routes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            routes.when(
              data: (routesList) => routesList.isEmpty
                  ? const Text('No routes configured')
                  : Column(
                      children: routesList
                          .take(3)
                          .map((route) => ListTile(
                                leading:
                                    const Icon(Icons.route, color: Colors.blue),
                                title: Text(route.name),
                                subtitle: Text(
                                    '${route.stops.length} stops | ${route.estimatedDuration} min'),
                                trailing: route.isActive
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : const Icon(Icons.pause_circle,
                                        color: Colors.orange),
                              ))
                          .toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading routes: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(WidgetRef ref, String userId) {
    final notifications = ref.watch(userNotificationsStreamProvider(userId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            notifications.when(
              data: (notificationsList) => notificationsList.isEmpty
                  ? const Text('No notifications')
                  : Column(
                      children: notificationsList
                          .take(3)
                          .map((notification) => ListTile(
                                leading: Icon(
                                  _getNotificationIcon(notification.type),
                                  color: notification.isRead
                                      ? Colors.grey
                                      : Colors.blue,
                                ),
                                title: Text(notification.title),
                                subtitle: Text(notification.body),
                                trailing: Text(
                                  _formatTime(notification.createdAt),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ))
                          .toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) =>
                  Text('Error loading notifications: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseActionsSection(WidgetRef ref, UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _testNotification(ref, user),
                  icon: const Icon(Icons.notifications),
                  label: const Text('Test Notification'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _logAnalyticsEvent(ref),
                  icon: const Icon(Icons.analytics),
                  label: const Text('Log Event'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _uploadTestFile(ref),
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload File'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _generateReport(ref),
                  icon: const Icon(Icons.report),
                  label: const Text('Generate Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.pickupAlert:
        return Icons.directions_bus;
      case NotificationType.dropoffAlert:
        return Icons.school;
      case NotificationType.emergencyAlert:
        return Icons.emergency;
      case NotificationType.paymentStatus:
        return Icons.payment;
      case NotificationType.maintenanceAlert:
        return Icons.build;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.incident:
        return Icons.warning;
      case NotificationType.report:
        return Icons.assessment;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _testNotification(WidgetRef ref, UserModel user) async {
    try {
      final notificationService = ref.read(sendNotificationProvider);
      await notificationService.sendNotificationRequest(
        type: 'test_notification',
        data: {
          'title': 'Test Notification',
          'body': 'This is a test notification from Firebase!',
          'test': 'true',
        },
        userIds: [user.uid],
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  Future<void> _logAnalyticsEvent(WidgetRef ref) async {
    final analyticsLogger = ref.read(analyticsLoggerProvider);
    analyticsLogger('dashboard_action', {
      'action': 'test_analytics',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _uploadTestFile(WidgetRef ref) async {
    // This would typically open a file picker
    debugPrint('File upload would be implemented here');
  }

  Future<void> _generateReport(WidgetRef ref) async {
    final generateReport = ref.read(generateReportProvider);
    await generateReport('attendance', {
      'startDate': DateTime.now().subtract(const Duration(days: 30)),
      'endDate': DateTime.now(),
    });
  }
}
