import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/colors.dart';
import '../../routes/app_routes.dart';
import '../../services/sensor_service.dart';
import '../../models/sensor_model.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  int _selectedIndex = 3; // Sensors is at index 3 in bottom nav
  final SensorService _sensorService = SensorService();
  List<SensorModel> _sensors = [];

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  Future<void> _loadSensors() async {
    // TODO: Replace with actual logic to retrieve user's farmId
    const String farmId = 'demoFarmId';
    final sensors = await _sensorService.getSensorsForFarm(farmId);
    setState(() => _sensors = sensors);
  }

  void _showAddSensorDialog() {
    final _formKey = GlobalKey<FormState>();
    String displayName = '';
    String type = 'soil';
    String hardwareId = '';
    String pairingMethod = 'BLE';
    String bleMac = '';
    String bleNote = '';
    String wifiSsid = '';
    String wifiPassword = '';
    String loraGateway = '';
    String loraNetworkId = '';
    String loraChannel = '';
    String assignedZoneId = '';
    String installNote = '';
    double? battery;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Register New Sensor'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold)),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Sensor Name (Label)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onChanged: (v) => displayName = v,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Sensor Type'),
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'soil', child: Text('Soil Moisture')),
                    DropdownMenuItem(value: 'temperature', child: Text('Temperature')),
                    DropdownMenuItem(value: 'humidity', child: Text('Humidity')),
                    DropdownMenuItem(value: 'ph', child: Text('Soil pH')),
                    DropdownMenuItem(value: 'light', child: Text('Light Intensity')),
                    DropdownMenuItem(value: 'airTemp', child: Text('Ambient Temp')),
                  ],
                  onChanged: (v) => type = v ?? 'soil',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Hardware ID (Serial/MAC)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onChanged: (v) => hardwareId = v,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Pairing Method'),
                  value: pairingMethod,
                  items: const [
                    DropdownMenuItem(value: 'BLE', child: Text('Bluetooth (BLE)')),
                    DropdownMenuItem(value: 'WiFi', child: Text('WiFi')),
                    DropdownMenuItem(value: 'LoRaWAN', child: Text('LoRaWAN Gateway')),
                  ],
                  onChanged: (v) => pairingMethod = v!,
                ),
                if (pairingMethod == 'BLE') ...[
                  const SizedBox(height: 8),
                  const Text('Bluetooth Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'BLE MAC Address'),
                    validator: (v) => pairingMethod == 'BLE' && (v == null || v.isEmpty) ? 'Required' : null,
                    onChanged: (v) => bleMac = v,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Pairing Note/Code (Optional)'),
                    onChanged: (v) => bleNote = v,
                  ),
                ],
                if (pairingMethod == 'WiFi') ...[
                  const SizedBox(height: 8),
                  const Text('WiFi Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'WiFi SSID'),
                    validator: (v) => pairingMethod == 'WiFi' && (v == null || v.isEmpty) ? 'Required' : null,
                    onChanged: (v) => wifiSsid = v,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'WiFi Password (Optional)'),
                    onChanged: (v) => wifiPassword = v,
                  ),
                ],
                if (pairingMethod == 'LoRaWAN') ...[
                  const SizedBox(height: 8),
                  const Text('LoRaWAN Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Gateway Name/ID'),
                    validator: (v) => pairingMethod == 'LoRaWAN' && (v == null || v.isEmpty) ? 'Required' : null,
                    onChanged: (v) => loraGateway = v,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Network ID'),
                    onChanged: (v) => loraNetworkId = v,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Channel'),
                    onChanged: (v) => loraChannel = v,
                  ),
                ],
                const SizedBox(height: 8),
                const Text('Other Details', style: TextStyle(fontWeight: FontWeight.bold)),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Field/Zone Assignment (Optional)'),
                  onChanged: (v) => assignedZoneId = v,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Installation Note (Optional)'),
                  onChanged: (v) => installNote = v,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Battery (%)', helperText: 'Leave blank if not known'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => battery = double.tryParse(v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                const String farmId = 'demoFarmId'; // Replace with actual logic
                Map<String, dynamic> pairingMeta = {};
                if (pairingMethod == 'BLE') {
                  pairingMeta = {
                    'mac': bleMac,
                    if (bleNote.isNotEmpty) 'note': bleNote,
                  };
                } else if (pairingMethod == 'WiFi') {
                  pairingMeta = {
                    'ssid': wifiSsid,
                    if (wifiPassword.isNotEmpty) 'password': wifiPassword,
                  };
                } else if (pairingMethod == 'LoRaWAN') {
                  pairingMeta = {
                    'gateway': loraGateway,
                    if (loraNetworkId.isNotEmpty) 'networkId': loraNetworkId,
                    if (loraChannel.isNotEmpty) 'channel': loraChannel,
                  };
                }
                final SensorModel sensor = SensorModel(
                  id: '',
                  farmId: farmId,
                  displayName: displayName,
                  type: type,
                  hardwareId: hardwareId,
                  pairing: {'method': pairingMethod, 'meta': pairingMeta},
                  status: 'pending activation',
                  lastSeenAt: null,
                  assignedZoneId: assignedZoneId.isNotEmpty ? assignedZoneId : null,
                  battery: battery,
                  installNote: installNote.isNotEmpty ? installNote : null,
                );
                await _sensorService.createSensor(sensor);
                Navigator.pop(context);
                await _loadSensors();
              }
            },
            child: const Text('Add Sensor'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onlineSensors = _sensors.where((s) => s.status.toLowerCase() == 'online').length;
    final offlineSensors = _sensors.where((s) => s.status.toLowerCase() == 'offline').length;

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
          _showAddSensorDialog();
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

  Widget _buildSensorCard(SensorModel sensor) {
    final bool isOnline = sensor.status.toLowerCase() == 'online';
    final title = sensor.displayName?.isNotEmpty == true
        ? sensor.displayName!
        : sensor.hardwareId;
    final subtitle = sensor.type;
    final lastSeenText = sensor.lastSeenAt != null
        ? 'Last seen: ' + sensor.lastSeenAt!.toLocal().toString().substring(0, 19)
        : 'Never online';
    // Choose an icon based on sensor type (optional)
    final iconData = Icons.sensors;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Get.snackbar(
            'Sensor Details',
            'Viewing details for $title',
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
                      iconData,
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
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall?.copyWith(
                                color: FamingaBrandColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastSeenText,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall?.copyWith(
                                color: FamingaBrandColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? FamingaBrandColors.statusSuccess.withOpacity(0.1)
                          : FamingaBrandColors.statusWarning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sensor.status,
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
              style: const TextStyle(
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

