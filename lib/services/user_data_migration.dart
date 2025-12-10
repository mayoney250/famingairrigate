import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

/// One-time migration script to populate fieldIds and sensorIds arrays
/// in existing user documents based on their current fields and sensors.
/// 
/// USAGE:
/// 1. Import this file in your app
/// 2. Call `await migrateUserFieldsAndSensors()` once from a debug screen or main.dart
/// 3. Remove the call after migration is complete
class UserDataMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate all users' fieldIds and sensorIds
  static Future<void> migrateAllUsers() async {
    try {
      dev.log('🔄 Starting user data migration...');
      
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      dev.log('📊 Found ${usersSnapshot.docs.length} users to migrate');

      int successCount = 0;
      int errorCount = 0;

      for (final userDoc in usersSnapshot.docs) {
        try {
          await _migrateSingleUser(userDoc.id);
          successCount++;
        } catch (e) {
          dev.log('❌ Error migrating user ${userDoc.id}: $e');
          errorCount++;
        }
      }

      dev.log('✅ Migration complete! Success: $successCount, Errors: $errorCount');
    } catch (e) {
      dev.log('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Migrate a single user's fieldIds and sensorIds
  static Future<void> _migrateSingleUser(String userId) async {
    dev.log('🔄 Migrating user: $userId');

    // Get all fields for this user
    final fieldsSnapshot = await _firestore
        .collection('fields')
        .where('userId', isEqualTo: userId)
        .get();

    final fieldIds = fieldsSnapshot.docs.map((doc) => doc.id).toList();
    dev.log('  📍 Found ${fieldIds.length} fields');

    // Get all sensors for this user's fields
    final sensorIds = <String>[];
    for (final fieldId in fieldIds) {
      final sensorsSnapshot = await _firestore
          .collection('sensors')
          .where('farmId', isEqualTo: fieldId)
          .get();
      
      sensorIds.addAll(sensorsSnapshot.docs.map((doc) => doc.id));
    }
    dev.log('  📡 Found ${sensorIds.length} sensors');

    // Update user document
    await _firestore.collection('users').doc(userId).update({
      'fieldIds': fieldIds,
      'sensorIds': sensorIds,
    });

    dev.log('  ✅ Updated user $userId with ${fieldIds.length} fieldIds and ${sensorIds.length} sensorIds');
  }

  /// Migrate a specific user (useful for testing)
  static Future<void> migrateSingleUser(String userId) async {
    try {
      await _migrateSingleUser(userId);
      dev.log('✅ Successfully migrated user: $userId');
    } catch (e) {
      dev.log('❌ Failed to migrate user $userId: $e');
      rethrow;
    }
  }

  /// Verify migration for a specific user
  static Future<void> verifyUserMigration(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      if (userData == null) {
        dev.log('❌ User $userId not found');
        return;
      }

      final fieldIds = userData['fieldIds'] as List<dynamic>?;
      final sensorIds = userData['sensorIds'] as List<dynamic>?;

      dev.log('📊 User $userId migration status:');
      dev.log('  fieldIds: ${fieldIds?.length ?? 0} items');
      dev.log('  sensorIds: ${sensorIds?.length ?? 0} items');
      
      if (fieldIds != null) {
        dev.log('  Fields: $fieldIds');
      }
      if (sensorIds != null) {
        dev.log('  Sensors: $sensorIds');
      }
    } catch (e) {
      dev.log('❌ Error verifying user $userId: $e');
    }
  }
}
