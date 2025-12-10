import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/sensor_session_service.dart';
import '../../services/sensor_discovery_service.dart';
import '../../config/colors.dart';

class NewSensorDialog extends StatefulWidget {
  final String hardwareId;
  final String? deviceInfo;

  const NewSensorDialog({
    super.key,
    required this.hardwareId,
    this.deviceInfo,
  });

  @override
  State<NewSensorDialog> createState() => _NewSensorDialogState();
}

class _NewSensorDialogState extends State<NewSensorDialog> {
  String? _selectedFieldId;
  bool _isClaiming = false;
  final _sessionService = SensorSessionService();
  final _discoveryService = SensorDiscoveryService();

  @override
  Widget build(BuildContext context) {
    final fields = Provider.of<DashboardProvider>(context).fields;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.usb, color: Colors.blue),
          SizedBox(width: 8),
          Text('New Sensor Detected'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hardware ID: ${widget.hardwareId}'),
          const SizedBox(height: 16),
          const Text('Select a field to assign this sensor to:'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _selectedFieldId,
            items: fields.map((field) {
              return DropdownMenuItem(
                value: field['id'],
                child: Text(field['name'] ?? 'Unknown Field'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedFieldId = val),
            hint: const Text('Select Field'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Ignore for now (maybe delete locally or from DB?)
            // For now just close, it will pop up again if we don't handle it
            // Ideally we could have an "Ignore" list in local storage
            Navigator.pop(context);
          },
          child: const Text('Ignore'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: FamingaBrandColors.primaryOrange,
            foregroundColor: Colors.white,
          ),
          onPressed: _selectedFieldId == null || _isClaiming
              ? null
              : () async {
                  setState(() => _isClaiming = true);
                  try {
                    // 1. Claim Sensor
                    await _sessionService.claimSensor(
                      hardwareId: widget.hardwareId,
                      fieldId: _selectedFieldId!,
                    );
                    
                    // 2. Remove from unassigned
                    await _discoveryService.removeUnassignedSensor(widget.hardwareId);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sensor assigned successfully!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isClaiming = false);
                  }
                },
          child: _isClaiming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Start Monitoring'),
        ),
      ],
    );
  }
}
