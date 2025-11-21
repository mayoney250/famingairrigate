import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weather_data_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cache_repository.dart';

class WeatherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'weatherData';
  static const String _forecastEndpoint = 'https://api.openweathermap.org/data/2.5/forecast';

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
        // cache today's weather (serialize timestamps to ISO strings for Hive)
        final cache = CacheRepository();
        final cacheKey = 'weather_today_${weather.userId}';
        final m = weather.toMap();
        // normalize Timestamp fields
        final normalized = Map<String, dynamic>.from(m);
        if (normalized['timestamp'] is Timestamp) {
          normalized['timestamp'] = (normalized['timestamp'] as Timestamp).toDate().toIso8601String();
        } else if (normalized['timestamp'] is DateTime) {
          normalized['timestamp'] = (normalized['timestamp'] as DateTime).toIso8601String();
        }
        if (normalized['lastUpdated'] is Timestamp) {
          normalized['lastUpdated'] = (normalized['lastUpdated'] as Timestamp).toDate().toIso8601String();
        } else if (normalized['lastUpdated'] is DateTime) {
          normalized['lastUpdated'] = (normalized['lastUpdated'] as DateTime).toIso8601String();
        }
        await cache.cacheJson(cacheKey, normalized);
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
      final cache = CacheRepository();
      final cacheKey = 'weather_today_$userId';
      final cached = cache.getCachedJson(cacheKey);
      if (cached != null) {
        try {
          return WeatherDataModel.fromMap(cached);
        } catch (_) {
          // fall through to fetching live data
        }
      }
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
        // cache today's weather
        await cache.cacheJson(cacheKey, todayWeather.first.toMap());
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
    final cache = CacheRepository();
    final cacheKey = 'weather_today_$userId';

    // async* stream: yield cached first then live updates
    return (() async* {
      final cached = cache.getCachedJson(cacheKey);
      if (cached != null) {
        try {
          yield WeatherDataModel.fromMap(cached);
        } catch (_) {
          // ignore
        }
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      try {
        await for (final snapshot in _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .limit(1)
            .snapshots()) {
          if (snapshot.docs.isNotEmpty) {
            final model = WeatherDataModel.fromFirestore(snapshot.docs.first);
            // normalize timestamps for cache
            final m = model.toMap();
            final normalized = Map<String, dynamic>.from(m);
            if (normalized['timestamp'] is Timestamp) {
              normalized['timestamp'] = (normalized['timestamp'] as Timestamp).toDate().toIso8601String();
            }
            if (normalized['lastUpdated'] is Timestamp) {
              normalized['lastUpdated'] = (normalized['lastUpdated'] as Timestamp).toDate().toIso8601String();
            }
            await cache.cacheJson(cacheKey, normalized);
            yield model;
          } else {
            yield null;
          }
        }
      } catch (e) {
        // Offline or Firestore error: yield cached weather if available
        log('⚠️ Firestore streamCurrentWeather error (offline?): $e');
        final cached = cache.getCachedJson(cacheKey);
        if (cached != null) {
          try {
            yield WeatherDataModel.fromMap(cached);
          } catch (_) {}
        }
      }
    })();
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
    final cache = CacheRepository();
    final cacheKey = 'weather_7days_$userId';
    final cached = cache.getCachedList(cacheKey);
    if (cached.isNotEmpty) {
      return cached.map((m) => WeatherDataModel.fromMap(m)).toList();
    }

    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    final list = await getWeatherHistory(userId, lastWeek, now);
    // Normalize maps to replace Timestamp with ISO strings for safe caching
    final normalizedList = list.map((w) {
      final m = w.toMap();
      final nm = Map<String, dynamic>.from(m);
      if (nm['timestamp'] is Timestamp) nm['timestamp'] = (nm['timestamp'] as Timestamp).toDate().toIso8601String();
      if (nm['lastUpdated'] is Timestamp) nm['lastUpdated'] = (nm['lastUpdated'] as Timestamp).toDate().toIso8601String();
      return nm;
    }).toList();
    await cache.cacheJsonList(cacheKey, normalizedList);
    return list;
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

  // Fetch 5-day forecast (3-hour intervals) and reduce to daily summaries
  Future<List<Map<String, dynamic>>> fetch5DayForecast({
    required double lat,
    required double lon,
    required String apiKey,
  }) async {
    final url = Uri.parse('$_forecastEndpoint?lat=$lat&lon=$lon&appid=$apiKey&units=metric');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      log('Failed to fetch forecast (status: ${res.statusCode})');
      return [];
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final list = (data['list'] as List?) ?? [];
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
    for (final raw in list) {
      final dt = DateTime.fromMillisecondsSinceEpoch(((raw['dt'] ?? 0) as int) * 1000);
      final d0 = DateTime(dt.year, dt.month, dt.day);
      (grouped[d0] ??= []).add(Map<String, dynamic>.from(raw));
    }
    final days = grouped.keys.toList()..sort();
    final out = <Map<String, dynamic>>[];
    for (final day in days.take(5)) {
      final entries = grouped[day]!;
      double minT = double.infinity, maxT = -double.infinity;
      double windSum = 0.0; int windN = 0;
      double rainMm = 0.0;
      double popSum = 0.0; int popN = 0;
      double humiditySum = 0.0; int humidityN = 0;
      String status = '';
      int weight = -1;
      for (final e in entries) {
        final main = e['main'] ?? {};
        final tmin = (main['temp_min'] ?? main['temp'] ?? 0).toDouble();
        final tmax = (main['temp_max'] ?? main['temp'] ?? 0).toDouble();
        if (tmin < minT) minT = tmin;
        if (tmax > maxT) maxT = tmax;
        final w = (e['wind']?['speed'] ?? 0).toDouble();
        windSum += w; windN++;
        if (e['pop'] != null) { popSum += (e['pop'] as num).toDouble(); popN++; }
        if (main['humidity'] != null) { 
          humiditySum += (main['humidity'] as num).toDouble(); 
          humidityN++; 
        }
        if (e['rain'] != null && e['rain']['3h'] != null) {
          rainMm += (e['rain']['3h'] as num).toDouble();
        }
        final weather = (e['weather'] as List?)?.first;
        final clouds = (e['clouds']?['all'] ?? 0) as int;
        final wmain = (weather?['main'] ?? '').toString();
        final wScore = wmain == 'Rain' ? 1000 : clouds; // prefer rain if present
        if (wScore > weight) { weight = wScore; status = wmain; }
      }
      out.add({
        'date': day.toIso8601String(),
        'tempMin': minT.isFinite ? minT : 0.0,
        'tempMax': maxT.isFinite ? maxT : 0.0,
        'windSpeed': windN > 0 ? windSum / windN : 0.0,
        'rainMm': rainMm,
        'pop': popN > 0 ? popSum / popN : 0.0,
        'humidity': humidityN > 0 ? (humiditySum / humidityN).round() : 0,
        'status': status,
      });
    }
    return out;
  }
}
