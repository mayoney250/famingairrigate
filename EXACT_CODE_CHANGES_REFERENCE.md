# Exact Code Changes - Complete Reference

## Overview
This document shows every code change made to implement admin email notifications and multi-identifier registration.

---

## 1. functions/package.json
**Location**: `functions/package.json`
**Change**: Added nodemailer dependency

### Before:
```json
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0"
  },
```

### After:
```json
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0",
    "nodemailer": "^6.9.7"
  },
```

**Impact**: Enables email sending capability via Gmail SMTP

---

## 2. functions/index.js
**Location**: `functions/index.js`
**Changes**: Added nodemailer configuration and two new Cloud Functions

### Part 1: Added Imports & Configuration (Lines 1-16)
```javascript
// ADDED THESE LINES:
const nodemailer = require('nodemailer');

// ADDED THIS AFTER admin.initializeApp():
// Configure nodemailer with Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.ADMIN_EMAIL_USER || 'your-email@gmail.com',
    pass: process.env.ADMIN_EMAIL_PASSWORD || 'your-app-password',
  },
});
```

### Part 2: Added sendVerificationEmail Function (End of File)
```javascript
/**
 * Cloud Function: Triggered when a new verification request is created
 * Sends email to admin with verification details
 */
exports.sendVerificationEmail = functions
  .region('us-central1')
  .firestore.document('verifications/{verificationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const verificationId = context.params.verificationId;
    const adminEmail = data.adminEmail || 'julieisaro01@gmail.com';
    const requesterEmail = data.requesterEmail || 'unknown@example.com';
    const payload = data.payload || {};

    console.log(`New verification request: ${verificationId}`);
    console.log(`Admin email: ${adminEmail}`);
    console.log(`Requester email: ${requesterEmail}`);

    try {
      const registrationType = data.type || 'unknown';
      let emailBody = '';
      let emailSubject = '';

      if (registrationType === 'cooperative') {
        emailSubject = `New Cooperative Registration for Verification - ${payload.coopName}`;
        emailBody = `
<html>
  <body style="font-family: Arial, sans-serif; line-height: 1.6;">
    <h2>New Cooperative Registration</h2>
    <p>A new cooperative has registered and requires verification.</p>
    
    <h3>User Information:</h3>
    <ul>
      <li><strong>Name:</strong> ${payload.firstName} ${payload.lastName}</li>
      <li><strong>Email/Phone/ID:</strong> ${requesterEmail}</li>
      <li><strong>Identifier Type:</strong> ${data.requesterIdentifierType || 'unknown'}</li>
    </ul>

    <h3>Cooperative Information:</h3>
    <ul>
      <li><strong>Cooperative Name:</strong> ${payload.coopName}</li>
      <li><strong>Government ID:</strong> ${payload.coopGovId}</li>
      <li><strong>Member ID:</strong> ${payload.memberId}</li>
      <li><strong>Number of Farmers:</strong> ${payload.numFarmers}</li>
    </ul>

    <h3>Leader Information:</h3>
    <ul>
      <li><strong>Leader Name:</strong> ${payload.leaderName}</li>
      <li><strong>Leader Phone:</strong> ${payload.leaderPhone}</li>
      <li><strong>Leader Email:</strong> ${payload.leaderEmail}</li>
    </ul>

    <h3>Land Information:</h3>
    <ul>
      <li><strong>Total Field Size:</strong> ${payload.coopFieldSize} hectares</li>
      <li><strong>Number of Fields:</strong> ${payload.coopNumFields}</li>
    </ul>

    <hr style="border: none; border-top: 1px solid #ccc; margin: 20px 0;">
    <p><strong>Verification ID:</strong> ${verificationId}</p>
    <p>Log in to the Firebase Console to review and approve/reject this registration.</p>
    <p><a href="https://console.firebase.google.com">Firebase Console</a></p>
    
    <p style="color: #666; font-size: 12px;">
      This is an automated email from Faminga Irrigation System.
      Please do not reply to this email.
    </p>
  </body>
</html>
        `;
      } else {
        emailSubject = `New Farmer Registration for Verification - ${payload.firstName} ${payload.lastName}`;
        emailBody = `
<html>
  <body style="font-family: Arial, sans-serif; line-height: 1.6;">
    <h2>New Farmer Registration</h2>
    <p>A new farmer has registered and requires verification.</p>
    
    <h3>User Information:</h3>
    <ul>
      <li><strong>Name:</strong> ${payload.firstName} ${payload.lastName}</li>
      <li><strong>Email/Phone/ID:</strong> ${requesterEmail}</li>
      <li><strong>Identifier Type:</strong> ${data.requesterIdentifierType || 'unknown'}</li>
      <li><strong>Phone:</strong> ${payload.phoneNumber || 'N/A'}</li>
      <li><strong>Province:</strong> ${payload.province || 'N/A'}</li>
      <li><strong>District:</strong> ${payload.district || 'N/A'}</li>
    </ul>

    <hr style="border: none; border-top: 1px solid #ccc; margin: 20px 0;">
    <p><strong>Verification ID:</strong> ${verificationId}</p>
    <p>Log in to the Firebase Console to review and approve/reject this registration.</p>
    <p><a href="https://console.firebase.google.com">Firebase Console</a></p>
    
    <p style="color: #666; font-size: 12px;">
      This is an automated email from Faminga Irrigation System.
      Please do not reply to this email.
    </p>
  </body>
