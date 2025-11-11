// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Faminga Irrigation';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get signInToManage => 'Sign in to manage your irrigation systems';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get login => 'Login';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get register => 'Register';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinFaminga => 'Join Faminga';

  @override
  String get startManaging => 'Start managing your irrigation smartly';

  @override
  String get firstName => 'First Name';

  @override
  String get enterFirstName => 'Enter your first name';

  @override
  String get lastName => 'Last Name';

  @override
  String get enterLastName => 'Enter your last name';

  @override
  String get phoneNumber => 'Phone Number (Optional)';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get reEnterPassword => 'Re-enter your password';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get enterEmailForReset =>
      'Enter your email address and we will send you a link to reset your password';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get irrigation => 'Irrigation';

  @override
  String get fields => 'Fields';

  @override
  String get sensors => 'Sensors';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get welcomeUser => 'Welcome back!';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get overview => 'Overview';

  @override
  String get recentActivities => 'Recent Activities';

  @override
  String get activeSystems => 'Active Systems';

  @override
  String get totalFields => 'Total Fields';

  @override
  String get waterSaved => 'Water Saved';

  @override
  String get activeSensors => 'Active Sensors';

  @override
  String get irrigationSystems => 'Irrigation Systems';

  @override
  String get addSystem => 'Add System';

  @override
  String get noIrrigationSystems => 'No irrigation systems yet';

  @override
  String get addFirstSystem =>
      'Add your first irrigation system to get started';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get type => 'Type';

  @override
  String get source => 'Source';

  @override
  String get mode => 'Mode';

  @override
  String get automated => 'Automated';

  @override
  String get manual => 'Manual';

  @override
  String get waterUsed => 'Water Used';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get loading => 'Loading...';

  @override
  String get refresh => 'Refresh';

  @override
  String get notifications => 'Notifications';

  @override
  String get accountCreatedSuccess =>
      'Account created successfully. Please check your email to verify your account.';

  @override
  String get emailSent => 'Email Sent';

  @override
  String get passwordResetSent =>
      'Password reset link has been sent to your email. Please check your inbox.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get update => 'Update';

  @override
  String get language => 'Language';

  @override
  String get startNow => 'Start Now';

  @override
  String get goToFields => 'Go to Fields';

  @override
  String get noFieldsFound => 'No fields found.';

  @override
  String get systemStatus => 'System Status';

  @override
  String get nextScheduleCycle => 'Next Schedule Cycle';

  @override
  String get weeklyPerformance => 'Weekly Performance';

  @override
  String get soilMoisture => 'Soil Moisture';

  @override
  String get averageToday => 'Average Today';

  @override
  String get noScheduledIrrigations => 'No scheduled irrigations';

  @override
  String get startIrrigationManually =>
      'Start irrigation manually or create a schedule';

  @override
  String get startCycleManually => 'START CYCLE MANUALLY';

  @override
  String get waterUsage => 'Water Usage';

  @override
  String get litersThisWeek => 'Liters this week';

  @override
  String get kshSaved => 'KSh Saved';

  @override
  String get thisWeek => 'This week';

  @override
  String get noFieldsTitle => 'No Fields Found';

  @override
  String get noFieldsMessage =>
      'You don\'t have any fields registered. Please create a field first to start manual irrigation.';

  @override
  String get alerts => 'Alerts';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get noAlertsYet => 'No alerts yet';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}min ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get manualStart => 'Manual Start';

  @override
  String get farmInfo => 'Farm Info';

  @override
  String get scheduled => 'Scheduled';
}
