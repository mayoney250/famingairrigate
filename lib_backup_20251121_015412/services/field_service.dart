import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
=======
import 'cache_repository.dart';
import 'offline_sync_service.dart';
>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4
import '../models/field_model.dart';

class FieldService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'fields';

  // Create new field
  Future<String?> createField(FieldModel field) async {
<<<<<<< HEAD
=======
    final cache = CacheRepository();
    final sync = OfflineSyncService();

>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4
    try {
      final fieldData = field.toMap();
      final docRef = await _firestore.collection(_collection).add(fieldData);
      dev.log('Field created: ${docRef.id}');
<<<<<<< HEAD
      return docRef.id;
    } catch (e) {
      dev.log('Error creating field: $e');
      return null;
=======

      // Update cached list for user
      final cacheKey = 'fields_user_${field.userId}';
      final cached = cache.getCachedList(cacheKey);
      final fresh = [...cached, {...fieldData, 'id': docRef.id}];
      await cache.cacheJsonList(cacheKey, fresh);

      return docRef.id;
    } catch (e) {
      dev.log('Error creating field (offline?): $e');

      // Offline path: assign a local id and cache immediately, enqueue for sync
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final map = {...field.toMap(), 'id': localId};

      final cacheKey = 'fields_user_${field.userId}';
      final cached = cache.getCachedList(cacheKey);
      final updated = [map, ...cached];
      await cache.cacheJsonList(cacheKey, updated);

      // Enqueue for background creation
      await sync.enqueueOperation(collection: _collection, operation: 'create', data: map, userId: field.userId);

      return localId;
>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4
    }
  }

  // Get all fields for a user
<<<<<<< HEAD
  Stream<List<FieldModel>> getUserFields(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
=======
  Stream<List<FieldModel>> getUserFields(String userId) async* {
    // Use read-through cache: yield cached value first, then stream live updates
    final cache = CacheRepository();

    // yield cached list if available
    final cacheKey = 'fields_user_$userId';
    final cached = cache.getCachedList(cacheKey);
    if (cached.isNotEmpty) {
      final models = cached.map((m) => FieldModel.fromMap(m..['id'] = m['id'] ?? '')).toList();
      models.sort((a, b) {
        final aDt = DateTime.tryParse(a.addedDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDt = DateTime.tryParse(b.addedDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDt.compareTo(aDt);
      });
      yield models;
    }

    // then yield live updates and refresh cache
    await for (final snapshot in _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()) {
>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4
      final fields = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID
        return FieldModel.fromMap(data);
      }).toList();

<<<<<<< HEAD
      // Sort by addedDate
      fields.sort((a, b) => b.addedDate.compareTo(a.addedDate));

      return fields;
    });
=======
      // Sort by addedDate (parse ISO strings defensively)
      fields.sort((a, b) {
        final aDt = DateTime.tryParse(a.addedDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDt = DateTime.tryParse(b.addedDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDt.compareTo(aDt);
      });

      // cache the list as JSON
      final listMaps = fields.map((f) => f.toMap()).toList();
      await cache.cacheJsonList(cacheKey, listMaps);

      yield fields;
    }
>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4
  }

  // Get single field
  Future<FieldModel?> getField(String fieldId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(fieldId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return FieldModel.fromMap(data);
      }
      return null;
    } catch (e) {
      dev.log('Error getting field: $e');
      return null;
    }
  }

  // Update field
  Future<bool> updateField(String fieldId, Map<String, dynamic> data) async {
<<<<<<< HEAD
    try {
      await _firestore.collection(_collection).doc(fieldId).update(data);
      dev.log('Field updated: $fieldId');
      return true;
    } catch (e) {
      dev.log('Error updating field: $e');
      return false;
=======
    final cache = CacheRepository();
    final sync = OfflineSyncService();

    try {
      await _firestore.collection(_collection).doc(fieldId).update(data);
      dev.log('Field updated: $fieldId');

      // Update cache entry if present
      try {
        // Attempt to find userId from cache entries (cheap but works)
        // We'll scan cached lists for a match and update in-place
        // NOTE: this is best-effort; if not found we skip cache update
        final userId = data['userId'] as String?;
        if (userId != null) {
          final cacheKey = 'fields_user_$userId';
          final cached = cache.getCachedList(cacheKey);
          final updated = cached.map((m) {
            if ((m['id'] ?? '') == fieldId) return {...m, ...data};
            return m;
          }).toList();
          await cache.cacheJsonList(cacheKey, updated);
        }
      } catch (_) {}

      return true;
    } catch (e) {
      dev.log('Error updating field (offline?): $e');

      // Offline: update cache and enqueue update
      try {
        final userId = data['userId'] as String?;
        if (userId != null) {
          final cacheKey = 'fields_user_$userId';
          final cached = cache.getCachedList(cacheKey);
          final updated = cached.map((m) {
            if ((m['id'] ?? '') == fieldId) return {...m, ...data};
            return m;
          }).toList();
          await cache.cacheJsonList(cacheKey, updated);
        }
      } catch (_) {}

      // Enqueue for background update
      await sync.enqueueOperation(collection: _collection, operation: 'update', data: {...data, 'id': fieldId});
      return true;
>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4
    }
  }

  // Delete field
  Future<bool> deleteField(String fieldId) async {
    try {
      await _firestore.collection(_collection).doc(fieldId).delete();
      dev.log('Field deleted: $fieldId');
      return true;
    } catch (e) {
      dev.log('Error deleting field: $e');
      return false;
    }
  }

  // Toggle field active status
  Future<bool> toggleFieldStatus(String fieldId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(fieldId).update({
        'isActive': isActive,
      });
      dev.log('Field status updated: $fieldId -> $isActive');
      return true;
    } catch (e) {
      dev.log('Error toggling field status: $e');
      return false;
    }
  }

  // Update field moisture (from sensors)
  Future<bool> updateFieldMoisture(String fieldId, double moisture) async {
    try {
      await _firestore.collection(_collection).doc(fieldId).update({
        'moisture': moisture,
      });
      return true;
    } catch (e) {
      dev.log('Error updating field moisture: $e');
      return false;
    }
  }

  // Get total area of user's fields
  Future<double> getTotalFieldArea(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      double totalArea = 0;
      for (var doc in snapshot.docs) {
        final size = doc.data()['size'];
        if (size != null) {
          totalArea += (size as num).toDouble();
        }
      }

      return totalArea;
    } catch (e) {
      dev.log('Error getting total field area: $e');
      return 0;
    }
  }
}

