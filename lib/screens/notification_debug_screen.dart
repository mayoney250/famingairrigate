import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationDebugScreen extends StatelessWidget {
  const NotificationDebugScreen({Key? key}) : super(key: key);

  Future<void> _showTestNotification(String title, String body) async {
    final localNotifications = FlutterLocalNotificationsPlugin();
    
    const androidDetails = AndroidNotificationDetails(
      'irrigation_alerts',
      'Irrigation Alerts',
      channelDescription: 'Notifications for irrigation management',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Test Notifications',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap each button to test different notification types. '
            'Check your notification tray after tapping.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          _buildTestButton(
            context,
            icon: Icons.water_drop,
            title: 'Test Irrigation Started',
            color: Colors.blue,
            onPressed: () async {
              await _showTestNotification(
                '💧 Irrigation Started',
                'Test: Irrigation has started for North Field.',
              );
              _showSnackBar(context, 'Irrigation notification sent!');
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildTestButton(
            context,
            icon: Icons.check_circle,
            title: 'Test Irrigation Completed',
            color: Colors.green,
            onPressed: () async {
              await _showTestNotification(
                '✅ Irrigation Completed',
                'Test: Irrigation completed. Total water used: 150L',
              );
              _showSnackBar(context, 'Completion notification sent!');
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildTestButton(
            context,
            icon: Icons.opacity,
            title: 'Test Low Moisture',
            color: Colors.orange,
            onPressed: () async {
              await _showTestNotification(
                '💧 Irrigation Needed',
                'Test: Soil moisture is low (45%) in North Field. Time to irrigate!',
              );
              _showSnackBar(context, 'Moisture alert sent!');
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildTestButton(
            context,
            icon: Icons.water,
            title: 'Test Low Water Level',
            color: Colors.red,
            onPressed: () async {
              await _showTestNotification(
                '⚠️ Low Water Level',
                'Test: Water level is low (15%) at Tank 1.',
              );
              _showSnackBar(context, 'Water alert sent!');
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildTestButton(
            context,
            icon: Icons.cloud,
            title: 'Test Rain Forecast',
            color: Colors.blueGrey,
            onPressed: () async {
              await _showTestNotification(
                '🌧️ Rain Forecast',
                'Test: Rain expected in 4 hours for North Field. Hold off on irrigation! (75% chance)',
              );
              _showSnackBar(context, 'Rain alert sent!');
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildTestButton(
            context,
            icon: Icons.sensors_off,
            title: 'Test Sensor Offline',
            color: Colors.grey,
            onPressed: () async {
              await _showTestNotification(
                '📴 Sensor Offline',
                'Test: Soil Sensor 1 has not reported in 5 hours. Check connection.',
              );
              _showSnackBar(context, 'Offline alert sent!');
            },
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () async {
              await _sendAllTests(context);
            },
            icon: const Icon(Icons.notification_important),
            label: const Text('Send All Test Notifications'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Divider(),
          
          const SizedBox(height: 16),
          
          const Text(
            'Instructions:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('1. Tap a button above'),
          const Text('2. Pull down your notification tray'),
          const Text('3. You should see the notification'),
          const Text('4. If not, check:'),
          const Text('   • App has notification permission'),
          const Text('   • Notification channel is enabled'),
          const Text('   • Battery optimization is off'),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Future<void> _sendAllTests(BuildContext context) async {
    _showSnackBar(context, 'Sending all notifications...');
    
    final notifications = [
      ('💧 Irrigation Started', 'Test: Irrigation has started'),
      ('✅ Irrigation Completed', 'Test: Irrigation completed'),
      ('💧 Irrigation Needed', 'Test: Soil moisture is low (45%)'),
      ('⚠️ Low Water Level', 'Test: Water level is low (15%)'),
      ('🌧️ Rain Forecast', 'Test: Rain expected in 4 hours'),
      ('📴 Sensor Offline', 'Test: Sensor has not reported in 5 hours'),
    ];
    
    for (var i = 0; i < notifications.length; i++) {
      await _showTestNotification(
        notifications[i].$1,
        notifications[i].$2,
      );
      if (i < notifications.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    
    if (context.mounted) {
      _showSnackBar(context, 'All ${notifications.length} notifications sent! Check notification tray.');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
