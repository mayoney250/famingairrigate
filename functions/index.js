const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Configure nodemailer with Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    // Prefer functions config, fall back to process.env
    user: (functions.config().mail && functions.config().mail.user) || process.env.ADMIN_EMAIL_USER || 'your-email@gmail.com',
    pass: (functions.config().mail && functions.config().mail.pass) || process.env.ADMIN_EMAIL_PASSWORD || 'your-app-password',
  },
});

async function sendNotificationToUser(userId, notification) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      console.log('User not found:', userId);
      return;
    }

    const userData = userDoc.data();
    const fcmTokens = userData.fcmTokens || [];

    if (fcmTokens.length === 0) {
      console.log('No FCM tokens for user:', userId);
      return;
    }

    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      tokens: fcmTokens,
    };

    const response = await messaging.sendMulticast(message);
    console.log(`✓ Successfully sent ${response.successCount} notifications`);

    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(fcmTokens[idx]);
        }
      });

      if (failedTokens.length > 0) {
        await db.collection('users').doc(userId).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens)
        });
        console.log('Removed invalid tokens:', failedTokens.length);
      }
    }

    return response;
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
}

exports.checkIrrigationNeeds = functions.pubsub
  .schedule('every 2 hours')
  .onRun(async (context) => {
    console.log('Checking irrigation needs...');

    try {
      const now = admin.firestore.Timestamp.now();
      const fieldsSnapshot = await db.collection('fields').get();

      for (const fieldDoc of fieldsSnapshot.docs) {
        const field = fieldDoc.data();
        const fieldId = fieldDoc.id;

        const sensorsSnapshot = await db
          .collection('sensors')
          .where('fieldId', '==', fieldId)
          .where('type', '==', 'soil_moisture')
          .get();

        for (const sensorDoc of sensorsSnapshot.docs) {
          const sensor = sensorDoc.data();

          const latestReadingSnapshot = await db
            .collection('sensor_readings')
            .where('sensorId', '==', sensorDoc.id)
            .orderBy('timestamp', 'desc')
            .limit(1)
            .get();

          if (!latestReadingSnapshot.empty) {
            const reading = latestReadingSnapshot.docs[0].data();
            const moistureLevel = reading.value;

            const threshold = sensor.lowThreshold || 50;
            const criticalThreshold = sensor.criticalThreshold || 40;

            // Check for critically dry soil (≤40%)
            if (moistureLevel <= criticalThreshold) {
              const lastAlertSnapshot = await db
                .collection('alerts')
                .where('fieldId', '==', fieldId)
                .where('type', '==', 'soil_dry')
                .where('sensorId', '==', sensorDoc.id)
                .orderBy('timestamp', 'desc')
                .limit(1)
                .get();

              let shouldAlert = true;
              if (!lastAlertSnapshot.empty) {
                const lastAlert = lastAlertSnapshot.docs[0].data();
                const hoursSinceLastAlert =
                  (now.toMillis() - lastAlert.timestamp.toMillis()) / (1000 * 60 * 60);
                
                if (hoursSinceLastAlert < 4) {
                  shouldAlert = false;
                }
              }

              if (shouldAlert) {
                await db.collection('alerts').add({
                  userId: field.userId,
                  fieldId: fieldId,
                  fieldName: field.name,
                  sensorId: sensorDoc.id,
                  sensorName: sensor.name,
                  type: 'soil_dry',
                  severity: 'critical',
                  message: `URGENT: Soil is critically dry (${moistureLevel.toFixed(1)}%) in ${field.name}. Immediate irrigation required.`,
                  moistureLevel: moistureLevel,
                  threshold: criticalThreshold,
                  timestamp: now,
                  read: false,
                });

                await sendNotificationToUser(field.userId, {
                  title: '[URGENT] Soil Critically Dry',
                  body: `Soil is critically dry (${moistureLevel.toFixed(1)}%) in ${field.name}. Immediate irrigation required.`,
                  data: {
                    type: 'soil_dry',
                    fieldId: fieldId,
                    sensorId: sensorDoc.id,
                    moistureLevel: moistureLevel.toString(),
                  },
                });

                console.log(`✓ Critical soil dry alert sent for field ${fieldId}`);
              }
            }
            // Check for low moisture (irrigation needed)
            else if (moistureLevel < threshold) {
              const lastAlertSnapshot = await db
                .collection('alerts')
                .where('fieldId', '==', fieldId)
                .where('type', '==', 'irrigation_needed')
                .where('sensorId', '==', sensorDoc.id)
                .orderBy('timestamp', 'desc')
                .limit(1)
                .get();

              let shouldAlert = true;
              if (!lastAlertSnapshot.empty) {
                const lastAlert = lastAlertSnapshot.docs[0].data();
                const hoursSinceLastAlert =
                  (now.toMillis() - lastAlert.timestamp.toMillis()) / (1000 * 60 * 60);
                
                if (hoursSinceLastAlert < 6) {
                  shouldAlert = false;
                }
              }

              if (shouldAlert) {
                await db.collection('alerts').add({
                  userId: field.userId,
                  fieldId: fieldId,
                  fieldName: field.name,
                  sensorId: sensorDoc.id,
                  sensorName: sensor.name,
                  type: 'irrigation_needed',
                  severity: 'medium',
                  message: `Soil moisture is low (${moistureLevel.toFixed(1)}%) in ${field.name}. Irrigation recommended.`,
                  moistureLevel: moistureLevel,
                  threshold: threshold,
                  timestamp: now,
                  read: false,
                });

                await sendNotificationToUser(field.userId, {
                  title: '[URGENT] Irrigation Needed',
                  body: `Soil moisture is low (${moistureLevel.toFixed(1)}%) in ${field.name}. Time to irrigate.`,
                  data: {
                    type: 'irrigation_needed',
                    fieldId: fieldId,
                    sensorId: sensorDoc.id,
                    moistureLevel: moistureLevel.toString(),
                  },
                });

                console.log(`✓ Irrigation alert sent for field ${fieldId}`);
              }
            }
          }
        }
      }

      console.log('✓ Irrigation needs check completed');
      return null;
    } catch (error) {
      console.error('Error checking irrigation needs:', error);
      throw error;
    }
  });

