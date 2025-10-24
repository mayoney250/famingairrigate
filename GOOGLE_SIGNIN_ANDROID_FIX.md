# Fix Google Sign-In on Android - Error 10

**Error**: `ApiException: 10:` means your SHA-1 certificate fingerprint is not registered in Firebase Console.

---

## ✅ **Solution: Register SHA-1 Fingerprint**

### **Step 1: Get Your SHA-1 Fingerprint**

#### **Option 1: Using Android Studio (Easiest)**

1. Open Android Studio
2. Right side panel → Click **Gradle** (elephant icon)
3. Navigate to: **faminga_irrigation** → **android** → **Tasks** → **android** → **signingReport**
4. Double-click **signingReport**
5. Look for output in the **Run** panel at the bottom
6. Find the **SHA-1** line under **Variant: debug**
7. Copy the SHA-1 fingerprint (looks like: `AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE`)

#### **Option 2: Using Command Line**

**Find Java keytool path:**
```bash
# Usually in one of these locations:
C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe
C:\Program Files\Java\jdk-XX.X.X\bin\keytool.exe
```

**Run keytool command:**
```bash
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android
```

**Copy the SHA-1 from the output.**

#### **Option 3: Using PowerShell (if above don't work)**

```powershell
# Find keytool first
where.exe /R "C:\Program Files" keytool.exe

# Then run with the found path
& "PATH_TO_KEYTOOL_FROM_ABOVE" -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android
```

---

### **Step 2: Add SHA-1 to Firebase Console**

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. Select your project: **ngairrigate**
3. Click the **⚙️ Settings** icon (top left) → **Project settings**
4. Scroll down to **Your apps** section
5. Find your **Android app** (`com.faminga.faminga_irrigation`)
6. Click **Add fingerprint** button
7. **Paste your SHA-1** fingerprint
8. Click **Save**

---

### **Step 3: Download Updated google-services.json**

After adding SHA-1:

1. Still in Firebase Console → Project Settings → Your Android app
2. Click **Download google-services.json**
3. **Replace** the file at: `android/app/google-services.json`

---

### **Step 4: Clean and Rebuild**

Run these commands:

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run on your device
flutter run
```

---

## 🎯 **What Each Error Code Means:**

| Error Code | Meaning | Solution |
|------------|---------|----------|
| **10** | Developer console configuration issue / SHA-1 not registered | Add SHA-1 to Firebase (this guide) |
| **12500** | Internal error (outdated Play Services) | Update Google Play Services on device |
| **12501** | User cancelled sign-in | Normal behavior, no fix needed |
| **7** | Network error | Check internet connection |

---

## 🔐 **For Production/Release Build:**

When you build a **release APK**, you'll need to:

1. Generate a release keystore
2. Get SHA-1 from release keystore
3. Add **both debug AND release SHA-1** to Firebase Console

**Get Release SHA-1:**
```bash
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

---

## ✅ **Verify Configuration**

After following the steps above, you should see in Firebase Console:

- ✅ SHA-1 fingerprint registered
- ✅ `google-services.json` downloaded and replaced
- ✅ Android package name matches: `com.faminga.faminga_irrigation`

---

## 🚀 **Test Google Sign-In Again**

1. **Fully close** the app on your phone (swipe away from recent apps)
2. Run `flutter clean` and `flutter run`
3. Try signing in with Google
4. Should now work! ✅

---

## 📝 **Still Not Working?**

### **Check These:**

1. **Package name mismatch**:
   - `android/app/build.gradle.kts` → `applicationId` should be: `com.faminga.faminga_irrigation`
   - Firebase Console → Android app package name should match

2. **OAuth client ID**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select your project
   - APIs & Services → Credentials
   - Should see an **OAuth 2.0 Client** with your SHA-1

3. **google-services.json correct**:
   - Open `android/app/google-services.json`
   - Verify `package_name` is `com.faminga.faminga_irrigation`
   - Verify `client_id` exists

---

## 💡 **Quick Debugging**

Add this to see detailed error:

```dart
// In lib/services/auth_service.dart
Future<UserCredential?> signInWithGoogle() async {
  try {
    // ... existing code ...
  } catch (e) {
    print('🔴 Detailed Google Sign-In Error: $e');
    if (e is PlatformException) {
      print('Error Code: ${e.code}');
      print('Error Message: ${e.message}');
      print('Error Details: ${e.details}');
    }
    rethrow;
  }
}
```

---

**After completing these steps, Google Sign-In should work perfectly on Android!** 🎉

