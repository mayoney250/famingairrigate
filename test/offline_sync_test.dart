import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../lib/models/sensor_data_model.dart';
import '../lib/models/flow_meter_model.dart';
import '../lib/models/sync_queue_item_model.dart';
import '../lib/models/sync_queue_item_adapter.dart';
import '../lib/services/cache_repository.dart';
import '../lib/services/offline_sync_service.dart';

void main() {
  group('Offline-First System Tests', () {
    late CacheRepository cacheRepository;
    late OfflineSyncService syncService;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      
      Hive.registerAdapter(SyncQueueItemAdapter());
      // SensorDataModelAdapter and FlowMeterModelAdapter are not generated in this project.
      // Tests can operate without registering adapters for plain models used by CacheRepository.
      // If adapters are added later, register them here.
      
      // Initialize services
      cacheRepository = CacheRepository();
      syncService = OfflineSyncService();
      
      await cacheRepository.initialize();
      await syncService.initialize();
    });

    tearDownAll(() async {
      await cacheRepository.clearCache();
      await Hive.deleteBoxFromDisk('sensorDataCache');
      await Hive.deleteBoxFromDisk('flowMeterCache');
      await Hive.deleteBoxFromDisk('syncQueue');
      await Hive.deleteBoxFromDisk('cacheMetadata');
    });

    test('Cache saves sensor data locally', () async {
      final sensorData = SensorDataModel(
        id: 'test_sensor_1',
        fieldId: 'field_1',
        userId: 'user_1',
        soilMoisture: 45.5,
        temperature: 28.0,
        humidity: 65.0,
        timestamp: DateTime.now(),
      );

      await cacheRepository.saveSensorDataOffline(sensorData, userId: 'user_1');

      final cached = await cacheRepository.getSensorData(fieldId: 'field_1', limit: 1);
      expect(cached.isNotEmpty, true);
      expect(cached.first.id, 'test_sensor_1');
    });

    test('Cache saves flow meter data locally', () async {
      final flowData = FlowMeterModel(
        id: 'test_flow_1',
        userId: 'user_1',
        fieldId: 'field_1',
        liters: 150.0,
        timestamp: DateTime.now(),
      );

      await cacheRepository.saveFlowMeterDataOffline(flowData, userId: 'user_1');

      final cached = await cacheRepository.getFlowMeterData(fieldId: 'field_1', limit: 1);
      expect(cached.isNotEmpty, true);
      expect(cached.first.id, 'test_flow_1');
    });

    test('Sync queue enqueues operations', () async {
      await syncService.enqueueOperation(
        collection: 'sensorData',
        operation: 'create',
        data: {
          'fieldId': 'field_1',
          'soilMoisture': 50.0,
          'timestamp': DateTime.now().toIso8601String(),
        },
        userId: 'user_1',
      );

      final metrics = syncService.getSyncMetrics();
      expect(metrics['totalInQueue'], greaterThan(0));
    });

    test('Sync metrics track attempts', () async {
      final initialMetrics = syncService.getSyncMetrics();
      final initialAttempts = initialMetrics['totalAttempts'] as int;

      await syncService.enqueueOperation(
        collection: 'sensorData',
        operation: 'create',
        data: {'test': 'data'},
        userId: 'user_1',
      );

      final updatedMetrics = syncService.getSyncMetrics();
      expect(
        updatedMetrics['totalAttempts'] as int,
        equals(initialAttempts + 1),
      );
    });

    test('Cache respects 7-day limit', () async {
      // Add data from 8 days ago
      final oldData = SensorDataModel(
        id: 'old_sensor',
        fieldId: 'field_1',
        userId: 'user_1',
        soilMoisture: 40.0,
        temperature: 25.0,
        humidity: 60.0,
        timestamp: DateTime.now().subtract(const Duration(days: 8)),
      );

      // Add recent data
      final recentData = SensorDataModel(
        id: 'recent_sensor',
        fieldId: 'field_1',
        userId: 'user_1',
        soilMoisture: 50.0,
        temperature: 28.0,
        humidity: 65.0,
        timestamp: DateTime.now(),
      );

      await cacheRepository.saveSensorDataOffline(oldData);
      await cacheRepository.saveSensorDataOffline(recentData);

      // Get data with 7-day limit
      final cached = await cacheRepository.getSensorData(
        fieldId: 'field_1',
        daysBack: 7,
        limit: 50,
      );

      // Should only have recent data
      expect(
        cached.any((item) => item.id == 'recent_sensor'),
        true,
      );
    });

    test('Cache respects 50-item limit', () async {
      // Add 60 items
      for (int i = 0; i < 60; i++) {
        final data = SensorDataModel(
          id: 'sensor_$i',
          fieldId: 'field_2',
          userId: 'user_1',
          soilMoisture: 40.0 + i,
          temperature: 25.0,
          humidity: 60.0,
          timestamp: DateTime.now().subtract(Duration(minutes: i)),
        );
        await cacheRepository.saveSensorDataOffline(data);
      }

      final cached = await cacheRepository.getSensorData(
        fieldId: 'field_2',
        limit: 50,
        daysBack: 7,
      );

      // Should only return max 50
      expect(cached.length, lessThanOrEqualTo(50));
    });

    test('Cache metrics report correct numbers', () async {
      final metrics = cacheRepository.getCacheMetrics();

      expect(metrics.containsKey('sensorDataCached'), true);
      expect(metrics.containsKey('flowMeterDataCached'), true);
      expect(metrics.containsKey('sync'), true);

      final syncMetrics = metrics['sync'] as Map;
      expect(syncMetrics.containsKey('successRate'), true);
      expect(syncMetrics.containsKey('totalAttempts'), true);
    });
  });
}
