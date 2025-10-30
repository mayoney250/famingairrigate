import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/irrigation_schedule_model.dart';

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
      return null;
    }
  }

  // Start an existing scheduled cycle immediately
  Future<bool> startScheduledNow(String scheduleId) async {
    return await startIrrigation(scheduleId);
  }

  // Start irrigation for a schedule
  Future<bool> startIrrigation(String scheduleId) async {
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
      log('Irrigation started: $scheduleId');
      return true;
    } catch (e) {
      log('Error starting irrigation: $e');
      return false;
    }
  }

  // Get all schedules for a user
  Stream<List<IrrigationScheduleModel>> getUserSchedules(String userId) {
    return _firestore
        .collection('irrigationSchedules')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final schedules = snapshot.docs
          .map((doc) => IrrigationScheduleModel.fromFirestore(doc))
          .toList();
      
      // Sort in memory by startTime
      schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      return schedules;
    });
  }

  // Get only upcoming scheduled and active cycles for a user
  Stream<List<IrrigationScheduleModel>> getUpcomingScheduled(String userId) {
    return _firestore
        .collection('irrigationSchedules')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      DateTime effectiveTime(IrrigationScheduleModel s) => s.nextRun ?? s.startTime;
      final schedules = snapshot.docs
          .map((doc) => IrrigationScheduleModel.fromFirestore(doc))
          .where((s) =>
            s.isActive &&
            (s.status == 'scheduled' || s.status == 'scheduleId') &&
            effectiveTime(s).isAfter(now))
          .toList();

      schedules.sort((a, b) => effectiveTime(a).compareTo(effectiveTime(b)));
      return schedules;
    });
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

      final schedule = IrrigationScheduleModel(
        id: '',
        userId: userId,
        name: 'Manual Irrigation - $fieldName',
        zoneId: fieldId,
        zoneName: fieldName,
        startTime: now,
        durationMinutes: durationMinutes,
        repeatDays: const [],
        isActive: true,
        status: 'running',
        createdAt: now,
      );

      await _firestore
          .collection('irrigationSchedules')
          .add(schedule.toMap());

      log('Irrigation started manually');
      return true;
    } catch (e) {
      log('Error starting irrigation manually: $e');
      return false;
    }
  }

  // Stop irrigation manually
  Future<bool> stopIrrigationManually(String scheduleId) async {
    return await stopIrrigation(scheduleId, stoppedBy: 'manual');
  }

  // Stop irrigation (generic)
  Future<bool> stopIrrigation(String scheduleId, {String stoppedBy = 'automatic'}) async {
    try {
      final now = DateTime.now();
      await _firestore
          .collection('irrigationSchedules')
          .doc(scheduleId)
          .update({
        'status': 'completed',
        'isActive': false,
        'stoppedAt': Timestamp.fromDate(now),
        'stoppedBy': stoppedBy,
        'updatedAt': Timestamp.fromDate(now),
      });
      log('Irrigation stopped ($stoppedBy): $scheduleId');
      return true;
    } catch (e) {
      log('Error stopping irrigation: $e');
      return false;
    }
  }

  // Create new schedule
  Future<bool> createSchedule(IrrigationScheduleModel schedule) async {
    try {
      await _firestore
          .collection('irrigationSchedules')
          .add(schedule.toMap());

      log('Schedule created');
      return true;
    } catch (e) {
      log('Error creating schedule: $e');
      return false;
    }
  }

  // Update schedule status
  Future<bool> updateScheduleStatus(String scheduleId, String status) async {
    try {
      await _firestore
          .collection('irrigationSchedules')
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
          .collection('irrigationSchedules')
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
          .collection('irrigationSchedules')
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

  // Toggle running/stopped for schedule
  Future<bool> toggleSchedule(String scheduleId, bool isRunning) async {
    if (isRunning) {
      return await stopIrrigation(scheduleId, stoppedBy: 'manual');
    } else {
      return await startIrrigation(scheduleId);
    }
  }
}
