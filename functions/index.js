const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Configure nodemailer with Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.ADMIN_EMAIL_USER || 'your-email@gmail.com',
    pass: process.env.ADMIN_EMAIL_PASSWORD || 'your-app-password',
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
      // Determine registration type
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
      <li><strong>Cooperative ID:</strong> ${payload.coopGovId}</li>
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
