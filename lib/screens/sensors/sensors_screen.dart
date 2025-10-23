import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/colors.dart';
import '../../routes/app_routes.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  int _selectedIndex = 3; // Sensors is at index 3 in bottom nav

  // Mock data - replace with real data from Firestore
  final List<Map<String, dynamic>> _sensors = [
    {
      'name': 'Soil Moisture - North',
      'type': 'Soil Moisture',
      'value': '65%',
      'status': 'Online',
      'location': 'North Field',
      'battery': '85%',
      'icon': Icons.water_drop,
    },
    {
      'name': 'Temperature - South',
      'type': 'Temperature',
      'value': '24°C',
      'status': 'Online',
      'location': 'South Field',
      'battery': '92%',
      'icon': Icons.thermostat,
    },
    {
      'name': 'Humidity - East',
      'type': 'Humidity',
      'value': '58%',
      'status': 'Online',
      'location': 'East Field',
      'battery': '76%',
      'icon': Icons.cloud,
    },
    {
      'name': 'Soil pH - West',
      'type': 'Soil pH',
      'value': '6.8',
      'status': 'Offline',
      'location': 'West Field',
      'battery': '15%',
      'icon': Icons.science,
    },
    {
      'name': 'Light - Central',
      'type': 'Light Intensity',
      'value': '850 lux',
      'status': 'Online',
      'location': 'Central Field',
      'battery': '88%',
      'icon': Icons.wb_sunny,
    },
    {
      'name': 'Soil Moisture - East',
      'type': 'Soil Moisture',
      'value': '72%',
      'status': 'Online',
      'location': 'East Field',
      'battery': '90%',
      'icon': Icons.water_drop,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final onlineSensors = _sensors.where((s) => s['status'] == 'Online').length;
    final offlineSensors = _sensors.where((s) => s['status'] == 'Offline').length;

    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Sensors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Get.snackbar(
                'Refreshing',
                'Updating sensor data...',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          Container(
            padding: const EdgeInsets.all(16),
            color: FamingaBrandColors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Online',
                    onlineSensors.toString(),
                    FamingaBrandColors.statusSuccess,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Offline',
                    offlineSensors.toString(),
                    FamingaBrandColors.statusWarning,
                    Icons.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    _sensors.length.toString(),
                    FamingaBrandColors.primaryOrange,
                    Icons.sensors,
                  ),
                ),
              ],
            ),
          ),

          // Sensors list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sensors.length,
              itemBuilder: (context, index) {
                final sensor = _sensors[index];
                return _buildSensorCard(sensor);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.snackbar(
            'Add Sensor',
            'Sensor pairing screen coming soon!',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        backgroundColor: FamingaBrandColors.primaryOrange,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(Map<String, dynamic> sensor) {
    final bool isOnline = sensor['status'] == 'Online';
    final int battery = int.parse(sensor['battery'].replaceAll('%', ''));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Get.snackbar(
            'Sensor Details',
            'Viewing ${sensor['name']} details',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      sensor['icon'],
                      color: FamingaBrandColors.iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensor['name'],
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sensor['location'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: FamingaBrandColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? FamingaBrandColors.statusSuccess.withOpacity(0.1)
                          : FamingaBrandColors.statusWarning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sensor['status'],
                      style: TextStyle(
                        color: isOnline
                            ? FamingaBrandColors.statusSuccess
                            : FamingaBrandColors.statusWarning,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(Icons.analytics, 'Current Value', sensor['value']),
                  _buildInfoItem(
                    Icons.battery_std,
                    'Battery',
                    sensor['battery'],
                    batteryLevel: battery,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {int? batteryLevel}) {
    Color iconColor = FamingaBrandColors.iconColor;
    
    if (batteryLevel != null) {
      if (batteryLevel < 20) {
        iconColor = FamingaBrandColors.statusWarning;
      } else if (batteryLevel < 50) {
        iconColor = FamingaBrandColors.primaryOrange;
      } else {
        iconColor = FamingaBrandColors.statusSuccess;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: FamingaBrandColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (index == _selectedIndex) return;

        setState(() => _selectedIndex = index);

        switch (index) {
          case 0:
            Get.offAllNamed(AppRoutes.dashboard);
            break;
          case 1:
            Get.offAllNamed(AppRoutes.irrigationList);
            break;
          case 2:
            Get.offAllNamed(AppRoutes.fields);
            break;
          case 3:
            // Already on Sensors
            break;
          case 4:
            Get.offAllNamed(AppRoutes.profile);
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: FamingaBrandColors.primaryOrange,
      unselectedItemColor: FamingaBrandColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop),
          label: 'Irrigation',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.landscape),
          label: 'Fields',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sensors),
          label: 'Sensors',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

