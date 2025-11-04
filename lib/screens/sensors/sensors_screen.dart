import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../routes/app_routes.dart';
import '../../services/sensor_service.dart';
import '../../models/sensor_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/sensor_local_service.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  int _selectedIndex = 3;
  final SensorService _sensorService = SensorService();
  List<SensorModel> _sensors = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSensors());
  }

  Future<void> _loadSensors() async {
    final dash = Provider.of<DashboardProvider>(context, listen: false);
    final farmId = dash.selectedFarmId;
    // 1) show local cache first
    final local = await SensorLocalService.getSensorsForFarm(farmId);
    if (mounted) setState(() => _sensors = local);
    // 2) refresh from remote and cache
    final remote = await _sensorService.getSensorsForFarm(farmId);
    await SensorLocalService.upsertSensors(remote);
    if (!mounted) return;
    setState(() => _sensors = remote);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Sensors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Sensor',
            onPressed: _showAddSensorDialog,
          ),
        ],
      ),
      body: _sensors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sensors, size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('No sensors yet. Tap + to add.', style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.65))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sensors.length,
              itemBuilder: (context, i) => _SensorCard(sensor: _sensors[i]),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (index == _selectedIndex) return;
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
            break;
          case 4:
            Get.offAllNamed(AppRoutes.profile);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Irrigation'),
        BottomNavigationBarItem(icon: Icon(Icons.landscape), label: 'Fields'),
        BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Sensors'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  void _showAddSensorDialog() {
    final formKey = GlobalKey<FormState>();
    String displayName = '';
    String type = 'soil';
    String hardwareId = '';
    String pairingMethod = 'BLE';

    // method-specific minimal
    String bleMac = '';
    String wifiSsid = '';
    String loraGateway = '';

    // optional/advanced
    String assignedZoneId = '';
    String installNote = '';
    String bleNote = '';
    String wifiPassword = '';
    String loraNetworkId = '';
    String loraChannel = '';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Sensor'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Main Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Sensor Name/Label'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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
                    onChanged: (v) => setState(() => type = v ?? 'soil'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Hardware ID/Serial'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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
                    onChanged: (v) => setState(() => pairingMethod = v!),
                  ),
                  if (pairingMethod == 'BLE')
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'BLE MAC Address'),
                      validator: (v) => pairingMethod == 'BLE' && (v == null || v.isEmpty) ? 'Required' : null,
                      onChanged: (v) => bleMac = v,
                    ),
                  if (pairingMethod == 'WiFi')
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'WiFi SSID'),
                      validator: (v) => pairingMethod == 'WiFi' && (v == null || v.isEmpty) ? 'Required' : null,
                      onChanged: (v) => wifiSsid = v,
                    ),
                  if (pairingMethod == 'LoRaWAN')
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Gateway ID/Name'),
                      validator: (v) => pairingMethod == 'LoRaWAN' && (v == null || v.isEmpty) ? 'Required' : null,
                      onChanged: (v) => loraGateway = v,
                    ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: const Text('Advanced (Optional)', style: TextStyle(fontSize: 14)),
                    children: [
                      if (pairingMethod == 'BLE')
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Pairing Note/Code (Optional)'),
                          onChanged: (v) => bleNote = v,
                        ),
                      if (pairingMethod == 'WiFi')
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'WiFi Password (Optional)'),
                          onChanged: (v) => wifiPassword = v,
                        ),
                      if (pairingMethod == 'LoRaWAN') ...[
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'LoRaWAN Network ID (Optional)'),
                          onChanged: (v) => loraNetworkId = v,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Channel (Optional)'),
                          onChanged: (v) => loraChannel = v,
                        ),
                      ],
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Field/Zone Assignment (Optional)'),
                        onChanged: (v) => assignedZoneId = v,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Installation Note (Optional)'),
                        maxLines: 2,
                        onChanged: (v) => installNote = v,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final dash = Provider.of<DashboardProvider>(context, listen: false);
                final farmId = dash.selectedFarmId;
                Map<String, dynamic> pairingMeta = {};
                if (pairingMethod == 'BLE') {
                  pairingMeta = {'mac': bleMac, if (bleNote.isNotEmpty) 'note': bleNote};
                } else if (pairingMethod == 'WiFi') {
                  pairingMeta = {'ssid': wifiSsid, if (wifiPassword.isNotEmpty) 'password': wifiPassword};
                } else if (pairingMethod == 'LoRaWAN') {
                  pairingMeta = {
                    'gateway': loraGateway,
                    if (loraNetworkId.isNotEmpty) 'networkId': loraNetworkId,
                    if (loraChannel.isNotEmpty) 'channel': loraChannel,
                  };
                }
                final sensor = SensorModel(
                  id: '',
                  farmId: farmId,
                  displayName: displayName,
                  type: type,
                  hardwareId: hardwareId,
                  pairing: {'method': pairingMethod, 'meta': pairingMeta},
                  status: 'pending activation',
                  lastSeenAt: null,
                  assignedZoneId: assignedZoneId.isNotEmpty ? assignedZoneId : null,
                  installNote: installNote.isNotEmpty ? installNote : null,
                );
                await _sensorService.createSensor(sensor);
                await SensorLocalService.upsertSensor(sensor);
                if (!mounted) return;
                Navigator.pop(context);
                await _loadSensors();
                Get.snackbar('Sensor Added', 'Sensor "$displayName" created.', snackPosition: SnackPosition.BOTTOM);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: const Text('Add Sensor', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final SensorModel sensor;
  const _SensorCard({required this.sensor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sensor.displayName ?? sensor.hardwareId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Type: ${sensor.type}   Status: ${sensor.status}', style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            if (sensor.installNote != null && sensor.installNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(sensor.installNote!, style: const TextStyle(color: Colors.black54)),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sensor.hardwareId, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(sensor.pairing['method'] ?? '', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant.withOpacity(0.65))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

