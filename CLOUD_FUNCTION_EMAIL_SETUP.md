# Cloud Function Email Setup Guide

## Overview
A Cloud Function (`onVerificationCreated`) has been created to automatically send emails to the admin when a new verification request is created. This function is triggered whenever a user registers as part of a cooperative and a verification request is created in the `verifications` collection.

## File Location
- **Cloud Function**: `functions/src/onVerificationCreated.ts`
- **Package Config**: `functions/package.json` (updated with nodemailer dependency)

## Setup Steps

### 1. Install Dependencies
```bash
cd functions
npm install
```

### 2. Configure Gmail SMTP
The Cloud Function uses Gmail's SMTP server via nodemailer. You have two options:

#### Option A: Gmail App Password (Recommended for Production)
1. Enable 2-Factor Authentication on your Gmail account
2. Generate an App Password at: https://myaccount.google.com/apppasswords
3. Create a Firebase secret with this password:
   ```bash
   firebase functions:config:set gmail.password="your-app-password"
   firebase functions:config:set gmail.user="your-email@gmail.com"
   ```

#### Option B: Environment Variables via Firebase Secrets
1. Create a `.env.local` file in the `functions/` directory:
   ```
   ADMIN_EMAIL_USER=your-email@gmail.com
   ADMIN_EMAIL_PASSWORD=your-app-password
   ```
2. Reference in Cloud Functions:
   ```bash
   firebase functions:config:set gmail.user="julieisaro01@gmail.com"
   firebase functions:config:set gmail.password="your-16-char-app-password"
   ```

### 3. Deploy the Cloud Function
```bash
# From project root
firebase deploy --only functions

# Or if you need to redeploy specifically:
firebase deploy --only functions:sendVerificationEmail,functions:retriggerVerificationEmail
```

### 4. Verify Deployment
```bash
# Check logs
firebase functions:log --limit 50

# Test the function by registering a cooperative
# You should see logs in the Firebase console
```

## Email Flow

### When Cooperative Registration Occurs:
1. User submits RegisterScreen form with `_isInCooperative = true`
2. `VerificationService.createVerificationRequest()` creates document in `verifications` collection
3. Cloud Function `onVerificationCreated` triggers automatically
4. Function reads admin email from `settings/verification.adminEmail` (defaults to julieisaro01@gmail.com)
5. HTML email is constructed with all cooperative details
6. Email is sent via Gmail SMTP
7. Verification request document is updated with `emailSentAt` timestamp

### Email Contents Include:
- User name and email
- Cooperative name, government ID, member ID
- Number of farmers, field size, number of fields
- Leader name, phone, email
- Verification link/ID for admin reference
- Firebase Console link for approval/rejection

## Firestore Document Structure

The Cloud Function expects the verification document to have this structure:

```dart
{
  "type": "cooperative" | "individual",
  "userEmail": "user@example.com",
  "requesterEmail": "email/phone/coop-id",
  "firstName": "John",
  "lastName": "Doe",
  "adminEmail": "julieisaro01@gmail.com",
  "payload": {
    "coopName": "Farmers Cooperative",
    "coopGovId": "GOV-12345",
    "memberId": "MEMBER-456",
    "numFarmers": 50,
    "leaderName": "Jane Smith",
    "leaderPhone": "+250788123456",
    "leaderEmail": "leader@coop.rw",
    "coopFieldSize": "100",
    "coopNumFields": "25"
  },
  "createdAt": [server timestamp],
  "emailSentAt": [server timestamp],  // Added by Cloud Function
  "status": "pending"
}
```

## Admin Workflow

1. **Receive Email**: Admin receives HTML formatted email with all registration details
2. **Review in Firebase Console**:
   - Open Firestore Database
   - Navigate to `verifications` collection
   - Find the verification document by ID (from email or search by email)
3. **Approve**:
   - Edit the document and set `status: "approved"`
   - (Optional) Add `approvedAt: server_timestamp` and `approvedBy: "admin@example.com"`
   - User can now log in and access dashboard
4. **Reject**:
   - Set `status: "rejected"` and `reason: "explanation"`
   - (Optional) Delete the corresponding user from Auth
   - User receives notification (future feature)

## Testing

### Local Testing with Emulator:
```bash
# Start Firebase emulator
firebase emulators:start --only functions,firestore

# In Flutter, use emulator settings to connect to local Firebase
```

### Production Testing:
1. Register a test cooperative account
2. Check logs in Firebase Console → Cloud Functions → sendVerificationEmail → Logs
3. Verify email arrives in admin inbox
4. Update verification document status to test approval flow

## Troubleshooting

### Email Not Sending
1. **Check Cloud Function Logs**: Firebase Console → Cloud Functions → sendVerificationEmail
2. **Verify Gmail Password**: Ensure app password is correct (not regular password)
3. **Check Gmail Account Security**: May need to allow "Less secure apps" or use app passwords
4. **Verify Firestore Document**: Ensure verification document has all required fields

### Error: "nodemailer not found"
```bash
cd functions
npm install nodemailer
```

### Error: "ADMIN_EMAIL_USER not set"
Set environment variables:
```bash
firebase functions:config:set gmail.user="your-email@gmail.com" gmail.password="your-app-password"
```

## Future Enhancements

1. **Email Templates**: Move HTML to separate template files for better maintainability
2. **Resend Emails**: Use `retriggerVerificationEmail` callable function to resend failed emails
3. **SMS Notifications**: Add SMS option for admin notifications
4. **Batch Processing**: Handle high-volume registrations with queue system
5. **Email Status Tracking**: Track bounced/failed emails in Firestore

## References

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Nodemailer Gmail Setup](https://nodemailer.com/smtp/gmail/)
- [Firebase Secrets Management](https://firebase.google.com/docs/functions/config-env)
- [Firestore Cloud Function Triggers](https://firebase.google.com/docs/functions/firestore-events)
