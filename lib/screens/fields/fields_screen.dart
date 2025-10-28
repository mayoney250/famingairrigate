import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/field_model.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/field_service.dart';

class FieldsScreen extends StatefulWidget {
  const FieldsScreen({super.key});

  @override
  State<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  int _selectedIndex = 2; // Fields is at index 2 in bottom nav
  final FieldService _fieldService = FieldService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.userId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Fields')),
        body: const Center(
          child: Text('Please log in to view your fields'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Fields'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter
            },
          ),
        ],
      ),
      body: StreamBuilder<List<FieldModel>>(
        stream: _fieldService.getUserFields(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: FamingaBrandColors.primaryOrange,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: FamingaBrandColors.statusWarning,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading fields',
                    style: TextStyle(
                      color: FamingaBrandColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final fields = snapshot.data ?? [];

          if (fields.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.landscape,
                    size: 64,
                    color: FamingaBrandColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Fields Yet',
                    style: TextStyle(
                      color: FamingaBrandColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first field to get started',
                    style: TextStyle(
                      color: FamingaBrandColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed(AppRoutes.addField);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Field'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FamingaBrandColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Trigger rebuild
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final field = fields[index];
                return _buildFieldCard(field);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.addField);
        },
        backgroundColor: FamingaBrandColors.primaryOrange,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFieldCard(FieldModel field) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showFieldOptions(field);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: field.isOrganic 
                          ? FamingaBrandColors.statusSuccess.withOpacity(0.1)
                          : FamingaBrandColors.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      field.isOrganic ? Icons.eco : Icons.landscape,
                      color: field.isOrganic
                          ? FamingaBrandColors.statusSuccess
                          : FamingaBrandColors.iconColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.label,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${field.size.toStringAsFixed(1)} hectares',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: FamingaBrandColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: field.isActive
                          ? FamingaBrandColors.statusSuccess.withOpacity(0.1)
                          : FamingaBrandColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      field.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: field.isActive
                            ? FamingaBrandColors.statusSuccess
                            : FamingaBrandColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoItem(Icons.person, 'Owner', field.owner),
                  const SizedBox(width: 24),
                  if (field.isOrganic)
                    _buildInfoItem(Icons.eco, 'Type', 'Organic'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: FamingaBrandColors.iconColor,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            color: FamingaBrandColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showFieldOptions(FieldModel field) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: FamingaBrandColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              field.label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${field.size.toStringAsFixed(1)} hectares • ${field.owner}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FamingaBrandColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: FamingaBrandColors.primaryOrange,
              ),
              title: const Text('View Details'),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Coming Soon',
                  'Field details screen will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit,
                color: FamingaBrandColors.primaryOrange,
              ),
              title: const Text('Edit Field'),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Coming Soon',
                  'Edit field feature will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: Icon(
                field.isActive ? Icons.pause_circle : Icons.play_circle,
                color: FamingaBrandColors.darkGreen,
              ),
              title: Text(field.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Get.back();
                _toggleFieldStatus(field);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.delete,
                color: FamingaBrandColors.statusWarning,
              ),
              title: const Text(
                'Delete Field',
                style: TextStyle(color: FamingaBrandColors.statusWarning),
              ),
              onTap: () {
                Get.back();
                _confirmDeleteField(field);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFieldStatus(FieldModel field) async {
    final success = await _fieldService.toggleFieldStatus(
      field.id,
      !field.isActive,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Field ${field.isActive ? 'deactivated' : 'activated'}',
        backgroundColor: FamingaBrandColors.statusSuccess,
        colorText: FamingaBrandColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to update field status',
        backgroundColor: FamingaBrandColors.statusWarning,
        colorText: FamingaBrandColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _confirmDeleteField(FieldModel field) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Field'),
        content: Text(
          'Are you sure you want to delete "${field.label}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog

              // Show loading
              Get.dialog(
                const Center(
                  child: CircularProgressIndicator(
                    color: FamingaBrandColors.primaryOrange,
                  ),
                ),
                barrierDismissible: false,
              );

              final success = await _fieldService.deleteField(field.id);

              Get.back(); // Close loading

              if (success) {
                Get.snackbar(
                  'Success',
                  'Field "${field.label}" deleted successfully',
                  backgroundColor: FamingaBrandColors.statusSuccess,
                  colorText: FamingaBrandColors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to delete field',
                  backgroundColor: FamingaBrandColors.statusWarning,
                  colorText: FamingaBrandColors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FamingaBrandColors.statusWarning,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (index == _selectedIndex) return;

        setState(() => _selectedIndex = index);

        switch (index) {
          case 0:
            Get.offAllNamed(AppRoutes.dashboard);
            break;
          case 1:
            Get.offAllNamed(AppRoutes.irrigationList);
            break;
          case 2:
            // Already on Fields
            break;
          case 3:
            Get.offAllNamed(AppRoutes.sensors);
            break;
          case 4:
            Get.offAllNamed(AppRoutes.profile);
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: FamingaBrandColors.primaryOrange,
      unselectedItemColor: FamingaBrandColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop),
          label: 'Irrigation',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.landscape),
          label: 'Fields',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sensors),
          label: 'Sensors',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

