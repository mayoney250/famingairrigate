import 'package:cloud_firestore/cloud_firestore.dart';

class SensorModel {
  final String id;
  final String userId;
  final String fieldId;
  final String sensorName;
  final String sensorType;
  final String connectionMethod;
  final String? deviceId;
  final String? ipAddress;
  final bool isActive;
  final bool isOnline;
  final DateTime installedDate;
  final double? latitude;
  final double? longitude;
  final int readingInterval;
  final Map<String, dynamic>? thresholds;
  final double? batteryLevel;
  final DateTime? lastReading;
  final Map<String, dynamic>? lastReadingData;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SensorModel({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.sensorName,
    required this.sensorType,
    required this.connectionMethod,
    this.deviceId,
    this.ipAddress,
    this.isActive = true,
    this.isOnline = false,
    required this.installedDate,
    this.latitude,
    this.longitude,
    this.readingInterval = 15,
    this.thresholds,
    this.batteryLevel,
    this.lastReading,
    this.lastReadingData,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fieldId': fieldId,
      'sensorName': sensorName,
      'sensorType': sensorType,
      'connectionMethod': connectionMethod,
      'deviceId': deviceId,
      'ipAddress': ipAddress,
      'isActive': isActive,
      'isOnline': isOnline,
      'installedDate': Timestamp.fromDate(installedDate),
      'latitude': latitude,
      'longitude': longitude,
      'readingInterval': readingInterval,
      'thresholds': thresholds,
      'batteryLevel': batteryLevel,
      'lastReading': lastReading != null
          ? Timestamp.fromDate(lastReading!)
          : null,
      'lastReadingData': lastReadingData,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SensorModel.fromMap(Map<String, dynamic> map) {
    return SensorModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fieldId: map['fieldId'] ?? '',
      sensorName: map['sensorName'] ?? '',
      sensorType: map['sensorType'] ?? '',
      connectionMethod: map['connectionMethod'] ?? '',
      deviceId: map['deviceId'],
      ipAddress: map['ipAddress'],
      isActive: map['isActive'] ?? true,
      isOnline: map['isOnline'] ?? false,
      installedDate: (map['installedDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      readingInterval: map['readingInterval'] ?? 15,
      thresholds: map['thresholds'],
      batteryLevel: map['batteryLevel']?.toDouble(),
      lastReading: (map['lastReading'] as Timestamp?)?.toDate(),
      lastReadingData: map['lastReadingData'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory SensorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SensorModel.fromMap(data);
  }

  SensorModel copyWith({
    String? id,
    String? userId,
    String? fieldId,
    String? sensorName,
    String? sensorType,
    String? connectionMethod,
    String? deviceId,
    String? ipAddress,
    bool? isActive,
    bool? isOnline,
    DateTime? installedDate,
    double? latitude,
    double? longitude,
    int? readingInterval,
    Map<String, dynamic>? thresholds,
    double? batteryLevel,
    DateTime? lastReading,
    Map<String, dynamic>? lastReadingData,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SensorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fieldId: fieldId ?? this.fieldId,
      sensorName: sensorName ?? this.sensorName,
      sensorType: sensorType ?? this.sensorType,
      connectionMethod: connectionMethod ?? this.connectionMethod,
      deviceId: deviceId ?? this.deviceId,
      ipAddress: ipAddress ?? this.ipAddress,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      installedDate: installedDate ?? this.installedDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      readingInterval: readingInterval ?? this.readingInterval,
      thresholds: thresholds ?? this.thresholds,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastReading: lastReading ?? this.lastReading,
      lastReadingData: lastReadingData ?? this.lastReadingData,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

