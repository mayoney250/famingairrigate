import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/field_model.dart';
import '../../services/field_service.dart';

class AddFieldModal {
  static Future<bool> show(BuildContext context, {
    required String userId,
    FieldModel? field,
  }) async {
    final FieldService fieldService = FieldService();
    final isEditing = field != null;
    final labelController = TextEditingController(text: field?.label ?? '');
    final sizeController = TextEditingController(text: field?.size.toString() ?? '');
    final ownerController = TextEditingController(text: field?.owner ?? '');
    bool isOrganic = field?.isOrganic ?? false;
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

    bool fieldCreated = false;

    await Get.bottomSheet(
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
                      final isWide = constraints.maxWidth > 640;
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
                          // Map picker section - simplified for non-Fields screen use
                          if (!isEditing) ...[
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Location (Optional)', style: Theme.of(context).textTheme.labelLarge),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: latController,
                                          decoration: const InputDecoration(labelText: 'Latitude'),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: lngController,
                                          decoration: const InputDecoration(labelText: 'Longitude'),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                      ),
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
                                'name': name,
                                'soilType': soilType,
                                'growthStage': growthStage,
                                'cropType': effectiveCropType,
                                'description': descriptionController.text.trim(),
                                if (lat != null && lng != null) 'borderCoordinates': [
                                  {'latitude': lat, 'longitude': lng}
                                ],
                              };
                              success = await fieldService.updateField(field!.id, updatedData);
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
                              createdId = await fieldService.createField(newField);
                              success = createdId != null;
                              if (success && createdId != null) {
                                await fieldService.updateField(createdId, {
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
                              fieldCreated = true;
                              Get.snackbar('Success', 'Field ${isEditing ? 'updated' : 'added'} successfully.',
                                  icon: const Icon(Icons.check_circle, color: Colors.green));
                            } else {
                              Get.snackbar('Error', 'Failed to save field.',
                                  icon: const Icon(Icons.error, color: Colors.red));
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

    return fieldCreated;
  }
}
