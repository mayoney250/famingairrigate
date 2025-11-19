# Quick Deployment Guide - Email Notifications

## Prerequisites
- Firebase CLI installed (`npm install -g firebase-tools`)
- Google account with Gmail enabled
- Firebase project configured locally

## Step 1: Setup Gmail Authentication (1-2 minutes)

### Get App Password:
1. Go to https://myaccount.google.com/apppasswords
2. Select "Mail" and "Windows Computer" (or your device)
3. Copy the 16-character app password

### Set Firebase Secrets:
```powershell
# Open PowerShell in project root directory
cd c:\Users\famin\Documents\famingairrigate

# Set Gmail credentials as environment variables
firebase functions:config:set gmail.user="julieisaro01@gmail.com"
firebase functions:config:set gmail.password="xxxx xxxx xxxx xxxx"  # Your 16-char app password

# Verify configuration
firebase functions:config:get
```

## Step 2: Install Dependencies (1 minute)

```powershell
# Navigate to functions directory
cd functions

# Install packages including nodemailer
npm install

# Return to project root
cd ..
```

## Step 3: Deploy Cloud Function (2-3 minutes)

```powershell
# Deploy only the Cloud Functions
firebase deploy --only functions

# Watch the console for success message:
# ✔  Deploy complete!
# Function URL: https://us-central1-your-project.cloudfunctions.net/sendVerificationEmail
```

## Step 4: Verify Deployment (1 minute)

```powershell
# Check function logs
firebase functions:log --limit 50

# Look for output similar to:
# i  functions: Beginning execution of "sendVerificationEmail"
# i  functions: New verification request: abc123xyz
# i  functions: Email sent successfully to julieisaro01@gmail.com
```

## Step 5: Test Email Flow (5 minutes)

1. **In Flutter App**:
   - Open registration screen
   - Select "I'm part of a cooperative" toggle
   - Fill in all cooperative fields
   - Register with any identifier:
     - Email: `test@example.com`
     - Phone: `+250788123456`
     - Coop ID: `COOP-TEST-001`

2. **Check Admin Email**:
   - Open inbox at `julieisaro01@gmail.com`
   - Look for email titled: "New Cooperative Registration for Verification - [Coop Name]"
   - Email should contain all cooperative details

3. **Verify in Firebase Console**:
   - Go to Firebase Console → Firestore Database
   - Open `verifications` collection
   - Find the new document
   - Check that it has: `emailSentAt` timestamp

4. **Test Approval Workflow**:
   - In Firebase Console, open the verification document
   - Click "Edit" (pencil icon)
   - Add new field: `status` → `approved` (if not already set)
   - Click "Save"
   - Try logging in with the cooperative account
   - Should now have dashboard access

## Troubleshooting

### Issue: "nodemailer not found"
```powershell
cd functions
npm install nodemailer
npm install
cd ..
firebase deploy --only functions
```

### Issue: "Email not sending"
```powershell
# Check logs for errors
firebase functions:log --limit 100

# Common causes:
# 1. Incorrect app password - regenerate at https://myaccount.google.com/apppasswords
# 2. Gmail account not set correctly - verify in Firebase config:
firebase functions:config:get
# Look for gmail.user and gmail.password
```

### Issue: "Functions deployment failed"
```powershell
# Clear cache and reinstall
cd functions
rm -r node_modules
npm install
cd ..
firebase deploy --only functions --debug
```

### Issue: "Gmail app password expired"
```powershell
# Generate new app password at https://myaccount.google.com/apppasswords
firebase functions:config:set gmail.password="xxxx xxxx xxxx xxxx"  # New password
firebase deploy --only functions
```

## Full Command Reference

```powershell
# Complete one-time setup (run from project root):
firebase functions:config:set gmail.user="julieisaro01@gmail.com"; `
firebase functions:config:set gmail.password="xxxx xxxx xxxx xxxx"; `
cd functions; `
npm install; `
cd ..; `
firebase deploy --only functions; `
firebase functions:log --limit 50

# Subsequent deployments (after code changes):
cd functions; npm install; cd ..; firebase deploy --only functions

# View live logs:
firebase functions:log --limit 50 --follow

# Clear environment config:
firebase functions:config:unset gmail
```

## What Happens Automatically

1. ✅ User registers with cooperative details
2. ✅ Verification document created in Firestore
3. ✅ Cloud Function triggers automatically
4. ✅ Email sent to admin at julieisaro01@gmail.com
5. ✅ Email contains verification ID and all cooperative details
6. ✅ Admin approves/rejects in Firebase Console
7. ✅ User can log in if approved

## Email Details Sent to Admin

**Subject**: `New Cooperative Registration for Verification - [Cooperative Name]`

**Contents**:
- User Name & Email/Phone/Cooperative ID
- Cooperative Name & Government ID
- Member ID & Number of Farmers
- Leader Name, Phone, Email
- Total Field Size & Number of Fields
- Verification ID (for tracking)
- Firebase Console link

## Next: Manual Admin Verification

Once email is received, admin can:

1. **Review Details**: Check email for all information
2. **Log into Firebase Console**: https://console.firebase.google.com
3. **Navigate to Firestore**: Database → `verifications` collection
4. **Find Document**: Search by user email or verification ID
5. **Approve**:
   - Click pencil icon to edit
   - Set `status: "approved"`
   - Click "Save"
   - User can now log in and use app
6. **Reject** (if needed):
   - Set `status: "rejected"`
   - Add `rejectionReason: "explanation"`
   - Click "Save"
   - User cannot access dashboard

## Important Notes

- ⚠️ Requires Gmail account with app password (not regular password)
- ⚠️ App password is stored in Firebase config (not in code)
- ⚠️ Email notifications only work after Cloud Function deployment
- ⚠️ Test with actual email address to verify delivery
- ✅ All changes preserve existing functionality
- ✅ Backwards compatible with existing user registrations

## Duration Summary

- Setup: 5-10 minutes total
- Test: 5 minutes
- Total: 10-15 minutes to full deployment

**Status**: Ready to deploy! 🚀
