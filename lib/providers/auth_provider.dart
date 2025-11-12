import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';
import '../services/user_local_service.dart';
import '../services/notification_service.dart';
import '../services/fcm_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final FCMService _fcmService = FCMService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasAuthChecked = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get hasAuthChecked => _hasAuthChecked;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await loadUserData(user.uid);
        // Initialize FCM for push notifications
        await _fcmService.initialize();
        // Initialize local notifications
        await _notificationService.initialize();
      } else {
        _currentUser = null;
        // Clean up on logout
        await _fcmService.deleteToken();
        _notificationService.dispose();
        notifyListeners();
      }
      _hasAuthChecked = true;
      notifyListeners();
    });
  }

  Future<void> loadUserData(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      try {
        final userData = await _authService.getUserData(userId);
        if (userData != null) {
          _currentUser = userData;
          await UserLocalService.saveUser(userData);
          _errorMessage = null;
        } else {
          // fall back to cache if remote returned null
          final cached = await UserLocalService.getUser(userId);
          if (cached != null) {
            _currentUser = cached;
            _errorMessage = null;
          } else {
            _errorMessage = 'Failed to load user data';
          }
        }
      } catch (e) {
        print('❌ Load user data error (remote): $e');
        // Try local cache
        final cached = await UserLocalService.getUser(userId);
        if (cached != null) {
          _currentUser = cached;
          _errorMessage = null;
        } else {
          _errorMessage = 'Failed to load user data';
        }
      }
    } finally {
      _isLoading = false;
      _hasAuthChecked = true;
      notifyListeners();
    }
  }

  Future<bool> signUp({
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
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('🚀 Starting sign up for: $email');
      dev.log('🚀 Starting sign up for: $email');

      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        province: province,
        district: district,
        address: address,
      );

      if (userCredential != null) {
        print('✅ Sign up successful! UID: ${userCredential.user!.uid}');
        dev.log('✅ Sign up successful! UID: ${userCredential.user!.uid}');
        await loadUserData(userCredential.user!.uid);
        return true;
      }
      print('❌ Sign up returned null');
      dev.log('❌ Sign up returned null');
      _errorMessage = 'Registration failed - no user credential returned';
      return false;
    } catch (e) {
      print('❌ Sign up error: $e');
      print('❌ Error type: ${e.runtimeType}');
      dev.log('❌ Sign up error: $e');
      dev.log('❌ Error type: ${e.runtimeType}');
      _errorMessage = ErrorService.toMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('🚀 Starting sign in for: $email');
      dev.log('🚀 Starting sign in for: $email');

      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential != null) {
        print('✅ Sign in successful! UID: ${userCredential.user!.uid}');
        dev.log('✅ Sign in successful! UID: ${userCredential.user!.uid}');
        await loadUserData(userCredential.user!.uid);
        return true;
      }
      print('❌ Sign in returned null');
      dev.log('❌ Sign in returned null');
      _errorMessage = 'Login failed - no user credential returned';
      return false;
    } catch (e) {
      print('❌ Sign in error: $e');
      print('❌ Error type: ${e.runtimeType}');
      dev.log('❌ Sign in error: $e');
      dev.log('❌ Error type: ${e.runtimeType}');
      _errorMessage = ErrorService.toMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null) {
        await loadUserData(userCredential.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Google sign-in error: $e');
      dev.log('Google sign-in error: $e');
      _errorMessage = ErrorService.toMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      print('❌ Sign out error: $e');
      dev.log('Sign out error: $e');
      _errorMessage = 'Failed to sign out';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      print('❌ Password reset error: $e');
      dev.log('Password reset error: $e');
      _errorMessage = ErrorService.toMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_currentUser != null) {
        await _authService.updateUserData(_currentUser!.userId, data);
        await loadUserData(_currentUser!.userId);
      }
    } catch (e) {
      print('❌ Update profile error: $e');
      dev.log('Update profile error: $e');
      _errorMessage = 'Failed to update profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

