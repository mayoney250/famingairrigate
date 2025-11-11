import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/field_model.dart';
import '../../models/irrigation_zone_model.dart';
import '../../services/irrigation_zone_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/map/map_drawing_widget.dart';
import '../../widgets/shimmer/shimmer_widgets.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';

class IrrigationPlanningScreen extends StatefulWidget {
  final FieldModel field;
  
  const IrrigationPlanningScreen({
    super.key,
    required this.field,
  });

  @override
  State<IrrigationPlanningScreen> createState() => _IrrigationPlanningScreenState();
}

class _IrrigationPlanningScreenState extends State<IrrigationPlanningScreen> {
  final IrrigationZoneService _zoneService = IrrigationZoneService();
  final List<IrrigationZone> _zones = [];
  bool _isLoading = false;
  IrrigationZone? _selectedZone;
  
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.userId ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Irrigation Planning - ${widget.field.label}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: StreamBuilder<List<IrrigationZone>>(
        stream: _zoneService.getFieldZones(widget.field.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: ShimmerCenter(size: 48),
            );
          }
          
          final zones = snapshot.data ?? [];
          
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: MapDrawingWidget(
                  initialLocation: widget.field.borderCoordinates.isNotEmpty
                      ? LatLng(
                          widget.field.borderCoordinates.first.latitude,
                          widget.field.borderCoordinates.first.longitude,
                        )
                      : null,
                  onDrawingComplete: (points, mode) {
                    _showZoneDetailsDialog(
                      context,
                      points,
                      mode == DrawingMode.polygon ? DrawingType.polygon : DrawingType.polyline,
                      userId,
                    );
                  },
                ),
              ),
              
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.water_drop, color: scheme.onPrimaryContainer),
                            const SizedBox(width: 12),
                            Text(
                              'Irrigation Zones (${zones.length})',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onPrimaryContainer,
                                  ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.refresh, color: scheme.onPrimaryContainer),
                              onPressed: () {
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: zones.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.draw,
                                      size: 64,
                                      color: scheme.onSurfaceVariant.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No irrigation zones yet',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Draw on the map to create zones',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: scheme.onSurfaceVariant.withOpacity(0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: zones.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final zone = zones[index];
                                  return _buildZoneCard(zone, scheme);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildZoneCard(IrrigationZone zone, ColorScheme scheme) {
    final color = Color(int.parse(zone.color.replaceFirst('#', '0xFF')));
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => setState(() => _selectedZone = zone),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      zone.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    iconSize: 20,
                    onPressed: () => _editZone(zone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    iconSize: 20,
                    color: scheme.error,
                    onPressed: () => _deleteZone(zone),
                  ),
                ],
              ),
              
              if (zone.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(
                  zone.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
              
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.category,
                    _getZoneTypeLabel(zone.zoneType),
                    scheme,
                  ),
                  _buildInfoChip(
                    Icons.architecture,
                    _getDrawingTypeLabel(zone.drawingType),
                    scheme,
                  ),
                  _buildInfoChip(
                    Icons.pin_drop,
                    '${zone.coordinates.length} points',
                    scheme,
                  ),
                  if (zone.flowRate != null)
                    _buildInfoChip(
                      Icons.speed,
                      '${zone.flowRate} L/min',
                      scheme,
                    ),
                  if (zone.coverage != null)
                    _buildInfoChip(
                      Icons.square_foot,
                      '${zone.coverage} m²',
                      scheme,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getZoneTypeLabel(IrrigationZoneType type) {
    switch (type) {
      case IrrigationZoneType.field:
        return 'Field';
      case IrrigationZoneType.pipe:
        return 'Pipe';
      case IrrigationZoneType.canal:
        return 'Canal';
      case IrrigationZoneType.sprinkler:
        return 'Sprinkler';
      case IrrigationZoneType.drip:
        return 'Drip System';
      case IrrigationZoneType.custom:
        return 'Custom';
    }
  }

  String _getDrawingTypeLabel(DrawingType type) {
    switch (type) {
      case DrawingType.polygon:
        return 'Area/Polygon';
      case DrawingType.polyline:
        return 'Line/Pipe';
      case DrawingType.marker:
        return 'Point';
    }
  }

  void _showZoneDetailsDialog(
    BuildContext context,
    List<LatLng> points,
    DrawingType drawingType,
    String userId,
  ) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final flowRateController = TextEditingController();
    final coverageController = TextEditingController();
    IrrigationZoneType selectedType = IrrigationZoneType.sprinkler;
    String selectedColor = '#2196F3';
    
    Get.dialog(
      AlertDialog(
        title: const Text('Save Irrigation Zone'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nameController,
                    label: 'Zone Name',
                    hintText: 'e.g., Main Sprinkler Zone',
                    prefixIcon: Icons.label,
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<IrrigationZoneType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Zone Type',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: IrrigationZoneType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getZoneTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedType = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Description (Optional)',
                    hintText: 'Add notes about this zone',
                    prefixIcon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: flowRateController,
                          label: 'Flow Rate (L/min)',
                          hintText: 'Optional',
                          prefixIcon: Icons.speed,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: coverageController,
                          label: 'Coverage (m²)',
                          hintText: 'Optional',
                          prefixIcon: Icons.square_foot,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      const Text('Color: '),
                      const SizedBox(width: 12),
                      ...['#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9C27B0'].map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                              shape: BoxShape.circle,
                              border: selectedColor == color
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please enter a zone name');
                return;
              }
              
              Get.back();
              
              final zone = IrrigationZone(
                id: '',
                fieldId: widget.field.id,
                userId: userId,
                name: nameController.text.trim(),
                description: descriptionController.text.trim().isEmpty 
                    ? null 
                    : descriptionController.text.trim(),
                zoneType: selectedType,
                drawingType: drawingType,
                coordinates: points.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
                color: selectedColor,
                flowRate: flowRateController.text.trim().isEmpty 
                    ? null 
                    : double.tryParse(flowRateController.text.trim()),
                coverage: coverageController.text.trim().isEmpty 
                    ? null 
                    : double.tryParse(coverageController.text.trim()),
                createdAt: DateTime.now(),
              );
              
              final zoneId = await _zoneService.createZone(zone);
              
              if (zoneId != null) {
                Get.snackbar(
                  'Success',
                  'Irrigation zone created successfully',
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.green,
                  colorText: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to create irrigation zone',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Save Zone'),
          ),
        ],
      ),
    );
  }

  void _editZone(IrrigationZone zone) {
    Get.snackbar('Coming Soon', 'Edit zone feature will be available soon');
  }

  void _deleteZone(IrrigationZone zone) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Zone'),
        content: Text('Are you sure you want to delete "${zone.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Get.back();
              final success = await _zoneService.deleteZone(zone.id);
              if (success) {
                Get.snackbar(
                  'Success',
                  'Zone deleted successfully',
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.green,
                  colorText: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to delete zone',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 12),
            Text('How to Use'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Drawing Irrigation Zones:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Select drawing mode (Area or Line) at the bottom'),
              const Text('2. Tap on the map to add points'),
              const Text('3. Drag markers to adjust positions'),
              const Text('4. Use "Undo" to remove last point'),
              const Text('5. Click "Save" when finished'),
              const SizedBox(height: 16),
              const Text(
                'Search & Navigation:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Search by address or location name'),
              const Text('• Add coordinates manually for precision'),
              const Text('• Switch between map types (Satellite/Street)'),
              const SizedBox(height: 16),
              const Text(
                'Zone Types:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Area: For irrigation coverage zones'),
              const Text('• Line: For pipes, canals, or irrigation lines'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
