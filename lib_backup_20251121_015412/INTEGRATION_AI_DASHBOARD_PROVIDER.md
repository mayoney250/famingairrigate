/// Add these lines to lib/providers/dashboard_provider.dart

// Add to imports section (at the top, after other imports):
import '../services/irrigation_ai_service.dart';
import '../models/ai_recommendation_model.dart';

// Add to class properties (after other service declarations):
final IrrigationAIService _aiService = IrrigationAIService();

// Add to state variables section:
AIRecommendation? _currentAIRecommendation;
DateTime? _lastAIRequestTime;
bool _aiRequestInProgress = false;

// Add to getters section:
AIRecommendation? get currentAIRecommendation => _currentAIRecommendation;
bool get aiRequestInProgress => _aiRequestInProgress;

// Add this method before loadDashboardData:
/// Fetch AI irrigation advice based on current sensor and weather data
Future<void> _fetchAIRecommendation(String userId) async {
  // Debounce: don't call more than once every 30 seconds
  if (_lastAIRequestTime != null &&
      DateTime.now().difference(_lastAIRequestTime!) <
          const Duration(seconds: 30)) {
    log('⏭️ Skipping AI request (debounce)');
    return;
  }

  // Skip if no sensor data or weather data yet
  if (_avgSoilMoisture == null || _weatherData == null || _fields.isEmpty) {
    log('⏭️ Skipping AI request (missing data)');
    return;
  }

  _aiRequestInProgress = true;
  notifyListeners();

  try {
    _lastAIRequestTime = DateTime.now();
    
    // Get first field's crop type (default to 'maize' if not available)
    final firstFieldId = _fields.isNotEmpty ? _fields.first['id'] : null;
    String cropType = 'maize';
    
    if (firstFieldId != null) {
      try {
        final fieldDoc = await _firestore
            .collection('fields')
            .doc(firstFieldId)
            .get();
        if (fieldDoc.exists) {
          cropType = fieldDoc['cropType'] ?? 'maize';
        }
      } catch (e) {
        log('⚠️ Error fetching field crop type: $e');
      }
    }

    log('🤖 Fetching AI recommendation for field: $firstFieldId, crop: $cropType');

    final recommendation = await _aiService.getIrrigationAdvice(
      userId: userId,
      fieldId: firstFieldId ?? 'unknown',
      soilMoisture: _avgSoilMoisture ?? 0.0,
      temperature: _weatherData?.temperature ?? 20.0,
      humidity: _weatherData?.humidity ?? 50.0,
      cropType: cropType,
    );

    _currentAIRecommendation = recommendation;
    
    // Save to Firestore for history
    if (firstFieldId != null) {
      await _firestore
          .collection('ai_recommendations')
          .add(recommendation.toMap());
    }

    log('✅ AI recommendation updated: ${recommendation.recommendation}');
    notifyListeners();
  } catch (e) {
    log('❌ Error fetching AI recommendation: $e');
    // Don't set error message - AI is optional
  } finally {
    _aiRequestInProgress = false;
    notifyListeners();
  }
}

// Add this line to the end of loadDashboardData (before the final notifyListeners):
// Fetch AI recommendation after loading sensor data
await _fetchAIRecommendation(userId).catchError((e) {
  log('⚠️ AI recommendation fetch failed: $e');
  // Non-blocking - continue even if AI fails
  return null;
});
