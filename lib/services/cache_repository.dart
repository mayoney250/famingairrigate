import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/sensor_data_model.dart';
import '../models/flow_meter_model.dart';
import 'offline_sync_service.dart';

/// Offline-first repository providing read-through caching for all data
class CacheRepository {
  static final CacheRepository _instance = CacheRepository._internal();

  factory CacheRepository() {
    return _instance;
  }

  CacheRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineSyncService _syncService = OfflineSyncService();

  Box<SensorDataModel>? _sensorDataCacheBox;
  Box<FlowMeterModel>? _flowMeterCacheBox;
  Box? _metadataBox;
  Box? _genericCacheBox; // for other collections (fields, schedules, weather, profiles, etc.)

  /// Initialize cache boxes
  Future<void> initialize() async {
    try {
      _sensorDataCacheBox = await Hive.openBox<SensorDataModel>('sensorDataCache');
      _flowMeterCacheBox = await Hive.openBox<FlowMeterModel>('flowMeterCache');
      _metadataBox = await Hive.openBox('cacheMetadata');
      _genericCacheBox = await Hive.openBox('genericCache');
      
      await _syncService.initialize();
      
      dev.log('✅ CacheRepository initialized');
    } catch (e) {
      dev.log('❌ Error initializing CacheRepository: $e');
    }
  }

  /// Generic: cache a JSON-like map under a key (e.g. 'fields_user_{userId}')
  Future<void> cacheJson(String key, Map<String, dynamic> data) async {
    try {
      await _genericCacheBox?.put(key, data);
    } catch (e) {
      dev.log('⚠️ Failed to cache json for $key: $e');
    }
  }

  /// Generic: cache a list of JSON-like maps under a key
  Future<void> cacheJsonList(String key, List<Map<String, dynamic>> list) async {
    try {
      await _genericCacheBox?.put(key, list);
    } catch (e) {
      dev.log('⚠️ Failed to cache json list for $key: $e');
    }
  }

  /// Generic: retrieve cached map
  Map<String, dynamic>? getCachedJson(String key) {
    try {
      final val = _genericCacheBox?.get(key);
      if (val == null) return null;
      return Map<String, dynamic>.from(val as Map);
    } catch (e) {
      dev.log('⚠️ Failed to read cached json for $key: $e');
      return null;
    }
  }

  /// Generic: retrieve cached list of maps
  List<Map<String, dynamic>> getCachedList(String key) {
    try {
      final val = _genericCacheBox?.get(key);
      if (val == null) return [];
      final list = List.from(val as List);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      dev.log('⚠️ Failed to read cached list for $key: $e');
      return [];
    }
  }

  /// Get sensor data with read-through cache
  /// Returns cached data immediately, then fetches fresh from Firebase if online
  Future<List<SensorDataModel>> getSensorData({
    required String fieldId,
    int limit = 50,
    int daysBack = 7,
  }) async {
    try {
      // Return cached data immediately
      final cached = _getCachedSensorData(fieldId, daysBack, limit);
      if (cached.isNotEmpty) {
        dev.log('📦 Returning ${cached.length} cached sensor readings for $fieldId');
      }

      // Fetch fresh data in background
      _fetchAndCacheSensorData(fieldId, limit, daysBack);

      return cached;
    } catch (e) {
      dev.log('❌ Error in getSensorData: $e');
      return [];
    }
  }

  /// Get flow meter data with read-through cache
  Future<List<FlowMeterModel>> getFlowMeterData({
    required String fieldId,
    int limit = 50,
    int daysBack = 7,
  }) async {
    try {
      // Return cached data immediately
      final cached = _getCachedFlowMeterData(fieldId, daysBack, limit);
      if (cached.isNotEmpty) {
        dev.log('📦 Returning ${cached.length} cached flow meter readings for $fieldId');
      }

      // Fetch fresh data in background
      _fetchAndCacheFlowMeterData(fieldId, limit, daysBack);

      return cached;
    } catch (e) {
      dev.log('❌ Error in getFlowMeterData: $e');
      return [];
    }
  }

  /// Get cached sensor data (immediate, no network)
  List<SensorDataModel> _getCachedSensorData(
    String fieldId,
    int daysBack,
    int limit,
  ) {
    if (_sensorDataCacheBox == null) return [];

    final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

    final data = _sensorDataCacheBox!.values
        .where((reading) =>
            reading.fieldId == fieldId && reading.timestamp.isAfter(cutoffDate))
        .toList();

    data.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return data.take(limit).toList();
  }

