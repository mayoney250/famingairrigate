import 'package:hive/hive.dart';
import '../models/alert_model.dart';

class AlertLocalService {
  static Future<Box<AlertModel>> getBox() async => Hive.openBox<AlertModel>('alertsBox');

  static Future<void> addAlert(AlertModel a) async {
    final box = await getBox();
    await box.put(a.id, a);
  }

  static Future<List<AlertModel>> getAlerts() async {
    final box = await getBox();
    return box.values.toList();
  }

  static Future<List<AlertModel>> getUnreadAlerts() async {
    final alerts = await getAlerts();
    return alerts.where((a) => !a.read).toList();
  }

  static Future<void> markRead(String id) async {
    final box = await getBox();
    final alert = box.get(id);
    if (alert != null) {
      final updated = AlertModel(
        id: alert.id,
        farmId: alert.farmId,
        sensorId: alert.sensorId,
        type: alert.type,
        message: alert.message,
        severity: alert.severity,
        ts: alert.ts,
        read: true,
      );
      await box.put(id, updated);
    }
  }

  static Future<void> removeAlert(String id) async {
    final box = await getBox();
    await box.delete(id);
  }

  static Future<void> clearAll() async {
    final box = await getBox();
    await box.clear();
  }
}
