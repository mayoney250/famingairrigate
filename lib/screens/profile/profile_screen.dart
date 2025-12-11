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
import '../../utils/l10n_extensions.dart';

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
                      context.l10n.personalInformation,
                      context.l10n.updatePersonalDetails,
                      () => Get.to(() => const EditProfileScreen()),
                    ),
                    _buildMenuItem(
                      Icons.lock_outline,
                      context.l10n.changePassword,
                      context.l10n.secureYourAccount,
                      () => Get.to(() => const ChangePasswordScreen()),
                    ),
                    _buildMenuItem(
                      Icons.notifications_outlined,
                      context.l10n.notificationSettings,
                      context.l10n.manageNotificationPreferences,
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
                      context.l10n.appSettings,
                      context.l10n.appSection,
                      () {
                        Get.toNamed(AppRoutes.settings);
                      },
                    ),
                    _buildMenuItem(
                      Icons.help_outline,
                      context.l10n.helpSupport,
                      context.l10n.getHelpSupport,
                      () => _showHelpAndSupport(),
                    ),
                    _buildMenuItem(
                      Icons.info_outline,
                      context.l10n.aboutFaminga,
                      context.l10n.aboutFamingaIrrigation,
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
                      context.l10n.logout,
                      context.l10n.signOut,
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
    // Translate section titles
    String translatedTitle = title;
    if (title == 'Account') {
      translatedTitle = context.l10n.accountSection;
    } else if (title == 'App') {
      translatedTitle = context.l10n.appSection;
    } else if (title == 'Account Actions') {
      translatedTitle = context.l10n.accountActions;
    }
    
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              translatedTitle,
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
        title: Text(context.l10n.logoutTitle),
        content: Text(context.l10n.logoutConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.l10n.cancelButton),
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
                  context.l10n.success,
                  context.l10n.logoutSuccess,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  colorText: Theme.of(context).colorScheme.onSecondary,
                );
              } catch (e) {
                Get.back(); // Close loading
                Get.snackbar(
                  context.l10n.error,
                  '${context.l10n.logoutFailed}: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
                );
              }
            },
            child: Text(context.l10n.logoutButton, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(context.l10n.aboutFamingaTitle),
        content: Column(
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
            const SizedBox(height: 8),
            Text(context.l10n.famingaVersion),
            const SizedBox(height: 16),
            Text(context.l10n.famingaDescription),
            const SizedBox(height: 16),
            Text(
              context.l10n.famingaCopyright,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.l10n.closeButton),
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
                    Expanded(
                      child: _buildStatItem(
                        Icons.landscape,
                        fieldsCount.toString(),
                        'Fields',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        Icons.water_drop,
                        irrigationCount.toString(),
                        'Systems',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        Icons.sensors,
                        sensorsCount.toString(),
                        'Sensors',
                      ),
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
              context.l10n.changeProfilePicture,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: scheme.primary),
              title: Text(context.l10n.takePhoto, style: TextStyle(color: scheme.onSurface)),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: scheme.primary),
              title: Text(context.l10n.chooseFromGallery, style: TextStyle(color: scheme.onSurface)),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: scheme.error),
              title: Text(context.l10n.removePhoto, style: TextStyle(color: scheme.error)),
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
            context.l10n.success,
            context.l10n.profilePictureUpdated,
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
          context.l10n.success,
          context.l10n.profilePictureRemoved,
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
        title: Text(context.l10n.editProfileTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: context.l10n.firstName,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: context.l10n.lastName,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: context.l10n.phoneNumberLabel,
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
            child: Text(context.l10n.cancelButton),
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
                    context.l10n.success,
                    context.l10n.profileUpdatedSuccess,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    colorText: Theme.of(context).colorScheme.onSecondary,
                  );
                }
              } catch (e) {
                Get.back(); // Close loading
                Get.snackbar(
                  context.l10n.error,
                  '${context.l10n.profileUpdateFailed}: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
                );
              }
            },
            child: Text(context.l10n.saveButton),
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
            title: Text(context.l10n.changePasswordTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: context.l10n.currentPassword,
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
                      labelText: context.l10n.newPassword,
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
                      labelText: context.l10n.confirmNewPassword,
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
                child: Text(context.l10n.cancelButton),
              ),
              TextButton(
                onPressed: () async {
                  if (newPasswordController.text.length < 6) {
                    Get.snackbar(
                      context.l10n.error,
                      context.l10n.passwordMinimumLength,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                    return;
                  }

                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    Get.snackbar(
                      context.l10n.error,
                      context.l10n.passwordsDoNotMatchConfirm,
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
                      context.l10n.success,
                      context.l10n.passwordChangedSuccess,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      colorText: Theme.of(context).colorScheme.onSecondary,
                    );
                  } catch (e) {
                    Get.back(); // Close loading
                    String err = e.toString();
                    Get.snackbar(
                      context.l10n.error,
                      err,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                  }
                },
                child: Text(context.l10n.changePassword),
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
              context.l10n.notificationsTitle,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                context.l10n.irrigationAlerts,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                context.l10n.irrigationAlertsDesc,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: true,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                // TODO: Save to Firebase
                Get.snackbar(
                  context.l10n.settingsUpdated,
                  '${context.l10n.irrigationAlerts} ${value ? context.l10n.enabledSetting : context.l10n.disabledSetting}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: Text(
                context.l10n.systemUpdates,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                context.l10n.systemUpdatesDesc,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: true,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                Get.snackbar(
                  context.l10n.settingsUpdated,
                  '${context.l10n.systemUpdates} ${value ? context.l10n.enabledSetting : context.l10n.disabledSetting}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: Text(
                context.l10n.weatherAlerts,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                context.l10n.weatherAlertsDesc,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: true,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                Get.snackbar(
                  context.l10n.settingsUpdated,
                  '${context.l10n.weatherAlerts} ${value ? context.l10n.enabledSetting : context.l10n.disabledSetting}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            SwitchListTile(
              title: Text(
                context.l10n.sensorAlerts,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                context.l10n.sensorAlertsDesc,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: false,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                Get.snackbar(
                  context.l10n.settingsUpdated,
                  '${context.l10n.sensorAlerts} ${value ? context.l10n.enabledSetting : context.l10n.disabledSetting}',
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
              context.l10n.helpSupport,
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
                context.l10n.emailSupport,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'info@faminga.app',
                style: textTheme.bodyMedium,
              ),
              onTap: () {
                Get.back();
                Get.snackbar(
                  context.l10n.openingEmailApp,
                  context.l10n.openingEmailApp,
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
                context.l10n.phoneSupport,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                '+250 796 882 585 ',
                style: textTheme.bodyMedium,
              ),
              onTap: () {
                Get.back();
                Get.snackbar(
                  context.l10n.openingPhoneApp,
                  context.l10n.openingPhoneApp,
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
                context.l10n.visitWebsite,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'faminga.app',
                style: textTheme.bodyMedium,
              ),
              onTap: () {
                Get.back();
                Get.snackbar(
                  context.l10n.launchingBrowser,
                  context.l10n.launchingBrowser,
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
                context.l10n.faqs,
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                context.l10n.frequentlyAskedQuestions,
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
          context.l10n.frequentlyAskedQuestions,
          style: textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem(
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
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              context.l10n.closeButton,
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
        ),
      ],
    );
  }
}

