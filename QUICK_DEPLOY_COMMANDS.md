# Quick Deployment Commands

Copy and paste these commands in order to complete the deployment.

## Step 1: Set Firebase Functions Configuration

```powershell
cd c:\Users\famin\Documents\famingairrigate

firebase functions:config:set mail.user="julieisaro01@gmail.com" mail.pass="your-app-password"

firebase functions:config:set migrate.secret="your-migration-secret-12345"

firebase functions:config:get
```

## Step 2: Deploy Functions

```powershell
firebase deploy --only functions
```

## Step 3: Run Migration to Approve Existing Users

```powershell
$url = "https://us-central1-famingairrigation.cloudfunctions.net/migrateApproveMissingVerification"
$secret = "your-migration-secret-12345"

Invoke-WebRequest -Uri "$url`?secret=$secret" -Method Get
```

## Step 4: Test New Registration

1. Open Flutter app
2. Go to Sign Up
3. Create a new account
4. Receive verification email
5. Click approval link
6. Log in with new account
7. Should see Dashboard

---

## Important Notes

- **Gmail App Password**: Use an app-specific password from [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords), NOT your regular Gmail password
- **Migration Secret**: Choose a long, random string. Save it securely.
- **Token Expiry**: Approval links expire after 7 days
- **Audit Logs**: View in Firestore → `approval_logs` collection

---

For detailed instructions, see: `HARDENED_DEPLOYMENT_GUIDE.md`
