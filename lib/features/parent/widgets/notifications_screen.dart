import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Emma Picked Up',
      message: 'Emma has been picked up from home at 7:45 AM',
      type: NotificationType.pickup,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      childName: 'Emma Johnson',
      location: 'Maple Street, Home',
    ),
    NotificationItem(
      id: '2',
      title: 'Bus Arriving Soon',
      message: 'Bus BUS-001 will arrive at your stop in 3 minutes',
      type: NotificationType.eta,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      isRead: false,
      childName: 'Alex Johnson',
      location: 'Oak Avenue Stop',
    ),
    NotificationItem(
      id: '3',
      title: 'Alex Dropped Off',
      message: 'Alex has been safely dropped off at Lincoln Elementary',
      type: NotificationType.dropoff,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
      childName: 'Alex Johnson',
      location: 'Lincoln Elementary School',
    ),
    NotificationItem(
      id: '4',
      title: 'Route Delay',
      message: 'Bus BUS-001 is running 5 minutes late due to traffic',
      type: NotificationType.delay,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      childName: 'Emma Johnson',
      location: 'Main Street',
    ),
    NotificationItem(
      id: '5',
      title: 'Emergency Alert Resolved',
      message: 'The emergency situation has been resolved. All children are safe.',
      type: NotificationType.emergency,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      childName: 'All Children',
      location: 'System Wide',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Notification Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Notification Summary
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.parentColor.withOpacity(0.1),
                  AppColors.parentColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppColors.parentColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.parentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Alerts Active',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_notifications.where((n) => !n.isRead).length} unread notifications',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: true,
                  onChanged: (value) {
                    _toggleNotifications(value);
                  },
                  activeColor: AppColors.parentColor,
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      color: notification.isRead ? null : AppColors.primary.withOpacity(0.05),
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  notification.childName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    notification.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            if (notification.type == NotificationType.emergency)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'URGENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _markAsRead(notification),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.pickup:
        return AppColors.success;
      case NotificationType.dropoff:
        return AppColors.info;
      case NotificationType.eta:
        return AppColors.warning;
      case NotificationType.delay:
        return AppColors.warning;
      case NotificationType.emergency:
        return AppColors.error;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.pickup:
        return Icons.directions_bus;
      case NotificationType.dropoff:
        return Icons.school;
      case NotificationType.eta:
        return Icons.access_time;
      case NotificationType.delay:
        return Icons.schedule;
      case NotificationType.emergency:
        return Icons.emergency;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _markAsRead(NotificationItem notification) {
    setState(() {
      notification.isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _toggleNotifications(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enabled ? 'Notifications enabled' : 'Notifications disabled'),
        backgroundColor: enabled ? AppColors.success : AppColors.warning,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _showNotificationSettings();
        break;
      case 'clear':
        _clearAllNotifications();
        break;
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildSettingTile('Pickup Alerts', true),
            _buildSettingTile('Drop-off Alerts', true),
            _buildSettingTile('ETA Notifications', true),
            _buildSettingTile('Delay Alerts', true),
            _buildSettingTile('Emergency Alerts', true),
            _buildSettingTile('WhatsApp Notifications', false),
            _buildSettingTile('SMS Fallback', true),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(String title, bool value) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (newValue) {
        // Handle setting change
      },
      activeColor: AppColors.parentColor,
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

enum NotificationType {
  pickup,
  dropoff,
  eta,
  delay,
  emergency,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final String childName;
  final String location;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.childName,
    required this.location,
  });
}
