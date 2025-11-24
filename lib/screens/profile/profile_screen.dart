import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:flutter/foundation.dart';
>>>>>>> hyacinthe
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
<<<<<<< HEAD
=======
import '../../utils/l10n_extensions.dart';
>>>>>>> hyacinthe

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
<<<<<<< HEAD
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
=======
        title: Text(context.l10n.profileTitle),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.edit),
          //   onPressed: () {
          //     Get.snackbar(
          //       'Edit Profile',
          //       'Profile editing coming soon!',
          //       snackPosition: SnackPosition.BOTTOM,
          //     );
          //   },
          // ),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                      'Personal Information',
                      'Update your personal details',
=======
                      context.l10n.personalInformation,
                      context.l10n.updatePersonalDetails,
>>>>>>> hyacinthe
                      () => Get.to(() => const EditProfileScreen()),
                    ),
                    _buildMenuItem(
                      Icons.lock_outline,
<<<<<<< HEAD
                      'Change Password',
                      'Update your password',
=======
                      context.l10n.changePassword,
                      context.l10n.secureYourAccount,
>>>>>>> hyacinthe
                      () => Get.to(() => const ChangePasswordScreen()),
                    ),
                    _buildMenuItem(
                      Icons.notifications_outlined,
<<<<<<< HEAD
                      'Notifications',
                      'Manage notification preferences',
=======
                      context.l10n.notificationSettings,
                      context.l10n.manageNotificationPreferences,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                      'Settings',
                      'App settings and preferences',
=======
                      context.l10n.appSettings,
                      context.l10n.appSection,
>>>>>>> hyacinthe
                      () {
                        Get.toNamed(AppRoutes.settings);
                      },
                    ),
                    _buildMenuItem(
                      Icons.help_outline,
<<<<<<< HEAD
                      'Help & Support',
                      'Get help and support',
=======
                      context.l10n.helpSupport,
                      context.l10n.getHelpSupport,
>>>>>>> hyacinthe
                      () => _showHelpAndSupport(),
                    ),
                    _buildMenuItem(
                      Icons.info_outline,
<<<<<<< HEAD
                      'About',
                      'About Faminga Irrigation',
=======
                      context.l10n.aboutFaminga,
                      context.l10n.aboutFamingaIrrigation,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                      'Logout',
                      'Sign out of your account',
=======
                      context.l10n.logout,
                      context.l10n.signOut,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
=======
    // Translate section titles
    String translatedTitle = title;
    if (title == 'Account') {
      translatedTitle = context.l10n.accountSection;
    } else if (title == 'App') {
      translatedTitle = context.l10n.appSection;
    } else if (title == 'Account Actions') {
      translatedTitle = context.l10n.accountActions;
    }
    
>>>>>>> hyacinthe
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
<<<<<<< HEAD
              title,
=======
              translatedTitle,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
=======
        title: Text(context.l10n.logoutTitle),
        content: Text(context.l10n.logoutConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.l10n.cancelButton),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                  'Success',
                  'You have been logged out successfully',
=======
                  context.l10n.success,
                  context.l10n.logoutSuccess,
>>>>>>> hyacinthe
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  colorText: Theme.of(context).colorScheme.onSecondary,
                );
              } catch (e) {
                Get.back(); // Close loading
                Get.snackbar(
<<<<<<< HEAD
                  'Error',
                  'Failed to logout: ${e.toString()}',
=======
                  context.l10n.error,
                  '${context.l10n.logoutFailed}: ${e.toString()}',
>>>>>>> hyacinthe
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
                );
              }
            },
<<<<<<< HEAD
            child: Text('Logout', style: TextStyle(color: Theme.of(context).colorScheme.error)),
=======
            child: Text(context.l10n.logoutButton, style: TextStyle(color: Theme.of(context).colorScheme.error)),
