import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/irrigation_schedule_model.dart';

class IrrigationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get next scheduled irrigation for a user
  Future<IrrigationSchedule?> getNextSchedule(String userId) async {
    try {
      final now = DateTime.now();
      
      final querySnapshot = await _firestore
          .collection('irrigation_schedules')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'scheduled')
          .where('startTime', isGreaterThan: now.toIso8601String())
          .orderBy('startTime', descending: false)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return IrrigationSchedule.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      log('Error getting next schedule: $e');
      return null;
    }
  }

  // Get all schedules for a user
  Stream<List<IrrigationSchedule>> getUserSchedules(String userId) {
    return _firestore
        .collection('irrigation_schedules')
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IrrigationSchedule.fromMap(doc.data()))
          .toList();
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
      final scheduleId = _firestore.collection('irrigation_schedules').doc().id;
      final now = DateTime.now();

      final schedule = IrrigationSchedule(
        scheduleId: scheduleId,
        userId: userId,
        farmId: farmId,
        fieldId: fieldId,
        fieldName: fieldName,
        startTime: now,
        durationMinutes: durationMinutes,
        isActive: true,
        status: 'running',
        notes: 'Started manually',
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('irrigation_schedules')
          .doc(scheduleId)
          .set(schedule.toMap());

      log('Irrigation started manually: $scheduleId');
      return true;
    } catch (e) {
      log('Error starting irrigation manually: $e');
      return false;
    }
  }

  // Create new schedule
  Future<bool> createSchedule(IrrigationSchedule schedule) async {
    try {
      await _firestore
          .collection('irrigation_schedules')
          .doc(schedule.scheduleId)
          .set(schedule.toMap());

      log('Schedule created: ${schedule.scheduleId}');
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
          .collection('irrigation_schedules')
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
