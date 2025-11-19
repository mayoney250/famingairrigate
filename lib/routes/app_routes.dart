import 'package:get/get.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verification_pending_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/fields/add_field_screen.dart';
import '../screens/fields/add_field_with_map_screen.dart';
import '../screens/fields/fields_screen.dart';
import '../screens/irrigation/irrigation_list_screen.dart';
import '../screens/irrigation/irrigation_control_screen.dart';
import '../screens/irrigation/irrigation_planning_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../models/field_model.dart';
import '../screens/sensors/sensors_screen.dart';
import '../screens/sensors/sensor_detail_screen.dart';
import '../screens/alerts/alerts_list_screen.dart';
import '../screens/alerts/alert_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/notification_test_screen.dart';

class AppRoutes {
  // Private constructor
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String dashboard = '/dashboard';
  static const String irrigationList = '/irrigation-list';
  static const String irrigationControl = '/irrigation-control';
  static const String irrigationDetail = '/irrigation-detail';
  static const String irrigationPlanning = '/irrigation-planning';
  static const String addIrrigation = '/add-irrigation';
  static const String fields = '/fields';
  static const String addField = '/add-field';
  static const String sensors = '/sensors';
  static const String sensorDetail = '/sensor-detail';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String alerts = '/alerts';
  static const String alertDetail = '/alert-detail';
  static const String notificationTest = '/notification-test';

  // Route definitions
  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: register,
      page: () => const RegisterScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/verification-pending',
      page: () => const VerificationPendingScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: emailVerification,
      page: () => const EmailVerificationScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: irrigationList,
      page: () => const IrrigationListScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: irrigationControl,
      page: () => const IrrigationControlScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: irrigationPlanning,
      page: () {
        final field = Get.arguments as FieldModel;
        return IrrigationPlanningScreen(field: field);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: fields,
      page: () => const FieldsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: addField,
      page: () => const AddFieldWithMapScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: sensors,
      page: () => const SensorsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: sensorDetail,
      page: () => const SensorDetailScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: alerts,
      page: () => const AlertsListScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: alertDetail,
      page: () => const AlertDetailScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: notificationTest,
      page: () => const NotificationTestScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}

