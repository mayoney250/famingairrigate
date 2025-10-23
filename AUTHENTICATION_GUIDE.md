# 🔐 Firebase Authentication Guide

## ✅ Authentication Features Implemented

Your Faminga Irrigation app now has a complete authentication system with the following features:

### 1. **Email & Password Authentication** ✅
- User registration with email verification
- Secure login with Firebase Authentication
- Password validation (minimum 8 characters)
- Email format validation
- Error handling with user-friendly messages

### 2. **Google Sign-In** ✅ NEW!
- One-tap Google authentication
- Automatic user profile creation from Google account
- Seamless integration with Firebase Auth
- Fallback icon when Google logo not available

### 3. **Password Management** ✅
- Password reset via email
- Secure password reset flow
- Email delivery via SendGrid (configured)

### 4. **User Profile Management** ✅
- Automatic Firestore user document creation
- User data includes:
  - First name & last name
  - Email address
  - Phone number (optional)
  - Avatar/profile picture
  - Online status
  - Last active timestamp
  - User role (farmer by default)
  - Language preference (en, rw, fr, sw)
  - Theme preference (light/dark)
  - Location (district, province, country)

### 5. **Session Management** ✅
- Persistent authentication state
- Automatic sign-in on app restart
- Auth state listener for real-time updates
- Secure sign-out with status updates

---

## 📱 Authentication Screens

### 1. Login Screen
**Path**: `lib/screens/auth/login_screen.dart`

**Features**:
- Email and password input fields
- Password visibility toggle
- "Forgot Password?" link
- Email/Password login button
- Google Sign-In button
- Link to registration screen

**Validation**:
- Valid email format required
- Password minimum 8 characters
- Real-time error messages

### 2. Register Screen
**Path**: `lib/screens/auth/register_screen.dart`

**Features**:
- First name & last name fields
- Email address field
- Phone number (optional)
- Password field with confirmation
- Password visibility toggle for both fields
- Email verification after successful registration

**Validation**:
- All required fields validated
- Email format checked
- Password confirmation match
- Minimum password length enforced

### 3. Forgot Password Screen
**Path**: `lib/screens/auth/forgot_password_screen.dart`

**Features**:
- Email input for password reset
- Reset link sent via email
- Success dialog confirmation
- Return to login screen

---

## 🔧 Technical Implementation

### Architecture

```
lib/
├── services/
│   └── auth_service.dart          # Firebase Auth & Firestore operations
├── providers/
│   └── auth_provider.dart         # State management with Provider
├── screens/
│   └── auth/
│       ├── login_screen.dart      # Login UI
│       ├── register_screen.dart   # Registration UI
│       └── forgot_password_screen.dart  # Password reset UI
└── models/
    └── user_model.dart            # User data model
```

### AuthService Methods

```dart
// Email & Password
Future<UserCredential?> signUpWithEmailAndPassword()
Future<UserCredential?> signInWithEmailAndPassword()

// Google Sign-In
Future<UserCredential?> signInWithGoogle()

// Password Management
Future<void> sendPasswordResetEmail(String email)
Future<void> sendEmailVerification()
Future<bool> isEmailVerified()

// User Management
Future<UserModel?> getUserData(String userId)
Future<void> updateUserData(String userId, Map<String, dynamic> data)

// Session Management
Future<void> signOut()
Future<void> deleteAccount()
```

### AuthProvider State Management

```dart
// State
UserModel? currentUser          // Current user data
bool isLoading                  // Loading state
String? errorMessage            // Error handling
bool isAuthenticated            // Auth status

// Methods
Future<bool> signUp()           // Register new user
Future<bool> signIn()           // Email/password login
Future<bool> signInWithGoogle() // Google Sign-In
Future<void> signOut()          // Logout
Future<bool> sendPasswordResetEmail()
Future<void> updateProfile()
```

---

## 🔥 Firebase Console Setup

### Step 1: Enable Authentication Methods

