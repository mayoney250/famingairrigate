import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/irrigation_schedule_model.dart';
import 'cache_repository.dart';
import 'offline_sync_service.dart';

class IrrigationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get next scheduled irrigation for a user
  Future<IrrigationScheduleModel?> getNextSchedule(String userId) async {
    try {
      // Get all schedules for user and filter/sort in memory to avoid composite index
      final querySnapshot = await _firestore
          .collection('irrigationSchedules')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      // Filter for active and future schedules in memory
      final now = DateTime.now();
      final schedules = querySnapshot.docs
          .map((doc) => IrrigationScheduleModel.fromFirestore(doc))
          .where((schedule) {
            final next = schedule.nextRun;
            final candidateTime = next ?? schedule.startTime;
            final isUpcoming = candidateTime.isAfter(now);
            return schedule.isActive && schedule.status == 'scheduled' && isUpcoming;
          })
          .toList();

      if (schedules.isEmpty) {
        return null;
      }

      // Sort by candidate next time and return first
      DateTime nextTimeFor(IrrigationScheduleModel s) => s.nextRun ?? s.startTime;
      schedules.sort((a, b) => nextTimeFor(a).compareTo(nextTimeFor(b)));
      
      return schedules.first;
    } catch (e) {
      log('Error getting next schedule: $e');
      // Fallback: try cached schedules
      try {
        final cache = CacheRepository();
        final cached = cache.getCachedList('schedules_user_$userId');
        if (cached.isNotEmpty) {
          final list = cached.map((m) => IrrigationScheduleModel.fromMap(m)).toList();
          list.sort((a, b) => (a.nextRun ?? a.startTime).compareTo(b.nextRun ?? b.startTime));
          return list.first;
        }
      } catch (_) {}
      return null;
    }
  }

  // Start an existing scheduled cycle immediately
  Future<bool> startScheduledNow(String scheduleId) async {
    try {
      final now = DateTime.now();
      await _firestore
          .collection('irrigationSchedules')
          .doc(scheduleId)
          .update({
        'status': 'running',
        'isActive': true,
        'startedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      log('Scheduled irrigation started now: $scheduleId');
      return true;
    } catch (e) {
      log('Error starting scheduled irrigation now: $e');
      return false;
    }
  }

  // Get all schedules for a user (read-through cache: yield cached first, then live updates)
  Stream<List<IrrigationScheduleModel>> getUserSchedules(String userId) async* {
    final cache = CacheRepository();
    final cacheKey = 'schedules_user_$userId';

    // yield cached schedules first, if present
    final cached = cache.getCachedList(cacheKey);
    if (cached.isNotEmpty) {
      try {
        final list = cached.map((m) => IrrigationScheduleModel.fromMap(m)).toList();
        list.sort((a, b) => a.startTime.compareTo(b.startTime));
        yield list;
      } catch (_) {}
    }

    // then yield live updates
    try {
      await for (final snapshot in _firestore
          .collection('irrigationSchedules')
          .where('userId', isEqualTo: userId)
          .snapshots()) {
        final schedules = snapshot.docs
            .map((doc) => IrrigationScheduleModel.fromFirestore(doc))
            .toList();

        schedules.sort((a, b) => a.startTime.compareTo(b.startTime));

        // cache for offline use
        try {
          final toCache = schedules.map((s) => {
            'id': s.id,
            'userId': s.userId,
            'name': s.name,
            'zoneId': s.zoneId,
            'zoneName': s.zoneName,
            'startTime': s.startTime.toIso8601String(),
            'durationMinutes': s.durationMinutes,
            'repeatDays': s.repeatDays,
            'isActive': s.isActive,
            'status': s.status,
            'createdAt': s.createdAt.toIso8601String(),
            'lastRun': s.lastRun?.toIso8601String(),
            'nextRun': s.nextRun?.toIso8601String(),
            'stoppedAt': s.stoppedAt?.toIso8601String(),
            'stoppedBy': s.stoppedBy,
            'isManual': s.isManual,
          }).toList();
          await cache.cacheJsonList(cacheKey, toCache);
        } catch (_) {}

        yield schedules;
      }
    } catch (e) {
      // Offline or Firestore error: yield cached data if available
      log('⚠️ Firestore getUserSchedules error (offline?): $e');
      final cached = cache.getCachedList(cacheKey);
      if (cached.isNotEmpty) {
        try {
          final list = cached.map((m) => IrrigationScheduleModel.fromMap(m)).toList();
          list.sort((a, b) => a.startTime.compareTo(b.startTime));
          yield list;
        } catch (_) {}
      }
    }
  }

  // Get only upcoming scheduled and active cycles for a user (read-through)
  Stream<List<IrrigationScheduleModel>> getUpcomingScheduled(String userId) async* {
    final cache = CacheRepository();
    final cacheKey = 'schedules_user_$userId';

    // yield cached filtered list first
    final cached = cache.getCachedList(cacheKey);
    if (cached.isNotEmpty) {
      try {
        final now = DateTime.now();
        final list = cached.map((m) => IrrigationScheduleModel.fromMap(m)).where((s) {
          final effective = s.nextRun ?? s.startTime;
          return s.isActive && (s.status == 'scheduled' || s.status == 'scheduleId') && effective.isAfter(now);
        }).toList();
        list.sort((a, b) => (a.nextRun ?? a.startTime).compareTo(b.nextRun ?? b.startTime));
        yield list;
      } catch (_) {}
    }

    // then live updates
    try {
      await for (final snapshot in _firestore
          .collection('irrigationSchedules')
          .where('userId', isEqualTo: userId)
          .snapshots()) {
        final now = DateTime.now();
        DateTime effectiveTime(IrrigationScheduleModel s) => s.nextRun ?? s.startTime;
        final schedules = snapshot.docs
            .map((doc) => IrrigationScheduleModel.fromFirestore(doc))
            .where((s) => s.isActive && (s.status == 'scheduled' || s.status == 'scheduleId') && effectiveTime(s).isAfter(now))
            .toList();

        schedules.sort((a, b) => effectiveTime(a).compareTo(effectiveTime(b)));
        yield schedules;
      }
    } catch (e) {
      // Offline or Firestore error: yield cached filtered list if available
      log('⚠️ Firestore getUpcomingScheduled error (offline?): $e');
      final cached = cache.getCachedList(cacheKey);
      if (cached.isNotEmpty) {
        try {
          final now = DateTime.now();
          final list = cached.map((m) => IrrigationScheduleModel.fromMap(m)).where((s) {
            final effective = s.nextRun ?? s.startTime;
            return s.isActive && (s.status == 'scheduled' || s.status == 'scheduleId') && effective.isAfter(now);
          }).toList();
          list.sort((a, b) => (a.nextRun ?? a.startTime).compareTo(b.nextRun ?? b.startTime));
          yield list;
        } catch (_) {}
      }
    }
  }

  // Start irrigation manually
  Future<bool> startIrrigationManually({
    required String userId,
    required String farmId,
    required String fieldId,
    required String fieldName,
    required int durationMinutes,
  }) async {
    try {
      final now = DateTime.now();

      final scheduleData = {
        'userId': userId,
        'name': 'Manual Irrigation - $fieldName',
        'zoneId': fieldId,
        'zoneName': fieldName,
        'startTime': Timestamp.fromDate(now),
        'durationMinutes': durationMinutes,
        'repeatDays': [],
        'isActive': true,
        'status': 'running',
        'createdAt': Timestamp.fromDate(now),
        'isManual': true,
      };

      await _firestore
          .collection('irrigationSchedules')
          .add(scheduleData);

      log('Irrigation started manually');
      return true;
    } catch (e) {
      log('Error starting irrigation manually: $e');
      return false;
    }
  }

  // Stop irrigation manually
  Future<bool> stopIrrigationManually(String scheduleId) async {
    try {
      final now = DateTime.now();
      
      await _firestore
          .collection('irrigationSchedules')
          .doc(scheduleId)
          .update({
        'status': 'stopped',
        'isActive': false,
        'stoppedAt': Timestamp.fromDate(now),
        'stoppedBy': 'manual',
        'updatedAt': Timestamp.fromDate(now),
      });

      log('Irrigation stopped manually: $scheduleId');
      return true;
    } catch (e) {
      log('Error stopping irrigation manually: $e');
      return false;
    }
  }

  // Create new schedule
  Future<bool> createSchedule(IrrigationScheduleModel schedule) async {
    try {
      log('[IrrigationService] Creating schedule: ${schedule.name}');
      
      final scheduleData = schedule.toMap(includeId: false); // Don't include ID for new documents
      log('[IrrigationService] Schedule data: $scheduleData');
      
      final docRef = await _firestore
          .collection('irrigationSchedules')
          .add(scheduleData);

      log('[IrrigationService] Schedule created with ID: ${docRef.id}');

      // Cache schedule for offline use
      try {
        final cache = CacheRepository();
        final cacheKey = 'schedules_user_${schedule.userId}';
        final cached = cache.getCachedList(cacheKey);
        final map = _normalizeScheduleMap(schedule.copyWith(id: docRef.id));
        final updated = [...cached, map];
        await cache.cacheJsonList(cacheKey, updated);
      } catch (_) {}

      return true;
    } catch (e, stackTrace) {
      log('[IrrigationService] Error creating schedule: $e');
      log('[IrrigationService] Stack trace: $stackTrace');
      // Offline path: cache locally and enqueue for sync
      try {
        final cache = CacheRepository();
        final sync = OfflineSyncService();
        final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        final localSchedule = schedule.copyWith(id: localId);
        final map = _normalizeScheduleMap(localSchedule);
        final cacheKey = 'schedules_user_${schedule.userId}';
        final cached = cache.getCachedList(cacheKey);
        final updated = [map, ...cached];
        await cache.cacheJsonList(cacheKey, updated);
        await sync.enqueueOperation(collection: 'irrigationSchedules', operation: 'create', data: map, userId: schedule.userId);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Map<String, dynamic> _normalizeScheduleMap(IrrigationScheduleModel s) {
    return {
      'id': s.id,
      'userId': s.userId,
      'name': s.name,
      'zoneId': s.zoneId,
      'zoneName': s.zoneName,
      'startTime': s.startTime.toIso8601String(),
      'durationMinutes': s.durationMinutes,
      'repeatDays': s.repeatDays,
      'isActive': s.isActive,
      'status': s.status,
      'createdAt': s.createdAt.toIso8601String(),
      'lastRun': s.lastRun?.toIso8601String(),
      'nextRun': s.nextRun?.toIso8601String(),
      'stoppedAt': s.stoppedAt?.toIso8601String(),
      'stoppedBy': s.stoppedBy,
      'isManual': s.isManual,
    };
  }

  // Update schedule status
  Future<bool> updateScheduleStatus(String scheduleId, String status) async {
    try {
      await _firestore
          .collection('irrigation_schedules')
          .doc(scheduleId)
          .update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      log('Schedule status updated: $scheduleId -> $status');
      return true;
    } catch (e) {
      log('Error updating schedule status: $e');
      return false;
    }
  }

  // Complete irrigation and log water usage
  Future<bool> completeIrrigation(
    String scheduleId,
    double waterUsed,
  ) async {
    try {
      await _firestore
          .collection('irrigation_schedules')
          .doc(scheduleId)
          .update({
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
        'waterUsed': waterUsed,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      log('Irrigation completed: $scheduleId, water used: $waterUsed L');
      return true;
    } catch (e) {
      log('Error completing irrigation: $e');
      return false;
    }
  }

  // Get water usage for period
  Future<double> getWaterUsage(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection('irrigation_schedules')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('completedAt', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      double totalWater = 0;
      for (var doc in querySnapshot.docs) {
        final waterUsed = doc.data()['waterUsed'];
        if (waterUsed != null) {
          totalWater += (waterUsed as num).toDouble();
        }
      }

      return totalWater;
    } catch (e) {
      log('Error getting water usage: $e');
      return 0;
    }
  }

  // Calculate cost savings (assuming KSh 2 per liter efficiency gain)
  Future<double> calculateSavings(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final waterUsed = await getWaterUsage(userId, startDate, endDate);
      // Assume 30% water savings with smart irrigation
      final waterSaved = waterUsed * 0.3;
      // KSh 2 per liter saved
      final savings = waterSaved * 2;
      return savings;
    } catch (e) {
      log('Error calculating savings: $e');
      return 0;
    }
  }

  // Delete schedule
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _firestore
          .collection('irrigationSchedules')
          .doc(scheduleId)
          .delete();

      log('Schedule deleted: $scheduleId');
      return true;
    } catch (e) {
      log('Error deleting schedule: $e');
      return false;
    }
  }
}
