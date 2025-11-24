import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/colors.dart';

/// A diagnostic widget to test Firebase connection and data saving
/// Add this as a floating button or a screen in your app to diagnose issues
class FirebaseConnectionTester extends StatefulWidget {
  const FirebaseConnectionTester({super.key});

  @override
  State<FirebaseConnectionTester> createState() =>
      _FirebaseConnectionTesterState();
}

class _FirebaseConnectionTesterState extends State<FirebaseConnectionTester> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
    print(result);
  }

  Future<void> _runAllTests() async {
    setState(() {
      _testResults.clear();
      _isRunning = true;
    });

    _addResult('🚀 Starting Firebase Connection Tests...\n');

    // Test 1: Check Authentication
    await _testAuthentication();

    // Test 2: Check Firestore Connection
    await _testFirestoreConnection();

    // Test 3: Test Write Permission
    await _testWritePermission();

    // Test 4: Test Read Permission
    await _testReadPermission();

    // Test 5: Test User Data Write
    await _testUserDataWrite();

    // Test 6: Test Field Data Write
    await _testFieldDataWrite();

    setState(() {
      _isRunning = false;
    });

    _addResult('\n✅ All tests completed!');
  }

  Future<void> _testAuthentication() async {
    _addResult('📝 Test 1: Authentication Status');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _addResult('✅ User is authenticated');
        _addResult('   UID: ${user.uid}');
        _addResult('   Email: ${user.email}');
        _addResult('   Email Verified: ${user.emailVerified}');
      } else {
        _addResult('❌ No user authenticated!');
        _addResult('   Please log in first\n');
      }
    } catch (e) {
      _addResult('❌ Authentication check failed: $e\n');
    }
  }

  Future<void> _testFirestoreConnection() async {
    _addResult('\n📝 Test 2: Firestore Connection');
    try {
      final firestore = FirebaseFirestore.instance;
      _addResult('✅ Firestore instance created');
      _addResult('   App: ${firestore.app.name}');
    } catch (e) {
      _addResult('❌ Firestore connection failed: $e\n');
    }
  }

  Future<void> _testWritePermission() async {
    _addResult('\n📝 Test 3: Write Permission');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addResult('⏭️ Skipped (not authenticated)\n');
        return;
      }

      // Try to write to a test collection
      final testDoc = FirebaseFirestore.instance
          .collection('connection_tests')
          .doc('test_${DateTime.now().millisecondsSinceEpoch}');

      await testDoc.set({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Test write from app',
        'deviceInfo': 'Flutter Web/Mobile',
      });

      _addResult('✅ Write permission granted');
      _addResult('   Successfully wrote to: connection_tests');
      _addResult('   Document ID: ${testDoc.id}\n');
    } catch (e) {
      _addResult('❌ Write permission denied!');
      _addResult('   Error: $e');
      _addResult(
          '   This is why your data isn\'t saving!\n');
    }
  }

  Future<void> _testReadPermission() async {
    _addResult('📝 Test 4: Read Permission');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addResult('⏭️ Skipped (not authenticated)\n');
        return;
      }

      // Try to read from connection_tests
      final snapshot = await FirebaseFirestore.instance
          .collection('connection_tests')
          .limit(1)
          .get();

      _addResult('✅ Read permission granted');
      _addResult('   Retrieved ${snapshot.docs.length} document(s)\n');
    } catch (e) {
      _addResult('❌ Read permission denied!');
      _addResult('   Error: $e\n');
    }
  }

  Future<void> _testUserDataWrite() async {
    _addResult('📝 Test 5: User Collection Write');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addResult('⏭️ Skipped (not authenticated)\n');
        return;
      }

      // Try to update user document
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userDoc.set({
        'userId': user.uid,
        'email': user.email,
        'firstName': 'Test',
        'lastName': 'User',
        'lastTestUpdate': FieldValue.serverTimestamp(),
        'testFlag': true,
      }, SetOptions(merge: true));

      _addResult('✅ User document write successful');
      _addResult('   Updated document: users/${user.uid}\n');
    } catch (e) {
      _addResult('❌ User document write failed!');
      _addResult('   Error: $e');
      _addResult(
          '   This is why registration doesn\'t save user data!\n');
    }
  }

  Future<void> _testFieldDataWrite() async {
    _addResult('📝 Test 6: Fields Collection Write');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addResult('⏭️ Skipped (not authenticated)\n');
        return;
      }

      // Try to create a test field
      final fieldDoc = await FirebaseFirestore.instance.collection('fields').add({
        'userId': user.uid,
        'label': 'Test Field',
        'addedDate': DateTime.now().toIso8601String(),
        'size': 1.0,
        'isActive': true,
        'testField': true,
        'borderCoordinates': [],
      });

      _addResult('✅ Field document write successful');
      _addResult('   Created document: fields/${fieldDoc.id}');
      _addResult('   This means field creation should work!\n');
    } catch (e) {
      _addResult('❌ Field document write failed!');
      _addResult('   Error: $e');
      _addResult(
          '   This is why field data doesn\'t save!\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: FamingaBrandColors.primaryOrange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Firebase Diagnostic Tool',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This tool will test your Firebase connection and identify why data isn\'t saving.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runAllTests,
                  icon: _isRunning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isRunning ? 'Running Tests...' : 'Run Tests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FamingaBrandColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _testResults.isEmpty
                  ? Center(
                      child: Text(
                        'Tap "Run Tests" to start diagnostics',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        final result = _testResults[index];
                        Color textColor = Colors.white;

                        if (result.startsWith('✅')) {
                          textColor = Colors.greenAccent;
                        } else if (result.startsWith('❌')) {
                          textColor = Colors.redAccent;
                        } else if (result.startsWith('⏭️')) {
                          textColor = Colors.orangeAccent;
                        } else if (result.startsWith('📝')) {
                          textColor = Colors.cyanAccent;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            result,
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border(
                top: BorderSide(color: Colors.orange.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '💡 Quick Tips:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Make sure you\'re logged in before running tests\n'
                  '• Red ❌ messages show what\'s broken\n'
                  '• Green ✅ messages show what\'s working\n'
                  '• Check Firebase Console after tests',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple button to add to your dashboard for quick access
class FirebaseTestButton extends StatelessWidget {
  const FirebaseTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FirebaseConnectionTester(),
          ),
        );
      },
      icon: const Icon(Icons.bug_report),
      label: const Text('Test Firebase'),
      backgroundColor: Colors.red,
    );
  }
}

