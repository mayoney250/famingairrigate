import 'package:hive/hive.dart';
import '../models/user_model.dart';

class UserLocalService {
  static Future<Box<UserModel>> userBox() async => Hive.openBox<UserModel>('userBox');

  static Future<void> saveUser(UserModel user) async {
    final box = await userBox();
    await box.put(user.userId, user);
  }

  static Future<UserModel?> getUser(String userId) async {
    final box = await userBox();
    return box.get(userId);
  }

  static Future<void> clear() async {
    final box = await userBox();
    await box.clear();
  }
}
