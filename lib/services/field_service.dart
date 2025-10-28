import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/field_model.dart';

class FieldService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'fields';

  // Create new field
  Future<String?> createField(FieldModel field) async {
    try {
      print('🚀 Creating field: ${field.label} for user: ${field.userId}');
      dev.log('🚀 Creating field: ${field.label} for user: ${field.userId}');
      
      final fieldData = field.toMap();
      print('📝 Field data: $fieldData');
      dev.log('📝 Field data: $fieldData');
      
      final docRef = await _firestore.collection(_collection).add(fieldData);
      print('✅ Field created successfully! ID: ${docRef.id}');
      dev.log('✅ Field created successfully! ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ Error creating field: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Error type: ${e.runtimeType}');
      dev.log('❌ Error creating field: $e');
      dev.log('❌ Stack trace: $stackTrace');
      dev.log('❌ Error type: ${e.runtimeType}');
      return null;
    }
  }

  // Get all fields for a user
  Stream<List<FieldModel>> getUserFields(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final fields = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID
        return FieldModel.fromMap(data);
      }).toList();

      // Sort by addedDate
      fields.sort((a, b) => b.addedDate.compareTo(a.addedDate));

      return fields;
    });
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
      print('❌ Error getting field: $e');
      dev.log('Error getting field: $e');
      return null;
    }
  }

  // Update field
  Future<bool> updateField(String fieldId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(fieldId).update(data);
      print('✅ Field updated: $fieldId');
      dev.log('Field updated: $fieldId');
      return true;
    } catch (e) {
      print('❌ Error updating field: $e');
      dev.log('Error updating field: $e');
      return false;
    }
  }

  // Delete field
  Future<bool> deleteField(String fieldId) async {
    try {
      await _firestore.collection(_collection).doc(fieldId).delete();
      print('✅ Field deleted: $fieldId');
      dev.log('Field deleted: $fieldId');
      return true;
    } catch (e) {
      print('❌ Error deleting field: $e');
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
      print('✅ Field status updated: $fieldId -> $isActive');
      dev.log('Field status updated: $fieldId -> $isActive');
      return true;
    } catch (e) {
      print('❌ Error toggling field status: $e');
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
      print('❌ Error updating field moisture: $e');
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
      print('❌ Error getting total field area: $e');
      dev.log('Error getting total field area: $e');
      return 0;
    }
  }
}

