import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/irrigation_schedule_model.dart';
import '../services/alert_service.dart';
import '../services/alert_local_service.dart';
import '../models/alert_model.dart';

class IrrigationStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AlertService _alertService = AlertService();

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

  // Mark all running irrigations whose duration is finished as completed
  // Only marks scheduled (non-manual) irrigations; manual cycles remain 'stopped'
  Future<int> markDueIrrigationsCompleted() async {
    final now = DateTime.now();
    final querySnapshot = await _firestore
        .collection('irrigationSchedules')
        .where('status', whereIn: ['running', 'scheduled', 'stopped'])
        .get();
    int patched = 0;
    for (final doc in querySnapshot.docs) {
      final data = doc.data();

      // Only consider items that are currently running
      final status = (data['status'] ?? '').toString();
      if (status != 'running') {
        continue;
      }

      // Skip manual irrigations - they should not be auto-completed
      final isManual = data['isManual'] == true;
      if (isManual) {
        continue;
      }

      // Determine actual start: prefer startedAt if present, else startTime
      DateTime parseDate(dynamic v) {
        if (v == null) return now;
        if (v is Timestamp) return v.toDate();
        if (v is DateTime) return v;
        return DateTime.tryParse(v.toString()) ?? now;
      }

      final startedAt = parseDate(data['startedAt'] ?? data['startTime']);
      final duration = data['durationMinutes'] is int
          ? data['durationMinutes'] as int
          : int.tryParse(data['durationMinutes']?.toString() ?? '0') ?? 0;
      final dueAt = startedAt.add(Duration(minutes: duration));

      // Only complete when the run actually passed its due time
      if (now.isBefore(dueAt)) {
        continue;
      }

      await doc.reference.update({
        'status': 'completed',
        'completedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      // Create completion alert (remote + local)
      final farmId = (data['zoneId'] ?? '').toString();
      final zoneName = (data['zoneName'] ?? 'Field').toString();
      try {
        final alertId = await _alertService.createIrrigationCompletedAlert(
          farmId: farmId,
          sensorId: null,
          zoneName: zoneName,
        );
        final alert = AlertModel(
          id: alertId,
          farmId: farmId,
          sensorId: null,
          type: 'VALVE',
          message: 'Irrigation completed for $zoneName.',
          severity: 'info',
          ts: now,
          read: false,
        );
        await AlertLocalService.addAlert(alert);
      } catch (e) {
        log('Warning: failed creating completion alert: $e');
      }
      patched++;
    }
    return patched;
  }
}
