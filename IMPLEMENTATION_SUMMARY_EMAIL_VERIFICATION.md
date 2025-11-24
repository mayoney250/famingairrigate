# Admin Email Notification & Multi-Identifier Registration - Implementation Complete

## Summary
Successfully implemented:
1. ✅ Cloud Function that automatically sends HTML emails to admin when cooperative registrations occur
2. ✅ Updated registration form to accept email, phone number, or cooperative ID as identifiers
3. ✅ Enhanced verification service to track and identify requester types
4. ✅ Firestore document structure to store identifier type for admin reference

## Changes Made

### 1. Cloud Function - `functions/src/onVerificationCreated.ts` (NEW)
**Purpose**: Automatically email admin when verification requests are created

**Key Features**:
- Triggered on document creation in `verifications` collection
- Sends HTML-formatted emails with all cooperative details
- Includes verification ID and link to Firebase Console
- Supports both cooperative and individual registrations
- Has fallback default admin email (julieisaro01@gmail.com)
- Includes retry/re-trigger callable function for manual email sends

**Email Contents**:
```
- User Name & Email
- Cooperative Details (name, gov ID, member ID, num farmers)
- Leader Information (name, phone, email)
- Land Info (field size, number of fields)
- Verification ID for tracking
- Firebase Console link for admin approval/rejection
```

**Functions Exported**:
- `sendVerificationEmail`: Automatically triggered onCreate
- `retriggerVerificationEmail`: Callable function to re-send emails

### 2. Registration Form Update - `lib/screens/auth/register_screen.dart` (UPDATED)
**Changed**: Email field now accepts multiple identifier types

**Before**:
```dart
// Email only - strict validation
CustomTextField(
  controller: _emailController,
  label: context.l10n.email,
  hintText: context.l10n.enterEmail,
  validator: (value) {
    if (!GetUtils.isEmail(value)) {
      return context.l10n.pleaseEnterValidEmail;
    }
  },
)
```

**After**:
```dart
// Email/Phone/Cooperative ID - flexible validation
CustomTextField(
  controller: _emailController,
  label: 'Email, Phone, or Cooperative ID',
  hintText: 'email@example.com, +250123456789, or COOP-ID-123',
  validator: (value) {
    // Accepts: email, +250 phone, or 5+ char alphanumeric ID
    // Returns null if any format is valid
  },
)
```

**Validation Logic**:
- **Email**: Must match standard email pattern (user@domain.com)
- **Phone**: Starts with '+' OR contains 10+ digits with regex match
- **Cooperative ID**: Alphanumeric with hyphens, 5+ characters minimum
- **User Hint**: Shows example of each accepted format

### 3. Verification Service Enhancement - `lib/services/verification_service.dart` (UPDATED)
**Added Methods & Features**:

```dart
// Identifies identifier type automatically
_identifyRequesterType(String identifier) → 'email' | 'phone' | 'cooperative_id'

// Updated createVerificationRequest signature
Future<String> createVerificationRequest(
  Map<String, dynamic> payload,
  {String requesterIdentifier = ''},
)

// New: Update verification status (approve/reject)
Future<void> updateVerificationStatus(
  String verificationId,
  {required String status, String? rejectionReason, String? approvedBy}
)

// New: Get verification request details
Future<Map<String, dynamic>?> getVerificationRequest(String verificationId)
```

**Changes to Firestore Document Creation**:
```dart
// Now includes:
'requesterEmail': identifier_value,
'requesterIdentifierType': 'email' | 'phone' | 'cooperative_id',
'createdAt': FieldValue.serverTimestamp(),  // Changed from DateTime.now()
```

### 4. Updated Register Logic - `lib/screens/auth/register_screen.dart` (UPDATED)
**When Cooperative Registration Occurs**:
```dart
// Pass identifier to service
final requesterIdentifier = _emailController.text.trim();
final verificationDocId = await verificationService.createVerificationRequest(
  {...payload},
  requesterIdentifier: requesterIdentifier,
);
// Cloud Function automatically sends email to admin
```

### 5. Package Dependencies - `functions/package.json` (UPDATED)
**Added**: `"nodemailer": "^6.9.7"`

```json
"dependencies": {
  "firebase-admin": "^12.0.0",
  "firebase-functions": "^4.5.0",
  "nodemailer": "^6.9.7"  // NEW
}
```

### 6. Setup Guide - `CLOUD_FUNCTION_EMAIL_SETUP.md` (NEW)
**Comprehensive deployment guide covering**:
- Installation and dependency setup
- Gmail SMTP configuration (App Password method)
- Firebase deployment commands
- Firestore document structure reference
- Admin approval workflow
- Testing procedures
- Troubleshooting common issues