</html>
        `;
      }

      const mailOptions = {
        from: process.env.ADMIN_EMAIL_USER || 'your-email@gmail.com',
        to: adminEmail,
        subject: emailSubject,
        html: emailBody,
      };

      await transporter.sendMail(mailOptions);
      console.log(`Email sent successfully to ${adminEmail}`);

      await snap.ref.update({
        emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error('Error sending email:', error);
      await snap.ref.update({
        emailError: error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  });
```

### Part 3: Added retriggerVerificationEmail Function (End of File)
```javascript
/**
 * Cloud Function: HTTP endpoint to manually trigger verification emails
 * Useful for testing or re-sending emails
 */
exports.retriggerVerificationEmail = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be authenticated to trigger emails'
      );
    }

    const { verificationId } = data;

    try {
      const verificationSnap = await db
        .collection('verifications')
        .doc(verificationId)
        .get();

      if (!verificationSnap.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Verification request not found'
        );
      }

      const verificationData = verificationSnap.data();
      const adminEmail = verificationData.adminEmail || 'julieisaro01@gmail.com';
      const payload = verificationData.payload || {};
      const requesterEmail = verificationData.requesterEmail || 'unknown@example.com';
      const registrationType = verificationData.type || 'unknown';

      let emailSubject = '';
      let emailBody = '';

      if (registrationType === 'cooperative') {
        emailSubject = `[RE-SENT] New Cooperative Registration - ${payload.coopName}`;
        emailBody = `
          <html>
            <body style="font-family: Arial, sans-serif;">
              <h2>[Re-sent] Cooperative Registration</h2>
              <p>Cooperative: ${payload.coopName}</p>
              <p>Leader: ${payload.leaderName}</p>
              <p>Verification ID: ${verificationId}</p>
              <p><a href="https://console.firebase.google.com">Firebase Console</a></p>
            </body>
          </html>
        `;
      } else {
        emailSubject = `[RE-SENT] New Farmer Registration - ${payload.firstName} ${payload.lastName}`;
        emailBody = `
          <html>
            <body style="font-family: Arial, sans-serif;">
              <h2>[Re-sent] Farmer Registration</h2>
              <p>Name: ${payload.firstName} ${payload.lastName}</p>
              <p>Email: ${requesterEmail}</p>
              <p>Verification ID: ${verificationId}</p>
              <p><a href="https://console.firebase.google.com">Firebase Console</a></p>
            </body>
          </html>
        `;
      }

      const mailOptions = {
        from: process.env.ADMIN_EMAIL_USER || 'your-email@gmail.com',
        to: adminEmail,
        subject: emailSubject,
        html: emailBody,
      };

      await transporter.sendMail(mailOptions);
      return { success: true, message: 'Email sent successfully' };
    } catch (error) {
      console.error('Error in retriggerVerificationEmail:', error);
      throw new functions.https.HttpsError(
        'internal',
        error instanceof Error ? error.message : 'Failed to send email'
      );
    }
  });
```

**Impact**: 
- `sendVerificationEmail`: Automatically sends email when verification document is created
- `retriggerVerificationEmail`: Allows manual re-sending of emails for testing/debugging

---

## 3. lib/services/verification_service.dart
**Location**: `lib/services/verification_service.dart`
**Changes**: Enhanced with identifier type tracking and new methods