  /// Get cached flow meter data (immediate, no network)
  List<FlowMeterModel> _getCachedFlowMeterData(
    String fieldId,
    int daysBack,
    int limit,
  ) {
    if (_flowMeterCacheBox == null) return [];

    final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

    final data = _flowMeterCacheBox!.values
        .where((reading) =>
            reading.fieldId == fieldId && reading.timestamp.isAfter(cutoffDate))
        .toList();

    data.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return data.take(limit).toList();
  }

  /// Fetch sensor data from Firebase and cache it (background)
  void _fetchAndCacheSensorData(String fieldId, int limit, int daysBack) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

      final snapshot = await _firestore
          .collection('sensorData')
          .where('fieldId', isEqualTo: fieldId)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        dev.log('ℹ️ No fresh sensor data from Firebase for $fieldId');
        return;
      }

      // Update cache
      for (final doc in snapshot.docs) {
        final model = SensorDataModel.fromFirestore(doc);
        await _sensorDataCacheBox?.put(model.id, model);
      }

      // Update cache timestamp
      await _metadataBox?.put('sensor_$fieldId', DateTime.now().toIso8601String());

      dev.log('🔄 Cached ${snapshot.docs.length} fresh sensor readings for $fieldId');
    } catch (e) {
      dev.log('⚠️ Failed to fetch sensor data from Firebase: $e (using cache)');
    }
  }

  /// Fetch flow meter data from Firebase and cache it (background)
  void _fetchAndCacheFlowMeterData(String fieldId, int limit, int daysBack) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

      final snapshot = await _firestore
          .collection('irrigationLogs')
          .where('type', isEqualTo: 'flow')
          .where('fieldId', isEqualTo: fieldId)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        dev.log('ℹ️ No fresh flow meter data from Firebase for $fieldId');
        return;
      }

      // Update cache
      for (final doc in snapshot.docs) {
        final model = FlowMeterModel.fromFirestore(doc);
        await _flowMeterCacheBox?.put(model.id, model);
      }

      // Update cache timestamp
      await _metadataBox?.put('flow_$fieldId', DateTime.now().toIso8601String());

      dev.log('🔄 Cached ${snapshot.docs.length} fresh flow meter readings for $fieldId');
    } catch (e) {
      dev.log('⚠️ Failed to fetch flow meter data from Firebase: $e (using cache)');
    }
  }

  /// Save sensor data locally and enqueue for sync
  Future<void> saveSensorDataOffline(
    SensorDataModel data, {
    String? userId,
  }) async {
    try {
      // Save to cache immediately
      await _sensorDataCacheBox?.put(data.id, data);
      dev.log('💾 Saved sensor data to cache: ${data.id}');

      // Enqueue for Firebase sync
      await _syncService.enqueueOperation(
        collection: 'sensorData',
        operation: 'create',
        data: data.toMap(),
        userId: userId,
      );
    } catch (e) {
      dev.log('❌ Error saving sensor data offline: $e');
    }
  }

  /// Save flow meter data locally and enqueue for sync
  Future<void> saveFlowMeterDataOffline(
    FlowMeterModel data, {
    String? userId,
  }) async {
    try {
      // Save to cache immediately
      await _flowMeterCacheBox?.put(data.id, data);
      dev.log('💾 Saved flow meter data to cache: ${data.id}');

      // Enqueue for Firebase sync with 'flow' type marker
      final payload = {
        ...data.toMap(),
        'type': 'flow',
      };

      await _syncService.enqueueOperation(
        collection: 'irrigationLogs',
        operation: 'create',
        data: payload,
        userId: userId,
      );
    } catch (e) {
      dev.log('❌ Error saving flow meter data offline: $e');
    }
  }

  /// Get sync metrics
  Map<String, dynamic> getCacheMetrics() {
    return {
      'sensorDataCached': _sensorDataCacheBox?.length ?? 0,
      'flowMeterDataCached': _flowMeterCacheBox?.length ?? 0,
      'sync': _syncService.getSyncMetrics(),
    };
  }

  /// Clear cache (for testing)
  Future<void> clearCache() async {
    await _sensorDataCacheBox?.clear();
    await _flowMeterCacheBox?.clear();
    await _metadataBox?.clear();
    dev.log('🗑️ Cleared all caches');
  }

  /// Cleanup
  void dispose() {
    _syncService.dispose();
  }
}
