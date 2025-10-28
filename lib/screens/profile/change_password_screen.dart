import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/colors.dart';
import '../../services/auth_service.dart';

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
  Color _passwordStrengthColor = Colors.red;
  
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
        _passwordStrengthColor = Colors.red;
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
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (strength <= 4) {
        _passwordStrengthText = 'Medium';
        _passwordStrengthColor = Colors.orange;
      } else {
        _passwordStrengthText = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }
  
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if new password matches confirm password
    if (_newPasswordController.text != _confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'New passwords do not match',
        backgroundColor: FamingaBrandColors.statusWarning,
        colorText: FamingaBrandColors.white,
        icon: const Icon(Icons.error, color: FamingaBrandColors.white),
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
        'Success',
        'Password changed successfully!',
        backgroundColor: FamingaBrandColors.statusSuccess,
        colorText: FamingaBrandColors.white,
        icon: const Icon(Icons.check_circle, color: FamingaBrandColors.white),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      
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
        errorMessage,
        backgroundColor: FamingaBrandColors.statusWarning,
        colorText: FamingaBrandColors.white,
        icon: const Icon(Icons.error, color: FamingaBrandColors.white),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Change Password'),
        elevation: 0,
        backgroundColor: FamingaBrandColors.white,
        foregroundColor: FamingaBrandColors.textPrimary,
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
                color: FamingaBrandColors.white,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: FamingaBrandColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Secure Your Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: FamingaBrandColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a strong password to protect your farming data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: FamingaBrandColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Current Password
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Current Password',
                hint: 'Enter your current password',
                obscureText: _obscureCurrentPassword,
                onToggleVisibility: () {
                  setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // New Password
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'New Password',
                hint: 'Enter your new password',
                obscureText: _obscureNewPassword,
                onToggleVisibility: () {
                  setState(() => _obscureNewPassword = !_obscureNewPassword);
                },
                onChanged: _checkPasswordStrength,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  if (value == _currentPasswordController.text) {
                    return 'New password must be different from current password';
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
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _passwordStrength,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                color: _passwordStrengthColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _passwordStrengthText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _passwordStrengthColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordRequirement(
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
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Confirm Password
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                hint: 'Re-enter your new password',
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
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
                  color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: FamingaBrandColors.primaryOrange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: FamingaBrandColors.primaryOrange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Security Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: FamingaBrandColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSecurityTip('Use a unique password for your Faminga account'),
                    _buildSecurityTip('Avoid using personal information'),
                    _buildSecurityTip('Change your password regularly'),
                    _buildSecurityTip('Never share your password with anyone'),
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
                            'Change Password',
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
                    style: TextButton.styleFrom(
                      foregroundColor: FamingaBrandColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: FamingaBrandColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
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
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: FamingaBrandColors.primaryOrange,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: FamingaBrandColors.textSecondary,
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: FamingaBrandColors.textSecondary.withOpacity(0.3),
            ),
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
          fillColor: FamingaBrandColors.white,
        ),
      ),
    );
  }
  
  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : FamingaBrandColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet
                  ? FamingaBrandColors.textPrimary
                  : FamingaBrandColors.textSecondary,
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
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: FamingaBrandColors.primaryOrange,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: FamingaBrandColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

