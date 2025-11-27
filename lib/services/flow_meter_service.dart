import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flow_meter_model.dart';

class FlowMeterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'irrigationLogs';

  Future<String> createReading(FlowMeterModel reading, {String? userId}) async {
    final payload = {
      'userId': reading.userId,
      'fieldId': reading.fieldId,
      'zoneId': reading.fieldId,
      'waterUsed': reading.liters,
      'liters': reading.liters,
      'timestamp': Timestamp.fromDate(reading.timestamp),
      'source': 'app',
      'type': 'flow',
    };
    final docRef = await _firestore.collection(_collection).add(payload);
    return docRef.id;
  }

  Query<Map<String, dynamic>> _baseQuery(String userId, String fieldId) {
    return _firestore.collection(_collection).where(
          Filter.and(
            Filter('userId', isEqualTo: userId),
            Filter.or(
              Filter('fieldId', isEqualTo: fieldId),
              Filter('zoneId', isEqualTo: fieldId),
            ),
          ),
        );
  }

  bool _isValidWaterLog(Map<String, dynamic> data, String userId, String fieldId) {
    final logUserId = (data['userId'] ?? '').toString();
    final logFieldId = (data['fieldId'] ?? data['zoneId'] ?? '').toString();
    final waterValue = data['waterUsed'] ?? data['liters'];
    if (logUserId != userId) {
      return false;
    }
    if (logFieldId != fieldId) {
      return false;
    }
    if (waterValue == null) {
      return false;
    }
    return true;
  }

  FlowMeterModel? _docToModel(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
    String fieldId,
  ) {
    final data = doc.data();
    if (data == null) return null;
    if (!_isValidWaterLog(data, userId, fieldId)) return null;
    return FlowMeterModel.fromFirestore(doc);
  }

  Future<FlowMeterModel?> getLatestReading(String fieldId, {required String userId}) async {
    final snapshot = await _baseQuery(userId, fieldId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return _docToModel(snapshot.docs.first, userId, fieldId);
  }

  Stream<FlowMeterModel?> streamLatestReading(String fieldId, {required String userId}) async* {
    final query = _baseQuery(userId, fieldId)
        .orderBy('timestamp', descending: true)
        .limit(1);
    yield* query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return _docToModel(snapshot.docs.first, userId, fieldId);
    });
  }

  Future<double> getUsageSince(String fieldId, DateTime start, {required String userId}) async {
    final snapshot = await _baseQuery(userId, fieldId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('timestamp', descending: true)
        .get();
    double total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!_isValidWaterLog(data, userId, fieldId)) continue;
      final waterUsed = (data['waterUsed'] ?? data['liters']) as num?;
      if (waterUsed != null) {
        total += waterUsed.toDouble();
      }
    }
    return total;
  }
}