exports.checkWaterLevels = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    console.log('Checking water levels...');

    try {
      const now = admin.firestore.Timestamp.now();
      
      const waterSensorsSnapshot = await db
        .collection('sensors')
        .where('type', '==', 'water_level')
        .get();

      for (const sensorDoc of waterSensorsSnapshot.docs) {
        const sensor = sensorDoc.data();

        const latestReadingSnapshot = await db
          .collection('sensor_readings')
          .where('sensorId', '==', sensorDoc.id)
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();

        if (!latestReadingSnapshot.empty) {
          const reading = latestReadingSnapshot.docs[0].data();
          const waterLevel = reading.value;

          const lowThreshold = sensor.lowThreshold || 20;
          const criticalThreshold = sensor.criticalThreshold || 10;

          let severity = null;
          let threshold = null;

          if (waterLevel <= criticalThreshold) {
            severity = 'critical';
            threshold = criticalThreshold;
          } else if (waterLevel <= lowThreshold) {
            severity = 'medium';
            threshold = lowThreshold;
          }

          if (severity) {
            const lastAlertSnapshot = await db
              .collection('alerts')
              .where('type', '==', 'water_low')
              .where('sensorId', '==', sensorDoc.id)
              .orderBy('timestamp', 'desc')
              .limit(1)
              .get();

            let shouldAlert = true;
            if (!lastAlertSnapshot.empty) {
              const lastAlert = lastAlertSnapshot.docs[0].data();
              const hoursSinceLastAlert =
                (now.toMillis() - lastAlert.timestamp.toMillis()) / (1000 * 60 * 60);
              
              if (hoursSinceLastAlert < 4 && lastAlert.severity === severity) {
                shouldAlert = false;
              }
            }

            if (shouldAlert) {
              const fieldDoc = await db.collection('fields').doc(sensor.fieldId).get();
              const field = fieldDoc.exists ? fieldDoc.data() : null;

              await db.collection('alerts').add({
                userId: sensor.userId,
                fieldId: sensor.fieldId,
                fieldName: field?.name || 'Unknown Field',
                sensorId: sensorDoc.id,
                sensorName: sensor.name,
                type: 'water_low',
                severity: severity,
                message: `Water level is ${severity === 'critical' ? 'critically' : ''} low (${waterLevel.toFixed(1)}%) at ${sensor.name}.`,
                waterLevel: waterLevel,
                threshold: threshold,
                timestamp: now,
                read: false,
              });

              const notificationTitle = severity === 'critical' 
                ? '[URGENT] Critical Water Level' 
                : '[URGENT] Low Water Level';
              
              const notificationBody = `Water level is ${severity === 'critical' ? 'critically' : ''} low (${waterLevel.toFixed(1)}%) at ${sensor.name}. ${severity === 'critical' ? 'Immediate action required!' : 'Please refill soon.'}`;

              await sendNotificationToUser(sensor.userId, {
                title: notificationTitle,
                body: notificationBody,
                data: {
                  type: 'water_low',
                  sensorId: sensorDoc.id,
                  waterLevel: waterLevel.toString(),
                  severity: severity,
                },
              });

              console.log(`✓ Water level alert sent for sensor ${sensorDoc.id}`);
            }
          }
        }
      }

      console.log('✓ Water level check completed');
      return null;
    } catch (error) {
      console.error('Error checking water levels:', error);
      throw error;
    }
  });

