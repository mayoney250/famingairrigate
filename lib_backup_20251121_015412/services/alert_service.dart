import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'alerts';

  // Create alert
  Future<String> createAlert(AlertModel alert) async {
    try {
      final docRef = await _firestore.collection(_collection).add(alert.toMap());
      log('Alert created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      log('Error creating alert: $e');
      rethrow;
    }
  }

  // Get all alerts for a farm
  Future<List<AlertModel>> getFarmAlerts(String farmId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('farmId', isEqualTo: farmId)
          .orderBy('ts', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList();
    } catch (e) {
      log('Error fetching alerts: $e');
      rethrow;
    }
  }

  // Stream of farm alerts
  Stream<List<AlertModel>> streamFarmAlerts(String farmId) {
    return _firestore
        .collection(_collection)
        .where('farmId', isEqualTo: farmId)
        .orderBy('ts', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList());
  }

  // Get unread alerts
  Future<List<AlertModel>> getUnreadAlerts(String farmId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('farmId', isEqualTo: farmId)
          .where('read', isEqualTo: false)
          .orderBy('ts', descending: true)
          .get();

      return snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList();
    } catch (e) {
      log('Error fetching unread alerts: $e');
      rethrow;
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String farmId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('farmId', isEqualTo: farmId)
          .where('read', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      log('Error fetching unread count: $e');
      return 0;
    }
  }

  // Mark alert as read
  Future<void> markAsRead(String alertId) async {
    try {
      await _firestore.collection(_collection).doc(alertId).update({'read': true});
      log('Alert marked as read: $alertId');
    } catch (e) {
      log('Error marking alert as read: $e');
      rethrow;
    }
  }

  // Mark all alerts as read
  Future<void> markAllAsRead(String farmId) async {
    try {
      final unreadAlerts = await getUnreadAlerts(farmId);
      final batch = _firestore.batch();
      for (final alert in unreadAlerts) {
        final docRef = _firestore.collection(_collection).doc(alert.id);
        batch.update(docRef, {'read': true});
      }
      await batch.commit();
      log('All alerts marked as read for farm: $farmId');
    } catch (e) {
      log('Error marking all alerts as read: $e');
      rethrow;
    }
  }

  // Delete alert
  Future<void> deleteAlert(String alertId) async {
    try {
      await _firestore.collection(_collection).doc(alertId).delete();
      log('Alert deleted: $alertId');
    } catch (e) {
      log('Error deleting alert: $e');
      rethrow;
    }
  }

  // Delete all alerts for farm
  Future<void> deleteAllAlerts(String farmId) async {
    try {
      final snapshot = await _firestore.collection(_collection).where('farmId', isEqualTo: farmId).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      log('All alerts deleted for farm: $farmId');
    } catch (e) {
      log('Error deleting all alerts: $e');
      rethrow;
    }
  }

  // Get alerts by type
  Future<List<AlertModel>> getAlertsByType(String farmId, String type) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('farmId', isEqualTo: farmId)
          .where('type', isEqualTo: type)
          .orderBy('ts', descending: true)
          .get();
      return snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList();
    } catch (e) {
      log('Error fetching alerts by type: $e');
      rethrow;
    }
  }

  // Get alerts by severity
  Future<List<AlertModel>> getAlertsBySeverity(String farmId, String severity) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('farmId', isEqualTo: farmId)
          .where('severity', isEqualTo: severity)
          .orderBy('ts', descending: true)
          .get();
      return snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList();
    } catch (e) {
      log('Error fetching alerts by severity: $e');
      rethrow;
    }
  }

  // Helper creators
  Future<String> createLowMoistureAlert({
    required String farmId,
    String? sensorId,
    required String zoneName,
    required double moistureLevel,
  }) async {
    final alert = AlertModel(
      id: '',
      farmId: farmId,
      sensorId: sensorId,
      type: 'THRESHOLD',
      severity: 'warning',
      message: 'Zone $zoneName has moisture below threshold (${moistureLevel.toStringAsFixed(1)}%).',
      ts: DateTime.now(),
      read: false,
    );
    return createAlert(alert);
  }

  Future<String> createHighTemperatureAlert({
    required String farmId,
    String? sensorId,
    required String zoneName,
    required double temperature,
  }) async {
    final alert = AlertModel(
      id: '',
      farmId: farmId,
      sensorId: sensorId,
      type: 'THRESHOLD',
      severity: 'warning',
      message: 'High temperature in $zoneName (${temperature.toStringAsFixed(1)}°C).',
      ts: DateTime.now(),
      read: false,
    );
    return createAlert(alert);
  }

  Future<String> createIrrigationCompletedAlert({
    required String farmId,
    String? sensorId,
    required String zoneName,
  }) async {
    final alert = AlertModel(
      id: '',
      farmId: farmId,
      sensorId: sensorId,
      type: 'VALVE',
      severity: 'info',
      message: 'Irrigation completed for $zoneName.',
      ts: DateTime.now(),
      read: false,
    );
    return createAlert(alert);
  }
}

