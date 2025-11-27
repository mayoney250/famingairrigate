import 'package:cloud_firestore/cloud_firestore.dart';

class FlowMeterModel {
  final String id;
  final String userId;
  final String fieldId;
  final double liters;
  final DateTime timestamp;

  FlowMeterModel({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.liters,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'fieldId': fieldId,
        'liters': liters,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory FlowMeterModel.fromMap(Map<String, dynamic> map) {
    final resolvedFieldId = (map['fieldId'] ?? map['zoneId'] ?? '').toString();
    final litersValue = map['liters'] ?? map['waterUsed'] ?? map['usage'] ?? 0.0;
    final tsRaw = map['timestamp'];
    DateTime resolvedTimestamp;
    if (tsRaw is Timestamp) {
      resolvedTimestamp = tsRaw.toDate();
    } else if (tsRaw is DateTime) {
      resolvedTimestamp = tsRaw;
    } else if (tsRaw is num) {
      resolvedTimestamp = DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt());
    } else if (tsRaw is String) {
      resolvedTimestamp = DateTime.tryParse(tsRaw) ?? DateTime.now();
    } else {
      resolvedTimestamp = DateTime.now();
    }

    return FlowMeterModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fieldId: resolvedFieldId,
      liters: (litersValue as num?)?.toDouble() ?? 0.0,
      timestamp: resolvedTimestamp,
    );
  }

  factory FlowMeterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlowMeterModel.fromMap({...data, 'id': doc.id});
  }
}

