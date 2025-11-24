import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
<<<<<<< HEAD
import '../../config/colors.dart';
import '../../providers/theme_provider.dart';
=======
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../generated/app_localizations.dart';
import 'terms_and_services_screen.dart';
import 'privacy_policy_screen.dart';
import 'reports_screen.dart';
import 'download_data_screen.dart';
import 'dart:async';
>>>>>>> hyacinthe

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

<<<<<<< HEAD
class _SettingsScreenState extends State<SettingsScreen> {
=======
class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
>>>>>>> hyacinthe
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _autoIrrigation = true;
  String _themeMode = 'Light';
  String _temperatureUnit = 'Celsius';
<<<<<<< HEAD
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _themeMode = _themeModeFor(themeProvider.themeMode);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
=======
  late LanguageProvider _languageProvider;

  @override
  void initState() {
    super.initState();
    _languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // Called when system locale changes
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Listen to language changes and rebuild entire screen
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        print('SettingsScreen rebuilding with locale: ${languageProvider.currentLocale}');
        _languageProvider = languageProvider;
        return _buildScreen(context);
      },
    );
  }

  Widget _buildScreen(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _themeMode = _themeModeFor(themeProvider.themeMode);
    
    print('_buildScreen called, locale from provider: ${_languageProvider.currentLocale}');
    final appLocalizations = AppLocalizations.of(context);
    print('AppLocalizations.of(context) returned: ${appLocalizations?.runtimeType}');
    print('Localization locale: ${appLocalizations?.localeName}');
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(appLocalizations?.settings ?? 'Settings'),
>>>>>>> hyacinthe
      ),
      body: ListView(
        children: [
          _buildSection(
<<<<<<< HEAD
            'Notifications',
            [
              _buildSwitchTile(
                Icons.notifications_outlined,
                'Enable Notifications',
                'Receive notifications about your irrigation system',
=======
            appLocalizations?.notifications ?? 'Notifications',
            [
              _buildSwitchTile(
                Icons.notifications_outlined,
                appLocalizations?.enableNotifications ?? 'Enable Notifications',
                appLocalizations?.receiveNotifications ?? 'Receive notifications about your irrigation system',
>>>>>>> hyacinthe
                _notificationsEnabled,
                (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              _buildSwitchTile(
                Icons.email_outlined,
<<<<<<< HEAD
                'Email Notifications',
                'Receive email updates',
=======
                appLocalizations?.emailNotifications ?? 'Email Notifications',
                appLocalizations?.receiveEmailUpdates ?? 'Receive email updates',
>>>>>>> hyacinthe
                _emailNotifications,
                (value) {
                  setState(() => _emailNotifications = value);
                },
                enabled: _notificationsEnabled,
              ),
              _buildSwitchTile(
                Icons.phone_android,
<<<<<<< HEAD
                'Push Notifications',
                'Receive push notifications',
=======
                appLocalizations?.pushNotifications ?? 'Push Notifications',
                appLocalizations?.receivePushNotifications ?? 'Receive push notifications',
>>>>>>> hyacinthe
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
<<<<<<< HEAD
            'Irrigation',
            [
              _buildSwitchTile(
                Icons.water_drop_outlined,
                'Auto Irrigation',
                'Automatically irrigate based on sensor data',
=======
            appLocalizations?.irrigation ?? 'Irrigation',
            [
              _buildSwitchTile(
                Icons.water_drop_outlined,
                appLocalizations?.autoIrrigation ?? 'Auto Irrigation',
                appLocalizations?.autoIrrigationDesc ?? 'Automatically irrigate based on sensor data',
>>>>>>> hyacinthe
                _autoIrrigation,
                (value) {
                  setState(() => _autoIrrigation = value);
                },
              ),
<<<<<<< HEAD
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
=======
>>>>>>> hyacinthe
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
<<<<<<< HEAD
            'Preferences',
            [
              _buildDropdownTile(
                Icons.thermostat_outlined,
                'Temperature Unit',
=======
            appLocalizations?.preferences ?? 'Preferences',
            [
              _buildDropdownTile(
                Icons.thermostat_outlined,
                appLocalizations?.temperatureUnit ?? 'Temperature Unit',
>>>>>>> hyacinthe
                _temperatureUnit,
                ['Celsius', 'Fahrenheit'],
                (value) {
                  setState(() => _temperatureUnit = value!);
                },
              ),
              _buildDropdownTile(
                Icons.language,
<<<<<<< HEAD
                'Language',
                _language,
                ['English', 'French', 'Swahili', 'Kinyarwanda'],
                (value) {
                  setState(() => _language = value!);
=======
                appLocalizations?.language ?? 'Language',
                _languageProvider.currentLanguageName,
                ['English', 'French', 'Swahili', 'Kinyarwanda'],
                (value) async {
                  if (value == null) return;
                  print('========== LANGUAGE CHANGE INITIATED: $value ==========');
                  
                  // Change language in provider
                  await _languageProvider.setLanguage(value);
                  print('Language provider updated');
                  
                  // Force GetX to update
                  Get.updateLocale(_languageProvider.currentLocale);
                  print('GetX locale updated');
                  
                  // Force this screen rebuild
                  setState(() {});
                  print('SetState called');
                  
                  // Wait for rebuild
                  await Future.delayed(const Duration(milliseconds: 100));
                  
                  // Trigger another setState
                  if (mounted) {
                    setState(() {});
                    print('Second setState called');
                  }
                  
                  print('========== LANGUAGE CHANGE COMPLETED ==========');
>>>>>>> hyacinthe
                },
              ),
              _buildDropdownTile(
                Icons.dark_mode_outlined,
<<<<<<< HEAD
                'Theme',
=======
                appLocalizations?.theme ?? 'Theme',
>>>>>>> hyacinthe
                _themeMode,
                ['Light', 'Dark'],
                (value) async {
                  if (value == null) return;
                  setState(() => _themeMode = value);
<<<<<<< HEAD
                  await themeProvider.setThemeMode(_modeFor(value));
                  Get.snackbar(
                    'Theme updated',
                    'Theme set to ${value.toLowerCase()}',
=======
                  await Provider.of<ThemeProvider>(context, listen: false).setThemeMode(_modeFor(value));
                  Get.snackbar(
                    appLocalizations?.themeUpdated ?? 'Theme updated',
                    '${appLocalizations?.theme ?? 'Theme'} ${appLocalizations?.setTo ?? 'set to'} ${value.toLowerCase()}',
>>>>>>> hyacinthe
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
<<<<<<< HEAD
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
=======
            appLocalizations?.dataStorage ?? 'Data & Storage',
            [
              _buildListTile(
                Icons.assessment_outlined,
                appLocalizations?.reports ?? 'Reports',
                appLocalizations?.reportsDesc ?? 'View irrigation statistics and insights',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportsScreen()),
                  );
                },
              ),
              _buildListTile(
                Icons.download_outlined,
                'Download Data',
                'Generate and download irrigation reports',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DownloadDataScreen()),
>>>>>>> hyacinthe
                  );
                },
              ),
              _buildListTile(
                Icons.delete_outline,
<<<<<<< HEAD
                'Clear Cache',
                'Free up storage space',
                () {
                  _showClearCacheDialog();
=======
                appLocalizations?.clearCache ?? 'Clear Cache',
                appLocalizations?.clearCacheDesc ?? 'Free up storage space',
                () {
                  _showClearCacheDialog(context);
>>>>>>> hyacinthe
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
<<<<<<< HEAD
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
=======
            appLocalizations?.legal ?? 'Legal',
            [
              _buildListTile(
                Icons.description,
                appLocalizations?.termsAndServices ?? 'Terms and Services',
                appLocalizations?.viewTerms ?? 'View terms and services',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsAndServicesScreen()),
>>>>>>> hyacinthe
                  );
                },
              ),
              _buildListTile(
<<<<<<< HEAD
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
=======
                Icons.privacy_tip,
                appLocalizations?.privacyPolicy ?? 'Privacy and Policy',
                appLocalizations?.readPrivacy ?? 'Read our privacy policy',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
>>>>>>> hyacinthe
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

<<<<<<< HEAD
  void _showClearCacheDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached data and free up storage space. '
          'Your account data will not be affected.',
=======
  void _showClearCacheDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text(AppLocalizations.of(context)?.clearCache ?? 'Clear Cache'),
        content: Text(
          AppLocalizations.of(context)?.clearCacheWarning ?? 'This will remove all cached data and free up storage space. Your account data will not be affected.',
>>>>>>> hyacinthe
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
<<<<<<< HEAD
            child: const Text('Cancel'),
=======
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
>>>>>>> hyacinthe
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
<<<<<<< HEAD
                'Cache Cleared',
                'Cache has been cleared successfully!',
=======
                AppLocalizations.of(context)?.cacheCleared ?? 'Cache Cleared',
                AppLocalizations.of(context)?.cacheSuccessful ?? 'Cache has been cleared successfully!',
>>>>>>> hyacinthe
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
<<<<<<< HEAD
              'Clear',
=======
              AppLocalizations.of(context)?.clear ?? 'Clear',
>>>>>>> hyacinthe
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