## Firestore Document Structure

After registration, a document in `verifications` collection looks like:
```json
{
  "type": "cooperative",
  "userEmail": "user@example.com",
  "requesterEmail": "user@example.com or +250788123456 or COOP-ID-123",
  "requesterIdentifierType": "email | phone | cooperative_id",
  "firstName": "John",
  "lastName": "Doe",
  "requesterUserId": "auth-user-id",
  "adminEmail": "julieisaro01@gmail.com",
  "payload": {
    "coopName": "Coffee Farmers Cooperative",
    "coopGovId": "GOV-2024-001",
    "memberId": "MEM-456",
    "numFarmers": 50,
    "leaderName": "Jane Smith",
    "leaderPhone": "+250788123456",
    "leaderEmail": "jane@coop.rw",
    "coopFieldSize": 100,
    "coopNumFields": 25
  },
  "status": "pending",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "emailSentAt": "2024-01-15T10:30:15.000Z"  // Added by Cloud Function
}
```

## Admin Workflow

### Step 1: Receive Email
Admin receives HTML-formatted email with:
- User and cooperative details
- Leader contact information
- Verification ID
- Firebase Console link

### Step 2: Review in Firebase Console
- Open Firestore Database
- Navigate to `verifications` collection
- Find document by email search or verification ID

### Step 3: Approve
```
Edit verification document:
- Set status: "approved"
- Set approvedAt: [server timestamp]
- Set approvedBy: "admin@example.com"

User can now log in and use dashboard
```

### Step 4: Reject
```
Edit verification document:
- Set status: "rejected"
- Set reason: "explanation of rejection"
- Set rejectedAt: [server timestamp]

User cannot access dashboard
```

## Deployment Steps

### 1. Install dependencies in functions directory
```bash
cd functions
npm install
```

### 2. Configure Gmail authentication
```bash
# Option A: Using Firebase config
firebase functions:config:set gmail.user="julieisaro01@gmail.com"
firebase functions:config:set gmail.password="your-16-char-app-password"

# Generate app password at: https://myaccount.google.com/apppasswords
```

### 3. Deploy Cloud Functions
```bash
# From project root
firebase deploy --only functions

# Verify deployment
firebase functions:log --limit 50
```

### 4. Test
- Register a cooperative account
- Check admin email for notification
- Update verification document status to test approval flow

## Testing Checklist

- [ ] User can register with email as identifier
- [ ] User can register with phone number as identifier
- [ ] User can register with cooperative ID as identifier
- [ ] Invalid format is rejected with helpful message
- [ ] Admin receives email when cooperative registers
- [ ] Email contains all expected cooperative details
- [ ] Email contains verification ID
- [ ] Admin can update status in Firebase Console
- [ ] Unverified users cannot access dashboard
- [ ] Verified users (status: 'approved') can access dashboard

## Files Modified

1. ✅ `functions/src/onVerificationCreated.ts` - NEW
2. ✅ `functions/package.json` - UPDATED (added nodemailer)
3. ✅ `lib/screens/auth/register_screen.dart` - UPDATED (multi-identifier field)
4. ✅ `lib/services/verification_service.dart` - UPDATED (identifier tracking)
5. ✅ `CLOUD_FUNCTION_EMAIL_SETUP.md` - NEW (deployment guide)

## Next Steps (Optional Enhancements)

1. **Admin Dashboard**: Create UI for admin to view and manage verification requests
2. **Email Templates**: Move HTML to separate template files
3. **SMS Notifications**: Add SMS option for admin alerts
4. **Batch Processing**: Handle high-volume registrations
5. **Email Status Tracking**: Track bounced/failed emails
6. **Rejection Emails**: Send email to user when application is rejected
7. **Approval Confirmation**: Send confirmation email to user when approved

## Known Limitations

1. Cloud Function requires Gmail account with app password (not regular password)
2. Email delivery depends on Gmail SMTP availability
3. No retry logic if email fails (manual retry via callable function)
4. Admin must manually approve registrations via Firebase Console (no UI)

## Security Notes

1. ✅ Unverified users cannot access dashboard (no home button on verification pending screen)
2. ✅ Identifier type is tracked for audit trail
3. ✅ Admin email is configurable via Firestore settings
4. ✅ Email password should use Gmail app password (not account password)
5. Consider: Adding rate limiting to prevent registration spam

## Support

For issues or questions:
1. Check `CLOUD_FUNCTION_EMAIL_SETUP.md` troubleshooting section
2. Review Firebase Cloud Functions logs in console
3. Verify Firestore document structure matches expected format
4. Test email delivery with test cooperative registration
