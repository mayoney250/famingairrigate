import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import '../../utils/l10n_extensions.dart';
import '../../generated/app_localizations.dart';
import '../../services/verification_service.dart';

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
  // Cooperative fields
  bool _isInCooperative = false;
  final _coopNameController = TextEditingController();
  final _coopGovIdController = TextEditingController();
  final _memberIdController = TextEditingController();
  final _numFarmersController = TextEditingController();
  final _leaderNameController = TextEditingController();
  final _leaderPhoneController = TextEditingController();
  final _leaderEmailController = TextEditingController();
  final _coopFieldSizeController = TextEditingController();
  final _coopNumFieldsController = TextEditingController();
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
    _coopNameController.dispose();
    _coopGovIdController.dispose();
    _memberIdController.dispose();
    _numFarmersController.dispose();
    _leaderNameController.dispose();
    _leaderPhoneController.dispose();
    _leaderEmailController.dispose();
    _coopFieldSizeController.dispose();
    _coopNumFieldsController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
<<<<<<< HEAD
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        province: _selectedProvince ?? '',
        district: _selectedDistrict ?? '',
        address: _addressController.text.trim(),
      );
      if (success && mounted) {
        // If user indicated cooperative membership, save cooperative data and create verification request
        if (_isInCooperative) {
          final verificationService = VerificationService();
          // Prepare coop payload
          final coopPayload = {
            'type': 'cooperative',
            'userEmail': _emailController.text.trim(),
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'coopName': _coopNameController.text.trim(),
            'coopGovId': _coopGovIdController.text.trim(),
            'memberId': _memberIdController.text.trim(),
            'numFarmers': int.tryParse(_numFarmersController.text.trim()) ?? 0,
            'leaderName': _leaderNameController.text.trim(),
            'leaderPhone': _leaderPhoneController.text.trim(),
            'leaderEmail': _leaderEmailController.text.trim(),
            'coopFieldSize': double.tryParse(_coopFieldSizeController.text.trim()) ?? 0.0,
            'coopNumFields': int.tryParse(_coopNumFieldsController.text.trim()) ?? 0,
          };

          // Update user's Firestore profile with cooperative info and pending flag
          try {
            if (authProvider.currentUser != null) {
              await authProvider.updateProfile({
                'isCooperative': true,
                'cooperative': coopPayload,
                'verificationStatus': 'pending',
              });
            }

            // create verification request and include admin email
            final adminEmail = await verificationService.getAdminEmail();
            final requesterIdentifier = _emailController.text.trim();
            final verificationDocId = await verificationService.createVerificationRequest(
              {
                'adminEmail': adminEmail,
                'requesterUserId': authProvider.currentUser?.userId ?? '',
                'payload': coopPayload,
              },
              requesterIdentifier: requesterIdentifier,
            );

            // Cloud Function triggers an email to admin automatically
            // Verification document stored with identifier type for admin reference
          } catch (e) {
            // ignore errors but show snackbar
            Get.snackbar(context.l10n.error, 'Failed to create verification request: $e');
          }

          // Show verification pending screen
          Get.offAllNamed('/verification-pending');
          return;
        }

        // Not cooperative: continue with normal email verification flow
        _showSuccessDialog();
      } else if (mounted) {
        _showErrorSnackBar(authProvider.errorMessage ?? context.l10n.registrationFailed);
      }
    }
  }
