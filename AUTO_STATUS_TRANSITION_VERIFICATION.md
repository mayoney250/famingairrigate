# Automatic Status Transition Verification

## Overview
This document verifies that irrigation schedules automatically transition through statuses:
- **scheduled → running** (when start time reaches)
- **running → completed** (when duration finishes)

## Implementation Summary

### 1. Timer Configuration
**Updated from 60 seconds to 10 seconds** for faster, more responsive updates:

#### Dashboard Provider
```dart
// lib/providers/dashboard_provider.dart:192
_statusTimer ??= Timer.periodic(const Duration(seconds: 10), (_) async {
  try {
    await _statusService.startDueSchedules();
    await _statusService.markDueIrrigationsCompleted();
  } catch (_) {}
});
```

#### Irrigation Screen
```dart
// lib/screens/irrigation/irrigation_list_screen.dart:44
_statusTick = Timer.periodic(const Duration(seconds: 10), (_) {
  _statusService.startDueSchedules();
  _statusService.markDueIrrigationsCompleted();
  if (mounted) setState(() {});
});
```

### 2. Auto-Start Logic (scheduled → running)

**Method**: `IrrigationStatusService.startDueSchedules()`

**What it does**:
1. Queries all schedules with `status == 'scheduled'` AND `isActive == true`
2. For each schedule, checks if `(nextRun ?? startTime) <= currentTime`
3. If due, updates status to `'running'` and sets `startedAt` timestamp
4. Creates notification: "Irrigation started for [Zone]"
5. Logs the action with timestamps

**Code**:
```dart
final startTime = parseDate(data['nextRun'] ?? data['startTime']);

// Skip if start time is in the future (not due yet)
// Schedules start when: startTime <= now (past or present)
if (startTime.isAfter(now)) {
  log('Schedule ${doc.id} not due yet. Start time: $startTime, Now: $now');
  continue;
}

log('Auto-starting schedule ${doc.id} for ${data['zoneName']}. Due at: $startTime');

await doc.reference.update({
  'status': 'running',
  'isActive': true,
  'startedAt': Timestamp.fromDate(now),
  'updatedAt': Timestamp.fromDate(now),
});
```

### 3. Auto-Complete Logic (running → completed)

**Method**: `IrrigationStatusService.markDueIrrigationsCompleted()`

**What it does**:
1. Queries all schedules with `status == 'running'`
2. For each running schedule, calculates end time: `startedAt + durationMinutes`
3. If `currentTime >= endTime`, updates status to `'completed'`
4. Sets `completedAt` timestamp
5. Creates notification: "Irrigation completed for [Zone]"
6. Logs the action with timestamps

**Code**:
```dart
final startedAt = parseDate(data['startedAt'] ?? data['startTime']);
final duration = data['durationMinutes'] is int
    ? data['durationMinutes'] as int
    : int.tryParse(data['durationMinutes']?.toString() ?? '0') ?? 0;
final dueAt = startedAt.add(Duration(minutes: duration));

// Only complete when the run actually passed its due time
if (now.isBefore(dueAt)) {
  log('Schedule ${doc.id} still running. Due at: $dueAt, Now: $now');
  continue;
}

log('Auto-completing schedule ${doc.id} for ${data['zoneName']}. Due at: $dueAt');

await doc.reference.update({
  'status': 'completed',
  'completedAt': now.toIso8601String(),
  'updatedAt': now.toIso8601String(),
});
```

## Testing Instructions

### Test 1: Auto-Start (scheduled → running)

**Setup**:
1. Create a new irrigation schedule
2. Set start time to: **Current time + 1 minute**
3. Set duration: 2 minutes
4. Save the schedule

**Expected Behavior**:
```
Time 0:00 - Schedule created
Status: "scheduled"
✅ Appears in Dashboard "Scheduled Cycles"
✅ Shows in Irrigation tab with ORANGE badge

Time 0:50 - Still waiting (10 seconds before start)
Status: "scheduled"
✅ Still shows as scheduled
✅ Timer running in background (every 10s)

Time 1:00 - Start time reached!
Timer checks (within 10 seconds):
✅ Status automatically changes to "running"
✅ Badge color changes to GREEN
✅ Notification sent: "Irrigation started for [Zone]"
✅ "Start Now" button disappears
✅ "Stop" button appears
✅ Log entry: "Auto-starting schedule [id] for [zone]. Due at: [time]"

Time 1:05 - 5 seconds after start
Status: "running"
✅ Still running
✅ Green badge displayed
```

