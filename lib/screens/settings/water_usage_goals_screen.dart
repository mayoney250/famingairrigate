import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/water_goal_provider.dart';
import '../../services/water_goal_service.dart';

class WaterUsageGoalsScreen extends StatefulWidget {
  const WaterUsageGoalsScreen({Key? key}) : super(key: key);

  @override
  State<WaterUsageGoalsScreen> createState() => _WaterUsageGoalsScreenState();
}

class _WaterUsageGoalsScreenState extends State<WaterUsageGoalsScreen> {
  late String userId;
  final List<String> periods = ['daily', 'weekly', 'monthly'];
  String period = 'daily';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userId = Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';
      await Provider.of<WaterGoalProvider>(context, listen: false).loadGoals(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<WaterGoalProvider>(context);
    final goals = goalProvider.goals.where((g) => g.period == period).toList();
    final activeGoal = goalProvider.activeGoal(period);
    return Scaffold(
      appBar: AppBar(title: const Text('Water Usage Goals')),
      body: const Center(child: Text('This is the Water Usage Goals page. Manage your water consumption targets here.')),
    );
  }
}





