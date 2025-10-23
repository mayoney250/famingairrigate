# Google Sign-In for Web - Complete Setup Guide

## 📋 Prerequisites
- Firebase project: `ngairrigate`
- Web app registered in Firebase Console

---

## 🚀 Step-by-Step Setup

### Step 1: Get OAuth Client ID from Firebase Console

1. **Go to Firebase Console:**
   ```
   https://console.firebase.google.com/project/ngairrigate/authentication/providers
   ```

2. **Enable Google Sign-In:**
   - Click on **"Google"** provider
   - Toggle **"Enable"** to ON
   - You'll see **"Web SDK configuration"** section

3. **Copy the Web Client ID:**
   - Look for **"Web client ID"** 
   - It looks like: `622157404711-xxxxxxxxxxxxxxxxx.apps.googleusercontent.com`
   - Copy this entire string

### Step 2: Update Your Web Configuration

1. **Open your `web/index.html` file**
2. **Find this line (around line 36):**
   ```html
   <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
   ```
3. **Replace `YOUR_WEB_CLIENT_ID` with your actual Web Client ID**

Example:
```html
<meta name="google-signin-client_id" content="622157404711-abc123def456.apps.googleusercontent.com">
```

### Step 3: Verify Authorized Domains

1. **In Firebase Console, go to:**
   ```
   https://console.firebase.google.com/project/ngairrigate/authentication/settings
   ```

2. **Click on "Authorized domains" tab**

3. **Make sure these domains are listed:**
   - ✅ `localhost`
   - ✅ `ngairrigate.firebaseapp.com`
   - ✅ `ngairrigate.web.app` (if using Firebase Hosting)

4. **Add any other domains** where you'll deploy your app

---

## 🔑 Where to Find Your Web Client ID

### Method 1: Firebase Console (Easiest)
1. Go to: https://console.firebase.google.com/project/ngairrigate/settings/general
2. Scroll down to **"Your apps"** section
3. Find your **Web app**
4. Click **"Web App (1)"** or the gear icon
5. Look for **"Firebase SDK snippet"**
6. Or go to Authentication → Sign-in method → Google → Web SDK configuration

### Method 2: Google Cloud Console
1. Go to: https://console.cloud.google.com/apis/credentials
2. Select project: `ngairrigate`
3. Find **"OAuth 2.0 Client IDs"**
4. Look for **"Web client (auto created by Google Service)"**
5. Copy the **Client ID**

---

## 📝 Complete Configuration Example

### Your `web/index.html` should look like:

```html
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Faminga Irrigation - Smart irrigation management for African farmers">

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Faminga Irrigation">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <title>Faminga Irrigation</title>
  <link rel="manifest" href="manifest.json">
  
  <!-- Google Sign-In -->
  <meta name="google-signin-client_id" content="622157404711-YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com">
  <script src="https://accounts.google.com/gsi/client" async defer></script>
</head>
<body>
  <!-- Loading indicator -->
  <div id="loading" style="display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #FFF5EA;">
    <div style="text-align: center;">
      <div style="width: 80px; height: 80px; background-color: #D47B0F; border-radius: 20px; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center;">
        <div style="width: 40px; height: 40px; border: 4px solid #FFFFFF; border-top-color: transparent; border-radius: 50%; animation: spin 1s linear infinite;"></div>
      </div>
      <p style="color: #2D4D31; font-family: system-ui; font-size: 18px; font-weight: 600;">Loading Faminga Irrigation...</p>
    </div>
  </div>
  <style>
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
  <script>
    window.addEventListener('flutter-first-frame', function () {
      var loading = document.getElementById('loading');
      if (loading) {
        loading.style.display = 'none';
      }
    });
  </script>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

---

## 🔄 After Configuration

### Step 1: Stop the running app
- In terminal, press `q` to quit

### Step 2: Clean and rebuild
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Step 3: Test Google Sign-In
1. Go to login screen
2. Click "Sign in with Google"
3. Should now open Google account picker
4. Select account
5. Grants permissions
6. Signs in and redirects to dashboard

---

## 🐛 Troubleshooting

### Issue: "popup_closed_by_user"
**Solution**: This is normal - user closed the popup. Not an error.

### Issue: "Invalid client ID"
**Solution**: 
- Double-check the client ID is correct
- Make sure there are no extra spaces
- Verify you copied the entire ID including `.apps.googleusercontent.com`

### Issue: "redirect_uri_mismatch"
**Solution**:
- Go to Google Cloud Console
- Add `http://localhost` to authorized redirect URIs
- Add your deployment URL

### Issue: Still shows dialog instead of popup
**Solution**:
- Make sure you saved `web/index.html` with correct client ID
- Run `flutter clean` and restart

---

## ✅ Verification Checklist

- [ ] Copied Web Client ID from Firebase Console
- [ ] Updated `web/index.html` with actual client ID
- [ ] Verified authorized domains in Firebase
- [ ] Saved all changes
- [ ] Ran `flutter clean`
- [ ] Ran `flutter pub get`
- [ ] Restarted app with `flutter run -d chrome`
- [ ] Tested Google Sign-In button
- [ ] Successfully signed in with Google

---

## 🎯 Quick Reference

**Firebase Console Authentication:**
https://console.firebase.google.com/project/ngairrigate/authentication/providers

**Firebase Project Settings:**
https://console.firebase.google.com/project/ngairrigate/settings/general

**Google Cloud Console Credentials:**
https://console.cloud.google.com/apis/credentials?project=ngairrigate

---

## 📞 Need Help?

If you're stuck:
1. Check Firebase Console for the correct client ID
2. Verify `localhost` is in authorized domains
3. Make sure Google Sign-In is enabled in Firebase
4. Check browser console for detailed error messages

---

**Built with ❤️ for African farmers by Faminga**

