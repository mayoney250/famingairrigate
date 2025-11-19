import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/irrigation_zone_model.dart';

class IrrigationZoneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'irrigation_zones';

  Future<String?> createZone(IrrigationZone zone) async {
    try {
      final zoneData = zone.toMap();
      final docRef = await _firestore.collection(_collection).add(zoneData);
      dev.log('Irrigation zone created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      dev.log('Error creating irrigation zone: $e');
      return null;
    }
  }

  Stream<List<IrrigationZone>> getFieldZones(String fieldId) {
    return _firestore
        .collection(_collection)
        .where('fieldId', isEqualTo: fieldId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final zones = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return IrrigationZone.fromMap(data);
      }).toList();

      zones.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return zones;
    });
  }

  Stream<List<IrrigationZone>> getUserZones(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final zones = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return IrrigationZone.fromMap(data);
      }).toList();

      zones.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return zones;
    });
  }

  Future<IrrigationZone?> getZone(String zoneId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(zoneId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return IrrigationZone.fromMap(data);
      }
      return null;
    } catch (e) {
      dev.log('Error getting irrigation zone: $e');
      return null;
    }
  }

  Future<bool> updateZone(String zoneId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection(_collection).doc(zoneId).update(data);
      dev.log('Irrigation zone updated: $zoneId');
      return true;
    } catch (e) {
      dev.log('Error updating irrigation zone: $e');
      return false;
    }
  }

  Future<bool> deleteZone(String zoneId) async {
    try {
      await _firestore.collection(_collection).doc(zoneId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      dev.log('Irrigation zone deleted: $zoneId');
      return true;
    } catch (e) {
      dev.log('Error deleting irrigation zone: $e');
      return false;
    }
  }

  Future<bool> toggleZoneStatus(String zoneId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(zoneId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      dev.log('Irrigation zone status updated: $zoneId -> $isActive');
      return true;
    } catch (e) {
      dev.log('Error toggling irrigation zone status: $e');
      return false;
    }
  }
}
