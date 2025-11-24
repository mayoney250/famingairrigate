import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure plugins are initialized in background isolate
  try {
    await FCMService.handleBackgroundMessage(message);
  } catch (e) {
    // ignore: avoid_print
    print('✗ Background handler error: $e');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  Future<void> initialize() async {
    await _requestPermissions();
    await _setupLocalNotifications();
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await _setupMessageHandlers();
    await _getAndSaveToken();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: true,
      );
    } else {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✓ FCM: User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✓ FCM: User granted provisional permission');
      } else {
        print('✗ FCM: User declined or has not accepted permission');
      }
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'irrigation_alerts',
      'Irrigation Alerts',
      description: 'Notifications for irrigation and water level alerts',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _getAndSaveToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('✓ FCM Token: $token');
        await _saveTokenToFirestore(token);
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('✓ FCM Token refreshed: $newToken');
        _saveTokenToFirestore(newToken);
      });
    } catch (e) {
      print('✗ Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    const maxRetries = 5;
    int attempt = 0;
    while (true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✓ FCM token saved to Firestore');
        break;
      } catch (e) {
        attempt++;
        final isTransient = e.toString().contains('UNAVAILABLE') || e.toString().contains('timeout') || e.toString().contains('network');
        if (!isTransient || attempt >= maxRetries) {
          print('✗ Error saving FCM token to Firestore (attempt $attempt): $e');
          break;
        }
        final backoffMs = (200 * attempt * attempt).clamp(200, 5000);
        print('⚠️ Transient error saving FCM token, retrying in ${backoffMs}ms (attempt $attempt)');
        await Future.delayed(Duration(milliseconds: backoffMs));
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('✓ Received foreground message: ${message.messageId}');

    _messageStreamController.add(message);

    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Faminga Irrigation';
    final body = notification?.body ?? data['body'] ?? (data['message'] ?? '');
    if (body != null && body.toString().isNotEmpty) {
      await _showLocalNotification(
        title: title,
        body: body.toString(),
        payload: _encodePayload(data),
        type: data['type'] ?? 'general',
        severity: data['severity'] as String?,
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('✓ Message opened app: ${message.messageId}');
    _messageStreamController.add(message);
    _handleNotificationNavigation(message.data);
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      print('✓ Handling background message: ${message.messageId}, data: ${message.data}');
      final notification = message.notification;
      final data = message.data;
      if (notification == null) {
        final title = data['title'] ?? 'Faminga Irrigation';
        final body = data['body'] ?? (data['message'] ?? '');
        if (body != null && body.toString().isNotEmpty) {
          final plugin = FlutterLocalNotificationsPlugin();
          const init = InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(),
          );
          await plugin.initialize(init);
          const channel = AndroidNotificationChannel(
            'irrigation_alerts',
            'Irrigation Alerts',
            description: 'Notifications for irrigation and water level alerts',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          );
          await plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(channel);
          
          final details = NotificationDetails(
            android: AndroidNotificationDetails(
              'irrigation_alerts',
              'Irrigation Alerts',
              channelDescription: 'Notifications for irrigation and water level alerts',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
          );
          await plugin.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title.toString(),
            body.toString(),
            details,
            payload: _encodePayload(data),
          );
        }
      }
    } catch (e) {
      print('✗ Error in background message handler: $e');
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
    required String type,
    String? severity,
  }) async {
    // Select color based on severity and type
    final notifColor = _getNotificationColor(type, severity: severity);
    
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'irrigation_alerts',
      'Irrigation Alerts',
      channelDescription: 'Notifications for irrigation and water level alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      color: notifColor,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    print('[FCM] 🔔 SHOWING NOTIFICATION #$notificationId');
    print('[FCM]    Title: "$title"');
    print('[FCM]    Body: "$body"');
    print('[FCM]    Type: $type');
    print('[FCM]    Source: FCMService (Push Message Handler)');

    await _localNotifications.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: payload,
    );
    
    print('[FCM] ✅ Notification #$notificationId shown successfully!');
  }

  /// Select Android notification icon based on severity and type
  String _getNotificationIcon(String type, {String? severity}) {
    // Critical severity overrides type
    if (severity == 'critical') {
      return 'ic_notif_critical';
    }
    
    // High severity or critical notification types
    if (severity == 'high' || 
        type == 'irrigation_failed' ||
        type == 'water_low' ||
        type == 'sensor_offline' ||
        type == 'ai_irrigate' ||
        type == 'irrigation_needed' ||
        type == 'ai_alert') {
      return 'ic_notif_warning';
    }
    
    // Reminder/schedule types
    if (type == 'schedule_reminder' ||
        type == 'rain_forecast') {
      return 'ic_notif_reminder';
    }
    
    // Default to info icon
    return 'ic_notif_info';
  }

  Color _getNotificationColor(String type, {String? severity}) {
    // Critical severity
    if (severity == 'critical' || type == 'irrigation_failed') {
      return const Color(0xFFD32F2F); // Red
    }
    
    // High/warning severity
    if (severity == 'high' || severity == 'medium' ||
        type == 'water_low' ||
        type == 'sensor_offline' ||
        type == 'ai_alert' ||
        type == 'irrigation_needed') {
      return const Color(0xFFFF9800); // Orange
    }
    
    // Info/reminder types
    if (type == 'schedule_reminder' ||
        type == 'rain_forecast' ||
        type == 'ai_hold') {
      return const Color(0xFF2196F3); // Blue
    }
    
    // Success/completion
    if (type == 'irrigation_completed') {
      return const Color(0xFF4CAF50); // Green
    }
    
    // Default
    return const Color(0xFF4CAF50); // Green
  }

  void _onNotificationTap(NotificationResponse response) {
    print('✓ Notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = _parsePayload(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  static String _encodePayload(Map<String, dynamic> data) {
    try {
      return const JsonEncoder().convert(data);
    } catch (_) {
      return '{}';
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    try {
      final decoded = json.decode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final id = data['id'];

    switch (type) {
      case 'irrigation_needed':
        break;
      case 'water_low':
        break;
      case 'schedule_reminder':
        break;
      default:
        break;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✓ Subscribed to topic: $topic');
    } catch (e) {
      print('✗ Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✓ Unsubscribed from topic: $topic');
    } catch (e) {
      print('✗ Error unsubscribing from topic: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('✗ Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'fcmTokens': FieldValue.arrayRemove([token]),
          });
        }
      }
      await _firebaseMessaging.deleteToken();
      print('✓ FCM token deleted');
    } catch (e) {
      print('✗ Error deleting FCM token: $e');
    }
  }

  void dispose() {
    _messageStreamController.close();
  }
}
