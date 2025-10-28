import 'package:cloud_firestore/cloud_firestore.dart';

class IrrigationZoneModel {
  final String id;
  final String userId;
  final String fieldId;
  final String name;
  final double areaHectares;
  final String? cropType;
  final bool isActive;
  final double waterUsageToday; // Liters
  final double waterUsageThisWeek; // Liters
  final DateTime createdAt;
  final DateTime? lastIrrigation;

  IrrigationZoneModel({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.name,
    required this.areaHectares,
    this.cropType,
    this.isActive = true,
    this.waterUsageToday = 0.0,
    this.waterUsageThisWeek = 0.0,
    required this.createdAt,
    this.lastIrrigation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fieldId': fieldId,
      'name': name,
      'areaHectares': areaHectares,
      'cropType': cropType,
      'isActive': isActive,
      'waterUsageToday': waterUsageToday,
      'waterUsageThisWeek': waterUsageThisWeek,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastIrrigation': lastIrrigation != null ? Timestamp.fromDate(lastIrrigation!) : null,
    };
  }

  factory IrrigationZoneModel.fromMap(Map<String, dynamic> map) {
    return IrrigationZoneModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fieldId: map['fieldId'] ?? '',
      name: map['name'] ?? '',
      areaHectares: (map['areaHectares'] ?? 0.0).toDouble(),
      cropType: map['cropType'],
      isActive: map['isActive'] ?? true,
      waterUsageToday: (map['waterUsageToday'] ?? 0.0).toDouble(),
      waterUsageThisWeek: (map['waterUsageThisWeek'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastIrrigation: map['lastIrrigation'] != null 
          ? (map['lastIrrigation'] as Timestamp).toDate() 
          : null,
    );
  }

  factory IrrigationZoneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IrrigationZoneModel.fromMap(data);
  }

  IrrigationZoneModel copyWith({
    String? id,
    String? userId,
    String? fieldId,
    String? name,
    double? areaHectares,
    String? cropType,
    bool? isActive,
    double? waterUsageToday,
    double? waterUsageThisWeek,
    DateTime? createdAt,
    DateTime? lastIrrigation,
  }) {
    return IrrigationZoneModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fieldId: fieldId ?? this.fieldId,
      name: name ?? this.name,
      areaHectares: areaHectares ?? this.areaHectares,
      cropType: cropType ?? this.cropType,
      isActive: isActive ?? this.isActive,
      waterUsageToday: waterUsageToday ?? this.waterUsageToday,
      waterUsageThisWeek: waterUsageThisWeek ?? this.waterUsageThisWeek,
      createdAt: createdAt ?? this.createdAt,
      lastIrrigation: lastIrrigation ?? this.lastIrrigation,
    );
  }
}

