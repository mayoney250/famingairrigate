import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

/// Enhanced Local notification service with comprehensive alert types
/// Supports: Irrigation AI recommendations, Status changes, Sensor alerts, Weather, and more
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<StreamSubscription> _listeners = [];
  final Map<String, DateTime> _lastAlertTimes = {};
  Timer? _periodicCheckTimer;
  Timer? _weatherCheckTimer;
  StreamSubscription<User?>? _authSubscription;
  String? _attachedForUid;

  Future<void> initialize() async {
    print('Initializing Enhanced Notification Service...');
    await _requestNotificationPermissions();
    await requestBatteryOptimizationExemption();
    await _setupLocalNotifications();
    _setupAuthBoundListeners();
    print('✅ Enhanced Notification Service initialized');
  }

  Future<void> sendTestNotification() async {
    await _showNotification(
      title: '🧪 Test Notification',
      body: 'If you see this, your notifications are working perfectly!',
      type: NotificationType.test,
    );
  }

  Future<Map<String, dynamic>> getNotificationStatus() async {
    final status = <String, dynamic>{};

    try {
      final permissionStatus = await Permission.notification.status;
      status['permissionGranted'] = permissionStatus.isGranted;
      status['permissionDenied'] = permissionStatus.isDenied;
      status['permissionPermanentlyDenied'] = permissionStatus.isPermanentlyDenied;

      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      status['batteryOptimizationDisabled'] = batteryStatus.isGranted;

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final channels = await androidPlugin.getNotificationChannels();
        status['channelCount'] = channels?.length ?? 0;

        if (channels != null && channels.isNotEmpty) {
          try {
            final irrigationChannel = channels.firstWhere(
                  (ch) => ch.id == 'irrigation_alerts',
            );
            status['channelName'] = irrigationChannel.name;
            status['channelImportance'] = irrigationChannel.importance.toString();
            status['soundEnabled'] = irrigationChannel.playSound;
            status['vibrationEnabled'] = irrigationChannel.enableVibration;
          } catch (e) {
            status['channelError'] = 'Irrigation channel not found';
          }
        }
      } else {
        status['platform'] = 'iOS or channel check not available';
      }

      final activeNotifications = await _localNotifications.getActiveNotifications();
      status['activeNotificationCount'] = activeNotifications?.length ?? 0;

    } catch (e) {
      status['error'] = e.toString();
    }

    print('📊 Notification Status: $status');
    return status;
  }

  Future<void> requestBatteryOptimizationExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;

      if (!status.isGranted) {
        print('⚠️ Battery optimization is ENABLED - this blocks notifications');
        print('🔄 Requesting battery optimization exemption...');

        final result = await Permission.ignoreBatteryOptimizations.request();

        if (result.isGranted) {
          print('✅ Battery optimization exemption granted');
        } else {
          print('❌ User denied battery optimization exemption');
          print('⚠️ Notifications may be delayed or blocked');
        }
      } else {
        print('✅ Battery optimization already disabled');
      }
    } catch (e) {
      print('❌ Error requesting battery optimization exemption: $e');
    }
  }

  Future<void> _requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print('✓ Notification permission granted');
    } else if (status.isDenied) {
      print('⚠️ Notification permission denied');
    } else if (status.isPermanentlyDenied) {
      print('⚠️ Notification permission permanently denied');
      await openAppSettings();
    }
  }

  Future<void> _setupLocalNotifications() async {
    try {
      print('🔧 Setting up local notifications...');

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        try {
          await androidPlugin.deleteNotificationChannel('irrigation_alerts');
          print('✅ Deleted old notification channel');
        } catch (e) {
          print('ℹ️ No existing channel to delete (first install): $e');
        }
      }

      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('📱 Notification tapped: ${response.payload}');
        },
      );

