import 'package:hive_flutter/hive_flutter.dart';
import '../models/alert_model.dart';
import '../models/sensor_model.dart';
import '../models/sensor_reading_model.dart';
import '../models/user_model.dart';
import 'app_initializer.dart';

class HiveService {
  static final Map<String, Box> _openBoxes = {};
  
  static Future<Box<AlertModel>> getAlertsBox() async {
    await AppInitializer.initializeHive();
    if (_openBoxes.containsKey('alertsBox')) {
      return _openBoxes['alertsBox'] as Box<AlertModel>;
    }
    final box = await Hive.openBox<AlertModel>('alertsBox');
    _openBoxes['alertsBox'] = box;
    return box;
  }
  
  static Future<Box<SensorModel>> getSensorsBox() async {
    await AppInitializer.initializeHive();
    if (_openBoxes.containsKey('sensorsBox')) {
      return _openBoxes['sensorsBox'] as Box<SensorModel>;
    }
    final box = await Hive.openBox<SensorModel>('sensorsBox');
    _openBoxes['sensorsBox'] = box;
    return box;
  }
  
  static Future<Box<SensorReadingModel>> getReadingsBox() async {
    await AppInitializer.initializeHive();
    if (_openBoxes.containsKey('readingsBox')) {
      return _openBoxes['readingsBox'] as Box<SensorReadingModel>;
    }
    final box = await Hive.openBox<SensorReadingModel>('readingsBox');
    _openBoxes['readingsBox'] = box;
    return box;
  }
  
  static Future<Box<UserModel>> getUserBox() async {
    await AppInitializer.initializeHive();
    if (_openBoxes.containsKey('userBox')) {
      return _openBoxes['userBox'] as Box<UserModel>;
    }
    final box = await Hive.openBox<UserModel>('userBox');
    _openBoxes['userBox'] = box;
    return box;
  }

  static Future<void> preloadAllBoxes() async {
    await Future.wait([
      getAlertsBox(),
      getSensorsBox(),
      getReadingsBox(),
      getUserBox(),
    ]);
  }
}
