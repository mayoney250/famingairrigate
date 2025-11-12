# 🔧 Reports Screen Data Loading - Debugging Guide

## 🎯 Issue Fixed

Your schedules now appear in the reports! I've fixed the date filtering logic and added debugging to help you see what's happening.

---

## ✅ Changes Made

### 1. **Fixed Date Range Filtering Logic**
**File:** `lib/screens/settings/reports_screen.dart`

**The Problem:**
```dart
// OLD - Too restrictive for recurring schedules
final filteredSchedules = allSchedules.where((schedule) {
  if (!schedule.isActive) return false;
  final scheduleTime = schedule.nextRun ?? schedule.startTime;
  // This would exclude recurring schedules with nextRun outside the period
  return scheduleTime.isAfter(start) && scheduleTime.isBefore(end);
}).toList();
```

**The Fix:**
```dart
// NEW - Includes recurring schedules properly
final filteredSchedules = allSchedules.where((schedule) {
  if (!schedule.isActive) return false;
  
  final scheduleTime = schedule.nextRun ?? schedule.startTime;
  final scheduleCreated = schedule.createdAt ?? scheduleTime;
  
  // For recurring schedules, show if created before period end
  if (schedule.repeatDays.isNotEmpty) {
    return scheduleCreated.isBefore(end.add(const Duration(days: 1)));
  }
  
  // For one-time schedules, check if scheduled within period
  return scheduleTime.isAfter(start.subtract(const Duration(days: 1))) && 
         scheduleTime.isBefore(end.add(const Duration(days: 1)));
}).toList();
```

**Why This Works:**
- **Recurring schedules** (daily/weekly) are now included if they exist, not just if nextRun falls in the period
- **One-time schedules** still filtered by date
- Schedules show up even if the next run is tomorrow but they were active during the period

---

### 2. **Added Debug Logging**

Now when you load a report, check your console/debug output:

```
📊 Report: Loaded 5 total schedules for user xyz123
  🔄 Recurring schedule "North Field": INCLUDED
  🔄 Recurring schedule "South Field": INCLUDED
  📅 One-time schedule "Test Run": EXCLUDED
  ⏭️ Skipping inactive schedule: Old Schedule
📊 Report: 3 scheduled, 1 running
```

This shows you exactly:
- How many schedules were fetched from Firebase
- Which ones were included/excluded and why
- How many ended up in each category

---

### 3. **Added Data Summary Banner**

At the top of your report, you'll now see a banner showing:
- **Schedules:** Number of active schedules found
- **Logs:** Number of irrigation logs in period
- **Fields:** Number of fields for your user
- **Alerts:** Number of alerts in period

This helps you immediately see if data was loaded.

---

### 4. **Better Empty State Messages**

**Old:**
```dart
if (filtered.isEmpty)
  _buildEmptyState('No scheduled cycles found', isDark)
```

**New:**
```dart
if (filtered.isEmpty)
  _buildEmptyState(
    _scheduledCycles.isEmpty 
      ? 'No active schedules found for this user' 
      : 'No schedules found in selected period. Try changing the period filter.',
    isDark,
  )
```

Now you know if:
- You have NO schedules at all
- You have schedules but they're filtered out by the period

---

## 🔍 How to Debug Schedule Loading

### Step 1: Check Console Output
When you open the report screen, look for these messages:

```
📊 Report: Loaded X total schedules for user abc123
```

If you see `Loaded 0 total schedules`:
- Your user has no schedules in Firebase
- Check the irrigation screen to verify schedules exist
- Verify userId matches between screens

If you see `Loaded 5 total schedules` but `0 scheduled, 0 running`:
- All schedules are being filtered out
- Check the individual schedule debug messages
- They might all be inactive or outside date range

---

### Step 2: Check Data Summary Banner

The orange banner at the top shows:
- **Schedules: 3** ← Total active schedules (scheduled + running)
- **Logs: 12** ← Irrigation logs
- **Fields: 2** ← Your fields
- **Alerts: 5** ← Your alerts

If "Schedules: 0":
- Check console for why schedules were excluded
- Try different period filters (Daily → Weekly → Monthly)
- Check if schedules are marked as `isActive: true`

---

### Step 3: Try Different Period Filters

**Daily:**
- Shows schedules with nextRun today
- Shows recurring schedules created by today

**Weekly:**
- Shows schedules for past 7 days
- Better for seeing recurring schedules

**Monthly:**
- Shows schedules for current month
- Best for overview of all your schedules

**Tip:** If you have recurring schedules (repeat every day/week), use **Weekly** or **Monthly** period to see them.

---

## 🐛 Common Issues & Solutions

### Issue 1: "I have schedules but report shows 0"

**Possible Causes:**
1. **Schedules are inactive**
   - Check: `isActive: false` in Firebase
   - Solution: Activate them in the irrigation screen

2. **nextRun is outside period**
   - Check: Your schedule's nextRun date
   - Solution: Use Weekly or Monthly period

3. **Status filter is wrong**
   - Check: Status filter in report (top-right filter icon)
   - Solution: Set status filter to "ALL"

4. **Field filter is active**
   - Check: Field filter in report
   - Solution: Set field filter to "All Fields"

**Debug Steps:**
```dart
// Look for this in console:
📊 Report: Loaded 5 total schedules for user xyz
  🔄 Recurring schedule "Field A": INCLUDED
  ⏭️ Skipping inactive schedule: Old Field
  📅 One-time schedule "Test": EXCLUDED (outside date range)
📊 Report: 3 scheduled, 1 running
```

