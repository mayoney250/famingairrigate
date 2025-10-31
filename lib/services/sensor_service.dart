import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_model.dart';
import '../models/sensor_reading_model.dart';

class SensorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createSensor(SensorModel sensor) async {
    final ref = await _firestore.collection('sensors').add(sensor.toMap());
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
}

