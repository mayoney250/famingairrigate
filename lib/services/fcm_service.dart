import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FCMService.handleBackgroundMessage(message);
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
      importance: Importance.high,
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
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✓ FCM token saved to Firestore');
    } catch (e) {
      print('✗ Error saving FCM token to Firestore: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('✓ Received foreground message: ${message.messageId}');

    _messageStreamController.add(message);

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'Faminga Irrigation',
        body: notification.body ?? '',
        payload: data.toString(),
        type: data['type'] ?? 'general',
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('✓ Message opened app: ${message.messageId}');
    _messageStreamController.add(message);
    _handleNotificationNavigation(message.data);
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('✓ Handling background message: ${message.messageId}');
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
    required String type,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'irrigation_alerts',
      'Irrigation Alerts',
      channelDescription: 'Notifications for irrigation and water level alerts',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
      color: _getNotificationColor(type),
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

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'irrigation_needed':
        return const Color(0xFF2196F3); // Blue
      case 'water_low':
        return const Color(0xFFFF9800); // Orange
      case 'critical':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF4CAF50); // Green
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('✓ Notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = _parsePayload(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    try {
      return Map<String, dynamic>.from(
        payload.split(',').fold<Map<String, dynamic>>({}, (map, item) {
          final parts = item.split(':');
          if (parts.length == 2) {
            map[parts[0].trim()] = parts[1].trim();
          }
          return map;
        }),
      );
    } catch (e) {
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
