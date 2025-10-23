import 'package:cloud_firestore/cloud_firestore.dart';

class IrrigationModel {
  final String id;
  final String userId;
  final String fieldId;
  final String systemName;
  final String irrigationType;
  final String waterSource;
  final double? flowRate;
  final String? flowRateUnit;
  final bool isAutomated;
  final bool isActive;
  final DateTime installedDate;
  final double? totalWaterUsed;
  final double? costPerCubicMeter;
  final String? currency;
  final Map<String, dynamic>? schedule;
  final List<String>? connectedSensors;
  final double? efficiency;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  IrrigationModel({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.systemName,
    required this.irrigationType,
    required this.waterSource,
    this.flowRate,
    this.flowRateUnit = 'L/h',
    this.isAutomated = false,
    this.isActive = true,
    required this.installedDate,
    this.totalWaterUsed = 0.0,
    this.costPerCubicMeter,
    this.currency = 'RWF',
    this.schedule,
    this.connectedSensors,
    this.efficiency,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fieldId': fieldId,
      'systemName': systemName,
      'irrigationType': irrigationType,
      'waterSource': waterSource,
      'flowRate': flowRate,
      'flowRateUnit': flowRateUnit,
      'isAutomated': isAutomated,
      'isActive': isActive,
      'installedDate': Timestamp.fromDate(installedDate),
      'totalWaterUsed': totalWaterUsed,
      'costPerCubicMeter': costPerCubicMeter,
      'currency': currency,
      'schedule': schedule,
      'connectedSensors': connectedSensors,
      'efficiency': efficiency,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory IrrigationModel.fromMap(Map<String, dynamic> map) {
    return IrrigationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fieldId: map['fieldId'] ?? '',
      systemName: map['systemName'] ?? '',
      irrigationType: map['irrigationType'] ?? '',
      waterSource: map['waterSource'] ?? '',
      flowRate: map['flowRate']?.toDouble(),
      flowRateUnit: map['flowRateUnit'] ?? 'L/h',
      isAutomated: map['isAutomated'] ?? false,
      isActive: map['isActive'] ?? true,
      installedDate: (map['installedDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      totalWaterUsed: map['totalWaterUsed']?.toDouble() ?? 0.0,
      costPerCubicMeter: map['costPerCubicMeter']?.toDouble(),
      currency: map['currency'] ?? 'RWF',
      schedule: map['schedule'],
      connectedSensors: map['connectedSensors'] != null
          ? List<String>.from(map['connectedSensors'])
          : null,
      efficiency: map['efficiency']?.toDouble(),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory IrrigationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IrrigationModel.fromMap(data);
  }

  IrrigationModel copyWith({
    String? id,
    String? userId,
    String? fieldId,
    String? systemName,
    String? irrigationType,
    String? waterSource,
    double? flowRate,
    String? flowRateUnit,
    bool? isAutomated,
    bool? isActive,
    DateTime? installedDate,
    double? totalWaterUsed,
    double? costPerCubicMeter,
    String? currency,
    Map<String, dynamic>? schedule,
    List<String>? connectedSensors,
    double? efficiency,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IrrigationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fieldId: fieldId ?? this.fieldId,
      systemName: systemName ?? this.systemName,
      irrigationType: irrigationType ?? this.irrigationType,
      waterSource: waterSource ?? this.waterSource,
      flowRate: flowRate ?? this.flowRate,
      flowRateUnit: flowRateUnit ?? this.flowRateUnit,
      isAutomated: isAutomated ?? this.isAutomated,
      isActive: isActive ?? this.isActive,
      installedDate: installedDate ?? this.installedDate,
      totalWaterUsed: totalWaterUsed ?? this.totalWaterUsed,
      costPerCubicMeter: costPerCubicMeter ?? this.costPerCubicMeter,
      currency: currency ?? this.currency,
      schedule: schedule ?? this.schedule,
      connectedSensors: connectedSensors ?? this.connectedSensors,
      efficiency: efficiency ?? this.efficiency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

