import 'package:cloud_firestore/cloud_firestore.dart';

class WaterGoal {
  final String id;
  final int goalAmount;
  final String period;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  WaterGoal({
    required this.id,
    required this.goalAmount,
    required this.period,
    required this.createdAt,
    required this.updatedAt,
    required this.active,
  });
  Map<String, dynamic> toMap() => {
    'goalAmount': goalAmount,
    'period': period,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'active': active,
  };
  factory WaterGoal.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WaterGoal(
      id: doc.id,
      goalAmount: data['goalAmount'],
      period: data['period'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      active: data['active'] ?? false,
    );
  }
}

class WaterGoalService {
  CollectionReference _goalRef(String userId) =>
      FirebaseFirestore.instance.collection('users').doc(userId).collection('waterGoals');

  Future<List<WaterGoal>> fetchGoals(String userId) async {
    final snapshot = await _goalRef(userId).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(WaterGoal.fromDoc).toList();
  }

  Future<WaterGoal?> fetchActiveGoal(String userId, String period) async {
    final query = await _goalRef(userId)
        .where('active', isEqualTo: true)
        .where('period', isEqualTo: period)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return WaterGoal.fromDoc(query.docs.first);
    return null;
  }

  Future<WaterGoal> addGoal(String userId, int goalAmount, String period) async {
    final now = DateTime.now();
    final newGoal = {
      'goalAmount': goalAmount,
      'period': period,
      'createdAt': now,
      'updatedAt': now,
      'active': true,
    };
    final batch = FirebaseFirestore.instance.batch();
    final ref = _goalRef(userId);
    final previous = await ref.where('active', isEqualTo: true).where('period', isEqualTo: period).get();
    for (final doc in previous.docs) {
      batch.update(doc.reference, {'active': false});
    }
    final docRef = ref.doc();
    batch.set(docRef, newGoal);
    await batch.commit();
    final saved = await docRef.get();
    return WaterGoal.fromDoc(saved);
  }

  Future<void> updateGoal(String userId, WaterGoal goal, int newAmount) async {
    final now = DateTime.now();
    await _goalRef(userId).doc(goal.id).update({
      'goalAmount': newAmount,
      'updatedAt': now,
    });
  }

  Future<void> deleteGoal(String userId, String goalId) async {
    await _goalRef(userId).doc(goalId).delete();
  }
}



















