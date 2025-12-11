import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_data_model.dart';

/// Updated sensor data service that reads live data directly from
/// `/sensors/{sensorId}/latest/current` instead of the legacy `sensorData`
/// collection.
class SensorDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, DocumentReference<Map<String, dynamic>>?> _latestDocByField = {};
  final Map<String, Map<String, dynamic>> _sensorMetaByField = {};

  Future<SensorDataModel?> getLatestReading(String fieldId, {String? userId}) async {
    try {
      // dev.log('🔍 [getLatestReading] Querying specific sensor path for fieldId: $fieldId');
      
      final doc = await _firestore.doc('sensors/faminga_2in1_sensor/latest/current').get();

      if (!doc.exists) {
        dev.log('⚠️ [getLatestReading] No sensor data found at specified path');
        return null;
      }
      
      final data = doc.data();
      if (data == null) return null;

      // VALIDATION: Check if data belongs to this user and field
      if (userId != null) {
        final dataUserId = (data['userId'] ?? '').toString();
        if (dataUserId != userId) {
           dev.log('⚠️ [getLatestReading] UserId mismatch: expected $userId, got $dataUserId');
           return null;
        }
      }

      final dataFieldId = (data['fieldId'] ?? '').toString();
      if (dataFieldId != fieldId) {
         dev.log('⚠️ [getLatestReading] FieldId mismatch: expected $fieldId, got $dataFieldId');
         return null; 
      }

      // dev.log('✅ [getLatestReading] Found matching sensor data for field $fieldId');
      return _toModel(doc, fieldId);
    } catch (e) {
      dev.log('❌ [getLatestReading] Error: $e');
      return null;
    }
  }

  Stream<SensorDataModel?> streamLatestReading(String fieldId, {String? userId}) {
    return _firestore
        .doc('sensors/faminga_2in1_sensor/latest/current')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      
      final data = doc.data();
      if (data == null) return null;

      // VALIDATION
      if (userId != null) {
        final dataUserId = (data['userId'] ?? '').toString();
        if (dataUserId != userId) return null;
      }

      final dataFieldId = (data['fieldId'] ?? '').toString();
      if (dataFieldId != fieldId) return null;

      return _toModel(doc, fieldId);
    });
  }

  // --- Helper Methods ---

  SensorDataModel? _toModel(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String fieldId,
  ) {
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;

    // For faminga_sensors, data structure is flatter
    // { userId, fieldId, hardwareId, moisture, temperature, timestamp }

    return SensorDataModel(
      id: snapshot.id, // hardwareId
      userId: (data['userId'] ?? '').toString(),
      fieldId: (data['fieldId'] ?? fieldId).toString(),
      sensorId: snapshot.id,
      soilMoisture: _toDouble(data['moisture'] ?? data['soilMoisture'] ?? data['soil_moisture']),
      temperature: _toDouble(data['temperature'] ?? data['temp']),
      humidity: _toDouble(data['humidity']),
      battery: _toInt(data['battery']),
      timestamp: _toDate(data['timestamp']),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // Legacy/Unused methods stubbed out or simplified
  Future<String> createReading(SensorDataModel reading) async {
    // Write to faminga_sensors/{sensorId}
     await _firestore.collection('faminga_sensors').doc(reading.sensorId ?? 'unknown').set({
       'fieldId': reading.fieldId,
       'userId': reading.userId,
       'moisture': reading.soilMoisture,
       'temperature': reading.temperature,
       'timestamp': FieldValue.serverTimestamp(),
     }, SetOptions(merge: true));
     return reading.sensorId ?? 'unknown';
  }
  
  Future<List<SensorDataModel>> getReadingsInRange(String f, DateTime s, DateTime e) async => [];
  Future<List<SensorDataModel>> getLast24Hours(String f) async => [];
  Future<List<SensorDataModel>> getLast7Days(String f) async => [];
  Future<List<Map<String, dynamic>>> getHourlyAverages(String f, DateTime d) async => [];
  Future<void> deleteOldReadings(String u, int d) async {}
  Future<bool> hasHistoricalData(String f) async => false;
}

