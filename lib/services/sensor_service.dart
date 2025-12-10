import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_model.dart';
import '../models/sensor_reading_model.dart';

class SensorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createSensor(SensorModel sensor, {String? userId}) async {
    final ref = await _firestore.collection('sensors').add(sensor.toMap());
    
    // Add sensorId to user's sensorIds array
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'sensorIds': FieldValue.arrayUnion([ref.id]),
        });
        log('Added sensorId ${ref.id} to user $userId');
      } catch (e) {
        log('Error updating user sensorIds: $e');
      }
    }
    
    return ref.id;
  }

  Future<List<SensorModel>> getSensorsForFarm(String farmId) async {
    final query = await _firestore.collection('sensors').where('farmId', isEqualTo: farmId).get();
    return query.docs.map((doc) => SensorModel.fromFirestore(doc)).toList();
  }

  Future<void> addSensorReading(SensorReadingModel reading) async {
    await _firestore.collection('sensor_readings').add(reading.toMap());
  }

  Future<List<SensorReadingModel>> getReadingsForSensor(String sensorId, {int limit = 50}) async {
    final query = await _firestore.collection('sensor_readings')
      .where('sensorId', isEqualTo: sensorId)
      .orderBy('ts', descending: true)
      .limit(limit)
      .get();
    return query.docs.map((doc) => SensorReadingModel.fromFirestore(doc)).toList();
  }

  Future<double?> getAverageSoilMoisture(String farmId) async {
    final sensors = await getSensorsForFarm(farmId);
    double sum = 0;
    int count = 0;
    for (final sensor in sensors) {
      final readings = await getReadingsForSensor(sensor.id, limit: 1);
      if (readings.isNotEmpty && readings.first.moisture != null) {
        sum += readings.first.moisture!;
        count++;
      }
    }
    return count > 0 ? sum / count : null;
  }

  // Delete sensor
  Future<bool> deleteSensor(String sensorId, {String? userId}) async {
    try {
      // If userId is not provided, try to infer it from sensor data
      String? sensorUserId = userId;
      if (sensorUserId == null) {
        final sensorDoc = await _firestore.collection('sensors').doc(sensorId).get();
        if (sensorDoc.exists) {
          // Sensors have farmId, not userId directly
          // We'll need to get userId from the field
          final farmId = sensorDoc.data()?['farmId'] as String?;
          if (farmId != null) {
            final fieldDoc = await _firestore.collection('fields').doc(farmId).get();
            if (fieldDoc.exists) {
              sensorUserId = fieldDoc.data()?['userId'] as String?;
            }
          }
        }
      }

      await _firestore.collection('sensors').doc(sensorId).delete();
      log('Sensor deleted: $sensorId');

      // Remove sensorId from user's sensorIds array
      if (sensorUserId != null) {
        try {
          await _firestore.collection('users').doc(sensorUserId).update({
            'sensorIds': FieldValue.arrayRemove([sensorId]),
          });
          log('Removed sensorId $sensorId from user $sensorUserId');
        } catch (e) {
          log('Error updating user sensorIds: $e');
        }
      }

      return true;
    } catch (e) {
      log('Error deleting sensor: $e');
      return false;
    }
  }
}

