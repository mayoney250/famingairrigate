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

    String bleMac = '';
    String wifiSsid = '';
    String loraGateway = '';

    String assignedZoneId = '';
    String installNote = '';
    String bleNote = '';
    String wifiPassword = '';
    String loraNetworkId = '';
    String loraChannel = '';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final scheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sensors, color: scheme.onPrimaryContainer, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Add Sensor',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sensor Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Sensor Name/Label',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              onChanged: (v) => displayName = v,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Hardware ID/Serial',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              onChanged: (v) => hardwareId = v,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Pairing Method',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              value: pairingMethod,
                              items: const [
                                DropdownMenuItem(value: 'BLE', child: Text('Bluetooth (BLE)')),
                                DropdownMenuItem(value: 'WiFi', child: Text('WiFi')),
                                DropdownMenuItem(value: 'LoRaWAN', child: Text('LoRaWAN Gateway')),
                              ],
                              onChanged: (v) => setState(() => pairingMethod = v!),
                            ),
                            const SizedBox(height: 16),
                            if (pairingMethod == 'BLE')
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'BLE MAC Address',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (v) => pairingMethod == 'BLE' && (v == null || v.isEmpty) ? 'Required' : null,
                                onChanged: (v) => bleMac = v,
                              ),
                            if (pairingMethod == 'WiFi')
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'WiFi SSID',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (v) => pairingMethod == 'WiFi' && (v == null || v.isEmpty) ? 'Required' : null,
                                onChanged: (v) => wifiSsid = v,
                              ),
                            if (pairingMethod == 'LoRaWAN')
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Gateway ID/Name',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (v) => pairingMethod == 'LoRaWAN' && (v == null || v.isEmpty) ? 'Required' : null,
                                onChanged: (v) => loraGateway = v,
                              ),
                            const SizedBox(height: 20),
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  'Advanced Options',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                children: [
                                  const SizedBox(height: 8),
                                  if (pairingMethod == 'BLE')
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Pairing Note/Code (Optional)',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          filled: true,
                                          fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        onChanged: (v) => bleNote = v,
                                      ),
                                    ),
                                  if (pairingMethod == 'WiFi')
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'WiFi Password (Optional)',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          filled: true,
                                          fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        obscureText: true,
                                        onChanged: (v) => wifiPassword = v,
                                      ),
                                    ),
                                  if (pairingMethod == 'LoRaWAN') ...[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'LoRaWAN Network ID (Optional)',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          filled: true,
                                          fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        onChanged: (v) => loraNetworkId = v,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Channel (Optional)',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          filled: true,
                                          fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        onChanged: (v) => loraChannel = v,
                                      ),
                                    ),
                                  ],
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Field/Zone Assignment (Optional)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                    onChanged: (v) => assignedZoneId = v,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Installation Note (Optional)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                    maxLines: 3,
                                    onChanged: (v) => installNote = v,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FamingaBrandColors.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: const Text('Add Sensor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

