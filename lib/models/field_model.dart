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
    // Normalize addedDate to an ISO-8601 string so callers can rely on a
    // consistent representation whether Firestore returned a Timestamp,
    // a DateTime or a String.
    final rawAdded = map['addedDate'];
    String addedDateStr;
    if (rawAdded == null) {
      addedDateStr = '';
    } else if (rawAdded is String) {
      addedDateStr = rawAdded;
    } else if (rawAdded is DateTime) {
      addedDateStr = rawAdded.toIso8601String();
    } else if (rawAdded is Timestamp) {
      addedDateStr = rawAdded.toDate().toIso8601String();
    } else {
      addedDateStr = rawAdded.toString();
    }

    return FieldModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      label: map['label'] ?? '',
      addedDate: addedDateStr,
      borderCoordinates: (map['borderCoordinates'] as List<dynamic>?)
              ?.map((coord) {
        if (coord is GeoPoint) return coord;
        if (coord is Map) {
          final latRaw = coord['latitude'] ?? coord['lat'] ?? coord['Latitude'];
          final lngRaw = coord['longitude'] ?? coord['lng'] ?? coord['Longitude'];
          final lat = (latRaw is num) ? latRaw.toDouble() : double.tryParse(latRaw?.toString() ?? '') ?? 0.0;
          final lng = (lngRaw is num) ? lngRaw.toDouble() : double.tryParse(lngRaw?.toString() ?? '') ?? 0.0;
          return GeoPoint(lat, lng);
        }
        if (coord is List && coord.length >= 2) {
          final latRaw = coord[0];
          final lngRaw = coord[1];
          final lat = (latRaw is num) ? latRaw.toDouble() : double.tryParse(latRaw?.toString() ?? '') ?? 0.0;
          final lng = (lngRaw is num) ? lngRaw.toDouble() : double.tryParse(lngRaw?.toString() ?? '') ?? 0.0;
          return GeoPoint(lat, lng);
        }
        return GeoPoint(0.0, 0.0);
      }).toList() ??
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
    final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
    // Ensure the doc id is available to the model
    data['id'] = doc.id;
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

