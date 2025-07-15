import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/user_model.dart';
import '../services/firebase_service.dart';

/// Provider for onboarding completion state
final onboardingStateProvider = StateNotifierProvider<OnboardingStateNotifier, OnboardingState>((ref) {
  return OnboardingStateNotifier();
});

/// Onboarding state model
class OnboardingState {
  final bool isFirstTime;
  final bool hasCompletedOnboarding;
  final bool hasRequestedPermissions;
  final UserRole? selectedRole;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.isFirstTime = true,
    this.hasCompletedOnboarding = false,
    this.hasRequestedPermissions = false,
    this.selectedRole,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    bool? isFirstTime,
    bool? hasCompletedOnboarding,
    bool? hasRequestedPermissions,
    UserRole? selectedRole,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      isFirstTime: isFirstTime ?? this.isFirstTime,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasRequestedPermissions: hasRequestedPermissions ?? this.hasRequestedPermissions,
      selectedRole: selectedRole ?? this.selectedRole,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Onboarding state notifier
class OnboardingStateNotifier extends StateNotifier<OnboardingState> {
  OnboardingStateNotifier() : super(const OnboardingState()) {
    _loadOnboardingState();
  }

  static const String _keyFirstTime = 'is_first_time';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyPermissionsRequested = 'permissions_requested';
  static const String _keySelectedRole = 'selected_role';

  /// Load onboarding state from local storage
  Future<void> _loadOnboardingState() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isFirstTime = prefs.getBool(_keyFirstTime) ?? true;
      final hasCompletedOnboarding = prefs.getBool(_keyOnboardingCompleted) ?? false;
      final hasRequestedPermissions = prefs.getBool(_keyPermissionsRequested) ?? false;
      final selectedRoleString = prefs.getString(_keySelectedRole);
      
      UserRole? selectedRole;
      if (selectedRoleString != null) {
        selectedRole = UserRole.values.firstWhere(
          (role) => role.toString() == selectedRoleString,
          orElse: () => UserRole.parent,
        );
      }

      state = OnboardingState(
        isFirstTime: isFirstTime,
        hasCompletedOnboarding: hasCompletedOnboarding,
        hasRequestedPermissions: hasRequestedPermissions,
        selectedRole: selectedRole,
        isLoading: false,
      );

      // Log analytics event
      await FirebaseService.instance.logEvent('onboarding_state_loaded', {
        'is_first_time': isFirstTime,
        'has_completed_onboarding': hasCompletedOnboarding,
        'has_requested_permissions': hasRequestedPermissions,
        'selected_role': selectedRoleString ?? 'none',
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load onboarding state: $e',
      );
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOnboardingCompleted, true);
      await prefs.setBool(_keyFirstTime, false);
      
      state = state.copyWith(
        hasCompletedOnboarding: true,
        isFirstTime: false,
      );

      // Log analytics event
      await FirebaseService.instance.logEvent('onboarding_completed', {
        'selected_role': state.selectedRole?.toString() ?? 'none',
        'completion_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      state = state.copyWith(error: 'Failed to save onboarding completion: $e');
    }
  }

  /// Mark permissions as requested
  Future<void> markPermissionsRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPermissionsRequested, true);
      
      state = state.copyWith(hasRequestedPermissions: true);

      // Log analytics event
      await FirebaseService.instance.logEvent('permissions_requested', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      state = state.copyWith(error: 'Failed to save permissions state: $e');
    }
  }

  /// Set selected role
  Future<void> setSelectedRole(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedRole, role.toString());
      
      state = state.copyWith(selectedRole: role);

      // Log analytics event
      await FirebaseService.instance.logEvent('role_selected', {
        'role': role.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      state = state.copyWith(error: 'Failed to save selected role: $e');
    }
  }

  /// Reset onboarding state (for testing or user reset)
  Future<void> resetOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyFirstTime);
      await prefs.remove(_keyOnboardingCompleted);
      await prefs.remove(_keyPermissionsRequested);
      await prefs.remove(_keySelectedRole);
      
      state = const OnboardingState(
        isFirstTime: true,
        hasCompletedOnboarding: false,
        hasRequestedPermissions: false,
        selectedRole: null,
        isLoading: false,
      );

      // Log analytics event
      await FirebaseService.instance.logEvent('onboarding_reset', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      state = state.copyWith(error: 'Failed to reset onboarding state: $e');
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Check if user should see onboarding
  bool shouldShowOnboarding() {
    return state.isFirstTime || !state.hasCompletedOnboarding;
  }

  /// Check if user should see permissions request
  bool shouldRequestPermissions() {
    return !state.hasRequestedPermissions;
  }
}