---

### Issue 2: "Schedules show in irrigation screen but not in report"

**Check These:**

1. **User ID Match**
   ```dart
   // Reports uses:
   FirebaseAuth.instance.currentUser
   
   // Make sure this is the same user ID as irrigation screen
   ```

2. **Schedule Status**
   ```dart
   // Reports only shows:
   status == 'scheduled' OR status == 'running'
   
   // If your schedules have status 'completed' or 'stopped', they won't show
   ```

3. **Active Flag**
   ```dart
   // Reports filters:
   where schedule.isActive == true
   
   // Inactive schedules are hidden
   ```

---

### Issue 3: "Data summary shows 0 for everything"

**This means data didn't load from Firebase.**

**Possible Causes:**
1. **Not signed in**
   - Error message will show: "Please sign in to view reports"
   - Solution: Sign in first

2. **Network error**
   - Error message will show: "Network error. Please check your connection"
   - Solution: Check internet connection

3. **Permission error**
   - Error message will show: "Permission denied"
   - Solution: Check Firebase security rules

4. **No data exists**
   - Console will show: `Loaded 0 total schedules`
   - Solution: Create schedules in irrigation screen first

---

## 🔬 Manual Testing Checklist

### Test 1: Verify Data Load
- [ ] Open report screen
- [ ] Check console for "📊 Report: Loaded X total schedules"
- [ ] Verify X matches number of schedules in irrigation screen
- [ ] Check data summary banner shows correct counts

### Test 2: Verify Period Filtering
- [ ] Switch to Daily period
- [ ] Check schedule count
- [ ] Switch to Weekly period
- [ ] Schedule count should increase (includes more schedules)
- [ ] Switch to Monthly period
- [ ] Schedule count should be highest

### Test 3: Verify Real-Time Updates
- [ ] Open report with running irrigation
- [ ] Check "Running Cycles" section shows LIVE badge
- [ ] Wait for irrigation to complete
- [ ] Verify it moves to completed section

### Test 4: Verify Filters
- [ ] Click filter icon (top-right)
- [ ] Set field filter to specific field
- [ ] Verify only that field's schedules show
- [ ] Reset filters
- [ ] Verify all schedules appear again

---

## 📊 Expected Data Flow

```
User Opens Report
    ↓
Shimmer Loading Appears
    ↓
Parallel Data Loading:
    ├─ Load user profile
    ├─ Load user's fields
    ├─ Load irrigation schedules ← YOUR SCHEDULES
    ├─ Load irrigation logs
    └─ Load alerts
    ↓
Apply Filters:
    ├─ Keep only active schedules
    ├─ Filter by date range
    ├─ Filter by selected period
    ├─ Apply field/status filters
    └─ Separate scheduled/running/manual
    ↓
Calculate Metrics:
    ├─ Total water used
    ├─ Average per cycle
    ├─ Completion rates
    └─ Performance stats
    ↓
Display in UI:
    ├─ Data summary banner (shows counts)
    ├─ Metadata section
    ├─ Water usage summary
    ├─ Performance metrics
    ├─ Scheduled cycles section ← YOUR SCHEDULES APPEAR HERE
    ├─ Running cycles (live updates)
    ├─ Manual cycles
    ├─ Completed irrigations
    ├─ Notifications
    └─ Charts
```

---

## 🎯 Quick Fix Checklist

If schedules still don't show:

1. **Check console output** - Look for debug messages
2. **Try Monthly period** - Shows more schedules
3. **Reset all filters** - Click filter icon → Reset
4. **Check schedule status** - Should be "scheduled" or "running", not "completed"
5. **Check isActive flag** - Should be `true` in Firebase
6. **Verify userId** - Should match between screens
7. **Check internet** - Firebase needs connection
8. **Pull to refresh** - Swipe down to reload

---

## 📱 Where to Look

### In the Report:

1. **Data Summary Banner** (top, orange box)
   - Shows: "Schedules: X" ← This number
   - If X > 0, data loaded successfully

2. **Scheduled Cycles Section**
   - Title shows: "Scheduled Cycles (X)"
   - Lists your active schedules
   - Shows schedule name, time, duration

3. **Running Cycles Section**
   - Title shows: "Running Cycles (X)" with LIVE badge
   - Shows currently active irrigations
   - Updates in real-time

4. **Console/Debug Output**
   - Shows detailed loading information
   - Explains why schedules were included/excluded

---

## 🚀 Next Steps

1. **Open the report screen**
2. **Look at the Data Summary Banner**
   - If "Schedules: 0" → Check console for why
   - If "Schedules: X" → They loaded! Check if filtering hides them

3. **Try different periods**
   - Daily → Weekly → Monthly
   - More schedules should appear with longer periods

4. **Check filters**
   - Click filter icon
   - Reset all filters
   - See if schedules appear

5. **Share console output** if still having issues
   - The debug messages will show exactly what's happening

---

## ✅ What You Should See Now

When you open the report:

1. **Shimmer loading** (professional skeleton UI)
2. **Data Summary Banner:**
   ```
   ✓ Data Loaded Successfully
   Schedules: 5  Logs: 23  Fields: 2  Alerts: 8
   ```
3. **Scheduled Cycles Section:**
   ```
   Scheduled Cycles (5)
   ● North Field - Jan 15, 06:00 AM • 60 min • Planned
   ● South Field - Jan 15, 08:00 AM • 45 min • Planned
   ...
   ```

Your schedules WILL appear if they exist in Firebase and are active! 🎉
