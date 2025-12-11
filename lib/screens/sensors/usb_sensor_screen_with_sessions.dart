import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/sensor_session_service.dart';
import '../../utils/l10n_extensions.dart';

class UsbSensorScreenWithSessions extends StatefulWidget {
  const UsbSensorScreenWithSessions({super.key});

  @override
  State<UsbSensorScreenWithSessions> createState() => _UsbSensorScreenWithSessionsState();
}

class _UsbSensorScreenWithSessionsState extends State<UsbSensorScreenWithSessions> {
  final SensorSessionService _sessionService = SensorSessionService();
  String? _selectedFieldId;
  bool _isLoading = false;

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _claimSensor(String hardwareId) async {
    if (_selectedFieldId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseSelectFieldFirst)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _sessionService.claimSensor(
      hardwareId: hardwareId,
      fieldId: _selectedFieldId!,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.sensorClaimedSuccess(hardwareId)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.sensorInUseError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _releaseSensor(String hardwareId) async {
    setState(() => _isLoading = true);

    final success = await _sessionService.releaseSensor(hardwareId);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.sensorReleasedSuccess(hardwareId)),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
      body: Column(
        children: [
          // Field selector
          _buildFieldSelector(userId),
          
          // Sensors list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('faminga_sensors')
                  .where('userId', isEqualTo: userId)  // Filter by current user
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
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
                    return _buildSensorCard(context, hardwareId, data, userId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSelector(String userId) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.selectFieldToMonitor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('fields')
                .where('userId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final fields = snapshot.data!.docs;

              if (fields.isEmpty) {
                return Text(
                  context.l10n.noFieldsCreateFirst,
                  style: const TextStyle(color: Colors.grey),
                );
              }

              return DropdownButtonFormField<String>(
                value: _selectedFieldId,
                decoration: InputDecoration(
                  hintText: context.l10n.chooseField,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: fields.map((field) {
                  final data = field.data() as Map<String, dynamic>;
                  final label = data['label'] ?? data['name'] ?? field.id;
                  return DropdownMenuItem(
                    value: field.id,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedFieldId = value);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(BuildContext context, String hardwareId, Map<String, dynamic> data, String currentUserId) {
    final moisture = data['moisture'] as num? ?? 0;
    final temperature = data['temperature'] as num? ?? 0;
    final moistureStatus = data['moisture_status'] as String? ?? 'Unknown';
    final tempStatus = data['temp_status'] as String? ?? 'Unknown';
    final timestamp = data['timestamp'] as Timestamp?;
    final fieldId = data['fieldId'] as String?;
    final sensorUserId = data['userId'] as String?;

    // Check if data is stale (>15 seconds old) - for offline badge
    final isStale = timestamp != null &&
        DateTime.now().difference(timestamp.toDate()).inSeconds > 15;
    
    // Check if data is fresh (<5 seconds old) - for sensor connectivity
    final isFresh = timestamp != null &&
        DateTime.now().difference(timestamp.toDate()).inSeconds <= 5;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _sessionService.streamSession(hardwareId),
      builder: (context, sessionSnapshot) {
        final session = sessionSnapshot.data;
        final hasActiveSession = session != null;
        final isOwnedByCurrentUser = session?['userId'] == currentUserId;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with sensor ID and session status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
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
                                  final fieldData = fieldSnapshot.data!.data() as Map<String, dynamic>;
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
                    ),
                    // Session status badge
                    _buildSessionBadge(hasActiveSession, isOwnedByCurrentUser, isStale),
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

                // Action buttons
                const SizedBox(height: 16),
                _buildActionButtons(hardwareId, hasActiveSession, isOwnedByCurrentUser, isStale, isFresh),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionBadge(bool hasActiveSession, bool isOwnedByCurrentUser, bool isStale) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (!hasActiveSession) {
      badgeColor = Colors.grey;
      badgeText = context.l10n.statusAvailable;
      badgeIcon = Icons.sensors_off;
    } else if (isOwnedByCurrentUser) {
      if (isStale) {
        badgeColor = Colors.orange;
        badgeText = context.l10n.statusOffline;
        badgeIcon = Icons.cloud_off;
      } else {
        badgeColor = Colors.green;
        badgeText = context.l10n.statusActive;
        badgeIcon = Icons.check_circle;
      }
    } else {
      badgeColor = Colors.red;
      badgeText = context.l10n.statusInUse;
      badgeIcon = Icons.lock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String hardwareId, bool hasActiveSession, bool isOwnedByCurrentUser, bool isStale, bool isFresh) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If sensor is offline (stale data), show disabled message
    if (isStale && hasActiveSession && isOwnedByCurrentUser) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.sensorOfflineMessage,
                    style: TextStyle(color: Colors.orange[800], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _releaseSensor(hardwareId),
              icon: const Icon(Icons.stop),
              label: Text(context.l10n.stopMonitoring),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!hasActiveSession) {
      // Check if sensor is connected (fresh data)
      if (!isFresh) {
        // No sensor detected or data too old
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.sensors_off, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.noSensorDetected,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null, // Disabled
                icon: const Icon(Icons.play_arrow),
                label: Text(context.l10n.startMonitoring),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      }
      
      // Sensor is connected and available - show enabled claim button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _claimSensor(hardwareId),
          icon: const Icon(Icons.play_arrow),
          label: Text(context.l10n.startMonitoring),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA500),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    } else if (isOwnedByCurrentUser) {
      // User owns this session - show release button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _releaseSensor(hardwareId),
          icon: const Icon(Icons.stop),
          label: Text(context.l10n.stopMonitoring),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    } else {
      // Someone else owns this session
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.sensorInUseByOther,
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
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

  Widget _buildNoSensorsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 64, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            context.l10n.noSensorsYet,
            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.sensorsWillAppearHere,
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
