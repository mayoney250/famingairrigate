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
    dev.log('🔍 [getLatestReading] Called for fieldId: $fieldId');
    
    final latestRef = await _resolveLatestDocForField(fieldId);
    if (latestRef == null) {
      dev.log('⚠️ [getLatestReading] No sensor configured for field $fieldId');
      return null;
    }

    dev.log('🔍 [getLatestReading] Fetching from path: ${latestRef.path}');
    final snapshot = await latestRef.get();
    
    if (!snapshot.exists) {
      dev.log('⚠️ [getLatestReading] Snapshot does not exist at ${latestRef.path}');
      return null;
    }
    
    dev.log('🔍 [getLatestReading] Snapshot exists, calling _toModel');
    final model = _toModel(snapshot, fieldId);
    
    if (model == null) {
      dev.log('⚠️ [getLatestReading] _toModel returned null');
    } else {
      dev.log('✅ [getLatestReading] Returning model with moisture: ${model.soilMoisture}%');
    }
    
    return model;
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
    dev.log('📊 [getReadingsInRange] Fetching for field: $fieldId');
    dev.log('📊 [getReadingsInRange] Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    
    final reading = await getLatestReading(fieldId);
    
    if (reading == null) {
      dev.log('⚠️ [getReadingsInRange] No reading returned from getLatestReading');
      return [];
    }
    
    dev.log('📊 [getReadingsInRange] Got reading with timestamp: ${reading.timestamp.toIso8601String()}');
    dev.log('📊 [getReadingsInRange] Moisture: ${reading.soilMoisture}%, Temp: ${reading.temperature}°C');
    
    // Check if reading is within date range
    final isAfterStart = reading.timestamp.isAfter(startDate) || reading.timestamp.isAtSameMomentAs(startDate);
    final isBeforeEnd = reading.timestamp.isBefore(endDate) || reading.timestamp.isAtSameMomentAs(endDate);
    
    dev.log('📊 [getReadingsInRange] isAfterStart: $isAfterStart, isBeforeEnd: $isBeforeEnd');
    
    if (isAfterStart && isBeforeEnd) {
      dev.log('✅ [getReadingsInRange] Reading is within range, returning it');
      return [reading];
    }
    
    dev.log('⚠️ [getReadingsInRange] Reading is outside date range, returning empty list');
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

  /// Check if a field has any historical data in the legacy collection
  Future<bool> hasHistoricalData(String fieldId) async {
    try {
      // Check legacy collection
      final legacyQuery = await _firestore
          .collection('sensorData')
          .where('fieldId', isEqualTo: fieldId)
          .limit(1)
          .get();
      
      if (legacyQuery.docs.isNotEmpty) return true;

      // Also check the new structure if applicable (though currently we only write to 'current')
      // If we start logging history to a subcollection, check that too.
      
      return false;
    } catch (e) {
      dev.log('Error checking historical data for $fieldId: $e');
      return false;
    }
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
    
    // UPDATED VALIDATION: Only validate if sensor data has an explicit fieldId
    // This allows a shared sensor to serve multiple fields
    if (dataFieldId.isNotEmpty && data.containsKey('fieldId')) {
      // If sensor explicitly specifies a fieldId, it must match the requested field
      if (dataFieldId != fieldId) {
        dev.log('⚠️ [SensorDataService] Field ID mismatch: sensor has "$dataFieldId" but requested "$fieldId" - returning null');
        return null;
      }
    } else {
      // If no explicit fieldId in sensor data, this is a shared sensor - use requested fieldId
      dev.log('📡 [SensorDataService] Shared sensor detected - using requested fieldId "$fieldId"');
    }
    
    final resolvedUserId = (data['userId'] ?? meta?['userId'] ?? '').toString();
    final timestamp = _toDate(data['timestamp'] ?? data['ts'] ?? data['time']);

    return SensorDataModel(
      id: snapshot.id == 'current'
          ? '${meta?['id'] ?? dataFieldId}_current'
          : snapshot.id,
      userId: resolvedUserId,
      fieldId: dataFieldId.isNotEmpty ? dataFieldId : fieldId, // Use sensor's fieldId if available, else requested
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

