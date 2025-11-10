const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

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

            const threshold = sensor.lowThreshold || 30;

            if (moistureLevel < threshold) {
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
                  title: '💧 Irrigation Needed',
                  body: `Soil moisture is low (${moistureLevel.toFixed(1)}%) in ${field.name}. Time to irrigate!`,
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
                ? '🚨 Critical: Water Level Alert' 
                : '⚠️ Low Water Level';
              
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
              title: '⏰ Irrigation Reminder',
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

      switch (newData.status) {
        case 'running':
          title = '💧 Irrigation Started';
          body = `Irrigation has started for ${field?.name || 'your field'}.`;
          break;
        case 'completed':
          title = '✅ Irrigation Completed';
          body = `Irrigation completed for ${field?.name || 'your field'}. Total water used: ${newData.waterUsed || 0}L`;
          break;
        case 'stopped':
          title = '⏸️ Irrigation Stopped';
          body = `Irrigation was manually stopped for ${field?.name || 'your field'}.`;
          break;
        case 'failed':
          title = '❌ Irrigation Failed';
          body = `Irrigation failed for ${field?.name || 'your field'}. Please check the system.`;
          break;
      }

      if (title && body) {
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
      }
    }

    return null;
  });
