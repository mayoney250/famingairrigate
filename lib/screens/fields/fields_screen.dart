import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/colors.dart';
import '../../routes/app_routes.dart';

class FieldsScreen extends StatefulWidget {
  const FieldsScreen({super.key});

  @override
  State<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  int _selectedIndex = 2; // Fields is at index 2 in bottom nav

  // Mock data - replace with real data from Firestore
  final List<Map<String, dynamic>> _fields = [
    {
      'name': 'North Field',
      'area': '5.2 hectares',
      'crop': 'Maize',
      'status': 'Active',
      'icon': Icons.grass,
    },
    {
      'name': 'South Field',
      'area': '3.8 hectares',
      'crop': 'Wheat',
      'status': 'Active',
      'icon': Icons.eco,
    },
    {
      'name': 'East Field',
      'area': '4.5 hectares',
      'crop': 'Rice',
      'status': 'Inactive',
      'icon': Icons.agriculture,
    },
    {
      'name': 'West Field',
      'area': '6.1 hectares',
      'crop': 'Vegetables',
      'status': 'Active',
      'icon': Icons.local_florist,
    },
    {
      'name': 'Central Field',
      'area': '2.9 hectares',
      'crop': 'Tomatoes',
      'status': 'Active',
      'icon': Icons.park,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fields.length,
        itemBuilder: (context, index) {
          final field = _fields[index];
          return _buildFieldCard(field);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add field screen
          Get.snackbar(
            'Add Field',
            'Field creation screen coming soon!',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        backgroundColor: FamingaBrandColors.primaryOrange,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field) {
    final bool isActive = field['status'] == 'Active';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to field details
          Get.snackbar(
            'Field Details',
            'Viewing ${field['name']} details',
            snackPosition: SnackPosition.BOTTOM,
          );
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
                      color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      field['icon'],
                      color: FamingaBrandColors.iconColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field['name'],
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          field['area'],
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
                      color: isActive
                          ? FamingaBrandColors.statusSuccess.withOpacity(0.1)
                          : FamingaBrandColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      field['status'],
                      style: TextStyle(
                        color: isActive
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
                  _buildInfoItem(Icons.spa, 'Crop', field['crop']),
                  const SizedBox(width: 24),
                  _buildInfoItem(Icons.water_drop, 'Irrigation', 'Auto'),
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
          style: TextStyle(
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