exports.sendScheduleReminders = functions.pubsub
  .schedule('every 30 minutes')
  .onRun(async (context) => {
    console.log('Checking irrigation schedules...');

    try {
      const now = admin.firestore.Timestamp.now();
      const nowDate = now.toDate();
      const in30Minutes = new Date(nowDate.getTime() + 30 * 60 * 1000);

      const schedulesSnapshot = await db
        .collection('irrigation_schedules')
        .where('status', '==', 'active')
        .get();

      for (const scheduleDoc of schedulesSnapshot.docs) {
        const schedule = scheduleDoc.data();
        const scheduleTime = schedule.scheduledTime?.toDate();

        if (!scheduleTime) continue;

        const timeDiff = scheduleTime.getTime() - nowDate.getTime();
        const minutesUntil = timeDiff / (1000 * 60);

        if (minutesUntil > 0 && minutesUntil <= 30) {
          const lastReminderSnapshot = await db
            .collection('schedule_reminders')
            .where('scheduleId', '==', scheduleDoc.id)
            .where('timestamp', '>', new Date(nowDate.getTime() - 60 * 60 * 1000))
            .get();

          if (lastReminderSnapshot.empty) {
            const fieldDoc = await db.collection('fields').doc(schedule.fieldId).get();
            const field = fieldDoc.exists ? fieldDoc.data() : null;

            await db.collection('schedule_reminders').add({
              scheduleId: scheduleDoc.id,
              timestamp: now,
            });

            await sendNotificationToUser(schedule.userId, {
              title: '[REMINDER] Irrigation Scheduled',
              body: `Irrigation scheduled for ${field?.name || 'your field'} in ${Math.round(minutesUntil)} minutes.`,
              data: {
                type: 'schedule_reminder',
                scheduleId: scheduleDoc.id,
                fieldId: schedule.fieldId,
              },
            });

            console.log(`✓ Schedule reminder sent for ${scheduleDoc.id}`);
          }
        }
      }

      console.log('✓ Schedule reminders check completed');
      return null;
    } catch (error) {
      console.error('Error checking schedules:', error);
      throw error;
    }
  });

