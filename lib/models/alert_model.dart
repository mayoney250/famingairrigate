import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType {
  lowMoisture,
  highTemperature,
  lowBattery,
  irrigationCompleted,
  irrigationFailed,
  sensorOffline,
  weatherWarning,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

class AlertModel {
  final String id;
  final String userId;
  final String? fieldId;
  final String? zoneId;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final bool isRead;
  final DateTime timestamp;

  AlertModel({
    required this.id,
    required this.userId,
    this.fieldId,
    this.zoneId,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fieldId': fieldId,
      'zoneId': zoneId,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'title': title,
      'message': message,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fieldId: map['fieldId'],
      zoneId: map['zoneId'],
      type: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => AlertType.irrigationCompleted,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == map['severity'],
        orElse: () => AlertSeverity.info,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertModel.fromMap(data);
  }

  AlertModel copyWith({
    String? id,
    String? userId,
    String? fieldId,
    String? zoneId,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    bool? isRead,
    DateTime? timestamp,
  }) {
    return AlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fieldId: fieldId ?? this.fieldId,
      zoneId: zoneId ?? this.zoneId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${difference.inDays ~/ 7} weeks ago';
    }
  }
}

