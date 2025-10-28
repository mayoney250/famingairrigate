import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/colors.dart';

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
  bool _darkMode = false;
  String _temperatureUnit = 'Celsius';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
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
              _buildListTile(
                Icons.schedule,
                'Irrigation Schedule',
                'Set up irrigation schedules',
                () {
                  Get.snackbar(
                    'Schedule',
                    'Irrigation schedule settings coming soon!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              _buildListTile(
                Icons.water,
                'Water Usage Goals',
                'Set water conservation targets',
                () {
                  Get.snackbar(
                    'Water Goals',
                    'Water usage goals coming soon!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
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
              _buildSwitchTile(
                Icons.dark_mode_outlined,
                'Dark Mode',
                'Use dark theme',
                _darkMode,
                (value) {
                  setState(() => _darkMode = value);
                  Get.snackbar(
                    'Dark Mode',
                    'Dark mode is coming soon!',
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
                Icons.cloud_download_outlined,
                'Download Data',
                'Export your irrigation data',
                () {
                  Get.snackbar(
                    'Download Data',
                    'Data export coming soon!',
                    snackPosition: SnackPosition.BOTTOM,
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
          const SizedBox(height: 16),
          _buildSection(
            'Security',
            [
              _buildListTile(
                Icons.lock_outline,
                'Change Password',
                'Update your account password',
                () {
                  Get.snackbar(
                    'Change Password',
                    'Password change coming soon!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              _buildListTile(
                Icons.fingerprint,
                'Biometric Login',
                'Use fingerprint or face ID',
                () {
                  Get.snackbar(
                    'Biometric Login',
                    'Biometric authentication coming soon!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'About',
            [
              _buildListTile(
                Icons.info_outline,
                'App Version',
                '1.0.0',
                null,
              ),
              _buildListTile(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                'Read our privacy policy',
                () {
                  Get.snackbar(
                    'Privacy Policy',
                    'Privacy policy coming soon!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              _buildListTile(
                Icons.description_outlined,
                'Terms of Service',
                'Read our terms of service',
                () {
                  Get.snackbar(
                    'Terms of Service',
                    'Terms of service coming soon!',
                    snackPosition: SnackPosition.BOTTOM,
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
      color: FamingaBrandColors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: const TextStyle(
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
            ? FamingaBrandColors.iconColor
            : FamingaBrandColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? null : FamingaBrandColors.textSecondary,
        ),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: FamingaBrandColors.primaryOrange,
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: FamingaBrandColors.iconColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: FamingaBrandColors.textSecondary)
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
      leading: Icon(icon, color: FamingaBrandColors.iconColor),
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
            child: const Text(
              'Clear',
              style: TextStyle(color: FamingaBrandColors.statusWarning),
            ),
          ),
        ],
      ),
    );
  }
}

