import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/field_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/field_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import '../../utils/l10n_extensions.dart';

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
          context.l10n.success,
          context.l10n.fieldAddedSuccess,
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
          context.l10n.error,
          '${context.l10n.failedCreateField}: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.addFieldTitle),
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
                context.l10n.fieldInformation,
                style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.enterBasicDetails,
                style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),

              // Field Name
              CustomTextField(
                controller: _nameController,
                label: context.l10n.fieldName,
                hintText: context.l10n.fieldNameHint,
                prefixIcon: Icons.landscape,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.fieldNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Size
              CustomTextField(
                controller: _sizeController,
                label: context.l10n.fieldSize,
                hintText: context.l10n.fieldSizeHint,
                prefixIcon: Icons.straighten,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.fieldSizeRequired;
                  }
                  final size = double.tryParse(value.trim());
                  if (size == null || size <= 0) {
                    return context.l10n.pleaseEnterValidSize;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Owner
              CustomTextField(
                controller: _ownerController,
                label: context.l10n.ownerManagerName,
                hintText: context.l10n.ownerHint,
                prefixIcon: Icons.person,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.ownerNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Organic Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.eco, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.organicFarming,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.isCertifiedOrganic,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
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
                      activeColor: scheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.youCanAddMore,
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: context.l10n.createField,
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

