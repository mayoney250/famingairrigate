import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../routes/app_routes.dart';
import '../../services/sensor_service.dart';
import '../../models/sensor_model.dart';
import '../../providers/dashboard_provider.dart';
<<<<<<< HEAD
import '../../services/sensor_local_service.dart';
=======
import '../../providers/language_provider.dart';
import '../../services/sensor_local_service.dart';
import '../../utils/l10n_extensions.dart';
>>>>>>> hyacinthe

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
<<<<<<< HEAD
    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Sensors'),
=======
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(context.l10n.sensorsTitle),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                children: const [
                  Icon(Icons.sensors, size: 48, color: FamingaBrandColors.iconColor),
                  SizedBox(height: 12),
                  Text('No sensors yet. Tap + to add.', style: TextStyle(color: Colors.black54)),
                ],
              ),
=======
        children: [
                  Icon(Icons.sensors, size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(context.l10n.noSensorsMessage, style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.65))),
              ],
            ),
>>>>>>> hyacinthe
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sensors.length,
              itemBuilder: (context, i) => _SensorCard(sensor: _sensors[i]),
<<<<<<< HEAD
            ),
=======
      ),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Irrigation'),
        BottomNavigationBarItem(icon: Icon(Icons.landscape), label: 'Fields'),
        BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Sensors'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
=======
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: context.l10n.dashboard),
        BottomNavigationBarItem(icon: const Icon(Icons.water_drop), label: context.l10n.irrigation),
        BottomNavigationBarItem(icon: const Icon(Icons.landscape), label: context.l10n.fields),
        BottomNavigationBarItem(icon: const Icon(Icons.sensors), label: context.l10n.sensors),
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: context.l10n.profile),
>>>>>>> hyacinthe
      ],
    );
  }

  void _showAddSensorDialog() {
    final formKey = GlobalKey<FormState>();
    String displayName = '';
    String type = 'soil';
    String hardwareId = '';
    String pairingMethod = 'BLE';

<<<<<<< HEAD
    // method-specific minimal
=======
>>>>>>> hyacinthe
    String bleMac = '';
    String wifiSsid = '';
    String loraGateway = '';

<<<<<<< HEAD
    // optional/advanced
=======
>>>>>>> hyacinthe
    String assignedZoneId = '';
    String installNote = '';
    String bleNote = '';
    String wifiPassword = '';
    String loraNetworkId = '';
    String loraChannel = '';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
<<<<<<< HEAD
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
=======
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
                            context.l10n.addSensor,
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
                              context.l10n.sensorInformation,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: context.l10n.sensorNameLabel,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? context.l10n.requiredField : null,
                              onChanged: (v) => displayName = v,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: context.l10n.hardwareIdSerial,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? context.l10n.requiredField : null,
                              onChanged: (v) => hardwareId = v,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: context.l10n.pairingMethod,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              value: pairingMethod,
                              items: [
                                DropdownMenuItem(value: 'BLE', child: Text(context.l10n.bleOption)),
                                DropdownMenuItem(value: 'WiFi', child: Text(context.l10n.wifiOption)),
                                DropdownMenuItem(value: 'LoRaWAN', child: Text(context.l10n.loraOption)),
                              ],
                              onChanged: (v) => setState(() => pairingMethod = v!),
                            ),
                            const SizedBox(height: 16),
                            if (pairingMethod == 'BLE')
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: context.l10n.bleMacAddress,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (v) => pairingMethod == 'BLE' && (v == null || v.isEmpty) ? context.l10n.requiredField : null,
                                onChanged: (v) => bleMac = v,
                              ),
                            if (pairingMethod == 'WiFi')
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: context.l10n.wifiSsid,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (v) => pairingMethod == 'WiFi' && (v == null || v.isEmpty) ? context.l10n.requiredField : null,
                                onChanged: (v) => wifiSsid = v,
                              ),
                            if (pairingMethod == 'LoRaWAN')
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: context.l10n.gatewayIdName,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (v) => pairingMethod == 'LoRaWAN' && (v == null || v.isEmpty) ? context.l10n.requiredField : null,
                                onChanged: (v) => loraGateway = v,
                              ),
                            const SizedBox(height: 20),
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  context.l10n.advancedOptions,
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
                                          labelText: context.l10n.pairingNoteCode,
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
                                          labelText: context.l10n.wifiPassword,
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
                                          labelText: context.l10n.loraNetworkId,
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
                                          labelText: context.l10n.channel,
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
                                      labelText: context.l10n.fieldZoneAssignment,
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
                                      labelText: context.l10n.installationNote,
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
                              child: Text(context.l10n.cancelButton),
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
                                Get.snackbar(context.l10n.success, context.l10n.sensorCreated(displayName), snackPosition: SnackPosition.BOTTOM);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FamingaBrandColors.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: Text(context.l10n.addSensor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                Text(sensor.hardwareId, style: TextStyle(fontSize: 12, color: FamingaBrandColors.iconColor)),
                Text(sensor.pairing['method'] ?? '', style: TextStyle(fontSize: 12, color: FamingaBrandColors.textSecondary)),
              ],
            ),
          ],
=======
                Text(sensor.hardwareId, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(sensor.pairing['method'] ?? '', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant.withOpacity(0.65))),
              ],
        ),
      ],
>>>>>>> hyacinthe
        ),
      ),
    );
  }
}

