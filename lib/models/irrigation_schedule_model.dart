class IrrigationSchedule {
  final String scheduleId;
  final String userId;
  final String farmId;
  final String fieldId;
  final String fieldName;
  final DateTime startTime;
  final int durationMinutes;
  final bool isActive;
  final String status; // scheduled, running, completed, cancelled
  final DateTime? completedAt;
  final double? waterUsed; // in liters
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  IrrigationSchedule({
    required this.scheduleId,
    required this.userId,
    required this.farmId,
    required this.fieldId,
    required this.fieldName,
    required this.startTime,
    required this.durationMinutes,
    required this.isActive,
    required this.status,
    this.completedAt,
    this.waterUsed,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'userId': userId,
      'farmId': farmId,
      'fieldId': fieldId,
      'fieldName': fieldName,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'isActive': isActive,
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
      'waterUsed': waterUsed,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory IrrigationSchedule.fromMap(Map<String, dynamic> map) {
    return IrrigationSchedule(
      scheduleId: map['scheduleId'] ?? '',
      userId: map['userId'] ?? '',
      farmId: map['farmId'] ?? '',
      fieldId: map['fieldId'] ?? '',
      fieldName: map['fieldName'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      durationMinutes: map['durationMinutes'] ?? 0,
      isActive: map['isActive'] ?? false,
      status: map['status'] ?? 'scheduled',
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      waterUsed: map['waterUsed']?.toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Check if schedule is upcoming
  bool get isUpcoming {
    return status == 'scheduled' && startTime.isAfter(DateTime.now());
  }

  // Check if schedule is running
  bool get isRunning {
    return status == 'running';
  }

  // Get time until start
  Duration get timeUntilStart {
    return startTime.difference(DateTime.now());
  }

  // Format duration
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes minutes';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes minutes';
    }
  }

  // Copy with method
  IrrigationSchedule copyWith({
    String? scheduleId,
    String? userId,
    String? farmId,
    String? fieldId,
    String? fieldName,
    DateTime? startTime,
    int? durationMinutes,
    bool? isActive,
    String? status,
    DateTime? completedAt,
    double? waterUsed,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IrrigationSchedule(
      scheduleId: scheduleId ?? this.scheduleId,
      userId: userId ?? this.userId,
      farmId: farmId ?? this.farmId,
      fieldId: fieldId ?? this.fieldId,
      fieldName: fieldName ?? this.fieldName,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      waterUsed: waterUsed ?? this.waterUsed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

