import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/field_model.dart';
import '../../models/irrigation_schedule_model.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/field_service.dart';
import '../../services/irrigation_service.dart';

class FieldsScreen extends StatefulWidget {
  const FieldsScreen({super.key});

  @override
  State<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  final int _selectedIndex = 2;
  final FieldService _fieldService = FieldService();
  final IrrigationService _irrigationService = IrrigationService();

  String _searchQuery = '';
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.userId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Fields')),
        body: const Center(child: Text('Please log in to view your fields')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Fields'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddEditFieldModal(context, userId: userId),
            icon: const Icon(Icons.add),
            label: const Text('Add Field'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<FieldModel>>(
              stream: _fieldService.getUserFields(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading fields.'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(context, userId);
                }

                final allFields = snapshot.data!;
                final filteredFields = allFields
                    .where((field) => field.label.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                if (_searchQuery.isNotEmpty && filteredFields.isEmpty) {
                  return _buildNoResultsState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFields.length,
                  itemBuilder: (context, index) {
                    final field = filteredFields[index];
                    return _FieldCard(
                      field: field,
                      onEdit: () => _showAddEditFieldModal(context, field: field, userId: userId),
                      onDelete: () => _confirmDeleteField(context, field),
                      onViewDetails: () => _showFieldDetailsModal(context, field),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by field name...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape_outlined, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 24),
          Text('No fields found.', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Add your first field to get started!', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditFieldModal(context, userId: userId),
            icon: const Icon(Icons.add),
            label: const Text('Add Field'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          Text('No fields found for "$_searchQuery"', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  void _showAddEditFieldModal(BuildContext context, {FieldModel? field, required String userId}) {
    final isEditing = field != null;
    final labelController = TextEditingController(text: field?.label ?? '');
    final sizeController = TextEditingController(text: field?.size.toString() ?? '');
    final ownerController = TextEditingController(text: field?.owner ?? '');
    bool isOrganic = field?.isOrganic ?? false;
    // Additional fields
    final fieldNameController = TextEditingController(text: field?.label ?? '');
    final fieldLabelController = TextEditingController(text: field?.label ?? '');
    final descriptionController = TextEditingController();
    final latController = TextEditingController(text: (field?.borderCoordinates.isNotEmpty ?? false)
        ? field!.borderCoordinates.first.latitude.toString()
        : '');
    final lngController = TextEditingController(text: (field?.borderCoordinates.isNotEmpty ?? false)
        ? field!.borderCoordinates.first.longitude.toString()
        : '');
    String soilType = 'Unknown';
    String growthStage = 'Germination';
    String cropType = 'Unknown';
    final cropTypeOtherController = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter modalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? 'Edit Field' : 'Add New Field', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 640; // responsive breakpoint
                      final fieldWidth = isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: fieldNameController,
                              decoration: const InputDecoration(labelText: 'Field Name*'),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: fieldLabelController,
                              decoration: const InputDecoration(labelText: 'Field Label*'),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: sizeController,
                              decoration: const InputDecoration(labelText: 'Size (hectares)*'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              value: soilType,
                              items: const [
                                DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                                DropdownMenuItem(value: 'Clay', child: Text('Clay')),
                                DropdownMenuItem(value: 'Sandy', child: Text('Sandy')),
                                DropdownMenuItem(value: 'Loam', child: Text('Loam')),
                                DropdownMenuItem(value: 'Silt', child: Text('Silt')),
                                DropdownMenuItem(value: 'Peat', child: Text('Peat')),
                                DropdownMenuItem(value: 'Chalk', child: Text('Chalk')),
                              ],
                              onChanged: (v) => modalState(() => soilType = v ?? 'Unknown'),
                              decoration: const InputDecoration(labelText: 'Soil Type'),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              value: growthStage,
                              items: const [
                                DropdownMenuItem(value: 'Germination', child: Text('Germination')),
                                DropdownMenuItem(value: 'Seedling', child: Text('Seedling')),
                                DropdownMenuItem(value: 'Vegetative Growth', child: Text('Vegetative Growth')),
                                DropdownMenuItem(value: 'Flowering', child: Text('Flowering')),
                                DropdownMenuItem(value: 'Fruit', child: Text('Fruit')),
                                DropdownMenuItem(value: 'Maturity', child: Text('Maturity')),
                                DropdownMenuItem(value: 'Harvest', child: Text('Harvest')),
                              ],
                              onChanged: (v) => modalState(() => growthStage = v ?? 'Germination'),
                              decoration: const InputDecoration(labelText: 'Growth Stage'),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              value: cropType,
                              items: const [
                                DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                                DropdownMenuItem(value: 'Maize', child: Text('Maize')),
                                DropdownMenuItem(value: 'Wheat', child: Text('Wheat')),
                                DropdownMenuItem(value: 'Rice', child: Text('Rice')),
                                DropdownMenuItem(value: 'Soybean', child: Text('Soybean')),
                                DropdownMenuItem(value: 'Cotton', child: Text('Cotton')),
                                DropdownMenuItem(value: 'Coffee', child: Text('Coffee')),
                                DropdownMenuItem(value: 'Tea', child: Text('Tea')),
                                DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
                                DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (v) => modalState(() => cropType = v ?? 'Unknown'),
                              decoration: const InputDecoration(labelText: 'Crop Type'),
                            ),
                          ),
                          if (cropType == 'Other')
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: cropTypeOtherController,
                                decoration: const InputDecoration(labelText: 'Specify Crop Type*'),
                              ),
                            ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: ownerController,
                              decoration: const InputDecoration(labelText: 'Owner*'),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: SwitchListTile(
                              title: const Text('Organic Farming'),
                              value: isOrganic,
                              onChanged: (value) => modalState(() => isOrganic = value),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: descriptionController,
                              maxLines: 3,
                              decoration: const InputDecoration(labelText: 'Description'),
                            ),
                          ),
                          // Map picker
                          SizedBox(
                            width: constraints.maxWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Location', style: Theme.of(context).textTheme.labelLarge),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 220,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: kIsWeb
                                        ? _WebMapPlaceholder(
                                            onUseMyLocation: () async {
                                              try {
                                                final pos = await _ensureLocationPermissionAndGetPosition();
                                                modalState(() {
                                                  latController.text = pos.latitude.toStringAsFixed(6);
                                                  lngController.text = pos.longitude.toStringAsFixed(6);
                                                });
                                              } catch (_) {}
                                            },
                                            onOpenMaps: () async {
                                              final url = Uri.parse('https://www.google.com/maps');
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url, mode: LaunchMode.externalApplication);
                                              }
                                            },
                                          )
                                        : FutureBuilder<Position>(
                                            future: _ensureLocationPermissionAndGetPosition(),
                                            builder: (context, snap) {
                                              final LatLng defaultCenter = const LatLng(-1.286389, 36.817223); // Nairobi fallback
                                              final LatLng center = (snap.hasData)
                                                  ? LatLng(snap.data!.latitude, snap.data!.longitude)
                                                  : defaultCenter;
                                              LatLng? selected;
                                              if (latController.text.isNotEmpty && lngController.text.isNotEmpty) {
                                                final lt = double.tryParse(latController.text);
                                                final lg = double.tryParse(lngController.text);
                                                if (lt != null && lg != null) selected = LatLng(lt, lg);
                                              }
                                              return GoogleMap(
                                                initialCameraPosition: CameraPosition(target: selected ?? center, zoom: selected != null ? 14 : 10),
                                                myLocationEnabled: snap.connectionState == ConnectionState.done,
                                                myLocationButtonEnabled: true,
                                                zoomControlsEnabled: true,
                                                markers: {
                                                  if (selected != null)
                                                    Marker(
                                                      markerId: const MarkerId('field_location'),
                                                      position: selected,
                                                    )
                                                },
                                                onTap: (LatLng pos) {
                                                  modalState(() {
                                                    latController.text = pos.latitude.toStringAsFixed(6);
                                                    lngController.text = pos.longitude.toStringAsFixed(6);
                                                  });
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: latController,
                              readOnly: true,
                              decoration: const InputDecoration(labelText: 'Latitude'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: lngController,
                              readOnly: true,
                              decoration: const InputDecoration(labelText: 'Longitude'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel'))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final label = fieldLabelController.text.trim();
                            final name = fieldNameController.text.trim();
                            final owner = ownerController.text.trim();
                            final size = double.tryParse(sizeController.text.trim());
                            final lat = double.tryParse(latController.text.trim());
                            final lng = double.tryParse(lngController.text.trim());

                            final effectiveCropType = cropType == 'Other'
                                ? cropTypeOtherController.text.trim()
                                : cropType;

                            if (name.isEmpty || label.isEmpty || owner.isEmpty || size == null || size <= 0 ||
                                (cropType == 'Other' && effectiveCropType.isEmpty)) {
                              Get.snackbar('Validation Error', 'Please fill all required fields correctly.',
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  colorText: Theme.of(context).colorScheme.onError);
                              return;
                            }

                            Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

                            bool success;
                            String? createdId;
                            if (isEditing) {
                              final updatedData = {
                                'label': label,
                                'size': size,
                                'owner': owner,
                                'isOrganic': isOrganic,
                                // extra metadata
                                'name': name,
                                'soilType': soilType,
                                'growthStage': growthStage,
                                'cropType': effectiveCropType,
                                'description': descriptionController.text.trim(),
                                if (lat != null && lng != null) 'borderCoordinates': [
                                  {'latitude': lat, 'longitude': lng}
                                ],
                              };
                              success = await _fieldService.updateField(field.id, updatedData);
                            } else {
                              final newField = FieldModel(
                                id: '',
                                userId: userId,
                                label: label,
                                addedDate: DateTime.now().toIso8601String(),
                                borderCoordinates: (lat != null && lng != null)
                                    ? [GeoPoint(lat, lng)]
                                    : [],
                                size: size,
                                owner: owner,
                                isOrganic: isOrganic,
                              );
                              createdId = await _fieldService.createField(newField);
                              success = createdId != null;
                              if (success && createdId != null) {
                                await _fieldService.updateField(createdId, {
                                  'name': name,
                                  'soilType': soilType,
                                  'growthStage': growthStage,
                                  'cropType': effectiveCropType,
                                  'description': descriptionController.text.trim(),
                                });
                              }
                            }

                            Get.back(); // Close loading dialog
                            Get.back(); // Close bottom sheet

                            if (success) {
                              Get.snackbar('Success', 'Field ${isEditing ? 'updated' : 'added'} successfully.',
                                  icon: Icon(Icons.check_circle, color: Colors.green));
                            } else {
                              Get.snackbar('Error', 'Failed to save field.',
                                  icon: Icon(Icons.error, color: Colors.red));
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<Position> _ensureLocationPermissionAndGetPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      // Return a default central position when permission is permanently denied
      return Future.error('Location permissions are permanently denied');
    }
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      // Fallback to last known or throw
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      return Future.error('Unable to get current location');
    }
  }

  void _confirmDeleteField(BuildContext context, FieldModel field) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Field?'),
        content: Text('Are you sure you want to delete "${field.label}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
              final success = await _fieldService.deleteField(field.id);
              Get.back();
              if (success) {
                Get.snackbar('Success', 'Field "${field.label}" deleted.');
              } else {
                Get.snackbar('Error', 'Failed to delete field.');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          ),
        ],
      ),
    );
  }
  
  void _showFieldDetailsModal(BuildContext context, FieldModel field) {
    Get.bottomSheet(
        _FieldDetailsSheet(field: field, irrigationService: _irrigationService),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (index == _selectedIndex) return;
        switch (index) {
          case 0: Get.offAllNamed(AppRoutes.dashboard); break;
          case 1: Get.offAllNamed(AppRoutes.irrigationList); break;
          case 2: break;
          case 3: Get.offAllNamed(AppRoutes.sensors); break;
          case 4: Get.offAllNamed(AppRoutes.profile); break;
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
}

class _FieldCard extends StatelessWidget {
  final FieldModel field;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const _FieldCard({
    required this.field,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shadowColor: scheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field.label, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(field.owner, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Text('${field.size.toStringAsFixed(1)} ha', style: textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Status:'),
                Text(field.isOrganic ? 'Organic' : 'Non-Organic', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(icon: Icon(Icons.edit_outlined, color: scheme.primary), onPressed: onEdit, tooltip: 'Edit Field'),
                IconButton(icon: Icon(Icons.delete_outline, color: scheme.error), onPressed: onDelete, tooltip: 'Delete Field'),
                IconButton(icon: Icon(Icons.visibility_outlined, color: scheme.tertiary), onPressed: onViewDetails, tooltip: 'View Details'),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _FieldDetailsSheet extends StatefulWidget {
  final FieldModel field;
  final IrrigationService irrigationService;
  
  const _FieldDetailsSheet({required this.field, required this.irrigationService});

  @override
  __FieldDetailsSheetState createState() => __FieldDetailsSheetState();
}

class _WebMapPlaceholder extends StatelessWidget {
  final VoidCallback onUseMyLocation;
  final VoidCallback onOpenMaps;

  const _WebMapPlaceholder({required this.onUseMyLocation, required this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceVariant.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 48),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Map picker requires a Google Maps API key on web. Use the buttons below or configure the API key.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: onUseMyLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use My Location'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenMaps,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Google Maps'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class __FieldDetailsSheetState extends State<_FieldDetailsSheet> {
  Future<Map<String, dynamic>>? _analyticsFuture;
  Future<Map<String, dynamic>>? _fieldMetaFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _fetchAnalytics();
    _fieldMetaFuture = _fetchFieldMeta();
  }

  Future<Map<String, dynamic>> _fetchAnalytics() async {
    // In a real app, you would fetch this data from your services
    // For now, we simulate with some delays and mock data
    await Future.delayed(const Duration(milliseconds: 500));
    final schedules = await widget.irrigationService.getUserSchedules(widget.field.userId).first;
    final fieldSchedules = schedules.where((s) => s.zoneId == widget.field.id).toList();
    
    final lastIrrigation = fieldSchedules.where((s) => s.status == 'completed').lastOrNull;
    final nextIrrigation = fieldSchedules.where((s) => s.status == 'scheduled' && s.startTime.isAfter(DateTime.now())).firstOrNull;

    return {
      'lastIrrigation': lastIrrigation,
      'nextIrrigation': nextIrrigation,
      'moisture': widget.field.moisture ?? 65.0, // Mock if null
      'temperature': widget.field.temperature ?? 24.0, // Mock if null
    };
  }

  Future<Map<String, dynamic>> _fetchFieldMeta() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('fields').doc(widget.field.id).get();
      final data = (doc.data() ?? {}) as Map<String, dynamic>;
      return data;
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Field Details', style: textTheme.titleLarge),
            const Divider(height: 24),
            FutureBuilder<Map<String, dynamic>>(
              future: _fieldMetaFuture,
              builder: (context, metaSnap) {
                final meta = metaSnap.data ?? {};
                final name = (meta['name'] as String?)?.trim();
                final soilType = (meta['soilType'] as String?) ?? 'Unknown';
                final growthStage = (meta['growthStage'] as String?) ?? 'N/A';
                final cropType = (meta['cropType'] as String?) ?? 'N/A';
                final description = (meta['description'] as String?) ?? '-';
                String coords = '-';
                if (widget.field.borderCoordinates.isNotEmpty) {
                  final gp = widget.field.borderCoordinates.first;
                  coords = '${gp.latitude.toStringAsFixed(6)}, ${gp.longitude.toStringAsFixed(6)}';
                }
                final rows = <Widget>[
                  _buildDetailRow('Field Name', name?.isNotEmpty == true ? name! : widget.field.label),
                  _buildDetailRow('Field Label', widget.field.label),
                  _buildDetailRow('Owner', widget.field.owner),
                  _buildDetailRow('Size', '${widget.field.size} ha'),
                  _buildDetailRow('Organic', widget.field.isOrganic ? 'Yes' : 'No'),
                  _buildDetailRow('Soil Type', soilType),
                  _buildDetailRow('Growth Stage', growthStage),
                  _buildDetailRow('Crop Type', cropType),
                  _buildDetailRow('Coordinates', coords),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...rows,
                    const SizedBox(height: 8),
                    Text('Description', style: textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(description, style: textTheme.bodyMedium),
                  ],
                );
              },
            ),
            const Divider(height: 24),
            // Actions header and spacing removed per user request.
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

