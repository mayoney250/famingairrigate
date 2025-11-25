import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic create method
  Future<void> createDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data);
      log('Document created in $collection: $docId');
    } catch (e) {
      log('Create document error: $e');
      rethrow;
    }
  }

  // Generic read method
  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      log('Get document error: $e');
      rethrow;
    }
  }

  // Generic update method
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(collection).doc(docId).update(data);
      log('Document updated in $collection: $docId');
    } catch (e) {
      log('Update document error: $e');
      rethrow;
    }
  }

  // Generic delete method
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      log('Document deleted from $collection: $docId');
    } catch (e) {
      log('Delete document error: $e');
      rethrow;
    }
  }

  // Query documents by user ID
  Future<QuerySnapshot> getUserDocuments({
    required String collection,
    required String userId,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      log('Get user documents error: $e');
      rethrow;
    }
  }

  // Stream of user documents
  Stream<QuerySnapshot> streamUserDocuments({
    required String collection,
    required String userId,
  }) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Paginated query
  Future<QuerySnapshot> getPaginatedDocuments({
    required String collection,
    required String userId,
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      return await query.get();
    } catch (e) {
      log('Get paginated documents error: $e');
      rethrow;
    }
  }

  // Batch write
  Future<void> batchWrite(
    List<Map<String, dynamic>> operations,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final docRef = _firestore
            .collection(operation['collection'])
            .doc(operation['docId']);

        switch (operation['type']) {
          case 'set':
            batch.set(docRef, operation['data']);
            break;
          case 'update':
            batch.update(docRef, operation['data']);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
      log('Batch write completed successfully');
    } catch (e) {
      log('Batch write error: $e');
      rethrow;
    }
  }

  // Count documents
  Future<int> countDocuments({
    required String collection,
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      log('Count documents error: $e');
      rethrow;
    }
  }
}

