import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Comprehensive Firebase Authentication Service
///
/// Provides email/password, phone, and Google authentication methods
/// with comprehensive error handling and state management using Riverpod.
///
/// ## Terminology Clarification:
/// - **Sign Up** = Create new account (registration)
/// - **Sign In / Login** = Authenticate existing account (same functionality)
///
/// This service provides both `signInWith*` and `loginWith*` methods for consistency.
/// Both method types perform the same authentication operations.
///
/// ## Available Authentication Methods:
/// 1. **Email/Password**: `signUpWithEmail()`, `signInWithEmail()`, `loginWithEmail()`
/// 2. **Phone**: `verifyPhoneNumber()`, `signInWithPhone()`, `loginWithPhone()`
/// 3. **Google**: `signInWithGoogle()`, `loginWithGoogle()`
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Store verification ID for phone authentication
  String? _verificationId;

  /// Current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is currently signed in
  bool get isSignedIn => currentUser != null;

  // ==================== EMAIL/PASSWORD AUTHENTICATION ====================

  /// Sign up with email and password
  ///
  /// [email] - User's email address (will be trimmed automatically)
  /// [password] - User's password
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('✅ Email signup successful for: ${email.trim()}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Email signup failed: ${e.code} - ${e.message}');
      throw _handleEmailAuthError(e);
    } catch (e) {
      debugPrint('❌ Unexpected signup error: $e');
      throw AuthException('An unexpected error occurred during signup');
    }
  }

  /// Sign in with email and password (Login)
  ///
  /// [email] - User's email address (will be trimmed automatically)
  /// [password] - User's password
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('✅ Email signin successful for: ${email.trim()}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Email signin failed: ${e.code} - ${e.message}');
      throw _handleEmailAuthError(e);
    } catch (e) {
      debugPrint('❌ Unexpected signin error: $e');
      throw AuthException('An unexpected error occurred during signin');
    }
  }

  /// Login with email and password (Alias for signInWithEmail)
  ///
  /// This is an alias method for [signInWithEmail] to provide
  /// consistent terminology across the app. Both methods do the same thing.
  ///
  /// [email] - User's email address (will be trimmed automatically)
  /// [password] - User's password
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> loginWithEmail(String email, String password) async {
    return signInWithEmail(email, password);
  }

  // ==================== PHONE AUTHENTICATION ====================

  /// Verify phone number for authentication
  ///
  /// [phoneNumber] - Phone number in international format (+1234567890)
  /// [onVerificationCompleted] - Called when verification is completed automatically
  /// [onVerificationFailed] - Called when verification fails
  /// [onCodeSent] - Called when SMS code is sent
  /// [onCodeAutoRetrievalTimeout] - Called when auto-retrieval times out
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required void Function(PhoneAuthCredential) onVerificationCompleted,
    required void Function(FirebaseAuthException) onVerificationFailed,
    required void Function(String, int?) onCodeSent,
    required void Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('✅ Phone verification completed automatically');
          onVerificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification failed: ${e.code} - ${e.message}');
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('📱 SMS code sent to: $phoneNumber');
          _verificationId = verificationId;
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ Phone verification timeout for: $phoneNumber');
          _verificationId = verificationId;
          onCodeAutoRetrievalTimeout(verificationId);
        },
      );
    } catch (e) {
      debugPrint('❌ Phone verification error: $e');
      throw AuthException('Failed to verify phone number');
    }
  }

  /// Sign in with phone number using SMS code
  ///
  /// [verificationId] - Verification ID received from codeSent callback
  /// [smsCode] - SMS code entered by user
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> signInWithPhone(
      String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Phone signin successful');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Phone signin failed: ${e.code} - ${e.message}');
      throw _handlePhoneAuthError(e);
    } catch (e) {
      debugPrint('❌ Unexpected phone signin error: $e');
      throw AuthException('An unexpected error occurred during phone signin');
    }
  }

  /// Sign in with phone credential directly
  ///
  /// [credential] - PhoneAuthCredential from verification
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Phone credential signin successful');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Phone credential signin failed: ${e.code} - ${e.message}');
      throw _handlePhoneAuthError(e);
    } catch (e) {
      debugPrint('❌ Unexpected phone credential signin error: $e');
      throw AuthException(
          'An unexpected error occurred during phone credential signin');
    }
  }

  /// Login with phone number using SMS code (Alias for signInWithPhone)
  ///
  /// This is an alias method for [signInWithPhone] to provide
  /// consistent terminology across the app. Both methods do the same thing.
  ///
  /// [verificationId] - Verification ID received from codeSent callback
  /// [smsCode] - SMS code entered by user
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> loginWithPhone(
      String verificationId, String smsCode) async {
    return signInWithPhone(verificationId, smsCode);
  }

  /// Login with phone credential (Alias for signInWithPhoneCredential)
  ///
  /// This is an alias method for [signInWithPhoneCredential] to provide
  /// consistent terminology across the app. Both methods do the same thing.
  ///
  /// [credential] - PhoneAuthCredential from verification
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> loginWithPhoneCredential(
      PhoneAuthCredential credential) async {
    return signInWithPhoneCredential(credential);
  }

  // ==================== GOOGLE SIGN-IN ====================

  /// Sign in with Google
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Google signin successful for: ${googleUser.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Google signin failed: ${e.code} - ${e.message}');
      throw _handleGoogleAuthError(e);
    } catch (e) {
      debugPrint('❌ Unexpected Google signin error: $e');
      throw AuthException('An unexpected error occurred during Google signin');
    }
  }

  /// Login with Google (Alias for signInWithGoogle)
  ///
  /// This is an alias method for [signInWithGoogle] to provide
  /// consistent terminology across the app. Both methods do the same thing.
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> loginWithGoogle() async {
    return signInWithGoogle();
  }

  // ==================== UTILITY METHODS ====================

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _verificationId = null;
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      throw AuthException('Failed to sign out');
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
      await _googleSignIn.signOut();
      _verificationId = null;
      debugPrint('✅ Account deleted successfully');
    } catch (e) {
      debugPrint('❌ Account deletion error: $e');
      throw AuthException('Failed to delete account');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('✅ Password reset email sent to: ${email.trim()}');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset failed: ${e.code} - ${e.message}');
      throw _handleEmailAuthError(e);
    }
  }

  // ==================== ERROR HANDLERS ====================

  /// Handle email authentication errors
  AuthException _handleEmailAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return AuthException(
            'Password is too weak. Please choose a stronger password.');
      case 'email-already-in-use':
        return AuthException(
            'An account already exists with this email address.');
      case 'invalid-email':
        return AuthException('Please enter a valid email address.');
      case 'user-not-found':
        return AuthException('No account found with this email address.');
      case 'wrong-password':
        return AuthException('Incorrect password. Please try again.');
      case 'user-disabled':
        return AuthException('This account has been disabled.');
      case 'too-many-requests':
        return AuthException(
            'Too many failed attempts. Please try again later.');
      case 'operation-not-allowed':
        return AuthException('Email/password authentication is not enabled.');
      default:
        return AuthException(e.message ?? 'Authentication failed');
    }
  }

  /// Handle phone authentication errors
  AuthException _handlePhoneAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return AuthException('Please enter a valid phone number.');
      case 'invalid-verification-code':
        return AuthException('Invalid verification code. Please try again.');
      case 'invalid-verification-id':
        return AuthException(
            'Verification session expired. Please request a new code.');
      case 'quota-exceeded':
        return AuthException('SMS quota exceeded. Please try again later.');
      case 'session-expired':
        return AuthException(
            'Verification session expired. Please request a new code.');
      default:
        return AuthException(e.message ?? 'Phone authentication failed');
    }
  }

  /// Handle Google authentication errors
  AuthException _handleGoogleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return AuthException(
            'An account already exists with this email using a different sign-in method.');
      case 'invalid-credential':
        return AuthException('Google sign-in credentials are invalid.');
      case 'operation-not-allowed':
        return AuthException('Google sign-in is not enabled.');
      case 'user-disabled':
        return AuthException('This account has been disabled.');
      default:
        return AuthException(e.message ?? 'Google sign-in failed');
    }
  }
}

/// Custom authentication exception
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Riverpod provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Riverpod provider for authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Riverpod provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});
