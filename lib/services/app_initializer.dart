import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/firebase_config.dart';
import '../models/alert_model.dart';
import '../models/sensor_model.dart';
import '../models/sensor_reading_model.dart';
import '../models/user_model.dart';
import 'fcm_service.dart';

class AppInitializer {
  static bool _isFirebaseInitialized = false;
  static bool _isHiveInitialized = false;
  static bool _isFCMInitialized = false;

  static Future<void> initializeFirebase() async {
    if (_isFirebaseInitialized) return;
    await FirebaseConfig.initialize();
    _isFirebaseInitialized = true;
  }

  static Future<void> initializeHive() async {
    if (_isHiveInitialized) return;
    await Hive.initFlutter();
    Hive.registerAdapter(AlertModelAdapter());
    Hive.registerAdapter(SensorModelAdapter());
    Hive.registerAdapter(SensorReadingModelAdapter());
    Hive.registerAdapter(UserModelAdapter());
    _isHiveInitialized = true;
  }

  static Future<void> initializeFCM() async {
    if (_isFCMInitialized) return;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _isFCMInitialized = true;
  }

  static Future<void> ensureFirebaseAndHive() async {
    await Future.wait([
      initializeFirebase(),
      initializeHive(),
    ]);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await AppInitializer.initializeFirebase();
  await firebaseMessagingBackgroundHandler(message);
}
