import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../routes/app_routes.dart';
import '../../services/sensor_service.dart';
import '../../models/sensor_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/sensor_local_service.dart';
import '../../utils/l10n_extensions.dart';
import 'usb_sensor_screen_with_sessions.dart'; // Import the new USB sensor screen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        actions: [
          // USB Sensor Button
          IconButton(
            icon: const Icon(Icons.usb),
            tooltip: 'USB Soil Sensor',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsbSensorScreenWithSessions()),
              );
            },
          ),
          // Add Wireless Sensor Button
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Sensor',
            onPressed: _showAddSensorDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // USB Sensor Card at the top
          _buildUsbSensorCard(context),
          
          // Divider
          if (_sensors.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Wireless Sensors',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
                ],
              ),
            ),
          
          // Wireless sensors list
          Expanded(
            child: _sensors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sensors, size: 48, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(context.l10n.noSensorsMessage, style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.65))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sensors.length,
                    itemBuilder: (context, i) => _SensorCard(sensor: _sensors[i]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildUsbSensorCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA500).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UsbSensorScreenWithSessions()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.usb,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌱 FAMINGA USB Soil Sensor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time soil monitoring via USB',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
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
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: context.l10n.dashboard),
        BottomNavigationBarItem(icon: const Icon(Icons.water_drop), label: context.l10n.irrigation),
        BottomNavigationBarItem(icon: const Icon(Icons.landscape), label: context.l10n.fields),
        BottomNavigationBarItem(icon: const Icon(Icons.sensors), label: context.l10n.sensors),
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: context.l10n.profile),
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
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('fields')
                                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                final fields = snapshot.data!.docs;
                                
                                if (fields.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: scheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'No fields available. Please create a field first.',
                                      style: TextStyle(color: scheme.onErrorContainer),
                                    ),
                                  );
                                }
                                
                                return DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Assign to Field',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  value: bleMac.isEmpty ? null : bleMac,
                                  items: fields.map((field) {
                                    final data = field.data() as Map<String, dynamic>;
                                    final label = data['label'] ?? 'Unknown Field';
                                    return DropdownMenuItem(
                                      value: field.id,
                                      child: Text(label),
                                    );
                                  }).toList(),
                                  validator: (v) => v == null || v.isEmpty 
                                      ? 'Please select a field' 
                                      : null,
                                  onChanged: (v) => setState(() => bleMac = v ?? ''),
                                );
                              },
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