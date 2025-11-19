# Faminga Irrigation

**Smart Irrigation Management for African Farmers**

A Flutter-based mobile application for managing IoT-powered precision irrigation systems, empowering farmers with data-driven insights to optimize water usage and improve crop yields.

## Features

- 🔐 **Authentication**: Secure email/password authentication with Firebase
- 💧 **Irrigation Management**: Monitor and control irrigation systems in real-time
- 📊 **Dashboard**: Visual insights on water usage, savings, and system performance
- 🌾 **Field Management**: Map-based field creation and monitoring
- 📡 **IoT Sensors**: Integration with temperature, moisture, pH, and other sensors
- 🌍 **Multi-language Support**: English, Kinyarwanda, French, and Swahili
- 🎨 **Brand Consistency**: Official Faminga brand colors and design system
- ☁️ **Cloud Sync**: Real-time data synchronization with Firebase

## Technology Stack

- **Framework**: Flutter 3.0+
- **Backend**: Firebase (Auth, Firestore, Storage, Analytics)
- **State Management**: Provider + GetX
- **UI**: Material Design 3 with custom theming
- **Maps**: Google Maps Flutter
- **Charts**: FL Chart + Syncfusion Charts
- **Internationalization**: Flutter Intl

## Brand Colors

- **Primary Orange**: `#D47B0F` - Main brand color
- **Dark Green**: `#2D4D31` - Text and professional elements
- **White**: `#FFFFFF` - Clean backgrounds
- **Cream**: `#FFF5EA` - Light backgrounds
- **Black**: `#000000` - Strong contrast

## Project Structure

```
lib/
├── config/          # App configuration (Firebase, theme, colors, constants)
├── models/          # Data models (User, Field, Irrigation, Sensor)
├── services/        # Business logic services (Auth, Firestore, Irrigation)
├── providers/       # State management providers
├── screens/         # UI screens (Auth, Dashboard, Irrigation, etc.)
├── widgets/         # Reusable widgets
├── utils/           # Helper functions and utilities
├── routes/          # App routing configuration
├── l10n/            # Internationalization files
└── main.dart        # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Firebase account
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/faminga/faminga-irrigation.git
cd faminga-irrigation
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase:

**✅ Firebase is already configured for project: `ngairrigate`**

**Quick Setup (5 minutes):**
- See [FIREBASE_QUICK_START.md](./FIREBASE_QUICK_START.md) for step-by-step guide
- Download `google-services.json` for Android from [Firebase Console](https://console.firebase.google.com/project/ngairrigate)
- Download `GoogleService-Info.plist` for iOS from Firebase Console
- Place them in the appropriate directories:
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`

**Complete Guide:**
- See [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) for detailed configuration
- Includes security rules, API setup, and troubleshooting

4. Configure Third-Party APIs (Optional):
   - OpenAI for disease detection
   - Google Gemini for AI assistant
   - Flutterwave for payments
   - See [ENV_VARIABLES.md](./ENV_VARIABLES.md) for complete list

5. Run the app:
```bash
flutter run
```

You should see:
```
✅ Firebase initialized successfully
✅ Firestore configured with offline persistence
```

### Building for Production

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## Configuration

### Firebase Collections

The app uses the following Firestore collections:

- `users` - User profiles and settings
- `fields` - Farm field information
- `irrigation` - Irrigation system data
- `sensors` - IoT sensor configurations
- `sensorData` - Real-time sensor readings
- `fieldActivities` - Field activities and tasks
- `notifications` - User notifications
- `subscriptions` - Subscription plans

### Security Rules

Implement proper Firestore security rules to protect user data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /irrigation/{irrigationId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    // Add rules for other collections
  }
}
```

## Internationalization

The app supports 4 languages:

- **English (en)** - Default
- **Kinyarwanda (rw)**
- **French (fr)**
- **Swahili (sw)**

To add or update translations, edit the ARB files in `lib/l10n/`:

- `app_en.arb`
- `app_rw.arb`
- `app_fr.arb`
- `app_sw.arb`

Then run:
```bash
flutter gen-l10n
```

## Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Flutter best practices
- Use meaningful variable and function names
- Add comments for complex logic
- Keep lines under 80 characters
- Use const constructors where possible

## Testing

Run tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test
```

## License

Copyright © 2024 FAMINGA Limited. All rights reserved.

## Contact

**FAMINGA Limited**
- Email: akariclaude@gmail.com
- Website: [https://faminga.app](https://faminga.app)
- Website: [https://ihinga.com](https://ihinga.com)

## Acknowledgments

- Farmers of Rwanda and East Africa
- Firebase team for the excellent backend platform
- Flutter community for amazing packages
- All contributors and supporters

---

**Built with ❤️ for African farmers by Faminga**
