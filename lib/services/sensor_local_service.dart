import 'package:hive/hive.dart';
import '../models/sensor_model.dart';
import '../models/sensor_reading_model.dart';

class SensorLocalService {
  static Future<Box<SensorModel>> sensorsBox() async => Hive.openBox<SensorModel>('sensorsBox');
  static Future<Box<SensorReadingModel>> readingsBox() async => Hive.openBox<SensorReadingModel>('readingsBox');

  // Sensors
  static Future<void> upsertSensor(SensorModel sensor) async {
    final box = await sensorsBox();
    await box.put(sensor.id, sensor);
  }

  static Future<void> upsertSensors(List<SensorModel> sensors) async {
    final box = await sensorsBox();
    for (final s in sensors) {
      await box.put(s.id, s);
    }
  }

  static Future<List<SensorModel>> getSensorsForFarm(String farmId) async {
    final box = await sensorsBox();
    return box.values.where((s) => s.farmId == farmId).toList();
  }

  static Future<void> removeSensor(String id) async {
    final box = await sensorsBox();
    await box.delete(id);
  }

  // Readings
  static Future<void> addReading(SensorReadingModel reading) async {
    final box = await readingsBox();
    await box.put(reading.id, reading);
  }

  static Future<List<SensorReadingModel>> getRecentReadings(String sensorId, {int limit = 50}) async {
    final box = await readingsBox();
    final list = box.values.where((r) => r.sensorId == sensorId).toList()
      ..sort((a, b) => b.ts.compareTo(a.ts));
    return list.take(limit).toList();
  }
}

