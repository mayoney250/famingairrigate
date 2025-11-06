# Automated Irrigation Cycle Logic - Complete Implementation

## Overview
This document describes the complete automated irrigation cycle logic implemented across the Dashboard and Irrigation screens in the Flutter app. The system supports both **Scheduled** and **Manual** irrigation cycles with real-time synchronization between UI screens and Firestore backend.

## Architecture

### Core Components

1. **Model**: `IrrigationScheduleModel` (`lib/models/irrigation_schedule_model.dart`)
   - Fields: `id`, `userId`, `name`, `zoneId`, `zoneName`, `startTime`, `durationMinutes`, `repeatDays`, `isActive`, `status`, `createdAt`, `lastRun`, `nextRun`, `isManual`, `stoppedAt`, `stoppedBy`
   - Status values: `'scheduled'`, `'running'`, `'completed'`, `'stopped'`

2. **Service**: `IrrigationStatusService` (`lib/services/irrigation_status_service.dart`)
   - `startDueSchedules()`: Auto-starts scheduled cycles when their time arrives
   - `markDueIrrigationsCompleted()`: Auto-completes running cycles when duration expires
   - `startScheduledNow()`: Manually start a scheduled cycle
   - `stopIrrigationManually()`: Stop a running cycle
   - `startIrrigationManually()`: Create and start a manual irrigation

3. **Provider**: `DashboardProvider` (`lib/providers/dashboard_provider.dart`)
   - Manages dashboard state and real-time sync
   - Runs a 60-second timer that calls status update methods
   - Streams irrigation schedules from Firestore

4. **Screens**:
   - `IrrigationListScreen` (`lib/screens/irrigation/irrigation_list_screen.dart`)
   - `DashboardScreen` (`lib/screens/dashboard/dashboard_screen.dart`)

## Irrigation Cycle Flows

### 1. Scheduled Irrigation Flow

#### Creation
1. User creates a schedule in the Irrigation screen
2. Initial status: `"scheduled"`
3. `nextRun` calculated based on `startTime` and `repeatDays`
4. Appears in:
   - Dashboard → "Next Schedule Cycle" section
   - Irrigation Tab → with "SCHEDULED" badge

#### Auto-Start (When Time Arrives)
1. Background timer checks every 60 seconds via `startDueSchedules()`
2. Queries all schedules with:
   - `status == 'scheduled'`
   - `isActive == true`
   - `nextRun` or `startTime` <= current time
3. For each due schedule:
   - Update `status` to `'running'`
   - Set `startedAt` to current timestamp
   - Create notification alert: "Irrigation started for [Zone]"
4. Real-time update in both screens (via StreamBuilder)

#### Manual Start (User Triggers "Start Now")
1. User clicks "Start Now" button on a scheduled cycle
2. Calls `startScheduledNow(scheduleId)`
3. Immediately updates status to `'running'`
4. Same flow as auto-start

#### Auto-Complete (When Duration Ends)
1. Background timer checks every 60 seconds via `markDueIrrigationsCompleted()`
2. Queries all schedules with `status == 'running'`
3. For each running schedule:
   - Calculate end time: `startedAt + durationMinutes`
   - If current time >= end time:
     - Update `status` to `'completed'`
     - Set `completedAt` timestamp
     - Create notification alert: "Irrigation completed for [Zone]"
     - Update `lastRun` timestamp
     - Calculate `nextRun` for recurring schedules
4. Completed cycles removed from "Scheduled Cycles" section
5. User receives notification

### 2. Manual Irrigation Flow

#### Start
1. User selects field and duration from Dashboard
2. Calls `startIrrigationManually()`
3. Creates new schedule document with:
   - `status`: `'running'`
   - `isManual`: `true`
   - `name`: `"Manual Irrigation - [FieldName]"`
   - `startTime`: current timestamp
   - `repeatDays`: `[]` (empty - no recurrence)
4. Immediately appears as "RUNNING" in both screens
5. Does NOT appear under "Scheduled Cycles" (filtered by isManual)

#### Stop (Manual or Auto)
1. **Manual Stop**: User clicks "Stop Irrigation" button
   - Calls `stopIrrigationManually()`
   - Updates `status` to `'stopped'`
   - Sets `stoppedAt` and `stoppedBy: 'manual'`

