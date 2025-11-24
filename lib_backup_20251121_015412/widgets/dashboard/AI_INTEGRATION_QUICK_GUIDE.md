# AI Recommendation Badge - Dashboard Integration

## Quick Integration (Recommended - No Provider Changes Needed)

The new `AIRecommendationBadge` widget is standalone and handles all AI fetching internally. You only need to add it to the dashboard UI.

### Step 1: Add Import to dashboard_screen.dart

```dart
import '../../widgets/dashboard/ai_recommendation_badge.dart';
```

### Step 2: Add Badge to Hero Card

In `dashboard_screen.dart`, find the `_buildUserInsightCard()` method (around line 429).

Inside the Column, locate the `recommendation` Text widget that looks like:
```dart
Text(
  recommendation,
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: FamingaBrandColors.textSecondary,
  ),
),
```

**Add the AI badge right after the recommendation text:**

```dart
Text(
  recommendation,
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: FamingaBrandColors.textSecondary,
  ),
),
const SizedBox(height: 8),
// NEW: AI Recommendation Badge
if (_dashboardData != null && 
    _dashboardData!['latestSensorReading'] != null)
  Align(
    alignment: Alignment.centerLeft,
    child: AIRecommendationBadge(
      userId: authProvider.currentUser!.id,
      fieldId: _selectedFieldId,
      soilMoisture: (_dashboardData!['latestSensorReading']['soilMoisture'] as num).toDouble(),
      temperature: (_dashboardData!['weatherData']['temperature'] as num).toDouble(),
      humidity: (_dashboardData!['weatherData']['humidity'] as num).toDouble(),
      cropType: _dashboardData!['field']['cropType'] ?? 'crops',
      onRecommendationReceived: () {
        dev.log('📊 AI recommendation received and displayed');
      },
    ),
  ),
```

### Step 3: Add Developer Import (if not already present)

At the top of `dashboard_screen.dart`:
```dart
import 'dart:developer' as dev;
```

## How It Works

1. **Standalone Operation**: The badge fetches its own recommendation without provider changes
2. **30-Second Debounce**: Won't call API more than once per 30 seconds even if widget rebuilds
3. **Graceful Degradation**: If API fails or sensor data is missing, badge silently disappears
4. **Auto-Refresh**: If soil moisture or temperature changes significantly (>5% for soil, >2°C for temp), it refetches
5. **Loading State**: Shows spinner with "AI advice" label while fetching
6. **Color Coded**:
   - 🟢 Irrigate = Green
   - 🟡 Hold = Amber  
   - 🔴 Alert = Red
7. **Confidence Display**: Shows AI confidence percentage (e.g., "AI (87%)")
8. **Tooltip**: Hover/long-press to see full reasoning

## API Contract

The badge communicates with:
- **Endpoint**: `POST https://famingaaimodal.onrender.com/api/v1/irrigation/advice`
- **Timeout**: 3 seconds (enforced in IrrigationAIService)
- **Request**:
  ```json
  {
    "soilMoisture": 45.2,
    "temperature": 28.5,
    "humidity": 62.0,
    "cropType": "tomato"
  }
  ```
- **Response**:
  ```json
  {
    "recommendation": "Irrigate",
    "reasoning": "Soil moisture is low at 45.2%...",
    "confidence": 0.87,
    "metadata": { ... }
  }
  ```

## UI Placement Reference

```
┌─ User Greeting Card ──────────────────┐
│ Greeting + Temperature Badge          │
│                                       │
│ 💧 Moisture: 45% 🌡️ Temp: 28°C      │
│                                       │
│ Current recommendation: Ready to      │
│ water. 🟢 Irrigate (AI 87%) ← NEW     │
│                                       │
│ [View Details] [+ Schedule]           │
└───────────────────────────────────────┘
```

## Testing Checklist

- [ ] Widget appears below recommendation text on dashboard
- [ ] Color matches recommendation type (Irrigate=green, etc.)
- [ ] Spinner shows for 0-3 seconds while loading
- [ ] Confidence percentage displays (e.g., "87%")
- [ ] Tooltip shows reasoning on hover/long-press
- [ ] Doesn't call API on every rebuild (30-second debounce)
- [ ] Gracefully handles API timeout (badge disappears, no error)
- [ ] Updates if soil moisture changes by >5%
- [ ] Works across different fields/crops

## Troubleshooting

**Badge not appearing:**
- Check that `_dashboardData` has both `latestSensorReading` and `weatherData`
- Verify `FamingaBrandColors` import exists in dashboard_screen.dart
- Check dev logs for "Error fetching AI recommendation" messages

**Widget rebuilding constantly:**
- Confirm `didUpdateWidget` comparison logic is correct (5% soil, 2°C temp thresholds)
- Check if parent widget is being rebuild unnecessarily

**API not responding:**
- Badge will silently disappear; check device dev console for timeout logs
- Verify Hadja API is running: `curl https://famingaaimodal.onrender.com/health`

**Confidence showing 0%:**
- API confidence is between 0.0-1.0; widget multiplies by 100 for display
- If showing "0", check AIRecommendation.confidence parsing in ai_recommendation_model.dart

## Future Enhancements

1. **Save to Firestore**: Persist recommendations in `ai_recommendations` collection
2. **Recommendation History**: Show last 5 recommendations in expandable panel
3. **Override UI**: Allow farmer to mark recommendation as "followed" or "ignored"
4. **Batch Recommendations**: Show advice for multiple fields simultaneously
5. **Time-based Display**: Hide recommendation if older than 1 hour (auto-refresh)

## Files Modified

- `dashboard_screen.dart`: Added AIRecommendationBadge widget to hero card (4 new lines + import)

## Files Created

- `lib/widgets/dashboard/ai_recommendation_badge.dart` (180 lines)
- `lib/services/irrigation_ai_service.dart` (147 lines)  
- `lib/models/ai_recommendation_model.dart` (137 lines)