=======
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Run uniqueness checks before attempting to create the account.
    // Use server-side callable (resolveIdentifier) via AuthService.getEmailForIdentifier
    // so we don't perform unauthenticated client-side reads that Firestore rules disallow.
    try {
      final phone = _phoneController.text.trim();

      // Check phone -> resolve to an existing email if present
      if (phone.isNotEmpty) {
        final resolved = await authProvider.authService.getEmailForIdentifier(phone);
        if (resolved != null) {
          _showErrorSnackBar('Phone number $phone is already registered');
          return;
        }
      }

      // For cooperative identifiers, ask server to resolve coop ID
      if (_isInCooperative) {
        final coopId = _coopGovIdController.text.trim();
        if (coopId.isNotEmpty) {
          final resolved = await authProvider.authService.getEmailForIdentifier(coopId);
          if (resolved != null) {
            _showErrorSnackBar('Cooperative ID $coopId is already registered');
            return;
          }
        }
      }
      // Note: For email duplicates we'll rely on Firebase Auth to raise
      // 'email-already-in-use' during signUp — this avoids unauthenticated
      // reads that Firestore rules block. AuthProvider.signUp handles errors.
    } catch (e) {
      _showErrorSnackBar('Error verifying registration: $e');
      return;
    }

    // If uniqueness checks passed, proceed to sign up
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      province: _selectedProvince ?? '',
      district: _selectedDistrict ?? '',
      address: _addressController.text.trim(),
    );

    if (success && mounted) {
      // If user indicated cooperative membership, save cooperative data and create verification request
      if (_isInCooperative) {
        final verificationService = VerificationService();
        // Prepare coop payload
        final coopPayload = {
          'type': 'cooperative',
          'userEmail': _emailController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'coopName': _coopNameController.text.trim(),
          'coopGovId': _coopGovIdController.text.trim(),
          'memberId': _memberIdController.text.trim(),
          'numFarmers': int.tryParse(_numFarmersController.text.trim()) ?? 0,
          'leaderName': _leaderNameController.text.trim(),
          'leaderPhone': _leaderPhoneController.text.trim(),
          'leaderEmail': _leaderEmailController.text.trim(),
          'coopFieldSize': double.tryParse(_coopFieldSizeController.text.trim()) ?? 0.0,
          'coopNumFields': int.tryParse(_coopNumFieldsController.text.trim()) ?? 0,
        };

        // Update user's Firestore profile with cooperative info and pending flag
        try {
          if (authProvider.currentUser != null) {
            await authProvider.updateProfile({
              'isCooperative': true,
              'cooperative': coopPayload,
              'verificationStatus': 'pending',
            });
          }

          // create verification request and include admin email
          final adminEmail = await verificationService.getAdminEmail();
          final requesterIdentifier = _emailController.text.trim();
          await verificationService.createVerificationRequest(
            {
              'adminEmail': adminEmail,
              'requesterUserId': authProvider.currentUser?.userId ?? '',
              'payload': coopPayload,
            },
            requesterIdentifier: requesterIdentifier,
          );
        } catch (e) {
          Get.snackbar(context.l10n.error, 'Failed to create verification request: $e');
        }

        // Show verification pending screen
        Get.offAllNamed('/verification-pending');
        return;
      }

      // Not cooperative: continue with normal email verification flow
      _showSuccessDialog();
    } else if (mounted) {
      _showErrorSnackBar(authProvider.errorMessage ?? context.l10n.registrationFailed);
    }
  }
 
