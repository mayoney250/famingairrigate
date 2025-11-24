import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/irrigation_schedule_model.dart';

class IrrigationScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'irrigationSchedules';

  // Create a new schedule
  Future<String> createSchedule(IrrigationScheduleModel schedule) async {
    try {
      final docRef = await _firestore.collection(_collection).add(schedule.toMap());
      log('Schedule created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      log('Error creating schedule: $e');
      rethrow;
    }
  }

  // Get all schedules for a user
  Future<List<IrrigationScheduleModel>> getUserSchedules(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => IrrigationScheduleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching schedules: $e');
      rethrow;
    }
  }

  // Stream of user schedules
  Stream<List<IrrigationScheduleModel>> streamUserSchedules(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IrrigationScheduleModel.fromFirestore(doc))
            .toList());
  }

  // Get schedule by ID
  Future<IrrigationScheduleModel?> getScheduleById(String scheduleId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(scheduleId).get();
      if (doc.exists) {
        return IrrigationScheduleModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      log('Error fetching schedule: $e');
      rethrow;
    }
  }

  // Update schedule
  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(scheduleId).update(updates);
      log('Schedule updated: $scheduleId');
    } catch (e) {
      log('Error updating schedule: $e');
      rethrow;
    }
  }

  // Toggle schedule active status
  Future<void> toggleScheduleStatus(String scheduleId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(scheduleId).update({
        'isActive': isActive,
      });
      log('Schedule status toggled: $scheduleId -> $isActive');
    } catch (e) {
      log('Error toggling schedule: $e');
      rethrow;
    }
  }

  // Delete schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection(_collection).doc(scheduleId).delete();
      log('Schedule deleted: $scheduleId');
    } catch (e) {
      log('Error deleting schedule: $e');
      rethrow;
    }
  }

  // Get active schedules
  Future<List<IrrigationScheduleModel>> getActiveSchedules(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => IrrigationScheduleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching active schedules: $e');
      rethrow;
    }
  }

  // Get schedules for a specific zone
  Future<List<IrrigationScheduleModel>> getZoneSchedules(
    String userId,
    String zoneId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('zoneId', isEqualTo: zoneId)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => IrrigationScheduleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching zone schedules: $e');
      rethrow;
    }
  }

  // Update last run time
  Future<void> updateLastRun(String scheduleId, DateTime lastRun) async {
    try {
      await _firestore.collection(_collection).doc(scheduleId).update({
        'lastRun': Timestamp.fromDate(lastRun),
      });
      log('Schedule last run updated: $scheduleId');
    } catch (e) {
      log('Error updating last run: $e');
      rethrow;
    }
  }

  // Calculate and update next run time
  Future<void> calculateNextRun(String scheduleId) async {
    try {
      final schedule = await getScheduleById(scheduleId);
      if (schedule == null) return;

      // Calculate next run based on repeat days
      final now = DateTime.now();
      DateTime? nextRun;

      if (schedule.repeatDays.isEmpty) {
        // One-time schedule
        nextRun = null;
      } else {
        // Find next occurrence
        for (int i = 0; i < 7; i++) {
          final candidateDay = now.add(Duration(days: i));
          if (schedule.repeatDays.contains(candidateDay.weekday)) {
            nextRun = DateTime(
              candidateDay.year,
              candidateDay.month,
              candidateDay.day,
              schedule.startTime.hour,
              schedule.startTime.minute,
            );
            if (nextRun.isAfter(now)) {
              break;
            }
          }
        }
      }

      if (nextRun != null) {
        await _firestore.collection(_collection).doc(scheduleId).update({
          'nextRun': Timestamp.fromDate(nextRun),
        });
      }
    } catch (e) {
      log('Error calculating next run: $e');
      rethrow;
    }
  }
<<<<<<< HEAD
=======

  // Stream of running schedules for a user
  Stream<List<IrrigationScheduleModel>> getRunningSchedulesStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'running') // Assuming 'status' field exists
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => IrrigationScheduleModel.fromFirestore(doc))
        .toList());
  }
>>>>>>> hyacinthe
}

