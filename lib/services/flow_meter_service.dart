import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flow_meter_model.dart';
import 'cache_repository.dart';

class FlowMeterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheRepository _cache = CacheRepository();
  final String _collection = 'irrigationLogs';

  Future<String> createReading(FlowMeterModel reading, {String? userId}) async {
    try {
      // Save locally first (instant response)
      await _cache.saveFlowMeterDataOffline(reading, userId: userId);
      
      // Try to sync immediately
      final col = _firestore.collection(_collection);
      final payload = {
        ...reading.toMap(),
        'type': 'flow',
      };
      final docRef = await col.add(payload);
      return docRef.id;
    } catch (e) {
      // Already saved to cache/queue
      rethrow;
    }
  }

  Future<FlowMeterModel?> getLatestReading(String fieldId, {String? userId}) async {
    try {
      // Return from cache immediately
      final cached = await _cache.getFlowMeterData(fieldId: fieldId, limit: 1);
      if (cached.isNotEmpty) {
        return cached.first;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Stream<FlowMeterModel?> streamLatestReading(String fieldId, {String? userId}) async* {
    try {
      // Yield cached value immediately
      final cached = await _cache.getFlowMeterData(fieldId: fieldId, limit: 1);
      if (cached.isNotEmpty) {
        yield cached.first;
      }

      // Then stream from Firebase
      yield* _firestore
          .collection(_collection)
          .where('type', isEqualTo: 'flow')
          .where('fieldId', isEqualTo: fieldId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .map((s) {
        if (s.docs.isNotEmpty) {
          final model = FlowMeterModel.fromFirestore(s.docs.first);
          // Update cache
          _cache.saveFlowMeterDataOffline(model, userId: userId);
          return model;
        }
        return null;
      });
    } catch (_) {}
  }

  Future<double> getUsageSince(String fieldId, DateTime start, {String? userId}) async {
    try {
      // Get from cache
      final daysBack = DateTime.now().difference(start).inDays.abs();
      final cached = await _cache.getFlowMeterData(
        fieldId: fieldId,
        daysBack: daysBack > 7 ? 7 : daysBack,
        limit: 50,
      );

      double total = 0;
      for (final reading in cached) {
        if (reading.timestamp.isAfter(start)) {
          total += reading.liters;
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}
