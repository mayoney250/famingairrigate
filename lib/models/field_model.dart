import 'package:cloud_firestore/cloud_firestore.dart';

class FieldModel {
  final String id;
  final String userId;
  final String label;
  final String addedDate;
  final List<GeoPoint> borderCoordinates;
  final double size;
  final String color;
  final String? imageUrl;
  final String owner;
  final bool isActive;
  final bool isOrganic;
  final double? moisture;
  final double? pH;
  final double? temperature;
  final List<String>? cropIds;
  final List<String>? irrigationSystemIds;

  FieldModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.addedDate,
    required this.borderCoordinates,
    required this.size,
    this.color = '#4CAF50',
    this.imageUrl,
    required this.owner,
    this.isActive = true,
    this.isOrganic = false,
    this.moisture,
    this.pH,
    this.temperature,
    this.cropIds,
    this.irrigationSystemIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'addedDate': addedDate,
      'borderCoordinates': borderCoordinates.map((gp) {
        return {
          'latitude': gp.latitude,
          'longitude': gp.longitude,
        };
      }).toList(),
      'size': size,
      'color': color,
      'imageUrl': imageUrl,
      'owner': owner,
      'isActive': isActive,
      'isOrganic': isOrganic,
      'moisture': moisture,
      'pH': pH,
      'temperature': temperature,
      'cropIds': cropIds,
      'irrigationSystemIds': irrigationSystemIds,
    };
  }

  factory FieldModel.fromMap(Map<String, dynamic> map) {
    return FieldModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      label: map['label'] ?? '',
      addedDate: map['addedDate'] ?? '',
      borderCoordinates: (map['borderCoordinates'] as List<dynamic>?)
              ?.map((coord) => GeoPoint(
                    coord['latitude'] ?? 0.0,
                    coord['longitude'] ?? 0.0,
                  ))
              .toList() ??
          [],
      size: map['size']?.toDouble() ?? 0.0,
      color: map['color'] ?? '#4CAF50',
      imageUrl: map['imageUrl'],
      owner: map['owner'] ?? '',
      isActive: map['isActive'] ?? true,
      isOrganic: map['isOrganic'] ?? false,
      moisture: map['moisture']?.toDouble(),
      pH: map['pH']?.toDouble(),
      temperature: map['temperature']?.toDouble(),
      cropIds: map['cropIds'] != null
          ? List<String>.from(map['cropIds'])
          : null,
      irrigationSystemIds: map['irrigationSystemIds'] != null
          ? List<String>.from(map['irrigationSystemIds'])
          : null,
    );
  }

  factory FieldModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FieldModel.fromMap(data);
  }

  FieldModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? addedDate,
    List<GeoPoint>? borderCoordinates,
    double? size,
    String? color,
    String? imageUrl,
    String? owner,
    bool? isActive,
    bool? isOrganic,
    double? moisture,
    double? pH,
    double? temperature,
    List<String>? cropIds,
    List<String>? irrigationSystemIds,
  }) {
    return FieldModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      addedDate: addedDate ?? this.addedDate,
      borderCoordinates: borderCoordinates ?? this.borderCoordinates,
      size: size ?? this.size,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      owner: owner ?? this.owner,
      isActive: isActive ?? this.isActive,
      isOrganic: isOrganic ?? this.isOrganic,
      moisture: moisture ?? this.moisture,
      pH: pH ?? this.pH,
      temperature: temperature ?? this.temperature,
      cropIds: cropIds ?? this.cropIds,
      irrigationSystemIds: irrigationSystemIds ?? this.irrigationSystemIds,
    );
  }
}

