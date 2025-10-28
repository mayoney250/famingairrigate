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

  // Get all alerts for user
  Future<List<AlertModel>> getUserAlerts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => AlertModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching alerts: $e');
      rethrow;
    }
  }

  // Stream of user alerts
  Stream<List<AlertModel>> streamUserAlerts(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromFirestore(doc))
            .toList());
  }

  // Get unread alerts
  Future<List<AlertModel>> getUnreadAlerts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AlertModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching unread alerts: $e');
      rethrow;
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
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
      await _firestore.collection(_collection).doc(alertId).update({
        'isRead': true,
      });
      log('Alert marked as read: $alertId');
    } catch (e) {
      log('Error marking alert as read: $e');
      rethrow;
    }
  }

  // Mark all alerts as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadAlerts = await getUnreadAlerts(userId);
      final batch = _firestore.batch();

      for (final alert in unreadAlerts) {
        final docRef = _firestore.collection(_collection).doc(alert.id);
        batch.update(docRef, {'isRead': true});
      }

      await batch.commit();
      log('All alerts marked as read for user: $userId');
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

  // Delete all alerts for user
  Future<void> deleteAllAlerts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      log('All alerts deleted for user: $userId');
    } catch (e) {
      log('Error deleting all alerts: $e');
      rethrow;
    }
  }

  // Get alerts by type
  Future<List<AlertModel>> getAlertsByType(
    String userId,
    AlertType type,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AlertModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching alerts by type: $e');
      rethrow;
    }
  }

  // Get alerts by severity
  Future<List<AlertModel>> getAlertsBySeverity(
    String userId,
    AlertSeverity severity,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('severity', isEqualTo: severity.toString().split('.').last)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AlertModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching alerts by severity: $e');
      rethrow;
    }
  }

  // Create specific alert types (helper methods)
  Future<String> createLowMoistureAlert(
    String userId,
    String fieldId,
    String zoneName,
    double moistureLevel,
  ) async {
    final alert = AlertModel(
      id: '',
      userId: userId,
      fieldId: fieldId,
      type: AlertType.lowMoisture,
      severity: AlertSeverity.warning,
      title: 'Low Soil Moisture',
      message: 'Zone $zoneName has moisture level below 30% ($moistureLevel%)',
      timestamp: DateTime.now(),
    );
    return createAlert(alert);
  }

  Future<String> createHighTemperatureAlert(
    String userId,
    String fieldId,
    String zoneName,
    double temperature,
  ) async {
    final alert = AlertModel(
      id: '',
      userId: userId,
      fieldId: fieldId,
      type: AlertType.highTemperature,
      severity: AlertSeverity.warning,
      title: 'High Temperature Alert',
      message: 'Temperature exceeded 35°C in Zone $zoneName (${temperature.toStringAsFixed(1)}°C)',
      timestamp: DateTime.now(),
    );
    return createAlert(alert);
  }

  Future<String> createIrrigationCompletedAlert(
    String userId,
    String zoneId,
    String zoneName,
  ) async {
    final alert = AlertModel(
      id: '',
      userId: userId,
      zoneId: zoneId,
      type: AlertType.irrigationCompleted,
      severity: AlertSeverity.info,
      title: 'Irrigation Completed',
      message: 'Zone $zoneName irrigation completed successfully',
      timestamp: DateTime.now(),
    );
    return createAlert(alert);
  }
}

