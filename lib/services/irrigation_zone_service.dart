import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/irrigation_zone_model.dart';

class IrrigationZoneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'irrigationZones';

  // Create a new zone
  Future<String> createZone(IrrigationZoneModel zone) async {
    try {
      final docRef = await _firestore.collection(_collection).add(zone.toMap());
      log('Zone created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      log('Error creating zone: $e');
      rethrow;
    }
  }

  // Get all zones for a user
  Future<List<IrrigationZoneModel>> getUserZones(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => IrrigationZoneModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching zones: $e');
      rethrow;
    }
  }

  // Stream of user zones
  Stream<List<IrrigationZoneModel>> streamUserZones(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IrrigationZoneModel.fromFirestore(doc))
            .toList());
  }

  // Get zone by ID
  Future<IrrigationZoneModel?> getZoneById(String zoneId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(zoneId).get();
      if (doc.exists) {
        return IrrigationZoneModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      log('Error fetching zone: $e');
      rethrow;
    }
  }

  // Update zone
  Future<void> updateZone(String zoneId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(zoneId).update(updates);
      log('Zone updated: $zoneId');
    } catch (e) {
      log('Error updating zone: $e');
      rethrow;
    }
  }

  // Toggle zone active status
  Future<void> toggleZoneStatus(String zoneId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(zoneId).update({
        'isActive': isActive,
      });
      log('Zone status toggled: $zoneId -> $isActive');
    } catch (e) {
      log('Error toggling zone: $e');
      rethrow;
    }
  }

  // Delete zone
  Future<void> deleteZone(String zoneId) async {
    try {
      await _firestore.collection(_collection).doc(zoneId).delete();
      log('Zone deleted: $zoneId');
    } catch (e) {
      log('Error deleting zone: $e');
      rethrow;
    }
  }

  // Update water usage
  Future<void> updateWaterUsage(
    String zoneId,
    double additionalUsage,
  ) async {
    try {
      final zone = await getZoneById(zoneId);
      if (zone != null) {
        await _firestore.collection(_collection).doc(zoneId).update({
          'waterUsageToday': zone.waterUsageToday + additionalUsage,
          'waterUsageThisWeek': zone.waterUsageThisWeek + additionalUsage,
        });
        log('Water usage updated for zone: $zoneId');
      }
    } catch (e) {
      log('Error updating water usage: $e');
      rethrow;
    }
  }

  // Reset daily water usage (should be called at midnight)
  Future<void> resetDailyUsage(String userId) async {
    try {
      final zones = await getUserZones(userId);
      final batch = _firestore.batch();

      for (final zone in zones) {
        final docRef = _firestore.collection(_collection).doc(zone.id);
        batch.update(docRef, {'waterUsageToday': 0.0});
      }

      await batch.commit();
      log('Daily water usage reset for user: $userId');
    } catch (e) {
      log('Error resetting daily usage: $e');
      rethrow;
    }
  }

  // Reset weekly water usage (should be called weekly)
  Future<void> resetWeeklyUsage(String userId) async {
    try {
      final zones = await getUserZones(userId);
      final batch = _firestore.batch();

      for (final zone in zones) {
        final docRef = _firestore.collection(_collection).doc(zone.id);
        batch.update(docRef, {'waterUsageThisWeek': 0.0});
      }

      await batch.commit();
      log('Weekly water usage reset for user: $userId');
    } catch (e) {
      log('Error resetting weekly usage: $e');
      rethrow;
    }
  }

  // Update last irrigation time
  Future<void> updateLastIrrigation(String zoneId, DateTime lastIrrigation) async {
    try {
      await _firestore.collection(_collection).doc(zoneId).update({
        'lastIrrigation': Timestamp.fromDate(lastIrrigation),
      });
      log('Last irrigation updated for zone: $zoneId');
    } catch (e) {
      log('Error updating last irrigation: $e');
      rethrow;
    }
  }

  // Get zones by field
  Future<List<IrrigationZoneModel>> getFieldZones(
    String userId,
    String fieldId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('fieldId', isEqualTo: fieldId)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => IrrigationZoneModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching field zones: $e');
      rethrow;
    }
  }
}