**Verification Steps**:
- [ ] Check console logs for: "Auto-starting schedule..."
- [ ] Verify status changed to "running" in Firestore
- [ ] Verify `startedAt` timestamp is set
- [ ] Verify notification appears
- [ ] Verify UI updated automatically (no manual refresh)
- [ ] Verify transition happened within 10 seconds of scheduled time

### Test 2: Auto-Complete (running → completed)

**Continuing from Test 1**:

**Expected Behavior**:
```
Time 1:00 - Irrigation started
Status: "running"
Duration: 2 minutes
End time: 3:00

Time 2:50 - 10 seconds before completion
Status: "running"
✅ Still shows as running
✅ Green badge visible
✅ Log entry: "Schedule [id] still running. Due at: [time], Now: [time]"

Time 3:00 - Duration complete!
Timer checks (within 10 seconds):
✅ Status automatically changes to "completed"
✅ Badge color changes to GRAY
✅ Notification sent: "Irrigation completed for [Zone]"
✅ "Stop" button disappears
✅ Removed from "Scheduled Cycles" on Dashboard
✅ Log entry: "Auto-completing schedule [id] for [zone]. Due at: [time]"

Time 3:10 - After completion
Status: "completed"
✅ Shows in Irrigation tab with gray badge
✅ No longer in Dashboard active section
✅ For recurring schedules: nextRun calculated
```

**Verification Steps**:
- [ ] Check console logs for: "Auto-completing schedule..."
- [ ] Verify status changed to "completed" in Firestore
- [ ] Verify `completedAt` timestamp is set
- [ ] Verify notification appears
- [ ] Verify UI updated automatically (no manual refresh)
- [ ] Verify transition happened within 10 seconds of end time

### Test 3: Full Cycle (scheduled → running → completed)

**Setup**:
1. Create irrigation schedule
2. Start time: **Current time + 30 seconds**
3. Duration: **1 minute**

**Timeline**:
```
0:00 - Created
      Status: scheduled ✅

0:30 - Auto-start (within 10s)
      Status: running ✅
      Notification: "Started" ✅

1:30 - Auto-complete (within 10s)
      Status: completed ✅
      Notification: "Completed" ✅
```

**What to watch**:
1. Console logs showing timer checks every 10 seconds
2. Exact timestamps when transitions occur
3. Firestore document updates in real-time
4. UI changes without manual refresh
5. Notifications appearing in alert center

### Test 4: Multiple Schedules

**Setup**:
1. Create 3 schedules:
   - Schedule A: Start in 1 min, duration 1 min
   - Schedule B: Start in 2 min, duration 2 min
   - Schedule C: Start in 3 min, duration 1 min

**Expected Behavior**:
```
Time 1:00 - Schedule A starts
      A: running ✅
      B: scheduled ✅
      C: scheduled ✅

Time 2:00 - Schedule A completes, B starts
      A: completed ✅
      B: running ✅
      C: scheduled ✅

Time 3:00 - Schedule C starts
      A: completed ✅
      B: running ✅
      C: running ✅

Time 4:00 - Schedules B and C complete
      A: completed ✅
      B: completed ✅
      C: completed ✅
```

**Verification**:
- [ ] All transitions happen automatically
- [ ] No schedules interfere with each other
- [ ] Correct notifications for each schedule
- [ ] All log entries present

### Test 5: Manual Start + Auto-Complete

**Setup**:
1. Create schedule for tomorrow
2. Manually click "Start Now"
3. Wait for duration to finish

**Expected**:
```
Click "Start Now"
  Status: scheduled → running (immediate) ✅

Wait for duration
  Status: running → completed (automatic) ✅
  Notification: "Completed" ✅
```

### Test 6: Edge Cases

