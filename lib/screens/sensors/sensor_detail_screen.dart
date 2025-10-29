import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/colors.dart';

class SensorDetailScreen extends StatefulWidget {
  const SensorDetailScreen({super.key});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensor = Get.arguments as Map<String, dynamic>?;
    final name = sensor?['name'] ?? 'Sensor';
    final status = (sensor?['status'] ?? 'Offline') as String;
    final isOnline = status.toLowerCase() == 'online';
    final lastSeen = sensor?['lastSeen'] ?? 'Just now';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Readings'),
            Tab(text: 'Info'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline
                      ? FamingaBrandColors.statusSuccess.withOpacity(0.1)
                      : FamingaBrandColors.statusWarning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: isOnline
                        ? FamingaBrandColors.statusSuccess
                        : FamingaBrandColors.statusWarning,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadingsTab(sensor),
          _buildInfoTab(sensor, lastSeen),
        ],
      ),
    );
  }

  Widget _buildReadingsTab(Map<String, dynamic>? sensor) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: FamingaBrandColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text(
                'Live',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: FamingaBrandColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.circle, color: FamingaBrandColors.statusSuccess, size: 10),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    'Latest reading: ${sensor?['value'] ?? '--'}   •   Updated every 5s   •   Source: device',
                    style: const TextStyle(color: FamingaBrandColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 24,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.timeline),
                title: Text('Value: ${(sensor?['value'] ?? '--')}'),
                subtitle: Text('Time: ${DateTime.now().subtract(Duration(minutes: index * 5))}'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(Map<String, dynamic>? sensor, String lastSeen) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Type'),
          subtitle: Text(sensor?['type'] ?? '--'),
        ),
        ListTile(
          leading: const Icon(Icons.place_outlined),
          title: const Text('Location'),
          subtitle: Text(sensor?['location'] ?? '--'),
        ),
        ListTile(
          leading: const Icon(Icons.bolt_outlined),
          title: const Text('Battery'),
          subtitle: Text(sensor?['battery'] ?? '--'),
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Last seen'),
          subtitle: Text(lastSeen),
        ),
      ],
    );
  }
}


