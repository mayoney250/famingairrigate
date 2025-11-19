import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fcm_service.dart';
import '../services/notification_service.dart';
import '../config/colors.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String? _fcmToken;
  bool _isLoading = false;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getFCMToken();
    await _checkFirestoreTokens();
  }

  Future<void> _getFCMToken() async {
    setState(() {
      _isLoading = true;
      _logs.add('📱 Fetching FCM token...');
    });

    try {
      final fcmService = FCMService();
      final token = await fcmService.getToken();
      setState(() {
        _fcmToken = token;
        if (token != null) {
          _logs.add('✅ FCM Token retrieved successfully');
          _logs.add('Token: ${token.substring(0, 20)}...');
        } else {
          _logs.add('❌ FCM Token is null');
        }
      });
    } catch (e) {
      setState(() {
        _logs.add('❌ Error getting FCM token: $e');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFirestoreTokens() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _logs.add('❌ User not logged in'));
      return;
    }

    setState(() => _logs.add('🔍 Checking Firestore for saved tokens...'));

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final tokens = data?['fcmTokens'] as List?;
        if (tokens != null && tokens.isNotEmpty) {
          setState(() {
            _logs.add('✅ Found ${tokens.length} token(s) in Firestore');
            for (var i = 0; i < tokens.length; i++) {
              _logs.add('  Token $i: ${tokens[i].toString().substring(0, 20)}...');
            }
          });
        } else {
          setState(() => _logs.add('⚠️ No tokens found in Firestore'));
        }
      } else {
        setState(() => _logs.add('❌ User document not found'));
      }
    } catch (e) {
      setState(() => _logs.add('❌ Error checking Firestore: $e'));
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
      _logs.add('🧪 Sending test notification...');
    });

    try {
      await NotificationService().sendTestNotification();
      setState(() => _logs.add('✅ Test notification sent'));
    } catch (e) {
      setState(() => _logs.add('❌ Error sending test notification: $e'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reinitializeFCM() async {
    setState(() {
      _isLoading = true;
      _logs.add('🔄 Reinitializing FCM...');
    });

    try {
      await FCMService().initialize();
      setState(() => _logs.add('✅ FCM reinitialized'));
      await _getFCMToken();
      await _checkFirestoreTokens();
    } catch (e) {
      setState(() => _logs.add('❌ Error reinitializing FCM: $e'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Diagnostics'),
        backgroundColor: FamingaBrandColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FCM Token Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_fcmToken != null) ...[
                      SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _copyToken,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Token'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FamingaBrandColors.primaryOrange,
                        ),
                      ),
                    ] else
                      const Text(
                        'No token available',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendTestNotification,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Send Test Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FamingaBrandColors.darkGreen,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                        _logs.add('🚀 Sending DIRECT test notification...');
                      });
                      try {
                        await NotificationService().sendDirectTestNotification();
                        setState(() => _logs.add('✅ Direct test notification sent - CHECK NOTIFICATION BAR!'));
                      } catch (e) {
                        setState(() => _logs.add('❌ Error: $e'));
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
              icon: const Icon(Icons.send),
              label: const Text('Send Direct Test (System Tray)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _reinitializeFCM,
              icon: const Icon(Icons.refresh),
              label: const Text('Reinitialize FCM'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FamingaBrandColors.primaryOrange,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _logs.clear();
                        _logs.add('🔄 Refreshing...');
                      });
                      await _initialize();
                    },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Logs Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Diagnostic Logs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _logs.clear());
                          },
                          icon: const Icon(Icons.clear_all),
                          tooltip: 'Clear logs',
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_logs.isEmpty)
                      const Text(
                        'No logs yet',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...List.generate(
                        _logs.length,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _logs[i],
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Testing Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Check that FCM Token is displayed above\n'
                      '2. Verify token exists in Firestore\n'
                      '3. Click "Send Test Notification" to test local notifications\n'
                      '4. Use Firebase Console to send push notifications:\n'
                      '   • Copy the FCM token\n'
                      '   • Go to Firebase Console > Cloud Messaging\n'
                      '   • Send test message to this token\n'
                      '5. Check app logs for FCM initialization messages',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
