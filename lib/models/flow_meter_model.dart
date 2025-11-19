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

  factory FlowMeterModel.fromMap(Map<String, dynamic> map) => FlowMeterModel(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        fieldId: map['fieldId'] ?? '',
        liters: (map['liters'] ?? 0.0).toDouble(),
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory FlowMeterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlowMeterModel.fromMap({...data, 'id': doc.id});
  }
}

