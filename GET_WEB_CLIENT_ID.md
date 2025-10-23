# 🔑 How to Get Your Web Client ID

## Quick Method (Recommended)

### Step 1: Open Firebase Console
Click this link (it will open in your browser):
```
https://console.firebase.google.com/project/ngairrigate/authentication/providers
```

### Step 2: Enable Google Sign-In
1. Click on **"Google"** in the list of providers
2. Toggle **"Enable"** to ON (if not already enabled)
3. Look for the **"Web SDK configuration"** section

### Step 3: Copy Your Web Client ID
You'll see something like:
```javascript
{
  "client_id": "622157404711-xxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com",
  "project_id": "ngairrigate"
}
```

**Copy the entire `client_id` value** (the long string ending in `.apps.googleusercontent.com`)

---

## Alternative Method

### Using Project Settings

1. Go to: https://console.firebase.google.com/project/ngairrigate/settings/general
2. Scroll down to **"Your apps"** section
3. Find your **Web app** (looks like `</>` icon)
4. Click on it to expand
5. Look for **Firebase SDK snippet**
6. Find the `authDomain` line - it should show your project ID

Then go to:
```
https://console.firebase.google.com/project/ngairrigate/authentication/providers
```

And follow the steps above.

---

## What Your Web Client ID Looks Like

It's a long string in this format:
```
622157404711-abc123def456ghi789jkl012mno345pq.apps.googleusercontent.com
```

Parts:
- `622157404711` - Project number (yours might be different)
- `-` - separator
- `abc123...` - unique identifier (random characters)
- `.apps.googleusercontent.com` - domain (always the same)

---

## After You Get the Client ID

1. Copy the ENTIRE client ID including `.apps.googleusercontent.com`
2. Open `web/index.html` in your code editor
3. Find this line (around line 36):
   ```html
   <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
   ```
4. Replace `YOUR_WEB_CLIENT_ID.apps.googleusercontent.com` with your actual client ID:
   ```html
   <meta name="google-signin-client_id" content="622157404711-abc123def456.apps.googleusercontent.com">
   ```
5. Save the file
6. Run:
   ```bash
   flutter clean
   flutter run -d chrome
   ```

---

## ⚠️ Common Mistakes to Avoid

❌ **DON'T** copy only part of the ID  
✅ **DO** copy the entire string including `.apps.googleusercontent.com`

❌ **DON'T** add extra spaces or quotes  
✅ **DO** paste it exactly as is

❌ **DON'T** use the Android or iOS client ID  
✅ **DO** use the Web client ID specifically

---

## 🎯 Visual Guide

When you're in Firebase Console → Authentication → Sign-in method → Google:

```
┌─────────────────────────────────────────────┐
│ Google                              Enabled │
├─────────────────────────────────────────────┤
│                                             │
│ Web SDK configuration                       │
│                                             │
│ To use Google Sign-In on the web, copy and │
│ paste this code snippet into your HTML     │
│                                             │
│ {                                          │
│   "client_id": "622...com",    ← COPY THIS │
│   "project_id": "ngairrigate"              │
│ }                                          │
│                                             │
│ [Save]                                      │
└─────────────────────────────────────────────┘
```

---

## 🔍 Can't Find It?

If you don't see the Web SDK configuration:

1. Make sure Google Sign-In is **Enabled** (toggle at the top)
2. Click **Save** after enabling
3. The Web SDK configuration section should appear
4. If still not visible, try these links:

**Direct Links:**
- Authentication Providers: https://console.firebase.google.com/project/ngairrigate/authentication/providers
- Google Cloud Credentials: https://console.cloud.google.com/apis/credentials?project=ngairrigate

In Google Cloud Console, look for:
- **OAuth 2.0 Client IDs**
- Find: **"Web client (auto created by Google Service)"**
- Copy the **Client ID** from there

---

## ✅ Verification

Your client ID is correct if:
- ✅ It's very long (50-70 characters)
- ✅ It ends with `.apps.googleusercontent.com`
- ✅ It starts with numbers (your project number)
- ✅ It has a hyphen after the project number
- ✅ It contains random letters and numbers

Example of a **valid** client ID:
```
622157404711-abcd1234efgh5678ijkl9012mnop3456.apps.googleusercontent.com
```

---

**Ready to configure? Let's do this! 🚀**