2. **Auto-Complete**: Same as scheduled cycles
   - After duration expires, status changes to `'completed'`

## Real-Time Synchronization

### Stream-Based Updates
```dart
// In DashboardProvider
Stream<List<IrrigationScheduleModel>> = _irrigationService.getUserSchedules(userId)

// In IrrigationListScreen
StreamBuilder<List<IrrigationScheduleModel>>(
  stream: _irrigationService.getUserSchedules(userId),
  ...
)
```

### Background Timers
1. **Dashboard Provider** (`dashboard_provider.dart`):
   ```dart
   Timer.periodic(Duration(seconds: 60), (_) {
     await _statusService.startDueSchedules();
     await _statusService.markDueIrrigationsCompleted();
   });
   ```

2. **Irrigation List Screen** (`irrigation_list_screen.dart`):
   ```dart
   Timer.periodic(Duration(seconds: 60), (_) {
     _statusService.startDueSchedules();
     _statusService.markDueIrrigationsCompleted();
     if (mounted) setState(() {});
   });
   ```

### Status Update Rules

| Current Status | Action | New Status | UI Updates |
|---------------|--------|-----------|------------|
| scheduled | Time arrives (auto) | running | Badge changes, "Start Now" → "Stop" button |
| scheduled | User clicks "Start Now" | running | Same as above |
| scheduled | User edits time | scheduled | nextRun recalculated |
| running | Duration expires (auto) | completed | Removed from active lists, notification sent |
| running | User clicks "Stop" | stopped | Badge changes, removed from active lists |

## UI Features

### Irrigation Screen

#### Status Badges
```dart
switch (schedule.status) {
  case 'running':  // Green badge with play icon
  case 'stopped':  // Warning badge with stop icon
  case 'completed': // Gray badge with checkmark
  case 'scheduled': // Orange badge with clock icon
}
```

#### Action Buttons

1. **"Start Now" Button**
   - Visible when: `status == 'scheduled' && !isManual`
   - Color: Green (Success)
   - Action: Immediately starts the irrigation

2. **"Stop Irrigation" Button**
   - Visible when: `status == 'running'`
   - Color: Warning (Orange/Red)
   - Action: Stops the running irrigation

3. **"Update" Button**
   - Visible when: `status != 'running'`
   - Allows editing schedule details
   - Resets status to 'scheduled' if time changed

4. **"Delete" Button**
   - Disabled when: `status == 'running'`
   - Requires confirmation dialog

### Dashboard Screen

#### Next Schedule Cycle Card
- Shows the next upcoming scheduled irrigation
- Displays time until start
- "Start Now" button for manual trigger
- Disappears when no scheduled cycles exist

#### Weekly Performance
- Water usage tracking
- Based on completed irrigation cycles
- Updates in real-time as cycles complete

## Notifications

### Alert Types

1. **Irrigation Started**
   - Triggered: When scheduled cycle auto-starts
   - Message: "Irrigation started for [Zone]."
   - Severity: info
   - Type: VALVE

2. **Irrigation Completed**
   - Triggered: When cycle duration expires
   - Message: "Irrigation completed for [Zone]."
   - Severity: info
   - Type: VALVE

### Notification Storage
- **Remote**: Firestore `alerts` collection
- **Local**: SQLite database via `AlertLocalService`
- Both created for offline support

## Technical Implementation

### Firestore Collection Structure

```javascript
irrigationSchedules: {
  [scheduleId]: {
    userId: string,
    name: string,
    zoneId: string,
    zoneName: string,
    startTime: Timestamp,
    durationMinutes: number,
    repeatDays: number[], // [1-7], empty for one-time
    isActive: boolean,
    status: 'scheduled' | 'running' | 'completed' | 'stopped',
    createdAt: Timestamp,
    updatedAt: Timestamp,
    startedAt: Timestamp | null,
    completedAt: Timestamp | null,
    stoppedAt: Timestamp | null,
    stoppedBy: 'manual' | 'automatic' | null,
    lastRun: Timestamp | null,
    nextRun: Timestamp | null,
    isManual: boolean
  }
}
```

### Timestamp Handling
```dart
DateTime parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? DateTime.now();
}
```