### Added Import:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
```

### Added Identifier Detection Method:
```dart
/// Identifies what type of identifier was provided (email, phone, or cooperative ID)
static String _identifyRequesterType(String identifier) {
  if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(identifier)) {
    return 'email';
  }
  if (identifier.startsWith('+') || 
      (identifier.replaceAll(RegExp(r'\D'), '').length >= 10 && 
       identifier.contains(RegExp(r'\d')))) {
    return 'phone';
  }
  if (RegExp(r'^[A-Z0-9-]{5,}$', caseSensitive: false).hasMatch(identifier)) {
    return 'cooperative_id';
  }
  return 'unknown';
}
```

### Updated createVerificationRequest Method:
```dart
/// Creates a verification request in Firestore. Returns the document id.
/// The [requesterIdentifier] can be email, phone number, or cooperative ID.
Future<String> createVerificationRequest(
  Map<String, dynamic> payload, {
  String requesterIdentifier = '',
}) async {
  final identifierType = _identifyRequesterType(requesterIdentifier);
  
  final docRef = await _firestore.collection('verifications').add({
    ...payload,
    'requesterEmail': requesterIdentifier,
    'requesterIdentifierType': identifierType,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
  return docRef.id;
}
```

### Added New Methods:
```dart
/// Updates verification request status (approve/reject)
Future<void> updateVerificationStatus(
  String verificationId, {
  required String status,
  String? rejectionReason,
  String? approvedBy,
}) async {
  final updateData = {
    'status': status,
    if (status == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
    if (status == 'approved' && approvedBy != null) 'approvedBy': approvedBy,
    if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
    if (status == 'rejected' && rejectionReason != null) 'rejectionReason': rejectionReason,
  };
  await _firestore.collection('verifications').doc(verificationId).update(updateData);
}

/// Retrieves a verification request
Future<Map<String, dynamic>?> getVerificationRequest(String verificationId) async {
  final doc = await _firestore.collection('verifications').doc(verificationId).get();
  if (doc.exists) {
    return doc.data() as Map<String, dynamic>;
  }
  return null;
}
```

**Impact**: 
- Tracks what type of identifier user provided
- Enables admin status updates
- Provides retrieval methods for admin dashboard (future feature)

---

## 4. lib/screens/auth/register_screen.dart
**Location**: `lib/screens/auth/register_screen.dart`
**Changes**: Updated email field and verification request creation

### Part 1: Email Field Validation (around line 240)

**Before**:
```dart
// Email
CustomTextField(
  controller: _emailController,
  label: context.l10n.email,
  hintText: context.l10n.enterEmail,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.email_outlined,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return context.l10n.pleaseEnterEmail;
    }
    if (!GetUtils.isEmail(value)) {
      return context.l10n.pleaseEnterValidEmail;
    }
    return null;
  },
),
```

**After**:
```dart
// Email/Phone/Cooperative ID
CustomTextField(
  controller: _emailController,
  label: 'Email, Phone, or Cooperative ID',
  hintText: 'email@example.com, +250123456789, or COOP-ID-123',
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.person_outline,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return context.l10n.pleaseEnterEmail;
    }
    
    final email = value.trim();
    
    // Check if it's a valid email
    if (GetUtils.isEmail(email)) {
      return null;
    }
    
    // Check if it's a phone number (starts with + or has 10+ digits)
    if (email.startsWith('+') || 
        (email.replaceAll(RegExp(r'\D'), '').length >= 10 && 
         email.contains(RegExp(r'\d')))) {
      return null;
    }
    
    // Check if it's a cooperative ID (alphanumeric with hyphens, 5+ chars)
    if (RegExp(r'^[A-Z0-9-]{5,}$', caseSensitive: false).hasMatch(email)) {
      return null;
    }
    
    return 'Please enter a valid email, phone number (+250123456789), or cooperative ID (e.g., COOP-ID-123)';
  },
),
```

### Part 2: Verification Request Creation (around line 95-135)

**Before**:
```dart
// create verification request and include admin email
final adminEmail = await verificationService.getAdminEmail();
final verificationDocId = await verificationService.createVerificationRequest({
  'adminEmail': adminEmail,
  'requesterEmail': _emailController.text.trim(),
  'requesterUserId': authProvider.currentUser?.userId ?? '',
  'payload': coopPayload,
});

// Ideally a cloud function triggers an email to admin. For now, store doc id so admin can verify.
```

**After**:
```dart
// create verification request and include admin email
final adminEmail = await verificationService.getAdminEmail();
final requesterIdentifier = _emailController.text.trim();
final verificationDocId = await verificationService.createVerificationRequest(
  {
    'adminEmail': adminEmail,
    'requesterUserId': authProvider.currentUser?.userId ?? '',
    'payload': coopPayload,
  },
  requesterIdentifier: requesterIdentifier,
);

// Cloud Function triggers an email to admin automatically
// Verification document stored with identifier type for admin reference
```

**Impact**: 
- Email field now accepts multiple identifier types
- Passes identifier to service so type can be tracked
- Better user feedback with clear hints and error messages

---

## Summary of Changes by File

| File | Change Type | Lines Added | Impact |
|------|-------------|-------------|--------|
| `functions/package.json` | Dependency | +1 | Enables email sending |
| `functions/index.js` | Functions | ~250 | Sends emails automatically |
| `lib/services/verification_service.dart` | Enhancement | ~60 | Identifier tracking |
| `lib/screens/auth/register_screen.dart` | UI + Logic | ~30 | Multi-identifier support |

**Total New Code**: ~340 lines
**Total Modified Code**: ~100 lines
**Deleted Code**: 0 lines (only added/updated)

---

## Key Features Implemented

1. **Automatic Email Notifications**
   - Triggered on Firestore document creation
   - HTML formatted emails
   - Supports both cooperative and individual registrations

2. **Multi-Identifier Support**
   - Email: user@domain.com
   - Phone: +250788123456 or 10+ digits
   - Cooperative ID: COOP-ID-123 (5+ alphanumeric)

3. **Identifier Tracking**
   - Firestore stores identifier type
   - Admin can reference any format
   - Audit trail for security

4. **Admin Verification Workflow**
   - Email notification on registration
   - Firestore Console for approval/rejection
   - Status tracking and timestamps

---

## Testing the Changes

### Flutter App Changes:
```bash
flutter clean
flutter pub get
flutter run
```

### Cloud Function Deployment:
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Configuration:
```bash
firebase functions:config:set gmail.user="julieisaro01@gmail.com"
firebase functions:config:set gmail.password="xxxx xxxx xxxx xxxx"
```

---

**Status**: All changes implemented and ready for deployment ✅
