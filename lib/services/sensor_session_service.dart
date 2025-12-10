import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

/// Service for managing sensor sessions (claiming/releasing sensors)
class SensorSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const int sessionTimeoutMinutes = 10;

  /// Claim a sensor for the current user and field
  /// Returns true if successful, false if sensor is already claimed
  Future<bool> claimSensor({
    required String hardwareId,
    required String fieldId,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        dev.log('Cannot claim sensor: user not logged in');
        return false;
      }

      final sessionRef = _firestore.collection('sensor_sessions').doc(hardwareId);
      
      // Check if sensor is already claimed
      final existingSession = await sessionRef.get();
      
      if (existingSession.exists) {
        final data = existingSession.data()!;
        final isActive = data['active'] as bool? ?? false;
        final lastHeartbeat = (data['lastHeartbeat'] as Timestamp?)?.toDate();
        
        if (isActive && lastHeartbeat != null) {
          final age = DateTime.now().difference(lastHeartbeat);
          
          // If heartbeat is recent (< 10 minutes), sensor is in use
          if (age.inMinutes < sessionTimeoutMinutes) {
            final currentOwner = data['userId'] as String?;
            
            // Allow re-claiming if it's the same user
            if (currentOwner == userId) {
              dev.log('User $userId re-claiming their own sensor $hardwareId');
            } else {
              dev.log('Sensor $hardwareId is in use by $currentOwner (heartbeat ${age.inMinutes}m ago)');
              return false;
            }
          } else {
            dev.log('Sensor $hardwareId session expired (${age.inMinutes}m old), allowing new claim');
          }
        }
      }

      // Create or overwrite session
      await sessionRef.set({
        'userId': userId,
        'fieldId': fieldId,
        'active': true,
        'claimedAt': FieldValue.serverTimestamp(),
        'lastHeartbeat': FieldValue.serverTimestamp(),
      });

      dev.log('✅ Sensor $hardwareId claimed by $userId for field $fieldId');
      return true;
    } catch (e) {
      dev.log('Error claiming sensor: $e');
      return false;
    }
  }

  /// Release a sensor (delete the session)
  Future<bool> releaseSensor(String hardwareId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      final sessionRef = _firestore.collection('sensor_sessions').doc(hardwareId);
      final session = await sessionRef.get();

      // Only allow releasing if it's the current user's session
      if (session.exists) {
        final data = session.data()!;
        final sessionUserId = data['userId'] as String?;
        
        if (sessionUserId != userId) {
          dev.log('Cannot release sensor $hardwareId: owned by different user');
          return false;
        }
      }

      await sessionRef.delete();
      dev.log('✅ Sensor $hardwareId released by $userId');
      return true;
    } catch (e) {
      dev.log('Error releasing sensor: $e');
      return false;
    }
  }

  /// Get the active session for a sensor
  Future<Map<String, dynamic>?> getActiveSession(String hardwareId) async {
    try {
      final sessionRef = _firestore.collection('sensor_sessions').doc(hardwareId);
      final snapshot = await sessionRef.get();

      if (!snapshot.exists) return null;

      final data = snapshot.data()!;
      final isActive = data['active'] as bool? ?? false;
      final lastHeartbeat = (data['lastHeartbeat'] as Timestamp?)?.toDate();

      if (!isActive) return null;

      // Check if session is expired
      if (lastHeartbeat != null) {
        final age = DateTime.now().difference(lastHeartbeat);
        if (age.inMinutes >= sessionTimeoutMinutes) {
          dev.log('Session for $hardwareId is expired (${age.inMinutes}m old)');
          return null;
        }
      }

      return data;
    } catch (e) {
      dev.log('Error getting active session: $e');
      return null;
    }
  }

  /// Check if a session is active and owned by the current user
  Future<bool> isSessionOwnedByCurrentUser(String hardwareId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final session = await getActiveSession(hardwareId);
    if (session == null) return false;

    return session['userId'] == userId;
  }

  /// Stream session changes for a sensor
  Stream<Map<String, dynamic>?> streamSession(String hardwareId) {
    return _firestore
        .collection('sensor_sessions')
        .doc(hardwareId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      final data = snapshot.data()!;
      final isActive = data['active'] as bool? ?? false;
      final lastHeartbeat = (data['lastHeartbeat'] as Timestamp?)?.toDate();

      if (!isActive) return null;

      // Check if expired
      if (lastHeartbeat != null) {
        final age = DateTime.now().difference(lastHeartbeat);
        if (age.inMinutes >= sessionTimeoutMinutes) {
          return null;
        }
      }

      return data;
    });
  }

  /// Get session status for display
  Future<SessionStatus> getSessionStatus(String hardwareId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final session = await getActiveSession(hardwareId);

    if (session == null) {
      return SessionStatus.available;
    }

    if (session['userId'] == userId) {
      return SessionStatus.ownedByCurrentUser;
    }

    return SessionStatus.ownedByOtherUser;
  }

  /// Release all sensors for a specific user (used on logout)
  Future<void> releaseAllSessionsForUser(String userId) async {
    try {
      final query = await _firestore
          .collection('sensor_sessions')
          .where('userId', isEqualTo: userId)
          .get();

      if (query.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      dev.log('✅ Released ${query.docs.length} sensor sessions for user $userId');
    } catch (e) {
      dev.log('Error releasing all sessions for user: $e');
    }
  }
}

enum SessionStatus {
  available,
  ownedByCurrentUser,
  ownedByOtherUser,
}
