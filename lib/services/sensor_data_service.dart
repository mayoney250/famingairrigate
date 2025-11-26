import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_data_model.dart';
import 'cache_repository.dart';

class SensorDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheRepository _cache = CacheRepository();
  final String _collection = 'sensorData';

  // Create sensor reading
  Future<String> createReading(SensorDataModel reading) async {
    try {
      // Save locally first (instant response)
      await _cache.saveSensorDataOffline(reading);
      
      // Try to sync immediately
      final docRef = await _firestore.collection(_collection).add(reading.toMap());
      log('Sensor reading created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      // Already saved to cache/queue in saveSensorDataOffline
      log('Error creating sensor reading (queued locally): $e');
      rethrow;
    }
  }

  // Get latest reading for a field (with cache)
  Future<SensorDataModel?> getLatestReading(String fieldId) async {
    try {
      // Return from cache immediately
      final cached = await _cache.getSensorData(fieldId: fieldId, limit: 1);
      if (cached.isNotEmpty) {
        return cached.first;
      }
      return null;
    } catch (e) {
      log('Error fetching latest reading: $e');
      rethrow;
    }
  }

  // Stream latest sensor data (with cache)
  Stream<SensorDataModel?> streamLatestReading(String fieldId) async* {
    try {
      log('🔴 [STREAM] Starting stream for fieldId: $fieldId');
      
      // Yield cached value immediately
      final cached = await _cache.getSensorData(fieldId: fieldId, limit: 1);
      if (cached.isNotEmpty) {
        log('🔴 [STREAM] Yielding cached data: moisture=${cached.first.soilMoisture}');
        yield cached.first;
      } else {
        log('🔴 [STREAM] No cached data to yield');
      }

      // Then stream from Firebase
      log('🔴 [STREAM] Setting up Firestore listener for $fieldId');
      yield* _firestore
          .collection(_collection)
          .where('fieldId', isEqualTo: fieldId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
        log('🔴 [STREAM] Firestore snapshot received: ${snapshot.docs.length} docs');
        if (snapshot.docs.isNotEmpty) {
          final model = SensorDataModel.fromFirestore(snapshot.docs.first);
          log('🔴 [STREAM] Yielding fresh data: moisture=${model.soilMoisture}, temp=${model.temperature}');
          // Update cache with latest from Firebase
          _cache.saveSensorDataOffline(model);
          return model;
        }
        log('🔴 [STREAM] No documents in snapshot');
        return null;
      });
    } catch (e) {
      log('❌ [STREAM] Error in streamLatestReading: $e');
    }
  }

  // Get readings for a time range (with cache + Firebase limit)
  Future<List<SensorDataModel>> getReadingsInRange(
    String fieldId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Calculate days back for caching
      final daysBack = DateTime.now().difference(startDate).inDays.abs();
      
      // Return from cache immediately (limits to 50 items, 7 days back)
      final cached = await _cache.getSensorData(
        fieldId: fieldId,
        daysBack: daysBack > 7 ? 7 : daysBack,
        limit: 50,
      );
      
      if (cached.isNotEmpty) {
        return cached.where((r) {
          return r.timestamp.isAfter(startDate) && r.timestamp.isBefore(endDate);
        }).toList();
      }
      
      return [];
    } catch (e) {
      log('Error fetching readings in range: $e');
      rethrow;
    }
  }

  // Get last 24 hours of readings
  Future<List<SensorDataModel>> getLast24Hours(
    String fieldId,
  ) async {
    try {
      return await _cache.getSensorData(fieldId: fieldId, limit: 50, daysBack: 1);
    } catch (e) {
      log('Error fetching last 24 hours: $e');
      return [];
    }
  }

  // Get last 7 days of readings
  Future<List<SensorDataModel>> getLast7Days(
    String fieldId,
  ) async {
    try {
      return await _cache.getSensorData(fieldId: fieldId, limit: 50, daysBack: 7);
    } catch (e) {
      log('Error fetching last 7 days: $e');
      return [];
    }
  }

  // Get readings for chart (hourly averages)
  Future<List<Map<String, dynamic>>> getHourlyAverages(
    String fieldId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final readings = await getReadingsInRange(
        fieldId,
        startOfDay,
        endOfDay,
      );

      // Group by hour and calculate averages
      final Map<int, List<SensorDataModel>> byHour = {};
      for (final r in readings) {
        final hour = r.timestamp.hour;
        byHour.putIfAbsent(hour, () => []).add(r);
      }

      final results = <Map<String, dynamic>>[];
      for (final entry in byHour.entries) {
        final list = entry.value;
        final avgMoisture = list.map((e) => e.soilMoisture).reduce((a, b) => a + b) / list.length;
        final avgTemp = list.map((e) => e.temperature).reduce((a, b) => a + b) / list.length;
        results.add({'hour': entry.key, 'moisture': avgMoisture, 'temperature': avgTemp});
      }
      results.sort((a, b) => (a['hour'] as int).compareTo(b['hour'] as int));
      return results;
    } catch (e) {
      log('Error computing hourly averages: $e');
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

