import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/colors.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _navigateToNextScreen();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

    // If user is authenticated, check whether they have a pending verification
    if (authProvider.isAuthenticated) {
      try {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
          final data = doc.data();
          final verificationStatus = data != null && data.containsKey('verificationStatus')
              ? (data['verificationStatus'] as String?)
              : null;

          if (verificationStatus != null && verificationStatus.toLowerCase() == 'pending') {
            Get.offAllNamed('/verification-pending');
            return;
          }
        }
      } catch (e) {
        // If anything goes wrong reading verification status we'll fall back to normal routing
      }

      // No pending verification found -> dashboard
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: FamingaBrandColors.primaryOrange,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.water_drop,
                  size: 64,
                  color: FamingaBrandColors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Faminga Irrigation',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: FamingaBrandColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart Farming, Smarter Irrigation',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: FamingaBrandColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  FamingaBrandColors.primaryOrange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

