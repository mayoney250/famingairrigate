import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_data_model.dart';

class SensorDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'sensorData';

  // Create sensor reading
  Future<String> createReading(SensorDataModel reading) async {
    try {
      final docRef = await _firestore.collection(_collection).add(reading.toMap());
      log('Sensor reading created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      log('Error creating sensor reading: $e');
      rethrow;
    }
  }

  // Get latest reading for a field
  Future<SensorDataModel?> getLatestReading(String userId, String fieldId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('fieldId', isEqualTo: fieldId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SensorDataModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      log('Error fetching latest reading: $e');
      rethrow;
    }
  }

  // Stream latest sensor data
  Stream<SensorDataModel?> streamLatestReading(String userId, String fieldId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('fieldId', isEqualTo: fieldId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return SensorDataModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // Get readings for a time range
  Future<List<SensorDataModel>> getReadingsInRange(
    String userId,
    String fieldId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('fieldId', isEqualTo: fieldId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp')
          .get();

      return snapshot.docs
          .map((doc) => SensorDataModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching readings in range: $e');
      rethrow;
    }
  }

  // Get last 24 hours of readings
  Future<List<SensorDataModel>> getLast24Hours(
    String userId,
    String fieldId,
  ) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    return getReadingsInRange(userId, fieldId, yesterday, now);
  }

  // Get last 7 days of readings
  Future<List<SensorDataModel>> getLast7Days(
    String userId,
    String fieldId,
  ) async {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return getReadingsInRange(userId, fieldId, lastWeek, now);
  }

  // Get readings for chart (hourly averages)
  Future<List<Map<String, dynamic>>> getHourlyAverages(
    String userId,
    String fieldId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final readings = await getReadingsInRange(
        userId,
        fieldId,
        startOfDay,
        endOfDay,
      );

      // Group by hour and calculate averages
      final Map<int, List<SensorDataModel>> hourlyReadings = {};
      for (final reading in readings) {
        final hour = reading.timestamp.hour;
        hourlyReadings.putIfAbsent(hour, () => []);
        hourlyReadings[hour]!.add(reading);
      }

      final List<Map<String, dynamic>> averages = [];
      for (int hour = 0; hour < 24; hour++) {
        if (hourlyReadings.containsKey(hour)) {
          final readings = hourlyReadings[hour]!;
          final avgMoisture = readings
              .map((r) => r.soilMoisture)
              .reduce((a, b) => a + b) /
              readings.length;
          final avgTemp = readings
              .map((r) => r.temperature)
              .reduce((a, b) => a + b) /
              readings.length;
          final avgHumidity = readings
              .map((r) => r.humidity)
              .reduce((a, b) => a + b) /
              readings.length;

          averages.add({
            'hour': hour,
            'moisture': avgMoisture,
            'temperature': avgTemp,
            'humidity': avgHumidity,
          });
        }
      }

      return averages;
    } catch (e) {
      log('Error calculating hourly averages: $e');
      rethrow;
    }
  }

  // Delete old readings (cleanup - keep last 30 days)
  Future<void> deleteOldReadings(String userId, int daysToKeep) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      log('Old sensor readings deleted: ${snapshot.docs.length} records');
    } catch (e) {
      log('Error deleting old readings: $e');
      rethrow;
    }
  }
}

