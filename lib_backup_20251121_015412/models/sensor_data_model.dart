import 'package:cloud_firestore/cloud_firestore.dart';

class SensorDataModel {
  final String id;
  final String userId;
  final String fieldId;
  final String? sensorId;
  final double soilMoisture; // Percentage
  final double temperature; // Celsius
  final double humidity; // Percentage
  final int? battery; // Percentage
  final DateTime timestamp;

  SensorDataModel({
    required this.id,
    required this.userId,
    required this.fieldId,
    this.sensorId,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    this.battery,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fieldId': fieldId,
      'sensorId': sensorId,
      'soilMoisture': soilMoisture,
      'temperature': temperature,
      'humidity': humidity,
      'battery': battery,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory SensorDataModel.fromMap(Map<String, dynamic> map) {
    return SensorDataModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fieldId: map['fieldId'] ?? '',
      sensorId: map['sensorId'],
      soilMoisture: (map['soilMoisture'] ?? 0.0).toDouble(),
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      battery: map['battery'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  factory SensorDataModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SensorDataModel.fromMap(data);
  }

  String get moistureStatus {
    if (soilMoisture < 30) return 'Low';
    if (soilMoisture < 60) return 'Normal';
    return 'High';
  }

  String get temperatureStatus {
    if (temperature < 15) return 'Cold';
    if (temperature < 30) return 'Normal';
    return 'Hot';
  }
}

