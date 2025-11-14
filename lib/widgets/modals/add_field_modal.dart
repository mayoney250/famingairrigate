import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/l10n_extensions.dart';
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
    
    final hasCoords = (field?.borderCoordinates?.isNotEmpty ?? false);
    final latController = TextEditingController(
      text: hasCoords ? field!.borderCoordinates.first.latitude.toString() : '',
    );
    final lngController = TextEditingController(
      text: hasCoords ? field!.borderCoordinates.first.longitude.toString() : '',
    );
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
                  Text(isEditing ? context.l10n.editField : context.l10n.addFieldTitle, style: Theme.of(context).textTheme.titleLarge),
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
                              decoration: InputDecoration(labelText: '${context.l10n.fieldNameField}*'),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: fieldLabelController,
                              decoration: InputDecoration(labelText: '${context.l10n.fieldLabelField}*'),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: sizeController,
                              decoration: InputDecoration(labelText: '${context.l10n.sizeHectares}*'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              value: soilType,
                              items: [
                                DropdownMenuItem(value: 'Unknown', child: Text(context.l10n.unknown)),
                                DropdownMenuItem(value: 'Clay', child: Text(context.l10n.clay)),
                                DropdownMenuItem(value: 'Sandy', child: Text(context.l10n.sandy)),
                                DropdownMenuItem(value: 'Loam', child: Text(context.l10n.loam)),
                                DropdownMenuItem(value: 'Silt', child: Text(context.l10n.silt)),
                                DropdownMenuItem(value: 'Peat', child: Text(context.l10n.peat)),
                                DropdownMenuItem(value: 'Chalk', child: Text(context.l10n.chalk)),
                              ],
                              onChanged: (v) => modalState(() => soilType = v ?? 'Unknown'),
                              decoration: InputDecoration(labelText: context.l10n.soilType),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              value: growthStage,
                              items: [
                                DropdownMenuItem(value: 'Germination', child: Text(context.l10n.germination)),
                                DropdownMenuItem(value: 'Seedling', child: Text(context.l10n.seedling)),
                                DropdownMenuItem(value: 'Vegetative Growth', child: Text(context.l10n.vegetativeGrowth)),
                                DropdownMenuItem(value: 'Flowering', child: Text(context.l10n.flowering)),
                                DropdownMenuItem(value: 'Fruit', child: Text(context.l10n.fruit)),
                                DropdownMenuItem(value: 'Maturity', child: Text(context.l10n.maturity)),
                                DropdownMenuItem(value: 'Harvest', child: Text(context.l10n.harvest)),
                              ],
                              onChanged: (v) => modalState(() => growthStage = v ?? 'Germination'),
                              decoration: InputDecoration(labelText: context.l10n.growthStage),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              value: cropType,
                              items: [
                                DropdownMenuItem(value: 'Unknown', child: Text(context.l10n.unknown)),
                                DropdownMenuItem(value: 'Maize', child: Text(context.l10n.maize)),
                                DropdownMenuItem(value: 'Wheat', child: Text(context.l10n.wheat)),
                                DropdownMenuItem(value: 'Rice', child: Text(context.l10n.rice)),
                                DropdownMenuItem(value: 'Soybean', child: Text(context.l10n.soybean)),
                                DropdownMenuItem(value: 'Cotton', child: Text(context.l10n.cotton)),
                                DropdownMenuItem(value: 'Coffee', child: Text(context.l10n.coffee)),
                                DropdownMenuItem(value: 'Tea', child: Text(context.l10n.tea)),
                                DropdownMenuItem(value: 'Vegetables', child: Text(context.l10n.vegetables)),
                                DropdownMenuItem(value: 'Fruits', child: Text(context.l10n.fruits)),
                                DropdownMenuItem(value: 'Other', child: Text(context.l10n.other)),
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
                                decoration: InputDecoration(labelText: '${context.l10n.other}*'),
                              ),
                            ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: ownerController,
                              decoration: InputDecoration(labelText: '${context.l10n.ownerManagerName}*'),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: SwitchListTile(
                              title: Text(context.l10n.organicFarming),
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
                              decoration: InputDecoration(labelText: context.l10n.description),
                            ),
                          ),
                          // Map picker section - simplified for non-Fields screen use
                          if (!isEditing) ...[
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(context.l10n.location, style: Theme.of(context).textTheme.labelLarge),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: latController,
                                          decoration: InputDecoration(labelText: context.l10n.latitude),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: lngController,
                                          decoration: InputDecoration(labelText: context.l10n.longitude),
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
                              child: Text(context.l10n.cancelButton),
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
                                  GeoPoint(lat, lng)
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
                              Get.snackbar(context.l10n.success, isEditing ? context.l10n.fieldUpdatedSuccess(field!.label ?? '') : context.l10n.fieldAddedSuccess,
                                  icon: const Icon(Icons.check_circle, color: Colors.green));
                            } else {
                              Get.snackbar(context.l10n.error, context.l10n.failedCreateField,
                                  icon: const Icon(Icons.error, color: Colors.red));
                            }
                          },
                          child: Text(context.l10n.saveButton),
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
