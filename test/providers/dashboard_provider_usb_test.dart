import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faminga_irrigation/providers/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// Since we are likely running in environment where cloud_firestore plugin isn't registered,
// we might have issues with Timestamp unless we mock it or use fake_cloud_firestore.
// However, Timestamp is a class in cloud_firestore_platform_interface.
// Let's try to use it directly. If it fails, we will have to use a wrapper or mock.
// Re-implementing Timestamp behavior for test if needed, but 'cloud_firestore' package exports it.

void main() {
  group('DashboardProvider Static Logic', () {
    
    test('processSensorData normalizes soilMoisture key', () {
      final raw = {
        'soilMoisture': 45.5,
        'temp': 23.0,
        'timestamp': Timestamp.now(), // This might need setup
      };
      
      final result = DashboardProvider.processSensorData(raw, 'test_id');
      
      expect(result['moisture'], 45.5);
      expect(result['temperature'], 23.0);
    });

    test('processSensorData detects offline status (> 60s)', () {
      final now = DateTime(2023, 1, 1, 12, 0, 0);
      final oldTime = now.subtract(const Duration(seconds: 61));
      
      final raw = {
        'moisture': 50.0,
        'timestamp': Timestamp.fromDate(oldTime),
      };
      
      final result = DashboardProvider.processSensorData(
        raw, 
        'test_id', 
        testNow: now
      );
      
      expect(result['isOffline'], true);
    });

    test('processSensorData detects online status (< 60s)', () {
      final now = DateTime(2023, 1, 1, 12, 0, 0);
      final recentTime = now.subtract(const Duration(seconds: 30));
      
      final raw = {
        'moisture': 50.0,
        'timestamp': Timestamp.fromDate(recentTime),
      };
      
      final result = DashboardProvider.processSensorData(
        raw, 
        'test_id', 
        testNow: now
      );
      
      expect(result['isOffline'], false);
    });
  });
}
