import 'package:cloud_firestore/cloud_firestore.dart';

class SensorReadingModel {
  final String id;
  final String sensorId;
  final DateTime ts;
  final double? moisture;
  final double? temperature;
  final double? humidity;

  SensorReadingModel({
    required this.id,
    required this.sensorId,
    required this.ts,
    this.moisture,
    this.temperature,
    this.humidity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensorId': sensorId,
      'ts': Timestamp.fromDate(ts),
      'moisture': moisture,
      'temperature': temperature,
      'humidity': humidity,
    };
  }

  factory SensorReadingModel.fromMap(Map<String, dynamic> map) {
    return SensorReadingModel(
      id: map['id'] ?? '',
      sensorId: map['sensorId'] ?? '',
      ts: map['ts'] is Timestamp ? (map['ts'] as Timestamp).toDate() : DateTime.tryParse(map['ts'].toString()) ?? DateTime.now(),
      moisture: map['moisture'] != null ? (map['moisture'] as num).toDouble() : null,
      temperature: map['temperature'] != null ? (map['temperature'] as num).toDouble() : null,
      humidity: map['humidity'] != null ? (map['humidity'] as num).toDouble() : null,
    );
  }

  factory SensorReadingModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return SensorReadingModel.fromMap({'id': doc.id, ...map});
  }
}