>>>>>>> hyacinthe
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
<<<<<<< HEAD
        title: const Text('About Faminga Irrigation'),
        content: const Column(
=======
        title: Text(context.l10n.aboutFamingaTitle),
        content: Column(
>>>>>>> hyacinthe
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
<<<<<<< HEAD
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
=======
            const SizedBox(height: 8),
            Text(context.l10n.famingaVersion),
            const SizedBox(height: 16),
            Text(context.l10n.famingaDescription),
            const SizedBox(height: 16),
            Text(
              context.l10n.famingaCopyright,
              style: const TextStyle(fontSize: 12),
>>>>>>> hyacinthe
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
<<<<<<< HEAD
            child: const Text('Close'),
=======
            child: Text(context.l10n.closeButton),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
=======
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
>>>>>>> hyacinthe
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
<<<<<<< HEAD
            const Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 18,
=======
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
              context.l10n.changeProfilePicture,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
>>>>>>> hyacinthe
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
<<<<<<< HEAD
              leading: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
              title: const Text('Take Photo'),
=======
              leading: Icon(Icons.camera_alt, color: scheme.primary),
              title: Text(context.l10n.takePhoto, style: TextStyle(color: scheme.onSurface)),
>>>>>>> hyacinthe
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
<<<<<<< HEAD
              leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
              title: const Text('Choose from Gallery'),
=======
              leading: Icon(Icons.photo_library, color: scheme.primary),
              title: Text(context.l10n.chooseFromGallery, style: TextStyle(color: scheme.onSurface)),
>>>>>>> hyacinthe
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
<<<<<<< HEAD
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: const Text('Remove Photo'),
=======
              leading: Icon(Icons.delete, color: scheme.error),
              title: Text(context.l10n.removePhoto, style: TextStyle(color: scheme.error)),
>>>>>>> hyacinthe
              onTap: () {
                Get.back();
                _removeProfilePicture();
              },
            ),
          ],
        ),
      ),
<<<<<<< HEAD
=======
      isDismissible: true,
      enableDrag: true,
>>>>>>> hyacinthe
    );
  }

  Future<void> _pickImage(ImageSource source) async {
<<<<<<< HEAD
=======
    bool isLoadingShown = false;
>>>>>>> hyacinthe
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
<<<<<<< HEAD
        // Show loading
          Get.dialog(Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
          barrierDismissible: false,
        );
=======
        if (!mounted) return;
        
        Get.dialog(
          Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
          barrierDismissible: false,
        );
        isLoadingShown = true;
>>>>>>> hyacinthe

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.userId;

        if (userId != null) {
<<<<<<< HEAD
          // Upload to Firebase Storage
          final AuthService authService = AuthService();
          final imageUrl = await authService.uploadProfilePicture(
            userId,
            File(image.path),
          );

          // Update Firestore
=======
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

>>>>>>> hyacinthe
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'avatar': imageUrl});

