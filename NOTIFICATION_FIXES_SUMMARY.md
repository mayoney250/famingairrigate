# Push Notification Fixes Summary

## Issues Fixed

### 1. ✅ Notifications Appearing Before Login
**Problem**: Users were receiving notifications for old events (irrigation cycles, alerts, sensor readings) that occurred before they logged in.

**Root Cause**: The notification listeners were triggering for all documents in the initial snapshot, including historical data.

**Solution**:
- Added universal `_attachCutoff` timestamp that's set when user logs in
- All listeners now skip events with timestamps older than the cutoff (minus 3 seconds for clock skew)
- Applied to:
  - Irrigation cycles (handles both Timestamp and String date fields)
  - Sensor readings
  - Alerts
  - AI recommendations

**Files Changed**:
- `lib/services/notification_service.dart`
  - Replaced `_alertsListenStart` with `_attachCutoff`
  - Added timestamp checks in all listener handlers

### 2. ✅ Soil Moisture Notifications Not Working
**Problem**: Soil dry/moisture notifications were not triggering at all.

**Root Causes**:
1. Sensor readings listener was using `collectionGroup('sensor_readings')` instead of `collection('sensor_readings')`
2. Old sensor readings from before login were being processed
3. Sensor type matching was case-sensitive and strict

**Solutions**:
- Changed from `collectionGroup` to `collection` to match the actual Firestore schema
- Added timestamp cutoff to skip old sensor readings
- Broadened sensor type matching to handle variations:
  - `soil_moisture`, `moisture`, `soilmoisture` → all trigger moisture checks
  - `water_level`, `waterlevel` → all trigger water level checks

**Files Changed**:
- `lib/services/notification_service.dart`
  - `_setupSensorReadingsListener()`: Changed to use `collection` instead of `collectionGroup`
  - `_handleNewSensorReading()`: Added normalized type matching

### 3. ✅ Added Appropriate Icons for Different Severities
**Problem**: All notifications used the same generic app icon, making it hard to distinguish critical alerts from informational ones.

**Solution**:
- Created 4 white vector drawable icons:
  - `ic_notif_critical.xml` - Red triangle warning (for critical alerts)
  - `ic_notif_warning.xml` - Orange circle warning (for high/medium severity)
  - `ic_notif_info.xml` - Blue info circle (for informational)
  - `ic_notif_reminder.xml` - Bell icon (for schedules/reminders)

- Added icon selection logic based on:
  - **Severity** (critical, high, medium, low, info)
  - **Notification Type** (irrigation failed, water low, sensor offline, etc.)

- Added color coding:
  - **Red** (#D32F2F): Critical/failures
  - **Orange** (#FF9800): High/medium warnings
  - **Blue** (#2196F3): Info/reminders
  - **Green** (#4CAF50): Success/completion

**Files Created**:
- `android/app/src/main/res/drawable/ic_notif_critical.xml`
- `android/app/src/main/res/drawable/ic_notif_warning.xml`
- `android/app/src/main/res/drawable/ic_notif_info.xml`
- `android/app/src/main/res/drawable/ic_notif_reminder.xml`

**Files Changed**:
- `lib/services/notification_service.dart`
  - Added `_androidIconFor()` method
  - Added `_colorFor()` method
  - Updated `_showNotification()` to accept severity parameter
  - Updated all notification calls to pass severity

- `lib/services/fcm_service.dart`
  - Added `_getNotificationIcon()` method
  - Updated `_getNotificationColor()` to accept severity
  - Updated `_showLocalNotification()` to use severity-based icons
  - Updated background message handler with icon/color logic
  - Increased channel importance from `Importance.high` to `Importance.max`

## Icon Mapping

| Severity/Type | Icon | Color | Use Case |
|---------------|------|-------|----------|
| `critical` | ic_notif_critical | Red | Irrigation failures, critical water levels |
| `high` | ic_notif_warning | Orange | Low water, sensor offline, irrigation needed |
| `medium` | ic_notif_warning | Orange | Moderate alerts |
| Irrigation Needed | ic_notif_warning | Orange | Soil moisture low |
| Schedule/Rain | ic_notif_reminder | Blue | Upcoming irrigation, rain forecast |
| Info/Completion | ic_notif_info | Green/Blue | General info, completed tasks |

## Testing Checklist

- [ ] Test notifications DO NOT appear for old irrigation cycles after fresh login
- [ ] Test notifications DO NOT appear for old alerts after fresh login
- [ ] Test soil moisture notifications trigger when moisture drops below threshold
- [ ] Test water level notifications trigger correctly
- [ ] Test different notification icons appear for:
  - [ ] Critical alerts (red triangle)
  - [ ] High/medium alerts (orange circle warning)
  - [ ] Info notifications (blue circle)
  - [ ] Schedule reminders (bell icon)
- [ ] Test notification colors match severity
- [ ] Test FCM push notifications from backend use correct icons
- [ ] Test local notifications use correct icons
- [ ] Verify notifications work on both foreground and background

## Breaking Changes

None - all changes are backward compatible.

## Migration Notes

- Old `_alertsListenStart` variable replaced with `_attachCutoff` (more descriptive name)
- Sensor type matching is now case-insensitive and more flexible
- Channel importance increased from `high` to `max` for better visibility

## Performance Impact

Minimal - added timestamp comparisons are O(1) operations that prevent unnecessary processing of old events.
