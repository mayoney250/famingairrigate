import 'package:cloud_firestore/cloud_firestore.dart';

class IrrigationScheduleModel {
  final String id;
  final String userId;
  final String name;
  final String zoneId;
  final String zoneName;
  final DateTime startTime;
  final int durationMinutes;
  final List<int> repeatDays; // 1=Monday, 7=Sunday
  final bool isActive;
  final String status; // 'scheduled', 'running', 'completed', 'stopped'
  final DateTime createdAt;
  final DateTime? lastRun;
  final DateTime? nextRun;
  final DateTime? stoppedAt;
  final String? stoppedBy; // 'manual' or 'automatic'
  final bool isManual; // true if this is a manual irrigation cycle

  IrrigationScheduleModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.zoneId,
    required this.zoneName,
    required this.startTime,
    required this.durationMinutes,
    required this.repeatDays,
    this.isActive = true,
    this.status = 'scheduled',
    required this.createdAt,
    this.lastRun,
    this.nextRun,
    this.stoppedAt,
    this.stoppedBy,
    this.isManual = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'startTime': Timestamp.fromDate(startTime),
      'durationMinutes': durationMinutes,
      'repeatDays': repeatDays,
      'isActive': isActive,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastRun': lastRun != null ? Timestamp.fromDate(lastRun!) : null,
      'nextRun': nextRun != null ? Timestamp.fromDate(nextRun!) : null,
      'stoppedAt': stoppedAt != null ? Timestamp.fromDate(stoppedAt!) : null,
      'stoppedBy': stoppedBy,
      'isManual': isManual,
    };
  }

  factory IrrigationScheduleModel.fromMap(Map<String, dynamic> map) {
    try {
      DateTime parseDate(dynamic value) {
        if (value == null) return DateTime.now();
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        if (value is String) {
          // Try ISO8601 or other formats
          return DateTime.tryParse(value) ?? DateTime.now();
        }
        return DateTime.now();
      }

      int parseInt(dynamic value, {int fallback = 0}) {
        if (value == null) return fallback;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          return int.tryParse(value) ?? fallback;
        }
        return fallback;
      }

      List<int> parseIntList(dynamic value) {
        if (value == null) return <int>[];
        if (value is List) {
          return value.map((e) => parseInt(e, fallback: 0)).where((e) => e > 0).toList();
        }
        return <int>[];
      }

      return IrrigationScheduleModel(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        name: map['name'] ?? '',
        zoneId: map['zoneId'] ?? '',
        zoneName: map['zoneName'] ?? '',
        startTime: parseDate(map['startTime']),
        durationMinutes: parseInt(map['durationMinutes'], fallback: 30),
        repeatDays: parseIntList(map['repeatDays']),
        isActive: map['isActive'] is bool ? map['isActive'] as bool : (map['isActive'].toString() == 'true'),
        status: map['status'] ?? 'scheduled',
        createdAt: parseDate(map['createdAt']),
        lastRun: map['lastRun'] != null ? parseDate(map['lastRun']) : null,
        nextRun: map['nextRun'] != null ? parseDate(map['nextRun']) : null,
        stoppedAt: map['stoppedAt'] != null ? parseDate(map['stoppedAt']) : null,
        stoppedBy: map['stoppedBy'],
        isManual: map['isManual'] is bool ? map['isManual'] as bool : (map['isManual'] == true),
      );
    } catch (e) {
      rethrow;
    }
  }

  factory IrrigationScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Use Firestore document ID
    return IrrigationScheduleModel.fromMap(data);
  }

  IrrigationScheduleModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? zoneId,
    String? zoneName,
    DateTime? startTime,
    int? durationMinutes,
    List<int>? repeatDays,
    bool? isActive,
    String? status,
    DateTime? createdAt,
    DateTime? lastRun,
    DateTime? nextRun,
    DateTime? stoppedAt,
    String? stoppedBy,
    bool? isManual,
  }) {
    return IrrigationScheduleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastRun: lastRun ?? this.lastRun,
      nextRun: nextRun ?? this.nextRun,
      stoppedAt: stoppedAt ?? this.stoppedAt,
      stoppedBy: stoppedBy ?? this.stoppedBy,
      isManual: isManual ?? this.isManual,
    );
  }

  String get formattedTime {
    final hour = startTime.hour.toString().padLeft(2, '0');
    final minute = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${startTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
  }
}
