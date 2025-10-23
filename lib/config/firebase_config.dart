import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: _getFirebaseOptions(),
    );
  }

  static FirebaseOptions _getFirebaseOptions() {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: String.fromEnvironment('VITE_FIREBASE_API_KEY'),
        authDomain: String.fromEnvironment('VITE_FIREBASE_AUTH_DOMAIN'),
        projectId: String.fromEnvironment('VITE_FIREBASE_PROJECT_ID'),
        storageBucket: String.fromEnvironment('VITE_FIREBASE_STORAGE_BUCKET'),
        messagingSenderId: String.fromEnvironment(
          'VITE_FIREBASE_MESSAGING_SENDER_ID',
        ),
        appId: String.fromEnvironment('VITE_FIREBASE_APP_ID'),
        measurementId: String.fromEnvironment('VITE_GA_MEASUREMENT_ID'),
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return const FirebaseOptions(
        apiKey: String.fromEnvironment(
          'VITE_FIREBASE_API_KEY',
          defaultValue: 'YOUR_ANDROID_API_KEY',
        ),
        authDomain: String.fromEnvironment('VITE_FIREBASE_AUTH_DOMAIN'),
        projectId: String.fromEnvironment('VITE_FIREBASE_PROJECT_ID'),
        storageBucket: String.fromEnvironment('VITE_FIREBASE_STORAGE_BUCKET'),
        messagingSenderId: String.fromEnvironment(
          'VITE_FIREBASE_MESSAGING_SENDER_ID',
        ),
        appId: String.fromEnvironment(
          'VITE_FIREBASE_APP_ID',
          defaultValue: 'YOUR_ANDROID_APP_ID',
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const FirebaseOptions(
        apiKey: String.fromEnvironment(
          'VITE_FIREBASE_API_KEY',
          defaultValue: 'YOUR_IOS_API_KEY',
        ),
        authDomain: String.fromEnvironment('VITE_FIREBASE_AUTH_DOMAIN'),
        projectId: String.fromEnvironment('VITE_FIREBASE_PROJECT_ID'),
        storageBucket: String.fromEnvironment('VITE_FIREBASE_STORAGE_BUCKET'),
        messagingSenderId: String.fromEnvironment(
          'VITE_FIREBASE_MESSAGING_SENDER_ID',
        ),
        appId: String.fromEnvironment(
          'VITE_FIREBASE_APP_ID',
          defaultValue: 'YOUR_IOS_APP_ID',
        ),
        iosClientId: String.fromEnvironment('VITE_GOOGLE_CLIENT_ID'),
        iosBundleId: 'com.faminga.irrigation',
      );
    }

    throw UnsupportedError('Unsupported platform');
  }
}

