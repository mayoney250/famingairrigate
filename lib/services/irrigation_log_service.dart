import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/irrigation_log_model.dart';

class IrrigationLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'irrigationLogs';

  // Create log entry
  Future<String> createLog(IrrigationLogModel log) async {
    try {
      final docRef = await _firestore.collection(_collection).add(log.toMap());
      dev.log('Irrigation log created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      dev.log('Error creating irrigation log: $e');
      rethrow;
    }
  }

  // Get all logs for user
  Future<List<IrrigationLogModel>> getUserLogs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => IrrigationLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      dev.log('Error fetching irrigation logs: $e');
      rethrow;
    }
  }

  // Stream of user logs
  Stream<List<IrrigationLogModel>> streamUserLogs(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IrrigationLogModel.fromFirestore(doc))
            .toList());
  }

  // Get logs for a specific zone
  Future<List<IrrigationLogModel>> getZoneLogs(
    String userId,
    String zoneId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('zoneId', isEqualTo: zoneId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => IrrigationLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      dev.log('Error fetching zone logs: $e');
      rethrow;
    }
  }

  // Get logs by action type
  Future<List<IrrigationLogModel>> getLogsByAction(
    String userId,
    IrrigationAction action,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('action', isEqualTo: action.toString().split('.').last)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => IrrigationLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      dev.log('Error fetching logs by action: $e');
      rethrow;
    }
  }

  // Get today's logs
  Future<List<IrrigationLogModel>> getTodayLogs(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      dev.log('🔍 [IrrigationLogService] Fetching logs for userId: $userId');
      dev.log('🔍 [IrrigationLogService] Date range: $startOfDay to $endOfDay');

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true)
          .get();

      dev.log('📊 [IrrigationLogService] Found ${snapshot.docs.length} logs');
      
      final logs = snapshot.docs
          .map((doc) {
            final log = IrrigationLogModel.fromFirestore(doc);
            dev.log('📝 [IrrigationLogService] Log: id=${log.id}, zoneId=${log.zoneId}, waterUsed=${log.waterUsed}, action=${log.action}');
            return log;
          })
          .toList();
      
      return logs;
    } catch (e) {
      dev.log('❌ [IrrigationLogService] Error fetching today logs: $e');
      rethrow;
    }
  }

  // Get logs in date range
  Future<List<IrrigationLogModel>> getLogsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => IrrigationLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      dev.log('Error fetching logs in range: $e');
      rethrow;
    }
  }

  // Log irrigation start
  Future<String> logIrrigationStart(
    String userId,
    String zoneId,
    String zoneName, {
    String? scheduleId,
    String triggeredBy = 'manual',
  }) async {
    final entry = IrrigationLogModel(
      id: '',
      userId: userId,
      zoneId: zoneId,
      zoneName: zoneName,
      action: IrrigationAction.started,
      scheduleId: scheduleId,
      triggeredBy: triggeredBy,
      timestamp: DateTime.now(),
    );
    return createLog(entry);
  }

  // Log irrigation completion
  Future<String> logIrrigationCompleted(
    String userId,
    String zoneId,
    String zoneName,
    int durationMinutes,
    double waterUsed, {
    String? scheduleId,
    String triggeredBy = 'manual',
  }) async {
    final entry = IrrigationLogModel(
      id: '',
      userId: userId,
      zoneId: zoneId,
      zoneName: zoneName,
      action: IrrigationAction.completed,
      durationMinutes: durationMinutes,
      waterUsed: waterUsed,
      scheduleId: scheduleId,
      triggeredBy: triggeredBy,
      timestamp: DateTime.now(),
    );
    return createLog(entry);
  }

  // Log irrigation stop
  Future<String> logIrrigationStop(
    String userId,
    String zoneId,
    String zoneName,
    int durationMinutes,
    double waterUsed,
  ) async {
    final entry = IrrigationLogModel(
      id: '',
      userId: userId,
      zoneId: zoneId,
      zoneName: zoneName,
      action: IrrigationAction.stopped,
      durationMinutes: durationMinutes,
      waterUsed: waterUsed,
      timestamp: DateTime.now(),
    );
    return createLog(entry);
  }

  // Calculate total water used today
  Future<double> getTodayWaterUsage(String userId) async {
    try {
      final logs = await getTodayLogs(userId);
      double total = 0;
      for (final log in logs) {
        if (log.waterUsed != null) {
          total += log.waterUsed!;
        }
      }
      return total;
    } catch (e) {
      dev.log('Error calculating today water usage: $e');
      return 0;
    }
  }

  // Calculate total water used this week
  Future<double> getThisWeekWaterUsage(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final logs = await getLogsInRange(userId, startOfWeek, now);
      
      double total = 0;
      for (final log in logs) {
        if (log.waterUsed != null) {
          total += log.waterUsed!;
        }
      }
      return total;
    } catch (e) {
      dev.log('Error calculating week water usage: $e');
      return 0;
    }
  }

  // Delete old logs (keep last 90 days)
  Future<void> deleteOldLogs(String userId, int daysToKeep) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      dev.log('Old irrigation logs deleted: ${snapshot.docs.length} records');
    } catch (e) {
      dev.log('Error deleting old logs: $e');
      rethrow;
    }
  }
}

