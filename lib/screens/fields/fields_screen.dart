import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/field_model.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class FieldsScreen extends StatefulWidget {
  const FieldsScreen({Key? key}) : super(key: key);

  @override
  State<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FieldModel> _fields = [];
  List<FieldModel> _filteredFields = [];

  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final snapshot = await _firestore.collection('fields').get();
    final fields = snapshot.docs.map((doc) {
      return FieldModel.fromMap(doc.data());
    }).toList();

    setState(() {
      _fields = fields;
      _filteredFields = fields;
    });
  }

  void _filterFields(String query) {
    setState(() {
      _filteredFields = _fields
          .where((field) => field.label.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _deleteField(FieldModel field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Field"),
        content: Text("Are you sure you want to delete '${field.label}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('fields').doc(field.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Field deleted successfully")),
      );
      _loadFields();
    }
  }

  void _openFieldModal({FieldModel? field}) {
    final isEdit = field != null;
    final nameController = TextEditingController(text: field?.label ?? '');
    final ownerController = TextEditingController(text: field?.owner ?? '');
    final sizeController = TextEditingController(text: field?.size.toString() ?? '');
    final cropTypeController = TextEditingController(text: field?.color ?? '');
    final locationController = TextEditingController(text: field?.color ?? '');
    final descriptionController = TextEditingController(text: field?.color ?? '');
    bool isOrganic = field?.isOrganic ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? "Edit Field" : "Add New Field",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),

              // Field Name
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Field Name*",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Size
              TextField(
                controller: sizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Size (hectares)*",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Owner
              TextField(
                controller: ownerController,
                decoration: const InputDecoration(
                  labelText: "Owner*",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Crop Type
              TextField(
                controller: cropTypeController,
                decoration: const InputDecoration(
                  labelText: "Crop Type",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Location
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Location / Address",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Organic toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Organic Farming"),
                  Switch(
                    value: isOrganic,
                    onChanged: (val) {
                      setState(() => isOrganic = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty ||
                          ownerController.text.isEmpty ||
                          sizeController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please fill all required fields")),
                        );
                        return;
                      }

                      final newField = {
                        'label': nameController.text,
                        'owner': ownerController.text,
                        'size': double.tryParse(sizeController.text) ?? 0,
                        'isOrganic': isOrganic,
                        'cropType': cropTypeController.text,
                        'location': locationController.text,
                        'description': descriptionController.text,
                        'addedDate': DateTime.now().toIso8601String(),
                        'userId': 'currentUser',
                      };

                      if (isEdit) {
                        await _firestore.collection('fields').doc(field!.id).update(newField);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Field updated successfully")),
                        );
                      } else {
                        await _firestore.collection('fields').add(newField);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Field added successfully")),
                        );
                      }

                      Navigator.pop(context);
                      _loadFields();
                    },
                    child: Text(isEdit ? "Save Changes" : "Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final scheme = Theme.of(context).colorScheme;
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
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      backgroundColor: scheme.surface,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Irrigation'),
        BottomNavigationBarItem(icon: Icon(Icons.landscape), label: 'Fields'),
        BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Sensors'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fields"),
        actions: [
          TextButton.icon(
            onPressed: () => _openFieldModal(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Field", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search
            TextField(
              controller: _searchController,
              onChanged: _filterFields,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search by field name...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // List
            Expanded(
              child: _filteredFields.isEmpty
                  ? const Center(child: Text("No fields found"))
                  : ListView.builder(
                      itemCount: _filteredFields.length,
                      itemBuilder: (context, index) {
                        final field = _filteredFields[index];
                        return Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.green.withOpacity(0.15), width: 1.5),
                          ),
                          color: Theme.of(context).colorScheme.surface,
                          margin: const EdgeInsets.only(bottom: 14),
                          shadowColor: Colors.greenAccent.withOpacity(0.14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 14),
                              leading: CircleAvatar(
                                backgroundColor: field.isOrganic ? Colors.green : Colors.brown[400],
                                child: Icon(
                                  field.isOrganic ? Icons.eco : Icons.landscape,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                field.label,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Chip(
                                          label: Text((field.isOrganic ? "Organic" : "Non-Organic")),
                                          avatar: Icon(Icons.eco, color: field.isOrganic ? Colors.green : Colors.brown, size: 18),
                                          backgroundColor: field.isOrganic ? Colors.green[50] : Colors.brown[100],
                                          labelStyle: TextStyle(color: field.isOrganic ? Colors.green[900] : Colors.brown[800]),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        Chip(
                                          label: Text("${field.size} ha"),
                                          avatar: const Icon(Icons.square_foot, size: 18),
                                          backgroundColor: Colors.blue[50],
                                          labelStyle: const TextStyle(color: Colors.indigo),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        if (field.cropType != null && field.cropType!.isNotEmpty) ...[
                                          Chip(
                                            label: Text(field.cropType ?? ''),
                                            avatar: const Icon(Icons.grass, size: 18),
                                            backgroundColor: Colors.teal[50],
                                            labelStyle: const TextStyle(color: Colors.teal),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ],
                                        if (field.location != null)
                                          Chip(
                                            label: Text("${field.location}"),
                                            avatar: const Icon(Icons.location_on, size: 18),
                                            backgroundColor: Colors.orange[50],
                                            labelStyle: const TextStyle(color: Colors.orange),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    if (field.description != null && field.description!.isNotEmpty)
                                      Text(
                                        field.description ?? '',
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    // Show growth stage if exists
                                    if (field.growthStage != null && field.growthStage!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Growth Stage: ' + field.growthStage!,
                                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.deepOrange),),
                                    ]
                                  ],
                                ),
                              ),
                              trailing: Wrap(
                                spacing: 0,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.amber),
                                    onPressed: () => _openFieldModal(field: field),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteField(field),
                                    tooltip: 'Delete',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye, color: Colors.green),
                                    onPressed: () {
                                      // You can add View Details Modal here
                                    },
                                    tooltip: 'View',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
