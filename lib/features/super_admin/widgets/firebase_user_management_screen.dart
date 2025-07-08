import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/role_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/user_model.dart';

class FirebaseUserManagementScreen extends StatefulWidget {
  const FirebaseUserManagementScreen({super.key});

  @override
  State<FirebaseUserManagementScreen> createState() => _FirebaseUserManagementScreenState();
}

class _FirebaseUserManagementScreenState extends State<FirebaseUserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UserRole? _filterRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final users = await RoleNavigationService.instance.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load users: $e');
    }
  }

  List<UserModel> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _filterRole == null || user.role == _filterRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.superAdminColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search users...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          // Role filter
          Row(
            children: [
              const Text('Filter by role: '),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                child: DropdownButton<UserRole?>(
                  value: _filterRole,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<UserRole?>(
                      value: null,
                      child: Text('All Roles'),
                    ),
                    ...UserRole.values.map((role) => DropdownMenuItem<UserRole?>(
                      value: role,
                      child: Text(role.toString().split('.').last),
                    )),
                  ],
                  onChanged: (value) => setState(() => _filterRole = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    final filteredUsers = _filteredUsers;
    
    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text('No users found'),
      );
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text(
              user.roleDisplayName,
              style: TextStyle(
                color: _getRoleColor(user.role),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit_role',
              child: Text('Change Role'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete User'),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return AppColors.parentColor;
      case UserRole.driver:
        return AppColors.driverColor;
      case UserRole.schoolAdmin:
        return AppColors.schoolAdminColor;
      case UserRole.superAdmin:
        return AppColors.superAdminColor;
    }
  }

  void _handleUserAction(String action, UserModel user) {
    switch (action) {
      case 'edit_role':
        _showChangeRoleDialog(user);
        break;
      case 'delete':
        _showDeleteUserDialog(user);
        break;
    }
  }

  void _showChangeRoleDialog(UserModel user) {
    UserRole? selectedRole = user.role;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${user.name}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) => RadioListTile<UserRole>(
              title: Text(role.toString().split('.').last),
              value: role,
              groupValue: selectedRole,
              onChanged: (value) => setState(() => selectedRole = value),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedRole != null && selectedRole != user.role) {
                try {
                  await RoleNavigationService.instance.updateUserRole(user.uid, selectedRole!);
                  Navigator.of(context).pop();
                  _loadUsers(); // Refresh the list
                  _showSuccess('User role updated successfully');
                } catch (e) {
                  _showError('Failed to update user role: $e');
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await RoleNavigationService.instance.deleteUser(user.uid);
                Navigator.of(context).pop();
                _loadUsers(); // Refresh the list
                _showSuccess('User deleted successfully');
              } catch (e) {
                _showError('Failed to delete user: $e');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
