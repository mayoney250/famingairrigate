# Manual Stop Irrigation Feature

## Overview
The manual stop irrigation feature allows farmers to immediately stop an ongoing irrigation session from the mobile app. This is useful for emergency situations, weather changes, or when the farmer needs to manually intervene.

## Implementation Details

### 1. Data Model Updates
**File:** `lib/models/irrigation_schedule_model.dart`

Added new fields to track irrigation status:
- `status` (String): Tracks the current state - 'scheduled', 'running', 'completed', 'stopped'
- `stoppedAt` (DateTime?): Timestamp when irrigation was stopped
- `stoppedBy` (String?): How it was stopped - 'manual' or 'automatic'

### 2. Service Updates
**File:** `lib/services/irrigation_service.dart`

Added new method:
```dart
Future<bool> stopIrrigationManually(String scheduleId)
```

This method:
- Updates the irrigation schedule status to 'stopped'
- Sets `isActive` to false
- Records the stop timestamp
- Marks it as manually stopped
- Logs the action for tracking

### 3. UI Updates
**File:** `lib/screens/irrigation/irrigation_list_screen.dart`

Enhanced the irrigation list screen with:

#### Status Badges
Color-coded status indicators:
- **Running** (Green): Irrigation is currently active
- **Scheduled** (Orange): Irrigation is scheduled for future
- **Stopped** (Red/Warning): Irrigation was manually stopped
- **Completed** (Gray): Irrigation finished successfully

#### Stop Button
- Appears only on schedules with status = 'running'
- Prominent red/warning color for visibility
- Confirmation dialog before stopping
- Loading indicator during the operation
- Success/error feedback messages

#### Schedule Details Dialog
Updated to show:
- Current status
- Stop timestamp (if stopped)
- Stop method (manual/automatic)
- Stop button for running irrigation

### 4. Firestore Integration

#### Collection: `irrigationSchedules`
Updated fields:
```
{
  id: string,
  userId: string,
  name: string,
  zoneId: string,
  zoneName: string,
  startTime: timestamp,
  durationMinutes: number,
  repeatDays: array,
  isActive: boolean,
  status: string,  // NEW
  createdAt: timestamp,
  lastRun: timestamp,
  nextRun: timestamp,
  stoppedAt: timestamp,  // NEW
  stoppedBy: string,  // NEW
  updatedAt: timestamp
}
```

#### Firestore Indexes
Added composite index for efficient queries:
- userId (ASCENDING)
- status (ASCENDING)
- startTime (ASCENDING)

This index enables fast queries like:
- Get all running irrigation for a user
- Get all stopped irrigation in chronological order
- Filter schedules by status

## How to Use

### For Farmers (End Users)

1. **View Active Irrigation**
   - Open the Irrigation screen from the bottom navigation
   - Running irrigation schedules show a green "RUNNING" badge
   - The stop button is visible at the bottom of running schedule cards

2. **Stop Irrigation**
   - Tap the "Stop Irrigation" button (red button with stop icon)
   - Confirm the action in the dialog
   - Wait for the success message
   - The schedule status updates to "STOPPED" with a warning badge

3. **View Stop Details**
   - Tap on a stopped schedule card to view details
   - See when it was stopped ("Stopped At" timestamp)
   - See how it was stopped ("Stopped By: manual")

### For Developers

#### Starting Manual Irrigation (sets status to 'running')
```dart
final success = await irrigationService.startIrrigationManually(
  userId: userId,
  farmId: farmId,
  fieldId: fieldId,
  fieldName: fieldName,
  durationMinutes: 30,
);
```

#### Stopping Manual Irrigation
```dart
final success = await irrigationService.stopIrrigationManually(scheduleId);
```

#### Querying by Status
```dart
// Get all running irrigation
FirebaseFirestore.instance
  .collection('irrigationSchedules')
  .where('userId', isEqualTo: userId)
  .where('status', isEqualTo: 'running')
  .get();

// Get all stopped irrigation
FirebaseFirestore.instance
  .collection('irrigationSchedules')
  .where('userId', isEqualTo: userId)
  .where('status', isEqualTo: 'stopped')
  .orderBy('stoppedAt', descending: true)
  .get();
```

