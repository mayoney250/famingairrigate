import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/water_goal_provider.dart';
import '../services/water_goal_service.dart';

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
      body: goalProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: periods
                        .map((p) => ChoiceChip(
                              label: Text(p[0].toUpperCase() + p.substring(1)),
                              selected: period == p,
                              onSelected: (sel) => setState(() => period = p),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  if (activeGoal != null)
                    Card(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        title: Text('${activeGoal.goalAmount} Liters'),
                        subtitle: Text('Current ${activeGoal.period} goal'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showGoalDialog(editGoal: activeGoal);
                            } else if (value == 'remove') {
                              await goalProvider.deleteGoal(userId, activeGoal.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Goal deleted.')),);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'remove', child: Text('Delete')),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      color: Colors.amberAccent,
                      child: ListTile(
                        title: Text('No active ${period} goal'),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Set Goal"),
                          onPressed: () => _showGoalDialog(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (goals.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Goal history', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Expanded(
                            child: ListView.builder(
                              itemCount: goals.length,
                              itemBuilder: (_, idx) {
                                final g = goals[idx];
                                return ListTile(
                                  title: Text('${g.goalAmount} L'),
                                  subtitle: Text(
                                      'Set: ${g.createdAt.toLocal().toString().substring(0, 16)}'),
                                  trailing: g.active ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                ],
              ),
            ),
      floatingActionButton: activeGoal == null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.edit),
              label: const Text('Edit Goal'),
              onPressed: () => _showGoalDialog(editGoal: activeGoal),
            ),
    );
  }
  void _showGoalDialog({WaterGoal? editGoal}) {
    final controller = TextEditingController(
        text: editGoal != null ? editGoal.goalAmount.toString() : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editGoal == null ? 'Set Goal' : 'Edit Goal'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Goal (Liters)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final int? value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')));
                return;
              }
              final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';
              final goalProvider =
                  Provider.of<WaterGoalProvider>(context, listen: false);
              if (editGoal == null) {
                await goalProvider.addGoal(userId, value, period);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal set!')));
              } else {
                await goalProvider.updateGoal(userId, editGoal, value);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal updated.')));
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

<<<<<<< HEAD
=======
<<<<<<< HEAD
      body: goalProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: periods
                        .map((p) => ChoiceChip(
                              label: Text(p[0].toUpperCase() + p.substring(1)),
                              selected: period == p,
                              onSelected: (sel) => setState(() => period = p),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  if (activeGoal != null)
                    Card(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        title: Text('${activeGoal.goalAmount} Liters'),
                        subtitle: Text('Current ${activeGoal.period} goal'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showGoalDialog(editGoal: activeGoal);
                            } else if (value == 'remove') {
                              await goalProvider.deleteGoal(userId, activeGoal.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Goal deleted.')),);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'remove', child: Text('Delete')),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      color: Colors.amberAccent,
                      child: ListTile(
                        title: Text('No active ${period} goal'),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Set Goal"),
                          onPressed: () => _showGoalDialog(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (goals.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Goal history', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Expanded(
                            child: ListView.builder(
                              itemCount: goals.length,
                              itemBuilder: (_, idx) {
                                final g = goals[idx];
                                return ListTile(
                                  title: Text('${g.goalAmount} L'),
                                  subtitle: Text(
                                      'Set: ${g.createdAt.toLocal().toString().substring(0, 16)}'),
                                  trailing: g.active ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                ],
              ),
            ),
      floatingActionButton: activeGoal == null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.edit),
              label: const Text('Edit Goal'),
              onPressed: () => _showGoalDialog(editGoal: activeGoal),
            ),
    );
  }
  void _showGoalDialog({WaterGoal? editGoal}) {
    final controller = TextEditingController(
        text: editGoal != null ? editGoal.goalAmount.toString() : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editGoal == null ? 'Set Goal' : 'Edit Goal'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Goal (Liters)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final int? value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')));
                return;
              }
              final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';
              final goalProvider =
                  Provider.of<WaterGoalProvider>(context, listen: false);
              if (editGoal == null) {
                await goalProvider.addGoal(userId, value, period);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal set!')));
              } else {
                await goalProvider.updateGoal(userId, editGoal, value);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal updated.')));
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

=======
>>>>>>> main
>>>>>>> hyacinthe



























