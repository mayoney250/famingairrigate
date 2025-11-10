import 'package:cloud_firestore/cloud_firestore.dart';

enum IrrigationZoneType {
  field,
  pipe,
  canal,
  sprinkler,
  drip,
  custom,
}

enum DrawingType {
  polygon,
  polyline,
  marker,
}

class IrrigationZone {
  final String id;
  final String fieldId;
  final String userId;
  final String name;
  final String? description;
  final IrrigationZoneType zoneType;
  final DrawingType drawingType;
  final List<GeoPoint> coordinates;
  final String color;
  final double? flowRate;
  final double? coverage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  IrrigationZone({
    required this.id,
    required this.fieldId,
    required this.userId,
    required this.name,
    this.description,
    required this.zoneType,
    required this.drawingType,
    required this.coordinates,
    this.color = '#2196F3',
    this.flowRate,
    this.coverage,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'userId': userId,
      'name': name,
      'description': description,
      'zoneType': zoneType.name,
      'drawingType': drawingType.name,
      'coordinates': coordinates.map((gp) => {
        'latitude': gp.latitude,
        'longitude': gp.longitude,
      }).toList(),
      'color': color,
      'flowRate': flowRate,
      'coverage': coverage,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory IrrigationZone.fromMap(Map<String, dynamic> map) {
    return IrrigationZone(
      id: map['id'] ?? '',
      fieldId: map['fieldId'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      zoneType: IrrigationZoneType.values.firstWhere(
        (e) => e.name == map['zoneType'],
        orElse: () => IrrigationZoneType.custom,
      ),
      drawingType: DrawingType.values.firstWhere(
        (e) => e.name == map['drawingType'],
        orElse: () => DrawingType.polygon,
      ),
      coordinates: (map['coordinates'] as List<dynamic>?)
              ?.map((coord) => GeoPoint(
                    coord['latitude'] ?? 0.0,
                    coord['longitude'] ?? 0.0,
                  ))
              .toList() ??
          [],
      color: map['color'] ?? '#2196F3',
      flowRate: map['flowRate']?.toDouble(),
      coverage: map['coverage']?.toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      metadata: map['metadata'],
    );
  }

  factory IrrigationZone.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IrrigationZone.fromMap(data);
  }

  IrrigationZone copyWith({
    String? id,
    String? fieldId,
    String? userId,
    String? name,
    String? description,
    IrrigationZoneType? zoneType,
    DrawingType? drawingType,
    List<GeoPoint>? coordinates,
    String? color,
    double? flowRate,
    double? coverage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return IrrigationZone(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      zoneType: zoneType ?? this.zoneType,
      drawingType: drawingType ?? this.drawingType,
      coordinates: coordinates ?? this.coordinates,
      color: color ?? this.color,
      flowRate: flowRate ?? this.flowRate,
      coverage: coverage ?? this.coverage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
