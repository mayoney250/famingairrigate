# Missing Translations Issue - Found

## Problem
The Irrigation, Sensors, and Profile screens have **HARDCODED English strings** instead of using `context.l10n` for localization. This is why language switching doesn't work on these screens.

## Solution Required
1. Add all hardcoded strings to .arb files (all 4 languages)
2. Replace all hardcoded `Text()` calls with `context.l10n.*` calls in the screens
3. Regenerate localization files with `flutter gen-l10n`

## Hardcoded Strings Found

### Irrigation Control Screen
- "OPEN" (action button label)
- "CLOSE" (action button label)
- "No actions yet"
- "Safety Note"
- "Cancel"
- "Confirm"

### Irrigation List Screen
- "Irrigation Schedules" (AppBar title)
- "Please log in to view schedules"
- "Create Schedule"
- "Stop Irrigation"
- "Start Now"
- "Update"
- "Delete"
- "Cancel"
- "Stop"
- "Start Irrigation Now"
- "Close"
- "Create Irrigation Schedule" (dialog title)
- "No fields available"
- "Start Time: "
- "Pick"
- "Save"
- "Update Irrigation Schedule" (dialog title)
- "Go to Fields"
- "No Fields Found" (modal title)
- "You don't have any fields registered..."

### Irrigation Planning Screen
- "Irrigation Planning" (AppBar title)
- "Save Irrigation Zone" (dialog title)
- "Color: "
- "Cancel"
- "Save Zone"
- "Delete Zone"
- "Delete"
- "How to Use" (help dialog)
- "1. Select drawing mode (Area or Line) at the bottom"
- "2. Tap on the map to add points"
- "3. Drag markers to adjust positions"
- "4. Use "Undo" to remove last point"
- "5. Click "Save" when finished"
- "Search & Navigation:" (help section)
- "• Search by address or location name"
- "• Add coordinates manually for precision"
- "• Switch between map types (Satellite/Street)"
- "Zone Types:" (help section)
- "• Area: For irrigation coverage zones"
- "• Line: For pipes, canals, or irrigation lines"
- "Got it"

### Sensors Screen
- "Sensors" (AppBar title)
- "No sensors yet. Tap + to add."
- "Bluetooth (BLE)"
- "WiFi"
- "LoRaWAN Gateway"
- "Cancel"
- "Add Sensor"

### Profile Screen
- "Profile" (AppBar title)
- "Logout" (dialog)
- "Are you sure you want to logout?"
- "Cancel"
- "Logout" (button)
- "About Faminga Irrigation" (dialog)
- "Version 1.0.0"
- "Close"
- "Take Photo"
- "Choose from Gallery"
- "Remove Photo"
- "Edit Profile" (dialog)
- "Cancel"
- "Save"
- "Change Password" (dialog)
- "Secure Your Account"
- "Security Tips"

### Change Password Screen
- "Change Password" (AppBar)
- "Secure Your Account"
- "Security Tips"

### Edit Profile Screen
- "Edit Profile" (dialog)

## Status
Ready to implement fixes in this order:
1. Add all strings to .arb files
2. Update all screens to use context.l10n
3. Run flutter gen-l10n
4. Test language switching