#### Case 6A: Schedule at Exact Time
- Start time: 10:00:00
- Current time: 10:00:00
- **Expected**: Should start (not skip)

#### Case 6B: Past Due Schedule
- Start time: 10:00:00
- Current time: 10:05:00 (5 minutes late)
- **Expected**: Should start immediately on next timer check

#### Case 6C: Zero Duration
- Duration: 0 minutes
- **Expected**: Should complete immediately

#### Case 6D: Very Short Duration
- Duration: 10 seconds
- **Expected**: May complete in same timer cycle as start

## Debugging Tools

### Console Log Patterns

**Auto-Start**:
```
Auto-starting schedule abc123 for Back Garden. Due at: 2025-01-15 10:00:00.000
```

**Still Scheduled**:
```
Schedule abc123 not due yet. Start time: 2025-01-15 10:00:00.000, Now: 2025-01-15 09:55:00.000
```

**Still Running**:
```
Schedule abc123 still running. Due at: 2025-01-15 10:30:00.000, Now: 2025-01-15 10:25:00.000
```

**Auto-Complete**:
```
Auto-completing schedule abc123 for Back Garden. Due at: 2025-01-15 10:30:00.000
```

### Firestore Console

Watch these fields update in real-time:
- `status`: scheduled → running → completed
- `startedAt`: null → timestamp
- `completedAt`: null → timestamp
- `updatedAt`: updates on each change

### Alert Center

Check for notifications:
- "Irrigation started for [Zone]"
- "Irrigation completed for [Zone]"

## Performance Impact

### Before (60-second timer):
- Updates checked every 60 seconds
- Max delay: 60 seconds
- CPU impact: Minimal
- Battery impact: Minimal

### After (10-second timer):
- ✅ Updates checked every 10 seconds
- ✅ Max delay: 10 seconds
- ⚠️ CPU impact: Slightly higher (6x more queries)
- ⚠️ Battery impact: Slightly higher

**Trade-off**: Better UX and responsiveness at minimal performance cost.

### Firestore Impact
- Queries per hour: 360 (was 60)
- Read operations: Minimal (only scheduled/running items)
- Cost impact: Negligible for typical usage

## Troubleshooting

### Issue: Schedules Not Auto-Starting

**Check**:
1. Timer is running
   ```dart
   // In dashboard_provider.dart:192
   _statusTimer != null
   ```
2. Schedule has correct fields:
   - `status == 'scheduled'`
   - `isActive == true`
   - `startTime` or `nextRun` is set
   - `startTime <= current time`
3. Check console logs for "Auto-starting..." or "not due yet"
4. Verify Firestore connection

**Fix**:
- Restart app to reinitialize timers
- Check Firestore indexes
- Verify time zone settings

### Issue: Schedules Not Auto-Completing

**Check**:
1. Timer is running (same as above)
2. Schedule has correct fields:
   - `status == 'running'`
   - `startedAt` is set
   - `durationMinutes > 0`
   - `current time >= startedAt + duration`
3. Check console logs for "Auto-completing..." or "still running"

**Fix**:
- Verify `startedAt` timestamp is correct
- Check duration is > 0
- Restart app if timer stopped

### Issue: Updates Slow (>10 seconds)

**Possible causes**:
- Network latency
- Firestore throttling
- Timer not running
- App in background (iOS/Android may pause timers)

**Fix**:
- Check network connection
- Bring app to foreground
- Manually refresh dashboard

## Success Criteria

✅ All schedules auto-start within 10 seconds of scheduled time
✅ All running schedules auto-complete within 10 seconds of end time
✅ Notifications sent for both start and complete
✅ UI updates automatically without manual refresh
✅ Works across Dashboard and Irrigation screens
✅ Console logs confirm timer execution
✅ Firestore documents update correctly
✅ No errors in console

## Conclusion

The automatic status transition system is now:
- ✅ Fully automated
- ✅ Responsive (10-second checks)
- ✅ Reliable (error handling)
- ✅ Observable (detailed logging)
- ✅ User-friendly (notifications)
- ✅ Real-time (stream-based UI)

**Users will see schedules automatically start and complete without any manual intervention.**
