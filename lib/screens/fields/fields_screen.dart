import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
        title: const Text('Fields'),
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
                  TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Field Name*')),
                  const SizedBox(height: 16),
                  TextField(controller: sizeController, decoration: const InputDecoration(labelText: 'Size (hectares)*'), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextField(controller: ownerController, decoration: const InputDecoration(labelText: 'Owner*')),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Organic Farming'),
                    value: isOrganic,
                    onChanged: (value) => modalState(() => isOrganic = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel'))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final label = labelController.text.trim();
                            final owner = ownerController.text.trim();
                            final size = double.tryParse(sizeController.text.trim());

                            if (label.isEmpty || owner.isEmpty || size == null || size <= 0) {
                              Get.snackbar('Validation Error', 'Please fill all required fields correctly.',
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  colorText: Theme.of(context).colorScheme.onError);
                              return;
                            }

                            Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

                            bool success;
                            if (isEditing) {
                              final updatedData = {
                                'label': label,
                                'size': size,
                                'owner': owner,
                                'isOrganic': isOrganic,
                              };
                              success = await _fieldService.updateField(field.id, updatedData);
                            } else {
                              final newField = FieldModel(
                                id: '',
                                userId: userId,
                                label: label,
                                addedDate: DateTime.now().toIso8601String(),
                                borderCoordinates: [],
                                size: size,
                                owner: owner,
                                isOrganic: isOrganic,
                              );
                              final newId = await _fieldService.createField(newField);
                              success = newId != null;
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

class __FieldDetailsSheetState extends State<_FieldDetailsSheet> {
  Future<Map<String, dynamic>>? _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _fetchAnalytics();
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
            _buildDetailRow('Field Name', widget.field.label),
            _buildDetailRow('Owner', widget.field.owner),
            _buildDetailRow('Size', '${widget.field.size} ha'),
            _buildDetailRow('Organic', widget.field.isOrganic ? 'Yes' : 'No'),
            const Divider(height: 24),
            Text('Analytics', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _analyticsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Could not load analytics.');
                }
                final data = snapshot.data!;
                final IrrigationScheduleModel? last = data['lastIrrigation'];
                final IrrigationScheduleModel? next = data['nextIrrigation'];
                
                return Column(
                  children: [
                    _buildDetailRow('Last Irrigation', last != null ? DateFormat.yMd().add_jm().format(last.startTime) : 'N/A'),
                    _buildDetailRow('Upcoming Schedule', next != null ? DateFormat.yMd().add_jm().format(next.startTime) : 'N/A'),
                    _buildDetailRow('Soil Moisture', '${data['moisture']?.toStringAsFixed(1) ?? 'N/A'}%'),
                    _buildDetailRow('Temperature', '${data['temperature']?.toStringAsFixed(1) ?? 'N/A'}°C'),
                  ],
                );
              },
            ),
             const Divider(height: 24),
            Text('Actions', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
                children: [
                    Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.water_drop_outlined), label: const Text('Start'), onPressed: () {})),
                    const SizedBox(width: 16),
                    Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.stop_circle_outlined), label: const Text('Stop'), onPressed: () {})),
                ],
            ),
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    icon: const Icon(Icons.view_list_outlined),
                    label: const Text('View Schedules'),
                    onPressed: () {
                         Get.toNamed(AppRoutes.irrigationList, arguments: {'fieldId': widget.field.id});
                    },
                ),
            )
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

