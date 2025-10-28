# 🧪 How to Test the New Profile Screens

## Quick Start Guide

### Step 1: Run the App
```bash
cd famingairrigate
flutter run -d chrome  # or your preferred device
```

### Step 2: Navigate to Profile
1. **Sign in** to your account
2. Tap the **Profile** icon in the bottom navigation (far right)
3. You'll see the profile screen with your info

### Step 3: Test Edit Profile

#### Click "Personal Information"
You should see:
```
┌─────────────────────────────────────┐
│  Edit Profile                    [x]│
├─────────────────────────────────────┤
│                                     │
│         [Profile Photo]             │
│         with camera icon            │
│    "Tap camera icon to change"     │
│                                     │
├─────────────────────────────────────┤
│  📱 Personal Information            │
├─────────────────────────────────────┤
│  👤 First Name      [Julie      ]  │
│  👤 Last Name       [Isaro      ]  │
│  ⚧  Gender          [▼ Select   ]  │
│  🎂 Date of Birth   [📅 Select  ]  │
│  🆔 National ID     [Optional   ]  │
├─────────────────────────────────────┤
│  📞 Contact Information             │
├─────────────────────────────────────┤
│  📱 Phone Number    [+250 7...  ]  │
│  📧 Email           isarojulie...   │
│     "Email cannot be changed"       │
├─────────────────────────────────────┤
│  📍 Location                        │
├─────────────────────────────────────┤
│  🗺️  Province       [▼ Kigali   ]  │
│  🏙️  District       [▼ Gasabo   ]  │
│  📌 Sector          [▼ Sector 1 ]  │
│  🏠 Village/Address [Optional   ]  │
├─────────────────────────────────────┤
│                                     │
│     [💾 Save Changes]              │
│                                     │
└─────────────────────────────────────┘
```

#### Test Actions:
1. ✅ **Tap camera icon** → Gallery opens → Select photo
2. ✅ **Change first name** → Type new name
3. ✅ **Select gender** → Choose from dropdown
4. ✅ **Pick date of birth** → Calendar picker opens
5. ✅ **Select province** → Dropdown shows 5 provinces
6. ✅ **Select district** → Auto-fills based on province
7. ✅ **Tap "Save Changes"** → See loading spinner → Success message

### Step 4: Test Change Password

#### Click "Change Password"
You should see:
```
┌─────────────────────────────────────┐
│  Change Password                 [x]│
├─────────────────────────────────────┤
│                                     │
│         🔒                          │
│    Secure Your Account              │
│  "Choose a strong password to       │
│   protect your farming data"        │
│                                     │
├─────────────────────────────────────┤
│  🔐 Current Password  [👁️]          │
│  [•••••••••••••]                    │
│                                     │
│  🔐 New Password      [👁️]          │
│  [•••••••••••••]                    │
│                                     │
│  ▓▓▓▓▓▓▓░░░  Strong                │
│                                     │
│  ✅ At least 8 characters           │
│  ✅ Contains uppercase letter       │
│  ✅ Contains lowercase letter       │
│  ✅ Contains number                 │
│  ⭕ Contains special character      │
│                                     │
│  🔐 Confirm Password  [👁️]          │
│  [•••••••••••••]                    │
│                                     │
├─────────────────────────────────────┤
│  🛡️  Security Tips                  │
│  • Use unique password              │
│  • Avoid personal info              │
│  • Change regularly                 │
│  • Never share password             │
├─────────────────────────────────────┤
│                                     │
│     [🔒 Change Password]           │
│     [    Cancel    ]                │
│                                     │
└─────────────────────────────────────┘
```

#### Test Actions:
1. ✅ **Enter current password** → Type your password
2. ✅ **Enter weak password** (e.g., "123456") → Red bar, "Weak"
3. ✅ **Enter medium password** (e.g., "Password1") → Orange bar, "Medium"
4. ✅ **Enter strong password** (e.g., "MyFarm@2024!") → Green bar, "Strong"
5. ✅ **Watch requirements checklist** → Checkmarks appear as you type
6. ✅ **Mismatch confirm** → Error message appears
7. ✅ **Match passwords** → No error
8. ✅ **Tap "Change Password"** → Loading → Success message

---

## Expected Results

### ✅ Edit Profile Success
After saving:
- ✅ Screen closes automatically
- ✅ Green success snackbar appears:
  ```
  ✓ Success
  Profile updated successfully!
  ```
- ✅ Profile screen shows updated information
- ✅ Data synced to Firebase Firestore
- ✅ Profile photo uploaded to Firebase Storage

### ✅ Change Password Success
After changing password:
- ✅ Screen closes automatically
- ✅ Green success snackbar appears:
  ```
  ✓ Success
  Password changed successfully!
  ```
- ✅ New password works immediately
- ✅ Can sign out and sign in with new password

---

## Common Test Scenarios