exports.onIrrigationStatusChange = functions.firestore
  .document('irrigation_cycles/{cycleId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    if (newData.status !== oldData.status) {
      const fieldDoc = await db.collection('fields').doc(newData.fieldId).get();
      const field = fieldDoc.exists ? fieldDoc.data() : null;

      let title = '';
      let body = '';
      let shouldSend = false;

      switch (newData.status) {
        case 'running':
          title = '[INFO] Irrigation Started';
          body = `Irrigation has started for ${field?.name || 'your field'}.`;
          shouldSend = true;
          break;
        case 'completed':
          title = '[INFO] Irrigation Completed';
          body = `Irrigation completed for ${field?.name || 'your field'}. Total water used: ${newData.waterUsed || 0}L`;
          shouldSend = true;
          break;
        case 'stopped':
          title = '[INFO] Irrigation Stopped';
          body = `Irrigation was manually stopped for ${field?.name || 'your field'}.`;
          shouldSend = true;
          break;
        case 'failed':
          title = '[URGENT] Irrigation Failed';
          body = `Irrigation failed for ${field?.name || 'your field'}. Please check the system.`;
          shouldSend = true;
          break;
      }

      if (shouldSend && title && body) {
        await sendNotificationToUser(newData.userId, {
          title: title,
          body: body,
          data: {
            type: 'irrigation_status',
            cycleId: context.params.cycleId,
            fieldId: newData.fieldId,
            status: newData.status,
          },
        });

        console.log(`✓ Irrigation status notification sent: ${newData.status} for cycle ${context.params.cycleId}`);
      }
    }

    return null;
  });

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
      // Generate a one-time approval token and save it to the verification doc
      const approvalToken = crypto.randomBytes(24).toString('hex');
      await snap.ref.update({
        approvalToken: approvalToken,
        approvalTokenCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      // Determine registration type
      const registrationType = data.type || 'unknown';
      let emailBody = '';
      let emailSubject = '';

      // Build an approval URL the admin can click. Use the GCLOUD_PROJECT env to form the function URL.
      const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_CONFIG && JSON.parse(process.env.FIREBASE_CONFIG).projectId || '';
      const approveBase = `https://us-central1-${projectId}.cloudfunctions.net/approveVerification`;
      const approveUrl = `${approveBase}?verificationId=${verificationId}&token=${approvalToken}`;

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
      <li><strong>Cooperative ID:</strong> ${payload.coopGovId}</li>
      <li><strong>Number of Farmers:</strong> ${payload.numFarmers}</li>
    </ul>

    <p>
      <strong>Approve registration:</strong>
      <a href="${approveUrl}">Click here to approve</a>
    </p>

    <hr style="border: none; border-top: 1px solid #ccc; margin: 20px 0;">
    <p><strong>Verification ID:</strong> ${verificationId}</p>
    
    <p style="color: #666; font-size: 12px;">
      This is an automated email from Faminga Irrigation System.
      Please do not reply to this email.
    </p>
  </body>
</html>
        `;
      } else {
        // Individual farmer registration
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

    <p>
      <strong>Approve registration:</strong>
      <a href="${approveUrl}">Click here to approve</a>
    </p>

    <hr style="border: none; border-top: 1px solid #ccc; margin: 20px 0;">
    <p><strong>Verification ID:</strong> ${verificationId}</p>
    
    <p style="color: #666; font-size: 12px;">
      This is an automated email from Faminga Irrigation System.
      Please do not reply to this email.
    </p>
  </body>
</html>
        `;
      }

      // Send email
      const mailOptions = {
        from: process.env.ADMIN_EMAIL_USER || 'your-email@gmail.com',
        to: adminEmail,
        subject: emailSubject,
        html: emailBody,
      };

      await transporter.sendMail(mailOptions);
      console.log(`Email sent successfully to ${adminEmail}`);

      // Update verification request with email sent timestamp
      await snap.ref.update({
        emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error('Error sending email:', error);
      // Update verification with error
      await snap.ref.update({
        emailError: error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  });

/**
 * Cloud Function: HTTP endpoint to manually trigger verification emails
 * Useful for testing or re-sending emails
 */
exports.retriggerVerificationEmail = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    // Verify the user is authenticated
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

/**
 * Cloud Function: Triggered when a new AI recommendation is created
 * Persists an in-app alert and sends FCM push notifications to the user's devices
 */
exports.onAIRecommendationCreated = functions.firestore
  .document('ai_recommendations/{recId}')
  .onCreate(async (snap, context) => {
    try {
      const data = snap.data();
      if (!data) {
        console.log('[AI_FN] Empty recommendation document');
        return null;
      }

      const userId = data.userId;
      const fieldId = data.fieldId;
      const recommendation = (data.recommendation || '').toString().toLowerCase();
      const reasoning = data.reasoning || '';
      const confidence = typeof data.confidence === 'number' ? data.confidence : (data.confidence || 0);

      console.log(`[AI_FN] New AI recommendation for user=${userId} field=${fieldId} rec=${recommendation}`);

      // Resolve field name
      let fieldName = 'your field';
      if (fieldId) {
        try {
          const fDoc = await db.collection('fields').doc(fieldId).get();
          if (fDoc.exists) fieldName = fDoc.data().name || fieldName;
        } catch (e) {
          console.log('[AI_FN] Error resolving field name:', e);
        }
      }

      // Create an in-app alert document for UI and audit
      const alertPayload = {
        userId: userId,
        fieldId: fieldId,
        fieldName: fieldName,
        type: `ai_${recommendation}`,
        severity: recommendation === 'alert' ? 'critical' : (recommendation === 'irrigate' ? 'high' : 'low'),
        message: `AI recommends ${recommendation} for ${fieldName}. ${reasoning || ''}`,
        recommendation: recommendation,
        reason: reasoning,
        confidence: confidence,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        origin: 'ai',
        read: false,
      };

      await db.collection('alerts').add(alertPayload);
      console.log('[AI_FN] In-app alert created');

      // Prepare FCM notification
      let title = 'AI Recommendation';
      let body = `AI suggests ${recommendation} for ${fieldName}.`;
      const notificationType = `ai_${recommendation}`;
      if (recommendation === 'irrigate') title = '💧 AI: Irrigate Now';
      if (recommendation === 'hold') title = '⏸️ AI: Hold Irrigation';
      if (recommendation === 'alert') title = '⚠️ AI Alert';
      if (reasoning) body += ` ${reasoning}`;

      // Load user tokens
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        console.log('[AI_FN] User doc not found, skipping push');
        return null;
      }

      const userData = userDoc.data() || {};
      const tokens = Array.isArray(userData.fcmTokens) ? userData.fcmTokens : [];

      if (!tokens || tokens.length === 0) {
        console.log('[AI_FN] No FCM tokens for user, skipping push');
        return null;
      }

      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: notificationType,
          fieldId: fieldId || '',
          recId: context.params.recId,
          confidence: String(confidence),
        },
        tokens: tokens,
      };

      const response = await messaging.sendMulticast(message);
      console.log(`[AI_FN] FCM send result: success=${response.successCount} failure=${response.failureCount}`);

      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) failedTokens.push(tokens[idx]);
        });

        if (failedTokens.length > 0) {
          await db.collection('users').doc(userId).update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens),
          });
          console.log('[AI_FN] Removed invalid FCM tokens:', failedTokens.length);
        }
      }

      return null;
    } catch (err) {
      console.error('[AI_FN] Error handling AI recommendation:', err);
      throw err;
    }
  });

