import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/irrigation_model.dart';
import '../config/constants.dart';
import 'firestore_service.dart';

class IrrigationService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create irrigation system
  Future<IrrigationModel> createIrrigationSystem({
    required String userId,
    required String fieldId,
    required String systemName,
    required String irrigationType,
    required String waterSource,
    double? flowRate,
    String? flowRateUnit,
    bool isAutomated = false,
    required DateTime installedDate,
    double? costPerCubicMeter,
    String? currency,
    Map<String, dynamic>? schedule,
    List<String>? connectedSensors,
    String? notes,
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();

      final irrigation = IrrigationModel(
        id: id,
        userId: userId,
        fieldId: fieldId,
        systemName: systemName,
        irrigationType: irrigationType,
        waterSource: waterSource,
        flowRate: flowRate,
        flowRateUnit: flowRateUnit ?? 'L/h',
        isAutomated: isAutomated,
        isActive: true,
        installedDate: installedDate,
        totalWaterUsed: 0.0,
        costPerCubicMeter: costPerCubicMeter,
        currency: currency ?? AppConstants.rwfCurrency,
        schedule: schedule,
        connectedSensors: connectedSensors,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.createDocument(
        collection: AppConstants.irrigationCollection,
        docId: id,
        data: irrigation.toMap(),
      );

      log('Irrigation system created: $id');
      return irrigation;
    } catch (e) {
      log('Create irrigation system error: $e');
      rethrow;
    }
  }

  // Get irrigation systems by user
  Future<List<IrrigationModel>> getUserIrrigationSystems(
    String userId,
  ) async {
    try {
      final snapshot = await _firestoreService.getUserDocuments(
        collection: AppConstants.irrigationCollection,
        userId: userId,
      );

      return snapshot.docs
          .map((doc) => IrrigationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Get user irrigation systems error: $e');
      rethrow;
    }
  }

  // Get irrigation systems by field
  Future<List<IrrigationModel>> getFieldIrrigationSystems(
    String fieldId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.irrigationCollection)
          .where('fieldId', isEqualTo: fieldId)
          .get();

      return snapshot.docs
          .map((doc) => IrrigationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Get field irrigation systems error: $e');
      rethrow;
    }
  }

  // Stream irrigation systems
  Stream<List<IrrigationModel>> streamUserIrrigationSystems(
    String userId,
  ) {
    return _firestoreService
        .streamUserDocuments(
          collection: AppConstants.irrigationCollection,
          userId: userId,
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => IrrigationModel.fromFirestore(doc)).toList());
  }

  // Update irrigation system
  Future<void> updateIrrigationSystem({
    required String id,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestoreService.updateDocument(
        collection: AppConstants.irrigationCollection,
        docId: id,
        data: data ?? {},
      );
      log('Irrigation system updated: $id');
    } catch (e) {
      log('Update irrigation system error: $e');
      rethrow;
    }
  }

  // Delete irrigation system
  Future<void> deleteIrrigationSystem(String id) async {
    try {
      await _firestoreService.deleteDocument(
        collection: AppConstants.irrigationCollection,
        docId: id,
      );
      log('Irrigation system deleted: $id');
    } catch (e) {
      log('Delete irrigation system error: $e');
      rethrow;
    }
  }

  // Update water usage
  Future<void> updateWaterUsage({
    required String id,
    required double waterUsed,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.irrigationCollection)
          .doc(id)
          .update({
        'totalWaterUsed': FieldValue.increment(waterUsed),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log('Water usage updated for: $id');
    } catch (e) {
      log('Update water usage error: $e');
      rethrow;
    }
  }

  // Toggle irrigation system status
  Future<void> toggleSystemStatus(String id, bool isActive) async {
    try {
      await _firestoreService.updateDocument(
        collection: AppConstants.irrigationCollection,
        docId: id,
        data: {'isActive': isActive},
      );
      log('Irrigation system status toggled: $id');
    } catch (e) {
      log('Toggle system status error: $e');
      rethrow;
    }
  }

  // Calculate water cost
  double calculateWaterCost({
    required double waterUsed,
    required double costPerCubicMeter,
  }) {
    return waterUsed * costPerCubicMeter;
  }

  // Calculate water savings
  double calculateWaterSavings({
    required double actualUsage,
    required double traditionalUsage,
  }) {
    if (traditionalUsage == 0) return 0.0;
    return ((traditionalUsage - actualUsage) / traditionalUsage) * 100;
  }

  // Get irrigation efficiency
  Future<double?> getIrrigationEfficiency(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.irrigationCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return doc.data()?['efficiency']?.toDouble();
      }
      return null;
    } catch (e) {
      log('Get irrigation efficiency error: $e');
      rethrow;
    }
  }

  // Update irrigation schedule
  Future<void> updateSchedule({
    required String id,
    required Map<String, dynamic> schedule,
  }) async {
    try {
      await _firestoreService.updateDocument(
        collection: AppConstants.irrigationCollection,
        docId: id,
        data: {'schedule': schedule},
      );
      log('Irrigation schedule updated: $id');
    } catch (e) {
      log('Update schedule error: $e');
      rethrow;
    }
  }
}