<<<<<<< HEAD
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
=======
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4
        'irrigation_alerts',
        'Irrigation Alerts',
        description: 'Critical irrigation and water level alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF4CAF50),
        showBadge: true,
      );

      await androidPlugin?.createNotificationChannel(channel);
      print('✅ Created notification channel with MAX importance');

      if (androidPlugin != null) {
        final channels = await androidPlugin.getNotificationChannels();
        if (channels != null) {
          print('📋 Active channels:');
          for (var ch in channels) {
            print('  - ${ch.name}: importance=${ch.importance}');
          }
        }
      }

      print('✅ Notification service initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error setting up notifications: $e');
      print(stackTrace);
    }
  }

  void _clearListeners() {
    for (var listener in _listeners) {
      listener.cancel();
    }
    _listeners.clear();
    print('✓ Listeners cleared');
  }

  void _setupAuthBoundListeners() {
    _authSubscription?.cancel();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('🔥 User already logged in, attaching listeners immediately');
      _attachListenersFor(currentUser.uid);
    } else {
      print('⚠️ No user currently logged in');
    }

    _authSubscription = FirebaseAuth.instance.idTokenChanges().listen((user) {
      final uid = user?.uid;
      if (uid == null) {
        _clearListeners();
        _attachedForUid = null;
        print('⚠️ User signed out; listeners cleared');
        return;
      }
      if (_attachedForUid == uid) {
        print('ℹ️ Listeners already attached for $uid, skipping');
        return;
      }
      print('🔥 Auth changed to $uid, attaching listeners');
      _attachListenersFor(uid);
    }, onError: (e) {
      print('❌ Auth stream error: $e');
    });
  }

  void _attachListenersFor(String uid) {
    _clearListeners();
    _attachedForUid = uid;
    print('Attaching listeners for user: $uid');

    _setupIrrigationListener(uid);
    _setupAlertsListener(uid);
    _setupAIRecommendationListener(uid);
    _setupSensorReadingsListener(uid);
    _setupScheduleListener(uid);

    _periodicCheckTimer?.cancel();
    _weatherCheckTimer?.cancel();
    _startPeriodicChecks();
    _startWeatherChecks();
  }

  /// NEW: Listen to AI recommendations (Irrigate/Hold/Alert)
  void _setupAIRecommendationListener(String userId) {
    print('[AI_RECOMMENDATIONS] Setting up listener for userId: $userId');

    final listener = _firestore
        .collection('ai_recommendations')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      print('[AI_RECOMMENDATIONS] Snapshot received - size: ${snapshot.size}, changes: ${snapshot.docChanges.length}');

      try {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            final data = change.doc.data()!;
            print('[AI_RECOMMENDATIONS] New recommendation: $data');

            await _handleAIRecommendation(change.doc.id, data);
          }
        }
      } catch (e, stackTrace) {
        print('[AI_RECOMMENDATIONS] ERROR in handler: $e');
        print(stackTrace);
      }
    }, onError: (e, stackTrace) {
      print('[AI_RECOMMENDATIONS] ERROR in stream: $e');
      print(stackTrace);
    });

    _listeners.add(listener);
    print('[AI_RECOMMENDATIONS] Listener attached successfully');
  }

  /// ENHANCED: Handle AI recommendations with proper notifications
  Future<void> _handleAIRecommendation(String docId, Map<String, dynamic> data) async {
    print('[AI_RECOMMENDATIONS] Processing recommendation: $docId');

    final recommendation = data['recommendation'] as String?; // 'irrigate', 'hold', or 'alert'
    final fieldId = data['fieldId'] as String?;
    final confidence = data['confidence'] as num?;
    final reason = data['reason'] as String?;

    if (recommendation == null) {
      print('[AI_RECOMMENDATIONS] ERROR: No recommendation field in data!');
      return;
    }

    // Get field name
    String fieldName = 'your field';
    if (fieldId != null) {
      try {
        final fieldDoc = await _firestore.collection('fields').doc(fieldId).get();
        if (fieldDoc.exists) {
          fieldName = fieldDoc.data()?['name'] ?? fieldName;
        }
      } catch (e) {
        print('[AI_RECOMMENDATIONS] ERROR getting field name: $e');
      }
    }

    // Cooldown check
    final alertKey = 'ai_${fieldId ?? 'unknown'}_$recommendation';
    if (!_shouldAlert(alertKey, const Duration(hours: 6))) {
      print('[AI_RECOMMENDATIONS] Alert cooldown active, skipping notification');
      return;
    }

    String title = '';
    String body = '';
    NotificationType notificationType;

    switch (recommendation.toLowerCase()) {
      case 'irrigate':
        title = '💧 AI Recommendation: Irrigate';
        body = 'AI suggests irrigating $fieldName now. ${reason ?? ""}';
        notificationType = NotificationType.aiIrrigate;

        // Create in-app alert
        await _firestore.collection('alerts').add({
          'userId': data['userId'],
          'fieldId': fieldId,
          'fieldName': fieldName,
          'type': 'ai_irrigate',
          'severity': 'high',
          'message': 'AI recommends irrigation for $fieldName. ${reason ?? ""}',
          'confidence': confidence,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
        break;

      case 'hold':
        title = '⏸️ AI Recommendation: Hold';
        body = 'AI suggests holding irrigation for $fieldName. ${reason ?? ""}';
        notificationType = NotificationType.aiHold;

        await _firestore.collection('alerts').add({
          'userId': data['userId'],
          'fieldId': fieldId,
          'fieldName': fieldName,
          'type': 'ai_hold',
          'severity': 'low',
          'message': 'AI recommends holding irrigation for $fieldName. ${reason ?? ""}',
          'confidence': confidence,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
        break;

      case 'alert':
        title = '⚠️ AI Alert';
        body = 'AI detected an issue with $fieldName. ${reason ?? "Check your system."}';
        notificationType = NotificationType.aiAlert;

        await _firestore.collection('alerts').add({
          'userId': data['userId'],
          'fieldId': fieldId,
          'fieldName': fieldName,
          'type': 'ai_alert',
          'severity': 'critical',
          'message': 'AI alert for $fieldName: ${reason ?? "System check needed."}',
          'confidence': confidence,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
        break;

      default:
        print('[AI_RECOMMENDATIONS] Unknown recommendation type: $recommendation');
        return;
    }

    if (title.isNotEmpty) {
      print('[AI_RECOMMENDATIONS] Sending notification: $title');
      await _showNotification(
        title: title,
        body: body,
        type: notificationType,
      );
      _recordAlert(alertKey);
      print('[AI_RECOMMENDATIONS] Notification sent successfully');
    }
  }

  /// ENHANCED: Listen to irrigation status changes with notifications
  void _setupIrrigationListener(String userId) {
    print('[IRRIGATION] Setting up listener for userId: $userId');

    final listener = _firestore
        .collection('irrigation_cycles')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      print('[IRRIGATION] Snapshot received - size: ${snapshot.size}, changes: ${snapshot.docChanges.length}');

      try {
        for (var change in snapshot.docChanges) {
          print('[IRRIGATION] Change type: ${change.type.name}, docId: ${change.doc.id}');
          print('[IRRIGATION] Document data: ${change.doc.data()}');

          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            await _handleIrrigationStatusChange(
              change.doc.id,
              change.doc.data()!,
            );
          }
        }
      } catch (e, stackTrace) {
        print('[IRRIGATION] ERROR in handler: $e');
        print(stackTrace);
      }
    }, onError: (e, stackTrace) {
      print('[IRRIGATION] ERROR in stream: $e');
      print(stackTrace);
    });

    _listeners.add(listener);
    print('[IRRIGATION] Listener attached successfully');
  }

  /// ENHANCED: Handle irrigation status changes with in-app alerts
  Future<void> _handleIrrigationStatusChange(String cycleId, Map<String, dynamic> data) async {
    print('[IRRIGATION] Handler called for cycle: $cycleId');
    print('[IRRIGATION] Data: $data');

    final status = data['status'] as String?;
    final userId = data['userId'] as String?;

    if (status == null || userId == null) {
      print('[IRRIGATION] ERROR: Missing status or userId field in data!');
      return;
    }

    final fieldId = data['fieldId'] as String?;
    String fieldName = 'your field';

    if (fieldId != null) {
      try {
        final fieldDoc = await _firestore.collection('fields').doc(fieldId).get();
        if (fieldDoc.exists) {
          fieldName = fieldDoc.data()?['name'] ?? fieldName;
          print('[IRRIGATION] Field name: $fieldName');
        }
      } catch (e) {
        print('[IRRIGATION] ERROR getting field name: $e');
      }
    }

    String title = '';
    String body = '';
    String alertType = '';
    String severity = 'medium';
    NotificationType notificationType;

    switch (status) {
      case 'running':
        title = '▶️ Irrigation Started';
        body = 'Irrigation has started for $fieldName.';
        alertType = 'irrigation_started';
        severity = 'medium';
        notificationType = NotificationType.irrigationStarted;
        break;

      case 'completed':
        final waterUsed = data['waterUsed'] ?? 0;
        final duration = data['duration'] ?? 0;
        title = '✅ Irrigation Completed';
        body = 'Irrigation completed for $fieldName. Water used: ${waterUsed}L in ${duration}min.';
        alertType = 'irrigation_completed';
        severity = 'low';
        notificationType = NotificationType.irrigationCompleted;
        break;

      case 'stopped':
        title = '⏹️ Irrigation Stopped';
        body = 'Irrigation was manually stopped for $fieldName.';
        alertType = 'irrigation_stopped';
        severity = 'medium';
        notificationType = NotificationType.irrigationStopped;
        break;

      case 'failed':
        final errorMessage = data['errorMessage'] as String?;
        title = '❌ Irrigation Failed';
        body = 'Irrigation failed for $fieldName. ${errorMessage ?? "Please check the system."}';
        alertType = 'irrigation_failed';
        severity = 'critical';
        notificationType = NotificationType.irrigationFailed;
        break;

      default:
        print('[IRRIGATION] Unknown status: $status');
        return;
    }

    if (title.isNotEmpty) {
      // Create in-app alert
      try {
        await _firestore.collection('alerts').add({
          'userId': userId,
          'cycleId': cycleId,
          'fieldId': fieldId,
          'fieldName': fieldName,
          'type': alertType,
          'severity': severity,
          'message': body,
          'status': status,
          'waterUsed': data['waterUsed'],
          'duration': data['duration'],
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
        print('[IRRIGATION] In-app alert created');
      } catch (e) {
        print('[IRRIGATION] ERROR creating alert: $e');
      }

      // Send push notification
      print('[IRRIGATION] About to send notification - title: $title');
      await _showNotification(
        title: title,
        body: body,
        type: notificationType,
      );
      print('[IRRIGATION] Notification sent');
    }
  }

  /// Listen to sensor readings for moisture and water levels
  void _setupSensorReadingsListener(String userId) async {
    final sensorsSnapshot = await _firestore
        .collection('sensors')
        .where('userId', isEqualTo: userId)
        .get();

    final sensorIds = sensorsSnapshot.docs.map((doc) => doc.id).toList();

    if (sensorIds.isEmpty) {
      print('⚠️ No sensors found for user $userId');
      return;
    }

    print('✓ Found ${sensorIds.length} sensors for user: ${sensorIds.join(", ")}');

    for (var i = 0; i < sensorIds.length; i += 10) {
      final batch = sensorIds.skip(i).take(10).toList();

      final listener = _firestore
          .collectionGroup('sensor_readings')
          .where('sensorId', whereIn: batch)
          .snapshots()
          .listen((snapshot) async {
        print('📡 sensor_readings snapshot: size=${snapshot.size} changes=${snapshot.docChanges.length}');
        try {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              print('🔔 New sensor reading: ${change.doc.id} - sensorId: ${data['sensorId']}, value: ${data['value']}, type: ${data['type']}');
              await _handleNewSensorReading(change.doc.id, data);

              final sensorId = data['sensorId'] as String?;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              if (sensorId != null) {
                await _firestore.collection('sensors').doc(sensorId).update({
                  'lastSeen': Timestamp.fromDate(timestamp),
                });
              }
            }
          }
        } catch (e, stackTrace) {
          print('❌ Sensor readings listener handler error: $e\n$stackTrace');
        }
      }, onError: (e, stackTrace) {
        print('❌ Sensor readings stream error: $e\n$stackTrace');
      });

      _listeners.add(listener);
    }

    print('✓ Sensor readings listener setup for ${sensorIds.length} sensors');
  }

  void _setupScheduleListener(String userId) {
    final listener = _firestore
        .collection('irrigation_schedules')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      print('📡 irrigation_schedules snapshot: size=${snapshot.size}');
      _checkScheduleReminders();
    });

    _listeners.add(listener);
    print('✓ Schedule listener setup for user $userId');
  }

  /// ENHANCED: Listen to alerts with expanded alert types
  void _setupAlertsListener(String userId) {
    print('[ALERTS] Setting up listener for userId: $userId');

    final listener = _firestore
        .collection('alerts')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) async {
      print('[ALERTS] Snapshot received - size: ${snapshot.size}, changes: ${snapshot.docChanges.length}');

      try {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            print('[ALERTS] New alert detected - data: $data');

            final type = data['type'] as String?;
            final message = data['message'] as String?;

            print('[ALERTS] Type: $type, Message: $message');

            if (type != null && message != null) {
              final notificationData = _getNotificationDataForAlertType(type, data);

              await _showNotification(
                title: notificationData['title']!,
                body: message,
                type: notificationData['notificationType'] as NotificationType,
              );
            }
          }
        }
      } catch (e, stackTrace) {
        print('[ALERTS] ERROR in handler: $e');
        print(stackTrace);
      }
    }, onError: (e, stackTrace) {
      print('[ALERTS] ERROR in stream: $e');
      print(stackTrace);
    });

    _listeners.add(listener);
    print('[ALERTS] Listener attached successfully');
  }

  /// ENHANCED: Get notification data for all alert types
  Map<String, dynamic> _getNotificationDataForAlertType(String type, Map<String, dynamic> data) {
    switch (type) {
    // Existing alert types
      case 'irrigation_needed':
        return {
          'title': '💧 Irrigation Needed',
          'notificationType': NotificationType.irrigationNeeded,
        };
      case 'water_low':
        return {
          'title': '⚠️ Low Water Level',
          'notificationType': NotificationType.waterLow,
        };
      case 'rain_forecast':
        return {
          'title': '🌧️ Rain Forecast',
          'notificationType': NotificationType.rainForecast,
        };
      case 'sensor_offline':
        return {
          'title': '📴 Sensor Offline',
          'notificationType': NotificationType.sensorOffline,
        };
      case 'schedule_reminder':
        return {
          'title': '⏰ Irrigation Reminder',
          'notificationType': NotificationType.scheduleReminder,
        };

    // NEW: Irrigation status alerts
      case 'irrigation_started':
        return {
          'title': '▶️ Irrigation Started',
          'notificationType': NotificationType.irrigationStarted,
        };
      case 'irrigation_completed':
        return {
          'title': '✅ Irrigation Completed',
          'notificationType': NotificationType.irrigationCompleted,
        };
      case 'irrigation_stopped':
        return {
          'title': '⏹️ Irrigation Stopped',
          'notificationType': NotificationType.irrigationStopped,
        };
      case 'irrigation_failed':
        return {
          'title': '❌ Irrigation Failed',
          'notificationType': NotificationType.irrigationFailed,
        };

    // NEW: AI recommendation alerts
      case 'ai_irrigate':
        return {
          'title': '💧 AI: Irrigate Now',
          'notificationType': NotificationType.aiIrrigate,
        };
      case 'ai_hold':
        return {
          'title': '⏸️ AI: Hold Irrigation',
          'notificationType': NotificationType.aiHold,
        };
      case 'ai_alert':
        return {
          'title': '⚠️ AI Alert',
          'notificationType': NotificationType.aiAlert,
        };

      default:
        return {
          'title': '🔔 Alert',
          'notificationType': NotificationType.generic,
        };
    }
  }

  void _startPeriodicChecks() {
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _checkScheduleReminders();
      _recheckLevels();
      _detectOfflineSensors(const Duration(hours: 3));
    });

    Future.delayed(const Duration(minutes: 1), () {
      _detectOfflineSensors(const Duration(hours: 3));
    });

    print('✓ Periodic checks started');
  }

  void _startWeatherChecks() {
    _checkWeather();
    _weatherCheckTimer = Timer.periodic(const Duration(hours: 3), (timer) {
      _checkWeather();
    });
    print('✓ Weather checks started');
  }

  Future<void> _checkWeather() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final fieldsSnapshot = await _firestore
          .collection('fields')
          .where('userId', isEqualTo: userId)
          .get();

      for (var fieldDoc in fieldsSnapshot.docs) {
        final field = fieldDoc.data();
        final latitude = field['latitude'] as num?;
        final longitude = field['longitude'] as num?;
        final fieldName = field['name'] as String? ?? 'your field';

        if (latitude != null && longitude != null) {
          final rainData = await _fetchWeatherData(latitude.toDouble(), longitude.toDouble());

          if (rainData != null) {
            final willRain = rainData['willRain'] as bool;
            final rainTime = rainData['rainTime'] as String?;
            final rainProbability = rainData['probability'] as int?;

            if (willRain && rainTime != null) {
              final alertKey = 'rain_${fieldDoc.id}';

              if (!_shouldAlert(alertKey, const Duration(hours: 12))) {
                continue;
              }

              await _firestore.collection('alerts').add({
                'userId': userId,
                'fieldId': fieldDoc.id,
                'fieldName': fieldName,
                'type': 'rain_forecast',
                'severity': 'low',
                'message': 'Rain expected $rainTime. Consider postponing irrigation for $fieldName.',
                'rainProbability': rainProbability,
                'timestamp': FieldValue.serverTimestamp(),
                'read': false,
              });

              await _showNotification(
                title: '🌧️ Rain Forecast',
                body: 'Rain expected $rainTime for $fieldName. Hold off on irrigation! (${rainProbability ?? 0}% chance)',
                type: NotificationType.rainForecast,
              );

              _recordAlert(alertKey);
            }
          }
        }
      }
    } catch (e) {
      print('Error checking weather: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchWeatherData(double lat, double lon) async {
    try {
      const apiKey = '7d3f7f3f3f3f3f3f3f3f3f3f3f3f3f3f'; // PLACEHOLDER
      final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final forecasts = data['list'] as List;

        final now = DateTime.now();
        final next24Hours = now.add(const Duration(hours: 24));

        for (var forecast in forecasts) {
          final dt = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);

          if (dt.isAfter(now) && dt.isBefore(next24Hours)) {
            final weather = forecast['weather'] as List;
            final pop = ((forecast['pop'] ?? 0) * 100).toInt();

            if (weather.isNotEmpty) {
              final condition = weather[0]['main'] as String;

              if (condition == 'Rain' || condition == 'Drizzle' || condition == 'Thunderstorm') {
                final hoursUntil = dt.difference(now).inHours;
                final rainTime = hoursUntil < 1
                    ? 'within the hour'
                    : hoursUntil < 6
                    ? 'in $hoursUntil hours'
                    : 'today';

                return {
                  'willRain': true,
                  'rainTime': rainTime,
                  'probability': pop,
                  'condition': condition,
                };
              }
            }
          }
        }
      } else {
        print('Weather API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }

    return null;
  }

  Future<void> _handleNewSensorReading(String readingId, Map<String, dynamic> data) async {
    print('➡️ _handleNewSensorReading readingId=$readingId data=$data');

    final sensorId = data['sensorId'] as String?;
    final value = data['value'] as num?;

    if (sensorId == null || value == null) {
      print('⚠️ Missing sensorId or value in reading');
      return;
    }

    try {
      final sensorDoc = await _firestore.collection('sensors').doc(sensorId).get();
      if (!sensorDoc.exists) {
        print('⚠️ Sensor $sensorId not found');
        return;
      }

      final sensor = sensorDoc.data()!;
      final sensorType = sensor['type'] as String?;
      final userId = sensor['userId'] as String?;

      print('📊 Sensor type=$sensorType value=${value.toDouble()} userId=$userId');

      if (userId != FirebaseAuth.instance.currentUser?.uid) {
        print('⚠️ Sensor belongs to different user, skipping');
        return;
      }

      if (sensorType == 'soil_moisture') {
        await _checkMoistureLevel(sensorId, sensor, value.toDouble());
      } else if (sensorType == 'water_level') {
        await _checkWaterLevel(sensorId, sensor, value.toDouble());
      } else {
        print('⚠️ Unknown sensor type: $sensorType');
      }
    } catch (e, stackTrace) {
      print('❌ Error handling sensor reading: $e\n$stackTrace');
    }
  }

  Future<void> _checkMoistureLevel(String sensorId, Map<String, dynamic> sensor, double moistureLevel) async {
    final threshold = (sensor['lowThreshold'] ?? 50.0) as num;

    if (moistureLevel < threshold) {
      final alertKey = 'moisture_$sensorId';

      if (!_shouldAlert(alertKey, const Duration(hours: 6))) {
        return;
      }

      final fieldId = sensor['fieldId'] as String?;
      String fieldName = 'Unknown Field';

      if (fieldId != null) {
        final fieldDoc = await _firestore.collection('fields').doc(fieldId).get();
        if (fieldDoc.exists) {
          fieldName = fieldDoc.data()?['name'] ?? fieldName;
        }
      }

      await _firestore.collection('alerts').add({
        'userId': sensor['userId'],
        'fieldId': fieldId,
        'fieldName': fieldName,
        'sensorId': sensorId,
        'sensorName': sensor['name'],
        'type': 'irrigation_needed',
        'severity': 'medium',
        'message': 'Soil moisture is low (${moistureLevel.toStringAsFixed(1)}%) in $fieldName. Irrigation recommended.',
        'moistureLevel': moistureLevel,
        'threshold': threshold,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await _showNotification(
        title: '💧 Irrigation Needed',
        body: 'Soil moisture is low (${moistureLevel.toStringAsFixed(1)}%) in $fieldName. Time to irrigate!',
        type: NotificationType.irrigationNeeded,
      );

      _recordAlert(alertKey);
    }
  }

  Future<void> _checkWaterLevel(String sensorId, Map<String, dynamic> sensor, double waterLevel) async {
    final lowThreshold = (sensor['lowThreshold'] ?? 20.0) as num;
    final criticalThreshold = (sensor['criticalThreshold'] ?? 10.0) as num;

    String? severity;
    num? threshold;

    if (waterLevel <= criticalThreshold) {
      severity = 'critical';
      threshold = criticalThreshold;
    } else if (waterLevel <= lowThreshold) {
      severity = 'medium';
      threshold = lowThreshold;
    }

    if (severity != null) {
      final alertKey = 'water_$sensorId';

      if (!_shouldAlert(alertKey, const Duration(hours: 4))) {
        return;
      }

      final fieldId = sensor['fieldId'] as String?;
      String fieldName = 'Unknown Field';

      if (fieldId != null) {
        final fieldDoc = await _firestore.collection('fields').doc(fieldId).get();
        if (fieldDoc.exists) {
          fieldName = fieldDoc.data()?['name'] ?? fieldName;
        }
      }

      await _firestore.collection('alerts').add({
        'userId': sensor['userId'],
        'fieldId': fieldId,
        'fieldName': fieldName,
        'sensorId': sensorId,
        'sensorName': sensor['name'],
        'type': 'water_low',
        'severity': severity,
        'message': 'Water level is ${severity == 'critical' ? 'critically' : ''} low (${waterLevel.toStringAsFixed(1)}%) at ${sensor['name']}.',
        'waterLevel': waterLevel,
        'threshold': threshold,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      final title = severity == 'critical'
          ? '🚨 Critical: Water Level Alert'
          : '⚠️ Low Water Level';
      final body = 'Water level is ${severity == 'critical' ? 'critically' : ''} low (${waterLevel.toStringAsFixed(1)}%) at ${sensor['name']}.';

      await _showNotification(
        title: title,
        body: body,
        type: NotificationType.waterLow,
      );

      _recordAlert(alertKey);
    }
  }

  Future<void> _checkScheduleReminders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final now = DateTime.now();
      final in30Minutes = now.add(const Duration(minutes: 30));
      final in35Minutes = now.add(const Duration(minutes: 35));

      final schedulesSnapshot = await _firestore
          .collection('irrigation_schedules')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      for (var scheduleDoc in schedulesSnapshot.docs) {
        final schedule = scheduleDoc.data();
        final scheduleTime = (schedule['scheduledTime'] as Timestamp?)?.toDate();

        if (scheduleTime == null) continue;

        if (scheduleTime.isAfter(in30Minutes) && scheduleTime.isBefore(in35Minutes)) {
          final reminderKey = 'schedule_${scheduleDoc.id}';

          if (!_shouldAlert(reminderKey, const Duration(hours: 1))) {
            continue;
          }

          final fieldId = schedule['fieldId'];
          String fieldName = 'your field';

          if (fieldId != null) {
            final fieldDoc = await _firestore.collection('fields').doc(fieldId).get();
            if (fieldDoc.exists) {
              fieldName = fieldDoc.data()?['name'] ?? fieldName;
            }
          }

          final minutesUntil = scheduleTime.difference(now).inMinutes;

          await _showNotification(
            title: '⏰ Irrigation Reminder',
            body: 'Irrigation scheduled for $fieldName in $minutesUntil minutes.',
            type: NotificationType.scheduleReminder,
          );

          _recordAlert(reminderKey);
        }
      }
    } catch (e) {
      print('Error checking schedules: $e');
    }
  }

  Future<void> _recheckLevels() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final sensorsSnapshot = await _firestore
          .collection('sensors')
          .where('userId', isEqualTo: userId)
          .get();

      for (var sensorDoc in sensorsSnapshot.docs) {
        final sensor = sensorDoc.data();
        final sensorType = sensor['type'] as String?;

        final readingsSnapshot = await _firestore
            .collection('sensor_readings')
            .where('sensorId', isEqualTo: sensorDoc.id)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (readingsSnapshot.docs.isNotEmpty) {
          final reading = readingsSnapshot.docs.first.data();
          final value = (reading['value'] as num?)?.toDouble();

          if (value != null) {
            if (sensorType == 'soil_moisture') {
              await _checkMoistureLevel(sensorDoc.id, sensor, value);
            } else if (sensorType == 'water_level') {
              await _checkWaterLevel(sensorDoc.id, sensor, value);
            }
          }
        }
      }
    } catch (e) {
      print('Error rechecking levels: $e');
    }
  }

  Future<void> _detectOfflineSensors(Duration threshold) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final cutoff = DateTime.now().subtract(threshold);
      final sensorsSnapshot = await _firestore
          .collection('sensors')
          .where('userId', isEqualTo: userId)
          .get();

      for (var sensorDoc in sensorsSnapshot.docs) {
        final sensor = sensorDoc.data();
        final sensorName = sensor['name'] ?? 'Sensor';
        final lastSeenTimestamp = sensor['lastSeen'] as Timestamp?;
        DateTime? effectiveLastSeen = lastSeenTimestamp?.toDate();

        if (effectiveLastSeen == null) {
          final readingsSnapshot = await _firestore
              .collection('sensor_readings')
              .where('sensorId', isEqualTo: sensorDoc.id)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (readingsSnapshot.docs.isNotEmpty) {
            final reading = readingsSnapshot.docs.first.data();
            effectiveLastSeen = (reading['timestamp'] as Timestamp?)?.toDate();
            if (effectiveLastSeen != null) {
              await sensorDoc.reference.update({
                'lastSeen': Timestamp.fromDate(effectiveLastSeen),
              });
            }
          }
        }

        if (effectiveLastSeen == null || effectiveLastSeen.isBefore(cutoff)) {
          final alertKey = 'offline_${sensorDoc.id}';
          if (!_shouldAlert(alertKey, const Duration(hours: 6))) {
            continue;
          }

          final fieldId = sensor['fieldId'] as String?;
          String fieldName = 'Unknown Field';
          if (fieldId != null) {
            final fieldDoc = await _firestore.collection('fields').doc(fieldId).get();
            if (fieldDoc.exists) {
              fieldName = fieldDoc.data()?['name'] ?? fieldName;
            }
          }

          final hoursOffline = effectiveLastSeen != null
              ? DateTime.now().difference(effectiveLastSeen).inHours
              : threshold.inHours;

          await _firestore.collection('alerts').add({
            'userId': userId,
            'sensorId': sensorDoc.id,
            'sensorName': sensorName,
            'fieldId': fieldId,
            'fieldName': fieldName,
            'type': 'sensor_offline',
            'severity': 'high',
            'message': '$sensorName in $fieldName has not reported in $hoursOffline hours.',
            'lastSeen': effectiveLastSeen,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });

          _recordAlert(alertKey);
        }
      }
    } catch (e) {
      print('❌ Error detecting offline sensors: $e');
    }
  }

  /// ENHANCED: Show notification with type-based styling
  Future<void> _showNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    try {
      print('[NOTIFICATION] Attempting to show: $title (type: ${type.name})');

      // Get color and priority based on notification type
      final notificationConfig = _getNotificationConfig(type);

      final androidDetails = AndroidNotificationDetails(
        'irrigation_alerts',
        'Irrigation Alerts',
        channelDescription: 'Critical irrigation and water level alerts',
        importance: notificationConfig['importance'] as Importance,
        priority: notificationConfig['priority'] as Priority,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        enableLights: true,
        ledColor: notificationConfig['ledColor'] as Color,
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch;

      print('[NOTIFICATION] Calling show() with ID: $notificationId, title: $title, body: $body');
      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformDetails,
      );

      print('[NOTIFICATION] show() completed successfully');
    } catch (e, stackTrace) {
      print('[NOTIFICATION] ERROR: $e');
      print(stackTrace);
    }
  }

  /// Get notification configuration based on type
  Map<String, dynamic> _getNotificationConfig(NotificationType type) {
    switch (type) {
      case NotificationType.irrigationFailed:
      case NotificationType.waterLow:
      case NotificationType.aiAlert:
        return {
          'importance': Importance.max,
          'priority': Priority.high,
          'ledColor': const Color(0xFFFF0000), // Red for critical
        };

      case NotificationType.aiIrrigate:
      case NotificationType.irrigationNeeded:
      case NotificationType.sensorOffline:
        return {
          'importance': Importance.high,
          'priority': Priority.high,
          'ledColor': const Color(0xFFFF9800), // Orange for important
        };

      case NotificationType.irrigationStarted:
      case NotificationType.aiHold:
      case NotificationType.scheduleReminder:
        return {
          'importance': Importance.defaultImportance,
          'priority': Priority.defaultPriority,
          'ledColor': const Color(0xFF2196F3), // Blue for info
        };

      case NotificationType.irrigationCompleted:
      case NotificationType.rainForecast:
        return {
          'importance': Importance.defaultImportance,
          'priority': Priority.low,
          'ledColor': const Color(0xFF4CAF50), // Green for success
        };

      default:
        return {
          'importance': Importance.defaultImportance,
          'priority': Priority.defaultPriority,
          'ledColor': const Color(0xFF4CAF50), // Green default
        };
    }
  }

  bool _shouldAlert(String key, Duration cooldown) {
    final lastAlert = _lastAlertTimes[key];
    if (lastAlert == null) return true;

    return DateTime.now().difference(lastAlert) > cooldown;
  }

  void _recordAlert(String key) {
    _lastAlertTimes[key] = DateTime.now();
  }

  void dispose() {
    _authSubscription?.cancel();
    for (var listener in _listeners) {
      listener.cancel();
    }
    _listeners.clear();
    _periodicCheckTimer?.cancel();
    _weatherCheckTimer?.cancel();
    print('✓ Notification service disposed');
  }
}

/// Notification types for categorization and styling
enum NotificationType {
  // Test
  test,

  // Irrigation status
  irrigationStarted,
  irrigationCompleted,
  irrigationStopped,
  irrigationFailed,

  // AI recommendations
  aiIrrigate,
  aiHold,
  aiAlert,

  // Sensor alerts
  irrigationNeeded,
  waterLow,
  sensorOffline,

  // Schedule & Weather
  scheduleReminder,
  rainForecast,

  // Generic
  generic,
}