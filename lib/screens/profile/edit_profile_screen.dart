import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
<<<<<<< HEAD
=======
import '../../utils/l10n_extensions.dart';
>>>>>>> hyacinthe

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
<<<<<<< HEAD
    'Kigali City': ['Gasabo', 'Kicukiro', 'Nyarugenge'],
    'Eastern Province': ['Bugesera', 'Gatsibo', 'Kayonza', 'Kirehe', 'Ngoma', 'Nyagatare', 'Rwamagana'],
    'Northern Province': ['Burera', 'Gakenke', 'Gicumbi', 'Musanze', 'Rulindo'],
    'Southern Province': ['Gisagara', 'Huye', 'Kamonyi', 'Muhanga', 'Nyamagabe', 'Nyanza', 'Nyaruguru', 'Ruhango'],
    'Western Province': ['Karongi', 'Ngororero', 'Nyabihu', 'Nyamasheke', 'Rubavu', 'Rusizi', 'Rutsiro'],
=======
    'Kigali': ['Gasabo', 'Kicukiro', 'Nyarugenge'],
    'Eastern': ['Bugesera', 'Gatsibo', 'Kayonza', 'Kirehe', 'Ngoma', 'Nyagatare', 'Rwamagana'],
    'Northern': ['Burera', 'Gakenke', 'Gicumbi', 'Musanze', 'Rulindo'],
    'Southern': ['Gisagara', 'Huye', 'Kamonyi', 'Muhanga', 'Nyamagabe', 'Nyanza', 'Nyaruguru', 'Ruhango'],
    'Western': ['Karongi', 'Ngororero', 'Nyabihu', 'Nyamasheke', 'Rubavu', 'Rusizi', 'Rutsiro'],
>>>>>>> hyacinthe
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
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
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
          data: Theme.of(context),
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
      final scheme = Theme.of(context).colorScheme;
      Get.snackbar(
        'Success',
        'Profile updated successfully!',
        backgroundColor: scheme.secondary,
        colorText: scheme.onSecondary,
        icon: Icon(Icons.check_circle, color: scheme.onSecondary),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      final scheme = Theme.of(context).colorScheme;
      Get.snackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
        backgroundColor: scheme.error,
        colorText: scheme.onError,
        icon: Icon(Icons.error, color: scheme.onError),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
<<<<<<< HEAD
        title: const Text('Edit Profile'),
=======
        title: Text(context.l10n.editProfileTitle),
>>>>>>> hyacinthe
        elevation: 0,
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
                color: scheme.surface,
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
                                    backgroundColor: scheme.primary,
                                    child: Text(
                                      (user?.firstName ?? 'U')[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: scheme.onPrimary,
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
                                color: scheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.surface,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: scheme.onPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
<<<<<<< HEAD
                      'Tap camera icon to change photo',
=======
                      context.l10n.tapCameraToChangePhoto,
>>>>>>> hyacinthe
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 2),
              
              // Personal Information Section
              _buildSection(
<<<<<<< HEAD
                title: 'Personal Information',
=======
                title: context.l10n.personalInformation,
>>>>>>> hyacinthe
                icon: Icons.person,
                children: [
                  _buildTextField(
                    controller: _firstNameController,
<<<<<<< HEAD
                    label: 'First Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
=======
                    label: context.l10n.firstName,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.l10n.pleaseEnterFirstName;
>>>>>>> hyacinthe
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    controller: _lastNameController,
<<<<<<< HEAD
                    label: 'Last Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
=======
                    label: context.l10n.lastName,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.l10n.pleaseEnterLastName;
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                title: 'Contact Information',
=======
                title: context.l10n.contactInformation,
>>>>>>> hyacinthe
                icon: Icons.contact_phone,
                children: [
                  _buildTextField(
                    controller: _phoneController,
<<<<<<< HEAD
                    label: 'Phone Number',
=======
                    label: context.l10n.phoneNumberLabel,
>>>>>>> hyacinthe
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    prefixText: '+250 ',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
<<<<<<< HEAD
                        return 'Please enter your phone number';
                      }
                      if (value.length < 9) {
                        return 'Please enter a valid phone number';
=======
                        return context.l10n.pleaseEnterPhoneNumber;
                      }
                      if (value.length < 9) {
                        return context.l10n.pleaseEnterValidPhoneNumber;
>>>>>>> hyacinthe
                      }
                      return null;
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Email cannot be changed',
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
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
<<<<<<< HEAD
                title: 'Location',
=======
                title: context.l10n.location,
>>>>>>> hyacinthe
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
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: scheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
<<<<<<< HEAD
                            'Save Changes',
=======
                            context.l10n.saveChanges,
>>>>>>> hyacinthe
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimary,
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      width: double.infinity,
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: scheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
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
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: scheme.primary),
          prefixText: prefixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outline.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: scheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.error),
          ),
          filled: true,
          fillColor: scheme.surfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: scheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outline.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: scheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: scheme.surfaceVariant,
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        dropdownColor: scheme.surface,
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: scheme.primary),
            suffixIcon: Icon(Icons.calendar_today, color: scheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: scheme.surfaceVariant,
          ),
          child: Text(
            value != null
                ? '${value.day}/${value.month}/${value.year}'
                : 'Select date',
            style: textTheme.bodyLarge?.copyWith(
              color: value != null
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