/**
 * Callable function: resolveIdentifier
 * Accepts { identifier: string }
 * Tries to resolve identifier (phone number or cooperative ID) to a registered email.
 * Returns { email: string|null, foundBy: 'phone'|'coopGovId'|'memberId'|null }
 * This runs with admin privileges so it bypasses Firestore rules safely.
 */
exports.resolveIdentifier = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    const identifier = (data && data.identifier) ? String(data.identifier).trim() : '';
    if (!identifier) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing identifier');
    }

    try {
      console.log('resolveIdentifier called for:', identifier);

      // Try phone lookup
      const phoneQ = await db.collection('users').where('phoneNumber', '==', identifier).limit(1).get();
      if (!phoneQ.empty) {
        const u = phoneQ.docs[0].data();
        return { email: u.email || null, foundBy: 'phone' };
      }

      // Try cooperative government id inside cooperative map
      const coopGovQ = await db.collection('users').where('cooperative.coopGovId', '==', identifier).limit(1).get();
      if (!coopGovQ.empty) {
        const u = coopGovQ.docs[0].data();
        return { email: u.email || null, foundBy: 'coopGovId' };
      }

      // Try cooperative member id
      const coopMemberQ = await db.collection('users').where('cooperative.memberId', '==', identifier).limit(1).get();
      if (!coopMemberQ.empty) {
        const u = coopMemberQ.docs[0].data();
        return { email: u.email || null, foundBy: 'memberId' };
      }

      // Not found
      return { email: null, foundBy: null };
    } catch (err) {
      console.error('Error in resolveIdentifier:', err);
      throw new functions.https.HttpsError('internal', 'Failed to resolve identifier');
    }
  });

  /**
   * HTTP function: approveVerification
   * Expects query params: verificationId, token
   * Validates the token matches the verification doc, then sets verification status
   * on the verification doc and updates the corresponding user document to set
   * 'verificationStatus': 'approved'
   * Includes token expiry (7 days) and audit logging.
   */
  exports.approveVerification = functions
    .region('us-central1')
    .https.onRequest(async (req, res) => {
      try {
        const verificationId = req.query.verificationId;
        const token = req.query.token;

        if (!verificationId || !token) {
          res.status(400).send('Missing verificationId or token');
          return;
        }

        const verRef = db.collection('verifications').doc(String(verificationId));
        const verSnap = await verRef.get();
        if (!verSnap.exists) {
          res.status(404).send('Verification request not found');
          return;
        }

        const ver = verSnap.data() || {};
        if (!ver.approvalToken || ver.approvalToken !== String(token)) {
          // Log potential token tampering attempt
          await db.collection('approval_logs').add({
            verificationId: verificationId,
            status: 'failed_invalid_token',
            failureReason: 'Token mismatch or missing',
            attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: req.ip || 'unknown',
            userAgent: (req.get('user-agent') || 'unknown').substring(0, 256),
          });
          res.status(403).send('Invalid or expired token');
          return;
        }

        // Check token expiry (7 days)
        const tokenCreatedAt = ver.approvalTokenCreatedAt;
        if (tokenCreatedAt) {
          const now = admin.firestore.Timestamp.now();
          const tokenAgeMs = now.toMillis() - tokenCreatedAt.toMillis();
          const tokenAgeHours = tokenAgeMs / (1000 * 3600);
          const tokenMaxHours = 7 * 24; // 7 days
          if (tokenAgeHours > tokenMaxHours) {
            console.warn(`✗ Token expired for verification ${verificationId}: age ${tokenAgeHours.toFixed(1)}h > ${tokenMaxHours}h`);
            await db.collection('approval_logs').add({
              verificationId: verificationId,
              status: 'failed_expired_token',
              failureReason: `Token expired after ${tokenAgeHours.toFixed(1)} hours`,
              attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
              ipAddress: req.ip || 'unknown',
            });
            res.status(403).send('Token expired. Please request a new verification email.');
            return;
          }
        }

        // Check if already approved (idempotency)
        if (ver.status === 'approved') {
          console.log(`ℹ Verification ${verificationId} already approved at ${ver.approvedAt}`);
          res.status(200).send('<html><body><h2>Already Approved</h2><p>This registration was already approved.</p></body></html>');
          return;
        }

        // Check if rejected
        if (ver.status === 'rejected') {
          console.warn(`✗ Attempted to approve a rejected verification: ${verificationId}`);
          await db.collection('approval_logs').add({
            verificationId: verificationId,
            status: 'failed_already_rejected',
            failureReason: 'Verification previously rejected',
            attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: req.ip || 'unknown',
          });
          res.status(403).send('This registration has been rejected and cannot be approved.');
          return;
        }

        // Mark verification as approved
        await verRef.update({
          status: 'approved',
          approvedAt: admin.firestore.FieldValue.serverTimestamp(),
          approvedBy: ver.adminEmail || 'admin',
          approvalIpAddress: req.ip || 'unknown',
          approvalUserAgent: (req.get('user-agent') || 'unknown').substring(0, 256),
        });

        // Update user document. Prefer requesterUserId if present, otherwise try requesterEmail
        let userId = null;
        if (ver.requesterUserId) {
          userId = ver.requesterUserId;
          await db.collection('users').doc(ver.requesterUserId).update({ verificationStatus: 'approved' });
        } else if (ver.requesterEmail) {
          const q = await db.collection('users').where('email', '==', ver.requesterEmail).limit(1).get();
          if (!q.empty) {
            userId = q.docs[0].id;
            await db.collection('users').doc(userId).update({ verificationStatus: 'approved' });
          }
        }

        // Log successful approval for audit trail
        if (userId) {
          await db.collection('approval_logs').add({
            verificationId: verificationId,
            userId: userId,
            userEmail: ver.requesterEmail,
            status: 'success',
            approvedAt: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: req.ip || 'unknown',
            userAgent: (req.get('user-agent') || 'unknown').substring(0, 256),
          });
          console.log(`✓ Approval successful: user ${userId}, verification ${verificationId}`);
        } else {
          console.warn(`⚠ Approval token valid but could not find user for verification ${verificationId}`);
        }

        // Return friendly confirmation page
        res.status(200).send(`
<html>
  <head><title>Verification Approved</title></head>
  <body style="font-family: Arial, sans-serif; text-align: center; padding: 20px;">
    <h2>✓ Registration Approved</h2>
    <p>Your registration has been approved! You can now log in and access the dashboard.</p>
    <p>If you have any issues logging in, please contact support.</p>
  </body>
</html>
        `);
      } catch (err) {
        console.error('✗ approveVerification error:', err);
        try {
          await db.collection('approval_logs').add({
            status: 'error',
            errorMessage: (err instanceof Error ? err.message : String(err)).substring(0, 500),
            errorAt: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: req.ip || 'unknown',
          });
        } catch (logErr) {
          console.error('Failed to log error:', logErr);
        }
        res.status(500).send('Internal error: ' + (err instanceof Error ? err.message : 'unknown'));
      }
    });

  /**
   * One-time protected migration: approve all existing users missing verificationStatus
   * Protected by a secret key passed as query param 'secret'. Configure required secret
   * with `firebase functions:config:set migrate.secret="YOUR_SECRET"` before deployment,
   * then call: /migrateApproveMissing?secret=YOUR_SECRET
   * Includes audit logging and detailed progress output.
   */
  exports.migrateApproveMissingVerification = functions
    .region('us-central1')
    .https.onRequest(async (req, res) => {
      try {
        const provided = req.query.secret || '';
        const cfg = functions.config();
        const required = (cfg.migrate && cfg.migrate.secret) || process.env.MIGRATE_SECRET || '';
        
        if (!required) {
          console.error('✗ Migration secret not configured in Firebase functions config');
          res.status(500).send('Migration not configured. Admin must set migrate.secret in Firebase config.');
          return;
        }
        
        if (!provided || String(provided) !== String(required)) {
          await db.collection('approval_logs').add({
            verificationId: 'migration_attempt',
            status: 'failed_unauthorized',
            failureReason: 'Invalid or missing secret',
            attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: req.ip || 'unknown',
          });
          console.warn(`✗ Migration unauthorized attempt from ${req.ip}`);
          res.status(403).send('Forbidden: Invalid secret');
          return;
        }

        console.log('🔄 Starting migration to approve missing verificationStatus fields...');
        const usersSnap = await db.collection('users').get();
        const batch = db.batch();
        let updated = 0;
        const updatedUserIds = [];
        
        usersSnap.docs.forEach(doc => {
          const data = doc.data() || {};
          if (!('verificationStatus' in data)) {
            batch.update(doc.ref, { 
              verificationStatus: 'approved',
              migratedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            updated += 1;
            updatedUserIds.push(doc.id);
          }
        });
        
        if (updated > 0) {
          await batch.commit();
          console.log(`✓ Migration completed: updated ${updated} user(s)`);
        } else {
          console.log('ℹ Migration completed: no users needed updating');
        }

        // Log successful migration
        await db.collection('approval_logs').add({
          verificationId: 'migration_batch',
          status: 'success',
          usersUpdated: updated,
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
          ipAddress: req.ip || 'unknown',
        });

        res.status(200).send(`
<html>
  <head><title>Migration Complete</title></head>
  <body style="font-family: Arial, sans-serif; padding: 20px;">
    <h2>✓ Migration Completed Successfully</h2>
    <p><strong>Users Updated:</strong> ${updated}</p>
    <p>All existing users have been marked as approved and can now access the dashboard.</p>
  </body>
</html>
        `);
      } catch (err) {
        console.error('✗ migrateApproveMissingVerification error:', err);
        try {
          await db.collection('approval_logs').add({
            verificationId: 'migration_error',
            status: 'error',
            errorMessage: (err instanceof Error ? err.message : String(err)).substring(0, 500),
            errorAt: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: req.ip || 'unknown',
          });
        } catch (logErr) {
          console.error('Failed to log migration error:', logErr);
        }
        res.status(500).send('Internal error: ' + (err instanceof Error ? err.message : 'unknown'));
      }
    });

