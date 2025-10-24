import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 4; // Profile is at index 4 in bottom nav

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.snackbar(
                'Edit Profile',
                'Profile editing coming soon!',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: FamingaBrandColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with edit button
                      Stack(
                        children: [
                          user?.avatar != null && user!.avatar!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: user.avatar!,
                                  imageBuilder: (context, imageProvider) => CircleAvatar(
                                    radius: 50,
                                    backgroundImage: imageProvider,
                                  ),
                                  placeholder: (context, url) => const CircleAvatar(
                                    radius: 50,
                                    backgroundColor: FamingaBrandColors.primaryOrange,
                                    child: CircularProgressIndicator(
                                      color: FamingaBrandColors.white,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => CircleAvatar(
                                    radius: 50,
                                    backgroundColor: FamingaBrandColors.primaryOrange,
                                    child: Text(
                                      (user?.firstName ?? 'U').substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: FamingaBrandColors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 50,
                                  backgroundColor: FamingaBrandColors.primaryOrange,
                                  child: Text(
                                    (user?.firstName ?? 'U').substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: FamingaBrandColors.white,
                                    ),
                                  ),
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showImagePicker(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: FamingaBrandColors.primaryOrange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: FamingaBrandColors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: FamingaBrandColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.fullName ?? 'User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: FamingaBrandColors.textSecondary,
                            ),
                      ),
                      if (user?.phoneNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          user!.phoneNumber!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: FamingaBrandColors.textSecondary,
                              ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      // User stats
                      _buildUserStats(user?.userId ?? ''),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Profile sections
                _buildSection(
                  'Account',
                  [
                    _buildMenuItem(
                      Icons.person_outline,
                      'Personal Information',
                      'Update your personal details',
                      () => _showEditProfileDialog(authProvider),
                    ),
                    _buildMenuItem(
                      Icons.lock_outline,
                      'Change Password',
                      'Update your password',
                      () => _showChangePasswordDialog(),
                    ),
                    _buildMenuItem(
                      Icons.notifications_outlined,
                      'Notifications',
                      'Manage notification preferences',
                      () => _showNotificationSettings(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSection(
                  'App',
                  [
                    _buildMenuItem(
                      Icons.settings_outlined,
                      'Settings',
                      'App settings and preferences',
                      () {
                        Get.toNamed(AppRoutes.settings);
                      },
                    ),
                    _buildMenuItem(
                      Icons.help_outline,
                      'Help & Support',
                      'Get help and support',
                      () => _showHelpAndSupport(),
                    ),
                    _buildMenuItem(
                      Icons.info_outline,
                      'About',
                      'About Faminga Irrigation',
                      () {
                        _showAboutDialog();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSection(
                  'Account Actions',
                  [
                    _buildMenuItem(
                      Icons.logout,
                      'Logout',
                      'Sign out of your account',
                      () {
                        _showLogoutDialog(authProvider);
                      },
                      isDestructive: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Container(
      color: FamingaBrandColors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FamingaBrandColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? FamingaBrandColors.statusWarning
            : FamingaBrandColors.iconColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? FamingaBrandColors.statusWarning : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: FamingaBrandColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog
              await authProvider.signOut();
              Get.offAllNamed(AppRoutes.login);
            },
            child: Text(
              'Logout',
              style: TextStyle(color: FamingaBrandColors.statusWarning),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('About Faminga Irrigation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faminga Irrigation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Version 1.0.0'),
            const SizedBox(height: 16),
            const Text(
              'Smart irrigation management system for African farmers.',
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2025 Faminga. All rights reserved.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fields')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, fieldsSnapshot) {
        final fieldsCount = fieldsSnapshot.hasData ? fieldsSnapshot.data!.docs.length : 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('irrigation')
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, irrigationSnapshot) {
            final irrigationCount = irrigationSnapshot.hasData ? irrigationSnapshot.data!.docs.length : 0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sensors')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, sensorsSnapshot) {
                final sensorsCount = sensorsSnapshot.hasData ? sensorsSnapshot.data!.docs.length : 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.landscape,
                      fieldsCount.toString(),
                      'Fields',
                    ),
                    _buildStatItem(
                      Icons.water_drop,
                      irrigationCount.toString(),
                      'Systems',
                    ),
                    _buildStatItem(
                      Icons.sensors,
                      sensorsCount.toString(),
                      'Sensors',
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FamingaBrandColors.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: FamingaBrandColors.primaryOrange,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FamingaBrandColors.darkGreen,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: FamingaBrandColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showImagePicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: FamingaBrandColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: FamingaBrandColors.primaryOrange,
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: FamingaBrandColors.primaryOrange,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete,
                color: FamingaBrandColors.statusWarning,
              ),
              title: const Text('Remove Photo'),
              onTap: () {
                Get.back();
                _removeProfilePicture();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Show loading
        Get.dialog(
          const Center(
            child: CircularProgressIndicator(),
          ),
          barrierDismissible: false,
        );

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.userId;

        if (userId != null) {
          // Upload to Firebase Storage
          final AuthService authService = AuthService();
          final imageUrl = await authService.uploadProfilePicture(
            userId,
            File(image.path),
          );

          // Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'avatar': imageUrl});

          // Reload user data
          await authProvider.loadUserData(userId);

          Get.back(); // Close loading
          Get.snackbar(
            'Success',
            'Profile picture updated successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: FamingaBrandColors.statusSuccess,
            colorText: FamingaBrandColors.white,
          );
        }
      }
    } catch (e) {
      Get.back(); // Close loading if open
      Get.snackbar(
        'Error',
        'Failed to update profile picture: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: FamingaBrandColors.statusWarning,
        colorText: FamingaBrandColors.white,
      );
    }
  }

  Future<void> _removeProfilePicture() async {
    try {
      // Show loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.userId;

      if (userId != null) {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'avatar': null});

        // Reload user data
        await authProvider.loadUserData(userId);

        Get.back(); // Close loading
        Get.snackbar(
          'Success',
          'Profile picture removed!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: FamingaBrandColors.statusSuccess,
          colorText: FamingaBrandColors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading if open
      Get.snackbar(
        'Error',
        'Failed to remove profile picture: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: FamingaBrandColors.statusWarning,
        colorText: FamingaBrandColors.white,
      );
    }
  }

  void _showEditProfileDialog(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final firstNameController = TextEditingController(text: user?.firstName ?? '');
    final lastNameController = TextEditingController(text: user?.lastName ?? '');
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixText: '+',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              
              // Show loading
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              try {
                final userId = user?.userId;
                if (userId != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({
                    'firstName': firstNameController.text.trim(),
                    'lastName': lastNameController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  await authProvider.loadUserData(userId);

                  Get.back(); // Close loading
                  Get.snackbar(
                    'Success',
                    'Profile updated successfully!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: FamingaBrandColors.statusSuccess,
                    colorText: FamingaBrandColors.white,
                  );
                }
              } catch (e) {
                Get.back(); // Close loading
                Get.snackbar(
                  'Error',
                  'Failed to update profile: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: FamingaBrandColors.statusWarning,
                  colorText: FamingaBrandColors.white,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrentPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureCurrentPassword = !obscureCurrentPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (newPasswordController.text.length < 6) {
                    Get.snackbar(
                      'Error',
                      'Password must be at least 6 characters',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: FamingaBrandColors.statusWarning,
                      colorText: FamingaBrandColors.white,
                    );
                    return;
                  }

                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    Get.snackbar(
                      'Error',
                      'Passwords do not match',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: FamingaBrandColors.statusWarning,
                      colorText: FamingaBrandColors.white,
                    );
                    return;
                  }

                  Get.back();

                  // Show loading
                  Get.dialog(
                    const Center(child: CircularProgressIndicator()),
                    barrierDismissible: false,
                  );

                  try {
                    final authService = AuthService();
                    await authService.changePassword(
                      currentPasswordController.text,
                      newPasswordController.text,
                    );

                    Get.back(); // Close loading
                    Get.snackbar(
                      'Success',
                      'Password changed successfully!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: FamingaBrandColors.statusSuccess,
                      colorText: FamingaBrandColors.white,
                    );
                  } catch (e) {
                    Get.back(); // Close loading
                    Get.snackbar(
                      'Error',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: FamingaBrandColors.statusWarning,
                      colorText: FamingaBrandColors.white,
                    );
                  }
                },
                child: const Text('Change Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNotificationSettings() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: FamingaBrandColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Irrigation Alerts'),
              subtitle: const Text('Get notified about irrigation schedules'),
              value: true,
              activeColor: FamingaBrandColors.primaryOrange,
              onChanged: (value) {
                // TODO: Save to Firebase
                Get.snackbar(
                  'Settings Updated',
                  'Irrigation alerts ${value ? 'enabled' : 'disabled'}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: const Text('System Updates'),
              subtitle: const Text('Get notified about system status changes'),
              value: true,
              activeColor: FamingaBrandColors.primaryOrange,
              onChanged: (value) {
                Get.snackbar(
                  'Settings Updated',
                  'System updates ${value ? 'enabled' : 'disabled'}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: const Text('Weather Alerts'),
              subtitle: const Text('Get notified about weather conditions'),
              value: true,
              activeColor: FamingaBrandColors.primaryOrange,
              onChanged: (value) {
                Get.snackbar(
                  'Settings Updated',
                  'Weather alerts ${value ? 'enabled' : 'disabled'}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: const Text('Sensor Alerts'),
              subtitle: const Text('Get notified about sensor readings'),
              value: false,
              activeColor: FamingaBrandColors.primaryOrange,
              onChanged: (value) {
                Get.snackbar(
                  'Settings Updated',
                  'Sensor alerts ${value ? 'enabled' : 'disabled'}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showHelpAndSupport() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: FamingaBrandColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.email,
                color: FamingaBrandColors.primaryOrange,
              ),
              title: const Text('Email Support'),
              subtitle: const Text('akariclaude@gmail.com'),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Contact Support',
                  'Opening email app...',
                  snackPosition: SnackPosition.BOTTOM,
                );
                // TODO: Launch email app
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.phone,
                color: FamingaBrandColors.primaryOrange,
              ),
              title: const Text('Phone Support'),
              subtitle: const Text('+250 XXX XXX XXX'),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Contact Support',
                  'Opening phone app...',
                  snackPosition: SnackPosition.BOTTOM,
                );
                // TODO: Launch phone app
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.language,
                color: FamingaBrandColors.primaryOrange,
              ),
              title: const Text('Visit Website'),
              subtitle: const Text('faminga.app'),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Opening Website',
                  'Launching browser...',
                  snackPosition: SnackPosition.BOTTOM,
                );
                // TODO: Launch browser
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.question_answer,
                color: FamingaBrandColors.primaryOrange,
              ),
              title: const Text('FAQs'),
              subtitle: const Text('Frequently asked questions'),
              onTap: () {
                Get.back();
                _showFAQs();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFAQs() {
    Get.dialog(
      AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem(
                'How do I add a field?',
                'Go to Fields tab → Tap the + button → Draw your field boundaries on the map.',
              ),
              _buildFAQItem(
                'How do I schedule irrigation?',
                'Go to Irrigation tab → Tap Schedule → Select field and set time.',
              ),
              _buildFAQItem(
                'How do I add sensors?',
                'Go to Sensors tab → Tap Add Sensor → Enter sensor details and location.',
              ),
              _buildFAQItem(
                'How do I change my password?',
                'Go to Profile → Change Password → Enter current and new password.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: FamingaBrandColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (index == _selectedIndex) return;

        setState(() => _selectedIndex = index);

        switch (index) {
          case 0:
            Get.offAllNamed(AppRoutes.dashboard);
            break;
          case 1:
            Get.offAllNamed(AppRoutes.irrigationList);
            break;
          case 2:
            Get.offAllNamed(AppRoutes.fields);
            break;
          case 3:
            Get.offAllNamed(AppRoutes.sensors);
            break;
          case 4:
            // Already on Profile
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: FamingaBrandColors.primaryOrange,
      unselectedItemColor: FamingaBrandColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop),
          label: 'Irrigation',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.landscape),
          label: 'Fields',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sensors),
          label: 'Sensors',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

