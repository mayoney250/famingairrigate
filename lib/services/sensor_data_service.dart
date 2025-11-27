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

  Future<String> createReading(SensorDataModel reading) async {
    final latestRef = await _resolveLatestDocForField(reading.fieldId);
    if (latestRef == null) {
      throw StateError('No sensor configured for field ${reading.fieldId}');
    }

    await latestRef.set(_toLatestPayload(reading), SetOptions(merge: true));
    return latestRef.id;
  }

  Future<SensorDataModel?> getLatestReading(String fieldId) async {
    final latestRef = await _resolveLatestDocForField(fieldId);
    if (latestRef == null) return null;

    final snapshot = await latestRef.get();
    return _toModel(snapshot, fieldId);
  }

  Stream<SensorDataModel?> streamLatestReading(String fieldId) async* {
    final latestRef = await _resolveLatestDocForField(fieldId);
    if (latestRef == null) {
      dev.log('⚠️ [SensorDataService] No sensor configured for $fieldId');
      yield null;
      return;
    }

    yield* latestRef.snapshots().map((snap) => _toModel(snap, fieldId));
  }

  Future<List<SensorDataModel>> getReadingsInRange(
    String fieldId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final reading = await getLatestReading(fieldId);
    if (reading == null) return [];
    if (!reading.timestamp.isBefore(startDate) && !reading.timestamp.isAfter(endDate)) {
      return [reading];
    }
    return [];
  }

  Future<List<SensorDataModel>> getLast24Hours(String fieldId) {
    final now = DateTime.now();
    return getReadingsInRange(fieldId, now.subtract(const Duration(days: 1)), now);
  }

  Future<List<SensorDataModel>> getLast7Days(String fieldId) {
    final now = DateTime.now();
    return getReadingsInRange(fieldId, now.subtract(const Duration(days: 7)), now);
  }

  Future<List<Map<String, dynamic>>> getHourlyAverages(
    String fieldId,
    DateTime date,
  ) async {
    final readings = await getReadingsInRange(
      fieldId,
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day).add(const Duration(days: 1)),
    );

    if (readings.isEmpty) return [];

    final reading = readings.first;
    return [
      {
        'hour': reading.timestamp.hour,
        'moisture': reading.soilMoisture,
        'temperature': reading.temperature,
      }
    ];
  }

  Future<void> deleteOldReadings(String userId, int daysToKeep) async {
    dev.log('ℹ️ [SensorDataService] deleteOldReadings skipped (live feed only)');
  }

  Future<DocumentReference<Map<String, dynamic>>?> _resolveLatestDocForField(
    String fieldId,
  ) async {
    if (_latestDocByField.containsKey(fieldId)) {
      return _latestDocByField[fieldId];
    }

    // HARDCODED: Use the single sensor path for all fields
    // Path: /sensors/faminga_2in1_sensor/latest/current
    dev.log('📡 [SensorDataService] Using hardcoded sensor: faminga_2in1_sensor for field $fieldId');
    
    final docRef = _firestore
        .collection('sensors')
        .doc('faminga_2in1_sensor')
        .collection('latest')
        .doc('current');
    
    _latestDocByField[fieldId] = docRef;
    _sensorMetaByField[fieldId] = {
      'id': 'faminga_2in1_sensor',
      'fieldId': fieldId,
    };
    
    return docRef;
  }

  SensorDataModel? _toModel(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String fieldId,
  ) {
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;

    final meta = _sensorMetaByField[fieldId];
    
    // Extract the fieldId from the sensor data
    final dataFieldId = (data['fieldId'] ?? meta?['fieldId'] ?? meta?['farmId']).toString();
    
    // VALIDATION: Only return data if the sensor's fieldId matches the requested fieldId
    if (dataFieldId.isNotEmpty && dataFieldId != fieldId) {
      dev.log('⚠️ [SensorDataService] Field ID mismatch: sensor has "$dataFieldId" but requested "$fieldId" - returning null');
      return null;
    }
    
    // If no fieldId in sensor data, log warning but allow it (for backward compatibility)
    if (dataFieldId.isEmpty) {
      dev.log('⚠️ [SensorDataService] No fieldId found in sensor data for field "$fieldId"');
    }
    
    final resolvedUserId = (data['userId'] ?? meta?['userId'] ?? '').toString();
    final timestamp = _toDate(data['timestamp'] ?? data['ts'] ?? data['time']);

    return SensorDataModel(
      id: snapshot.id == 'current'
          ? '${meta?['id'] ?? dataFieldId}_current'
          : snapshot.id,
      userId: resolvedUserId,
      fieldId: dataFieldId.isNotEmpty ? dataFieldId : fieldId,
      sensorId: meta?['id']?.toString(),
      soilMoisture: _toDouble(
        data['soil_moisture'] ??
            data['soilMoisture'] ??
            data['moisture'] ??
            data['value'] ??
            0,
      ),
      temperature: _toDouble(data['temperature'] ?? data['temp']),
      humidity: _toDouble(data['humidity'] ?? data['hum']),
      battery: _toInt(data['battery'] ?? data['bat']),
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> _toLatestPayload(SensorDataModel reading) {
    return {
      'userId': reading.userId,
      'fieldId': reading.fieldId,
      'sensorId': reading.sensorId,
      'soil_moisture': reading.soilMoisture,
      'temperature': reading.temperature,
      'humidity': reading.humidity,
      'battery': reading.battery,
      'timestamp': Timestamp.fromDate(reading.timestamp),
      'status': 'active',
    };
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
}

