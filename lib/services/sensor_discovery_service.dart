import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SensorDiscoveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream of unassigned sensors (list of hardware IDs)
  Stream<List<UnassignedSensor>> get unassignedSensorsStream {
    return _firestore
        .collection('unassigned_sensors')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final lastSeen = data['lastSeen'] as Timestamp?;
        // If no timestamp, assume valid (or invalid? existing behavior kept all). 
        // Let's keep it if null, to avoid hiding creating-in-progress ones.
        if (lastSeen == null) return true; 
        final diff = now.difference(lastSeen.toDate());
        return diff.inMinutes <= 5; // active in last 5 mins
      }).map((doc) {
        final data = doc.data();
        return UnassignedSensor(
          hardwareId: data['hardwareId'] ?? doc.id,
          status: data['status'] ?? 'unknown',
          lastSeen: data['lastSeen'] as Timestamp?,
        );
      }).toList();
    });
  }

  // Delete from unassigned (cleanup)
  Future<void> removeUnassignedSensor(String hardwareId) async {
    try {
      await _firestore.collection('unassigned_sensors').doc(hardwareId).delete();
    } catch (e) {
      debugPrint("Error removing unassigned sensor: $e");
    }
  }
}

class UnassignedSensor {
  final String hardwareId;
  final String status;
  final Timestamp? lastSeen;

  UnassignedSensor({
    required this.hardwareId,
    required this.status,
    this.lastSeen,
  });
}
