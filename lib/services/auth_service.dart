import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
    required String province,
    required String district,
    String? address,
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
        province: province,
        district: district,
        address: address,
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

      // Sign out from Google if user signed in with Google
      if (!kIsWeb) {
        try {
          await googleSignIn.signOut();
          log('Google sign out successful');
        } catch (e) {
          log('Google sign out error (non-critical): $e');
          // Don't throw, as this is non-critical
        }
      }

      // Sign out from Firebase
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

  /// Find a user's email by identifier which can be a phone number or cooperative ID
  /// Returns the user's email if found, or null otherwise.
  Future<String?> getEmailForIdentifier(String identifier) async {
    // First try the secure callable function
    try {
      log('🔍 Calling resolveIdentifier function for: $identifier');
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('resolveIdentifier');
      final result = await callable.call(<String, dynamic>{'identifier': identifier});
      final data = result.data as Map<String, dynamic>?;
      if (data != null && data['email'] != null) {
        final email = data['email'] as String?;
        log('✅ resolveIdentifier returned email: $email (via ${data['foundBy']})');
        return email;
      }
      log('🔎 resolveIdentifier returned no email for: $identifier');
    } catch (e) {
      log('⚠️ resolveIdentifier callable failed (falling back to client queries): $e');
    }

    // Fallback: try client-side queries (best-effort)
    try {
      log('🔍 Fallback: client-side lookup for identifier: $identifier');
      final phoneQuery = await _firestore.collection('users').where('phoneNumber', isEqualTo: identifier).limit(1).get();
      if (phoneQuery.docs.isNotEmpty) return phoneQuery.docs.first.data()['email'] as String?;

      final coopGovQuery = await _firestore.collection('users').where('cooperative.coopGovId', isEqualTo: identifier).limit(1).get();
      if (coopGovQuery.docs.isNotEmpty) return coopGovQuery.docs.first.data()['email'] as String?;

      final coopMemberQuery = await _firestore.collection('users').where('cooperative.memberId', isEqualTo: identifier).limit(1).get();
      if (coopMemberQuery.docs.isNotEmpty) return coopMemberQuery.docs.first.data()['email'] as String?;

      return null;
    } catch (e) {
      log('❌ getEmailForIdentifier fallback error: $e');
      return null;
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
      UserCredential userCredential;
      String? displayName;
      String? email;
      String? photoUrl;
      
      if (kIsWeb) {
        // Web: Use Firebase Auth popup directly (no google_sign_in package needed)
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Add scopes
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // Sign in with popup
        userCredential = await _auth.signInWithPopup(googleProvider);
        
        // Get user info from Firebase user
        displayName = userCredential.user?.displayName;
        email = userCredential.user?.email;
        photoUrl = userCredential.user?.photoURL;
        
        log('Google sign-in successful (web): ${userCredential.user!.uid}');
      } else {
        // Mobile: Use google_sign_in package
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
        userCredential = await _auth.signInWithCredential(credential);
        
        // Get user info from Google account
        displayName = googleUser.displayName;
        email = googleUser.email;
        photoUrl = googleUser.photoUrl;
        
        log('Google sign-in successful (mobile): ${userCredential.user!.uid}');
      }

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Create user document for new Google sign-in user
        final displayNameParts = displayName?.split(' ') ?? [];
        final user = UserModel(
          userId: userCredential.user!.uid,
          email: email ?? '',
          firstName: displayNameParts.isNotEmpty ? displayNameParts[0] : '',
          lastName: displayNameParts.length > 1
              ? displayNameParts.sublist(1).join(' ')
              : '',
          avatar: photoUrl,
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

  /// Upload profile picture to Firebase Storage
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // Create a reference to the profile pictures directory
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      log('Profile picture uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // Upload profile picture for web (using bytes instead of File)
  Future<String> uploadProfilePictureBytes(
    String userId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      // Create a reference to the profile pictures directory
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      // Upload the bytes
      final uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      log('Profile picture uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// Change user password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);

      log('Password changed successfully');
    } on FirebaseAuthException catch (e) {
      log('Error changing password: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Unexpected error changing password: $e');
      rethrow;
    }
  }

  /// Check if email already exists in users or verifications collection
  Future<bool> emailExists(String email) async {
    try {
      // Check users collection
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (usersSnapshot.docs.isNotEmpty) {
        log('Email already exists in users collection: $email');
        return true;
      }

      // Check verifications collection for pending requests
      final verificationsSnapshot = await _firestore
          .collection('verifications')
          .where('payload.userEmail', isEqualTo: email.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (verificationsSnapshot.docs.isNotEmpty) {
        log('Email already exists in pending verifications: $email');
        return true;
      }

      return false;
    } catch (e) {
      log('Error checking email uniqueness: $e');
      rethrow;
    }
  }

  /// Check if phone number already exists in users or verifications collection
  Future<bool> phoneNumberExists(String phoneNumber) async {
    try {
      // Normalize phone number (remove spaces, dashes, etc.)
      final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

      if (normalizedPhone.isEmpty || normalizedPhone.length < 10) {
        log('Phone number too short: $phoneNumber');
        return false;
      }

      // Check users collection
      final usersSnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isNotEmpty) {
        log('Phone number already exists in users collection: $phoneNumber');
        return true;
      }

      // Also check against normalized phone numbers in users
      final allUsers = await _firestore.collection('users').get();
      for (final doc in allUsers.docs) {
        final userPhone = (doc.data()['phoneNumber'] as String?)?.replaceAll(RegExp(r'\D'), '');
        if (userPhone == normalizedPhone) {
          log('Phone number (normalized) already exists in users: $phoneNumber');
          return true;
        }
      }

      // Check verifications collection for pending requests
      final verificationsSnapshot = await _firestore
          .collection('verifications')
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in verificationsSnapshot.docs) {
        final verifyPhone = (doc.data()['payload']['leaderPhone'] as String?)?.replaceAll(RegExp(r'\D'), '');
        if (verifyPhone == normalizedPhone) {
          log('Phone number (normalized) already exists in verifications: $phoneNumber');
          return true;
        }
      }

      return false;
    } catch (e) {
      log('Error checking phone uniqueness: $e');
      rethrow;
    }
  }

  /// Check if cooperative ID already exists in verifications collection
  Future<bool> cooperativeIdExists(String cooperativeId) async {
    try {
      // Check verifications collection for pending/approved requests
      final verificationsSnapshot = await _firestore
          .collection('verifications')
          .where('payload.coopGovId', isEqualTo: cooperativeId.toUpperCase())
          .get();

      if (verificationsSnapshot.docs.isNotEmpty) {
        log('Cooperative ID already exists: $cooperativeId');
        return true;
      }

      // Check users collection for existing cooperative registrations
      final usersSnapshot = await _firestore
          .collection('users')
          .where('cooperative.coopGovId', isEqualTo: cooperativeId.toUpperCase())
          .get();

      if (usersSnapshot.docs.isNotEmpty) {
        log('Cooperative ID already exists in users: $cooperativeId');
        return true;
      }

      return false;
    } catch (e) {
      log('Error checking cooperative ID uniqueness: $e');
      rethrow;
    }
  }

  /// Check if an identifier (email/phone/coop ID) already exists
  /// Returns: {'exists': bool, 'type': 'email'|'phone'|'cooperative_id'|'unknown'}
  Future<Map<String, dynamic>> checkIdentifierUniqueness(String identifier, bool isCooperative) async {
    try {
      // For cooperative registrations, check all three identifiers
      if (isCooperative) {
        // Could be email, phone, or cooperative ID
        // Check email format
        if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(identifier)) {
          final exists = await emailExists(identifier);
          return {'exists': exists, 'type': 'email', 'identifier': identifier};
        }

        // Check phone format
        if (identifier.startsWith('+') || (identifier.replaceAll(RegExp(r'\D'), '').length >= 10)) {
          final exists = await phoneNumberExists(identifier);
          return {'exists': exists, 'type': 'phone', 'identifier': identifier};
        }

        // Check cooperative ID format
        if (RegExp(r'^[A-Z0-9-]{5,}$', caseSensitive: false).hasMatch(identifier)) {
          final exists = await cooperativeIdExists(identifier);
          return {'exists': exists, 'type': 'cooperative_id', 'identifier': identifier};
        }
      } else {
        // For regular users, typically email or phone
        if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(identifier)) {
          final exists = await emailExists(identifier);
          return {'exists': exists, 'type': 'email', 'identifier': identifier};
        }
      }

      return {'exists': false, 'type': 'unknown', 'identifier': identifier};
    } catch (e) {
      log('Error checking identifier uniqueness: $e');
      // On error, don't block registration - return false
      return {'exists': false, 'type': 'unknown', 'identifier': identifier, 'error': e.toString()};
    }
  }
}

