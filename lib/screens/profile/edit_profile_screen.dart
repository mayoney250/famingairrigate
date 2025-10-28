import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _idNumberController;
  late TextEditingController _addressController;
  late TextEditingController _farmSizeController;
  late TextEditingController _experienceController;
  
  // Dropdown values
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSector;
  String? _selectedGender;
  String? _selectedFarmingType;
  DateTime? _dateOfBirth;
  final List<String> _selectedCrops = [];
  
  File? _selectedImage;
  bool _isLoading = false;
  
  // Rwanda provinces and districts
  final Map<String, List<String>> _rwandaLocations = {
    'Kigali City': ['Gasabo', 'Kicukiro', 'Nyarugenge'],
    'Eastern Province': ['Bugesera', 'Gatsibo', 'Kayonza', 'Kirehe', 'Ngoma', 'Nyagatare', 'Rwamagana'],
    'Northern Province': ['Burera', 'Gakenke', 'Gicumbi', 'Musanze', 'Rulindo'],
    'Southern Province': ['Gisagara', 'Huye', 'Kamonyi', 'Muhanga', 'Nyamagabe', 'Nyanza', 'Nyaruguru', 'Ruhango'],
    'Western Province': ['Karongi', 'Ngororero', 'Nyabihu', 'Nyamasheke', 'Rubavu', 'Rusizi', 'Rutsiro'],
  };
  
  // Sectors will be populated based on district (simplified for now)
  final List<String> _sectors = ['Sector 1', 'Sector 2', 'Sector 3', 'Sector 4', 'Sector 5'];
  
  final List<String> _farmingTypes = [
    'Subsistence Farming',
    'Commercial Farming',
    'Mixed Farming',
    'Organic Farming',
    'Livestock Farming',
    'Crop Farming',
  ];
  
  final List<String> _cropOptions = [
    'Maize', 'Rice', 'Beans', 'Cassava', 'Sweet Potato', 
    'Irish Potato', 'Sorghum', 'Wheat', 'Banana', 'Coffee',
    'Tea', 'Vegetables', 'Fruits', 'Flowers', 'Other'
  ];
  
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _idNumberController = TextEditingController(text: user?.idNumber ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _farmSizeController = TextEditingController(text: '');
    _experienceController = TextEditingController(text: '');
    
    _selectedProvince = user?.province;
    _selectedDistrict = user?.district;
    _selectedGender = user?.gender;
    _dateOfBirth = user?.dateOfBirth;
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _farmSizeController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        backgroundColor: FamingaBrandColors.statusWarning,
        colorText: FamingaBrandColors.white,
      );
    }
  }
  
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: FamingaBrandColors.primaryOrange,
              onPrimary: FamingaBrandColors.white,
              onSurface: FamingaBrandColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw 'User not found';
      }
      
      // Upload image if selected
      String? avatarUrl;
      if (_selectedImage != null) {
        final authService = AuthService();
        avatarUrl = await authService.uploadProfilePicture(
          user.userId,
          _selectedImage!,
        );
      }
      
      // Prepare update data
      final updateData = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'province': _selectedProvince,
        'district': _selectedDistrict,
        'gender': _selectedGender,
        'dateOfBirth': _dateOfBirth,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (avatarUrl != null) {
        updateData['avatar'] = avatarUrl;
      }
      
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.userId)
          .update(updateData);
      
      // Reload user data
      await authProvider.loadUserData(user.userId);
      
      setState(() => _isLoading = false);
      
      Get.back();
      Get.snackbar(
        'Success',
        'Profile updated successfully!',
        backgroundColor: FamingaBrandColors.statusSuccess,
        colorText: FamingaBrandColors.white,
        icon: const Icon(Icons.check_circle, color: FamingaBrandColors.white),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
        backgroundColor: FamingaBrandColors.statusWarning,
        colorText: FamingaBrandColors.white,
        icon: const Icon(Icons.error, color: FamingaBrandColors.white),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: FamingaBrandColors.white,
        foregroundColor: FamingaBrandColors.textPrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Photo Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: FamingaBrandColors.white,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        _selectedImage != null
                            ? CircleAvatar(
                                radius: 60,
                                backgroundImage: FileImage(_selectedImage!),
                              )
                            : user?.avatar != null && user!.avatar!.isNotEmpty
                                ? CircleAvatar(
                                    radius: 60,
                                    backgroundImage: NetworkImage(user.avatar!),
                                  )
                                : CircleAvatar(
                                    radius: 60,
                                    backgroundColor: FamingaBrandColors.primaryOrange,
                                    child: Text(
                                      (user?.firstName ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: FamingaBrandColors.white,
                                      ),
                                    ),
                                  ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: FamingaBrandColors.primaryOrange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: FamingaBrandColors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: FamingaBrandColors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap camera icon to change photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: FamingaBrandColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 2),
              
              // Personal Information Section
              _buildSection(
                title: 'Personal Information',
                icon: Icons.person,
                children: [
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                  _buildDropdown(
                    value: _selectedGender,
                    label: 'Gender',
                    icon: Icons.wc,
                    items: ['Male', 'Female', 'Other'],
                    onChanged: (value) {
                      setState(() => _selectedGender = value);
                    },
                  ),
                  _buildDateField(
                    label: 'Date of Birth',
                    icon: Icons.cake,
                    value: _dateOfBirth,
                    onTap: _selectDate,
                  ),
                  _buildTextField(
                    controller: _idNumberController,
                    label: 'National ID Number (Optional)',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              
              const SizedBox(height: 2),
              
              // Contact Information Section
              _buildSection(
                title: 'Contact Information',
                icon: Icons.contact_phone,
                children: [
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    prefixText: '+250 ',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length < 9) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: FamingaBrandColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email,
                          color: FamingaBrandColors.primaryOrange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: FamingaBrandColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: FamingaBrandColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Email cannot be changed',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: FamingaBrandColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 2),
              
              // Location Section
              _buildSection(
                title: 'Location',
                icon: Icons.location_on,
                children: [
                  _buildDropdown(
                    value: _selectedProvince,
                    label: 'Province',
                    icon: Icons.map,
                    items: _rwandaLocations.keys.toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProvince = value;
                        _selectedDistrict = null; // Reset district
                      });
                    },
                  ),
                  if (_selectedProvince != null)
                    _buildDropdown(
                      value: _selectedDistrict,
                      label: 'District',
                      icon: Icons.location_city,
                      items: _rwandaLocations[_selectedProvince!] ?? [],
                      onChanged: (value) {
                        setState(() => _selectedDistrict = value);
                      },
                    ),
                  if (_selectedDistrict != null)
                    _buildDropdown(
                      value: _selectedSector,
                      label: 'Sector',
                      icon: Icons.place,
                      items: _sectors,
                      onChanged: (value) {
                        setState(() => _selectedSector = value);
                      },
                    ),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Village/Address (Optional)',
                    icon: Icons.home,
                    maxLines: 2,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FamingaBrandColors.primaryOrange,
                      foregroundColor: FamingaBrandColors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: FamingaBrandColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      color: FamingaBrandColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: FamingaBrandColors.primaryOrange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: FamingaBrandColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: FamingaBrandColors.primaryOrange),
          prefixText: prefixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FamingaBrandColors.textSecondary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: FamingaBrandColors.textSecondary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: FamingaBrandColors.primaryOrange,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FamingaBrandColors.statusWarning),
          ),
          filled: true,
          fillColor: FamingaBrandColors.backgroundLight,
        ),
      ),
    );
  }
  
  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: FamingaBrandColors.primaryOrange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: FamingaBrandColors.textSecondary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: FamingaBrandColors.primaryOrange,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: FamingaBrandColors.backgroundLight,
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: FamingaBrandColors.primaryOrange),
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: FamingaBrandColors.textSecondary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: FamingaBrandColors.primaryOrange,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: FamingaBrandColors.backgroundLight,
          ),
          child: Text(
            value != null
                ? '${value.day}/${value.month}/${value.year}'
                : 'Select date',
            style: TextStyle(
              fontSize: 16,
              color: value != null
                  ? FamingaBrandColors.textPrimary
                  : FamingaBrandColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

