import 'package:cloud_firestore/cloud_firestore.dart';

class SensorModel {
  final String id;
  final String farmId;
  final String? displayName;
  final String type; // 'soil', 'temperature', etc.
  final String hardwareId;
  final Map<String, dynamic> pairing; // method, meta (with keys for BLE, WiFi, LoRa, etc.)
  final String status; // 'online', 'offline', ...
  final DateTime? lastSeenAt;
  final String? assignedZoneId;
  final double? battery;
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
      'lastSeenAt': lastSeenAt != null ? Timestamp.fromDate(lastSeenAt!) : null,
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
      lastSeenAt: map['lastSeenAt'] != null ? (map['lastSeenAt'] is Timestamp ? (map['lastSeenAt'] as Timestamp).toDate() : DateTime.tryParse(map['lastSeenAt'].toString()) ) : null,
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

