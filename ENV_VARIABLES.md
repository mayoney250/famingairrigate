# Environment Variables Configuration

## 📋 Required API Keys and Credentials

Copy these variables and set them up according to your deployment method.

### Firebase Configuration (Already Configured)
```bash
FIREBASE_PROJECT_ID=ngairrigate
FIREBASE_API_KEY=AIzaSyD95nh8G5koVV04Oqmq_ni9n0wl0YgbHC8
FIREBASE_AUTH_DOMAIN=ngairrigate.firebaseapp.com
FIREBASE_STORAGE_BUCKET=ngairrigate.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=622157404711
FIREBASE_APP_ID=1:622157404711:web:0ef6a4c4d838c75aef0c02
FIREBASE_MEASUREMENT_ID=G-PHY8RXWZER
```

### AI Services
```bash
# OpenAI (Disease Detection)
OPENAI_API_KEY=sk-...your_key_here

# Google Gemini (AI Assistant)
GEMINI_API_KEY=...your_key_here

# Perplexity AI (Market Intelligence)
PERPLEXITY_API_KEY=...your_key_here
```

### Communication Services
```bash
# SendGrid (Email)
SENDGRID_API_KEY=SG...your_key_here
FROM_EMAIL=noreply@faminga.app

# Twilio (SMS/2FA)
TWILIO_ACCOUNT_SID=AC...your_sid_here
TWILIO_AUTH_TOKEN=...your_token_here
TWILIO_PHONE_NUMBER=+...your_phone_here
```

### Payment Services
```bash
# Flutterwave
FLUTTERWAVE_PUBLIC_KEY=FLWPUBK-...your_key_here
FLUTTERWAVE_SECRET_KEY=FLWSECK-...your_key_here
FLUTTERWAVE_ENCRYPTION_KEY=...your_key_here
```

### Maps & Weather
```bash
# Google Maps
GOOGLE_MAPS_API_KEY=AIza...your_key_here

# OpenWeather
OPENWEATHER_API_KEY=...your_key_here
```

### Google Services
```bash
GOOGLE_CLIENT_ID=...your_id_here
GOOGLE_CLIENT_SECRET=...your_secret_here
GOOGLE_TRANSLATE_API_KEY=...your_key_here
```

## 🔐 Security Best Practices

1. **Never commit API keys** to version control
2. **Use different keys** for development, staging, and production
3. **Rotate keys regularly** (every 90 days)
4. **Enable API restrictions** in provider dashboards
5. **Monitor API usage** for unusual activity
6. **Use Firebase Security Rules** to protect data

## 📱 Using Environment Variables in Flutter

### Option 1: Command Line (Recommended for Development)
```bash
flutter run --dart-define=OPENAI_API_KEY=your_key_here --dart-define=GEMINI_API_KEY=your_key_here
```

### Option 2: flutter_dotenv Package
```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0

# Load in main.dart
await dotenv.load(fileName: ".env");
String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
```

### Option 3: Build Configuration Files
Create separate configuration files for each environment:
- `config/dev.dart`
- `config/staging.dart`
- `config/production.dart`

## 🚀 Deployment

### For Production Builds:
1. Use CI/CD environment variables
2. Never include keys in source code
3. Use secure secrets management (GitHub Secrets, Google Cloud Secret Manager)
4. Enable API key restrictions for production keys

## 📞 Where to Get Keys

| Service | Link |
|---------|------|
| OpenAI | https://platform.openai.com/api-keys |
| Google Gemini | https://makersuite.google.com/app/apikey |
| Perplexity | https://www.perplexity.ai/settings/api |
| SendGrid | https://app.sendgrid.com/settings/api_keys |
| Twilio | https://console.twilio.com/ |
| Flutterwave | https://dashboard.flutterwave.com/dashboard/settings/apis |
| Google Maps | https://console.cloud.google.com/google/maps-apis |
| OpenWeather | https://openweathermap.org/api |


