import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
<<<<<<< HEAD
=======
import '../../utils/l10n_extensions.dart';
>>>>>>> hyacinthe

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  // Password strength indicator
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  // We will compute strength color from theme in build instead of storing a fixed color
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _checkPasswordStrength(String password) {
    setState(() {
      if (password.isEmpty) {
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
        return;
      }
      
      int strength = 0;
      
      // Length check
      if (password.length >= 8) strength++;
      if (password.length >= 12) strength++;
      
      // Contains uppercase
      if (password.contains(RegExp(r'[A-Z]'))) strength++;
      
      // Contains lowercase
      if (password.contains(RegExp(r'[a-z]'))) strength++;
      
      // Contains number
      if (password.contains(RegExp(r'[0-9]'))) strength++;
      
      // Contains special character
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
      
      _passwordStrength = strength / 6;
      
      if (strength <= 2) {
<<<<<<< HEAD
        _passwordStrengthText = 'Weak';
      } else if (strength <= 4) {
        _passwordStrengthText = 'Medium';
      } else {
        _passwordStrengthText = 'Strong';
=======
        _passwordStrengthText = context.l10n.weakPassword;
      } else if (strength <= 4) {
        _passwordStrengthText = context.l10n.mediumPassword;
      } else {
        _passwordStrengthText = context.l10n.strongPassword;
>>>>>>> hyacinthe
      }
    });
  }
  
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if new password matches confirm password
    if (_newPasswordController.text != _confirmPasswordController.text) {
      Get.snackbar(
<<<<<<< HEAD
        'Error',
        'New passwords do not match',
=======
        context.l10n.error,
        context.l10n.passwordsDoNotMatch,
>>>>>>> hyacinthe
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
        icon: Icon(Icons.error, color: Theme.of(context).colorScheme.onError),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      
      setState(() => _isLoading = false);
      
      Get.back();
      Get.snackbar(
<<<<<<< HEAD
        'Success',
        'Password changed successfully!',
=======
        context.l10n.success,
        context.l10n.passwordChangedSuccess,
>>>>>>> hyacinthe
        backgroundColor: Theme.of(context).colorScheme.secondary,
        colorText: Theme.of(context).colorScheme.onSecondary,
        icon: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onSecondary),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      
<<<<<<< HEAD
      String errorMessage = 'Failed to change password';
      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Current password is incorrect';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'New password is too weak';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Please sign out and sign in again to change password';
      }
      
      Get.snackbar(
        'Error',
=======
      String errorMessage = context.l10n.passwordChangeFailed;
      if (e.toString().contains('wrong-password')) {
        errorMessage = context.l10n.currentPasswordIncorrect;
      } else if (e.toString().contains('weak-password')) {
        errorMessage = context.l10n.passwordTooWeak;
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = context.l10n.passwordChangeRequireRelogin;
      }

      Get.snackbar(
        context.l10n.error,
>>>>>>> hyacinthe
        errorMessage,
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
        icon: Icon(Icons.error, color: Theme.of(context).colorScheme.onError),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
<<<<<<< HEAD
        title: const Text('Change Password'),
=======
        title: Text(context.l10n.changePasswordTitle),
>>>>>>> hyacinthe
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                color: scheme.surface,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
<<<<<<< HEAD
                    Text('Secure Your Account', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a strong password to protect your farming data',
=======
                    Text(context.l10n.secureYourAccount, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.chooseStrongPassword,
>>>>>>> hyacinthe
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Current Password
              _buildPasswordField(
                controller: _currentPasswordController,
<<<<<<< HEAD
                label: 'Current Password',
                hint: 'Enter your current password',
=======
                label: context.l10n.currentPassword,
                hint: context.l10n.enterCurrentPassword,
>>>>>>> hyacinthe
                obscureText: _obscureCurrentPassword,
                onToggleVisibility: () {
                  setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
<<<<<<< HEAD
                    return 'Please enter your current password';
=======
                    return context.l10n.currentPasswordRequired;
>>>>>>> hyacinthe
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // New Password
              _buildPasswordField(
                controller: _newPasswordController,
<<<<<<< HEAD
                label: 'New Password',
                hint: 'Enter your new password',
=======
                label: context.l10n.newPassword,
                hint: context.l10n.enterNewPassword,
>>>>>>> hyacinthe
                obscureText: _obscureNewPassword,
                onToggleVisibility: () {
                  setState(() => _obscureNewPassword = !_obscureNewPassword);
                },
                onChanged: _checkPasswordStrength,
                validator: (value) {
                  if (value == null || value.isEmpty) {
<<<<<<< HEAD
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  if (value == _currentPasswordController.text) {
                    return 'New password must be different from current password';
=======
                    return context.l10n.newPasswordRequired;
                  }
                  if (value.length < 6) {
                    return context.l10n.passwordMinimumLength;
                  }
                  if (value == _currentPasswordController.text) {
                    return context.l10n.passwordCannotBeSame;
>>>>>>> hyacinthe
                  }
                  return null;
                },
              ),
              
              // Password strength indicator
              if (_newPasswordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(builder: (context) {
                        final strength = _passwordStrength;
                        final strengthColor = strength <= 0.33
                            ? scheme.error
                            : (strength <= 0.66 ? scheme.primary : scheme.secondary);
                        final strengthText = _passwordStrengthText;
                        return Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _passwordStrength,
                                  minHeight: 8,
                                  backgroundColor: scheme.surfaceVariant,
                                  color: strengthColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              strengthText,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: strengthColor,
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                      _buildPasswordRequirement(
<<<<<<< HEAD
                        'At least 8 characters',
                        _newPasswordController.text.length >= 8,
                      ),
                      _buildPasswordRequirement(
                        'Contains uppercase letter',
                        _newPasswordController.text.contains(RegExp(r'[A-Z]')),
                      ),
                      _buildPasswordRequirement(
                        'Contains lowercase letter',
                        _newPasswordController.text.contains(RegExp(r'[a-z]')),
                      ),
                      _buildPasswordRequirement(
                        'Contains number',
                        _newPasswordController.text.contains(RegExp(r'[0-9]')),
                      ),
                      _buildPasswordRequirement(
                        'Contains special character (!@#\$%^&*)',
                        _newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
=======
                        context.l10n.passwordRequirement8Chars,
                        _newPasswordController.text.length >= 8,
                      ),
                      _buildPasswordRequirement(
                        context.l10n.passwordRequirementUppercase,
                        _newPasswordController.text.contains(RegExp(r'[A-Z]')),
                      ),
                      _buildPasswordRequirement(
                        context.l10n.passwordRequirementLowercase,
                        _newPasswordController.text.contains(RegExp(r'[a-z]')),
                      ),
                      _buildPasswordRequirement(
                        context.l10n.passwordRequirementNumber,
                        _newPasswordController.text.contains(RegExp(r'[0-9]')),
                      ),
                      _buildPasswordRequirement(
                        context.l10n.passwordRequirementSpecial,
                        _newPasswordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
>>>>>>> hyacinthe
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Confirm Password
              _buildPasswordField(
                controller: _confirmPasswordController,
<<<<<<< HEAD
                label: 'Confirm New Password',
                hint: 'Re-enter your new password',
=======
                label: context.l10n.confirmNewPassword,
                hint: context.l10n.reEnterNewPassword,
>>>>>>> hyacinthe
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
<<<<<<< HEAD
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
=======
                    return context.l10n.newPasswordConfirmRequired;
                  }
                  if (value != _newPasswordController.text) {
                    return context.l10n.passwordsDoNotMatchConfirm;
>>>>>>> hyacinthe
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Security Tips
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: scheme.primary, size: 20),
                        const SizedBox(width: 8),
<<<<<<< HEAD
                        Text('Security Tips', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSecurityTip('Use a unique password for your Faminga account'),
                    _buildSecurityTip('Avoid using personal information'),
                    _buildSecurityTip('Change your password regularly'),
                    _buildSecurityTip('Never share your password with anyone'),
=======
                        Text(context.l10n.securityTips, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSecurityTip(context.l10n.tipUnique),
                    _buildSecurityTip(context.l10n.tipPersonal),
                    _buildSecurityTip(context.l10n.tipRegularly),
                    _buildSecurityTip(context.l10n.tipNeverShare),
>>>>>>> hyacinthe
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Change Password Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
<<<<<<< HEAD
                        : const Text(
                            'Change Password',
=======
                        : Text(
                            context.l10n.changePassword,
>>>>>>> hyacinthe
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Cancel Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Get.back(),
                    style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
<<<<<<< HEAD
                    child: const Text(
                      'Cancel',
=======
                    child: Text(
                      context.l10n.cancelButton,
>>>>>>> hyacinthe
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
  
  Widget _buildPasswordRequirement(String text, bool isMet) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? scheme.secondary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: isMet ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecurityTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

