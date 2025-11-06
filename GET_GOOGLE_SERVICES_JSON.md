# How to Get google-services.json for Android

## Quick Steps

1. **Go to Firebase Console**: https://console.firebase.google.com/

2. **Select your project**: `famingairrigation`

3. **Add Android App** (if not already added):
   - Click the Android icon or gear icon → Project Settings
   - Scroll to "Your apps" section
   - Click "Add app" → Select Android

4. **Register your app**:
   - **Android package name**: `com.faminga.irrigation`
   - App nickname: Faminga Irrigation (optional)
   - Debug signing certificate SHA-1: (optional for now)
   - Click "Register app"

5. **Download google-services.json**:
   - Click "Download google-services.json"
   - Save it to: `android/app/google-services.json`

6. **Verify the file location**:
   ```
   famingairrigate/
   └── android/
       └── app/
           └── google-services.json  ← Here!
   ```

7. **Run the app**:
   ```bash
   flutter run
   ```

## Alternative: Use Existing Web Configuration

Your Firebase web config is already working. You can create a minimal google-services.json based on your web config:

### Create android/app/google-services.json with this content:

```json
{
  "project_info": {
    "project_number": "622157404711",
    "project_id": "famingairrigation",
    "storage_bucket": "famingairrigation.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:622157404711:android:YOUR_APP_ID",
        "android_client_info": {
          "package_name": "com.faminga.irrigation"
        }
      },
      "oauth_client": [
        {
          "client_id": "622157404711-ANDROID_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "AIzaSyDZDeht3F5sa6jiqedhREjFuRs7DrXzgm0"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "622157404711-ANDROID_CLIENT_ID.apps.googleusercontent.com",
              "client_type": 3
            }
          ]
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

**Note**: You'll need to get the actual Android app ID from Firebase Console.

## Recommended Approach

**Just use Chrome for testing** - it's faster and all features work:

```bash
flutter run -d chrome
```

Android setup can be done later when you're ready to deploy to mobile.
