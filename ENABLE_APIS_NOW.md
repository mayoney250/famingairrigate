# ⚠️ CRITICAL: Enable APIs in Google Cloud Console

## The Error You're Seeing

```
TypeError: Cannot read properties of undefined (reading 'MapTypeId')
```

**This means:** The Google Maps JavaScript API is not enabled in your Google Cloud project.

---

## 🚨 DO THIS NOW (2 minutes):

### Step 1: Go to Google Cloud Console
Open: https://console.cloud.google.com/apis/library

### Step 2: Enable These 4 APIs

Click on each and press **ENABLE**:

#### 1. Maps JavaScript API ⭐ (REQUIRED FOR WEB)
https://console.cloud.google.com/apis/library/maps-backend.googleapis.com

#### 2. Maps SDK for Android (REQUIRED FOR ANDROID)
https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com

#### 3. Geocoding API (FOR LOCATION SEARCH)
https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com

#### 4. Maps SDK for iOS (REQUIRED FOR iOS)
https://console.cloud.google.com/apis/library/maps-ios-backend.googleapis.com

---

## ✅ After Enabling APIs:

1. **Wait 1-2 minutes** for APIs to activate
2. **Stop your Flutter app** (Ctrl+C in terminal)
3. **Clear browser cache** or use incognito mode
4. **Restart the app**:
   ```bash
   flutter run -d chrome
   ```
5. **Navigate to**: Fields → Add Field → Step 2
6. **Map will appear!** 🗺️

---

## 🔍 Verify APIs Are Enabled:

Go to: https://console.cloud.google.com/apis/dashboard

You should see:
- ✅ Maps JavaScript API
- ✅ Maps SDK for Android  
- ✅ Geocoding API
- ✅ Maps SDK for iOS

---

## 💳 Billing Setup

Google Maps APIs require billing to be enabled (even for free tier):

1. Go to: https://console.cloud.google.com/billing
2. Link a credit card
3. **Don't worry:** You get $200/month FREE credit
4. Your usage will stay in free tier

**Without billing enabled, APIs won't work!**

---

## 🧪 Quick Test

After enabling APIs:

1. Open browser console (F12)
2. Refresh the page
3. You should NOT see any Google Maps errors
4. Map should load in the red area

---

**Enable the APIs now and the map will work immediately!** ⚡
