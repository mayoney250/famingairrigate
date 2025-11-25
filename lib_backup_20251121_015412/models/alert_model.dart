import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
part 'alert_model.g.dart';

@HiveType(typeId: 2)
class AlertModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String farmId;
  @HiveField(2)
  final String? sensorId;
  @HiveField(3)
  final String type; // 'THRESHOLD','OFFLINE','VALVE'
  @HiveField(4)
  final String message;
  @HiveField(5)
  final String severity; // e.g. 'low','medium','high'
  @HiveField(6)
  final DateTime ts;
  @HiveField(7)
  final bool read;

  AlertModel({
    required this.id,
    required this.farmId,
    this.sensorId,
    required this.type,
    required this.message,
    required this.severity,
    required this.ts,
    this.read = false,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map) => AlertModel(
      id: map['id'] ?? '',
      farmId: map['farmId'] ?? '',
      sensorId: map['sensorId'],
      type: map['type'] ?? 'THRESHOLD',
      message: map['message'] ?? '',
      severity: map['severity'] ?? 'info',
      ts: map['ts'] is Timestamp
          ? (map['ts'] as Timestamp).toDate()
          : (map['ts'] is DateTime
              ? map['ts']
              : DateTime.tryParse(map['ts'].toString()) ?? DateTime.now()),
      read: map['read'] ?? false,
    );

  Map<String, dynamic> toMap() => {
        'id': id,
        'farmId': farmId,
        'sensorId': sensorId,
        'type': type,
        'message': message,
        'severity': severity,
        'ts': ts,
        'read': read,
      };

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return AlertModel.fromMap({'id': doc.id, ...map});
  }
}

