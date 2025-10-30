import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/irrigation_schedule_model.dart';
import 'irrigation_status_service.dart';

class IrrigationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IrrigationStatusService irrigationStatusService = IrrigationStatusService();

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
