import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../generated/app_localizations.dart';
import 'terms_and_services_screen.dart';
import 'privacy_policy_screen.dart';
import 'reports_screen.dart';
<<<<<<< HEAD
import 'download_data_screen.dart';
=======
>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _autoIrrigation = true;
  String _themeMode = 'Light';
  String _temperatureUnit = 'Celsius';
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
      ),
      body: ListView(
        children: [
          _buildSection(
            appLocalizations?.notifications ?? 'Notifications',
            [
              _buildSwitchTile(
                Icons.notifications_outlined,
                appLocalizations?.enableNotifications ?? 'Enable Notifications',
                appLocalizations?.receiveNotifications ?? 'Receive notifications about your irrigation system',
                _notificationsEnabled,
                (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              _buildSwitchTile(
                Icons.email_outlined,
                appLocalizations?.emailNotifications ?? 'Email Notifications',
                appLocalizations?.receiveEmailUpdates ?? 'Receive email updates',
                _emailNotifications,
                (value) {
                  setState(() => _emailNotifications = value);
                },
                enabled: _notificationsEnabled,
              ),
              _buildSwitchTile(
                Icons.phone_android,
                appLocalizations?.pushNotifications ?? 'Push Notifications',
                appLocalizations?.receivePushNotifications ?? 'Receive push notifications',
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
            appLocalizations?.irrigation ?? 'Irrigation',
            [
              _buildSwitchTile(
                Icons.water_drop_outlined,
                appLocalizations?.autoIrrigation ?? 'Auto Irrigation',
                appLocalizations?.autoIrrigationDesc ?? 'Automatically irrigate based on sensor data',
                _autoIrrigation,
                (value) {
                  setState(() => _autoIrrigation = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            appLocalizations?.preferences ?? 'Preferences',
            [
              _buildDropdownTile(
                Icons.thermostat_outlined,
                appLocalizations?.temperatureUnit ?? 'Temperature Unit',
                _temperatureUnit,
                ['Celsius', 'Fahrenheit'],
                (value) {
                  setState(() => _temperatureUnit = value!);
                },
              ),
              _buildDropdownTile(
                Icons.language,
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
                },
              ),
              _buildDropdownTile(
                Icons.dark_mode_outlined,
                appLocalizations?.theme ?? 'Theme',
                _themeMode,
                ['Light', 'Dark'],
                (value) async {
                  if (value == null) return;
                  setState(() => _themeMode = value);
                  await Provider.of<ThemeProvider>(context, listen: false).setThemeMode(_modeFor(value));
                  Get.snackbar(
                    appLocalizations?.themeUpdated ?? 'Theme updated',
                    '${appLocalizations?.theme ?? 'Theme'} ${appLocalizations?.setTo ?? 'set to'} ${value.toLowerCase()}',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
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
<<<<<<< HEAD
                Icons.download_outlined,
                'Download Data',
                'Generate and download irrigation reports',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DownloadDataScreen()),
                  );
                },
              ),
              _buildListTile(
=======
>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4
                Icons.delete_outline,
                appLocalizations?.clearCache ?? 'Clear Cache',
                appLocalizations?.clearCacheDesc ?? 'Free up storage space',
                () {
                  _showClearCacheDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
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
                  );
                },
              ),
              _buildListTile(
                Icons.privacy_tip,
                appLocalizations?.privacyPolicy ?? 'Privacy and Policy',
                appLocalizations?.readPrivacy ?? 'Read our privacy policy',
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

  void _showClearCacheDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text(AppLocalizations.of(context)?.clearCache ?? 'Clear Cache'),
        content: Text(
          AppLocalizations.of(context)?.clearCacheWarning ?? 'This will remove all cached data and free up storage space. Your account data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                AppLocalizations.of(context)?.cacheCleared ?? 'Cache Cleared',
                AppLocalizations.of(context)?.cacheSuccessful ?? 'Cache has been cleared successfully!',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
              AppLocalizations.of(context)?.clear ?? 'Clear',
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

