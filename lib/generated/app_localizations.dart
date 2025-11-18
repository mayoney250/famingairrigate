import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_rw.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('rw'),
    Locale('sw')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Faminga Irrigation'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @signInToManage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your irrigation systems'**
  String get signInToManage;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinFaminga.
  ///
  /// In en, this message translates to:
  /// **'Join Faminga'**
  String get joinFaminga;

  /// No description provided for @startManaging.
  ///
  /// In en, this message translates to:
  /// **'Start managing your irrigation smartly'**
  String get startManaging;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get enterFirstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @enterLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get enterLastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @reEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reEnterPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterEmailForReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we will send you a link to reset your password'**
  String get enterEmailForReset;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @irrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigation;

  /// No description provided for @fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fields;

  /// No description provided for @sensors.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get sensors;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeUser;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// No description provided for @activeSystems.
  ///
  /// In en, this message translates to:
  /// **'Active Systems'**
  String get activeSystems;

  /// No description provided for @totalFields.
  ///
  /// In en, this message translates to:
  /// **'Total Fields'**
  String get totalFields;

  /// No description provided for @waterSaved.
  ///
  /// In en, this message translates to:
  /// **'Water Saved'**
  String get waterSaved;

  /// No description provided for @activeSensors.
  ///
  /// In en, this message translates to:
  /// **'Active Sensors'**
  String get activeSensors;

  /// No description provided for @irrigationSystems.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Systems'**
  String get irrigationSystems;

  /// No description provided for @addSystem.
  ///
  /// In en, this message translates to:
  /// **'Add System'**
  String get addSystem;

  /// No description provided for @noIrrigationSystems.
  ///
  /// In en, this message translates to:
  /// **'No irrigation systems yet'**
  String get noIrrigationSystems;

  /// No description provided for @addFirstSystem.
  ///
  /// In en, this message translates to:
  /// **'Add your first irrigation system to get started'**
  String get addFirstSystem;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @automated.
  ///
  /// In en, this message translates to:
  /// **'Automated'**
  String get automated;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @waterUsed.
  ///
  /// In en, this message translates to:
  /// **'Water Used'**
  String get waterUsed;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully. Please check your email to verify your account.'**
  String get accountCreatedSuccess;

  /// No description provided for @emailSent.
  ///
  /// In en, this message translates to:
  /// **'Email Sent'**
  String get emailSent;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link has been sent to your email. Please check your inbox.'**
  String get passwordResetSent;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get startNow;

  /// No description provided for @goToFields.
  ///
  /// In en, this message translates to:
  /// **'Go to Fields'**
  String get goToFields;

  /// No description provided for @noFieldsFound.
  ///
  /// In en, this message translates to:
  /// **'No fields found.'**
  String get noFieldsFound;

  /// No description provided for @systemStatus.
  ///
  /// In en, this message translates to:
  /// **'System Status'**
  String get systemStatus;

  /// No description provided for @nextScheduleCycle.
  ///
  /// In en, this message translates to:
  /// **'Next Schedule Cycle'**
  String get nextScheduleCycle;

  /// No description provided for @weeklyPerformance.
  ///
  /// In en, this message translates to:
  /// **'Weekly Performance'**
  String get weeklyPerformance;

  /// No description provided for @soilMoisture.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture'**
  String get soilMoisture;

  /// No description provided for @averageToday.
  ///
  /// In en, this message translates to:
  /// **'Average Today'**
  String get averageToday;

  /// No description provided for @soilWaterLabel.
  ///
  /// In en, this message translates to:
  /// **'Soil Water'**
  String get soilWaterLabel;

  /// No description provided for @tempLabel.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get tempLabel;

  /// No description provided for @waterUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Water Used'**
  String get waterUsedLabel;

  /// No description provided for @soilDryMsg.
  ///
  /// In en, this message translates to:
  /// **'Soil is dry – it\'s time to irrigate.'**
  String get soilDryMsg;

  /// No description provided for @soilTooWetMsg.
  ///
  /// In en, this message translates to:
  /// **'Soil is too wet – check drainage.'**
  String get soilTooWetMsg;

  /// No description provided for @soilOptimalMsg.
  ///
  /// In en, this message translates to:
  /// **'Soil conditions are optimal – no action needed.'**
  String get soilOptimalMsg;

  /// No description provided for @noScheduledIrrigations.
  ///
  /// In en, this message translates to:
  /// **'No scheduled irrigations'**
  String get noScheduledIrrigations;

  /// No description provided for @startIrrigationManually.
  ///
  /// In en, this message translates to:
  /// **'Start irrigation manually or create a schedule'**
  String get startIrrigationManually;

  /// No description provided for @startCycleManually.
  ///
  /// In en, this message translates to:
  /// **'START CYCLE MANUALLY'**
  String get startCycleManually;

  /// No description provided for @waterUsage.
  ///
  /// In en, this message translates to:
  /// **'Water Usage'**
  String get waterUsage;

  /// No description provided for @litersThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Liters this week'**
  String get litersThisWeek;

  /// No description provided for @kshSaved.
  ///
  /// In en, this message translates to:
  /// **'KSh Saved'**
  String get kshSaved;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @noFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Fields Found'**
  String get noFieldsTitle;

  /// No description provided for @noFieldsMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any fields registered. Please create a field first to start manual irrigation.'**
  String get noFieldsMessage;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// No description provided for @noAlertsYet.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet'**
  String get noAlertsYet;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}min ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @manualStart.
  ///
  /// In en, this message translates to:
  /// **'Manual Start'**
  String get manualStart;

  /// No description provided for @farmInfo.
  ///
  /// In en, this message translates to:
  /// **'Farm Info'**
  String get farmInfo;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @pleaseEnterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get pleaseEnterFirstName;

  /// No description provided for @pleaseEnterLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get pleaseEnterLastName;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @pleaseEnterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhoneNumber;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @chooseProvince.
  ///
  /// In en, this message translates to:
  /// **'Choose a province'**
  String get chooseProvince;

  /// No description provided for @chooseDistrict.
  ///
  /// In en, this message translates to:
  /// **'Choose a district'**
  String get chooseDistrict;

  /// No description provided for @chooseProvinceFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a province first'**
  String get chooseProvinceFirst;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Village, Cell, Sector'**
  String get addressHint;

  /// No description provided for @addressTooShort.
  ///
  /// In en, this message translates to:
  /// **'Address too short'**
  String get addressTooShort;

  /// No description provided for @addressTooLong.
  ///
  /// In en, this message translates to:
  /// **'Address too long'**
  String get addressTooLong;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email'**
  String get failedToSendResetEmail;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @verificationEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification email to:'**
  String get verificationEmailSentTo;

  /// No description provided for @nextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next Steps:'**
  String get nextSteps;

  /// No description provided for @checkEmailInbox.
  ///
  /// In en, this message translates to:
  /// **'1. Check your email inbox'**
  String get checkEmailInbox;

  /// No description provided for @lookForFirebaseEmail.
  ///
  /// In en, this message translates to:
  /// **'2. Look for an email from Firebase'**
  String get lookForFirebaseEmail;

  /// No description provided for @checkSpamFolder.
  ///
  /// In en, this message translates to:
  /// **'3. Check your spam/junk folder'**
  String get checkSpamFolder;

  /// No description provided for @clickVerificationLink.
  ///
  /// In en, this message translates to:
  /// **'4. Click the verification link'**
  String get clickVerificationLink;

  /// No description provided for @returnAndClickVerified.
  ///
  /// In en, this message translates to:
  /// **'5. Return here and click \"I\'ve Verified\"'**
  String get returnAndClickVerified;

  /// No description provided for @verifiedMyEmail.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Verified My Email'**
  String get verifiedMyEmail;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get resendVerificationEmail;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @errorSendingEmail.
  ///
  /// In en, this message translates to:
  /// **'Error sending email'**
  String get errorSendingEmail;

  /// No description provided for @emailNotVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet. Please check your email and click the verification link.'**
  String get emailNotVerifiedYet;

  /// No description provided for @errorCheckingVerification.
  ///
  /// In en, this message translates to:
  /// **'Error checking verification'**
  String get errorCheckingVerification;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent! Please check your inbox and spam folder.'**
  String get verificationEmailSent;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @receiveNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications about your irrigation system'**
  String get receiveNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @receiveEmailUpdates.
  ///
  /// In en, this message translates to:
  /// **'Receive email updates'**
  String get receiveEmailUpdates;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receivePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications'**
  String get receivePushNotifications;

  /// No description provided for @autoIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Auto Irrigation'**
  String get autoIrrigation;

  /// No description provided for @autoIrrigationDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically irrigate based on sensor data'**
  String get autoIrrigationDesc;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @temperatureUnit.
  ///
  /// In en, this message translates to:
  /// **'Temperature Unit'**
  String get temperatureUnit;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Theme updated'**
  String get themeUpdated;

  /// No description provided for @setTo.
  ///
  /// In en, this message translates to:
  /// **'set to'**
  String get setTo;

  /// No description provided for @dataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dataStorage;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @reportsDesc.
  ///
  /// In en, this message translates to:
  /// **'View irrigation statistics and insights'**
  String get reportsDesc;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Free up storage space'**
  String get clearCacheDesc;

  /// No description provided for @clearCacheWarning.
  ///
  /// In en, this message translates to:
  /// **'This will remove all cached data and free up storage space. Your account data will not be affected.'**
  String get clearCacheWarning;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache Cleared'**
  String get cacheCleared;

  /// No description provided for @cacheSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Cache has been cleared successfully!'**
  String get cacheSuccessful;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @termsAndServices.
  ///
  /// In en, this message translates to:
  /// **'Terms and Services'**
  String get termsAndServices;

  /// No description provided for @viewTerms.
  ///
  /// In en, this message translates to:
  /// **'View terms and services'**
  String get viewTerms;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Policy'**
  String get privacyPolicy;

  /// No description provided for @readPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacy;

  /// No description provided for @sensorInformation.
  ///
  /// In en, this message translates to:
  /// **'Sensor Information'**
  String get sensorInformation;

  /// No description provided for @sensorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Sensor Name/Label'**
  String get sensorNameLabel;

  /// No description provided for @hardwareIdSerial.
  ///
  /// In en, this message translates to:
  /// **'Hardware ID/Serial'**
  String get hardwareIdSerial;

  /// No description provided for @pairingMethod.
  ///
  /// In en, this message translates to:
  /// **'Pairing Method'**
  String get pairingMethod;

  /// No description provided for @bleOption.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth (BLE)'**
  String get bleOption;

  /// No description provided for @wifiOption.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get wifiOption;

  /// No description provided for @loraOption.
  ///
  /// In en, this message translates to:
  /// **'LoRaWAN Gateway'**
  String get loraOption;

  /// No description provided for @bleMacAddress.
  ///
  /// In en, this message translates to:
  /// **'BLE MAC Address'**
  String get bleMacAddress;

  /// No description provided for @wifiSsid.
  ///
  /// In en, this message translates to:
  /// **'WiFi SSID'**
  String get wifiSsid;

  /// No description provided for @gatewayIdName.
  ///
  /// In en, this message translates to:
  /// **'Gateway ID/Name'**
  String get gatewayIdName;

  /// No description provided for @advancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Advanced Options'**
  String get advancedOptions;

  /// No description provided for @pairingNoteCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing Note/Code (Optional)'**
  String get pairingNoteCode;

  /// No description provided for @wifiPassword.
  ///
  /// In en, this message translates to:
  /// **'WiFi Password (Optional)'**
  String get wifiPassword;

  /// No description provided for @loraNetworkId.
  ///
  /// In en, this message translates to:
  /// **'LoRaWAN Network ID (Optional)'**
  String get loraNetworkId;

  /// No description provided for @channel.
  ///
  /// In en, this message translates to:
  /// **'Channel (Optional)'**
  String get channel;

  /// No description provided for @fieldZoneAssignment.
  ///
  /// In en, this message translates to:
  /// **'Field/Zone Assignment (Optional)'**
  String get fieldZoneAssignment;

  /// No description provided for @installationNote.
  ///
  /// In en, this message translates to:
  /// **'Installation Note (Optional)'**
  String get installationNote;

  /// No description provided for @addSensor.
  ///
  /// In en, this message translates to:
  /// **'Add Sensor'**
  String get addSensor;

  /// No description provided for @sensorCreated.
  ///
  /// In en, this message translates to:
  /// **'Sensor \"{sensor}\" created.'**
  String sensorCreated(String sensor);

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @noSensorsYet.
  ///
  /// In en, this message translates to:
  /// **'No sensors yet. Tap + to add.'**
  String get noSensorsYet;

  /// No description provided for @readings.
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get readings;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get offline;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @latestReading.
  ///
  /// In en, this message translates to:
  /// **'Latest reading'**
  String get latestReading;

  /// No description provided for @updatedEvery5s.
  ///
  /// In en, this message translates to:
  /// **'Updated every 5s'**
  String get updatedEvery5s;

  /// No description provided for @sourceDevice.
  ///
  /// In en, this message translates to:
  /// **'Source: device'**
  String get sourceDevice;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get lastSeen;

  /// No description provided for @irrigationControl.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Control'**
  String get irrigationControl;

  /// No description provided for @openValve.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get openValve;

  /// No description provided for @closeValve.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get closeValve;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get open;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @actionLog.
  ///
  /// In en, this message translates to:
  /// **'Action Log'**
  String get actionLog;

  /// No description provided for @noActionsYet.
  ///
  /// In en, this message translates to:
  /// **'No actions yet'**
  String get noActionsYet;

  /// No description provided for @safetyNote.
  ///
  /// In en, this message translates to:
  /// **'Safety Note'**
  String get safetyNote;

  /// No description provided for @ensurePersonnel.
  ///
  /// In en, this message translates to:
  /// **'Ensure personnel and equipment are clear of active irrigation paths.'**
  String get ensurePersonnel;

  /// No description provided for @confirmStopIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Confirm that manual irrigation should stop now.'**
  String get confirmStopIrrigation;

  /// No description provided for @valveOpened.
  ///
  /// In en, this message translates to:
  /// **'Valve opened (manual start)'**
  String get valveOpened;

  /// No description provided for @failedOpenValve.
  ///
  /// In en, this message translates to:
  /// **'Failed to open valve'**
  String get failedOpenValve;

  /// No description provided for @valveClosed.
  ///
  /// In en, this message translates to:
  /// **'Valve closed (logged stop)'**
  String get valveClosed;

  /// No description provided for @failedCloseValve.
  ///
  /// In en, this message translates to:
  /// **'Failed to close valve'**
  String get failedCloseValve;

  /// No description provided for @irrigationSchedules.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Schedules'**
  String get irrigationSchedules;

  /// No description provided for @pleaseLoginToView.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view schedules'**
  String get pleaseLoginToView;

  /// No description provided for @pleaseLoginToViewSchedules.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view schedules'**
  String get pleaseLoginToViewSchedules;

  /// No description provided for @errorLoadingSchedules.
  ///
  /// In en, this message translates to:
  /// **'Error loading schedules'**
  String get errorLoadingSchedules;

  /// No description provided for @noIrrigationSchedules.
  ///
  /// In en, this message translates to:
  /// **'No Irrigation Schedules'**
  String get noIrrigationSchedules;

  /// No description provided for @createFirstSchedule.
  ///
  /// In en, this message translates to:
  /// **'Create your first irrigation schedule'**
  String get createFirstSchedule;

  /// No description provided for @createSchedule.
  ///
  /// In en, this message translates to:
  /// **'Create Schedule'**
  String get createSchedule;

  /// No description provided for @deleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete Schedule'**
  String get deleteSchedule;

  /// No description provided for @deleteScheduleConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this irrigation schedule?'**
  String get deleteScheduleConfirmation;

  /// No description provided for @stopIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Stop Irrigation'**
  String get stopIrrigation;

  /// No description provided for @startIrrigationNow.
  ///
  /// In en, this message translates to:
  /// **'Start Irrigation Now'**
  String get startIrrigationNow;

  /// No description provided for @startIrrigationFor.
  ///
  /// In en, this message translates to:
  /// **'Start irrigation for {zone} immediately?'**
  String startIrrigationFor(String zone);

  /// No description provided for @areYouSureStopIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop irrigation for {zone}?'**
  String areYouSureStopIrrigation(String zone);

  /// No description provided for @irrigationStartedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Irrigation started successfully'**
  String get irrigationStartedSuccessfully;

  /// No description provided for @failedStartIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Failed to start irrigation. Please try again.'**
  String get failedStartIrrigation;

  /// No description provided for @irrigationStoppedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Irrigation stopped successfully'**
  String get irrigationStoppedSuccessfully;

  /// No description provided for @failedStopIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop irrigation. Please try again.'**
  String get failedStopIrrigation;

  /// No description provided for @scheduleDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Schedule deleted successfully.'**
  String get scheduleDeletedSuccessfully;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this irrigation schedule?'**
  String get areYouSureDelete;

  /// No description provided for @irrigationPlanning.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Planning'**
  String get irrigationPlanning;

  /// No description provided for @irrigationZones.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Zones'**
  String get irrigationZones;

  /// No description provided for @noIrrigationZonesYet.
  ///
  /// In en, this message translates to:
  /// **'No irrigation zones yet'**
  String get noIrrigationZonesYet;

  /// No description provided for @drawOnMapToCreate.
  ///
  /// In en, this message translates to:
  /// **'Draw on the map to create zones'**
  String get drawOnMapToCreate;

  /// No description provided for @saveIrrigationZone.
  ///
  /// In en, this message translates to:
  /// **'Save Irrigation Zone'**
  String get saveIrrigationZone;

  /// No description provided for @zoneName.
  ///
  /// In en, this message translates to:
  /// **'Zone Name'**
  String get zoneName;

  /// No description provided for @zoneType.
  ///
  /// In en, this message translates to:
  /// **'Zone Type'**
  String get zoneType;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @flowRate.
  ///
  /// In en, this message translates to:
  /// **'Flow Rate'**
  String get flowRate;

  /// No description provided for @coverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get coverage;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @areaPolygon.
  ///
  /// In en, this message translates to:
  /// **'Area/Polygon'**
  String get areaPolygon;

  /// No description provided for @linePipe.
  ///
  /// In en, this message translates to:
  /// **'Line/Pipe'**
  String get linePipe;

  /// No description provided for @pointMarker.
  ///
  /// In en, this message translates to:
  /// **'Point'**
  String get pointMarker;

  /// No description provided for @drawingIrrigationZones.
  ///
  /// In en, this message translates to:
  /// **'Drawing Irrigation Zones:'**
  String get drawingIrrigationZones;

  /// No description provided for @selectDrawingMode.
  ///
  /// In en, this message translates to:
  /// **'1. Select drawing mode (Area or Line) at the bottom'**
  String get selectDrawingMode;

  /// No description provided for @tapMapAddPoints.
  ///
  /// In en, this message translates to:
  /// **'2. Tap on the map to add points'**
  String get tapMapAddPoints;

  /// No description provided for @dragMarkersAdjust.
  ///
  /// In en, this message translates to:
  /// **'3. Drag markers to adjust positions'**
  String get dragMarkersAdjust;

  /// No description provided for @useUndoRemove.
  ///
  /// In en, this message translates to:
  /// **'4. Use \"Undo\" to remove last point'**
  String get useUndoRemove;

  /// No description provided for @clickSaveWhenFinished.
  ///
  /// In en, this message translates to:
  /// **'5. Click \"Save\" when finished'**
  String get clickSaveWhenFinished;

  /// No description provided for @searchNavigation.
  ///
  /// In en, this message translates to:
  /// **'Search & Navigation:'**
  String get searchNavigation;

  /// No description provided for @searchByAddress.
  ///
  /// In en, this message translates to:
  /// **'Search by address or location name'**
  String get searchByAddress;

  /// No description provided for @addCoordinatesManually.
  ///
  /// In en, this message translates to:
  /// **'Add coordinates manually for precision'**
  String get addCoordinatesManually;

  /// No description provided for @switchMapTypes.
  ///
  /// In en, this message translates to:
  /// **'Switch between map types (Satellite/Street)'**
  String get switchMapTypes;

  /// No description provided for @zoneTypes.
  ///
  /// In en, this message translates to:
  /// **'Zone Types:'**
  String get zoneTypes;

  /// No description provided for @areaForIrrigation.
  ///
  /// In en, this message translates to:
  /// **'• Area: For irrigation coverage zones'**
  String get areaForIrrigation;

  /// No description provided for @lineForPipes.
  ///
  /// In en, this message translates to:
  /// **'• Line: For pipes, canals, or irrigation lines'**
  String get lineForPipes;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to Use'**
  String get howToUse;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @zoneCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Irrigation zone created successfully'**
  String get zoneCreatedSuccessfully;

  /// No description provided for @failedCreateZone.
  ///
  /// In en, this message translates to:
  /// **'Failed to create irrigation zone'**
  String get failedCreateZone;

  /// No description provided for @deleteZone.
  ///
  /// In en, this message translates to:
  /// **'Delete Zone'**
  String get deleteZone;

  /// No description provided for @areYouSureDeleteZone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{zone}\"?'**
  String areYouSureDeleteZone(String zone);

  /// No description provided for @zoneDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Zone deleted successfully'**
  String get zoneDeletedSuccessfully;

  /// No description provided for @failedDeleteZone.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete zone'**
  String get failedDeleteZone;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @editZoneComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit zone feature will be available soon'**
  String get editZoneComingSoon;

  /// No description provided for @scheduleDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Details'**
  String get scheduleDetailsTitle;

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @lastRun.
  ///
  /// In en, this message translates to:
  /// **'Last Run'**
  String get lastRun;

  /// No description provided for @nextRun.
  ///
  /// In en, this message translates to:
  /// **'Next Run'**
  String get nextRun;

  /// No description provided for @stoppedAt.
  ///
  /// In en, this message translates to:
  /// **'Stopped At'**
  String get stoppedAt;

  /// No description provided for @stoppedBy.
  ///
  /// In en, this message translates to:
  /// **'Stopped By'**
  String get stoppedBy;

  /// No description provided for @oneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get oneTime;

  /// No description provided for @notAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get notAllowed;

  /// No description provided for @stopCycleBeforeDeleting.
  ///
  /// In en, this message translates to:
  /// **'Stop the cycle before deleting'**
  String get stopCycleBeforeDeleting;

  /// No description provided for @invalidScheduleId.
  ///
  /// In en, this message translates to:
  /// **'Invalid schedule id'**
  String get invalidScheduleId;

  /// No description provided for @createScheduleName.
  ///
  /// In en, this message translates to:
  /// **'Create Irrigation Schedule'**
  String get createScheduleName;

  /// No description provided for @scheduleName.
  ///
  /// In en, this message translates to:
  /// **'Schedule Name'**
  String get scheduleName;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationMinutes;

  /// No description provided for @pickDateTime.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get pickDateTime;

  /// No description provided for @noFieldsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No fields available'**
  String get noFieldsAvailable;

  /// No description provided for @updateScheduleName.
  ///
  /// In en, this message translates to:
  /// **'Update Irrigation Schedule'**
  String get updateScheduleName;

  /// No description provided for @invalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalidInput;

  /// No description provided for @pleaseEnterScheduleName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a schedule name'**
  String get pleaseEnterScheduleName;

  /// No description provided for @durationMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Duration must be a positive number'**
  String get durationMustBePositive;

  /// No description provided for @scheduleSaved.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved'**
  String get scheduleSaved;

  /// No description provided for @failedSaveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Failed to save schedule'**
  String get failedSaveSchedule;

  /// No description provided for @notAllowedUpdateRunning.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get notAllowedUpdateRunning;

  /// No description provided for @scheduleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated'**
  String get scheduleUpdated;

  /// No description provided for @notAllowedDeleteRunning.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get notAllowedDeleteRunning;

  /// No description provided for @myFields.
  ///
  /// In en, this message translates to:
  /// **'My Fields'**
  String get myFields;

  /// No description provided for @addNewField.
  ///
  /// In en, this message translates to:
  /// **'Add New Field'**
  String get addNewField;

  /// No description provided for @pleaseLoginToViewFields.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view your fields'**
  String get pleaseLoginToViewFields;

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get addField;

  /// No description provided for @errorLoadingFields.
  ///
  /// In en, this message translates to:
  /// **'Error loading fields.'**
  String get errorLoadingFields;

  /// No description provided for @addFirstField.
  ///
  /// In en, this message translates to:
  /// **'Add your first field to get started!'**
  String get addFirstField;

  /// No description provided for @addFirstFieldToStart.
  ///
  /// In en, this message translates to:
  /// **'Add your first field to get started!'**
  String get addFirstFieldToStart;

  /// No description provided for @noFieldsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No fields found for'**
  String noFieldsFoundFor(String query);

  /// No description provided for @fieldInformation.
  ///
  /// In en, this message translates to:
  /// **'Field Information'**
  String get fieldInformation;

  /// No description provided for @enterBasicDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter basic details about your field'**
  String get enterBasicDetails;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Field Name'**
  String get fieldName;

  /// No description provided for @fieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., North Field, Back Garden'**
  String get fieldNameHint;

  /// No description provided for @fieldSize.
  ///
  /// In en, this message translates to:
  /// **'Field Size (hectares)'**
  String get fieldSize;

  /// No description provided for @fieldSizeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2.5'**
  String get fieldSizeHint;

  /// No description provided for @ownerManagerName.
  ///
  /// In en, this message translates to:
  /// **'Owner/Manager Name'**
  String get ownerManagerName;

  /// No description provided for @ownerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., John Doe'**
  String get ownerHint;

  /// No description provided for @organicFarming.
  ///
  /// In en, this message translates to:
  /// **'Organic Farming'**
  String get organicFarming;

  /// No description provided for @isCertifiedOrganic.
  ///
  /// In en, this message translates to:
  /// **'Is this field certified organic?'**
  String get isCertifiedOrganic;

  /// No description provided for @youCanAddMore.
  ///
  /// In en, this message translates to:
  /// **'You can add more details like crop types and irrigation systems after creating the field.'**
  String get youCanAddMore;

  /// No description provided for @createField.
  ///
  /// In en, this message translates to:
  /// **'Create Field'**
  String get createField;

  /// No description provided for @fieldCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Field \"{field}\" created successfully!'**
  String fieldCreatedSuccess(String field);

  /// No description provided for @failedCreateField.
  ///
  /// In en, this message translates to:
  /// **'Failed to create field'**
  String get failedCreateField;

  /// No description provided for @fieldUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Field \"{field}\" updated successfully!'**
  String fieldUpdatedSuccess(String field);

  /// No description provided for @editField.
  ///
  /// In en, this message translates to:
  /// **'Edit Field'**
  String get editField;

  /// No description provided for @drawFieldBoundary.
  ///
  /// In en, this message translates to:
  /// **'Draw Field Boundary'**
  String get drawFieldBoundary;

  /// No description provided for @tapMapMarkCorners.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to mark the corners of your field. You can drag markers to adjust positions.'**
  String get tapMapMarkCorners;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'1. Basic Info'**
  String get basicInfo;

  /// No description provided for @drawBoundary.
  ///
  /// In en, this message translates to:
  /// **'2. Draw Boundary'**
  String get drawBoundary;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'3. Review'**
  String get review;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 3'**
  String stepOf(int step);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @saveField.
  ///
  /// In en, this message translates to:
  /// **'Save Field'**
  String get saveField;

  /// No description provided for @estimatedSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated Size (hectares)'**
  String get estimatedSize;

  /// No description provided for @estimatedSizeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2.5 (will be calculated from boundary)'**
  String get estimatedSizeHint;

  /// No description provided for @fieldBoundarySaved.
  ///
  /// In en, this message translates to:
  /// **'Field boundary saved with {points} points'**
  String fieldBoundarySaved(int points);

  /// No description provided for @reviewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Review & Confirm'**
  String get reviewConfirm;

  /// No description provided for @pleaseDrawFieldBoundary.
  ///
  /// In en, this message translates to:
  /// **'Please draw the field boundary first.'**
  String get pleaseDrawFieldBoundary;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get pointsLabel;

  /// No description provided for @hectareUnit.
  ///
  /// In en, this message translates to:
  /// **'ha'**
  String get hectareUnit;

  /// No description provided for @reviewDetails.
  ///
  /// In en, this message translates to:
  /// **'Please review your field details before saving'**
  String get reviewDetails;

  /// No description provided for @fieldInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Field Information'**
  String get fieldInformationSection;

  /// No description provided for @boundaryDetails.
  ///
  /// In en, this message translates to:
  /// **'Boundary Details'**
  String get boundaryDetails;

  /// No description provided for @boundaryPoints.
  ///
  /// In en, this message translates to:
  /// **'Boundary Points'**
  String get boundaryPoints;

  /// No description provided for @enteredSize.
  ///
  /// In en, this message translates to:
  /// **'Entered Size'**
  String get enteredSize;

  /// No description provided for @calculatedArea.
  ///
  /// In en, this message translates to:
  /// **'Calculated Area'**
  String get calculatedArea;

  /// No description provided for @basedOnDrawn.
  ///
  /// In en, this message translates to:
  /// **'Based on drawn boundary'**
  String get basedOnDrawn;

  /// No description provided for @invalidBoundary.
  ///
  /// In en, this message translates to:
  /// **'Invalid boundary shape'**
  String get invalidBoundary;

  /// No description provided for @calculatedAreaWill.
  ///
  /// In en, this message translates to:
  /// **'The calculated area will be used if it differs from your entered size.'**
  String get calculatedAreaWill;

  /// No description provided for @editFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Field'**
  String get editFieldTitle;

  /// No description provided for @weatherForecast.
  ///
  /// In en, this message translates to:
  /// **'Weather Forecast'**
  String get weatherForecast;

  /// No description provided for @upcomingIrrigations.
  ///
  /// In en, this message translates to:
  /// **'Upcoming irrigations:'**
  String get upcomingIrrigations;

  /// No description provided for @field.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get field;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @loadingWeather.
  ///
  /// In en, this message translates to:
  /// **'Loading weather...'**
  String get loadingWeather;

  /// No description provided for @noWeatherData.
  ///
  /// In en, this message translates to:
  /// **'No weather data available'**
  String get noWeatherData;

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// No description provided for @weatherClouds.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherClouds;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunderstorm;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// Greeting shown on the dashboard user insight card
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String userInsightGreeting(String name);

  /// Message shown when there is no recent sensor data for user's fields
  ///
  /// In en, this message translates to:
  /// **'No recent sensor data available for your fields.'**
  String get userInsightNoData;

  /// Recommendation when no sensor data is available
  ///
  /// In en, this message translates to:
  /// **'Please check your sensors or add fields to start receiving insights.'**
  String get userInsightNoDataRecommendation;

  /// Insight text shown when average soil moisture is low
  ///
  /// In en, this message translates to:
  /// **'Average soil moisture is {value}% — conditions look dry.'**
  String userInsightDryInsight(String value);

  /// Recommendation when fields are dry
  ///
  /// In en, this message translates to:
  /// **'Consider scheduling irrigation soon to avoid crop stress.'**
  String get userInsightDryRecommendation;

  /// Insight text shown when average soil moisture is within optimal range
  ///
  /// In en, this message translates to:
  /// **'Average soil moisture is {value}% — within a healthy range.'**
  String userInsightOptimalInsight(String value);

  /// Recommendation when conditions are optimal
  ///
  /// In en, this message translates to:
  /// **'Conditions look good. Continue to monitor to maintain optimal levels.'**
  String get userInsightOptimalRecommendation;

  /// Insight text shown when average soil moisture is high
  ///
  /// In en, this message translates to:
  /// **'Average soil moisture is {value}% — fields appear wet.'**
  String userInsightWetInsight(String value);

  /// Recommendation when fields appear too wet
  ///
  /// In en, this message translates to:
  /// **'Hold off irrigation and monitor drainage to prevent waterlogging.'**
  String get userInsightWetRecommendation;

  /// Button label to view user's fields
  ///
  /// In en, this message translates to:
  /// **'View fields'**
  String get userInsightViewFields;

  /// Button label to view user's sensors
  ///
  /// In en, this message translates to:
  /// **'View sensors'**
  String get userInsightViewSensors;

  /// Headline summarizing farm-level averages
  ///
  /// In en, this message translates to:
  /// **'Across {count} field(s), average soil moisture is {moisture} and average temperature is {temp}.'**
  String userInsightFarmHeadline(int count, String moisture, String temp);

  /// Short line describing liters irrigated today
  ///
  /// In en, this message translates to:
  /// **'Today you have irrigated {liters} across your fields.'**
  String userInsightWaterLine(String liters);

  /// Prompt when user has no fields
  ///
  /// In en, this message translates to:
  /// **'You have no fields yet — add a field to start receiving insights.'**
  String get userInsightNoFields;

  /// No description provided for @recommendationShortIrrigate.
  ///
  /// In en, this message translates to:
  /// **'Irrigate'**
  String get recommendationShortIrrigate;

  /// No description provided for @recommendationShortDrainage.
  ///
  /// In en, this message translates to:
  /// **'Drainage'**
  String get recommendationShortDrainage;

  /// No description provided for @recommendationShortNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get recommendationShortNeutral;

  /// No description provided for @searchByFieldName.
  ///
  /// In en, this message translates to:
  /// **'Search by field name...'**
  String get searchByFieldName;

  /// No description provided for @fieldNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a field name'**
  String get fieldNameRequired;

  /// No description provided for @fieldSizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter field size'**
  String get fieldSizeRequired;

  /// No description provided for @validSizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid size'**
  String get validSizeRequired;

  /// No description provided for @pleaseEnterValidSize.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid size'**
  String get pleaseEnterValidSize;

  /// No description provided for @ownerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter owner name'**
  String get ownerNameRequired;

  /// No description provided for @deleteField.
  ///
  /// In en, this message translates to:
  /// **'Delete Field?'**
  String get deleteField;

  /// No description provided for @areYouSureDeleteField.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{field}\"? This action cannot be undone.'**
  String areYouSureDeleteField(String field);

  /// No description provided for @fieldDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Field \"{field}\" deleted.'**
  String fieldDeletedSuccess(String field);

  /// No description provided for @failedDeleteField.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete field.'**
  String get failedDeleteField;

  /// No description provided for @fieldDetails.
  ///
  /// In en, this message translates to:
  /// **'Field Details'**
  String get fieldDetails;

  /// No description provided for @fieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Field Label'**
  String get fieldLabel;

  /// No description provided for @organicStatus.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get organicStatus;

  /// No description provided for @soilType.
  ///
  /// In en, this message translates to:
  /// **'Soil Type'**
  String get soilType;

  /// No description provided for @growthStage.
  ///
  /// In en, this message translates to:
  /// **'Growth Stage'**
  String get growthStage;

  /// No description provided for @cropType.
  ///
  /// In en, this message translates to:
  /// **'Crop Type'**
  String get cropType;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @fieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Field Name'**
  String get fieldNameLabel;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @addFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Field'**
  String get addFieldTitle;

  /// No description provided for @fieldNameField.
  ///
  /// In en, this message translates to:
  /// **'Field Name'**
  String get fieldNameField;

  /// No description provided for @fieldLabelField.
  ///
  /// In en, this message translates to:
  /// **'Field Label'**
  String get fieldLabelField;

  /// No description provided for @sizeHectares.
  ///
  /// In en, this message translates to:
  /// **'Size (hectares)'**
  String get sizeHectares;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @clay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get clay;

  /// No description provided for @sandy.
  ///
  /// In en, this message translates to:
  /// **'Sandy'**
  String get sandy;

  /// No description provided for @loam.
  ///
  /// In en, this message translates to:
  /// **'Loam'**
  String get loam;

  /// No description provided for @silt.
  ///
  /// In en, this message translates to:
  /// **'Silt'**
  String get silt;

  /// No description provided for @peat.
  ///
  /// In en, this message translates to:
  /// **'Peat'**
  String get peat;

  /// No description provided for @chalk.
  ///
  /// In en, this message translates to:
  /// **'Chalk'**
  String get chalk;

  /// No description provided for @germination.
  ///
  /// In en, this message translates to:
  /// **'Germination'**
  String get germination;

  /// No description provided for @seedling.
  ///
  /// In en, this message translates to:
  /// **'Seedling'**
  String get seedling;

  /// No description provided for @vegetativeGrowth.
  ///
  /// In en, this message translates to:
  /// **'Vegetative Growth'**
  String get vegetativeGrowth;

  /// No description provided for @flowering.
  ///
  /// In en, this message translates to:
  /// **'Flowering'**
  String get flowering;

  /// No description provided for @fruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get fruit;

  /// No description provided for @maturity.
  ///
  /// In en, this message translates to:
  /// **'Maturity'**
  String get maturity;

  /// No description provided for @harvest.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get harvest;

  /// No description provided for @maize.
  ///
  /// In en, this message translates to:
  /// **'Maize'**
  String get maize;

  /// No description provided for @wheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get wheat;

  /// No description provided for @rice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get rice;

  /// No description provided for @soybean.
  ///
  /// In en, this message translates to:
  /// **'Soybean'**
  String get soybean;

  /// No description provided for @cotton.
  ///
  /// In en, this message translates to:
  /// **'Cotton'**
  String get cotton;

  /// No description provided for @coffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get coffee;

  /// No description provided for @tea.
  ///
  /// In en, this message translates to:
  /// **'Tea'**
  String get tea;

  /// No description provided for @vegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get vegetables;

  /// No description provided for @fruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get fruits;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @specifyCropType.
  ///
  /// In en, this message translates to:
  /// **'Specify Crop Type'**
  String get specifyCropType;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get useMyLocation;

  /// No description provided for @openGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open Google Maps'**
  String get openGoogleMaps;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Validation Error'**
  String get validationError;

  /// No description provided for @fillAllRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields correctly.'**
  String get fillAllRequired;

  /// No description provided for @fieldAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Field added successfully.'**
  String get fieldAddedSuccess;

  /// No description provided for @fieldSaved.
  ///
  /// In en, this message translates to:
  /// **'Field saved'**
  String get fieldSaved;

  /// No description provided for @mapPickerInfo.
  ///
  /// In en, this message translates to:
  /// **'Map picker requires a Google Maps API key on web. Use the buttons below or configure the API key.'**
  String get mapPickerInfo;

  /// No description provided for @nonOrganic.
  ///
  /// In en, this message translates to:
  /// **'Non-Organic'**
  String get nonOrganic;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No alerts'**
  String get noAlerts;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get googleSignIn;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirthLabel;

  /// No description provided for @idNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'National ID Number (Optional)'**
  String get idNumberLabel;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @otherGender.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherGender;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed'**
  String get emailCannotBeChanged;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @provinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get provinceLabel;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @sectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get sectorLabel;

  /// No description provided for @villageAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Village/Address (Optional)'**
  String get villageAddressLabel;

  /// No description provided for @tapCameraToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap camera icon to change photo'**
  String get tapCameraToChangePhoto;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateFailed;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @pleaseFillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillRequired;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @updatePersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your personal details'**
  String get updatePersonalDetails;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @manageNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get manageNotificationPreferences;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings and preferences'**
  String get appSettings;

  /// No description provided for @getHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get getHelpSupport;

  /// No description provided for @aboutFaminga.
  ///
  /// In en, this message translates to:
  /// **'About Faminga Irrigation'**
  String get aboutFaminga;

  /// No description provided for @aboutFamingaIrrigation.
  ///
  /// In en, this message translates to:
  /// **'About Faminga Irrigation'**
  String get aboutFamingaIrrigation;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account Actions'**
  String get accountActions;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'You have been logged out successfully'**
  String get logoutSuccess;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to logout'**
  String get logoutFailed;

  /// No description provided for @aboutFamingaTitle.
  ///
  /// In en, this message translates to:
  /// **'About Faminga Irrigation'**
  String get aboutFamingaTitle;

  /// No description provided for @famingaVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get famingaVersion;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @famingaDescription.
  ///
  /// In en, this message translates to:
  /// **'Smart irrigation management system for African farmers.'**
  String get famingaDescription;

  /// No description provided for @famingaCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2025 Faminga. All rights reserved.'**
  String get famingaCopyright;

  /// No description provided for @statFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get statFields;

  /// No description provided for @statSystems.
  ///
  /// In en, this message translates to:
  /// **'Systems'**
  String get statSystems;

  /// No description provided for @statSensors.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get statSensors;

  /// No description provided for @changeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture'**
  String get changeProfilePicture;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get profilePictureUpdated;

  /// No description provided for @profilePictureRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile picture removed!'**
  String get profilePictureRemoved;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @secureYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure Your Account'**
  String get secureYourAccount;

  /// No description provided for @chooseStrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password to protect your farming data'**
  String get chooseStrongPassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @reEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get reEnterNewPassword;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password Strength'**
  String get passwordStrength;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weakPassword;

  /// No description provided for @mediumPassword.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumPassword;

  /// No description provided for @strongPassword.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strongPassword;

  /// No description provided for @passwordRequirement8Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordRequirement8Chars;

  /// No description provided for @passwordRequirementUppercase.
  ///
  /// In en, this message translates to:
  /// **'Contains uppercase letter'**
  String get passwordRequirementUppercase;

  /// No description provided for @passwordRequirementLowercase.
  ///
  /// In en, this message translates to:
  /// **'Contains lowercase letter'**
  String get passwordRequirementLowercase;

  /// No description provided for @passwordRequirementNumber.
  ///
  /// In en, this message translates to:
  /// **'Contains number'**
  String get passwordRequirementNumber;

  /// No description provided for @passwordRequirementSpecial.
  ///
  /// In en, this message translates to:
  /// **'Contains special character (!@#\$%^&*)'**
  String get passwordRequirementSpecial;

  /// No description provided for @securityTips.
  ///
  /// In en, this message translates to:
  /// **'Security Tips'**
  String get securityTips;

  /// No description provided for @tipUnique.
  ///
  /// In en, this message translates to:
  /// **'Use a unique password for your Faminga account'**
  String get tipUnique;

  /// No description provided for @tipPersonal.
  ///
  /// In en, this message translates to:
  /// **'Avoid using personal information'**
  String get tipPersonal;

  /// No description provided for @tipRegularly.
  ///
  /// In en, this message translates to:
  /// **'Change your password regularly'**
  String get tipRegularly;

  /// No description provided for @tipNeverShare.
  ///
  /// In en, this message translates to:
  /// **'Never share your password with anyone'**
  String get tipNeverShare;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChangedSuccess;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get passwordChangeFailed;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordIncorrect;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'New password is too weak'**
  String get passwordTooWeak;

  /// No description provided for @passwordChangeRequireRelogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign out and sign in again to change password'**
  String get passwordChangeRequireRelogin;

  /// No description provided for @passwordsDoNotMatchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchConfirm;

  /// No description provided for @passwordMinimumLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinimumLength;

  /// No description provided for @passwordCannotBeSame.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get passwordCannotBeSame;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get currentPasswordRequired;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get newPasswordRequired;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get confirmPasswordRequired;

  /// No description provided for @newPasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get newPasswordConfirmRequired;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @irrigationAlerts.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Alerts'**
  String get irrigationAlerts;

  /// No description provided for @irrigationAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified about irrigation schedules'**
  String get irrigationAlertsDesc;

  /// No description provided for @systemUpdates.
  ///
  /// In en, this message translates to:
  /// **'System Updates'**
  String get systemUpdates;

  /// No description provided for @systemUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified about system status changes'**
  String get systemUpdatesDesc;

  /// No description provided for @weatherAlerts.
  ///
  /// In en, this message translates to:
  /// **'Weather Alerts'**
  String get weatherAlerts;

  /// No description provided for @weatherAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified about weather conditions'**
  String get weatherAlertsDesc;

  /// No description provided for @sensorAlerts.
  ///
  /// In en, this message translates to:
  /// **'Sensor Alerts'**
  String get sensorAlerts;

  /// No description provided for @sensorAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified about sensor readings'**
  String get sensorAlertsDesc;

  /// No description provided for @settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings Updated'**
  String get settingsUpdated;

  /// No description provided for @enabledSetting.
  ///
  /// In en, this message translates to:
  /// **'enabled'**
  String get enabledSetting;

  /// No description provided for @disabledSetting.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get disabledSetting;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @phoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get phoneSupport;

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit Website'**
  String get visitWebsite;

  /// No description provided for @faqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqs;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @openingEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Opening email app...'**
  String get openingEmailApp;

  /// No description provided for @openingPhoneApp.
  ///
  /// In en, this message translates to:
  /// **'Opening phone app...'**
  String get openingPhoneApp;

  /// No description provided for @openingWebsite.
  ///
  /// In en, this message translates to:
  /// **'Opening Website'**
  String get openingWebsite;

  /// No description provided for @launchingBrowser.
  ///
  /// In en, this message translates to:
  /// **'Launching browser...'**
  String get launchingBrowser;

  /// No description provided for @faqAddField.
  ///
  /// In en, this message translates to:
  /// **'How do I add a field?'**
  String get faqAddField;

  /// No description provided for @faqAddFieldAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Fields tab → Tap the + button → Draw your field boundaries on the map.'**
  String get faqAddFieldAnswer;

  /// No description provided for @faqScheduleIrrigation.
  ///
  /// In en, this message translates to:
  /// **'How do I schedule irrigation?'**
  String get faqScheduleIrrigation;

  /// No description provided for @faqScheduleIrrigationAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Irrigation tab → Tap Schedule → Select field and set time.'**
  String get faqScheduleIrrigationAnswer;

  /// No description provided for @faqAddSensor.
  ///
  /// In en, this message translates to:
  /// **'How do I add sensors?'**
  String get faqAddSensor;

  /// No description provided for @faqAddSensorAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Sensors tab → Tap Add Sensor → Enter sensor details and location.'**
  String get faqAddSensorAnswer;

  /// No description provided for @faqChangePassword.
  ///
  /// In en, this message translates to:
  /// **'How do I change my password?'**
  String get faqChangePassword;

  /// No description provided for @faqChangePasswordAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Change Password → Enter current and new password.'**
  String get faqChangePasswordAnswer;

  /// No description provided for @irrigationControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Control'**
  String get irrigationControlTitle;

  /// No description provided for @safetyNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Note'**
  String get safetyNoteTitle;

  /// No description provided for @irrigationSchedulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Schedules'**
  String get irrigationSchedulesTitle;

  /// No description provided for @createScheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Create Schedule'**
  String get createScheduleButton;

  /// No description provided for @stopIrrigationButton.
  ///
  /// In en, this message translates to:
  /// **'Stop Irrigation'**
  String get stopIrrigationButton;

  /// No description provided for @startNowButton.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get startNowButton;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @stopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @createIrrigationScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Irrigation Schedule'**
  String get createIrrigationScheduleTitle;

  /// No description provided for @noFieldsAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'No fields available'**
  String get noFieldsAvailableMessage;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeLabel;

  /// No description provided for @pickButton.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get pickButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @updateIrrigationScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Irrigation Schedule'**
  String get updateIrrigationScheduleTitle;

  /// No description provided for @goToFieldsButton.
  ///
  /// In en, this message translates to:
  /// **'Go to Fields'**
  String get goToFieldsButton;

  /// No description provided for @noFieldsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No Fields Found'**
  String get noFieldsFoundTitle;

  /// No description provided for @noFieldsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any fields registered. Please create a field first to add an irrigation schedule.'**
  String get noFieldsFoundMessage;

  /// No description provided for @irrigationPlanningTitle.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Planning'**
  String get irrigationPlanningTitle;

  /// No description provided for @saveIrrigationZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Irrigation Zone'**
  String get saveIrrigationZoneTitle;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @saveZoneButton.
  ///
  /// In en, this message translates to:
  /// **'Save Zone'**
  String get saveZoneButton;

  /// No description provided for @deleteZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Zone'**
  String get deleteZoneTitle;

  /// No description provided for @howToUseTitle.
  ///
  /// In en, this message translates to:
  /// **'How to Use'**
  String get howToUseTitle;

  /// No description provided for @drawingZonesStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Select drawing mode (Area or Line) at the bottom'**
  String get drawingZonesStep1;

  /// No description provided for @drawingZonesStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Tap on the map to add points'**
  String get drawingZonesStep2;

  /// No description provided for @drawingZonesStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Drag markers to adjust positions'**
  String get drawingZonesStep3;

  /// No description provided for @drawingZonesStep4.
  ///
  /// In en, this message translates to:
  /// **'4. Use \"Undo\" to remove last point'**
  String get drawingZonesStep4;

  /// No description provided for @drawingZonesStep5.
  ///
  /// In en, this message translates to:
  /// **'5. Click \"Save\" when finished'**
  String get drawingZonesStep5;

  /// No description provided for @searchNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Search & Navigation'**
  String get searchNavigationTitle;

  /// No description provided for @zoneTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'Zone Types'**
  String get zoneTypesTitle;

  /// No description provided for @areaDescription.
  ///
  /// In en, this message translates to:
  /// **'Area: For irrigation coverage zones'**
  String get areaDescription;

  /// No description provided for @lineDescription.
  ///
  /// In en, this message translates to:
  /// **'Line: For pipes, canals, or irrigation lines'**
  String get lineDescription;

  /// No description provided for @gotItButton.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotItButton;

  /// No description provided for @sensorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get sensorsTitle;

  /// No description provided for @noSensorsMessage.
  ///
  /// In en, this message translates to:
  /// **'No sensors yet. Tap + to add.'**
  String get noSensorsMessage;

  /// No description provided for @bluetoothBLE.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth (BLE)'**
  String get bluetoothBLE;

  /// No description provided for @wiFiOption.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get wiFiOption;

  /// No description provided for @loRaWANGateway.
  ///
  /// In en, this message translates to:
  /// **'LoRaWAN Gateway'**
  String get loRaWANGateway;

  /// No description provided for @addSensorButton.
  ///
  /// In en, this message translates to:
  /// **'Add Sensor'**
  String get addSensorButton;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmationMessage;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get versionLabel;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @secureYourAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Your Account'**
  String get secureYourAccountTitle;

  /// No description provided for @securityTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Tips'**
  String get securityTipsTitle;

  /// No description provided for @failedDeleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete schedule.'**
  String get failedDeleteSchedule;

  /// No description provided for @accountVerification.
  ///
  /// In en, this message translates to:
  /// **'Account Verification'**
  String get accountVerification;

  /// No description provided for @verificationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Being Verified'**
  String get verificationPendingTitle;

  /// No description provided for @verificationPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your registration has been submitted for verification. Our admin team will review your cooperative details and contact you shortly. Thank you for your patience!'**
  String get verificationPendingMessage;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'rw', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'rw':
      return AppLocalizationsRw();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
