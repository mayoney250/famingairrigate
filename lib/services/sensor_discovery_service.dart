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
      return snapshot.docs.map((doc) {
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
