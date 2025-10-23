import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Lazy initialization of GoogleSignIn to avoid web issues
  GoogleSignIn? _googleSignIn;
  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn();
    return _googleSignIn!;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final user = UserModel(
        userId: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        isActive: true,
        isOnline: false,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toMap());

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      log('User signed up successfully: ${userCredential.user!.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      log('Sign up error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Unexpected sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user online status
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
        'isOnline': true,
        'lastActive': DateTime.now().toIso8601String(),
      });

      log('User signed in successfully: ${userCredential.user!.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      log('Sign in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Unexpected sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final userId = currentUser?.uid;
      if (userId != null) {
        // Update user online status
        await _firestore.collection('users').doc(userId).update({
          'isOnline': false,
          'lastActive': DateTime.now().toIso8601String(),
        });
      }

      await _auth.signOut();
      log('User signed out successfully');
    } catch (e) {
      log('Sign out error: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      log('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      log('Password reset error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Unexpected password reset error: $e');
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
      log('Email verification sent');
    } catch (e) {
      log('Email verification error: $e');
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    await currentUser?.reload();
    return currentUser?.emailVerified ?? false;
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      log('Get user data error: $e');
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      log('User data updated successfully');
    } catch (e) {
      log('Update user data error: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        log('Google sign-in cancelled by user');
        return null;
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
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Create user document for new Google sign-in user
        final displayNameParts = googleUser.displayName?.split(' ') ?? [];
        final user = UserModel(
          userId: userCredential.user!.uid,
          email: googleUser.email,
          firstName: displayNameParts.isNotEmpty ? displayNameParts[0] : '',
          lastName: displayNameParts.length > 1
              ? displayNameParts.sublist(1).join(' ')
              : '',
          avatar: googleUser.photoUrl,
          createdAt: DateTime.now(),
          isActive: true,
          isOnline: true,
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(user.toMap());
      } else {
        // Update existing user's online status
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'isOnline': true,
          'lastActive': DateTime.now().toIso8601String(),
        });
      }

      log('Google sign-in successful: ${userCredential.user!.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      log('Google sign-in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Unexpected Google sign-in error: $e');
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final userId = currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).delete();
        await currentUser?.delete();
        log('Account deleted successfully');
      }
    } catch (e) {
      log('Delete account error: $e');
      rethrow;
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}

