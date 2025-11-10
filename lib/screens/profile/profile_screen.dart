import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                              placeholder: (context, url) => CircleAvatar(
                                    radius: 50,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                                  ),
                              errorWidget: (context, url, error) => CircleAvatar(
                                    radius: 50,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      (user.firstName ?? 'U').substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    (user?.firstName ?? 'U').substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimary,
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
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onPrimary,
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
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      if (user?.phoneNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          user!.phoneNumber!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                      () => Get.to(() => const EditProfileScreen()),
                    ),
                    _buildMenuItem(
                      Icons.lock_outline,
                      'Change Password',
                      'Update your password',
                      () => Get.to(() => const ChangePasswordScreen()),
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
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
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
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDestructive ? Theme.of(context).colorScheme.error : null,
            ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              
              // Show loading
              Get.dialog(
                Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                barrierDismissible: false,
              );

              try {
                await authProvider.signOut();
                
                Get.back(); // Close loading
                
                // Navigate to login
                Get.offAllNamed(AppRoutes.login);
                
                Get.snackbar(
                  'Success',
                  'You have been logged out successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  colorText: Theme.of(context).colorScheme.onSecondary,
                );
              } catch (e) {
                Get.back(); // Close loading
                Get.snackbar(
                  'Error',
                  'Failed to logout: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
                );
              }
            },
            child: Text('Logout', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('About Faminga Irrigation'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Faminga Irrigation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Smart irrigation management system for African farmers.',
            ),
            SizedBox(height: 16),
            Text(
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
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  void _showImagePicker() {
    final scheme = Theme.of(context).colorScheme;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Change Profile Picture',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: scheme.primary),
              title: Text('Take Photo', style: TextStyle(color: scheme.onSurface)),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: scheme.primary),
              title: Text('Choose from Gallery', style: TextStyle(color: scheme.onSurface)),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: scheme.error),
              title: Text('Remove Photo', style: TextStyle(color: scheme.error)),
              onTap: () {
                Get.back();
                _removeProfilePicture();
              },
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    bool isLoadingShown = false;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        if (!mounted) return;
        
        Get.dialog(
          Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
          barrierDismissible: false,
        );
        isLoadingShown = true;

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.userId;

        if (userId != null) {
          final AuthService authService = AuthService();
          String imageUrl;
          
          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            imageUrl = await authService.uploadProfilePictureBytes(
              userId,
              bytes,
              image.name,
            );
          } else {
            imageUrl = await authService.uploadProfilePicture(
              userId,
              File(image.path),
            );
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'avatar': imageUrl});

          await authProvider.loadUserData(userId);

          if (isLoadingShown) {
            Get.back();
            isLoadingShown = false;
          }

          if (!mounted) return;
          
          Get.snackbar(
            'Success',
            'Profile picture updated successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            colorText: Theme.of(context).colorScheme.onSecondary,
          );
        } else {
          if (isLoadingShown) {
            Get.back();
            isLoadingShown = false;
          }
          Get.snackbar(
            'Error',
            'User not found',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Theme.of(context).colorScheme.error,
            colorText: Theme.of(context).colorScheme.onError,
          );
        }
      }
    } catch (e) {
      if (isLoadingShown) {
        Get.back();
        isLoadingShown = false;
      }
      if (!mounted) return;
      Get.snackbar(
        'Error',
        'Failed to update profile picture: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
      );
    }
  }

  Future<void> _removeProfilePicture() async {
    bool isLoadingShown = false;
    try {
      if (!mounted) return;
      
      Get.dialog(
        Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        barrierDismissible: false,
      );
      isLoadingShown = true;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.userId;

      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'avatar': null});

        await authProvider.loadUserData(userId);

        if (isLoadingShown) {
          Get.back();
          isLoadingShown = false;
        }

        if (!mounted) return;
        
        Get.snackbar(
          'Success',
          'Profile picture removed!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          colorText: Theme.of(context).colorScheme.onSecondary,
        );
      } else {
        if (isLoadingShown) {
          Get.back();
          isLoadingShown = false;
        }
        Get.snackbar(
          'Error',
          'User not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
        );
      }
    } catch (e) {
      if (isLoadingShown) {
        Get.back();
        isLoadingShown = false;
      }
      if (!mounted) return;
      Get.snackbar(
        'Error',
        'Failed to remove profile picture: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
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
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    colorText: Theme.of(context).colorScheme.onSecondary,
                  );
                }
              } catch (e) {
                Get.back(); // Close loading
                Get.snackbar(
                  'Error',
                  'Failed to update profile: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
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
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                    return;
                  }

                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    Get.snackbar(
                      'Error',
                      'Passwords do not match',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
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
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      colorText: Theme.of(context).colorScheme.onSecondary,
                    );
                  } catch (e) {
                    Get.back(); // Close loading
                    Get.snackbar(
                      'Error',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                'Irrigation Alerts',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Get notified about irrigation schedules',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: true,
              activeThumbColor: scheme.primary,
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
              title: Text(
                'System Updates',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Get notified about system status changes',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: true,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                Get.snackbar(
                  'Settings Updated',
                  'System updates ${value ? 'enabled' : 'disabled'}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: Text(
                'Weather Alerts',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Get notified about weather conditions',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: true,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                Get.snackbar(
                  'Settings Updated',
                  'Weather alerts ${value ? 'enabled' : 'disabled'}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: Text(
                'Sensor Alerts',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Get notified about sensor readings',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: false,
              activeThumbColor: scheme.primary,
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.email,
                color: scheme.primary,
              ),
              title: Text(
                'Email Support',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'akariclaude@gmail.com',
                style: textTheme.bodyMedium,
              ),
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
              leading: Icon(
                Icons.phone,
                color: scheme.primary,
              ),
              title: Text(
                'Phone Support',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                '+250 XXX XXX XXX',
                style: textTheme.bodyMedium,
              ),
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
              leading: Icon(
                Icons.language,
                color: scheme.primary,
              ),
              title: Text(
                'Visit Website',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'faminga.app',
                style: textTheme.bodyMedium,
              ),
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
              leading: Icon(
                Icons.question_answer,
                color: scheme.primary,
              ),
              title: Text(
                'FAQs',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Frequently asked questions',
                style: textTheme.bodyMedium,
              ),
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          'Frequently Asked Questions',
          style: textTheme.titleLarge,
        ),
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
            child: Text(
              'Close',
              style: TextStyle(color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
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
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
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

