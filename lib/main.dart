import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/alert_model.dart';
import 'models/sensor_model.dart';
import 'models/sensor_reading_model.dart';
import 'models/user_model.dart';
import 'config/firebase_config.dart';
import 'config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_routes.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseConfig.initialize();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AlertModelAdapter());
  Hive.registerAdapter(SensorModelAdapter());
  Hive.registerAdapter(SensorReadingModelAdapter());
  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<AlertModel>('alertsBox');
  await Hive.openBox<SensorModel>('sensorsBox');
  await Hive.openBox<SensorReadingModel>('readingsBox');
  await Hive.openBox<UserModel>('userBox');

  // Load persisted locale before starting the app to avoid UI flash
  final localeProvider = LocaleProvider();
  await localeProvider.loadLocale();

  // Pass the pre-loaded provider instance into the app so it can be provided to the tree
  runApp(FamingaIrrigationApp(localeProvider: localeProvider));
}

class FamingaIrrigationApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  const FamingaIrrigationApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Provide the pre-loaded LocaleProvider instance
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return GetMaterialApp(
            title: 'Faminga Irrigation',
            debugShowCheckedModeBanner: false,

            // Theme Configuration
            theme: ThemeConfig.lightTheme,
            darkTheme: ThemeConfig.darkTheme,
            themeMode: themeProvider.themeMode,

            // Routing
            initialRoute: AppRoutes.splash,
            getPages: AppRoutes.routes,

            // Localization wiring
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (localeProvider.locale != null) return localeProvider.locale;
              if (deviceLocale == null) return supportedLocales.first;
              for (final locale in supportedLocales) {
                if (locale.languageCode == deviceLocale.languageCode) return locale;
              }
              return supportedLocales.first;
            }, 
            // locale: languageProvider.currentLocale,
            // localizationsDelegates: AppLocalizations.localizationsDelegates,
            // supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
