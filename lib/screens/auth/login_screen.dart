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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
    
    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header with Language Selector
                      Align(
                        alignment: Alignment.topRight,
                        child: _buildCompactLanguageSelector(),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 16),
                      
                      // Main Content
                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo - Responsive sizing
                              Center(
                                child: Container(
                                  width: isSmallScreen ? 80 : 100,
                                  height: isSmallScreen ? 80 : 100,
                                  decoration: BoxDecoration(
                                    color: FamingaBrandColors.primaryOrange,
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                  ),
                                  child: Icon(
                                    Icons.water_drop,
                                    size: isSmallScreen ? 44 : 56,
                                    color: FamingaBrandColors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Welcome text - Responsive font sizes
                              Text(
                                context.l10n.welcomeBack,
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      color: FamingaBrandColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 24 : 32,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              Text(
                                context.l10n.signInToManage,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: FamingaBrandColors.textPrimary,
                                      fontSize: isSmallScreen ? 13 : 16,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isSmallScreen ? 32 : 48),
                              
                              // Email field
                              CustomTextField(
                                controller: _emailController,
                                label: context.l10n.email,
                                hintText: context.l10n.enterEmail,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return context.l10n.enterEmail;
                                  }
                                  if (!GetUtils.isEmail(value)) {
                                    return context.l10n.enterEmail;
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              
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
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              
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
                                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                                    child: Text(
                                      AppLocalizations.of(context)?.or ?? 'OR',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                    ),
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
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                                      side: BorderSide(
                                        color: FamingaBrandColors.textPrimary.withOpacity(0.3),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Register link - Flexible for small screens
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 4,
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
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactLanguageSelector() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
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
      offset: Offset(-(isSmallScreen ? 80.0 : 100.0), 40.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 6 : 8,
          vertical: isSmallScreen ? 4 : 6,
        ),
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
              style: TextStyle(fontSize: isSmallScreen ? 14 : 18),
            ),
            SizedBox(width: isSmallScreen ? 2 : 4),
            Icon(
              Icons.arrow_drop_down,
              color: FamingaBrandColors.primaryOrange,
              size: isSmallScreen ? 14 : 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => languages.map((lang) {
        return PopupMenuItem<String>(
          value: lang['code'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang['flag']!,
                style: const TextStyle(fontSize: 18),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Text(
                lang['code']!,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
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

