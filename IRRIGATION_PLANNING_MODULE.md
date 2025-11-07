# Interactive Irrigation Planning Module

## Overview

The Interactive Irrigation Planning Module is a comprehensive feature for the Faminga platform that allows farmers to visually plan and manage irrigation zones using interactive maps. Users can draw field boundaries, mark irrigation infrastructure (pipes, canals, sprinkler zones), and save these layouts for future reference.

## Features

### ✅ Completed Features

1. **Interactive Map Drawing**
   - Draw polygons for irrigation coverage areas
   - Draw polylines for pipes, canals, and irrigation lines
   - Drag markers to adjust point positions
   - Real-time visual feedback

2. **Map Controls**
   - Location search by address
   - Manual coordinate entry (latitude/longitude)
   - Current location detection
   - Map type switching (Satellite, Street, Hybrid)
   - Zoom and pan controls

3. **Irrigation Zone Management**
   - Save irrigation zones with detailed metadata
   - View all zones for a field
   - Delete zones
   - Color-coded visualization
   - Zone type categorization (Field, Pipe, Canal, Sprinkler, Drip, Custom)

4. **Data Persistence**
   - Firebase Firestore integration
   - Real-time updates
   - Automatic save/load functionality
   - User-specific data isolation

5. **Mobile & Web Support**
   - Responsive design
   - Touch-friendly controls
   - Cross-platform compatibility

## Architecture

### Models

1. **IrrigationZone** (`lib/models/irrigation_zone_model.dart`)
   - Represents a single irrigation zone
   - Supports polygon and polyline geometries
   - Includes metadata: name, type, flow rate, coverage, color

2. **FieldModel** (existing, enhanced)
   - Represents a farm field
   - Contains border coordinates
   - Links to irrigation zones

### Services

1. **IrrigationZoneService** (`lib/services/irrigation_zone_service.dart`)
   - CRUD operations for irrigation zones
   - Real-time streaming of zone data
   - Firestore integration

### Widgets

1. **MapDrawingWidget** (`lib/widgets/map/map_drawing_widget.dart`)
   - Reusable interactive map component
   - Drawing mode controls
   - Location search and coordinate input
   - Marker manipulation

### Screens

1. **IrrigationPlanningScreen** (`lib/screens/irrigation/irrigation_planning_screen.dart`)
   - Main planning interface
   - Zone list and management
   - Map integration
   - Help dialog

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.0.0)
- Google Maps API key (for Android and Web)
- Firebase project configured

### 1. Google Maps API Key Setup

#### For Android:

1. Get your Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)

2. Create/edit `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="google_maps_api_key">YOUR_ACTUAL_API_KEY_HERE</string>
</resources>
```

3. Update `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <!-- ... other configurations ... -->
    
    <!-- Google Maps API Key -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="@string/google_maps_api_key" />
</application>
```

#### For iOS:

Add to `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### For Web:

Add to `web/index.html` in the `<head>` section:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY_HERE"></script>
```

### 2. Enable Required Google Maps APIs

In Google Cloud Console, enable:
- Maps SDK for Android
- Maps SDK for iOS
- Maps JavaScript API
- Geocoding API
- Places API (optional, for enhanced search)

### 3. Firestore Security Rules

Add these rules to your `firestore.rules` file:

```javascript
// Irrigation zones
match /irrigation_zones/{zoneId} {
  allow read: if request.auth != null && 
    (resource.data.userId == request.auth.uid || 
     request.auth.uid in resource.data.sharedWith);
  
  allow create: if request.auth != null && 
    request.resource.data.userId == request.auth.uid;
  
  allow update, delete: if request.auth != null && 
    resource.data.userId == request.auth.uid;
}
```

Deploy the rules:
```bash
firebase deploy --only firestore:rules
```

### 4. Location Permissions

