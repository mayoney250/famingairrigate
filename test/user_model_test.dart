import 'package:flutter_test/flutter_test.dart';
import 'package:faminga_irrigation/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should support new fields: fieldId and sensorId', () {
      final user = UserModel(
        userId: 'user1',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        createdAt: DateTime.now(),
        fieldId: 'field1',
        sensorId: 'sensor1',
      );

      expect(user.fieldId, 'field1');
      expect(user.sensorId, 'sensor1');
      expect(user.fields, null);
      expect(user.sensors, null);
    });

    test('should serialize and deserialize with new fields', () {
      final now = DateTime.now();
      final user = UserModel(
        userId: 'user1',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        createdAt: now,
        fieldId: 'field1',
        sensorId: 'sensor1',
      );

      final map = user.toMap();
      expect(map['fieldId'], 'field1');
      expect(map['sensorId'], 'sensor1');
      expect(map['fields'], null);
      expect(map['sensors'], null);
    });
  });
}
