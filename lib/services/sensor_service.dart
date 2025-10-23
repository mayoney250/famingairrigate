import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_reading_model.dart';

class SensorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get latest sensor reading by type
  Future<SensorReading?> getLatestReading(
    String farmId,
    String sensorType,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('sensor_readings')
          .where('farmId', isEqualTo: farmId)
          .where('sensorType', isEqualTo: sensorType)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return SensorReading.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      log('Error getting latest sensor reading: $e');
      return null;
    }
  }

  // Get average soil moisture for farm
  Future<double> getAverageSoilMoisture(String farmId) async {
    try {
      // Get readings from last hour
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      
      final querySnapshot = await _firestore
          .collection('sensor_readings')
          .where('farmId', isEqualTo: farmId)
          .where('sensorType', isEqualTo: 'soil_moisture')
          .where('timestamp', isGreaterThan: oneHourAgo.toIso8601String())
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Return default value if no readings
        return 75.0;
      }

      double totalMoisture = 0;
      for (var doc in querySnapshot.docs) {
        totalMoisture += (doc.data()['value'] as num).toDouble();
      }

      return totalMoisture / querySnapshot.docs.length;
    } catch (e) {
      log('Error getting average soil moisture: $e');
      return 75.0; // Default value
    }
  }

  // Get soil moisture status message
  String getSoilMoistureStatus(double moisture) {
    if (moisture < 30) {
      return 'Soil is too dry. Consider irrigating soon.';
    } else if (moisture < 50) {
      return 'Soil moisture is low. Irrigation recommended.';
    } else if (moisture < 80) {
      return 'Farm moisture is at optimal levels';
    } else {
      return 'Soil is very moist. No irrigation needed.';
    }
  }

  // Stream sensor readings
  Stream<List<SensorReading>> getSensorReadingsStream(
    String farmId,
    String sensorType,
  ) {
    return _firestore
        .collection('sensor_readings')
        .where('farmId', isEqualTo: farmId)
        .where('sensorType', isEqualTo: sensorType)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SensorReading.fromMap(doc.data()))
          .toList();
    });
  }

  // Add sensor reading (for testing)
  Future<bool> addSensorReading(SensorReading reading) async {
    try {
      await _firestore
          .collection('sensor_readings')
          .doc(reading.readingId)
          .set(reading.toMap());

      log('Sensor reading added: ${reading.readingId}');
      return true;
    } catch (e) {
      log('Error adding sensor reading: $e');
      return false;
    }
  }

  // Generate mock sensor reading for testing
  Future<bool> generateMockReading(String farmId, String fieldId) async {
    try {
      final readingId = _firestore.collection('sensor_readings').doc().id;
      
      final reading = SensorReading(
        readingId: readingId,
        sensorId: 'sensor_${DateTime.now().millisecondsSinceEpoch}',
        sensorType: 'soil_moisture',
        farmId: farmId,
        fieldId: fieldId,
        value: 70 + (DateTime.now().millisecondsSinceEpoch % 20).toDouble(),
        unit: '%',
        timestamp: DateTime.now(),
      );

      return await addSensorReading(reading);
    } catch (e) {
      log('Error generating mock reading: $e');
      return false;
    }
  }
}