The app requires location permissions. These are already configured in the project:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to show your current position on the map.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location to show your current position on the map.</string>
```

## Usage

### Accessing the Feature

1. Navigate to the **Fields** screen
2. Find a field in your list
3. Tap the **Map icon** (Plan Irrigation button)
4. The Irrigation Planning screen opens

### Drawing Zones

1. **Select Drawing Mode**:
   - **None**: Pan and zoom only
   - **Area**: Draw polygon zones (irrigation coverage areas)
   - **Line**: Draw pipe/canal routes

2. **Add Points**:
   - Tap on the map to add points
   - Markers appear for each point
   - Drag markers to adjust positions

3. **Use Controls**:
   - **Search**: Enter address or location name
   - **Coordinates**: Tap pin icon, enter lat/lng manually
   - **My Location**: Tap location icon to center on current position
   - **Map Type**: Toggle between Satellite, Street, Hybrid views

4. **Save Zone**:
   - Click **Save** button
   - Enter zone details:
     - Name (required)
     - Type (Sprinkler, Drip, Pipe, etc.)
     - Description (optional)
     - Flow rate (optional)
     - Coverage area (optional)
     - Color (visual identification)
   - Click **Save Zone**

5. **Manage Zones**:
   - View all zones in the list below the map
   - Edit zone details (coming soon)
   - Delete zones with confirmation

### Coordinate Entry

For precision mapping:
1. Tap the **pin drop** icon
2. Enter latitude (e.g., -1.286389)
3. Enter longitude (e.g., 36.817223)
4. Click **Add Location** icon
5. Point is added to the map

## Data Model

### IrrigationZone

```dart
{
  "id": "auto_generated",
  "fieldId": "field_id",
  "userId": "user_id",
  "name": "Main Sprinkler Zone",
  "description": "Covers north section",
  "zoneType": "sprinkler", // field, pipe, canal, sprinkler, drip, custom
  "drawingType": "polygon", // polygon, polyline, marker
  "coordinates": [
    {"latitude": -1.2864, "longitude": 36.8172},
    {"latitude": -1.2865, "longitude": 36.8173},
    // ... more points
  ],
  "color": "#2196F3",
  "flowRate": 150.5, // L/min
  "coverage": 2500.0, // m²
  "isActive": true,
  "createdAt": "2025-01-15T10:30:00.000Z",
  "updatedAt": "2025-01-15T10:30:00.000Z"
}
```

## Troubleshooting

### App Crashes When Adding Field

**Fixed**: The crash was caused by a null-safety bug in `add_field_modal.dart`. The fix has been applied:
- Updated null checks for `borderCoordinates`
- Fixed Firestore data type consistency (using `GeoPoint` instead of maps)

### Map Not Showing on Android

1. Verify Google Maps API key is set in `strings.xml`
2. Ensure API key is enabled for Android in Google Cloud Console
3. Check that Maps SDK for Android is enabled
4. Verify the SHA-1 certificate fingerprint is added to Firebase

Get SHA-1:
```bash
cd android
./gradlew signingReport
```

### Map Not Showing on Web

1. Verify API key is in `web/index.html`
2. Ensure Maps JavaScript API is enabled
3. Check browser console for errors
4. Verify domain restrictions in Google Cloud Console

### Location Not Working

1. Check permissions are granted in device settings
2. Ensure location services are enabled
3. For Android 10+, ensure ACCESS_FINE_LOCATION is granted
4. For iOS, verify Info.plist has location usage descriptions

### Firestore Permission Denied

1. Deploy updated security rules
2. Verify user is authenticated
3. Check userId matches the authenticated user
4. Review Firestore console for rule evaluation errors

## Next Steps / Enhancements

- [ ] Edit existing zones
- [ ] Duplicate/copy zones
- [ ] Import/export zone data (GeoJSON)
- [ ] Calculate irrigation coverage automatically
- [ ] Integration with irrigation scheduling
- [ ] Offline support with local caching
- [ ] Multi-field zone planning
- [ ] Weather overlay on maps
- [ ] Soil moisture heatmap
- [ ] 3D terrain visualization

## Code Structure

```
lib/
├── models/
│   ├── irrigation_zone_model.dart       [NEW]
│   └── field_model.dart                 [EXISTING]
├── services/
│   ├── irrigation_zone_service.dart     [NEW]
│   └── field_service.dart               [EXISTING]
├── screens/
│   ├── irrigation/
│   │   ├── irrigation_planning_screen.dart [NEW]
│   │   └── irrigation_list_screen.dart     [EXISTING]
│   └── fields/
│       └── fields_screen.dart           [MODIFIED]
├── widgets/
│   └── map/
│       └── map_drawing_widget.dart      [NEW]
└── routes/
    └── app_routes.dart                   [MODIFIED]
```

## Dependencies

All required dependencies are already in `pubspec.yaml`:

```yaml
google_maps_flutter: ^2.5.0
geolocator: ^10.1.0
geocoding: ^2.1.1
location: ^5.0.3
cloud_firestore: ^4.13.0
```

## Testing Checklist

- [x] Create new irrigation zone with polygon
- [x] Create new irrigation zone with polyline
- [ ] Edit existing zone
- [x] Delete zone
- [x] Search location by address
- [x] Add point by coordinates
- [x] Drag markers to adjust
- [x] Switch map types
- [x] Test on Android
- [ ] Test on iOS
- [ ] Test on Web
- [x] Verify data persistence
- [x] Test with multiple fields
- [x] Verify real-time updates

## Support

For issues or questions:
- Check the troubleshooting section above
- Review Firebase Console for Firestore errors
- Check device logs for runtime errors
- Verify Google Maps API quotas and billing

## License

Part of the Faminga Irrigation Management System
© 2025 Faminga. All rights reserved.
