import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

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
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: FamingaBrandColors.primaryOrange,
                        child: Text(
                          user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: FamingaBrandColors.white,
                          ),
                        ),
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
                      () {
                        Get.snackbar(
                          'Personal Info',
                          'Coming soon!',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    _buildMenuItem(
                      Icons.lock_outline,
                      'Change Password',
                      'Update your password',
                      () {
                        Get.snackbar(
                          'Change Password',
                          'Coming soon!',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    _buildMenuItem(
                      Icons.notifications_outline,
                      'Notifications',
                      'Manage notification preferences',
                      () {
                        Get.snackbar(
                          'Notifications',
                          'Coming soon!',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
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
                      () {
                        Get.snackbar(
                          'Help & Support',
                          'Coming soon!',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
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

