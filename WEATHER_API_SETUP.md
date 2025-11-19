# 🌦️ Weather API Setup for Rain Notifications

## Get Your Free OpenWeatherMap API Key

### Step 1: Create Account
1. Go to [OpenWeatherMap](https://openweathermap.org/)
2. Click "Sign In" → "Create an Account"
3. Fill in your details and verify your email

### Step 2: Get API Key
1. After logging in, go to [API Keys](https://home.openweathermap.org/api_keys)
2. You'll see a default API key already created
3. Copy this API key

### Step 3: Add API Key to Your App
1. Open [lib/services/notification_service.dart](file:///c:/Users/famin/Documents/famingairrigate/lib/services/notification_service.dart#L220)
2. Find line 220 (around the `_fetchWeatherData` method)
3. Replace the placeholder API key:
   ```dart
   const apiKey = 'YOUR_API_KEY_HERE'; // Replace with your actual key
   ```

### Example:
```dart
// Before:
const apiKey = '7d3f7f3f3f3f3f3f3f3f3f3f3f3f3f3f';

// After:
const apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```

---

## ⚠️ Important Notes

### Free Tier Limits
- ✅ **60 calls/minute**
- ✅ **1,000,000 calls/month**
- ✅ **Free forever**

### Usage in This App
- Checks weather every **3 hours**
- Approximately **8 calls per day per user**
- Well within free limits

### API Key Activation
- New API keys take **up to 2 hours** to activate
- If you get "Invalid API key" error, wait and try again

---

## 🌧️ How Rain Notifications Work

### When You Get Notified
- **Rain expected within 24 hours** for any of your fields
- **12-hour cooldown** to prevent spam
- **Notification shows**:
  - When rain is expected ("in 3 hours", "today")
  - Probability percentage
  - Which field is affected

### Notification Example
```
🌧️ Rain Forecast
Rain expected in 4 hours for North Field. 
Hold off on irrigation! (75% chance)
```

### What It Checks
- ✅ Rain
- ✅ Drizzle  
- ✅ Thunderstorms

### How Often
- Checks every **3 hours**
- Looks ahead **24 hours**
- Only alerts if rain probability > 0%

---

## 🗺️ Field Location Requirements

For weather notifications to work, your **fields must have location data**:

1. When creating/editing a field, ensure you set the location
2. The app uses field coordinates (latitude/longitude) to get weather
3. If a field has no coordinates, it won't get weather alerts

---

## 🧪 Testing Rain Notifications

### Test Immediately
You can modify the code temporarily to test:

1. Open [lib/services/notification_service.dart](file:///c:/Users/famin/Documents/famingairrigate/lib/services/notification_service.dart#L150)
2. Change weather check frequency:
   ```dart
   // For testing - check every 1 minute instead of 3 hours
   _weatherCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
   ```
3. Restart the app
4. Wait 1 minute to see if weather data is fetched

### Check Logs
Look for these in the console:
```
✓ Weather checks started
✓ Notification sent: 🌧️ Rain Forecast
```

Or errors:
```
Weather API error: 401  (Invalid API key)
Error fetching weather: [error message]
```

---

## 🔒 Security Best Practice

### Don't Commit API Keys
The API key is currently hardcoded in the app. For production:

1. Use environment variables or Firebase Remote Config
2. Never commit API keys to public repositories
3. Consider using a backend to proxy API calls

### For Now (Development)
- The free tier key is safe for personal use
- Just don't share your code publicly with the key in it

---

## 🔍 Troubleshooting

### "Invalid API key" Error
- Wait 2 hours after creating account
- Check you copied the full key correctly
- Verify key is active in OpenWeatherMap dashboard

### No Weather Notifications
1. Check fields have location coordinates
2. Verify API key is set correctly
3. Check app logs for errors
4. Ensure there's actually rain in the forecast for your location

### Still Not Working?
1. Test the API directly in browser:
   ```
   https://api.openweathermap.org/data/2.5/forecast?lat=-1.9536&lon=30.0606&appid=YOUR_KEY
   ```
2. Replace `YOUR_KEY` with your API key
3. Replace lat/lon with your field coordinates
4. Should return JSON with weather data

---

## 📊 All Notification Types Now Available

1. ✅ **Irrigation Started** - Real-time when irrigation begins
2. ✅ **Irrigation Completed** - Real-time when irrigation ends
3. ✅ **Irrigation Stopped** - Real-time when manually stopped
4. ✅ **Low Moisture** (< 50%) - Real-time + every 30 min check
5. ✅ **Low Water Level** - Real-time + every 30 min check
6. ✅ **Schedule Reminders** - 30 minutes before scheduled irrigation
7. ✅ **Rain Forecast** - Every 3 hours, alerts if rain expected

---

## 🎉 You're All Set!

After adding your API key:
1. Run `flutter pub get`
2. Run the app
3. Grant notification permissions when prompted
4. Weather checks will start automatically
5. You'll get rain alerts when relevant

**Note:** Notification permissions are critical - the app will prompt you on first launch. Make sure to allow them!
