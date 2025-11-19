import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'models/alert_model.dart';
import 'models/sensor_model.dart';
import 'models/sensor_reading_model.dart';
import 'models/user_model.dart';
import 'models/sync_queue_item_model.dart';
import 'models/sync_queue_item_adapter.dart';
import 'config/firebase_config.dart';
import 'config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/connectivity_provider.dart';
import 'routes/app_routes.dart';
import 'services/fcm_service.dart';
import 'services/cache_repository.dart';
// FIXED: Changed import path to Flutter's generated location
import 'generated/app_localizations.dart';
     
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseConfig.initialize();
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseConfig.initialize();
  
  // Initialize FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AlertModelAdapter());
  Hive.registerAdapter(SensorModelAdapter());
  Hive.registerAdapter(SensorReadingModelAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(SyncQueueItemAdapter());
  await Hive.openBox<AlertModel>('alertsBox');
  await Hive.openBox<SensorModel>('sensorsBox');
  await Hive.openBox<SensorReadingModel>('readingsBox');
  await Hive.openBox<UserModel>('userBox');
  
  // Initialize offline-first cache system
  final cacheRepo = CacheRepository();
  await cacheRepo.initialize();

  runApp(const FamingaIrrigationApp());
}

class FamingaIrrigationApp extends StatelessWidget {
  const FamingaIrrigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = ConnectivityProvider();
            provider.initialize();
            return provider;
          },
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          return _AppLocaleWrapper(
            locale: languageProvider.currentLocale,
            child: GetMaterialApp(
              title: 'Faminga Irrigation',
              debugShowCheckedModeBanner: false,

              // Theme Configuration
              theme: ThemeConfig.lightTheme,
              darkTheme: ThemeConfig.darkTheme,
              themeMode: themeProvider.themeMode,

              // Localization
              locale: languageProvider.currentLocale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                _FallbackMaterialLocalizationsDelegate(),
                _FallbackCupertinoLocalizationsDelegate(),
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('fr'),
                Locale('rw'),
                Locale('sw'),
              ],
              fallbackLocale: const Locale('en'),
                                                                                                                                                                                                             
              // Routing
              initialRoute: AppRoutes.splash,
              getPages: AppRoutes.routes,
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper widget that ensures all descendants rebuild when locale changes
class _AppLocaleWrapper extends StatefulWidget {
  final Locale locale;
  final Widget child;

  const _AppLocaleWrapper({
    required this.locale,
    required this.child,
  });

  @override
  State<_AppLocaleWrapper> createState() => _AppLocaleWrapperState();
}

class _AppLocaleWrapperState extends State<_AppLocaleWrapper> {
  late Locale _currentLocale;

  @override
  void initState() {
    super.initState();
    _currentLocale = widget.locale;
  }

  @override
  void didUpdateWidget(_AppLocaleWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When locale changes, trigger a rebuild
    if (oldWidget.locale != widget.locale) {
      _currentLocale = widget.locale;
      print('_AppLocaleWrapper: Locale changed to $_currentLocale');
      // Rebuild the wrapper to force GetMaterialApp to see new locale
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('_AppLocaleWrapper building with locale: $_currentLocale');
    // Return child directly with a key to force rebuild
    // The key changes whenever locale changes, forcing GetMaterialApp to rebuild
    return KeyedSubtree(
      key: ValueKey<String>(_currentLocale.languageCode),
      child: widget.child,
    );
  }
}

/// Fallback delegate for Material localizations for unsupported locales
class _FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support rw and sw by falling back to English
    return locale.languageCode == 'rw' || locale.languageCode == 'sw';
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return DefaultMaterialLocalizations.load(
      const Locale('en'),
    );
  }

  @override
  bool shouldReload(_FallbackMaterialLocalizationsDelegate old) => false;
}

/// Fallback delegate for locales not supported by Flutter's built-in localizations
class _FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support rw and sw by falling back to English
    return locale.languageCode == 'rw' || locale.languageCode == 'sw';
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return DefaultCupertinoLocalizations.load(
      const Locale('en'),
    );
  }

  @override
  bool shouldReload(_FallbackCupertinoLocalizationsDelegate old) => false;
}