1. Go to [Firebase Console](https://console.firebase.google.com/project/ngairrigate)
2. Navigate to **Authentication** → **Sign-in method**
3. Enable the following:
   - ✅ **Email/Password**
   - ✅ **Google**

### Step 2: Configure Google Sign-In

#### For Android:
1. In Firebase Console, go to **Authentication** → **Sign-in method** → **Google**
2. Add your app's **SHA-1** fingerprint:

```bash
# Get SHA-1 fingerprint (debug)
cd android
./gradlew signingReport

# Or using keytool
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

3. Copy the SHA-1 fingerprint
4. Go to **Project Settings** → **Your apps** → Android app
5. Add SHA-1 to **SHA certificate fingerprints**
6. Download new `google-services.json`
7. Replace in `android/app/google-services.json`

#### For iOS:
1. In Firebase Console, go to **Authentication** → **Sign-in method** → **Google**
2. Download `GoogleService-Info.plist`
3. Open `ios/Runner.xcworkspace` in Xcode
4. Drag `GoogleService-Info.plist` into the Runner target
5. Update `Info.plist` with URL schemes from Firebase Console

#### For Web:
Already configured! No additional setup needed.

---

## 🎯 Usage Examples

### 1. Sign Up with Email & Password

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);

final success = await authProvider.signUp(
  email: 'farmer@example.com',
  password: 'securePassword123',
  firstName: 'John',
  lastName: 'Doe',
  phoneNumber: '+250788123456', // Optional
);

if (success) {
  // Registration successful
  // Email verification sent
  // Redirect to email confirmation screen
}
```

### 2. Sign In with Email & Password

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);

final success = await authProvider.signIn(
  email: 'farmer@example.com',
  password: 'securePassword123',
);

if (success) {
  // Login successful
  // Navigate to dashboard
  Get.offAllNamed(AppRoutes.dashboard);
}
```

### 3. Sign In with Google

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);

final success = await authProvider.signInWithGoogle();

if (success) {
  // Google sign-in successful
  // User profile automatically created
  // Navigate to dashboard
  Get.offAllNamed(AppRoutes.dashboard);
}
```

### 4. Check Authentication State

```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    if (authProvider.isAuthenticated) {
      // User is logged in
      return DashboardScreen();
    } else {
      // User is not logged in
      return LoginScreen();
    }
  },
)
```

### 5. Sign Out

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);

await authProvider.signOut();

// User signed out
// Navigate to login screen
Get.offAllNamed(AppRoutes.login);
```

---

## 🛡️ Security Features

### 1. **Email Verification**
- Automatic verification email sent on registration
- Users must verify email before full access
- Re-send verification email option available

### 2. **Password Security**
- Minimum 8 characters required
- Firebase handles password hashing
- Passwords never stored in plain text

### 3. **Firestore Security Rules**

Apply these rules in Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users can only read/write their own data
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }
    
    // User subcollections
    match /users/{userId}/{document=**} {
      allow read, write: if isOwner(userId);
    }
  }
}
```

### 4. **Online Status Tracking**
- Automatically updates on sign-in
- Updates on sign-out
- Shows last active timestamp

---

## 🎨 UI/UX Features

### 1. **Loading States**
- Loading indicators during authentication
- Disabled buttons during processing
- Prevents multiple submissions

### 2. **Error Handling**
- User-friendly error messages
- Color-coded error snackbars
- Specific error messages for each scenario:
  - Weak password
  - Email already in use
  - User not found
  - Wrong password
  - Invalid email
  - Account disabled
  - Too many requests

### 3. **Success Feedback**
- Success dialogs for important actions
- Automatic navigation on success
- Clear confirmation messages

### 4. **Form Validation**
- Real-time validation
- Clear error messages
- Required field indicators
- Email format validation
- Password strength requirements

---

## 📊 User Data Structure

### Firestore Document: `users/{userId}`