## Testing

### Manual Testing Steps

1. **Start Irrigation**
   ```
   - Login to the app
   - Navigate to Dashboard
   - Tap "Start Manual Irrigation" (if available)
   - Or create a test schedule with status = 'running'
   ```

2. **View Running Irrigation**
   ```
   - Navigate to Irrigation screen
   - Verify the schedule shows "RUNNING" badge (green)
   - Verify the stop button is visible
   ```

3. **Stop Irrigation**
   ```
   - Tap "Stop Irrigation" button
   - Verify confirmation dialog appears
   - Tap "Stop" to confirm
   - Verify loading indicator appears
   - Verify success message appears
   - Verify status changes to "STOPPED" (orange/warning)
   ```

4. **View Stop Details**
   ```
   - Tap on the stopped schedule
   - Verify "Stopped At" timestamp is shown
   - Verify "Stopped By" shows "manual"
   - Verify "Stop" button is no longer visible
   ```

### Test Data Creation
To test this feature, create a test document in Firestore:

```javascript
// Firestore Console -> irrigationSchedules collection
{
  userId: "YOUR_USER_ID",
  name: "Test Irrigation",
  zoneId: "field_123",
  zoneName: "Test Field",
  startTime: firebase.firestore.Timestamp.now(),
  durationMinutes: 30,
  repeatDays: [],
  isActive: true,
  status: "running",  // Set to running for testing
  createdAt: firebase.firestore.Timestamp.now(),
  lastRun: null,
  nextRun: null,
  stoppedAt: null,
  stoppedBy: null
}
```

## Security Considerations

1. **User Authentication**
   - Only authenticated users can stop irrigation
   - Users can only stop their own irrigation schedules

2. **Authorization**
   - The service checks userId matches the current user
   - Firestore rules enforce user-level access control

3. **Audit Trail**
   - All stop actions are logged with timestamps
   - The system tracks whether stops were manual or automatic

## Future Enhancements

1. **Automatic Stop**
   - Implement automatic stop when duration expires
   - Set `stoppedBy: 'automatic'`

2. **Emergency Stop**
   - Add emergency stop with reasons
   - Track emergency stop reasons

3. **Stop Notifications**
   - Send push notification when irrigation stops
   - SMS alerts for critical stops

4. **Water Usage Tracking**
   - Calculate actual water used before stop
   - Compare planned vs actual usage

5. **Resume Functionality**
   - Allow resuming stopped irrigation
   - Track pause/resume cycles

6. **Cooperative Management**
   - Allow cooperative managers to stop member irrigation
   - Track who stopped which schedules

## Troubleshooting

### Stop Button Not Showing
- Check schedule status is 'running'
- Verify the schedule is active (isActive = true)
- Check Firestore document has correct fields

### Stop Not Working
- Check internet connection
- Verify Firestore rules allow updates
- Check console logs for error messages
- Verify schedule ID is correct

### Status Not Updating
- Check Firestore listener is active
- Verify StreamBuilder is rebuilding
- Check for Firestore permission errors

## Database Migration

If you have existing irrigation schedules without the new fields:

```javascript
// Run this in Firestore console to update existing documents
db.collection('irrigationSchedules').get().then(snapshot => {
  snapshot.forEach(doc => {
    doc.ref.update({
      status: doc.data().isActive ? 'scheduled' : 'completed',
      stoppedAt: null,
      stoppedBy: null
    });
  });
});
```

## Related Files
- `lib/models/irrigation_schedule_model.dart` - Data model
- `lib/services/irrigation_service.dart` - Business logic
- `lib/screens/irrigation/irrigation_list_screen.dart` - UI
- `firestore.indexes.json` - Database indexes
- `firestore.rules` - Security rules

## Support
For issues or questions about this feature, contact the development team or create an issue in the project repository.

