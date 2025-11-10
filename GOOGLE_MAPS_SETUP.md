# Google Maps API Setup Guide

## Quick Setup (Required to Fix Map Issues)

### Critical: The app will crash on mobile when adding fields without proper Google Maps configuration

## Step 1: Get Your Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Go to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **API Key**
5. Copy the API key
6. **Important**: Restrict the API key:
   - Click on the key to edit
   - Under "Application restrictions", choose appropriate option
   - Under "API restrictions", select:
     - Maps SDK for Android
     - Maps SDK for iOS (if targeting iOS)
     - Maps JavaScript API (for web)
     - Geocoding API
     - Places API

## Step 2: Enable Required APIs

In Google Cloud Console, enable these APIs:

1. **Maps SDK for Android** (Required for Android)
2. **Maps SDK for iOS** (Required for iOS)
3. **Maps JavaScript API** (Required for Web)
4. **Geocoding API** (For address search)
5. **Places API** (For location search)

## Step 3: Configure Android

### 3a. Create strings.xml

Create file: `android/app/src/main/res/values/strings.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Replace YOUR_API_KEY_HERE with your actual Google Maps API key -->
    <string name="google_maps_api_key">YOUR_API_KEY_HERE</string>
</resources>
```

### 3b. Update AndroidManifest.xml

Edit: `android/app/src/main/AndroidManifest.xml`

Add this inside the `<application>` tag:

```xml
<application
    android:label="faminga_irrigation"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
    
    <!-- Add this meta-data tag -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="@string/google_maps_api_key" />
    
    <!-- Rest of your application config -->
    <activity ...>
        ...
    </activity>
</application>
```

### 3c. Add SHA-1 Fingerprint to Firebase

1. Get your SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Or on Windows:
   ```cmd
   cd android
   gradlew.bat signingReport
   ```

2. Copy the SHA-1 fingerprint (debug and/or release)

3. Go to Firebase Console > Project Settings > Your Android App
4. Scroll to "SHA certificate fingerprints"
5. Click "Add fingerprint"
6. Paste the SHA-1 fingerprint
7. Download the updated `google-services.json`
8. Replace `android/app/google-services.json` with the new file

## Step 4: Configure iOS (if targeting iOS)

Edit: `ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter
import GoogleMaps  // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Add this line with your actual API key
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Step 5: Configure Web (if targeting Web)

Edit: `web/index.html`

Add this in the `<head>` section:

```html
<head>
  <!-- ... other head elements ... -->
  
  <!-- Google Maps JavaScript API -->
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
  
  <!-- ... rest of head ... -->
</head>
```

## Step 6: Verify Setup

### For Android:

1. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean && cd ..
   flutter build apk --debug
   ```

2. Install on device/emulator:
   ```bash
   flutter run
   ```

3. Navigate to Fields > Add Field
4. Map should appear without crashes

### For Web:

1. Run:
   ```bash
   flutter run -d chrome
   ```

2. Check browser console for any API key errors

## Common Issues & Solutions

### Issue: App crashes when opening map

**Solution**: 
- Verify API key is correctly set in `strings.xml`
- Ensure `google-services.json` is up to date with SHA-1
- Check Google Cloud Console that APIs are enabled
- Verify billing is enabled on Google Cloud project

### Issue: Map shows "For development purposes only" watermark

**Solution**: 
- This means API key restrictions are preventing proper authentication
- Go to Google Cloud Console > Credentials > Your API Key
- Check "Application restrictions" match your package name: `com.faminga.irrigation`
- Add SHA-1 fingerprint if missing

### Issue: Map not loading on web

**Solution**:
- Check browser console for errors
- Verify `<script>` tag is in `web/index.html`
- Ensure Maps JavaScript API is enabled
- Check for any CORS or domain restriction issues

### Issue: "This API key is not authorized to use this service or API"

**Solution**:
- Go to Google Cloud Console
- Navigate to APIs & Services > Enabled APIs
- Ensure the required APIs are enabled
- Check API key restrictions allow your app

### Issue: Geocoding/Search not working

**Solution**:
- Enable Geocoding API in Google Cloud Console
- Enable Places API for enhanced search
- Verify API key has access to these APIs

## Cost Management

Google Maps APIs have free tier but may incur costs:

### Free Tier (per month):
- **Maps SDK for Android**: 100,000 loads free
- **Maps SDK for iOS**: 100,000 loads free  
- **Maps JavaScript API**: $200 credit (≈28,000 loads)
- **Geocoding API**: $200 credit (≈40,000 requests)
- **Places API**: $200 credit (varies by request type)

### To Avoid Unexpected Charges:

1. Set up billing alerts:
   - Go to Google Cloud Console > Billing > Budgets & alerts
   - Create a budget with email notifications

2. Set quotas:
   - Go to APIs & Services > Enabled APIs > Select API
   - Click "Quotas"
   - Set daily request limits

3. Restrict API key:
   - Limit to specific apps (package name, SHA-1)
   - Limit to specific APIs only

## Security Best Practices

1. **Never commit API keys to git**
   - Add `strings.xml` to `.gitignore`
   - Use environment variables for production

2. **Use separate keys for development/production**
   - Create different API keys
   - Use build flavors to manage keys

3. **Restrict API keys**
   - Always set application restrictions
   - Always set API restrictions
   - Never use unrestricted keys

4. **Rotate keys regularly**
   - Generate new keys periodically
   - Delete unused keys

## Testing Your Setup

Run this checklist:

- [ ] API key obtained from Google Cloud Console
- [ ] Required APIs enabled (Maps SDK, Geocoding, Places)
- [ ] `strings.xml` created with API key (Android)
- [ ] `AndroidManifest.xml` updated with meta-data (Android)
- [ ] SHA-1 fingerprint added to Firebase
- [ ] `google-services.json` updated and downloaded
- [ ] App builds without errors
- [ ] Map displays when adding a field
- [ ] No "For development purposes only" watermark
- [ ] Location search works
- [ ] Current location detection works
- [ ] Map types (Satellite/Street) switching works

## Environment-Specific Setup (Optional)

For production apps, use build flavors:

### Android: Build Variants

1. Create `android/app/src/debug/res/values/strings.xml`:
```xml
<resources>
    <string name="google_maps_api_key">DEBUG_API_KEY</string>
</resources>
```

2. Create `android/app/src/release/res/values/strings.xml`:
```xml
<resources>
    <string name="google_maps_api_key">PRODUCTION_API_KEY</string>
</resources>
```

## Support Links

- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Flutter google_maps_flutter package](https://pub.dev/packages/google_maps_flutter)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Console](https://console.firebase.google.com/)

## Need Help?

If you encounter issues:

1. Check the error message in Android Studio logcat or VS Code debug console
2. Verify all steps above are completed
3. Check Google Cloud Console > APIs & Services > Dashboard for usage/errors
4. Review Firebase Console for configuration issues
5. Search [Stack Overflow](https://stackoverflow.com) for specific error messages

---

**After completing this setup, the irrigation planning module will work perfectly on all platforms!**
