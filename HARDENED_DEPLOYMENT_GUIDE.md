# Hardened Verification System - Step-by-Step Deployment Guide

## 📋 Overview

This guide walks you through deploying the **hardened approval flow** with the following security improvements:

✅ **Token Expiry**: Approval tokens expire after 7 days  
✅ **Audit Logging**: All approval attempts logged with IP, timestamp, and result  
✅ **Error Handling**: Detailed error messages and token tampering detection  
✅ **Idempotency**: Already-approved verifications handled gracefully  
✅ **Migration Support**: One-time protected migration for existing users  

---

## 🔑 Step 1: Configure Firebase Functions with Required Secrets

You must set two critical configuration values in Firebase:

### 1.1 Mail Credentials (for sending verification emails)

Replace `your-email@gmail.com` and `your-app-password` with your actual Gmail credentials:

```powershell
firebase functions:config:set mail.user="your-email@gmail.com" mail.pass="your-app-password"
```

**⚠️ Important:** 
- Use a **Gmail app password**, not your regular Gmail password
- [Generate Gmail app password here](https://myaccount.google.com/apppasswords)
- This email will receive new registration requests

### 1.2 Migration Secret (for protecting the migration endpoint)

Choose a **long, random secret** (at least 20 characters):

```powershell
firebase functions:config:set migrate.secret="your-super-secret-migration-key-12345"
```

**Save this secret securely** — you'll need it to run the migration in Step 4.

### 1.3 Verify Configuration

```powershell
firebase functions:config:get
```

You should see:
```json
{
  "mail": {
    "user": "your-email@gmail.com",
    "pass": "your-app-password"
  },
  "migrate": {
    "secret": "your-super-secret-migration-key-12345"
  }
}
```

---

## 🚀 Step 2: Deploy Functions to Firebase

Navigate to your project directory and deploy the updated Cloud Functions:

```powershell
cd c:\Users\famin\Documents\famingairrigate
firebase deploy --only functions
```

**Expected Output:**
```
Deploying functions to project famingairrigation...
✓ functions[sendVerificationEmail] deployed
✓ functions[approveVerification] deployed
✓ functions[migrateApproveMissingVerification] deployed
✓ functions[resolveIdentifier] deployed
... (other functions)
✓ All done
```

⏱️ **Wait time:** 2-5 minutes

### What's being deployed:

| Function | Purpose | Security |
|----------|---------|----------|
| `sendVerificationEmail` | Sends approval link via email | Firestore trigger, admin SDK |
| `approveVerification` | Admin clicks email link to approve | Token validation, 7-day expiry, audit log |
| `migrateApproveMissingVerification` | One-time migration for existing users | Secret-protected, audit log |
| `resolveIdentifier` | Server-side uniqueness checks | Admin SDK, callable |

---

## ✉️ Step 3: Test Email Delivery (Optional but Recommended)

To verify emails are being sent correctly:

### 3.1 Create a test verification request

Use Firebase Console to manually create a verification document:

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project (`famingairrigation`)
3. Go to **Firestore Database**
4. Create a new document in collection `verifications`:

```json
{
  "adminEmail": "your-email@gmail.com",
  "requesterEmail": "test@example.com",
  "requesterIdentifierType": "email",
  "type": "cooperative",
  "status": "pending",
  "payload": {
    "firstName": "Test",
    "lastName": "User",
    "coopName": "Test Coop",
    "coopGovId": "COOP-001",
    "numFarmers": 50
  }
}
```

### 3.2 Watch for the verification trigger

- The `sendVerificationEmail` function should trigger automatically
- Check your email (the one you configured in `mail.user`)
- You should receive a verification email with an approval link
- **Important:** This email contains the secure approval token in the URL

### 3.3 Check function logs

```powershell
firebase functions:log --limit 50
```

You should see:
```
New verification request: {docId}
Admin email: your-email@gmail.com
Email sent successfully to your-email@gmail.com
```

---

## 📱 Step 4: Run the Migration (Approve Existing Users)

**⚠️ Critical:** Run this BEFORE users try to log in, otherwise they'll be blocked.

This migration marks all existing users as approved so they can access the dashboard.

### 4.1 Get your Firebase project URL

First, find your function URL:

```powershell
firebase functions:describe migrateApproveMissingVerification --region us-central1
```

Or build it manually: `https://us-central1-{PROJECT_ID}.cloudfunctions.net/migrateApproveMissingVerification`

Replace `{PROJECT_ID}` with your actual project ID (from Firebase Console).

### 4.2 Run the migration command

Use the secret you configured in Step 1.2:

```powershell
$url = "https://us-central1-famingairrigation.cloudfunctions.net/migrateApproveMissingVerification"
$secret = "your-super-secret-migration-key-12345"
Invoke-WebRequest -Uri "$url`?secret=$secret" -Method Get
```

**Expected Output (on success):**
```
StatusCode        : 200
StatusDescription : OK
Content           : ✓ Migration Completed Successfully
                    Users Updated: {count}
                    All existing users have been marked as approved...
```

### 4.3 Verify migration in Firestore

Check the Firestore Console:
1. Go to **Firestore Database**
2. View the `users` collection
3. Click on any user document
4. Confirm they now have `verificationStatus: "approved"` and `migratedAt: {timestamp}`

### 4.4 Check audit logs

View all approval/migration activity:

```powershell
firebase functions:log --limit 100
```

Filter for migration logs:
```
🔄 Starting migration...
✓ Migration completed: updated {N} user(s)
```

---

## 🧪 Step 5: Test New User Registration Flow

Now test that new registrations work end-to-end:

### 5.1 Register a new user (Individual Farmer)

In your Flutter app:
1. Go to **Login Screen** → **Register**
2. Select **Individual Farmer**
3. Fill in all details:
   - Name, Email, Phone
   - Province, District
   - Unique phone/email
4. Click **Register**

**Expected behavior:**
- ✓ User created in Firebase Auth
- ✓ Verification document created in Firestore
- ✓ Verification email sent to admin

### 5.2 Admin approves registration

In your email:
1. Find the new registration email from the admin address
2. Click **[Click here to approve]** link
3. Browser shows: "✓ Registration Approved"

**Behind the scenes:**
- ✓ Verification document marked as `status: approved`
- ✓ User document marked as `verificationStatus: approved`
- ✓ Approval logged in `approval_logs` collection

### 5.3 New user logs in

Back in the Flutter app:
1. Log out
2. Log in with the new user's credentials
3. Should see **Dashboard** (not registration screen)

**If it fails:** Check Firestore rules — they require `verificationStatus == 'approved'`

### 5.4 Register a cooperative

Repeat the flow with **Cooperative Registration**:
1. Fill in coop details (Name, Gov ID, Number of Farmers)
2. Receive slightly different verification email
3. Admin approves via the same link
4. Coop leader can log in

---

## 🔒 Security Features Explained

### Token Expiry (7 days)

- Approval tokens are time-limited to **7 days**
- After 7 days, clicking the approval link returns: `"Token expired. Please request a new verification email."`
- Users can request a new email by re-registering (or contact admin)

**Token expiry is checked in:** `approveVerification` endpoint

### Audit Logging

All approval attempts are logged to the `approval_logs` collection:

**Successful approval:**
```json
{
  "verificationId": "doc-123",
  "userId": "user-abc",
  "userEmail": "farmer@example.com",
  "status": "success",
  "approvedAt": "2024-01-15T10:30:00Z",
  "ipAddress": "192.168.1.1",
  "userAgent": "Mozilla/5.0..."
}
```

**Failed (expired token):**
```json
{
  "verificationId": "doc-456",
  "status": "failed_expired_token",
  "failureReason": "Token expired after 168.5 hours",
  "attemptedAt": "2024-01-23T14:20:00Z",
  "ipAddress": "203.0.113.45"
}
```

**Migration:**
```json
{
  "verificationId": "migration_batch",
  "status": "success",
  "usersUpdated": 42,
  "migratedAt": "2024-01-15T09:00:00Z"
}
```

### Idempotency

- If someone clicks an approval link **twice**, the second click is handled gracefully
- Returns: "Already Approved" (doesn't error)
- Prevents accidental duplicate approvals

### Token Tampering Detection

- If a token is altered or invalid, the attempt is logged
- Response: `"Invalid or expired token"` (403)
- Audit log includes failed attempt details

---

## 🔧 Troubleshooting

### Issue: Verification emails not being sent

**Cause:** Gmail credentials not configured or incorrect

**Solution:**
```powershell
firebase functions:config:get
# Verify mail.user and mail.pass are set correctly
# If not:
firebase functions:config:set mail.user="your-email@gmail.com" mail.pass="your-app-password"
firebase deploy --only functions
```

### Issue: "Permission denied" when registering

**Cause:** User's `verificationStatus` field is missing or incorrect

**Solution:** Run the migration again (Step 4)

### Issue: Approval link doesn't work

**Possible causes:**
1. **Token expired** (> 7 days old) → Re-register to get a new token
2. **Invalid token** → Check the URL is exactly as in the email
3. **Already approved** → User already approved, just needs to log in

**Check logs:**
```powershell
firebase functions:log --limit 50
```

### Issue: Migration failed with "secret invalid"

**Cause:** Wrong migration secret or secret not configured

**Solution:**
```powershell
firebase functions:config:get
# Verify migrate.secret matches what you used in the URL
# If not, re-run Step 1.2 with correct secret
firebase functions:config:set migrate.secret="correct-secret-here"
firebase deploy --only functions
# Then retry Step 4
```

### Issue: Can't see audit logs

**Check:**
1. Go to Firebase Console → Firestore Database → Collection `approval_logs`
2. Should see documents with timestamps and statuses
3. If empty, no approvals have been logged yet

---

## 📊 Monitoring Checklist

After deployment, verify everything is working:

- [ ] **Emails sending**: Registered users receive verification emails within 1 minute
- [ ] **Token validation**: Clicking approval link updates user to `verificationStatus: approved`
- [ ] **Token expiry**: Approval link fails after 7 days
- [ ] **Audit logging**: Each approval appears in `approval_logs` collection
- [ ] **Migration complete**: All existing users have `verificationStatus` field
- [ ] **New registrations**: Can register, get email, get approved, log in
- [ ] **Permission handling**: No "permission-denied" errors on login

---

## 🎯 Summary

| Step | Action | Status |
|------|--------|--------|
| 1 | Configure Firebase functions config (mail + secret) | ✓ Required |
| 2 | Deploy functions | ✓ Required |
| 3 | Test email delivery | ⚠️ Recommended |
| 4 | Run migration | ✓ **CRITICAL** |
| 5 | Test new registration flow | ✓ Recommended |

---

## 🆘 Need Help?

**Check logs:**
```powershell
firebase functions:log --limit 100
```

**Redeploy functions:**
```powershell
firebase deploy --only functions
```

**Reset and restart:**
1. Delete all `verification` documents from Firestore
2. Re-register a test user
3. Check logs and emails

---

**Last Updated:** 2024-01-15  
**Deployment Status:** ✓ Hardened & Ready for Production
