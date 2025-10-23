# 🚀 Firebase Quick Start Guide

## ✅ What's Already Configured

Firebase has been configured for the **ngairrigate** project with the following setup:

### ✅ Web Configuration - COMPLETE
- Project ID: `ngairrigate`
- API Key: Configured in `lib/config/firebase_config.dart`
- All Firebase services ready for web platform

### ✅ Android Configuration - READY
- Gradle plugins configured
- Package name: `com.faminga.faminga_irrigation`
- Google Services plugin added

### ✅ iOS Configuration - READY
- Bundle ID: `com.faminga.irrigation`
- Info.plist ready for Firebase

## ⚡ 3-Step Setup Process

### Step 1: Add Your App to Firebase Console (5 minutes)

#### For Android:
1. Visit: https://console.firebase.google.com/project/ngairrigate
2. Click **"Add app"** → Select **Android** icon
3. Register app with package name: `com.faminga.faminga_irrigation`
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`
6. ✅ Done!

#### For iOS:
1. Visit: https://console.firebase.google.com/project/ngairrigate
2. Click **"Add app"** → Select **iOS** icon
3. Register app with bundle ID: `com.faminga.irrigation`
4. Download `GoogleService-Info.plist`
5. Place it in: `ios/Runner/GoogleService-Info.plist`
6. ✅ Done!

### Step 2: Enable Firebase Services (3 minutes)

In Firebase Console (https://console.firebase.google.com/project/ngairrigate):

1. **Authentication**
   - Go to: Build → Authentication
   - Click "Get Started"
   - Enable: Email/Password ✅
   - Enable: Google Sign-In ✅

2. **Firestore Database**
   - Go to: Build → Firestore Database
   - Click "Create database"
   - Start in **production mode**
   - Choose region: `us-central` (or closest to Rwanda)
   - Apply security rules from `FIREBASE_SETUP.md`

3. **Storage**
   - Go to: Build → Storage
   - Click "Get started"
   - Start in **production mode**
   - Choose same region as Firestore
   - Apply security rules from `FIREBASE_SETUP.md`

4. **Cloud Messaging**
   - Go to: Build → Cloud Messaging
   - Click "Get Started"
   - ✅ Automatically configured

### Step 3: Test Your Setup (2 minutes)

Run the app:
```bash
flutter pub get
flutter run
```

Check console for:
```
✅ Firebase initialized successfully
✅ Firestore configured with offline persistence
```

## 🔒 Quick Security Setup

Copy these rules to Firebase Console:

### Firestore Rules
Go to: Firestore Database → Rules
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
    
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
      
      match /{subcollection}/{document=**} {
        allow read, write: if isOwner(userId);
      }
    }
    
    match /fields/{fieldId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    match /sensors/{sensorId} {
      allow read, write: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    match /irrigation/{irrigationId} {
      allow read, write: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

### Storage Rules
Go to: Storage → Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    function isSizeValid() {
      return request.resource.size < 5 * 1024 * 1024; // 5MB
    }
    
    match /users/{userId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId) && isImage() && isSizeValid();
    }
    
    match /fields/{userId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId) && isImage() && isSizeValid();
    }
  }
}
```

## 🎯 Next Steps

After Firebase is working:

1. ✅ Test user registration and login
2. ✅ Test creating a field
3. ✅ Test adding sensors
4. ✅ Test irrigation controls
5. ✅ Test image uploads
6. ✅ Configure third-party APIs (OpenAI, Gemini, etc.)

## 📁 Files to Download from Firebase

| Platform | File | Location | Required |
|----------|------|----------|----------|
| Android | `google-services.json` | `android/app/` | Yes |
| iOS | `GoogleService-Info.plist` | `ios/Runner/` | Yes |

## ⚠️ Important Notes

1. **Template files provided**: 
   - `android/app/google-services.json.template`
   - `ios/Runner/GoogleService-Info.plist.template`
   
2. **Replace templates** with actual files from Firebase Console

3. **Never commit** actual API keys to public repositories

4. **Test on real devices** for best results

## 🆘 Troubleshooting

### Firebase initialization fails
- ✅ Check internet connection
- ✅ Verify `google-services.json` is in correct location
- ✅ Run `flutter clean` and `flutter pub get`
- ✅ Rebuild the app

### Authentication not working
- ✅ Enable Authentication in Firebase Console
- ✅ Add your app's SHA-1 fingerprint (Android)
- ✅ Enable sign-in methods (Email/Password, Google)

### Firestore permission denied
- ✅ Apply security rules from above
- ✅ Check user is authenticated
- ✅ Verify userId matches in rules

### Images not uploading
- ✅ Apply Storage rules from above
- ✅ Check file size < 5MB
- ✅ Verify file type is image

## 📚 Documentation Links

- [Full Firebase Setup Guide](./FIREBASE_SETUP.md)
- [Environment Variables](./ENV_VARIABLES.md)
- [Project README](./README.md)

## ✅ Setup Checklist

- [ ] Downloaded `google-services.json` for Android
- [ ] Placed `google-services.json` in `android/app/`
- [ ] Downloaded `GoogleService-Info.plist` for iOS
- [ ] Placed `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Enabled Authentication in Firebase Console
- [ ] Enabled Firestore Database
- [ ] Enabled Storage
- [ ] Applied Firestore security rules
- [ ] Applied Storage security rules
- [ ] Ran `flutter pub get`
- [ ] Tested app on device
- [ ] Verified Firebase initialization in console

## 🎉 You're All Set!

Once you see the success messages in your console, Firebase is ready to use!

For advanced configuration, see [FIREBASE_SETUP.md](./FIREBASE_SETUP.md)


