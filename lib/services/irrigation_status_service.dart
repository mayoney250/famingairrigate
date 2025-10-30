import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/irrigation_schedule_model.dart';

class IrrigationStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Patch: Mark all running, scheduled, or stopped irrigations whose duration is finished as completed
  Future<int> markDueIrrigationsCompleted() async {
    final now = DateTime.now();
    final querySnapshot = await _firestore
        .collection('irrigationSchedules')
        .where('status', whereIn: ['running', 'scheduled', 'stopped'])
        .get();
    int patched = 0;
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final startTime = (data['startTime'] is Timestamp)
        ? (data['startTime'] as Timestamp).toDate()
        : DateTime.tryParse(data['startTime'].toString()) ?? now;
      final duration = data['durationMinutes'] is int ? data['durationMinutes'] : int.tryParse(data['durationMinutes']?.toString() ?? '0') ?? 0;
      final stopTime = startTime.add(Duration(minutes: duration));
      if (now.isAfter(stopTime) && data['status'] != 'completed') {
        await doc.reference.update({
          'status': 'completed',
          'completedAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
        patched++;
      }
    }
    return patched;
  }
}
