import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import '../../utils/l10n_extensions.dart';

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
        _showErrorSnackBar(authProvider.errorMessage ?? context.l10n.registrationFailed);
      }
    }
  }

  void _showSuccessDialog() {
    Get.offAllNamed(AppRoutes.emailVerification);
  }

  void _showErrorSnackBar(String message) {
    Get.snackbar(
      context.l10n.error,
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
        title: Text(context.l10n.createAccount),
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
                  context.l10n.joinFaminga,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: FamingaBrandColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.startManaging,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: FamingaBrandColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // First name
                CustomTextField(
                  controller: _firstNameController,
                  label: context.l10n.firstName,
                  hintText: context.l10n.enterFirstName,
                  prefixIcon: Icons.person_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.pleaseEnterFirstName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Last name
                CustomTextField(
                  controller: _lastNameController,
                  label: context.l10n.lastName,
                  hintText: context.l10n.enterLastName,
                  prefixIcon: Icons.person_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.pleaseEnterLastName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email
                CustomTextField(
                  controller: _emailController,
                  label: context.l10n.email,
                  hintText: context.l10n.enterEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.pleaseEnterEmail;
                    }
                    if (!GetUtils.isEmail(value)) {
                      return context.l10n.pleaseEnterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone (optional)
                CustomTextField(
                  controller: _phoneController,
                  label: context.l10n.phoneNumber,
                  hintText: context.l10n.enterPhoneNumber,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                // Province
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvince,
                  decoration: InputDecoration(
                    labelText: context.l10n.province,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.map_outlined),
                  ),
                  items: _provinces
                      .map((province) => DropdownMenuItem<String>(
                            value: province,
                            child: Text(province),
                          ))
                      .toList(),
                  validator: (value) => value == null ? context.l10n.chooseProvince : null,
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
                  initialValue: _selectedDistrict,
                  decoration: InputDecoration(
                    labelText: context.l10n.district,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.location_city_outlined, color: FamingaBrandColors.iconColor),
                  ),
                  items: _districts
                      .map((district) => DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          ))
                      .toList(),
                  validator: (value) => value == null ? context.l10n.chooseDistrict : null,
                  onChanged: (d) => setState(() => _selectedDistrict = d),
                  disabledHint: Text(context.l10n.chooseProvinceFirst),
                ),
                const SizedBox(height: 16),
                // Address
                CustomTextField(
                  controller: _addressController,
                  label: context.l10n.addressOptional,
                  hintText: context.l10n.addressHint,
                  prefixIcon: Icons.location_on_outlined,
                  keyboardType: TextInputType.streetAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length < 5) return context.l10n.addressTooShort;
                      if (value.length > 100) return context.l10n.addressTooLong;
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
                  label: context.l10n.password,
                  hintText: context.l10n.enterPassword,
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
                      return context.l10n.pleaseEnterPassword;
                    }
                    if (value.length < 8) {
                      return context.l10n.passwordMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: context.l10n.confirmPassword,
                  hintText: context.l10n.reEnterPassword,
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
                      return context.l10n.pleaseConfirmPassword;
                    }
                    if (value != _passwordController.text) {
                      return context.l10n.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Register button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomButton(
                      text: context.l10n.createAccount,
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
      context.l10n.alreadyHaveAccount,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
    TextButton(
      onPressed: () {
        Get.back();
      },
      child: Text(
        context.l10n.login,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

