import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/theme_provider.dart';
import 'terms_and_services_screen.dart';
import 'privacy_policy_screen.dart';
import 'reports_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _autoIrrigation = true;
  String _themeMode = 'Light';
  String _temperatureUnit = 'Celsius';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _themeMode = _themeModeFor(themeProvider.themeMode);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            'Notifications',
            [
              _buildSwitchTile(
                Icons.notifications_outlined,
                'Enable Notifications',
                'Receive notifications about your irrigation system',
                _notificationsEnabled,
                (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              _buildSwitchTile(
                Icons.email_outlined,
                'Email Notifications',
                'Receive email updates',
                _emailNotifications,
                (value) {
                  setState(() => _emailNotifications = value);
                },
                enabled: _notificationsEnabled,
              ),
              _buildSwitchTile(
                Icons.phone_android,
                'Push Notifications',
                'Receive push notifications',
                _pushNotifications,
                (value) {
                  setState(() => _pushNotifications = value);
                },
                enabled: _notificationsEnabled,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Irrigation',
            [
              _buildSwitchTile(
                Icons.water_drop_outlined,
                'Auto Irrigation',
                'Automatically irrigate based on sensor data',
                _autoIrrigation,
                (value) {
                  setState(() => _autoIrrigation = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Preferences',
            [
              _buildDropdownTile(
                Icons.thermostat_outlined,
                'Temperature Unit',
                _temperatureUnit,
                ['Celsius', 'Fahrenheit'],
                (value) {
                  setState(() => _temperatureUnit = value!);
                },
              ),
              _buildDropdownTile(
                Icons.language,
                'Language',
                _language,
                ['English', 'French', 'Swahili', 'Kinyarwanda'],
                (value) {
                  setState(() => _language = value!);
                },
              ),
              _buildDropdownTile(
                Icons.dark_mode_outlined,
                'Theme',
                _themeMode,
                ['Light', 'Dark'],
                (value) async {
                  if (value == null) return;
                  setState(() => _themeMode = value);
                  await themeProvider.setThemeMode(_modeFor(value));
                  Get.snackbar(
                    'Theme updated',
                    'Theme set to ${value.toLowerCase()}',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Data & Storage',
            [
              _buildListTile(
                Icons.assessment_outlined,
                'Reports',
                'View irrigation statistics and insights',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportsScreen()),
                  );
                },
              ),
              _buildListTile(
                Icons.delete_outline,
                'Clear Cache',
                'Free up storage space',
                () {
                  _showClearCacheDialog();
                },
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // _buildSection(
          //   'Security',
          //   [
          //     _buildListTile(
          //       Icons.lock_outline,
          //       'Change Password',
          //       'Update your account password',
          //       () {
          //         Get.snackbar(
          //           'Change Password',
          //           'Password change coming soon!',
          //           snackPosition: SnackPosition.BOTTOM,
          //         );
          //       },
          //     ),
          //     _buildListTile(
          //       Icons.fingerprint,
          //       'Biometric Login',
          //       'Use fingerprint or face ID',
          //       () {
          //         Get.snackbar(
          //           'Biometric Login',
          //           'Biometric authentication coming soon!',
          //           snackPosition: SnackPosition.BOTTOM,
          //         );
          //       },
          //     ),
          //   ],
          // ),
          const SizedBox(height: 16),
          _buildSection(
            'Legal',
            [
              _buildListTile(
                Icons.description,
                'Terms and Services',
                'View terms and services',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsAndServicesScreen()),
                  );
                },
              ),
              _buildListTile(
                Icons.privacy_tip,
                'Privacy and Policy',
                'Read our privacy policy',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: enabled
            ? Theme.of(context).iconTheme.color
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile(
    IconData icon,
    String title,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _showClearCacheDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached data and free up storage space. '
          'Your account data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Cache Cleared',
                'Cache has been cleared successfully!',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
      default:
        return 'Light';
    }
  }

  ThemeMode _modeFor(String value) {
    switch (value) {
      case 'Dark':
        return ThemeMode.dark;
      case 'Light':
      default:
        return ThemeMode.light;
    }
  }
}

