import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/field_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/field_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import '../../widgets/map/osm_map_drawing_widget.dart';

class AddFieldWithMapScreen extends StatefulWidget {
  final FieldModel? existingField;
  
  const AddFieldWithMapScreen({super.key, this.existingField});

  @override
  State<AddFieldWithMapScreen> createState() => _AddFieldWithMapScreenState();
}

class _AddFieldWithMapScreenState extends State<AddFieldWithMapScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _ownerController = TextEditingController();
  bool _isOrganic = false;
  bool _isLoading = false;
  
  List<LatLng> _fieldBoundary = [];
  
  LatLng? get _initialLocation {
    if (widget.existingField != null && widget.existingField!.borderCoordinates.isNotEmpty) {
      final first = widget.existingField!.borderCoordinates.first;
      return LatLng(first.latitude, first.longitude);
    }
    return null;
  }
  int _currentStep = 0;
  
  final FieldService _fieldService = FieldService();

  @override
  void initState() {
    super.initState();
    if (widget.existingField != null) {
      _nameController.text = widget.existingField!.label;
      _sizeController.text = widget.existingField!.size.toString();
      _ownerController.text = widget.existingField!.owner;
      _isOrganic = widget.existingField!.isOrganic;
      
      _fieldBoundary = widget.existingField!.borderCoordinates
          .map((gp) => LatLng(gp.latitude, gp.longitude))
          .toList();
      
      if (_fieldBoundary.isNotEmpty) {
        _currentStep = 1;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_fieldBoundary.isEmpty) {
        Get.snackbar(
          'Draw Field Boundary',
          'Please draw the field boundary on the map first',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      _saveField();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveField() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.userId;

      if (userId == null) {
        throw 'User not logged in';
      }

      final field = FieldModel(
        id: widget.existingField?.id ?? '',
        userId: userId,
        label: _nameController.text.trim(),
        addedDate: widget.existingField?.addedDate ?? DateTime.now().toIso8601String(),
        borderCoordinates: _fieldBoundary.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
        size: double.parse(_sizeController.text.trim()),
        color: '#4CAF50',
        owner: _ownerController.text.trim(),
        isActive: true,
        isOrganic: _isOrganic,
      );

      String? fieldId;
      if (widget.existingField != null) {
        await _fieldService.updateField(widget.existingField!.id, {
          'label': field.label,
          'borderCoordinates': _fieldBoundary.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
          'size': field.size,
          'owner': field.owner,
          'isOrganic': field.isOrganic,
        });
        fieldId = widget.existingField!.id;
      } else {
        fieldId = await _fieldService.createField(field);
      }

      if (mounted) {
        Get.back();
      }

      if (fieldId != null && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        Get.snackbar(
          'Success',
          'Field "${field.label}" ${widget.existingField != null ? "updated" : "created"} successfully!',
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.green,
          colorText: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else if (mounted) {
        throw 'Failed to save field';
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to save field: $e',
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

  double _calculateArea() {
    if (_fieldBoundary.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < _fieldBoundary.length; i++) {
      int j = (i + 1) % _fieldBoundary.length;
      area += _fieldBoundary[i].latitude * _fieldBoundary[j].longitude;
      area -= _fieldBoundary[j].latitude * _fieldBoundary[i].longitude;
    }
    area = area.abs() / 2.0;
    
    const double earthRadius = 6371000;
    double latInRadians = _fieldBoundary[0].latitude * pi / 180;
    double areaInSquareMeters = area * earthRadius * earthRadius * cos(latInRadians);
    double areaInHectares = areaInSquareMeters / 10000;
    
    return areaInHectares;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.existingField != null ? 'Edit Field' : 'Add New Field'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: index <= _currentStep ? scheme.primary : scheme.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index <= _currentStep ? scheme.onPrimary : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (index < 2)
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.only(left: 4),
                              color: index < _currentStep ? scheme.primary : scheme.surfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ['1. Basic Info', '2. Draw Boundary', '3. Review'][_currentStep],
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildBasicInfoStep(scheme, textTheme),
                _buildMapDrawingStep(),
                _buildReviewStep(scheme, textTheme),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _previousStep,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: _currentStep == 2 ? 'Save Field' : 'Next',
                    onPressed: _nextStep,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep(ColorScheme scheme, TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.edit_note, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'Field Information',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter basic details about your field',
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

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

            CustomTextField(
              controller: _sizeController,
              label: 'Estimated Size (hectares)',
              hintText: 'e.g., 2.5 (will be calculated from boundary)',
              prefixIcon: Icons.straighten,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          'Organic Farming',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Is this field certified organic?',
                          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMapDrawingStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.draw, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Draw Field Boundary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap on the map to mark the corners of your field. You can drag markers to adjust positions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: OSMMapDrawingWidget(
            initialLocation: _initialLocation,
            initialPoints: _fieldBoundary,
            initialDrawingMode: DrawingMode.polygon,
            allowModeSwitch: false,
            onDrawingComplete: (points, mode) {
              setState(() {
                _fieldBoundary = points;
                
                if (_fieldBoundary.length >= 3) {
                  final calculatedArea = _calculateArea();
                  _sizeController.text = calculatedArea.toStringAsFixed(2);
                }
              });
              
              Get.snackbar(
                'Success',
                'Field boundary saved with ${points.length} points',
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.green,
                colorText: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(ColorScheme scheme, TextTheme textTheme) {
    final calculatedArea = _calculateArea();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: scheme.primary),
          const SizedBox(height: 16),
          Text(
            'Review & Confirm',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your field details before saving',
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildReviewCard(
            scheme,
            'Field Information',
            [
              _buildReviewRow('Name', _nameController.text, Icons.landscape),
              _buildReviewRow('Owner', _ownerController.text, Icons.person),
              _buildReviewRow(
                'Farming Type',
                _isOrganic ? 'Organic' : 'Conventional',
                Icons.eco,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildReviewCard(
            scheme,
            'Boundary Details',
            [
              _buildReviewRow(
                'Boundary Points',
                '${_fieldBoundary.length} points',
                Icons.location_on,
              ),
              _buildReviewRow(
                'Entered Size',
                '${_sizeController.text} ha',
                Icons.straighten,
              ),
              if (_fieldBoundary.length >= 3)
                _buildReviewRow(
                  'Calculated Area',
                  '${calculatedArea.toStringAsFixed(2)} ha',
                  Icons.calculate,
                  subtitle: calculatedArea > 0
                      ? 'Based on drawn boundary'
                      : 'Invalid boundary shape',
                  subtitleColor: calculatedArea > 0 ? scheme.primary : scheme.error,
                ),
            ],
          ),
          
          if (_fieldBoundary.length >= 3 && calculatedArea > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The calculated area will be used if it differs from your entered size.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ColorScheme scheme, String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(
    String label,
    String value,
    IconData icon, {
    String? subtitle,
    Color? subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtitleColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