### Scenario 1: New User (First Time)
```
1. Sign up for new account
2. Go to Profile → Personal Information
3. Fill in all fields:
   - Name (pre-filled from signup)
   - Gender: Male
   - Date of Birth: 1990-01-15
   - Phone: +250 788 123 456
   - Province: Eastern Province
   - District: Nyagatare
   - Address: Rwimiyaga Village
4. Save
5. Verify all info appears correctly
```

### Scenario 2: Updating Photo
```
1. Go to Profile → Personal Information
2. Tap camera icon on profile photo
3. Select new image from gallery
4. See preview of new image
5. Save
6. Image uploads to Firebase Storage
7. Profile shows new photo immediately
```

### Scenario 3: Changing Location
```
1. Go to Profile → Personal Information
2. Change Province: Kigali City → Southern Province
3. Notice District resets
4. Select new District: Huye
5. Select Sector
6. Save
7. Location updates in Firebase
```

### Scenario 4: Password Strength
```
1. Go to Profile → Change Password
2. Try password "pass" → Weak, 2/6 strength
3. Try password "Password" → Medium, 3/6 strength  
4. Try password "Password1" → Medium, 4/6 strength
5. Try password "Password1!" → Strong, 5/6 strength
6. Try password "MyFarm@2024!" → Strong, 6/6 strength ✅
7. Confirm and save
```

---

## Error Scenarios to Test

### Edit Profile Errors
❌ **Empty required field**
```
→ Leave first name empty
→ Tap Save
→ Red error: "Please enter your first name"
```

❌ **Invalid phone number**
```
→ Enter "123" in phone
→ Tap Save  
→ Red error: "Please enter a valid phone number"
```

❌ **Network error**
```
→ Turn off internet
→ Make changes
→ Tap Save
→ Red error: "Failed to update profile: Network error"
```

### Change Password Errors
❌ **Wrong current password**
```
→ Enter wrong current password
→ Tap Change Password
→ Red error: "Current password is incorrect"
```

❌ **Weak password**
```
→ Enter "123456"
→ Red error: "Password must be at least 6 characters"
```

❌ **Password mismatch**
```
→ New password: "MyFarm@2024!"
→ Confirm: "MyFarm@2024"
→ Red error: "Passwords do not match"
```

❌ **Same as current**
```
→ New password same as current
→ Red error: "New password must be different from current password"
```

---

## Visual Verification

### Before Saving
- [ ] All input fields are clearly labeled
- [ ] Icons match field types (👤 person, 📱 phone, etc.)
- [ ] Dropdowns show arrow icon
- [ ] Date field shows calendar icon
- [ ] Password fields have eye icon for toggle
- [ ] Save button is orange (#D47B0F)
- [ ] Background is cream color (#FFF5EA)

### During Save
- [ ] Loading spinner appears
- [ ] Button disabled during save
- [ ] Can't navigate away during save

### After Save
- [ ] Success message in green
- [ ] Screen closes automatically
- [ ] Data persists after app restart

---

## Firebase Verification

### Check Firestore
1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to `users/{userId}`
4. Verify updated fields:
   ```javascript
   {
     firstName: "Julie",      // ✅ Updated
     lastName: "Isaro",       // ✅ Updated
     phoneNumber: "+250788...", // ✅ Updated
     gender: "Female",        // ✅ New field
     dateOfBirth: Timestamp,  // ✅ New field
     idNumber: "1...",        // ✅ New field
     province: "Kigali City", // ✅ Updated
     district: "Gasabo",      // ✅ Updated
     address: "...",          // ✅ Updated
     updatedAt: Timestamp     // ✅ Auto-updated
   }
   ```

### Check Firebase Storage
1. Open Firebase Console
2. Go to Storage
3. Navigate to `profile_pictures/`
4. Verify image file: `{userId}.jpg`
5. Click to view uploaded photo

### Check Firebase Auth
1. Open Firebase Console
2. Go to Authentication → Users
3. Find your user
4. Password was updated (can't see hash, but can verify by logging in)

---

## Troubleshooting

### Issue: Can't see new screens
**Solution:** Make sure you've imported the new files:
```dart
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
```

### Issue: Fields not saving
**Solution:** Check Firestore rules allow write:
```javascript
allow write: if request.auth.uid == userId;
```

### Issue: Image upload fails
**Solution:** Check Firebase Storage rules:
```javascript
allow write: if request.auth.uid == userId;
```

### Issue: Password change fails
**Solution:** User may need to sign out and sign in again for re-authentication

---

## 🎉 Success Criteria

Your implementation is working correctly if:
- ✅ All screens load without errors
- ✅ All fields are editable
- ✅ Validation works correctly
- ✅ Data saves to Firebase
- ✅ Success messages appear
- ✅ Profile refreshes with new data
- ✅ No console errors
- ✅ Works on web, Android, and iOS

---

**Happy Testing! 🚀**

