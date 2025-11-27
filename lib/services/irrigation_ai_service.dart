import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/ai_recommendation_model.dart';

class IrrigationAIService {
  static const String _baseUrl = 'https://famingaaimodal.onrender.com';
  static const String _adviceEndpoint = '/api/v1/irrigation/advice';
  static const Duration _timeout = Duration(seconds: 10); // Increased timeout for proxy

  /// Helper to handle CORS proxy for web
  Uri _getUri(String endpoint) {
    final url = '$_baseUrl$endpoint';
    if (kIsWeb) {
      // Use corsproxy.io to bypass CORS on web
      return Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}');
    }
    return Uri.parse(url);
  }

  /// Get irrigation advice from the AI API
  /// Returns an [AIRecommendation] with recommendation (Irrigate/Hold/Alert) and reasoning
  /// Throws an exception if the request fails or times out
  Future<AIRecommendation> getIrrigationAdvice({
    required String userId,
    required String fieldId,
    required double soilMoisture,
    required double temperature,
    required double humidity,
    required String cropType,
  }) async {
    try {
      dev.log('📡 Calling AI service for field: $fieldId');

      // New API format with nested objects
      final requestPayload = {
        'soil_data': {
          'soil_moisture': soilMoisture,
        },
        'weather_data': {
          'temperature': temperature,
          'humidity': humidity,
        },
        'crop_type': cropType,
      };

      dev.log('📤 Request payload: ${jsonEncode(requestPayload)}');

      final response = await http
          .post(
            _getUri(_adviceEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestPayload),
          )
          .timeout(_timeout, onTimeout: () {
        dev.log('⏱️ AI API request timed out');
        throw TimeoutException('AI API request timed out');
      });

      dev.log('📥 API Response status: ${response.statusCode}');
      dev.log('📥 API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // API returns 'decision' not 'recommendation'
        dev.log('✅ AI decision received: ${data['decision']}');

        final recommendation = AIRecommendation.fromAPIResponse(
          userId: userId,
          fieldId: fieldId,
          apiResponse: data,
        );

        return recommendation;
      } else {
        dev.log('❌ AI API error: ${response.statusCode} - ${response.body}');
        throw Exception(
            'AI API returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      dev.log('❌ Error calling AI service: $e');
      rethrow;
    }
  }

  /// Health check for the AI API
  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(_getUri('/health'))
          .timeout(const Duration(seconds: 5));

      dev.log('🏥 AI API health check: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      dev.log('⚠️ AI API health check failed: $e');
      return false;
    }
  }

  /// Get available crop profiles
  Future<List<String>> getCropProfiles() async {
    try {
      final response = await http
          .get(_getUri('/api/v1/crops'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final crops = List<String>.from(data['crops'] ?? []);
        dev.log('🌾 Crop profiles available: $crops');
        return crops;
      }
      return [];
    } catch (e) {
      dev.log('⚠️ Failed to fetch crop profiles: $e');
      return [];
    }
  }

  /// Get recent decision history
  Future<List<Map<String, dynamic>>> getDecisionHistory({int limit = 10}) async {
    try {
      final response = await http
          .get(_getUri('/api/v1/history?limit=$limit'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final history = List<Map<String, dynamic>>.from(data['history'] ?? []);
        dev.log('📋 Decision history retrieved: ${history.length} records');
        return history;
      }
      return [];
    } catch (e) {
      dev.log('⚠️ Failed to fetch decision history: $e');
      return [];
    }
  }
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => message;
}
