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

  Future<SensorDataModel?> getLatestReading(String fieldId) async {
    try {
      dev.log('🔍 [getLatestReading] Querying faminga_sensors for fieldId: $fieldId');
      
      final snapshot = await _firestore
          .collection('faminga_sensors')
          .where('fieldId', isEqualTo: fieldId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        dev.log('⚠️ [getLatestReading] No sensor found for field $fieldId');
        return null;
      }

      final doc = snapshot.docs.first;
      dev.log('✅ [getLatestReading] Found sensor ${doc.id} for field $fieldId');
      return _toModel(doc, fieldId);
    } catch (e) {
      dev.log('❌ [getLatestReading] Error: $e');
      return null;
    }
  }

  Stream<SensorDataModel?> streamLatestReading(String fieldId) {
    return _firestore
        .collection('faminga_sensors')
        .where('fieldId', isEqualTo: fieldId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return _toModel(snapshot.docs.first, fieldId);
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

