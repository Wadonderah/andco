import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/user_model.dart';
import 'firebase_service.dart';

/// Authentication service for managing user authentication
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();

  final FirebaseAuth _auth = FirebaseService.instance.auth;
  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Current user
  User? get currentUser => _auth.currentUser;
  
  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await FirebaseService.instance.logEvent('login', {
        'method': 'email',
        'user_id': credential.user?.uid ?? '',
      });
      
      return credential;
    } on FirebaseAuthException catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'Email sign in failed');
      throw _handleAuthException(e);
    }
  }

  /// Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await FirebaseService.instance.logEvent('sign_up', {
        'method': 'email',
        'user_id': credential.user?.uid ?? '',
      });
      
      return credential;
    } on FirebaseAuthException catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'Email sign up failed');
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      await FirebaseService.instance.logEvent('login', {
        'method': 'google',
        'user_id': userCredential.user?.uid ?? '',
      });
      
      return userCredential;
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'Google sign in failed');
      throw Exception('Google sign in failed: $e');
    }
  }

  /// Send phone verification code
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'Phone verification failed');
      rethrow;
    }
  }

  /// Sign in with phone credential
  Future<UserCredential?> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      
      await FirebaseService.instance.logEvent('login', {
        'method': 'phone',
        'user_id': userCredential.user?.uid ?? '',
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'Phone sign in failed');
      throw _handleAuthException(e);
    }
  }

  /// Create phone auth credential
  PhoneAuthCredential createPhoneCredential(String verificationId, String smsCode) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      
      await FirebaseService.instance.logEvent('password_reset_requested', {
        'email': email,
      });
    } on FirebaseAuthException catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'Password reset failed');
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      await FirebaseService.instance.logEvent('logout', {
        'user_id': currentUser?.uid ?? '',
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'Sign out failed');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete user account
        await user.delete();
        
        await FirebaseService.instance.logEvent('account_deleted', {
          'user_id': user.uid,
        });
      }
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'Account deletion failed');
      rethrow;
    }
  }

  /// Create or update user profile in Firestore
  Future<void> createUserProfile(UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(userModel.uid).set(userModel.toMap());
      
      await FirebaseService.instance.logEvent('user_profile_created', {
        'user_id': userModel.uid,
        'role': userModel.role.toString(),
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'User profile creation failed');
      rethrow;
    }
  }

  /// Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'Get user profile failed');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      
      await FirebaseService.instance.logEvent('user_profile_updated', {
        'user_id': uid,
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, reason: 'User profile update failed');
      rethrow;
    }
  }

  /// Check if user has specific role
  Future<bool> hasRole(UserRole role) async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      final userProfile = await getUserProfile(user.uid);
      return userProfile?.role == role;
    } catch (e) {
      debugPrint('Error checking user role: $e');
      return false;
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
