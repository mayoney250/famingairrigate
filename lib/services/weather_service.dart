import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weather_data_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'weatherData';

  // Create or update weather data
  Future<String> saveWeatherData(WeatherDataModel weather) async {
    try {
      // Check if weather data exists for user today
      final existing = await getTodayWeather(weather.userId);
      
      if (existing != null) {
        // Update existing
        await _firestore.collection(_collection).doc(existing.id).update({
          'temperature': weather.temperature,
          'humidity': weather.humidity,
          'condition': weather.condition,
          'description': weather.description,
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
        });
        log('Weather data updated: ${existing.id}');
        return existing.id;
      } else {
        // Create new
        final docRef = await _firestore.collection(_collection).add(weather.toMap());
        log('Weather data created: ${docRef.id}');
        return docRef.id;
      }
    } catch (e) {
      log('Error saving weather data: $e');
      rethrow;
    }
  }

  // Get today's weather
  Future<WeatherDataModel?> getTodayWeather(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Simplified query - just get by userId
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      // Filter for today's weather in memory
      final todayWeather = snapshot.docs
          .map((doc) => WeatherDataModel.fromFirestore(doc))
          .where((weather) {
            final timestamp = weather.timestamp;
            return timestamp.isAfter(startOfDay) && 
                   timestamp.isBefore(endOfDay);
          })
          .toList();

      if (todayWeather.isNotEmpty) {
        // Sort by timestamp and return most recent
        todayWeather.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return todayWeather.first;
      }
      
      return null;
    } catch (e) {
      log('Error fetching today weather: $e');
      return null; // Return null instead of rethrowing
    }
  }

  // Stream of current weather
  Stream<WeatherDataModel?> streamCurrentWeather(String userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return WeatherDataModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // Get weather history
  Future<List<WeatherDataModel>> getWeatherHistory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WeatherDataModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching weather history: $e');
      rethrow;
    }
  }

  // Get last 7 days weather
  Future<List<WeatherDataModel>> getLast7DaysWeather(String userId) async {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return getWeatherHistory(userId, lastWeek, now);
  }

  // Delete old weather data (keep last 30 days)
  Future<void> deleteOldWeatherData(String userId, int daysToKeep) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      log('Old weather data deleted: ${snapshot.docs.length} records');
    } catch (e) {
      log('Error deleting old weather data: $e');
      rethrow;
    }
  }

  Future<WeatherDataModel?> fetchCurrentWeatherFromOpenWeather({
    required double lat,
    required double lon,
    required String apiKey,
  }) async {
    final Uri url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return WeatherDataModel(
        id: '',
        userId: '',
        temperature: (data['main']['temp'] as num).toDouble(),
        humidity: (data['main']['humidity'] as num).toDouble(),
        condition: (data['weather']?[0]?['main'] ?? '').toString(),
        description: (data['weather']?[0]?['description'] ?? '').toString(),
        timestamp: DateTime.fromMillisecondsSinceEpoch((data['dt'] as int) * 1000),
        location: data['name'] ?? '',
      );
    } else {
      log('Failed to fetch OpenWeather (status: ${res.statusCode})');
      return null;
    }
  }
}
