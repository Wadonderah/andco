import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart' as comprehensive_auth;
import '../../shared/models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

/// Provider for Firebase Auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

/// Provider for current user profile
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) async {
      if (user != null) {
        return await AuthService.instance.getUserProfile(user.uid);
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Authentication controller
class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  AuthController() : super(const AsyncValue.loading()) {
    _init();
  }

  final AuthService _authService = AuthService.instance;
  final comprehensive_auth.AuthService _comprehensiveAuthService =
      comprehensive_auth.AuthService();

  void _init() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        final userProfile = await _authService.getUserProfile(user.uid);
        state = AsyncValue.data(userProfile);
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  /// Sign in with email and password (Login)
  ///
  /// This method authenticates existing users with their email and password.
  /// For new user registration, use [signUpWithEmailAndPassword] instead.
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      // Use comprehensive auth service for better error handling
      final credential =
          await _comprehensiveAuthService.signInWithEmail(email, password);
      if (credential.user != null) {
        final userProfile =
            await _authService.getUserProfile(credential.user!.uid);
        state = AsyncValue.data(userProfile);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Login with email and password (Alias for signInWithEmailAndPassword)
  ///
  /// This is an alias method for [signInWithEmailAndPassword] to provide
  /// consistent terminology across the app. Both methods do the same thing.
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    return signInWithEmailAndPassword(email, password);
  }

  /// Sign up with email and password
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required UserRole role,
    String? schoolId,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Use comprehensive auth service for better error handling
      final credential =
          await _comprehensiveAuthService.signUpWithEmail(email, password);
      final user = credential.user!;

      // Update display name
      await user.updateDisplayName(name);

      // Get FCM token
      final fcmToken = await FirebaseService.instance.getFCMToken();

      // Create user profile
      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        isVerified: user.emailVerified,
        schoolId: schoolId,
        fcmToken: fcmToken,
      );

      await _authService.createUserProfile(userModel);
      state = AsyncValue.data(userModel);

      // Send email verification
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle({UserRole? role, String? schoolId}) async {
    state = const AsyncValue.loading();

    try {
      // Use comprehensive auth service for better error handling
      final credential = await _comprehensiveAuthService.signInWithGoogle();
      final user = credential.user!;

      // Check if user profile exists
      UserModel? userProfile = await _authService.getUserProfile(user.uid);

      if (userProfile == null && role != null) {
        // Create new user profile for first-time Google sign-in
        final fcmToken = await FirebaseService.instance.getFCMToken();

        userProfile = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          phoneNumber: user.phoneNumber,
          profileImageUrl: user.photoURL,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          isVerified: user.emailVerified,
          schoolId: schoolId,
          fcmToken: fcmToken,
        );

        await _authService.createUserProfile(userProfile);
      }

      state = AsyncValue.data(userProfile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Login with Google (Alias for signInWithGoogle)
  ///
  /// This is an alias method for [signInWithGoogle] to provide
  /// consistent terminology across the app. Both methods do the same thing.
  Future<void> loginWithGoogle({UserRole? role, String? schoolId}) async {
    return signInWithGoogle(role: role, schoolId: schoolId);
  }

  /// Verify phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _comprehensiveAuthService.verifyPhoneNumber(
        phoneNumber,
        onVerificationCompleted: verificationCompleted,
        onVerificationFailed: verificationFailed,
        onCodeSent: codeSent,
        onCodeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with phone number
  Future<void> signInWithPhoneCredential(
    PhoneAuthCredential credential, {
    String? name,
    UserRole? role,
    String? schoolId,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Use comprehensive auth service for better error handling
      final userCredential =
          await _comprehensiveAuthService.signInWithPhoneCredential(credential);
      final user = userCredential.user!;

      // Check if user profile exists
      UserModel? userProfile = await _authService.getUserProfile(user.uid);

      if (userProfile == null && role != null && name != null) {
        // Create new user profile for first-time phone sign-in
        final fcmToken = await FirebaseService.instance.getFCMToken();

        userProfile = UserModel(
          uid: user.uid,
          name: name,
          email: '',
          phoneNumber: user.phoneNumber,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          isVerified: true, // Phone is verified
          schoolId: schoolId,
          fcmToken: fcmToken,
        );

        await _authService.createUserProfile(userProfile);
      }

      state = AsyncValue.data(userProfile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Login with phone credential (Alias for signInWithPhoneCredential)
  ///
  /// This is an alias method for [signInWithPhoneCredential] to provide
  /// consistent terminology across the app. Both methods do the same thing.
  Future<void> loginWithPhoneCredential(
    PhoneAuthCredential credential, {
    String? name,
    UserRole? role,
    String? schoolId,
  }) async {
    return signInWithPhoneCredential(
      credential,
      name: name,
      role: role,
      schoolId: schoolId,
    );
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    try {
      await _authService.updateUserProfile(currentUser.uid, {
        ...data,
        'updatedAt': DateTime.now(),
      });

      // Refresh user profile
      final updatedProfile = await _authService.getUserProfile(currentUser.uid);
      state = AsyncValue.data(updatedProfile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Check if user has specific role
  Future<bool> hasRole(UserRole role) async {
    return await _authService.hasRole(role);
  }
}

/// Provider for authentication controller
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController();
});

/// Provider to check if user is signed in
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// Provider to get current user role
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userProfile = ref.watch(currentUserProvider);
  return userProfile.maybeWhen(
    data: (user) => user?.role,
    orElse: () => null,
  );
});
