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
  String get phoneNumber => 'Phone Number';

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
  String get soilWaterLabel => 'Soil Water';

  @override
  String get tempLabel => 'Temp';

  @override
  String get waterUsedLabel => 'Water Used';

  @override
  String get soilDryMsg => 'Soil is dry – it\'s time to irrigate.';

  @override
  String get soilTooWetMsg => 'Soil is too wet – check drainage.';

  @override
  String get soilOptimalMsg =>
      'Soil conditions are optimal – no action needed.';

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
  String get accountVerification => 'Account Verification';

  @override
  String get verificationPendingTitle => 'Account Being Verified';

  @override
  String get verificationPendingMessage =>
      'Your registration has been submitted for verification. Our admin team will review your cooperative details and contact you shortly. Thank you for your patience!';

  @override
  String get goToHome => 'Go to Home';

  @override
  String emailAlreadyRegistered(String email) {
    return '$email is already registered';
  }

  @override
  String phoneAlreadyRegistered(String phone) {
    return 'Phone number $phone is already registered';
  }

  @override
  String cooperativeIdAlreadyRegistered(String coopId) {
    return 'Cooperative ID $coopId is already registered';
  }

  @override
  String get verifyingRegistration => 'Verifying registration..';

  @override
  String registrationVerificationFailed(String error) {
    return 'Error verifying registration: $error';
  }

  @override
  String get nextSteps => 'Next Steps:';

  @override
  String get checkEmailInbox => '1. Check your email inbox';

  @override
  String get lookForFirebaseEmail => '2. Look for an email from Firebase';

  @override
  String get checkSpamFolder => '3. Check your spam/junk folder';

  @override
  String get clickVerificationLink => '4. Click the verification link';

  @override
  String get returnAndClickVerified =>
      '5. Return here and click \"I\'ve Verified\"';

  @override
  String get verifiedMyEmail => 'I\'ve Verified My Email';

  @override
  String get resendVerificationEmail => 'Resend Verification Email';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get errorSendingEmail => 'Error sending email';

  @override
  String get emailNotVerifiedYet =>
      'Email not verified yet. Please check your email and click the verification link.';

  @override
  String get errorCheckingVerification => 'Error checking verification';

  @override
  String get verificationEmailSent =>
      'Verification email sent! Please check your inbox and spam folder.';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get receiveNotifications =>
      'Receive notifications about your irrigation system';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get receiveEmailUpdates => 'Receive email updates';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get receivePushNotifications => 'Receive push notifications';

  @override
  String get autoIrrigation => 'Auto Irrigation';

  @override
  String get autoIrrigationDesc =>
      'Automatically irrigate based on sensor data';

  @override
  String get preferences => 'Preferences';

  @override
  String get temperatureUnit => 'Temperature Unit';

  @override
  String get theme => 'Theme';

  @override
  String get themeUpdated => 'Theme updated';

  @override
  String get setTo => 'set to';

  @override
  String get dataStorage => 'Data & Storage';

  @override
  String get reports => 'Reports';

  @override
  String get reportsDesc => 'View irrigation statistics and insights';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheDesc => 'Free up storage space';

  @override
  String get clearCacheWarning =>
      'This will remove all cached data and free up storage space. Your account data will not be affected.';

  @override
  String get cacheCleared => 'Cache Cleared';

  @override
  String get cacheSuccessful => 'Cache has been cleared successfully!';

  @override
  String get clear => 'Clear';

  @override
  String get legal => 'Legal';

  @override
  String get termsAndServices => 'Terms and Services';

  @override
  String get viewTerms => 'View terms and services';

  @override
  String get privacyPolicy => 'Privacy and Policy';

  @override
  String get readPrivacy => 'Read our privacy policy';

  @override
  String get sensorInformation => 'Sensor Information';

  @override
  String get sensorNameLabel => 'Sensor Name/Label';

  @override
  String get hardwareIdSerial => 'Hardware ID/Serial';

  @override
  String get pairingMethod => 'Pairing Method';

  @override
  String get bleOption => 'Bluetooth (BLE)';

  @override
  String get wifiOption => 'WiFi';

  @override
  String get loraOption => 'LoRaWAN Gateway';

  @override
  String get bleMacAddress => 'BLE MAC Address';

  @override
  String get wifiSsid => 'WiFi SSID';

  @override
  String get gatewayIdName => 'Gateway ID/Name';

  @override
  String get advancedOptions => 'Advanced Options';

  @override
  String get pairingNoteCode => 'Pairing Note/Code (Optional)';

  @override
  String get wifiPassword => 'WiFi Password (Optional)';

  @override
  String get loraNetworkId => 'LoRaWAN Network ID (Optional)';

  @override
  String get channel => 'Channel (Optional)';

  @override
  String get fieldZoneAssignment => 'Field/Zone Assignment (Optional)';

  @override
  String get installationNote => 'Installation Note (Optional)';

  @override
  String get addSensor => 'Add Sensor';

  @override
  String sensorCreated(String sensor) {
    return 'Sensor \"$sensor\" created.';
  }

  @override
  String get requiredField => 'Required';

  @override
  String get noSensorsYet => 'No sensors yet. Tap + to add.';

  @override
  String get readings => 'Readings';

  @override
  String get info => 'Info';

  @override
  String get online => 'ONLINE';

  @override
  String get offline => 'OFFLINE';

  @override
  String get live => 'Live';

  @override
  String get latestReading => 'Latest reading';

  @override
  String get updatedEvery5s => 'Updated every 5s';

  @override
  String get sourceDevice => 'Source: device';

  @override
  String get value => 'Value';

  @override
  String get time => 'Time';

  @override
  String get location => 'Location';

  @override
  String get battery => 'Battery';

  @override
  String get lastSeen => 'Last seen';

  @override
  String get irrigationControl => 'Irrigation Control';

  @override
  String get openValve => 'OPEN';

  @override
  String get closeValve => 'CLOSE';

  @override
  String get open => 'OPEN';

  @override
  String get close => 'Close';

  @override
  String get actionLog => 'Action Log';

  @override
  String get noActionsYet => 'No actions yet';

  @override
  String get safetyNote => 'Safety Note';

  @override
  String get ensurePersonnel =>
      'Ensure personnel and equipment are clear of active irrigation paths.';

  @override
  String get confirmStopIrrigation =>
      'Confirm that manual irrigation should stop now.';

  @override
  String get valveOpened => 'Valve opened (manual start)';

  @override
  String get failedOpenValve => 'Failed to open valve';

  @override
  String get valveClosed => 'Valve closed (logged stop)';

  @override
  String get failedCloseValve => 'Failed to close valve';

  @override
  String get irrigationSchedules => 'Irrigation Schedules';

  @override
  String get pleaseLoginToView => 'Please log in to view schedules';

  @override
  String get pleaseLoginToViewSchedules => 'Please log in to view schedules';

  @override
  String get errorLoadingSchedules => 'Error loading schedules';

  @override
  String get noIrrigationSchedules => 'No Irrigation Schedules';

  @override
  String get createFirstSchedule => 'Create your first irrigation schedule';

  @override
  String get createSchedule => 'Create Schedule';

  @override
  String get deleteSchedule => 'Delete Schedule';

  @override
  String get deleteScheduleConfirmation =>
      'Are you sure you want to delete this irrigation schedule?';

  @override
  String get stopIrrigation => 'Stop Irrigation';

  @override
  String get startIrrigationNow => 'Start Irrigation Now';

  @override
  String startIrrigationFor(String zone) {
    return 'Start irrigation for $zone immediately?';
  }

  @override
  String areYouSureStopIrrigation(String zone) {
    return 'Are you sure you want to stop irrigation for $zone?';
  }

  @override
  String get irrigationStartedSuccessfully => 'Irrigation started successfully';

  @override
  String get failedStartIrrigation =>
      'Failed to start irrigation. Please try again.';

  @override
  String get irrigationStoppedSuccessfully => 'Irrigation stopped successfully';

  @override
  String get failedStopIrrigation =>
      'Failed to stop irrigation. Please try again.';

  @override
  String get scheduleDeletedSuccessfully => 'Schedule deleted successfully.';

  @override
  String get areYouSureDelete =>
      'Are you sure you want to delete this irrigation schedule?';

  @override
  String get irrigationPlanning => 'Irrigation Planning';

  @override
  String get irrigationZones => 'Irrigation Zones';

  @override
  String get noIrrigationZonesYet => 'No irrigation zones yet';

  @override
  String get drawOnMapToCreate => 'Draw on the map to create zones';

  @override
  String get saveIrrigationZone => 'Save Irrigation Zone';

  @override
  String get zoneName => 'Zone Name';

  @override
  String get zoneType => 'Zone Type';

  @override
  String get description => 'Description';

  @override
  String get flowRate => 'Flow Rate';

  @override
  String get coverage => 'Coverage';

  @override
  String get color => 'Color';

  @override
  String get areaPolygon => 'Area/Polygon';

  @override
  String get linePipe => 'Line/Pipe';

  @override
  String get pointMarker => 'Point';

  @override
  String get drawingIrrigationZones => 'Drawing Irrigation Zones:';

  @override
  String get selectDrawingMode =>
      '1. Select drawing mode (Area or Line) at the bottom';

  @override
  String get tapMapAddPoints => '2. Tap on the map to add points';

  @override
  String get dragMarkersAdjust => '3. Drag markers to adjust positions';

  @override
  String get useUndoRemove => '4. Use \"Undo\" to remove last point';

  @override
  String get clickSaveWhenFinished => '5. Click \"Save\" when finished';

  @override
  String get searchNavigation => 'Search & Navigation:';

  @override
  String get searchByAddress => 'Search by address or location name';

  @override
  String get addCoordinatesManually => 'Add coordinates manually for precision';

  @override
  String get switchMapTypes => 'Switch between map types (Satellite/Street)';

  @override
  String get zoneTypes => 'Zone Types:';

  @override
  String get areaForIrrigation => '• Area: For irrigation coverage zones';

  @override
  String get lineForPipes => '• Line: For pipes, canals, or irrigation lines';

  @override
  String get howToUse => 'How to Use';

  @override
  String get gotIt => 'Got it';

  @override
  String get zoneCreatedSuccessfully => 'Irrigation zone created successfully';

  @override
  String get failedCreateZone => 'Failed to create irrigation zone';

  @override
  String get deleteZone => 'Delete Zone';

  @override
  String areYouSureDeleteZone(String zone) {
    return 'Are you sure you want to delete \"$zone\"?';
  }

  @override
  String get zoneDeletedSuccessfully => 'Zone deleted successfully';

  @override
  String get failedDeleteZone => 'Failed to delete zone';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get editZoneComingSoon => 'Edit zone feature will be available soon';

  @override
  String get scheduleDetailsTitle => 'Schedule Details';

  @override
  String get zone => 'Zone';

  @override
  String get startTime => 'Start Time';

  @override
  String get duration => 'Duration';

  @override
  String get repeat => 'Repeat';

  @override
  String get lastRun => 'Last Run';

  @override
  String get nextRun => 'Next Run';

  @override
  String get stoppedAt => 'Stopped At';

  @override
  String get stoppedBy => 'Stopped By';

  @override
  String get oneTime => 'One-time';

  @override
  String get notAllowed => 'Not allowed';

  @override
  String get stopCycleBeforeDeleting => 'Stop the cycle before deleting';

  @override
  String get invalidScheduleId => 'Invalid schedule id';

  @override
  String get createScheduleName => 'Create Irrigation Schedule';

  @override
  String get scheduleName => 'Schedule Name';

  @override
  String get durationMinutes => 'Duration (minutes)';

  @override
  String get pickDateTime => 'Pick';

  @override
  String get noFieldsAvailable => 'No fields available';

  @override
  String get updateScheduleName => 'Update Irrigation Schedule';

  @override
  String get invalidInput => 'Invalid';

  @override
  String get pleaseEnterScheduleName => 'Please enter a schedule name';

  @override
  String get durationMustBePositive => 'Duration must be a positive number';

  @override
  String get scheduleSaved => 'Schedule saved';

  @override
  String get failedSaveSchedule => 'Failed to save schedule';

  @override
  String get notAllowedUpdateRunning => 'Not allowed';

  @override
  String get scheduleUpdated => 'Schedule updated';

  @override
  String get notAllowedDeleteRunning => 'Not allowed';

  @override
  String get myFields => 'My Fields';

  @override
  String get addNewField => 'Add New Field';

  @override
  String get pleaseLoginToViewFields => 'Please log in to view your fields';

  @override
  String get addField => 'Add Field';

  @override
  String get errorLoadingFields => 'Error loading fields.';

  @override
  String get addFirstField => 'Add your first field to get started!';

  @override
  String get addFirstFieldToStart => 'Add your first field to get started!';

  @override
  String noFieldsFoundFor(String query) {
    return 'No fields found for';
  }

  @override
  String get fieldInformation => 'Field Information';

  @override
  String get enterBasicDetails => 'Enter basic details about your field';

  @override
  String get fieldName => 'Field Name';

  @override
  String get fieldNameHint => 'e.g., North Field, Back Garden';

  @override
  String get fieldSize => 'Field Size (hectares)';

  @override
  String get fieldSizeHint => 'e.g., 2.5';

  @override
  String get ownerManagerName => 'Owner/Manager Name';

  @override
  String get ownerHint => 'e.g., John Doe';

  @override
  String get organicFarming => 'Organic Farming';

  @override
  String get isCertifiedOrganic => 'Is this field certified organic?';

  @override
  String get youCanAddMore =>
      'You can add more details like crop types and irrigation systems after creating the field.';

  @override
  String get createField => 'Create Field';

  @override
  String fieldCreatedSuccess(String field) {
    return 'Field \"$field\" created successfully!';
  }

  @override
  String get failedCreateField => 'Failed to create field';

  @override
  String fieldUpdatedSuccess(String field) {
    return 'Field \"$field\" updated successfully!';
  }

  @override
  String get editField => 'Edit Field';

  @override
  String get drawFieldBoundary => 'Draw Field Boundary';

  @override
  String get tapMapMarkCorners =>
      'Tap on the map to mark the corners of your field. You can drag markers to adjust positions.';

  @override
  String get basicInfo => '1. Basic Info';

  @override
  String get drawBoundary => '2. Draw Boundary';

  @override
  String get review => '3. Review';

  @override
  String stepOf(int step) {
    return 'Step $step of 3';
  }

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get saveField => 'Save Field';

  @override
  String get estimatedSize => 'Estimated Size (hectares)';

  @override
  String get estimatedSizeHint =>
      'e.g., 2.5 (will be calculated from boundary)';

  @override
  String fieldBoundarySaved(int points) {
    return 'Field boundary saved with $points points';
  }

  @override
  String get reviewConfirm => 'Review & Confirm';

  @override
  String get pleaseDrawFieldBoundary => 'Please draw the field boundary first.';

  @override
  String get pointsLabel => 'points';

  @override
  String get hectareUnit => 'ha';

  @override
  String get reviewDetails => 'Please review your field details before saving';

  @override
  String get fieldInformationSection => 'Field Information';

  @override
  String get boundaryDetails => 'Boundary Details';

  @override
  String get boundaryPoints => 'Boundary Points';

  @override
  String get enteredSize => 'Entered Size';

  @override
  String get calculatedArea => 'Calculated Area';

  @override
  String get basedOnDrawn => 'Based on drawn boundary';

  @override
  String get invalidBoundary => 'Invalid boundary shape';

  @override
  String get calculatedAreaWill =>
      'The calculated area will be used if it differs from your entered size.';

  @override
  String get editFieldTitle => 'Edit Field';

  @override
  String get weatherForecast => 'Weather Forecast';

  @override
  String get upcomingIrrigations => 'Upcoming irrigations:';

  @override
  String get field => 'Field';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get loadingWeather => 'Loading weather...';

  @override
  String get noWeatherData => 'No weather data available';

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherClouds => 'Cloudy';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String userInsightGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get userInsightNoData =>
      'No recent sensor data available for your fields.';

  @override
  String get userInsightNoDataRecommendation =>
      'Please check your sensors or add fields to start receiving insights.';

  @override
  String userInsightDryInsight(String value) {
    return 'Average soil moisture is $value% — conditions look dry.';
  }

  @override
  String get userInsightDryRecommendation =>
      'Consider scheduling irrigation soon to avoid crop stress.';

  @override
  String userInsightOptimalInsight(String value) {
    return 'Average soil moisture is $value% — within a healthy range.';
  }

  @override
  String get userInsightOptimalRecommendation =>
      'Conditions look good. Continue to monitor to maintain optimal levels.';

  @override
  String userInsightWetInsight(String value) {
    return 'Average soil moisture is $value% — fields appear wet.';
  }

  @override
  String get userInsightWetRecommendation =>
      'Hold off irrigation and monitor drainage to prevent waterlogging.';

  @override
  String get userInsightViewFields => 'View fields';

  @override
  String get userInsightViewSensors => 'View sensors';

  @override
  String userInsightFarmHeadline(int count, String moisture, String temp) {
    return 'Across $count field(s), average soil moisture is $moisture and average temperature is $temp.';
  }

  @override
  String userInsightWaterLine(String liters) {
    return 'Today you have irrigated $liters across your fields.';
  }

  @override
  String get userInsightNoFields =>
      'You have no fields yet — add a field to start receiving insights.';

  @override
  String get recommendationShortIrrigate => 'Irrigate';

  @override
  String get recommendationShortDrainage => 'Drainage';

  @override
  String get recommendationShortNeutral => 'Neutral';

  @override
  String get searchByFieldName => 'Search by field name...';

  @override
  String get fieldNameRequired => 'Please enter a field name';

  @override
  String get fieldSizeRequired => 'Please enter field size';

  @override
  String get validSizeRequired => 'Please enter a valid size';

  @override
  String get pleaseEnterValidSize => 'Please enter a valid size';

  @override
  String get ownerNameRequired => 'Please enter owner name';

  @override
  String get deleteField => 'Delete Field?';

  @override
  String areYouSureDeleteField(String field) {
    return 'Are you sure you want to delete \"$field\"? This action cannot be undone.';
  }

  @override
  String fieldDeletedSuccess(String field) {
    return 'Field \"$field\" deleted.';
  }

  @override
  String get failedDeleteField => 'Failed to delete field.';

  @override
  String get fieldDetails => 'Field Details';

  @override
  String fieldLabel(String name) {
    return 'Field: $name';
  }

  @override
  String get organicStatus => 'Organic';

  @override
  String get soilType => 'Soil Type';

  @override
  String get growthStage => 'Growth Stage';

  @override
  String get cropType => 'Crop Type';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get fieldNameLabel => 'Field Name';

  @override
  String get owner => 'Owner';

  @override
  String get status => 'Status';

  @override
  String get addFieldTitle => 'Add New Field';

  @override
  String get fieldNameField => 'Field Name';

  @override
  String get fieldLabelField => 'Field Label';

  @override
  String get sizeHectares => 'Size (hectares)';

  @override
  String get unknown => 'Unknown';

  @override
  String get clay => 'Clay';

  @override
  String get sandy => 'Sandy';

  @override
  String get loam => 'Loam';

  @override
  String get silt => 'Silt';

  @override
  String get peat => 'Peat';

  @override
  String get chalk => 'Chalk';

  @override
  String get germination => 'Germination';

  @override
  String get seedling => 'Seedling';

  @override
  String get vegetativeGrowth => 'Vegetative Growth';

  @override
  String get flowering => 'Flowering';

  @override
  String get fruit => 'Fruit';

  @override
  String get maturity => 'Maturity';

  @override
  String get harvest => 'Harvest';

  @override
  String get maize => 'Maize';

  @override
  String get wheat => 'Wheat';

  @override
  String get rice => 'Rice';

  @override
  String get soybean => 'Soybean';

  @override
  String get cotton => 'Cotton';

  @override
  String get coffee => 'Coffee';

  @override
  String get tea => 'Tea';

  @override
  String get vegetables => 'Vegetables';

  @override
  String get fruits => 'Fruits';

  @override
  String get other => 'Other';

  @override
  String get specifyCropType => 'Specify Crop Type';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get useMyLocation => 'Use My Location';

  @override
  String get openGoogleMaps => 'Open Google Maps';

  @override
  String get validationError => 'Validation Error';

  @override
  String get fillAllRequired => 'Please fill all required fields correctly.';

  @override
  String get fieldAddedSuccess => 'Field added successfully.';

  @override
  String get fieldSaved => 'Field saved';

  @override
  String get mapPickerInfo =>
      'Map picker requires a Google Maps API key on web. Use the buttons below or configure the API key.';

  @override
  String get nonOrganic => 'Non-Organic';

  @override
  String get noAlerts => 'No alerts';

  @override
  String get alert => 'Alert';

  @override
  String get or => 'OR';

  @override
  String get googleSignIn => 'Sign in with Google';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get verifyYourEmail => 'Verify Your Email';

  @override
  String get verificationEmailSentTo => 'We\'ve sent a verification email to:';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get lastNameLabel => 'Last Name';

  @override
  String get genderLabel => 'Gender';

  @override
  String get dateOfBirthLabel => 'Date of Birth';

  @override
  String get idNumberLabel => 'National ID Number (Optional)';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get otherGender => 'Other';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailCannotBeChanged => 'Email cannot be changed';

  @override
  String get locationLabel => 'Location';

  @override
  String get provinceLabel => 'Province';

  @override
  String get districtLabel => 'District';

  @override
  String get sectorLabel => 'Sector';

  @override
  String get villageAddressLabel => 'Village/Address (Optional)';

  @override
  String get tapCameraToChangePhoto => 'Tap camera icon to change photo';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully!';

  @override
  String get profileUpdateFailed => 'Failed to update profile';

  @override
  String get selectDate => 'Select date';

  @override
  String get pleaseFillRequired => 'Please fill all required fields';

  @override
  String get accountSection => 'Account';

  @override
  String get updatePersonalDetails => 'Update your personal details';

  @override
  String get appSection => 'App';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get manageNotificationPreferences => 'Manage notification preferences';

  @override
  String get appSettings => 'App settings and preferences';

  @override
  String get getHelpSupport => 'Get help and support';

  @override
  String get aboutFaminga => 'About Faminga Irrigation';

  @override
  String get aboutFamingaIrrigation => 'About Faminga Irrigation';

  @override
  String get accountActions => 'Account Actions';

  @override
  String get signOut => 'Sign out';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get areYouSureLogout => 'Are you sure you want to logout?';

  @override
  String get logoutSuccess => 'You have been logged out successfully';

  @override
  String get logoutFailed => 'Failed to logout';

  @override
  String get aboutFamingaTitle => 'About Faminga Irrigation';

  @override
  String get famingaVersion => 'Version 1.0.0';

  @override
  String get version => 'Version 1.0.0';

  @override
  String get famingaDescription =>
      'Smart irrigation management system for African farmers.';

  @override
  String get famingaCopyright => '© 2025 Faminga. All rights reserved.';

  @override
  String get statFields => 'Fields';

  @override
  String get statSystems => 'Systems';

  @override
  String get statSensors => 'Sensors';

  @override
  String get changeProfilePicture => 'Change Profile Picture';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get profilePictureUpdated => 'Profile picture updated successfully!';

  @override
  String get profilePictureRemoved => 'Profile picture removed!';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get secureYourAccountTitle => 'Secure Your Account';

  @override
  String get securityTipsTitle => 'Security Tips';

  @override
  String get failedDeleteSchedule => 'Failed to delete schedule.';

  @override
  String get passwordRequirementSpecial =>
      'Contains special character (!@#\$%^&*)';

  @override
  String get securityTips => 'Security Tips';

  @override
  String get tipUnique => 'Use a unique password for your Faminga account';

  @override
  String get tipPersonal => 'Avoid using personal information';

  @override
  String get tipRegularly => 'Change your password regularly';

  @override
  String get tipNeverShare => 'Never share your password with anyone';

  @override
  String get passwordChangedSuccess => 'Password changed successfully!';

  @override
  String get passwordChangeFailed => 'Failed to change password';

  @override
  String get currentPasswordIncorrect => 'Current password is incorrect';

  @override
  String get passwordTooWeak => 'New password is too weak';

  @override
  String get passwordChangeRequireRelogin =>
      'Please sign out and sign in again to change password';

  @override
  String get passwordsDoNotMatchConfirm => 'Passwords do not match';

  @override
  String get passwordMinimumLength => 'Password must be at least 6 characters';

  @override
  String get passwordCannotBeSame =>
      'New password must be different from current password';

  @override
  String get currentPasswordRequired => 'Please enter your current password';

  @override
  String get newPasswordRequired => 'Please enter a new password';

  @override
  String get confirmPasswordRequired => 'Please confirm your new password';

  @override
  String get newPasswordConfirmRequired => 'Please confirm your new password';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get irrigationAlerts => 'Irrigation Alerts';

  @override
  String get irrigationAlertsDesc => 'Get notified about irrigation schedules';

  @override
  String get systemUpdates => 'System Updates';

  @override
  String get systemUpdatesDesc => 'Get notified about system status changes';

  @override
  String get weatherAlerts => 'Weather Alerts';

  @override
  String get weatherAlertsDesc => 'Get notified about weather conditions';

  @override
  String get sensorAlerts => 'Sensor Alerts';

  @override
  String get sensorAlertsDesc => 'Get notified about sensor readings';

  @override
  String get settingsUpdated => 'Settings Updated';

  @override
  String get enabledSetting => 'enabled';

  @override
  String get disabledSetting => 'disabled';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get emailSupport => 'Email Support';

  @override
  String get phoneSupport => 'Phone Support';

  @override
  String get visitWebsite => 'Visit Website';

  @override
  String get faqs => 'FAQs';

  @override
  String get frequentlyAskedQuestions => 'Frequently asked questions';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get openingEmailApp => 'Opening email app...';

  @override
  String get openingPhoneApp => 'Opening phone app...';

  @override
  String get openingWebsite => 'Opening Website';

  @override
  String get launchingBrowser => 'Launching browser...';

  @override
  String get faqAddField => 'How do I add a field?';

  @override
  String get faqAddFieldAnswer =>
      'Go to Fields tab → Tap the + button → Draw your field boundaries on the map.';

  @override
  String get faqScheduleIrrigation => 'How do I schedule irrigation?';

  @override
  String get faqScheduleIrrigationAnswer =>
      'Go to Irrigation tab → Tap Schedule → Select field and set time.';

  @override
  String get faqAddSensor => 'How do I add sensors?';

  @override
  String get faqAddSensorAnswer =>
      'Go to Sensors tab → Tap Add Sensor → Enter sensor details and location.';

  @override
  String get faqChangePassword => 'How do I change my password?';

  @override
  String get faqChangePasswordAnswer =>
      'Go to Profile → Change Password → Enter current and new password.';

  @override
  String get irrigationControlTitle => 'Irrigation Control';

  @override
  String get safetyNoteTitle => 'Safety Note';

  @override
  String get irrigationSchedulesTitle => 'Irrigation Schedules';

  @override
  String get createScheduleButton => 'Create Schedule';

  @override
  String get stopIrrigationButton => 'Stop Irrigation';

  @override
  String get startNowButton => 'Start Now';

  @override
  String get updateButton => 'Update';

  @override
  String get deleteButton => 'Delete';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get stopButton => 'Stop';

  @override
  String get closeButton => 'Close';

  @override
  String get createIrrigationScheduleTitle => 'Create Irrigation Schedule';

  @override
  String get noFieldsAvailableMessage => 'No fields available';

  @override
  String get startTimeLabel => 'Start Time';

  @override
  String get pickButton => 'Pick';

  @override
  String get saveButton => 'Save';

  @override
  String get updateIrrigationScheduleTitle => 'Update Irrigation Schedule';

  @override
  String get goToFieldsButton => 'Go to Fields';

  @override
  String get noFieldsFoundTitle => 'No Fields Found';

  @override
  String get noFieldsFoundMessage =>
      'You don\'t have any fields registered. Please create a field first to add an irrigation schedule.';

  @override
  String get irrigationPlanningTitle => 'Irrigation Planning';

  @override
  String get saveIrrigationZoneTitle => 'Save Irrigation Zone';

  @override
  String get colorLabel => 'Color';

  @override
  String get saveZoneButton => 'Save Zone';

  @override
  String get deleteZoneTitle => 'Delete Zone';

  @override
  String get howToUseTitle => 'How to Use';

  @override
  String get drawingZonesStep1 =>
      '1. Select drawing mode (Area or Line) at the bottom';

  @override
  String get drawingZonesStep2 => '2. Tap on the map to add points';

  @override
  String get drawingZonesStep3 => '3. Drag markers to adjust positions';

  @override
  String get drawingZonesStep4 => '4. Use \"Undo\" to remove last point';

  @override
  String get drawingZonesStep5 => '5. Click \"Save\" when finished';

  @override
  String get searchNavigationTitle => 'Search & Navigation';

  @override
  String get zoneTypesTitle => 'Zone Types';

  @override
  String get areaDescription => 'Area: For irrigation coverage zones';

  @override
  String get lineDescription => 'Line: For pipes, canals, or irrigation lines';

  @override
  String get gotItButton => 'Got it';

  @override
  String get sensorsTitle => 'Sensors';

  @override
  String get noSensorsMessage => 'No sensors yet. Tap + to add.';

  @override
  String get bluetoothBLE => 'Bluetooth (BLE)';

  @override
  String get wiFiOption => 'WiFi';

  @override
  String get loRaWANGateway => 'LoRaWAN Gateway';

  @override
  String get addSensorButton => 'Add Sensor';

  @override
  String get profileTitle => 'Profile';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get logoutConfirmationMessage => 'Are you sure you want to logout?';

  @override
  String get logoutButton => 'Logout';

  @override
  String get versionLabel => 'Version 1.0.0';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get registrationFailed => 'Registration failed. Please try again.';

  @override
  String get pleaseEnterFirstName => 'Please enter your first name';

  @override
  String get pleaseEnterLastName => 'Please enter your last name';

  @override
  String get pleaseEnterEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter a valid phone number';

  @override
  String get province => 'Province';

  @override
  String get chooseProvince => 'Please choose a province';

  @override
  String get district => 'District';

  @override
  String get chooseProvinceFirst => 'Please choose a province first';

  @override
  String get chooseDistrict => 'Please choose a district';

  @override
  String get addressHint => 'Enter your address';

  @override
  String get addressTooShort => 'Address must be at least 5 characters';

  @override
  String get addressTooLong => 'Address cannot exceed 100 characters';

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get manualStart => 'Manual Start';

  @override
  String get farmInfo => 'Farm Info';

  @override
  String get scheduled => 'Scheduled';

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get changePassword => 'Change Password';

  @override
  String get secureYourAccount => 'Secure Your Account';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get weakPassword => 'Weak';

  @override
  String get mediumPassword => 'Medium';

  @override
  String get strongPassword => 'Strong';

  @override
  String get enterCurrentPassword => 'Enter your current password';

  @override
  String get enterNewPassword => 'Enter your new password';

  @override
  String get passwordRequirement8Chars => 'At least 8 characters';

  @override
  String get passwordRequirementUppercase => 'Contains uppercase letter';

  @override
  String get passwordRequirementLowercase => 'Contains lowercase letter';

  @override
  String get passwordRequirementNumber => 'Contains a number';

  @override
  String get reEnterNewPassword => 'Re-enter your new password';

  @override
  String get chooseStrongPassword =>
      'Choose a strong password to protect your farm data';

  @override
  String get pleaseEnterValidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get todaysFarmStatus => 'Today\'s Farm Status';

  @override
  String get noFieldsConfiguredAction =>
      'No fields configured yet. Add a field to start monitoring.';

  @override
  String get advice => 'Advice';

  @override
  String get checkSensorsAndFields => 'Check your sensors and field conditions';

  @override
  String get continueMonitoring => 'Continue monitoring your fields';

  @override
  String get litersSuffix => 'liters';

  @override
  String get noData => 'No data';

  @override
  String get sensorNotLoggingData => 'Sensor Not Logging Data';

  @override
  String get sensorDataNotAvailable => 'Sensor data is not available.';

  @override
  String get usbSoilSensor => '🌱 USB Soil Sensor';

  @override
  String get lastUpdate => 'Last update';

  @override
  String get sensorDisconnectedCheckUsb =>
      'Sensor disconnected - Check USB connection';

  @override
  String get aiRecommendation => 'AI Recommendation';

  @override
  String get pleaseSelectFieldFirst => 'Please select a field first';

  @override
  String sensorClaimedSuccess(String hardwareId) {
    return '✅ Sensor $hardwareId claimed successfully!';
  }

  @override
  String get sensorInUseError => '❌ Sensor is already in use by another user';

  @override
  String sensorReleasedSuccess(String hardwareId) {
    return '✅ Sensor $hardwareId released';
  }

  @override
  String get pleaseLoginToViewSensors => 'Please log in to view sensors';

  @override
  String get selectFieldToMonitor => 'Select Field to Monitor';

  @override
  String get noFieldsCreateFirst =>
      'No fields available. Create a field first.';

  @override
  String get chooseField => 'Choose a field';

  @override
  String get unknownField => 'Unknown Field';

  @override
  String get statusAvailable => 'AVAILABLE';

  @override
  String get statusOffline => 'OFFLINE';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String get statusInUse => 'IN USE';

  @override
  String get sensorOfflineMessage =>
      'Sensor is offline. Data hasn\'t been updated in over 15 seconds.';

  @override
  String get stopMonitoring => 'Stop Monitoring';

  @override
  String get noSensorDetected =>
      'No sensor detected. Please connect a USB sensor.';

  @override
  String get startMonitoring => 'Start Monitoring';

  @override
  String get sensorInUseByOther =>
      'This sensor is currently being used by another user';

  @override
  String get sensorsWillAppearHere =>
      'Sensors will appear here when they start sending data';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get firestoreSecurityRulesBlocking =>
      'Firestore Security Rules are blocking access.';

  @override
  String get noSensorsRegistered => 'No sensors registered';

  @override
  String get registerSensorInSensorsPage =>
      'Register a sensor in the Sensors page';

  @override
  String sensorLabel(String id) {
    return 'Sensor: $id';
  }

  @override
  String get needsAttention => 'needs attention';

  @override
  String get needsUrgentAttention => 'needs urgent attention';

  @override
  String get isHealthy => 'is healthy';

  @override
  String get cloudData => 'Cloud Data';

  @override
  String get bothView => 'Both';

  @override
  String get selectFieldLabel => 'Select Field';

  @override
  String get dateRangeLabel => 'Date Range';

  @override
  String get selectDatesPlaceholder => 'Select Dates';

  @override
  String get generateReportButton => 'GENERATE REPORT';

  @override
  String get generateReportTitle => 'Generate Report';

  @override
  String get generateReportMessage =>
      'Select a field and date range to view detailed insights.';
}
