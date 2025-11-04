import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flow_meter_model.dart';

class FlowMeterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Use permitted collection per current security rules
  final String _collection = 'irrigationLogs';

  Future<String> createReading(FlowMeterModel reading, {String? userId}) async {
    // Store as an irrigation log entry tagged as flow
    final col = _firestore.collection(_collection);
    final payload = {
      ...reading.toMap(),
      'type': 'flow',
    };
    final docRef = await col.add(payload);
    return docRef.id;
  }

  Future<FlowMeterModel?> getLatestReading(String fieldId, {String? userId}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('type', isEqualTo: 'flow')
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
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: 'flow')
        .where('fieldId', isEqualTo: fieldId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isNotEmpty ? FlowMeterModel.fromFirestore(s.docs.first) : null);
  }

  Future<double> getUsageSince(String fieldId, DateTime start, {String? userId}) async {
    final snap = await _firestore
        .collection(_collection)
        .where('type', isEqualTo: 'flow')
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
