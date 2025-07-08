import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

/// Authentication state notifier for managing auth operations with loading states
///
/// ## Terminology Clarification:
/// - **Sign Up** = Create new account (registration)
/// - **Sign In / Login** = Authenticate existing account (same functionality)
///
/// This notifier provides both `signInWith*` and `loginWith*` methods for consistency.
/// Both method types perform the same authentication operations.
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (mounted) {
        state = AsyncValue.data(user);
      }
    });
  }

  final AuthService _authService;

  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.signUpWithEmail(email, password);
      state = AsyncValue.data(credential.user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.signInWithEmail(email, password);
      state = AsyncValue.data(credential.user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.signInWithGoogle();
      state = AsyncValue.data(credential.user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign in with phone number
  Future<void> signInWithPhone(String verificationId, String smsCode) async {
    state = const AsyncValue.loading();
    try {
      final credential =
          await _authService.signInWithPhone(verificationId, smsCode);
      state = AsyncValue.data(credential.user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _authService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e, stackTrace) {
      // Don't change the main auth state for password reset
      rethrow;
    }
  }

  /// Verify phone number
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required void Function(PhoneAuthCredential) onVerificationCompleted,
    required void Function(FirebaseAuthException) onVerificationFailed,
    required void Function(String, int?) onCodeSent,
    required void Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber,
        onVerificationCompleted: onVerificationCompleted,
        onVerificationFailed: onVerificationFailed,
        onCodeSent: onCodeSent,
        onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for AuthNotifier
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Convenience providers for common auth states
final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isLoading;
});

final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (_) => null,
    loading: () => null,
    error: (error, _) => error.toString(),
  );
});

/// Phone authentication state notifier
class PhoneAuthNotifier extends StateNotifier<PhoneAuthState> {
  PhoneAuthNotifier(this._authService) : super(const PhoneAuthState.initial());

  final AuthService _authService;

  /// Start phone verification process
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    state = const PhoneAuthState.loading();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber,
        onVerificationCompleted: (credential) {
          state = PhoneAuthState.verificationCompleted(credential);
        },
        onVerificationFailed: (exception) {
          state = PhoneAuthState.error(exception.toString());
        },
        onCodeSent: (verificationId, resendToken) {
          state = PhoneAuthState.codeSent(verificationId, resendToken);
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          state = PhoneAuthState.timeout(verificationId);
        },
      );
    } catch (e) {
      state = PhoneAuthState.error(e.toString());
    }
  }

  /// Reset to initial state
  void reset() {
    state = const PhoneAuthState.initial();
  }
}

/// Phone authentication state
class PhoneAuthState {
  const PhoneAuthState();

  const factory PhoneAuthState.initial() = _Initial;
  const factory PhoneAuthState.loading() = _Loading;
  const factory PhoneAuthState.codeSent(
      String verificationId, int? resendToken) = _CodeSent;
  const factory PhoneAuthState.verificationCompleted(
      PhoneAuthCredential credential) = _VerificationCompleted;
  const factory PhoneAuthState.timeout(String verificationId) = _Timeout;
  const factory PhoneAuthState.error(String message) = _Error;

  bool get isLoading => this is _Loading;
  bool get isCodeSent => this is _CodeSent;
  bool get isCompleted => this is _VerificationCompleted;
  bool get isTimeout => this is _Timeout;
  bool get hasError => this is _Error;

  String? get verificationId {
    final state = this;
    if (state is _CodeSent) return state.verificationId;
    if (state is _Timeout) return state.verificationId;
    return null;
  }

  int? get resendToken {
    final state = this;
    if (state is _CodeSent) return state.resendToken;
    return null;
  }

  PhoneAuthCredential? get credential {
    final state = this;
    if (state is _VerificationCompleted) return state.credential;
    return null;
  }

  String? get error {
    final state = this;
    if (state is _Error) return state.message;
    return null;
  }
}

class _Initial extends PhoneAuthState {
  const _Initial();
}

class _Loading extends PhoneAuthState {
  const _Loading();
}

class _CodeSent extends PhoneAuthState {
  const _CodeSent(this.verificationId, this.resendToken);
  @override
  final String verificationId;
  @override
  final int? resendToken;
}

class _VerificationCompleted extends PhoneAuthState {
  const _VerificationCompleted(this.credential);
  @override
  final PhoneAuthCredential credential;
}

class _Timeout extends PhoneAuthState {
  const _Timeout(this.verificationId);
  @override
  final String verificationId;
}

class _Error extends PhoneAuthState {
  const _Error(this.message);
  final String message;
}

/// Provider for phone authentication
final phoneAuthNotifierProvider =
    StateNotifierProvider<PhoneAuthNotifier, PhoneAuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return PhoneAuthNotifier(authService);
});
