import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

/// Local notification service that handles all notifications without Cloud Functions
/// Uses Firestore listeners for real-time monitoring
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
    print('Initializing Notification Service...');
    await _requestNotificationPermissions();
    await _setupLocalNotifications();
    _setupAuthBoundListeners();
    // Don't start periodic checks here - wait for auth
    print('Notification Service initialized');
  }

  /// Send a test notification (can be called manually)
  Future<void> sendTestNotification() async {
    await _showNotification(
      title: '🧪 Test Notification',
      body: 'If you see this, your notifications are working perfectly!',
    );
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

    await _localNotifications.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'irrigation_alerts',
      'Irrigation Alerts',
      description: 'Notifications for irrigation and water level alerts',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('✓ Notification service initialized');
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

    // CRITICAL FIX: Attach immediately if user is already signed in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('🔥 User already logged in, attaching listeners immediately');
      _attachListenersFor(currentUser.uid);
    } else {
      print('⚠️ No user currently logged in');
    }

    // Then listen for auth changes
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
        return; // Already attached
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
    
    // Start periodic checks ONLY after login
    _periodicCheckTimer?.cancel();
    _weatherCheckTimer?.cancel();
    _startPeriodicChecks();
    _startWeatherChecks();
  }

  /// Listen to irrigation status changes in real-time
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

  /// Listen to sensor readings for moisture and water levels
  void _setupSensorReadingsListener(String userId) async {
    // First, get all user's sensor IDs
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

    // Use collectionGroup to catch readings in any location
    // Firestore whereIn limit is 10, so batch if needed
    for (var i = 0; i < sensorIds.length; i += 10) {
      final batch = sensorIds.skip(i).take(10).toList();
      
      final listener = _firestore
          .collectionGroup('sensor_readings')  // Use collectionGroup instead of collection
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
              
              // Update sensor lastSeen timestamp
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

  /// Listen to schedules for reminders
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

  /// Listen to alerts for in-app notifications
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
              await _showNotification(
                title: _getTitleForAlertType(type),
                body: message,
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

  String _getTitleForAlertType(String type) {
    switch (type) {
      case 'irrigation_needed':
        return '💧 Irrigation Needed';
      case 'water_low':
        return '⚠️ Low Water Level';
      case 'rain_forecast':
        return '🌧️ Rain Forecast';
      case 'sensor_offline':
        return '📴 Sensor Offline';
      case 'schedule_reminder':
        return '⏰ Irrigation Reminder';
      default:
        return '🔔 Alert';
    }
  }

  /// Start periodic checks every 30 minutes
  void _startPeriodicChecks() {
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _checkScheduleReminders();
      _recheckLevels();
      _detectOfflineSensors(const Duration(hours: 3));
    });
    
    // Initial check for offline sensors
    Future.delayed(const Duration(minutes: 1), () {
      _detectOfflineSensors(const Duration(hours: 3));
    });
    
    print('✓ Periodic checks started');
  }

  /// Start weather checks every 3 hours
  void _startWeatherChecks() {
    _checkWeather(); // Check immediately
    _weatherCheckTimer = Timer.periodic(const Duration(hours: 3), (timer) {
      _checkWeather();
    });
    print('✓ Weather checks started');
  }

  /// Check weather for rain forecast
  Future<void> _checkWeather() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Get user's fields with location data
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

  /// Fetch weather data from OpenWeatherMap API
  Future<Map<String, dynamic>?> _fetchWeatherData(double lat, double lon) async {
    try {
      // Free OpenWeatherMap API key - replace with your own for production
      const apiKey = '7d3f7f3f3f3f3f3f3f3f3f3f3f3f3f3f'; // PLACEHOLDER - user needs their own key
      final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final forecasts = data['list'] as List;

        // Check next 24 hours for rain
        final now = DateTime.now();
        final next24Hours = now.add(const Duration(hours: 24));

        for (var forecast in forecasts) {
          final dt = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
          
          if (dt.isAfter(now) && dt.isBefore(next24Hours)) {
            final weather = forecast['weather'] as List;
            final pop = ((forecast['pop'] ?? 0) * 100).toInt(); // Probability of precipitation
            
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

  Future<void> _handleIrrigationStatusChange(String cycleId, Map<String, dynamic> data) async {
    print('[IRRIGATION] Handler called for cycle: $cycleId');
    print('[IRRIGATION] Data: $data');
    
    final status = data['status'] as String?;
    print('[IRRIGATION] Status extracted: $status');
    
    if (status == null) {
      print('[IRRIGATION] ERROR: No status field in data!');
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

    switch (status) {
      case 'running':
        title = 'Irrigation Started';
        body = 'Irrigation has started for $fieldName.';
        break;
      case 'completed':
        final waterUsed = data['waterUsed'] ?? 0;
        title = 'Irrigation Completed';
        body = 'Irrigation completed for $fieldName. Total water used: ${waterUsed}L';
        break;
      case 'stopped':
        title = 'Irrigation Stopped';
        body = 'Irrigation was manually stopped for $fieldName.';
        break;
      case 'failed':
        title = 'Irrigation Failed';
        body = 'Irrigation failed for $fieldName. Please check the system.';
        break;
      default:
        print('[IRRIGATION] Unknown status: $status');
    }

    if (title.isNotEmpty) {
      print('[IRRIGATION] About to send notification - title: $title');
      await _showNotification(title: title, body: body);
      print('[IRRIGATION] Notification sent');
    } else {
      print('[IRRIGATION] ERROR: No title generated, notification not sent');
    }
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

      await _showNotification(title: title, body: body);

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

  /// Detect sensors that haven't reported in a while
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

        // If no lastSeen, check latest reading
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
            // Update lastSeen for future checks
            if (effectiveLastSeen != null) {
              await sensorDoc.reference.update({
                'lastSeen': Timestamp.fromDate(effectiveLastSeen),
              });
            }
          }
        }

        // Check if sensor is offline
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

          // Record only real alert in Firestore. Remove local test notification display.
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

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    try {
      print('[NOTIFICATION] Attempting to show: $title');
      
      final androidDetails = const AndroidNotificationDetails(
        'irrigation_alerts',
        'Irrigation Alerts',
        channelDescription: 'Notifications for irrigation management',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
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

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
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
