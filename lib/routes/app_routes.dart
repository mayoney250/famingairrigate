import 'package:get/get.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/irrigation/irrigation_list_screen.dart';
import '../screens/splash_screen.dart';

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
  static const String irrigationDetail = '/irrigation-detail';
  static const String addIrrigation = '/add-irrigation';
  static const String fields = '/fields';
  static const String sensors = '/sensors';
  static const String profile = '/profile';
  static const String settings = '/settings';

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
  ];
}

