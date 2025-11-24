import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../services/sensor_service.dart';
import '../../providers/language_provider.dart';

class FamingaSensorScreen extends StatefulWidget {
  const FamingaSensorScreen({super.key});

  @override
  State<FamingaSensorScreen> createState() => _FamingaSensorScreenState();
}

class _FamingaSensorScreenState extends State<FamingaSensorScreen> {
  final String _docPath = 'sensors/faminga_2in1_sensor/latest/current';
  final String _expectedUserId = '0xv5rdRsAFg05aQcAxvlyynaFy73';
  final SensorService _sensorService = SensorService();
  bool _hasAccess = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final ok = await _sensorService.verifyOwner(_docPath, _expectedUserId);
    if (mounted) {
      setState(() {
        _hasAccess = ok;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lp, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Faminga Sensor'),
        ),
        body: _checking
            ? const Center(child: CircularProgressIndicator())
            : _hasAccess
                ? _buildSensorStream(context)
                : _buildNoAccess(context),
      ),
    );
  }

  Widget _buildNoAccess(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('Permission denied. You are not the owner of this sensor.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStream(BuildContext context) {
    return StreamBuilder(
      stream: _sensorService.streamSensorDocument(_docPath),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data.exists) {
          return const Center(child: Text('No data available'));
        }

        final data = Map<String, dynamic>.from(snapshot.data.data() as Map);

        // common fields
        final temperature = data['temperature'] ?? data['temp'] ?? '--';
        final humidity = data['humidity'] ?? data['hum'] ?? '--';
        final moisture = data['soil_moisture'] ?? data['moisture'] ?? '--';
        final battery = data['battery'] ?? data['bat'] ?? '--';
        final ts = data['ts'] ?? data['timestamp'] ?? data['time'] ?? null;

        String tsText = ts != null ? ts.toString() : 'Unknown';

        return RefreshIndicator(
          onRefresh: () async {
            await _sensorService.getSensorDocumentOnce(_docPath);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.thermostat_outlined),
                  title: const Text('Temperature'),
                  trailing: Text('$temperature'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.water_drop_outlined),
                  title: const Text('Humidity'),
                  trailing: Text('$humidity'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.grass_outlined),
                  title: const Text('Soil Moisture'),
                  trailing: Text('$moisture'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.battery_full_outlined),
                  title: const Text('Battery'),
                  trailing: Text('$battery'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Last Updated'),
                  subtitle: Text(tsText),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async => await _checkOwnership(),
                icon: const Icon(Icons.refresh),
                label: const Text('Re-check Ownership'),
              ),
            ],
          ),
        );
      },
    );
  }
}