>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4

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
        actions: [
          _buildCompactLanguageSelector(),
          const SizedBox(width: 16),
        ],
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
                  label: 'Email',
                  hintText: 'email@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.pleaseEnterEmail;
                    }
                    
                    final email = value.trim();
                    
                    // Check if it's a valid email
                    if (GetUtils.isEmail(email)) {
                      return null;
                    }
                    
                    return 'Please enter a valid email';
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone (required)
                CustomTextField(
                  controller: _phoneController,
                  label: context.l10n.phoneNumber,
                  hintText: context.l10n.enterPhoneNumber,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.pleaseEnterPhoneNumber ?? 'Please enter phone number';
                    }
                    // basic length check
                    final digitsOnly = value.replaceAll(RegExp(r'[^0-9+]'), '');
                    if (digitsOnly.length < 7) return 'Enter a valid phone number';
                    return null;
                  },
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
                // Address (required)
                CustomTextField(
                  controller: _addressController,
                  label: 'Address*',
                  hintText: context.l10n.addressHint,
                  prefixIcon: Icons.location_on_outlined,
                  keyboardType: TextInputType.streetAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter your address';
                    if (value.trim().length < 5) return context.l10n.addressTooShort;
                    if (value.length > 100) return context.l10n.addressTooLong;
                    return null;
                  },
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                
                // Cooperative question
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FamingaBrandColors.primaryOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group_work, color: FamingaBrandColors.primaryOrange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Are you part of a farming cooperative?',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select if you belong to an organized cooperative',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isInCooperative,
                        onChanged: (val) => setState(() => _isInCooperative = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cooperative details section (shown if _isInCooperative is true)
                if (_isInCooperative) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cooperative Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Cooperative Name
                        CustomTextField(
                          controller: _coopNameController,
                          label: 'Cooperative Name*',
                          hintText: 'Enter cooperative name',
                          prefixIcon: Icons.group_work,
                          validator: _isInCooperative
                              ? (value) =>
                                  (value == null || value.isEmpty) ? 'Cooperative name required' : null
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Cooperative ID
                        CustomTextField(
                          controller: _coopGovIdController,
                          label: 'Cooperative ID*',
                          hintText: 'Cooperative government registration ID',
                          prefixIcon: Icons.badge,
                          validator: _isInCooperative
                              ? (value) => (value == null || value.isEmpty) ? 'Cooperative ID required' : null
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Number of Farmers
                        CustomTextField(
                          controller: _numFarmersController,
                          label: 'Number of Farmers*',
                          hintText: 'Total farmers in cooperative',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.people,
                          validator: _isInCooperative
                              ? (value) => (value == null || value.isEmpty) ? 'Number of farmers required' : null
                              : null,
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Leader Information',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Leader Name
                        CustomTextField(
                          controller: _leaderNameController,
                          label: 'Leader Name*',
                          hintText: 'Cooperative leader/chairperson name',
                          prefixIcon: Icons.person_outlined,
                          textCapitalization: TextCapitalization.words,
                          validator: _isInCooperative
                              ? (value) => (value == null || value.isEmpty) ? 'Leader name required' : null
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Leader Phone
                        CustomTextField(
                          controller: _leaderPhoneController,
                          label: 'Leader Phone*',
                          hintText: 'Leader contact number',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          validator: _isInCooperative
                              ? (value) => (value == null || value.isEmpty) ? 'Leader phone required' : null
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Leader Email
                        CustomTextField(
                          controller: _leaderEmailController,
                          label: 'Leader Email*',
                          hintText: 'Leader email address',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: _isInCooperative
                              ? (value) {
                                  if (value == null || value.isEmpty) return 'Leader email required';
                                  if (!GetUtils.isEmail(value)) return 'Enter valid email';
                                  return null;
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Cooperative Land',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Total Field Size
                        CustomTextField(
                          controller: _coopFieldSizeController,
                          label: 'Total Size of Fields (hectares)*',
                          hintText: 'Total cultivated area',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.landscape,
                          validator: _isInCooperative
                              ? (value) => (value == null || value.isEmpty) ? 'Field size required' : null
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Number of Fields
                        CustomTextField(
                          controller: _coopNumFieldsController,
                          label: 'Number of Fields*',
                          hintText: 'Total number of fields',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.grid_on,
                          validator: _isInCooperative
                              ? (value) => (value == null || value.isEmpty) ? 'Number of fields required' : null
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
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

  Widget _buildCompactLanguageSelector() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    final languages = [
      {'code': 'English', 'flag': '🇬🇧'},
      {'code': 'Kinyarwanda', 'flag': '🇷🇼'},
      {'code': 'French', 'flag': '🇫🇷'},
      {'code': 'Swahili', 'flag': '🇹🇿'},
    ];

    final currentLang = languages.firstWhere(
      (lang) => lang['code'] == languageProvider.currentLanguageName,
      orElse: () => languages[0],
    );

    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FamingaBrandColors.primaryOrange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLang['flag']!,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: FamingaBrandColors.primaryOrange,
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => languages.map((lang) {
        return PopupMenuItem<String>(
          value: lang['code'],
          child: Row(
            children: [
              Text(
                lang['flag']!,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Text(
                lang['code']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: (value) {
        languageProvider.setLanguage(value);
      },
    );
  }
}

