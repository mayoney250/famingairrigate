import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import '../../generated/app_localizations.dart';
import '../../utils/l10n_extensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signIn(
        identifier: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else if (mounted) {
        _showErrorSnackBar(
          authProvider.errorMessage ?? context.l10n.login,
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(
        authProvider.errorMessage!,
      );
    }
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;
            final isLargeScreen = constraints.maxWidth > 800;
            
            // Calculate dynamic padding based on screen width
            final double horizontalPadding = isSmallScreen ? 16.0 : (isLargeScreen ? 0.0 : 24.0);
            final double contentWidth = isLargeScreen ? 500.0 : double.infinity;

            return Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildCompactLanguageSelector(),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo
                              Center(
                                child: Container(
                                  width: isSmallScreen ? 120 : 150,
                                  height: isSmallScreen ? 120 : 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Image.asset(
                                    'assets/images/splash_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Welcome text
                              Text(
                                context.l10n.welcomeBack,
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      color: FamingaBrandColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 24 : 32,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.signInToManage,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: FamingaBrandColors.textPrimary,
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isSmallScreen ? 32 : 48),
                              
                              // Identifier field (Email | Cooperative ID | Phone)
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email, Cooperative ID or Phone',
                                hintText: 'email@example.com or +2507XXXXXXXX or COOP12345',
                                keyboardType: TextInputType.text,
                                prefixIcon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return context.l10n.enterEmail;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Password field
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
                                    return context.l10n.enterPassword;
                                  }
                                  if (value.length < 8) {
                                    return context.l10n.enterPassword;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              
                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Get.toNamed(AppRoutes.forgotPassword);
                                  },
                                  child: Text(
                                    context.l10n.forgotPassword,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: FamingaBrandColors.primaryOrange,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Login button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  return CustomButton(
                                    text: context.l10n.login,
                                    onPressed: _handleLogin,
                                    isLoading: authProvider.isLoading,
                                  );
                                },
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Divider with OR text
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(AppLocalizations.of(context)?.or ?? 'OR'),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Google Sign-In button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  return OutlinedButton.icon(
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : _handleGoogleSignIn,
                                    icon: Icon(
                                      Icons.g_mobiledata,
                                      size: isSmallScreen ? 24 : 32,
                                      color: FamingaBrandColors.primaryOrange,
                                    ),
                                    label: Text(
                                      AppLocalizations.of(context)?.googleSignIn ?? 'Sign in with Google',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                                      side: BorderSide(
                                        color: FamingaBrandColors.textPrimary.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    context.l10n.dontHaveAccount,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.toNamed(AppRoutes.register);
                                    },
                                    child: Text(
                                      context.l10n.register,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: FamingaBrandColors.primaryOrange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen ? 12 : 14,
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
                  ),
                ),
              ],
            );
          },
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

