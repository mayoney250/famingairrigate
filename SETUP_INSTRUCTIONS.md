# Faminga Irrigation - Setup Instructions

Complete setup guide for the Faminga Irrigation Flutter application.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0 or higher)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)
- [Firebase CLI](https://firebase.google.com/docs/cli) (optional but recommended)
- [Xcode](https://developer.apple.com/xcode/) (for iOS development on macOS)

## Step 1: Clone the Repository

```bash
git clone https://github.com/faminga/faminga-irrigation.git
cd faminga-irrigation
```

## Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

## Step 3: Firebase Setup

### 3.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Name it "Faminga Irrigation" (or your preferred name)
4. Follow the setup wizard

### 3.2 Enable Firebase Services

Enable the following services in your Firebase project:

- **Authentication**
  - Go to Authentication > Sign-in method
  - Enable Email/Password authentication
  - Enable Google Sign-In (optional)

- **Cloud Firestore**
  - Go to Firestore Database
  - Create database in production mode
  - Start in your preferred region (e.g., `us-central1` or closest to Rwanda)

- **Firebase Storage**
  - Go to Storage
  - Get started with default settings

- **Cloud Messaging (FCM)**
  - Automatically enabled with Firebase setup

- **Analytics** (optional but recommended)
  - Automatically enabled with Firebase setup

### 3.3 Add Android App

1. In Firebase Console, click "Add App" → Android
2. Package name: `com.faminga.irrigation`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

### 3.4 Add iOS App

1. In Firebase Console, click "Add App" → iOS
2. Bundle ID: `com.faminga.irrigation`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

### 3.5 Update Firebase Configuration

Edit `lib/config/firebase_config.dart` and update with your Firebase credentials:

```dart
// Update these values from your Firebase project settings
apiKey: 'YOUR_API_KEY',
authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
projectId: 'YOUR_PROJECT_ID',
storageBucket: 'YOUR_PROJECT_ID.appspot.com',
messagingSenderId: 'YOUR_SENDER_ID',
appId: 'YOUR_APP_ID',
```

## Step 4: Configure Firestore Security Rules

In Firebase Console, go to Firestore Database → Rules and update:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User documents
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Irrigation systems
    match /irrigation/{irrigationId} {
      allow read: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Fields
    match /fields/{fieldId} {
      allow read: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Sensors
    match /sensors/{sensorId} {
      allow read: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Notifications
    match /notifications/{userId}/notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

## Step 5: Configure Storage Security Rules

In Firebase Console, go to Storage → Rules and update:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /fields/{fieldId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Step 6: Google Maps Setup (Optional)

### 6.1 Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
4. Create API credentials (API Key)

### 6.2 Configure Android

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
</application>
```

### 6.3 Configure iOS

Edit `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

## Step 7: Generate Localization Files

```bash
flutter gen-l10n
```

## Step 8: Run the App

### Development Mode

```bash
flutter run
```

### Specific Device

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

## Step 9: Building for Production

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Google Play)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode and archive.

## Step 10: Environment-Specific Configuration (Optional)

### Create environment configuration

Create different Firebase projects for dev/staging/production:

**Development:**
```bash
flutter run --dart-define=ENVIRONMENT=development
```

**Production:**
```bash
flutter run --dart-define=ENVIRONMENT=production
```

## Troubleshooting

### Common Issues

**Issue: Firebase initialization error**
- Verify `google-services.json` and `GoogleService-Info.plist` are in correct locations
- Check Firebase configuration in `firebase_config.dart`

**Issue: Dependencies conflict**
```bash
flutter pub get --verbose
flutter clean
flutter pub get
```

**Issue: iOS build fails**
```bash
cd ios
pod deinstall
pod install
cd ..
flutter clean
flutter build ios
```

**Issue: Android build fails**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk
```

**Issue: Localization not working**
```bash
flutter gen-l10n
flutter clean
flutter pub get
```

## Testing

### Run unit tests

```bash
flutter test
```

### Run integration tests

```bash
flutter drive --target=test_driver/app.dart
```

### Test coverage

```bash
flutter test --coverage
```

## Next Steps

1. Set up Firebase Cloud Functions (optional)
2. Integrate third-party APIs (Weather, Market Intelligence)
3. Set up CI/CD pipeline
4. Configure app signing for release
5. Submit to app stores

## Support

For issues and questions:
- Email: akariclaude@gmail.com
- Website: https://faminga.app

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Faminga Developer Portal](https://faminga.app/developers)

---

**Happy Coding! 🚀**