### Next Run Calculation
```dart
// For recurring schedules
if (schedule.repeatDays.isNotEmpty) {
  for (int i = 0; i < 7; i++) {
    final candidateDay = selectedStart.add(Duration(days: i));
    if (schedule.repeatDays.contains(candidateDay.weekday)) {
      nextRunTime = DateTime(
        candidateDay.year,
        candidateDay.month,
        candidateDay.day,
        selectedStart.hour,
        selectedStart.minute,
      );
      if (nextRunTime.isAfter(now)) break;
    }
  }
}
```

## Error Handling

### Service Layer
```dart
try {
  await _firestore.collection('irrigationSchedules').doc(id).update({...});
  log('Schedule updated successfully');
  return true;
} catch (e) {
  log('Error updating schedule: $e');
  return false;
}
```

### UI Layer
```dart
final success = await _statusService.startScheduledNow(schedule.id);

if (success) {
  Get.snackbar(
    'Success',
    'Irrigation started successfully',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: FamingaBrandColors.statusSuccess,
  );
} else {
  Get.snackbar(
    'Error',
    'Failed to start irrigation. Please try again.',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: FamingaBrandColors.statusWarning,
  );
}
```

## Testing Guidelines

### Manual Testing Checklist

1. **Create Scheduled Irrigation**
   - [ ] Creates with status="scheduled"
   - [ ] Appears in both screens
   - [ ] Shows correct time and duration

2. **Auto-Start (Scheduled)**
   - [ ] Status changes to "running" when time arrives
   - [ ] Notification sent
   - [ ] UI updates in both screens without refresh

3. **Manual Start**
   - [ ] "Start Now" button visible for scheduled cycles
   - [ ] Status immediately changes to "running"
   - [ ] Button changes to "Stop"

4. **Auto-Complete**
   - [ ] Status changes to "completed" after duration
   - [ ] Notification sent
   - [ ] Removed from active sections
   - [ ] nextRun calculated for recurring schedules

5. **Manual Stop**
   - [ ] "Stop" button works during running state
   - [ ] Status changes to "stopped"
   - [ ] Timestamps recorded correctly

6. **Manual Irrigation**
   - [ ] Starts immediately
   - [ ] Does not appear in "Scheduled Cycles"
   - [ ] Auto-completes after duration
   - [ ] isManual=true in database

7. **Edit Schedule**
   - [ ] Updates time correctly
   - [ ] Recalculates nextRun
   - [ ] Resets status to "scheduled" if needed
   - [ ] Cannot edit running cycles

8. **Real-Time Sync**
   - [ ] Changes visible immediately across screens
   - [ ] StreamBuilder updates automatically
   - [ ] No manual refresh needed

## Performance Considerations

1. **Timer Frequency**: 60 seconds is optimal balance between responsiveness and battery/CPU usage

2. **Firestore Queries**: Indexed on:
   - `userId` + `status`
   - `isActive` + `status`

3. **Stream Management**: Streams properly disposed in widget lifecycle

4. **Local Caching**: AlertLocalService provides offline fallback

## Future Enhancements

1. **Push Notifications**: Integrate FCM for remote notifications
2. **Predictive Scheduling**: ML-based optimal irrigation times
3. **Conflict Detection**: Prevent overlapping irrigations
4. **Historical Analytics**: Detailed cycle history and reports
5. **Zone Prioritization**: Smart queue for limited water resources

## Troubleshooting

### Issue: Cycles Not Auto-Starting
- **Check**: Timer is running in both screens
- **Check**: Firestore indexes created
- **Check**: `nextRun` and `startTime` values correct
- **Check**: `isActive` is true

### Issue: Status Not Updating
- **Check**: StreamBuilder listening to correct stream
- **Check**: Network connectivity
- **Check**: Firestore rules allow updates

### Issue: Notifications Not Appearing
- **Check**: AlertService and AlertLocalService working
- **Check**: Notification permissions granted
- **Check**: Alert creation code not throwing errors

## Conclusion

This implementation provides a robust, production-ready automated irrigation cycle system with:
✅ Real-time synchronization across screens
✅ Automated start/stop based on schedule
✅ Manual override capabilities
✅ Comprehensive notification system
✅ Clean separation of concerns
✅ Error handling and offline support
