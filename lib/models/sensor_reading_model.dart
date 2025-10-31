import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'sensor_reading_model.g.dart';

@HiveType(typeId: 4)
class SensorReadingModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String sensorId;
  @HiveField(2)
  final DateTime ts;
  @HiveField(3)
  final double? moisture;
  @HiveField(4)
  final double? temperature;
  @HiveField(5)
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
      'ts': ts,
      'moisture': moisture,
      'temperature': temperature,
      'humidity': humidity,
    };
  }

  factory SensorReadingModel.fromMap(Map<String, dynamic> map) {
    return SensorReadingModel(
      id: map['id'] ?? '',
      sensorId: map['sensorId'] ?? '',
      ts: map['ts'] is Timestamp
          ? (map['ts'] as Timestamp).toDate()
          : DateTime.tryParse(map['ts'].toString()) ?? DateTime.now(),
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

