class AIRecommendation {
  final String id;
  final String userId;
  final String fieldId;
  final String recommendation; // 'Irrigate', 'Hold', or 'Alert'
  final String reasoning;
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final String cropType;
  final double confidence; // 0.0 to 1.0
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  AIRecommendation({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.recommendation,
    required this.reasoning,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.cropType,
    required this.confidence,
    required this.createdAt,
    this.expiresAt,
    this.metadata,
  });

  // Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fieldId': fieldId,
      'recommendation': recommendation,
      'reasoning': reasoning,
      'soilMoisture': soilMoisture,
      'temperature': temperature,
      'humidity': humidity,
      'cropType': cropType,
      'confidence': confidence,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory AIRecommendation.fromMap(String docId, Map<String, dynamic> map) {
    return AIRecommendation(
      id: docId,
      userId: map['userId'] ?? '',
      fieldId: map['fieldId'] ?? '',
      recommendation: map['recommendation'] ?? 'Hold',
      reasoning: map['reasoning'] ?? '',
      soilMoisture: (map['soilMoisture'] as num?)?.toDouble() ?? 0.0,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 0.0,
      cropType: map['cropType'] ?? 'unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'])
          : null,
      metadata: map['metadata'],
    );
  }

  // Create from API response
  factory AIRecommendation.fromAPIResponse({
    required String userId,
    required String fieldId,
    required Map<String, dynamic> apiResponse,
  }) {
    // New API format uses 'decision' instead of 'recommendation'
    final decision = apiResponse['decision'] ?? 'HOLD';
    
    // 'reasons' is an array, join them into a string
    final reasons = apiResponse['reasons'] as List<dynamic>?;
    final reasoning = reasons?.join(', ') ?? '';
    
    // Extract data from nested 'analysis' object
    final analysis = apiResponse['analysis'] as Map<String, dynamic>?;
    final soilData = analysis?['soil'] as Map<String, dynamic>?;
    final weatherData = analysis?['weather'] as Map<String, dynamic>?;
    
    final soilMoisture = (soilData?['moisture'] as num?)?.toDouble() ?? 0.0;
    final temperature = (weatherData?['temperature'] as num?)?.toDouble() ?? 0.0;
    final humidity = (weatherData?['humidity'] as num?)?.toDouble() ?? 0.0;
    final cropType = apiResponse['crop'] ?? 'unknown';
    
    // Confidence is already a percentage (0-100), convert to 0-1 range
    final confidencePercent = (apiResponse['confidence'] as num?)?.toDouble() ?? 50.0;
    final confidence = confidencePercent / 100.0;

    return AIRecommendation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fieldId: fieldId,
      recommendation: decision,
      reasoning: reasoning,
      soilMoisture: soilMoisture,
      temperature: temperature,
      humidity: humidity,
      cropType: cropType,
      confidence: confidence,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 3)),
      metadata: apiResponse,
    );
  }

  // Determine color/icon based on recommendation
  String getRecommendationColor() {
    switch (recommendation.toLowerCase()) {
      case 'irrigate':
        return '#4CAF50'; // Green
      case 'hold':
        return '#FFC107'; // Amber
      case 'alert':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
