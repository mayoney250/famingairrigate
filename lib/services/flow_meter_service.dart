import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flow_meter_model.dart';

class FlowMeterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'flow_meter';
  CollectionReference<Map<String, dynamic>> _userScoped(String userId) =>
      _firestore.collection('users').doc(userId).collection(_collection);

  Future<String> createReading(FlowMeterModel reading, {String? userId}) async {
    final col = userId != null ? _userScoped(userId) : _firestore.collection(_collection);
    final docRef = await col.add(reading.toMap());
    return docRef.id;
  }

  Future<FlowMeterModel?> getLatestReading(String fieldId, {String? userId}) async {
    // Try user-scoped first if provided
    if (userId != null) {
      final userSnap = await _userScoped(userId)
          .where('fieldId', isEqualTo: fieldId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (userSnap.docs.isNotEmpty) {
        return FlowMeterModel.fromFirestore(userSnap.docs.first);
      }
    }
    final snapshot = await _firestore
        .collection(_collection)
        .where('fieldId', isEqualTo: fieldId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return FlowMeterModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Stream<FlowMeterModel?> streamLatestReading(String fieldId, {String? userId}) {
    final topStream = _firestore
        .collection(_collection)
        .where('fieldId', isEqualTo: fieldId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isNotEmpty ? FlowMeterModel.fromFirestore(s.docs.first) : null);

    if (userId == null) return topStream;

    final userStream = _userScoped(userId)
        .where('fieldId', isEqualTo: fieldId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isNotEmpty ? FlowMeterModel.fromFirestore(s.docs.first) : null);

    // Prefer user-scoped event if present; otherwise fall back to top-level
    return userStream.asyncMap((u) async {
      if (u != null) return u;
      return await topStream.first;
    });
  }

  Future<double> getUsageSince(String fieldId, DateTime start, {String? userId}) async {
    // Try user-scoped first if provided
    if (userId != null) {
      final userSnap = await _userScoped(userId)
          .where('fieldId', isEqualTo: fieldId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();
      if (userSnap.docs.isNotEmpty) {
        double tot = 0;
        for (final d in userSnap.docs) {
          final data = d.data();
          final liters = data['liters'];
          if (liters != null) tot += (liters as num).toDouble();
        }
        return tot;
      }
    }
    final snap = await _firestore
        .collection(_collection)
        .where('fieldId', isEqualTo: fieldId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();
    double total = 0;
    for (final d in snap.docs) {
      final data = d.data();
      final liters = data['liters'];
      if (liters != null) total += (liters as num).toDouble();
    }
    return total;
  }
}
