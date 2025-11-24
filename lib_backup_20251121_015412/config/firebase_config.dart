import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Configuration for Faminga Irrigation App
/// Project: ngairrigate
/// 
/// SECURITY NOTE: Firebase config values are safe to expose in client apps
/// as they are protected by Firebase Security Rules and API restrictions
class FirebaseConfig {
  // Firebase Project Configuration
  static const String projectId = 'famingairrigation';
  static const String apiKey = 'AIzaSyDZDeht3F5sa6jiqedhREjFuRs7DrXzgm0';
  static const String authDomain = 'famingairrigation.firebaseapp.com';
  static const String storageBucket = 'famingairrigation.appspot.com';
  static const String messagingSenderId = '622157404711';
  static const String appId = '1:622157404711:web:0ef6a4c4d838c75aef0c02';
  static const String measurementId = 'G-PHY8RXWZER';

  /// Initialize Firebase for the current platform
  static Future<void> initialize() async {
    try {
      // Try to initialize Firebase
      // On web, this will succeed even if called multiple times (idempotent)
      // On mobile, it will throw duplicate-app error if already initialized
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      
      if (kDebugMode) {
        print('✅ Firebase initialized successfully for ${kIsWeb ? 'web' : defaultTargetPlatform.name}');
      }
      
      // Enable Firestore offline persistence (not available on web)
      await _configureFirestore();
    } catch (e) {
      // Handle duplicate app error gracefully (can happen on Android/iOS with config files)
      // or if Firebase is already initialized
      if (e.toString().contains('duplicate-app') || 
          e.toString().contains('already created') ||
          e.toString().contains('already initialized')) {
        if (kDebugMode) {
          print('✅ Firebase already initialized, continuing...');
        }
        // Continue with Firestore configuration
        await _configureFirestore();
      } else {
        if (kDebugMode) {
          print('❌ Firebase initialization error: $e');
        }
        rethrow;
      }
    }
  }

  /// Configure Firestore settings
  static Future<void> _configureFirestore() async {
    try {
      if (kIsWeb) {
        // Web doesn't support offline persistence configuration
        if (kDebugMode) {
          print('✅ Firestore configured for web');
        }
      } else {
        // Firestore offline persistence is enabled by default on mobile
        // Additional settings can be configured here if needed
        if (kDebugMode) {
          print('✅ Firestore configured with offline persistence');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Firestore configuration warning: $e');
      }
    }
  }

  /// Get platform-specific Firebase options
  static FirebaseOptions _getFirebaseOptions() {
    if (kIsWeb) {
      return _webOptions;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidOptions;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosOptions;
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      return _macOSOptions;
    }

    throw UnsupportedError(
      'Firebase is not supported on ${defaultTargetPlatform.name}',
    );
  }

  /// Web Firebase Options
  static const FirebaseOptions _webOptions = FirebaseOptions(
    apiKey: apiKey,
    authDomain: authDomain,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: appId,
    measurementId: measurementId,
  );

  /// Android Firebase Options
  /// NOTE: For production, you should add google-services.json to android/app/
  static const FirebaseOptions _androidOptions = FirebaseOptions(
    apiKey: apiKey,
    authDomain: authDomain,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: appId,
    measurementId: measurementId,
  );

  /// iOS Firebase Options
  /// NOTE: For production, you should add GoogleService-Info.plist to ios/Runner/
  static const FirebaseOptions _iosOptions = FirebaseOptions(
    apiKey: apiKey,
    authDomain: authDomain,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: appId,
    measurementId: measurementId,
    iosBundleId: 'com.faminga.irrigation',
  );

  /// macOS Firebase Options
  static const FirebaseOptions _macOSOptions = FirebaseOptions(
    apiKey: apiKey,
    authDomain: authDomain,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: appId,
    measurementId: measurementId,
  );
}