```json
{
  "userId": "firebase_uid",
  "email": "farmer@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+250788123456",
  "avatar": "https://...",
  "isActive": true,
  "createdAt": "2024-10-23T...",
  "tokens": ["fcm_token_1", "fcm_token_2"],
  "isOnline": true,
  "lastActive": "2024-10-23T...",
  "about": "Farmer in Bugesera",
  "isPublic": true,
  "district": "Bugesera",
  "province": "Eastern Province",
  "country": "Rwanda",
  "address": "Sector, Cell, Village",
  "role": "farmer",
  "languagePreference": "rw",
  "themePreference": "light"
}
```

---

## 🚀 Testing Authentication

### Manual Testing Checklist:

- [ ] Register new user with email/password
- [ ] Receive verification email
- [ ] Login with correct credentials
- [ ] Login with incorrect credentials (should fail)
- [ ] Sign in with Google
- [ ] Password reset flow
- [ ] Sign out
- [ ] Check persistence (close and reopen app)
- [ ] Update user profile
- [ ] View other user profiles
- [ ] Online status updates correctly

### Test Users:

Create test accounts for different scenarios:
- Verified email user
- Unverified email user
- Google sign-in user
- User with profile picture
- User without profile picture

---

## 🔄 Authentication Flow

```
1. App Launch
   ├─> Check Auth State
   ├─> If Authenticated
   │   ├─> Load User Data
   │   └─> Navigate to Dashboard
   └─> If Not Authenticated
       └─> Show Login Screen

2. Login/Register
   ├─> Email/Password
   │   ├─> Validate Input
   │   ├─> Firebase Auth
   │   ├─> Create/Update Firestore Doc
   │   └─> Navigate to Dashboard
   └─> Google Sign-In
       ├─> Google OAuth Flow
       ├─> Firebase Auth with Credential
       ├─> Create/Update Firestore Doc
       └─> Navigate to Dashboard

3. Sign Out
   ├─> Update Online Status
   ├─> Firebase Sign Out
   ├─> Clear Local State
   └─> Navigate to Login
```

---

## 📝 Next Steps

### To Complete Authentication Setup:

1. **Enable Services in Firebase Console**
   - Go to https://console.firebase.google.com/project/ngairrigate
   - Enable Email/Password authentication
   - Enable Google authentication
   - Configure authorized domains

2. **Add SHA-1 Fingerprint (Android)**
   - Get SHA-1 from debug keystore
   - Add to Firebase Console
   - Download new google-services.json

3. **Test on Real Devices**
   - Test email/password flow
   - Test Google Sign-In
   - Test password reset
   - Verify email verification works

4. **Optional Enhancements**
   - Add phone number authentication
   - Add Apple Sign-In (iOS)
   - Add biometric authentication
   - Add two-factor authentication (2FA)
   - Add email link authentication

---

## 🆘 Troubleshooting

### Google Sign-In Not Working?

**Problem**: Google Sign-In button does nothing
**Solution**: 
- Check SHA-1 fingerprint is added in Firebase Console
- Verify Google Sign-In is enabled in Firebase Console
- Check `google-services.json` is up to date
- Ensure internet connection is available

### Email Not Sending?

**Problem**: Verification/reset emails not received
**Solution**:
- Check spam folder
- Verify SendGrid API key is configured
- Check Firebase Console → Authentication → Templates
- Verify email is not blocked

### User Not Found Error?

**Problem**: "No user found with this email"
**Solution**:
- User needs to register first
- Check email spelling
- Verify Firebase Authentication is enabled

---

## 📞 Support

For authentication issues:
- Firebase Documentation: https://firebase.google.com/docs/auth
- FlutterFire Auth: https://firebase.flutter.dev/docs/auth/overview
- Google Sign-In Package: https://pub.dev/packages/google_sign_in

For Faminga-specific issues:
- Email: akariclaude@gmail.com
- Company: FAMINGA Limited, Rwanda

---

**Built with ❤️ for African farmers by Faminga**

