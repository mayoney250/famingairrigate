import 'package:flutter/material.dart';
import '../services/water_goal_service.dart';

class WaterGoalProvider with ChangeNotifier {
  final WaterGoalService _service = WaterGoalService();
  List<WaterGoal> _goals = [];
  bool _isLoading = false;
  List<WaterGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  WaterGoal? activeGoal(String period) {
    for (final goal in _goals) {
      if (goal.active && goal.period == period) {
        return goal;
      }
    }
    return null;
  }
  Future<void> loadGoals(String userId) async {
    _isLoading = true;
    notifyListeners();
    _goals = await _service.fetchGoals(userId);
    _isLoading = false;
    notifyListeners();
  }
  Future<void> addGoal(String userId, int amount, String period) async {
    final goal = await _service.addGoal(userId, amount, period);
    _goals.removeWhere((g) => g.period == period);
    _goals.insert(0, goal);
    notifyListeners();
  }
  Future<void> updateGoal(String userId, WaterGoal goal, int newAmount) async {
    await _service.updateGoal(userId, goal, newAmount);
    await loadGoals(userId);
  }
  Future<void> deleteGoal(String userId, String goalId) async {
    await _service.deleteGoal(userId, goalId);
    _goals.removeWhere((g) => g.id == goalId);
    notifyListeners();
  }
}










