import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/field_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/field_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFieldScreen extends StatefulWidget {
  const AddFieldScreen({super.key});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _ownerController = TextEditingController();
  final _cropTypeController = TextEditingController();
  final _locationController = TextEditingController(); // human-readable address or "lat,lng"
  final _descriptionController = TextEditingController();

  bool _isOrganic = false;
  bool _isLoading = false;
  String? _selectedGrowthStage;
  final List<String> _growthStages = [
    'Germination',
    'Seedling',
    'Vegetative Growth',
    'Flowering',
    'Fruit',
    'Maturity / Ripening Stage',
    'Harvest',
  ];

  final FieldService _fieldService = FieldService();

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _ownerController.dispose();
    _cropTypeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveField() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.userId;
      if (userId == null) throw 'User not logged in';

      final String locationRaw = _locationController.text.trim();
      GeoPoint? geoLocation;
      String? locationAddress;
      if (locationRaw.contains(',')) {
        final parts = locationRaw.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            geoLocation = GeoPoint(lat, lng);
          } else {
            locationAddress = locationRaw;
          }
        } else {
          locationAddress = locationRaw;
        }
      } else {
        locationAddress = locationRaw;
      }
      final field = FieldModel(
        id: '',
        userId: userId,
        label: _nameController.text.trim(),
        addedDate: DateTime.now().toIso8601String(),
        borderCoordinates: [],
        size: double.parse(_sizeController.text.trim()),
        color: '#4CAF50',
        owner: _ownerController.text.trim(),
        isActive: true,
        isOrganic: _isOrganic,
        cropType: _cropTypeController.text.trim(),
        description: _descriptionController.text.trim() + (locationAddress != null ? '\nLocation: $locationAddress' : ''),
        location: geoLocation,
        growthStage: _selectedGrowthStage, // Save growth stage
      );

      final fieldId = await _fieldService.createField(field);

      if (mounted) Get.back(); // close screen/modal immediately after creating

      if (fieldId != null && mounted) {
        // show success AFTER returning to list
        await Future.delayed(const Duration(milliseconds: 250));
        Get.snackbar(
          'Success',
          'Field "${field.label}" created successfully!',
          backgroundColor: Theme.of(context).colorScheme.secondary,
          colorText: Theme.of(context).colorScheme.onSecondary,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else if (mounted) {
        throw 'Failed to create field';
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to create field: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Map picker fallback — shows a dialog that lets user either type an address
  // or enter coordinates. Replace the body with a real map widget later if you add a map package.
  Future<void> _showMapPicker() async {
    final addressCtrl = TextEditingController(text: _locationController.text);
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    // If current location was stored as "lat,lng", prefill coords
    if (_locationController.text.contains(',')) {
      final parts = _locationController.text.split(',');
      if (parts.length >= 2) {
        latCtrl.text = parts[0].trim();
        lngCtrl.text = parts[1].trim();
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets.add(const EdgeInsets.all(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pick Location', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              // NOTE: Replace this container with a real map widget (GoogleMap/FlutterMap)
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(ctx).colorScheme.background,
                  border: Border.all(color: Theme.of(ctx).colorScheme.outline),
                ),
                child: Center(
                  child: Text(
                    'Map preview (add google_maps_flutter or flutter_map and replace this)',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Address input
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address (optional)'),
              ),
              const SizedBox(height: 8),

              // Option 2: Coordinates input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latCtrl,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngCtrl,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Choose the best available value: coordinates if provided, else address.
                        final lat = latCtrl.text.trim();
                        final lng = lngCtrl.text.trim();
                        final address = addressCtrl.text.trim();

                        if (lat.isNotEmpty && lng.isNotEmpty) {
                          _locationController.text = '${lat},${lng}';
                        } else if (address.isNotEmpty) {
                          _locationController.text = address;
                        } else {
                          // nothing chosen — keep as-is
                        }

                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Use Location'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add New Field'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Field Information', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Add details about the field. You can refine location with the map picker.',
                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),

            // Field Name
            CustomTextField(
              controller: _nameController,
              label: 'Field Name',
              hintText: 'e.g., North Field',
              prefixIcon: Icons.landscape,
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a field name' : null,
            ),
            const SizedBox(height: 12),

            // Size
            CustomTextField(
              controller: _sizeController,
              label: 'Field Size (hectares)',
              hintText: 'e.g., 2.5',
              prefixIcon: Icons.square_foot,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter field size';
                final size = double.tryParse(v.trim());
                if (size == null || size <= 0) return 'Enter a valid size';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Owner
            CustomTextField(
              controller: _ownerController,
              label: 'Owner / Manager',
              hintText: 'e.g., Jane Doe',
              prefixIcon: Icons.person,
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter owner name' : null,
            ),
            const SizedBox(height: 12),

            // Crop Type
            CustomTextField(
              controller: _cropTypeController,
              label: 'Crop Type',
              hintText: 'e.g., Maize, Beans',
              prefixIcon: Icons.grass,
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter crop type' : null,
            ),
            const SizedBox(height: 12),

            // Growth Stage Dropdown field
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.07),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Growth Stage', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedGrowthStage,
                    hint: const Text('Select Growth Stage'),
                    items: _growthStages.map((stage) {
                      return DropdownMenuItem(
                        value: stage,
                        child: Text(stage),
                      );
                    }).toList(),
                    onChanged: (stage) => setState(() => _selectedGrowthStage = stage),
                  ),
                ],
              ),
            ),
            // Location & map picker row (improved hint)
            Row(children: [
              Expanded(
                child: CustomTextField(
                  controller: _locationController,
                  label: 'Location (address or pick on map)',
                  hintText: 'Kigali, Rwanda or use map icon',
                  prefixIcon: Icons.location_on,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter location or pick on map' : null,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showMapPicker,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Pick'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: scheme.primary),
                  foregroundColor: scheme.primary,
                  minimumSize: const Size(76, 56),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Short description',
              hintText: 'Optional: notes about soil, drains, access, etc.',
              prefixIcon: Icons.description,
              maxLines: 3,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a short description';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Organic toggle (styled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isOrganic ? scheme.primary : scheme.outline),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: _isOrganic ? scheme.primary : scheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Organic Farming', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: _isOrganic ? scheme.primary : null)),
                  ),
                  Switch(
                    value: _isOrganic,
                    onChanged: (v) => setState(() => _isOrganic = v),
                    activeColor: scheme.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Save
            CustomButton(text: 'Create Field', onPressed: _handleSaveField, isLoading: _isLoading),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}