<<<<<<< HEAD
          // Reload user data
          await authProvider.loadUserData(userId);

          Get.back(); // Close loading
          Get.snackbar(
            'Success',
            'Profile picture updated successfully!',
=======
          await authProvider.loadUserData(userId);

          if (isLoadingShown) {
            Get.back();
            isLoadingShown = false;
          }

          if (!mounted) return;
          
          Get.snackbar(
            context.l10n.success,
            context.l10n.profilePictureUpdated,
>>>>>>> hyacinthe
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            colorText: Theme.of(context).colorScheme.onSecondary,
          );
<<<<<<< HEAD
        }
      }
    } catch (e) {
      Get.back(); // Close loading if open
      Get.snackbar(
        'Error',
=======
        } else {
          if (isLoadingShown) {
            Get.back();
            isLoadingShown = false;
          }
          Get.snackbar(
            context.l10n.error,
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
        context.l10n.error,
>>>>>>> hyacinthe
        'Failed to update profile picture: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
      );
    }
  }

  Future<void> _removeProfilePicture() async {
<<<<<<< HEAD
    try {
      // Show loading
      Get.dialog(Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        barrierDismissible: false,
      );
=======
    bool isLoadingShown = false;
    try {
      if (!mounted) return;
      
      Get.dialog(
        Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        barrierDismissible: false,
      );
      isLoadingShown = true;
>>>>>>> hyacinthe

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.userId;

      if (userId != null) {
<<<<<<< HEAD
        // Update Firestore
=======
>>>>>>> hyacinthe
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'avatar': null});

<<<<<<< HEAD
        // Reload user data
        await authProvider.loadUserData(userId);

        Get.back(); // Close loading
        Get.snackbar(
          'Success',
          'Profile picture removed!',
=======
        await authProvider.loadUserData(userId);

        if (isLoadingShown) {
          Get.back();
          isLoadingShown = false;
        }

        if (!mounted) return;
        
        Get.snackbar(
          context.l10n.success,
          context.l10n.profilePictureRemoved,
>>>>>>> hyacinthe
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          colorText: Theme.of(context).colorScheme.onSecondary,
        );
<<<<<<< HEAD
      }
    } catch (e) {
      Get.back(); // Close loading if open
      Get.snackbar(
        'Error',
=======
      } else {
        if (isLoadingShown) {
          Get.back();
          isLoadingShown = false;
        }
        Get.snackbar(
          context.l10n.error,
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
        context.l10n.error,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
        title: const Text('Edit Profile'),
=======
        title: Text(context.l10n.editProfileTitle),
>>>>>>> hyacinthe
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
<<<<<<< HEAD
                decoration: const InputDecoration(
                  labelText: 'First Name',
=======
                decoration: InputDecoration(
                  labelText: context.l10n.firstName,
>>>>>>> hyacinthe
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
<<<<<<< HEAD
                decoration: const InputDecoration(
                  labelText: 'Last Name',
=======
                decoration: InputDecoration(
                  labelText: context.l10n.lastName,
>>>>>>> hyacinthe
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
<<<<<<< HEAD
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
=======
                decoration: InputDecoration(
                  labelText: context.l10n.phoneNumberLabel,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
            child: const Text('Cancel'),
=======
            child: Text(context.l10n.cancelButton),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                    'Success',
                    'Profile updated successfully!',
=======
                    context.l10n.success,
                    context.l10n.profileUpdatedSuccess,
>>>>>>> hyacinthe
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    colorText: Theme.of(context).colorScheme.onSecondary,
                  );
                }
              } catch (e) {
                Get.back(); // Close loading
                Get.snackbar(
<<<<<<< HEAD
                  'Error',
                  'Failed to update profile: ${e.toString()}',
=======
                  context.l10n.error,
                  '${context.l10n.profileUpdateFailed}: ${e.toString()}',
>>>>>>> hyacinthe
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
                );
              }
            },
<<<<<<< HEAD
            child: const Text('Save'),
=======
            child: Text(context.l10n.saveButton),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
            title: const Text('Change Password'),
=======
            title: Text(context.l10n.changePasswordTitle),
>>>>>>> hyacinthe
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrentPassword,
                    decoration: InputDecoration(
<<<<<<< HEAD
                      labelText: 'Current Password',
=======
                      labelText: context.l10n.currentPassword,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                      labelText: 'New Password',
=======
                      labelText: context.l10n.newPassword,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                      labelText: 'Confirm Password',
=======
                      labelText: context.l10n.confirmNewPassword,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                child: const Text('Cancel'),
=======
                child: Text(context.l10n.cancelButton),
>>>>>>> hyacinthe
              ),
              TextButton(
                onPressed: () async {
                  if (newPasswordController.text.length < 6) {
                    Get.snackbar(
<<<<<<< HEAD
                      'Error',
                      'Password must be at least 6 characters',
=======
                      context.l10n.error,
                      context.l10n.passwordMinimumLength,
>>>>>>> hyacinthe
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                    return;
                  }

                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    Get.snackbar(
<<<<<<< HEAD
                      'Error',
                      'Passwords do not match',
=======
                      context.l10n.error,
                      context.l10n.passwordsDoNotMatchConfirm,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                      'Success',
                      'Password changed successfully!',
=======
                      context.l10n.success,
                      context.l10n.passwordChangedSuccess,
>>>>>>> hyacinthe
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      colorText: Theme.of(context).colorScheme.onSecondary,
                    );
                  } catch (e) {
                    Get.back(); // Close loading
<<<<<<< HEAD
                    Get.snackbar(
                      'Error',
                      e.toString(),
=======
                    String err = e.toString();
                    Get.snackbar(
                      context.l10n.error,
                      err,
>>>>>>> hyacinthe
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                  }
                },
<<<<<<< HEAD
                child: const Text('Change Password'),
=======
                child: Text(context.l10n.changePassword),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
              'Notification Settings',
=======
              context.l10n.notificationsTitle,
>>>>>>> hyacinthe
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(
<<<<<<< HEAD
                'Irrigation Alerts',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Get notified about irrigation schedules',
=======
                context.l10n.irrigationAlerts,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                context.l10n.irrigationAlertsDesc,
>>>>>>> hyacinthe
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: true,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                // TODO: Save to Firebase
                Get.snackbar(
<<<<<<< HEAD
                  'Settings Updated',
                  'Irrigation alerts ${value ? 'enabled' : 'disabled'}',
=======
                  context.l10n.settingsUpdated,
                  '${context.l10n.irrigationAlerts} ${value ? context.l10n.enabledSetting : context.l10n.disabledSetting}',
>>>>>>> hyacinthe
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: Text(
<<<<<<< HEAD
                'System Updates',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Get notified about system status changes',
=======
                context.l10n.systemUpdates,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                context.l10n.systemUpdatesDesc,
>>>>>>> hyacinthe
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: true,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                Get.snackbar(
<<<<<<< HEAD
                  'Settings Updated',
                  'System updates ${value ? 'enabled' : 'disabled'}',
=======
                  context.l10n.settingsUpdated,
                  '${context.l10n.systemUpdates} ${value ? context.l10n.enabledSetting : context.l10n.disabledSetting}',
>>>>>>> hyacinthe
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: Text(
<<<<<<< HEAD
                'Weather Alerts',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Get notified about weather conditions',
=======
                context.l10n.weatherAlerts,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                context.l10n.weatherAlertsDesc,
>>>>>>> hyacinthe
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: true,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                Get.snackbar(
<<<<<<< HEAD
                  'Settings Updated',
                  'Weather alerts ${value ? 'enabled' : 'disabled'}',
=======
                  context.l10n.settingsUpdated,
                  '${context.l10n.weatherAlerts} ${value ? context.l10n.enabledSetting : context.l10n.disabledSetting}',
>>>>>>> hyacinthe
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: Text(
<<<<<<< HEAD
                'Sensor Alerts',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Get notified about sensor readings',
=======
                context.l10n.sensorAlerts,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                context.l10n.sensorAlertsDesc,
>>>>>>> hyacinthe
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: false,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                Get.snackbar(
<<<<<<< HEAD
                  'Settings Updated',
                  'Sensor alerts ${value ? 'enabled' : 'disabled'}',
=======
                  context.l10n.settingsUpdated,
                  '${context.l10n.sensorAlerts} ${value ? context.l10n.enabledSetting : context.l10n.disabledSetting}',
>>>>>>> hyacinthe
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
<<<<<<< HEAD
              'Help & Support',
=======
              context.l10n.helpSupport,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                'Email Support',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'akariclaude@gmail.com',
=======
                context.l10n.emailSupport,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'info@faminga.app',
>>>>>>> hyacinthe
                style: textTheme.bodyMedium,
              ),
              onTap: () {
                Get.back();
                Get.snackbar(
<<<<<<< HEAD
                  'Contact Support',
                  'Opening email app...',
=======
                  context.l10n.openingEmailApp,
                  context.l10n.openingEmailApp,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                'Phone Support',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                '+250 XXX XXX XXX',
=======
                context.l10n.phoneSupport,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                '+250 796 882 585 ',
>>>>>>> hyacinthe
                style: textTheme.bodyMedium,
              ),
              onTap: () {
                Get.back();
                Get.snackbar(
<<<<<<< HEAD
                  'Contact Support',
                  'Opening phone app...',
=======
                  context.l10n.openingPhoneApp,
                  context.l10n.openingPhoneApp,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                'Visit Website',
=======
                context.l10n.visitWebsite,
>>>>>>> hyacinthe
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'faminga.app',
                style: textTheme.bodyMedium,
              ),
              onTap: () {
                Get.back();
                Get.snackbar(
<<<<<<< HEAD
                  'Opening Website',
                  'Launching browser...',
=======
                  context.l10n.launchingBrowser,
                  context.l10n.launchingBrowser,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                'FAQs',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Frequently asked questions',
=======
                context.l10n.faqs,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                context.l10n.frequentlyAskedQuestions,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
          'Frequently Asked Questions',
=======
          context.l10n.frequentlyAskedQuestions,
>>>>>>> hyacinthe
          style: textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem(
<<<<<<< HEAD
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
=======
                context.l10n.faqAddField,
                context.l10n.faqAddFieldAnswer,
              ),
              _buildFAQItem(
                context.l10n.faqScheduleIrrigation,
                context.l10n.faqScheduleIrrigationAnswer,
              ),
              _buildFAQItem(
                context.l10n.faqAddSensor,
                context.l10n.faqAddSensorAnswer,
              ),
              _buildFAQItem(
                context.l10n.faqChangePassword,
                context.l10n.faqChangePasswordAnswer,
>>>>>>> hyacinthe
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
<<<<<<< HEAD
              'Close',
=======
              context.l10n.closeButton,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
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
=======
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: context.l10n.dashboard,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.water_drop),
          label: context.l10n.irrigation,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.landscape),
          label: context.l10n.fields,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.sensors),
          label: context.l10n.sensors,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: context.l10n.profile,
>>>>>>> hyacinthe
        ),
      ],
    );
  }
}

