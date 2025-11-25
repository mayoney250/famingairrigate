import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../generated/app_localizations.dart';
import '../../utils/l10n_extensions.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isChecking = false;
  String? _message;

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
      _message = null;
    });

    try {
      final authService = AuthService();
      await authService.sendEmailVerification();
      
      if (mounted) {
        setState(() {
          _message = 'Verification email sent! Please check your inbox and spam folder.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error sending email: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      final authService = AuthService();
      final isVerified = await authService.isEmailVerified();
      
      if (mounted) {
        if (isVerified) {
          Get.offAllNamed(AppRoutes.dashboard);
        } else {
          setState(() {
            _message = 'Email not verified yet. Please check your email and click the verification link.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error checking verification: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userEmail = authProvider.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.verifyEmail ?? 'Verify Email'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Email icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 64,
                    color: FamingaBrandColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  AppLocalizations.of(context)?.verifyYourEmail ?? 'Verify Your Email',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: FamingaBrandColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  AppLocalizations.of(context)?.verificationEmailSentTo ?? 'We\'ve sent a verification email to:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: FamingaBrandColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Email address
                Text(
                  userEmail,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: FamingaBrandColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FamingaBrandColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: FamingaBrandColors.primaryOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: FamingaBrandColors.primaryOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.nextSteps ?? 'Next Steps:',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionItem(
                        AppLocalizations.of(context)?.checkEmailInbox ?? '1. Check your email inbox',
                      ),
                      _buildInstructionItem(
                        AppLocalizations.of(context)?.lookForFirebaseEmail ?? '2. Look for an email from Firebase',
                      ),
                      _buildInstructionItem(
                        AppLocalizations.of(context)?.checkSpamFolder ?? '3. Check your spam/junk folder',
                      ),
                      _buildInstructionItem(
                        AppLocalizations.of(context)?.clickVerificationLink ?? '4. Click the verification link',
                      ),
                      _buildInstructionItem(
                        AppLocalizations.of(context)?.returnAndClickVerified ?? '5. Return here and click "I\'ve Verified"',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Message
                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _message!.contains('Error')
                          ? FamingaBrandColors.statusWarning.withOpacity(0.1)
                          : FamingaBrandColors.statusSuccess.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _message!.contains('Error')
                                ? FamingaBrandColors.statusWarning
                                : FamingaBrandColors.statusSuccess,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Check Verification button
                CustomButton(
                  text: AppLocalizations.of(context)?.verifiedMyEmail ?? 'I\'ve Verified My Email',
                  onPressed: _checkVerification,
                  isLoading: _isChecking,
                ),
                const SizedBox(height: 16),

                // Resend email button
                OutlinedButton(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: FamingaBrandColors.primaryOrange,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FamingaBrandColors.primaryOrange,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)?.resendVerificationEmail ?? 'Resend Verification Email',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: FamingaBrandColors.primaryOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                ),
                const SizedBox(height: 24),

                // Logout button
                TextButton(
                  onPressed: () async {
                    await authProvider.signOut();
                    Get.offAllNamed(AppRoutes.login);
                  },
                  child: Text(
                    AppLocalizations.of(context)?.backToLogin ?? 'Back to Login',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: FamingaBrandColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: FamingaBrandColors.statusSuccess,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

