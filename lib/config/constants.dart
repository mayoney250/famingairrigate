/// App-wide constants
class AppConstants {
  // Private constructor
  AppConstants._();

  // App Information
  static const String appName = 'Faminga Irrigation';
  static const String appVersion = '1.0.0';
  static const String companyName = 'FAMINGA Limited';
  static const String supportEmail = 'akariclaude@gmail.com';
  static const String website = 'https://faminga.app';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String fieldsCollection = 'fields';
  static const String irrigationCollection = 'irrigation';
  static const String sensorsCollection = 'sensors';
  static const String sensorDataCollection = 'sensorData';
  static const String activitiesCollection = 'fieldActivities';
  static const String notificationsCollection = 'notifications';
  static const String subscriptionsCollection = 'subscriptions';
  static const String userPlansCollection = 'userPlans';

  // Sensor Types
  static const List<String> sensorTypes = [
    'Temperature',
    'Humidity',
    'Soil Moisture',
    'pH',
    'Light',
    'Water Flow',
  ];

  // Connection Methods
  static const List<String> connectionMethods = [
    'Wi-Fi',
    'Bluetooth',
    'LoRa',
    'IP Address',
  ];

  // Irrigation Methods
  static const List<String> irrigationMethods = [
    'Drip Irrigation',
    'Sprinkler',
    'Surface Irrigation',
    'Manual',
  ];

  // Water Source Types
  static const List<String> waterSourceTypes = [
    'Borehole',
    'River',
    'Dam',
    'Municipal Supply',
    'Rainwater Harvesting',
  ];

  // Subscription Plans
  static const String freePlan = 'free';
  static const String proPlan = 'pro';

  // Default Values
  static const int defaultSensorReadingInterval = 15; // minutes
  static const double defaultWaterSavingPercentage = 65.0;
  static const int maxFreeFields = 5;
  static const int maxFreeSensors = 3;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // API Endpoints (if needed)
  static const String baseUrl = 'https://api.faminga.app';
  static const String weatherApiEndpoint = '/weather';
  static const String marketApiEndpoint = '/market';

  // Shared Preferences Keys
  static const String themePreferenceKey = 'theme_preference';
  static const String languagePreferenceKey = 'language_preference';
  static const String userIdKey = 'user_id';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String lastSyncTimeKey = 'last_sync_time';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minFieldNameLength = 3;
  static const int maxFieldNameLength = 50;

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  static const String authErrorMessage = 'Authentication failed.';
  static const String permissionDeniedMessage = 'Permission denied.';

  // Success Messages
  static const String loginSuccessMessage = 'Welcome back!';
  static const String signupSuccessMessage =
      'Account created successfully. Please verify your email.';
  static const String updateSuccessMessage = 'Updated successfully!';
  static const String deleteSuccessMessage = 'Deleted successfully!';

  // Units
  static const String hectareUnit = 'ha';
  static const String litersUnit = 'L';
  static const String cubicMetersUnit = 'm³';
  static const String celsiusUnit = '°C';
  static const String percentageUnit = '%';
  static const String rwfCurrency = 'RWF';
  static const String usdCurrency = 'USD';
}

