import 'package:cloud_firestore/cloud_firestore.dart';

enum IrrigationAction {
  started,
  stopped,
  completed,
  failed,
  scheduled,
}

class IrrigationLogModel {
  final String id;
  final String userId;
  final String zoneId;
  final String zoneName;
  final IrrigationAction action;
  final int? durationMinutes;
  final double? waterUsed; // Liters
  final String? scheduleId;
  final String? triggeredBy; // 'manual', 'schedule', 'auto'
  final String? notes;
  final DateTime timestamp;

  IrrigationLogModel({
    required this.id,
    required this.userId,
    required this.zoneId,
    required this.zoneName,
    required this.action,
    this.durationMinutes,
    this.waterUsed,
    this.scheduleId,
    this.triggeredBy,
    this.notes,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'action': action.toString().split('.').last,
      'durationMinutes': durationMinutes,
      'waterUsed': waterUsed,
      'scheduleId': scheduleId,
      'triggeredBy': triggeredBy,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory IrrigationLogModel.fromMap(Map<String, dynamic> map) {
    return IrrigationLogModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      zoneId: map['zoneId'] ?? map['fieldId'] ?? '',
      zoneName: map['zoneName'] ?? '',
      action: IrrigationAction.values.firstWhere(
        (e) => e.toString().split('.').last == map['action'],
        orElse: () => IrrigationAction.started,
      ),
      durationMinutes: map['durationMinutes'],
      waterUsed: map['waterUsed']?.toDouble(),
      scheduleId: map['scheduleId'],
      triggeredBy: map['triggeredBy'],
      notes: map['notes'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  factory IrrigationLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IrrigationLogModel.fromMap(data);
  }

  String get actionDisplay {
    switch (action) {
      case IrrigationAction.started:
        return 'Started Irrigation';
      case IrrigationAction.stopped:
        return 'Stopped Irrigation';
      case IrrigationAction.completed:
        return 'Irrigation Completed';
      case IrrigationAction.failed:
        return 'Irrigation Failed';
      case IrrigationAction.scheduled:
        return 'Scheduled Irrigation';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

