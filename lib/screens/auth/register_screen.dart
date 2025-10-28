import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Class scope variables:
  String? _selectedProvince;
  String? _selectedDistrict;

  // Province/District lists (hardcoded for now)
  final Map<String, List<String>> _provinceDistricts = const {
    'Kigali': ['Gasabo', 'Kicukiro', 'Nyarugenge'],
    'Northern': ['Musanze', 'Gicumbi', 'Burera', 'Rulindo', 'Gakenke'],
    'Southern': ['Huye', 'Nyanza', 'Gisagara', 'Muhanga', 'Nyamagabe', 'Nyaruguru', 'Kamonyi', 'Ruhango'],
    'Eastern': ['Bugesera', 'Kayonza', 'Gatsibo', 'Nyagatare', 'Ngoma', 'Kirehe', 'Rwamagana'],
    'Western': ['Rusizi', 'Nyamasheke', 'Rubavu', 'Rutsiro', 'Ngororero', 'Karongi', 'Nyabihu'],
  };
  List<String> get _provinces => _provinceDistricts.keys.toList();
  List<String> get _districts => (_selectedProvince != null) ? _provinceDistricts[_selectedProvince!] ?? [] : [];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        province: _selectedProvince ?? '',
        district: _selectedDistrict ?? '',
      );
      if (success && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        _showErrorSnackBar(authProvider.errorMessage ?? 'Registration failed');
      }
    }
  }

  void _showSuccessDialog() {
    Get.offAllNamed(AppRoutes.emailVerification);
  }

  void _showErrorSnackBar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: FamingaBrandColors.statusWarning,
      colorText: FamingaBrandColors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join Faminga',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: FamingaBrandColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start managing your irrigation smartly',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: FamingaBrandColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // First name
                CustomTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hintText: 'Enter your first name',
                  prefixIcon: Icons.person_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Last name
                CustomTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hintText: 'Enter your last name',
                  prefixIcon: Icons.person_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone (optional)
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  hintText: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                // Province
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: InputDecoration(
                    labelText: 'Province',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.map_outlined),
                  ),
                  items: _provinces
                      .map((province) => DropdownMenuItem<String>(
                            value: province,
                            child: Text(province),
                          ))
                      .toList(),
                  validator: (value) => value == null ? 'Choose a province' : null,
                  onChanged: (p) {
                    setState(() {
                      _selectedProvince = p;
                      _selectedDistrict = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // District
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.location_city_outlined, color: FamingaBrandColors.iconColor),
                  ),
                  items: _districts
                      .map((district) => DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          ))
                      .toList(),
                  validator: (value) => value == null ? 'Choose a district' : null,
                  onChanged: (d) => setState(() => _selectedDistrict = d),
                  disabledHint: const Text('Choose a province first'),
                ),
                const SizedBox(height: 16),
                // Address
                CustomTextField(
                  controller: _addressController,
                  label: 'Address (optional)',
                  hintText: 'e.g., Village, Cell, Sector',
                  prefixIcon: Icons.location_on_outlined,
                  keyboardType: TextInputType.streetAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length < 5) return 'Address too short';
                      if (value.length > 100) return 'Address too long';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      // Store address value if needed to provider
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter your password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Register button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomButton(
                      text: 'Create Account',
                      onPressed: _handleRegister,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: Text(
                        'Login',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: FamingaBrandColors.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

