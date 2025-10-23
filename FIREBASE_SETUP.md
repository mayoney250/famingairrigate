# Firebase Configuration Guide for Faminga Irrigation App

## ✅ Firebase Project Details

- **Project ID**: `ngairrigate`
- **Project Name**: NG Airrigate
- **Console**: [Firebase Console](https://console.firebase.google.com/project/ngairrigate)

## 🔧 Current Configuration Status

### Web Configuration ✅
The web configuration has been set up in `lib/config/firebase_config.dart` with the following details:
- API Key: `AIzaSyD95nh8G5koVV04Oqmq_ni9n0wl0YgbHC8`
- Auth Domain: `ngairrigate.firebaseapp.com`
- Project ID: `ngairrigate`
- Storage Bucket: `ngairrigate.firebasestorage.app`
- Messaging Sender ID: `622157404711`
- App ID: `1:622157404711:web:0ef6a4c4d838c75aef0c02`
- Measurement ID: `G-PHY8RXWZER`

### Android Configuration ⚠️
**Action Required**: You need to add your Android app to Firebase and download the configuration file.

#### Steps to configure Android:
1. Go to [Firebase Console](https://console.firebase.google.com/project/ngairrigate)
2. Click on the Android icon to add an Android app
3. Register app with package name: `com.faminga.irrigation`
4. Download `google-services.json`
5. Place the file in: `android/app/google-services.json`

### iOS Configuration ⚠️
**Action Required**: You need to add your iOS app to Firebase and download the configuration file.

#### Steps to configure iOS:
1. Go to [Firebase Console](https://console.firebase.google.com/project/ngairrigate)
2. Click on the iOS icon to add an iOS app
3. Register app with bundle ID: `com.faminga.irrigation`
4. Download `GoogleService-Info.plist`
5. Place the file in: `ios/Runner/GoogleService-Info.plist`
6. Open `ios/Runner.xcworkspace` in Xcode
7. Drag `GoogleService-Info.plist` into the Runner target

## 🔐 Security Configuration

### Firestore Security Rules
Create these security rules in the Firebase Console under Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
      
      // User subcollections
      match /{subcollection}/{document=**} {
        allow read, write: if isOwner(userId);
      }
    }
    
    // Fields collection
    match /fields/{fieldId} {
      allow read: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || resource.data.isPublic == true);
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    // Sensors collection
    match /sensors/{sensorId} {
      allow read: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
      allow write: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Irrigation systems
    match /irrigation/{irrigationId} {
      allow read, write: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    // Public collections (read-only for all authenticated users)
    match /crops/{cropId} {
      allow read: if isAuthenticated();
      allow write: if false; // Only admin can write (via server)
    }
    
    match /governmentPrograms/{programId} {
      allow read: if isAuthenticated();
      allow write: if false; // Only admin can write (via server)
    }
    
    // User plans (subscriptions)
    match /userPlans/{userId} {
      allow read: if isOwner(userId);
      allow write: if false; // Only server can write after payment
    }
  }
}
```

### Firebase Storage Rules
Create these rules in Firebase Console under Storage > Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    function isSizeValid() {
      return request.resource.size < 5 * 1024 * 1024; // 5MB
    }
    
    // User profile images
    match /users/{userId}/profile/{imageId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId) && isImage() && isSizeValid();
    }
    
    // Field images
    match /fields/{userId}/{fieldId}/{imageId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId) && isImage() && isSizeValid();
    }
    
    // Disease detection images
    match /disease-detection/{userId}/{imageId} {
      allow read, write: if isOwner(userId) && isImage() && isSizeValid();
    }
    
    // Marketplace product images
    match /marketplace/{userId}/products/{imageId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId) && isImage() && isSizeValid();
    }
    
    // Sensor data exports
    match /exports/{userId}/{exportId} {
      allow read, write: if isOwner(userId);
    }
  }
}
```

## 🎯 Firebase Services to Enable

Enable these services in your Firebase Console:

### ✅ Authentication
1. Go to Authentication > Sign-in method
2. Enable the following providers:
   - ✅ Email/Password
   - ✅ Google Sign-In
   - ⚠️ Phone (for 2FA - optional)

### ✅ Firestore Database
1. Go to Firestore Database
2. Create database in production mode
3. Select region: `us-central1` or closest to Rwanda
4. Apply security rules (see above)

### ✅ Storage
1. Go to Storage
2. Get started
3. Select region: `us-central1` or closest to Rwanda
4. Apply security rules (see above)

### ✅ Cloud Messaging (FCM)
1. Go to Cloud Messaging
2. Enable Firebase Cloud Messaging API
3. No additional configuration needed (uses existing credentials)

### ✅ Analytics
1. Go to Analytics
2. Enable Google Analytics
3. Create or link Analytics account
4. Measurement ID already configured: `G-PHY8RXWZER`

### ⚠️ Crashlytics (Optional but Recommended)
1. Go to Crashlytics
2. Enable Crashlytics
3. Add the following to your app:

**Android**: Already configured in `build.gradle.kts`

**iOS**: Add the following to your `ios/Podfile`:
```ruby
pod 'FirebaseCrashlytics'
```

### ⚠️ Performance Monitoring (Optional but Recommended)
1. Go to Performance
2. Enable Performance Monitoring
3. No additional configuration needed

## 🌍 Firestore Data Structure

### Collections Overview

```
📁 users/{userId}
├── Basic user profile
└── 📁 Subcollections:
    ├── following/{followedUserId}
    ├── followers/{followerId}
    ├── products/{productId}
    ├── irrigation/{irrigationId}
    ├── transactions/{transactionId}
    ├── notifications/{notificationId}
    └── sentRequests/{recipientId}

📁 fields/{fieldId}
├── Field details, boundaries, crops
└── Financial and agricultural records

📁 sensors/{sensorId}
└── Sensor data and configuration

📁 userPlans/{userId}
└── Subscription information

📁 irrigation/{irrigationId}
└── Irrigation system details

📁 crops/{cropId}
└── Public crop information (admin only write)

📁 governmentPrograms/{programId}
└── Available programs (admin only write)

📁 products/{productId}
└── Marketplace products

📁 chats/{chatId}
└── User-to-user messaging

📁 notifications/{userId}/notifications/{notificationId}
└── User notifications
```

## 🔑 Environment Variables

Create a `.env` file in the root directory (gitignored) with:

```env
# Firebase Configuration (already in firebase_config.dart)
FIREBASE_PROJECT_ID=ngairrigate
FIREBASE_API_KEY=AIzaSyD95nh8G5koVV04Oqmq_ni9n0wl0YgbHC8
FIREBASE_AUTH_DOMAIN=ngairrigate.firebaseapp.com
FIREBASE_STORAGE_BUCKET=ngairrigate.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=622157404711
FIREBASE_APP_ID=1:622157404711:web:0ef6a4c4d838c75aef0c02
FIREBASE_MEASUREMENT_ID=G-PHY8RXWZER

# Third-party API Keys (get from your .env file)
OPENAI_API_KEY=your_openai_key_here
GEMINI_API_KEY=your_gemini_key_here
PERPLEXITY_API_KEY=your_perplexity_key_here
SENDGRID_API_KEY=your_sendgrid_key_here
TWILIO_ACCOUNT_SID=your_twilio_sid_here
TWILIO_AUTH_TOKEN=your_twilio_token_here
FLUTTERWAVE_PUBLIC_KEY=your_flutterwave_key_here
GOOGLE_MAPS_API_KEY=your_maps_key_here
```

## 🧪 Testing Firebase Connection

Run the app and check the console for:
```
✅ Firebase initialized successfully
✅ Firestore configured with offline persistence
```

If you see errors, check:
1. Internet connection
2. Firebase project configuration
3. Platform-specific configuration files (google-services.json, GoogleService-Info.plist)
4. Firebase services are enabled in console

## 📱 Platform-Specific Setup

### Android Setup
1. Ensure `google-services.json` is in `android/app/`
2. Check `android/app/build.gradle.kts` has:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

3. Check `android/build.gradle.kts` has:
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

### iOS Setup
1. Ensure `GoogleService-Info.plist` is in `ios/Runner/`
2. Open `ios/Runner.xcworkspace` in Xcode
3. Verify the file is added to the Runner target
4. Check iOS deployment target is set to 12.0 or higher

### Web Setup
✅ Already configured! No additional steps needed.

## 🔄 Offline Persistence

The app is configured with offline persistence:
- Firestore caches data automatically on mobile
- Users can work offline
- Data syncs when connection is restored
- Pending operations are queued and executed when online

## 🚀 Next Steps

1. ✅ Firebase configuration completed
2. ⚠️ Add Android app to Firebase Console and download google-services.json
3. ⚠️ Add iOS app to Firebase Console and download GoogleService-Info.plist
4. ⚠️ Enable required Firebase services (Authentication, Firestore, Storage, FCM)
5. ⚠️ Set up Firestore security rules
6. ⚠️ Set up Storage security rules
7. ⚠️ Test Firebase connection on all platforms

## 📞 Support

For Firebase issues:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

For Faminga-specific issues:
- Email: akariclaude@gmail.com
- Company: FAMINGA Limited, Rwanda


