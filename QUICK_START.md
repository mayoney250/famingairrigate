# Faminga Irrigation - Quick Start Guide

## ⚡ Get Started in 5 Minutes

### Step 1: Enable Developer Mode (Windows Only)

Open PowerShell as Administrator and run:
```powershell
start ms-settings:developers
```
Then toggle "Developer Mode" to ON.

### Step 2: Check Flutter Installation

```bash
flutter doctor
```

Make sure all checkmarks are green. If not, follow the instructions provided.

### Step 3: Navigate to Project

```bash
cd d:\irrigation\faminga_irrigation
```

### Step 4: Get Dependencies (Already Done!)

Dependencies are already installed, but if you need to reinstall:
```bash
flutter pub get
```

### Step 5: Generate Localization

```bash
flutter gen-l10n
```

### Step 6: Configure Firebase (REQUIRED BEFORE RUNNING)

#### Option A: Quick Test (Mock Setup - NOT RECOMMENDED)
For initial testing only, you can temporarily comment out Firebase initialization in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Uncomment after Firebase setup
  // await FirebaseConfig.initialize();
  
  runApp(const FamingaIrrigationApp());
}
```

#### Option B: Proper Firebase Setup (RECOMMENDED)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project: "Faminga Irrigation"
3. Add Android app:
   - Package name: `com.faminga.irrigation`
   - Download `google-services.json`
   - Place in: `android/app/google-services.json`

4. Add iOS app (if developing for iOS):
   - Bundle ID: `com.faminga.irrigation`
   - Download `GoogleService-Info.plist`
   - Place in: `ios/Runner/GoogleService-Info.plist`

5. Enable Authentication:
   - Go to Authentication → Sign-in method
   - Enable "Email/Password"

6. Enable Firestore:
   - Go to Firestore Database
   - Create database (Start in production mode)

7. Update `lib/config/firebase_config.dart` with your credentials

### Step 7: Run the App

```bash
# List available devices
flutter devices

# Run on connected device
flutter run

# Or run on specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release
```

### Step 8: Test the App

1. Launch app → Should show splash screen
2. Navigate to Login screen
3. Click "Register" to create account
4. Fill in registration form
5. Complete registration
6. Login with credentials
7. Explore dashboard

## 🔥 Common Commands

### Development

```bash
# Hot reload (r key while app is running)
r

# Hot restart (R key while app is running)
R

# Quit (q key while app is running)
q

# Run with verbose logging
flutter run -v

# Run on specific device
flutter run -d windows
flutter run -d chrome
flutter run -d <device-id>
```

### Building

```bash
# Build Android APK
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build iOS (requires macOS)
flutter build ios --release

# Build for Windows
flutter build windows --release
```

### Maintenance

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Generate localization
flutter gen-l10n

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

## 🐛 Troubleshooting

### Error: "No Firebase App '[DEFAULT]' has been created"
**Solution**: Configure Firebase following Step 6 above.

### Error: "Unable to resolve dependency"
**Solution**:
```bash
flutter clean
flutter pub get
```

### Error: Android build fails
**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### Error: iOS build fails
**Solution**:
```bash
cd ios
pod deinstall
pod install
cd ..
flutter clean
flutter build ios
```

### Error: Localization not working
**Solution**:
```bash
flutter gen-l10n
flutter clean
flutter pub get
flutter run
```

### Error: "Developer Mode required" (Windows)
**Solution**: Enable Developer Mode in Windows Settings (Step 1 above)

## 📱 Recommended Test Devices

### Android
- Physical device with Android 6.0+ (API 23+)
- Android Emulator (API 30 or higher recommended)

### iOS
- Physical device with iOS 12.0+
- iOS Simulator

### Desktop
- Windows 10/11
- Chrome browser (for web testing)

## 🎯 Quick Test Checklist

- [ ] App launches successfully
- [ ] Splash screen displays
- [ ] Navigation to login works
- [ ] Registration form validates inputs
- [ ] Can navigate between screens
- [ ] Theme colors match Faminga brand
- [ ] All four languages available (en, rw, fr, sw)
- [ ] Bottom navigation works
- [ ] Dashboard displays correctly

## 🔑 Default Test Account (After Setup)

Create a test account with:
- Email: `test@faminga.app`
- Password: `Test1234!`
- First Name: Test
- Last Name: User

## 📞 Need Help?

- **Documentation**: Check `SETUP_INSTRUCTIONS.md` and `README.md`
- **Email**: akariclaude@gmail.com
- **Website**: https://faminga.app

## 🎉 You're Ready!

Your Faminga Irrigation app is set up and ready for development. Start coding and build amazing features for African farmers!

---

**Pro Tip**: Use `flutter run --hot` for faster development with hot reload enabled by default.

**Remember**: Always test on real devices before releasing to production!

