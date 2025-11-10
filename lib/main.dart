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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
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
          );
        },
      ),
    );
  }
}
