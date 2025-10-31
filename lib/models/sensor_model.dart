import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'sensor_model.g.dart';

@HiveType(typeId: 3)
class SensorModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String farmId;
  @HiveField(2)
  final String? displayName;
  @HiveField(3)
  final String type; // 'soil', 'temperature', etc.
  @HiveField(4)
  final String hardwareId;
  @HiveField(5)
  final Map<String, dynamic> pairing; // method, meta (with keys for BLE, WiFi, LoRa, etc.)
  @HiveField(6)
  final String status; // 'online', 'offline', ...
  @HiveField(7)
  final DateTime? lastSeenAt;
  @HiveField(8)
  final String? assignedZoneId;
  @HiveField(9)
  final double? battery;
  @HiveField(10)
  final String? installNote;

  SensorModel({
    required this.id,
    required this.farmId,
    this.displayName,
    required this.type,
    required this.hardwareId,
    required this.pairing,
    required this.status,
    this.lastSeenAt,
    this.assignedZoneId,
    this.battery,
    this.installNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmId': farmId,
      'displayName': displayName,
      'type': type,
      'hardwareId': hardwareId,
      'pairing': pairing,
      'status': status,
      'lastSeenAt': lastSeenAt,
      'assignedZoneId': assignedZoneId,
      'battery': battery,
      'installNote': installNote,
    };
  }

  factory SensorModel.fromMap(Map<String, dynamic> map) {
    return SensorModel(
      id: map['id'] ?? '',
      farmId: map['farmId'] ?? '',
      displayName: map['displayName'],
      type: map['type'] ?? '',
      hardwareId: map['hardwareId'] ?? '',
      pairing: Map<String, dynamic>.from(map['pairing'] ?? {}),
      status: map['status'] ?? 'offline',
      lastSeenAt: map['lastSeenAt'] != null
          ? (map['lastSeenAt'] is Timestamp
              ? (map['lastSeenAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['lastSeenAt'].toString()))
          : null,
      assignedZoneId: map['assignedZoneId'],
      battery: map['battery'] != null ? (map['battery'] as num).toDouble() : null,
      installNote: map['installNote'],
    );
  }

  factory SensorModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return SensorModel.fromMap({'id': doc.id, ...map});
  }
}

