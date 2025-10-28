import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/field_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/field_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';

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
  bool _isOrganic = false;
  bool _isLoading = false;

  final FieldService _fieldService = FieldService();

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveField() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.userId;

      if (userId == null) {
        throw 'User not logged in';
      }

      // Create field with simple data (no complex map coordinates for now)
      final field = FieldModel(
        id: '', // Will be set by Firestore
        userId: userId,
        label: _nameController.text.trim(),
        addedDate: DateTime.now().toIso8601String(),
        borderCoordinates: [
          // Default empty coordinates for now
          // You can add map integration later
        ],
        size: double.parse(_sizeController.text.trim()),
        color: '#4CAF50',
        owner: _ownerController.text.trim(),
        isActive: true,
        isOrganic: _isOrganic,
      );

      final fieldId = await _fieldService.createField(field);

      if (mounted) {
        Get.back(); // Return to fields list first
      }

      if (fieldId != null && mounted) {
        // Show success message AFTER navigation
        await Future.delayed(const Duration(milliseconds: 300));
        Get.snackbar(
          'Success',
          'Field "${field.label}" created successfully!',
          backgroundColor: FamingaBrandColors.statusSuccess,
          colorText: FamingaBrandColors.white,
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
          backgroundColor: FamingaBrandColors.statusWarning,
          colorText: FamingaBrandColors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Add New Field'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Field Information',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: FamingaBrandColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter basic details about your field',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: FamingaBrandColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),

              // Field Name
              CustomTextField(
                controller: _nameController,
                label: 'Field Name',
                hintText: 'e.g., North Field, Back Garden',
                prefixIcon: Icons.landscape,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a field name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Size
              CustomTextField(
                controller: _sizeController,
                label: 'Field Size (hectares)',
                hintText: 'e.g., 2.5',
                prefixIcon: Icons.straighten,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter field size';
                  }
                  final size = double.tryParse(value.trim());
                  if (size == null || size <= 0) {
                    return 'Please enter a valid size';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Owner
              CustomTextField(
                controller: _ownerController,
                label: 'Owner/Manager Name',
                hintText: 'e.g., John Doe',
                prefixIcon: Icons.person,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter owner name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Organic Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FamingaBrandColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FamingaBrandColors.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco,
                      color: FamingaBrandColors.iconColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Organic Farming',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Is this field certified organic?',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: FamingaBrandColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isOrganic,
                      onChanged: (value) {
                        setState(() => _isOrganic = value);
                      },
                      activeColor: FamingaBrandColors.statusSuccess,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: FamingaBrandColors.primaryOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: FamingaBrandColors.primaryOrange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can add more details like crop types and irrigation systems after creating the field.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: FamingaBrandColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: 'Create Field',
                onPressed: _handleSaveField,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

