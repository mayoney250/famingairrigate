import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/l10n_extensions.dart';

class UsbSensorScreen extends StatelessWidget {
  const UsbSensorScreen({super.key});

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final userId = _getCurrentUserId();
    
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.usbSoilSensor)),
        body: Center(child: Text(context.l10n.pleaseLoginToViewSensors)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.l10n.usbSoilSensor,
          style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('faminga_sensors')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('permission-denied')) {
              return _buildPermissionDeniedError();
            }
            return Center(child: Text('Error: $error'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFA500)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoSensorsMessage();
          }

          final sensors = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sensors.length,
            itemBuilder: (context, index) {
              final sensorDoc = sensors[index];
              final data = sensorDoc.data() as Map<String, dynamic>;
              final hardwareId = sensorDoc.id;
              return _buildSensorCard(context, hardwareId, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildPermissionDeniedError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.l10n.accessDenied,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.firestoreSecurityRulesBlocking,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSensorsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 64, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            context.l10n.noSensorsRegistered,
            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.registerSensorInSensorsPage,
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
          ),
        ],
      ),
    );

  Widget _buildSensorCard(BuildContext context, String hardwareId, Map<String, dynamic> data) {
    final moisture = data['moisture'] as num? ?? 0;
    final temperature = data['temperature'] as num? ?? 0;
    final moistureStatus = data['moisture_status'] as String? ?? 'Unknown';
    final tempStatus = data['temp_status'] as String? ?? 'Unknown';
    final timestamp = data['timestamp'] as Timestamp?;
    final fieldId = data['fieldId'] as String?;

    // Check if data is stale (> 15 seconds old)
    final isStale = timestamp != null &&
        DateTime.now().difference(timestamp.toDate()).inSeconds > 15;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sensor ID and field name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.sensorLabel(hardwareId),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (fieldId != null)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('fields')
                            .doc(fieldId)
                            .get(),
                        builder: (context, fieldSnapshot) {
                          if (fieldSnapshot.hasData && fieldSnapshot.data!.exists) {
                                  final fieldName = fieldData['label'] ?? context.l10n.unknownField;
                                  return Text(
                                    context.l10n.fieldLabel(fieldName),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isStale ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isStale ? Colors.red : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isStale ? context.l10n.statusOffline : context.l10n.statusActive,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isStale ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: context.l10n.soilMoisture,
                    value: '$moisture',
                    unit: '%',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                    status: moistureStatus,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: context.l10n.tempLabel,
                    value: '$temperature',
                    unit: '°C',
                    icon: Icons.thermostat,
                    color: Colors.orange,
                    status: tempStatus,
                  ),
                ),
              ],
            ),

            // Timestamp
            if (timestamp != null) ...[
              const SizedBox(height: 12),
              Text(
                '${context.l10n.lastUpdate}: ${DateFormat('MMM d, HH:mm:ss').format(timestamp.toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String status,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}